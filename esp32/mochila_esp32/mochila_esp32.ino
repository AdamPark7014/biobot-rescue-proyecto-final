// ============================================================================
// mochila_esp32.ino
// Proyecto final - Sistemas Embebidos (CN113) - BioBot-Rescue
// ESP32 DevKit V1: la parte de la mochila que no va en la FPGA.
//
//   matriz térmica 8x8  --I2C-->  ESP32  --UART2 (GPIO16/17)-->  DE10-Lite
//                                   |                              (núcleo)
//                                   +--USB--> monitor serie de la PC
//
// Diez veces por segundo manda a la tarjeta un cuadro de 66 bytes:
//     0xA5, actividad, píxel 0, píxel 1, ... píxel 63
// Cada píxel es un byte sin signo de 0.25 grados C por cuenta (112 = 28 C,
// 152 = 38 C), fila por fila; las columnas 0 a 2 son la izquierda de la
// imagen y las 5 a 7 la derecha. "actividad" es cuánto se mueve el insecto
// según la IMU: menos de 8 durante un segundo cuenta como quieto.
//
// La tarjeta contesta cada cuadro con cuatro bytes:
//     0x5A
//     {alerta, estado[2:0], hubo_estimulo, canal[1:0], quieto}
//     {pre, n_fil[6:0]}        píxeles calientes ya promediados
//     cuenta[15:8]             estímulos acumulados
//
// Hay dos fuentes de cuadros, a elegir con USAR_SENSOR:
//   0  Escena sintética con un insecto simulado. No hace falta ningún sensor:
//      sirve para demostrar el núcleo solo con el ESP32 y la DE10-Lite. El
//      insecto simulado camina, se detiene y obedece los estímulos que
//      ordena la tarjeta, así que el lazo queda cerrado.
//   1  Matriz AMG8833 real por I2C (SDA = GPIO21, SCL = GPIO22, 3.3 V).
//      Como aquí no hay IMU, el botón BOOT hace de insecto: presionado =
//      camina, suelto = quieto.
//
// Conexión con la tarjeta (cruzada, con tierra común), igual que en la
// práctica 4:
//   GPIO17 (TX2) del ESP32  ->  GPIO_32, pin 37 de JP1 (UART_RX de la tarjeta)
//   GPIO16 (RX2) del ESP32  <-  GPIO_30, pin 35 de JP1 (UART_TX de la tarjeta)
//   GND del ESP32           ->  GND de la DE10-Lite (pin 12 o 30 de JP1)
//
// En la tarjeta: SW0 arriba arranca la misión y KEY0 la reinicia.
// ============================================================================

#include <Arduino.h>
#include <Wire.h>

#ifndef USAR_SENSOR
#define USAR_SENSOR 0              // 0 = escena sintética, 1 = AMG8833 real
#endif

// ---- pines y velocidades ---------------------------------------------------
static const int FPGA_RX_PIN = 16;             // RX del ESP32 <- TX de la tarjeta
static const int FPGA_TX_PIN = 17;             // TX del ESP32 -> RX de la tarjeta
static const int LED_PIN     = 2;              // LED azul: encendido en ALERTAR
static const int BOTON_PIN   = 0;              // botón BOOT (activo en bajo)
static const uint32_t FPGA_BAUD  = 9600;       // debe coincidir con la tarjeta
static const uint32_t PC_BAUD    = 115200;     // monitor serie
static const uint32_t PERIODO_MS = 100;        // 10 cuadros por segundo

// ---- protocolo ------------------------------------------------------------
static const uint8_t CABECERA_TX = 0xA5;
static const uint8_t CABECERA_RX = 0x5A;
static const int     N_PIX       = 64;
static const int     COLS        = 8;

// Estados del núcleo, en el mismo orden que fsm_politica.v
static const char *const NOMBRE_ESTADO[8] = {
  "REPOSO", "EXPLORAR", "REACTIVAR", "REORIENTAR",
  "ACERCAR", "CONFIRMAR", "ALERTAR", "DESCANSO"
};
static const uint8_t EST_REPOSO  = 0;
static const uint8_t EST_ALERTAR = 6;
static const char *const NOMBRE_CANAL[4] = { "avance", "izquierda", "derecha", "?" };

HardwareSerial FPGA_Serial(2);

uint8_t  trama[2 + N_PIX];        // cuadro que se manda
uint32_t proximoCuadro = 0;       // millis() del siguiente envío
uint32_t cuadros       = 0;       // cuadros mandados
uint32_t sinRespuesta  = 0;       // cuadros que la tarjeta no contestó
uint32_t estimulos     = 0;       // estímulos ordenados por la tarjeta
uint8_t  estadoPrevio  = 255;

// ============================================================================
// Fuente 1: matriz AMG8833 real
// ============================================================================
#if USAR_SENSOR

static const uint8_t AMG_DIR      = 0x69;   // 0x68 si el puente AD0 va a tierra
static const uint8_t AMG_PCTL     = 0x00;   // modo de energía
static const uint8_t AMG_RST      = 0x01;   // reinicio
static const uint8_t AMG_FPSC     = 0x02;   // cuadros por segundo
static const uint8_t AMG_PIXEL_0  = 0x80;   // T01L; cada píxel son dos bytes

static void amgEscribe(uint8_t registro, uint8_t valor) {
  Wire.beginTransmission(AMG_DIR);
  Wire.write(registro);
  Wire.write(valor);
  Wire.endTransmission();
}

void fuenteInicia() {
  Wire.begin();                    // SDA = 21, SCL = 22
  Wire.setClock(400000);
  amgEscribe(AMG_PCTL, 0x00);      // modo normal
  amgEscribe(AMG_RST, 0x3F);       // reinicio inicial
  delay(100);
  amgEscribe(AMG_FPSC, 0x00);      // 10 cuadros por segundo
  pinMode(BOTON_PIN, INPUT_PULLUP);
}

// Lee los 64 píxeles. El sensor entrega 12 bits con signo y 0.25 C por
// cuenta, que es justo la escala del núcleo: solo se recorta a un byte.
// Se lee en cuatro bloques de 32 bytes para no pasar del búfer de Wire.
void fuenteCuadro(uint8_t *pix, uint8_t *actividad) {
  for (int bloque = 0; bloque < 4; bloque++) {
    Wire.beginTransmission(AMG_DIR);
    Wire.write((uint8_t)(AMG_PIXEL_0 + 32 * bloque));
    Wire.endTransmission(false);
    Wire.requestFrom((int)AMG_DIR, 32);
    for (int i = 0; i < 16; i++) {
      int bajo = Wire.available() ? Wire.read() : 0;
      int alto = Wire.available() ? Wire.read() : 0;
      int crudo = ((alto & 0x0F) << 8) | bajo;
      if (crudo & 0x800) crudo -= 4096;          // complemento a dos de 12 bits
      if (crudo < 0)   crudo = 0;
      if (crudo > 255) crudo = 255;
      pix[16 * bloque + i] = (uint8_t)crudo;
    }
  }
  // Sin IMU: el botón BOOT presionado equivale a un insecto que camina
  *actividad = (digitalRead(BOTON_PIN) == LOW) ? 40 : 0;
}

void fuenteEstimulo(uint8_t canal) { (void)canal; }
void fuenteReinicia() {}
void fuenteTexto(char *texto, size_t n) { snprintf(texto, n, "sensor real"); }

// ============================================================================
// Fuente 0: escena sintética con insecto simulado
// ============================================================================
#else

static const float GRADOS_POR_PIXEL = 7.5f;     // 60 grados entre 8 columnas
static const float AREA_BLANCO      = 0.03f;    // m2 de piel a la vista (una cara)
static const uint8_t T_FONDO        = 88;       // 22 C
static const uint8_t T_PIEL         = 132;      // 33 C
static const float V_NATURAL        = 0.02f;    // m/s
static const float V_IMPULSO        = 0.05f;    // m/s durante 4 s tras un estímulo
static const float P_OBEDECE        = 0.78f;    // probabilidad de obedecer

struct Insecto {
  float    dist;          // m hasta la persona
  float    rumbo;         // grados; positivo = la persona queda a la derecha
  bool     anda;
  uint32_t finPausa;      // millis() en que reanuda sola la marcha
  uint32_t finImpulso;    // millis() hasta el que camina rápido
} ins;

void fuenteReinicia() {
  ins.dist       = 3.0f;
  ins.rumbo      = (float)random(-25, 26);
  ins.anda       = true;
  ins.finPausa   = 0;
  ins.finImpulso = 0;
}

void fuenteInicia() {
  randomSeed(esp_random());
  fuenteReinicia();
}

// La tarjeta ordenó un estímulo: el insecto simulado obedece casi siempre
void fuenteEstimulo(uint8_t canal) {
  if (random(0, 1000) >= (long)(P_OBEDECE * 1000)) return;
  float giro = 50.0f + (float)random(-20, 21);
  if (canal == 1)      ins.rumbo += giro;      // gira a la izquierda: la persona se va a la derecha
  else if (canal == 2) ins.rumbo -= giro;
  else                 ins.finImpulso = millis() + 4000;
  ins.anda = true;
}

void fuenteCuadro(uint8_t *pix, uint8_t *actividad) {
  const float dt = PERIODO_MS / 1000.0f;
  uint32_t ahora = millis();

  // --- el insecto: camina, a veces se detiene un buen rato
  if (ins.anda) {
    float v = (ahora < ins.finImpulso) ? V_IMPULSO : V_NATURAL;
    ins.dist  -= v * cosf(radians(ins.rumbo)) * dt;
    ins.rumbo += (float)random(-10, 11) * 0.1f;
    if (ins.dist < 0.25f) ins.dist = 0.25f;
    if (ins.dist > 4.0f)  ins.dist = 4.0f;
    if (ahora >= ins.finImpulso && random(0, 1000) < 12) {     // una pausa cada 8 s en promedio
      ins.anda     = false;
      ins.finPausa = ahora + (uint32_t)random(20000, 50000);
    }
  } else if (ahora >= ins.finPausa) {
    ins.anda = true;
  }
  if (ins.rumbo > 180.0f)  ins.rumbo -= 360.0f;
  if (ins.rumbo < -180.0f) ins.rumbo += 360.0f;
  *actividad = ins.anda ? (uint8_t)random(30, 40) : (uint8_t)random(0, 4);

  // --- lo que vería la matriz: una mancha tibia sobre un fondo a 22 C
  float lado   = ins.dist * tanf(radians(GRADOS_POR_PIXEL));   // m que cubre un píxel
  float n      = AREA_BLANCO / (lado * lado);                  // píxeles que llena la cara
  float radio2 = n / PI;                                       // radio al cuadrado, en píxeles
  float cx     = 3.5f + ins.rumbo / GRADOS_POR_PIXEL;
  float cy     = 3.5f;
  for (int f = 0; f < COLS; f++) {
    for (int c = 0; c < COLS; c++) {
      float dx = c - cx, dy = f - cy;
      bool piel = (dx * dx + dy * dy) <= radio2;
      pix[f * COLS + c] = (uint8_t)((piel ? T_PIEL : T_FONDO) + random(-1, 2));
    }
  }
}

void fuenteTexto(char *texto, size_t n) {
  snprintf(texto, n, "persona a %.2f m, %+.0f grados, insecto %s",
           ins.dist, ins.rumbo, ins.anda ? "camina" : "quieto");
}

#endif

// ============================================================================
// Enlace con la tarjeta
// ============================================================================

// Espera los cuatro bytes de respuesta. Devuelve false si no llegan a tiempo.
bool leeRespuesta(uint8_t *r, uint32_t plazoMs) {
  uint32_t limite = millis() + plazoMs;
  int n = 0;
  while (millis() < limite) {
    while (FPGA_Serial.available()) {
      uint8_t b = (uint8_t)FPGA_Serial.read();
      if (n == 0 && b != CABECERA_RX) continue;      // busca el encabezado
      r[n++] = b;
      if (n == 4) return true;
    }
  }
  return false;
}

void setup() {
  Serial.begin(PC_BAUD);
  FPGA_Serial.begin(FPGA_BAUD, SERIAL_8N1, FPGA_RX_PIN, FPGA_TX_PIN);
  pinMode(LED_PIN, OUTPUT);
  digitalWrite(LED_PIN, LOW);
  delay(300);
  fuenteInicia();
  Serial.println();
  Serial.println(USAR_SENSOR ? "BioBot-Rescue: matriz AMG8833 real" : "BioBot-Rescue: escena sintetica");
  Serial.println("Sube SW0 en la tarjeta para arrancar la mision; KEY0 la reinicia.");
  proximoCuadro = millis() + PERIODO_MS;
}

void loop() {
  if ((int32_t)(millis() - proximoCuadro) < 0) return;
  proximoCuadro += PERIODO_MS;

  // --- arma y manda el cuadro de una sola vez: la tarjeta descarta una trama
  //     que se quede más de 5 ms sin bytes
  trama[0] = CABECERA_TX;
  fuenteCuadro(&trama[2], &trama[1]);
  while (FPGA_Serial.available()) FPGA_Serial.read();   // respuestas viejas
  FPGA_Serial.write(trama, sizeof(trama));
  FPGA_Serial.flush();                                  // 66 bytes a 9600 baudios: 69 ms
  cuadros++;

  // --- lee la respuesta
  uint8_t r[4];
  if (!leeRespuesta(r, 20)) {
    sinRespuesta++;
    if (sinRespuesta % 20 == 1)
      Serial.println("La tarjeta no contesta: revisa el cableado, la tierra comun y que el .sof este cargado.");
    return;
  }
  bool    alerta = r[1] & 0x80;
  uint8_t estado = (r[1] >> 4) & 0x07;
  bool    hubo   = r[1] & 0x08;
  uint8_t canal  = (r[1] >> 1) & 0x03;
  bool    quieto = r[1] & 0x01;
  bool    pre    = r[2] & 0x80;
  uint8_t nFil   = r[2] & 0x7F;
  uint8_t cuenta = r[3];

  digitalWrite(LED_PIN, alerta ? HIGH : LOW);

  if (hubo) {
    estimulos++;
    fuenteEstimulo(canal);
    Serial.printf("  ESTIMULO %lu: %s (acumulados: %u de 12)\n",
                  (unsigned long)estimulos, NOMBRE_CANAL[canal], cuenta);
  }

  // Si la tarjeta se reinició (KEY0) empieza una escena nueva. ALERTAR es un
  // estado final, así que salir de él solo puede deberse a un reinicio.
  bool volvioAReposo = (estado == EST_REPOSO && estadoPrevio != EST_REPOSO && estadoPrevio != 255);
  bool salioDeAlerta = (estadoPrevio == EST_ALERTAR && estado != EST_ALERTAR);
  if (volvioAReposo || salioDeAlerta) {
    fuenteReinicia();
    estimulos = 0;
    Serial.println("--- reinicio: escena nueva ---");
  }

  // Un renglón cada segundo, y uno más cada vez que cambia el estado
  if (estado != estadoPrevio || cuadros % 10 == 0) {
    char texto[80];
    fuenteTexto(texto, sizeof(texto));
    Serial.printf("%7.1f s  %-10s  pixeles calientes %2u%s%s  |  %s\n",
                  cuadros * (PERIODO_MS / 1000.0f), NOMBRE_ESTADO[estado], nFil,
                  pre ? "  ve calor" : "", quieto ? "  quieto" : "", texto);
    if (estado == EST_ALERTAR && estadoPrevio != EST_ALERTAR)
      Serial.println("*** ALERTA: persona confirmada. KEY0 en la tarjeta para repetir. ***");
  }
  estadoPrevio = estado;
}
