#include <Arduino.h>
#include <Wire.h>

#ifndef USAR_SENSOR
#define USAR_SENSOR 0
#endif

// pines y velocidades
static const int FPGA_RX_PIN = 16;
static const int FPGA_TX_PIN = 17;
static const int LED_PIN     = 2;
static const int BOTON_PIN   = 0;
static const uint32_t FPGA_BAUD  = 9600;
static const uint32_t PC_BAUD    = 115200;
static const uint32_t PERIODO_MS = 100;

// protocolo
static const uint8_t CABECERA_TX = 0xA5;
static const uint8_t CABECERA_RX = 0x5A;
static const int     N_PIX       = 64;
static const int     COLS        = 8;

// estados del núcleo
static const char *const NOMBRE_ESTADO[8] = {
  "REPOSO", "EXPLORAR", "REACTIVAR", "REORIENTAR",
  "ACERCAR", "CONFIRMAR", "ALERTAR", "DESCANSO"
};
static const uint8_t EST_REPOSO  = 0;
static const uint8_t EST_ALERTAR = 6;
static const char *const NOMBRE_CANAL[4] = { "avance", "izquierda", "derecha", "?" };

HardwareSerial FPGA_Serial(2);

uint8_t  trama[2 + N_PIX];
uint32_t proximoCuadro = 0;
uint32_t cuadros       = 0;
uint32_t sinRespuesta  = 0;
uint32_t estimulos     = 0;
uint8_t  estadoPrevio  = 255;

// sensor real
#if USAR_SENSOR

static const uint8_t AMG_DIR      = 0x69;
static const uint8_t AMG_PCTL     = 0x00;
static const uint8_t AMG_RST      = 0x01;
static const uint8_t AMG_FPSC     = 0x02;
static const uint8_t AMG_PIXEL_0  = 0x80;

static void amgEscribe(uint8_t registro, uint8_t valor) {
  Wire.beginTransmission(AMG_DIR);
  Wire.write(registro);
  Wire.write(valor);
  Wire.endTransmission();
}

void fuenteInicia() {
  Wire.begin();
  Wire.setClock(400000);
  amgEscribe(AMG_PCTL, 0x00);
  amgEscribe(AMG_RST, 0x3F);
  delay(100);
  amgEscribe(AMG_FPSC, 0x00);
  pinMode(BOTON_PIN, INPUT_PULLUP);
}

// lectura
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
      if (crudo & 0x800) crudo -= 4096;
      if (crudo < 0)   crudo = 0;
      if (crudo > 255) crudo = 255;
      pix[16 * bloque + i] = (uint8_t)crudo;
    }
  }
  // sin IMU
  *actividad = (digitalRead(BOTON_PIN) == LOW) ? 40 : 0;
}

void fuenteEstimulo(uint8_t canal) { (void)canal; }
void fuenteReinicia() {}
void fuenteTexto(char *texto, size_t n) { snprintf(texto, n, "sensor real"); }

// insecto simulado
#else

static const float GRADOS_POR_PIXEL = 7.5f;
static const float AREA_BLANCO      = 0.03f;
static const uint8_t T_FONDO        = 88;
static const uint8_t T_PIEL         = 132;
static const float V_NATURAL        = 0.02f;
static const float V_IMPULSO        = 0.05f;
static const float P_OBEDECE        = 0.78f;

struct Insecto {
  float    dist;
  float    rumbo;
  bool     anda;
  uint32_t finPausa;
  uint32_t finImpulso;
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

// estímulo
void fuenteEstimulo(uint8_t canal) {
  if (random(0, 1000) >= (long)(P_OBEDECE * 1000)) return;
  float giro = 50.0f + (float)random(-20, 21);
  if (canal == 1)      ins.rumbo += giro;
  else if (canal == 2) ins.rumbo -= giro;
  else                 ins.finImpulso = millis() + 4000;
  ins.anda = true;
}

void fuenteCuadro(uint8_t *pix, uint8_t *actividad) {
  const float dt = PERIODO_MS / 1000.0f;
  uint32_t ahora = millis();

  // insecto
  if (ins.anda) {
    float v = (ahora < ins.finImpulso) ? V_IMPULSO : V_NATURAL;
    ins.dist  -= v * cosf(radians(ins.rumbo)) * dt;
    ins.rumbo += (float)random(-10, 11) * 0.1f;
    if (ins.dist < 0.25f) ins.dist = 0.25f;
    if (ins.dist > 4.0f)  ins.dist = 4.0f;
    if (ahora >= ins.finImpulso && random(0, 1000) < 12) {
      ins.anda     = false;
      ins.finPausa = ahora + (uint32_t)random(20000, 50000);
    }
  } else if (ahora >= ins.finPausa) {
    ins.anda = true;
  }
  if (ins.rumbo > 180.0f)  ins.rumbo -= 360.0f;
  if (ins.rumbo < -180.0f) ins.rumbo += 360.0f;
  *actividad = ins.anda ? (uint8_t)random(30, 40) : (uint8_t)random(0, 4);

  // imagen
  float lado   = ins.dist * tanf(radians(GRADOS_POR_PIXEL));
  float n      = AREA_BLANCO / (lado * lado);
  float radio2 = n / PI;
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

// enlace con la tarjeta
bool leeRespuesta(uint8_t *r, uint32_t plazoMs) {
  uint32_t limite = millis() + plazoMs;
  int n = 0;
  while (millis() < limite) {
    while (FPGA_Serial.available()) {
      uint8_t b = (uint8_t)FPGA_Serial.read();
      if (n == 0 && b != CABECERA_RX) continue;
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

  trama[0] = CABECERA_TX;
  fuenteCuadro(&trama[2], &trama[1]);
  while (FPGA_Serial.available()) FPGA_Serial.read();
  FPGA_Serial.write(trama, sizeof(trama));
  FPGA_Serial.flush();
  cuadros++;

  // lee la respuesta
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

  // reinicio
  bool volvioAReposo = (estado == EST_REPOSO && estadoPrevio != EST_REPOSO && estadoPrevio != 255);
  bool salioDeAlerta = (estadoPrevio == EST_ALERTAR && estado != EST_ALERTAR);
  if (volvioAReposo || salioDeAlerta) {
    fuenteReinicia();
    estimulos = 0;
    Serial.println("--- reinicio: escena nueva ---");
  }

  // reporte
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
