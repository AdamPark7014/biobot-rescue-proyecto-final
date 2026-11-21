# Guía de laboratorio: probar BioBot-Rescue en la DE10-Lite

Tarjeta: **DE10-Lite, MAX 10 `10M50DAF484C7G`**, la misma de las prácticas 2 a 4.
Todos los archivos `.sof` ya están generados; no hace falta compilar nada en clase.

| Montaje | Tarjetas | Archivo a cargar |
|---|---|---|
| **E. Red de tres FPGA (la demostración)** | 3 | `CARGAR_RED.cmd` carga las tres y verifica los enlaces |
| A. Una sola tarjeta | 1 | `quartus_demo/output_files/biobot_demo.sof` |
| B. Dos tarjetas | 2 | Mochila: `quartus/output_files/biobot.sof`. Insecto: `quartus_insecto/output_files/biobot_insecto.sof` |
| C. Tarjeta y ESP32 | 1 + ESP32 | `quartus/output_files/biobot.sof` y el programa `esp32/mochila_esp32` |
| D. Red de botón y puente (versión anterior) | 2 o 3 | `quartus_red_*` |

Para cargar a mano: Quartus → Tools → Programmer → Hardware Setup: USB-Blaster → Add File → el `.sof` → Start.
El `.sof` se pierde al quitar la corriente; hay que volver a cargarlo.

## Montaje E: red de tres FPGA con detección, tonos y triangulación

Es el montaje de la demostración. Dos tarjetas son las mochilas de dos cucarachas (A y B) y la tercera es
el receptor del operador. La computadora se conecta al receptor y muestra todo en una terminal.

### Qué hace cada tarjeta

- **Cada mochila** corre el núcleo del proyecto sobre un sensor térmico simulado con los interruptores.
  Detecta a una persona de dos formas redundantes: por temperatura y por el botón de ayuda. Avisa por radio
  (UART) a las otras dos tarjetas, mide en qué dirección ve el calor y emite un tono propio.
- **El receptor** junta lo que llega, cuenta las personas detectadas, cruza los rumbos de las dos mochilas
  para estimar dónde está la persona (triangulación) y se lo pasa a la computadora.
- **Si una mochila queda fuera de alcance**, la otra retransmite su aviso (puente).

### En tres pasos

1. Conectar las tres tarjetas por USB y poner los seis cables de JP1 (tabla de abajo).
2. Doble clic en **`CARGAR_RED.cmd`**. Carga las tres tarjetas y revisa los cuatro enlaces. No importa en
   qué puerto USB quedó cada una. Cada tarjeta muestra su letra en el display de la izquierda: `A`, `b` o `r`.
3. Doble clic en **`DEMO.cmd`**. Abre dos ventanas: el **monitor**, que se actualiza solo, y la de **órdenes**.

### Cables (conector JP1, el de 40 pines)

| De | | A | Para qué |
|---|---|---|---|
| A, pin 35 | → | r, pin 37 | A habla con el receptor |
| A, pin 33 | → | b, pin 37 | A habla con B |
| b, pin 35 | → | r, pin 39 | B habla con el receptor |
| b, pin 33 | → | A, pin 37 | B habla con A |
| A, pin 30 | — | r, pin 30 | tierra |
| b, pin 30 | — | r, pin 12 | tierra |

Los pines 33, 35, 37 y 39 son los cuatro últimos de la columna izquierda; el 39 es el de hasta abajo. Los
pines 35 y 33 de cada tarjeta llevan la misma señal. El pin 1 saca el tono propio de la tarjeta (1, 2 o
4 kHz), por si se quiere oír con un zumbador o ver en el osciloscopio; no hace falta conectarlo.

### Controles de cada mochila

| Control | Qué es |
|---|---|
| **SW5–SW0** | La temperatura que lee el sensor térmico, en grados, en binario. Detecta de **35 a 38 °C** |
| **KEY1** | El botón de ayuda que va sobre la cucaracha. Queda marcado hasta reiniciar |
| **KEY0** | Reinicia la tarjeta |
| SW9–SW6 | Posición de la cucaracha (16 lugares fijos), si la terminal no la fija |

Temperaturas en los interruptores (SW5 a SW0): 34 = `100010`, **35 = `100011`, 36 = `100100`,
37 = `100101`, 38 = `100110`**, 39 = `100111`. Con 22 (`010110`) no hay nadie; con 47 (`101111`) es un
objeto caliente y no debe contar. Si la temperatura sale del intervalo, la detección se apaga en menos de
un segundo y el conteo baja.

### Qué se ve en las tarjetas

| Indicador | En una mochila | En el receptor |
|---|---|---|
| HEX5 | Quién es: `A` o `b` | `r` |
| HEX4–HEX3 | `Pd` (personas detectadas) | `Pd` |
| HEX2 | Cuántas personas detectadas: 0, 1 o 2 | Lo mismo |
| HEX1 | La letra de la otra mochila, si oye su tono | `A`, si oye el tono de A |
| HEX0 | `r`, si oye el tono del receptor | `b`, si oye el tono de B |
| LEDR9–5 | Metros a la otra mochila, en binario | Metros a la mochila A |
| LEDR4–0 | Metros al receptor, en binario | Metros a la mochila B |

Los LED de una distancia quedan apagados cuando no se oye a ese nodo. Con cinco LED se cuentan hasta 31 m,
que es justo el alcance: **a menos de 32 m se oye; a 32 m o más, no**.

En el receptor, SW1–SW0 cambian lo que muestran los displays: `00` lo de la tabla, `01` la posición de la
persona (X y Y en decímetros), `10` la distancia entre A y B, `11` los rumbos de A y B en grados.

### Escala y alcance

- Mapa de 0 a 64 m en 10 bits: una cuenta vale **6.25 cm**. Por ejemplo, 5 m son 80 cuentas, el 7.8 % de
  la escala.
- El receptor está en la entrada, en (0, 0). La persona está escondida en (25.50, 19.25) m, a 31.95 m: en
  el borde del alcance.
- Alcance del radio y de los tonos: 31.94 m (511 cuentas).

### La terminal

`DEMO.cmd` abre dos ventanas:

- **Monitor.** Muestra lo que sabe el receptor: personas detectadas, posición estimada de la persona, y de
  cada mochila su posición, la distancia, si la detección es térmica **y a cuántos grados**, el botón, el
  rumbo y a quién oye. Cambia en cuanto cambia algo en las tarjetas.
- **Órdenes.** Lo que se escribe aquí se ejecuta en las tarjetas y se ve en el monitor:

| Orden | Qué hace |
|---|---|
| `pos A 31 0` | Pone la mochila A en x = 31 m, y = 0 m. Está a 31 m: se oye |
| `pos A 32 0` | A 32 m ya no se oye: se apagan sus LED y desaparece del receptor |
| `pos B 4.5 3` | Pone a B cerca de la entrada, para que haga de puente |
| `pos A sw` | La posición vuelve a los interruptores SW9–SW6 |
| `temp A 36` | El sensor de A lee 36 °C (lo mismo que mover SW5–SW0) |
| `temp A sw` | La temperatura vuelve a los interruptores |
| `boton B` | Aprieta el botón de ayuda de B |
| `vista 1` | Cambia lo que muestran los displays del receptor (0 a 3) |
| `vista sw` | La vista del receptor vuelve a sus interruptores SW1–SW0 |
| `reset` / `suelta` | Reinicia las tarjetas / todo vuelve a los interruptores |

### Guion de la demostración

1. **Nadie.** Las dos mochilas en 22 °C. Las tres tarjetas muestran `Pd 0`.
2. **Detección térmica.** En A, poner 36 en SW5–SW0. En un segundo y medio las tres tarjetas muestran `Pd 1`
   y el monitor dice «térmica SÍ, 36 C».
3. **Segunda detección.** En B, poner 37. Las tres muestran `Pd 2` y el receptor da la posición de la
   persona cruzando los dos rumbos.
4. **Sale del intervalo.** En A, poner 40 o 30. El conteo baja a 1 en las tres.
5. **Objeto caliente.** Poner 47: no cuenta.
6. **Botón.** Con las dos en 22 °C, apretar KEY1 en B: `Pd 1` en las tres. Se borra con KEY0 en B.
7. **Alcance.** En órdenes: `pos A 31 0` (el receptor muestra `A` y 31 en los LED) y luego `pos A 32 0`
   (se apagan).
8. **Puente.** `pos A sw` y `pos B sw`, con SW9–SW6 de A en `0001` y de B en `0000`: A queda a 32.00 m,
   fuera de alcance, y su aviso llega por B. El monitor dice «radio: por el puente B».

### Posiciones con SW9–SW6

| SW9–SW6 | Lugar (m) | Distancia al receptor |
|---|---|---|
| `0000` | (25.25, 19.00), junto a la persona | 31.60 m: se oye |
| `0001` | (25.75, 19.00), junto a la persona | 32.00 m: no se oye |
| `0010` | (25.75, 19.50), junto a la persona | 32.30 m: no se oye |
| `0011` | (25.25, 19.50), junto a la persona | 31.90 m: se oye |
| `0100` | (25.50, 18.94), junto a la persona | 31.76 m: se oye |
| `0101` | (40, 30) | 50.0 m |
| `0110` | (50, 40) | 64.0 m |
| `0111` | (4.5, 3.0), cerca de la entrada | 5.4 m |
| `1000` a `1111` | (2, 2), (10, 10), (20, 10), (10, 20), (20, 20), (23, 22), (24, 22), (60, 60) | 2.8, 14.1, 22.4, 22.4, 28.3, 31.8, 32.6 y 84.9 m |

### Cómo se hablan las tarjetas

UART a 115 200 baudios, con una trama propia de 16 bytes cada 100 ms:

| Byte | Contenido |
|---|---|
| 0 | `0xA5`, sincronía |
| 1 | Quién midió (origen), quién transmite esta copia (emisor) y cuántos saltos lleva |
| 2 | Detección térmica, botón, mancha a la vista, rumbo válido y estado del núcleo |
| 3–8 | Posición del origen, rumbo hacia el calor, distancia estimada y píxeles calientes |
| 9–11 | Posición del emisor |
| 12 | A quién oye por tonos y la temperatura del sensor |
| 13 | Número de secuencia |
| 14–15 | **CRC-16/CCITT** de los bytes 1 a 13 |

Quien recibe descarta la trama si el CRC no coincide, si se corta a la mitad o si el emisor está a 32 m o
más. Con el número de secuencia el receptor cuenta las tramas perdidas y reconoce la que le llega repetida
por dos caminos. Si en un segundo no llega nada de una mochila, la da por perdida.

### Los tonos

Cada nodo emite todo el tiempo un tono distinto: **A 1 kHz, B 2 kHz y el receptor 4 kHz**. Cada uno lleva
un detector que mide la potencia en las frecuencias de los otros dos con filtros de Goertzel (un filtro IIR
de segundo orden), cada 4 ms. Con saber a quién oye, cada nodo sabe quién le queda cerca. No hay bocinas ni
micrófonos: el canal va simulado, y el tono de un nodo «llega» solo si ese nodo está a menos de 32 m.

### Pruebas

| Prueba | Cómo | Resultado |
|---|---|---|
| CORDIC y divisor | `tb_cordic` | 248 de 248 casos; error máximo de 0.008° en el ángulo y 0.013 % en la magnitud |
| Detector de tonos | `tb_tonos` | 8 de 8; un tono presente mide unas 28 000 unidades y el silencio menos de 50 |
| Las tres FPGA | `tb_tri`, nueve escenarios | 9 de 9. Triangula con 6.2 cm de error a 31.95 m, en 1.10 s; a 31 m se oye y a 32 m no; con ruido en la línea descarta 14 tramas por CRC y no usa ningún dato equivocado |
| La terminal contra las tres tarjetas simuladas | `sim/probar_terminal.ps1` | 47 de 47 comprobaciones en 12 pasos: cada orden llega bien a la FPGA y la terminal muestra lo que el circuito hace |
| Síntesis de las cuatro variantes | `sintetizar_red.ps1` | Mochila 4 812 elementos lógicos (10 %) y 56 MHz; receptor 6 220 (13 %) y 57 MHz; sin advertencias críticas |
| En las tres tarjetas reales, 18-11-2026 | `sim/prueba_tri.tcl` | Seis escenarios correctos con la versión anterior del enlace (mapa de 20 m, sin CRC ni tonos); error de triangulación de 2.8 cm |
| Sensor en la tarjeta real, 18-11-2026 | lectura directa | Detecta con 35, 36 y 38 °C; no con 34, 39, 47 ni 22 °C; al salir del intervalo se apaga en 0.77 s |

La versión con CRC-16, número de secuencia, tonos y mapa de 64 m está simulada y sintetizada, pero **todavía
no se ha cargado en las tarjetas**. Para comprobarla: `CARGAR_RED.cmd` y después
`quartus_stp -t sim/prueba_tri.tcl`, con el monitor cerrado.

Las distancias se guardan en cuentas de 6.25 cm y se truncan: una mochila a 31.60 m aparece en la terminal
a 31.56 m.

Si una tarjeta se queda sin corriente pierde su programa: volver a correr `CARGAR_RED.cmd`.

## Cuántas tarjetas y por qué

- **Con una** se demuestra el circuito completo: dentro del mismo chip van el núcleo de la mochila y un
  insecto de prueba que genera lo que vería la matriz térmica y reacciona a los estímulos.
- **Con dos** se demuestra además el enlace real: una tarjeta es la mochila y la otra es el insecto con su
  sensor. Solo las unen dos líneas de UART y tierra. Es el mismo circuito de la mochila que se usaría con el
  ESP32 y el sensor, sin cambiarle nada.
- **Con tres** (montaje E) se demuestra la red: dos mochilas que detectan, se oyen por tonos y se
  retransmiten, y el receptor del operador que triangula.

## Montaje A: una sola tarjeta

1. Cargar `biobot_demo.sof`.
2. Elegir el escenario con SW2 y SW1 (tabla de abajo).
3. Subir **SW0** para arrancar la misión. **KEY0** reinicia todo.
4. **SW9** arriba corre ocho veces más rápido: con persona, la alerta llega en unos 7 s en vez de 56 s.

## Montaje B: dos tarjetas

Tres cables hembra-hembra entre los conectores JP1 (el de 40 pines), **cruzados**:

| Tarjeta insecto | | Tarjeta mochila |
|---|---|---|
| pin 35 (GPIO_30, transmite) | → | pin 37 (GPIO_32, recibe) |
| pin 37 (GPIO_32, recibe) | ← | pin 35 (GPIO_30, transmite) |
| pin 30 (GND) | — | pin 30 (GND) |

Es el mismo par de pines de la práctica 4. Conectar con las tarjetas apagadas.

**Dónde están los pines.** Con la tarjeta como en la figura 3-18 del manual (USB arriba, VGA abajo), JP1
queda a la derecha y tiene dos columnas: la izquierda lleva los pines nones (1 arriba, 39 abajo) y la
derecha los pares (2 arriba, 40 abajo). Contando **desde abajo**:

| Pin | Columna | Fila desde abajo | Qué es |
|---|---|---|---|
| 37 | izquierda | 2.ª | GPIO_32, recibe |
| 35 | izquierda | 3.ª | GPIO_30, transmite |
| 30 | derecha | 6.ª | Tierra |

El pin 29, justo a la izquierda del 30, es de 3.3 V: no se conecta.

1. Cargar `biobot.sof` en la mochila y `biobot_insecto.sof` en la otra.
2. En la tarjeta insecto, elegir el escenario con SW2 y SW1.
3. En la mochila, subir **SW0**.
4. En la tarjeta insecto debe encenderse **LEDR8** (enlace vivo). Si no enciende: revisar que los cables
   estén cruzados, la tierra y que la mochila tenga su `.sof`.
5. Para repetir: KEY0 en las dos tarjetas.

Aquí no hay modo rápido: el enlace va a 9600 baudios y diez cuadros por segundo, en tiempo real.

## Escenarios (SW2, SW1)

| SW2 SW1 | Escenario | Qué debe verse |
|---|---|---|
| 0 0 | Sin persona | Estado 1 (explorar). Cuando el insecto se detiene 15 s, estado 2 y LEDR0 (pulso de avance). De vez en cuando estado 3 con LEDR1 o LEDR2 (giro al azar). Nunca alerta |
| 0 1 | Persona a 1.65 m, a la izquierda | Estado 1 unos segundos; luego 4 (acercar) con LEDR1 o LEDR2 al girar; la distancia baja; cerca de 0.5 m pasa a 5 (confirmar) y a 6 (alertar) con **LEDR9** encendido |
| 1 0 | Objeto a 47.5 °C en ambiente de 30 °C | Píxeles calientes en 00 todo el tiempo. Nunca pasa a 4 ni alerta: el objeto está fuera de la ventana de 28 a 38 °C y el ambiente tibio no cuenta |
| 1 1 | Insecto que no responde | Estado 2 a los 16 s, luego a los 49, 112 y 236 s: la espera se duplica. HEX1 sube con cada estímulo. Nunca alerta |

## Qué muestra cada indicador

| Indicador | Una tarjeta y mochila | Tarjeta insecto |
|---|---|---|
| LEDR2-0 | Estímulo activo: derecha, izquierda, avance | Estímulo recibido (medio segundo) |
| LEDR3 | El núcleo ve al insecto quieto | El insecto camina |
| LEDR4 | Mancha de calor a la vista | La mochila reporta mancha |
| LEDR7-5 | Estado, en binario | Estado que reporta la mochila |
| LEDR8 | Cambia con cada cuadro | Enlace vivo |
| LEDR9 | **Alerta: persona detectada** | La mochila reporta alerta |
| HEX0 | Estado: 0 reposo, 1 explorar, 2 reactivar, 3 reorientar, 4 acercar, 5 confirmar, 6 alertar, 7 descanso | Lo mismo, reportado |
| HEX1 | Estímulos acumulados en el presupuesto (0 a C) | Estímulos que el insecto obedeció |
| HEX3-HEX2 | Píxeles calientes, en hexadecimal | Lo mismo, reportado |
| HEX5-HEX4 | Distancia a la persona en decímetros (solo en una tarjeta) | Distancia a la persona en decímetros |

En la tarjeta de la mochila (`biobot.sof`) HEX4 y HEX5 no se usan.

## Estado de las pruebas

Comprobado en simulación con Icarus Verilog (`pwsh -File sim\simular.ps1`):

- `tb_demo`: los cuatro escenarios en una tarjeta terminan como dice la tabla. Con persona, alerta en el
  cuadro 558 (56 s), con 3 estímulos.
- `tb_dos_tarjetas`: las dos tarjetas unidas solo por UART llegan a la alerta en el cuadro 557, y con el
  objeto caliente no alertan.
- Los tres bancos anteriores del núcleo siguen pasando.

Síntesis en Quartus Prime 24.1 sin errores ni advertencias críticas.

Comprobado en las tarjetas físicas el 11 de noviembre de 2026:

| Montaje | Escenario | Resultado medido |
|---|---|---|
| Una tarjeta, modo rápido | Persona | Explorar → acercar → alertar a los 7.4 s; hasta 34 píxeles calientes; distancia de 1.6 a 0.2 m |
| Una tarjeta, modo rápido | Objeto caliente, sin persona | Sin alerta |
| Una tarjeta, modo rápido | No responde | Pasa a reactivar con el LED de avance; sin alerta |
| **Dos tarjetas, tiempo real** | Persona | Enlace vivo; reactivar a los 24.6 s (el insecto se había detenido); acercar a los 26.3 s con 2 píxeles; 8 píxeles a los 54.6 s; confirmar a los 54.7 s; **alertar a los 55.1 s**, cuatro cuadros después; 3 estímulos obedecidos; la tarjeta insecto recibe la alerta. La simulación da 55.6 s |
| **Dos tarjetas, tiempo real** | Objeto a 47.5 °C | Enlace vivo; 0 píxeles calientes aun a 0.2 m; sin alerta en 45 s |
| **Dos tarjetas, tiempo real** | Sin persona | Enlace vivo; un pulso de avance cuando el insecto se detuvo; sin alerta en 75 s |
| **Dos tarjetas, tiempo real** | No responde | Reactivar a los 16 s y a los 49 s, como en la tabla; sin alerta en 75 s |

Falta por probar en físico el montaje C (tarjeta con ESP32 y sensor real).

## Probar sin tocar las tarjetas

Hay una versión de cada circuito con una sonda de Quartus (In-System Sources and Probes) que viaja por el
mismo cable USB-Blaster. Hace lo mismo que la versión normal, y además deja que la computadora lea los LED
y los displays y mueva el reset, SW0 y el escenario. Los interruptores siguen funcionando.

| Tarjeta | Archivo con sonda |
|---|---|
| Mochila (primer cable, USB-0) | `quartus_lab_mochila/output_files/lab_mochila.sof` |
| Insecto (segundo cable, USB-1) | `quartus_lab_insecto/output_files/lab_insecto.sof` |
| Una sola tarjeta | `quartus_lab_demo/output_files/lab_demo.sof` |

Con esas versiones cargadas, desde la carpeta del proyecto:

```
C:\intelFPGA_lite\24.1std\quartus\bin64\quartus_stp -t sim/prueba_tarjetas.tcl 1 110
C:\intelFPGA_lite\24.1std\quartus\bin64\quartus_stp -t sim/prueba_una_tarjeta.tcl 0 1 1 40
```

El primero prueba las dos tarjetas (escenario y segundos); el segundo, una sola (cable, escenario, modo
rápido y segundos). Los dos reinician, arrancan la misión, imprimen cada pocos segundos lo que muestran
las tarjetas y terminan con una línea `RESULTADO`. Si dice `SIN ENLACE`, falta alguno de los tres cables.

`sim/traza_mochila.tcl` hace la prueba con persona leyendo la mochila unas 500 veces por segundo e
imprime cada cambio de estado, de píxeles o de alerta, con su hora. Sirve para ver que la alerta llega
cuatro cuadros después de contar 8 píxeles.

Si algo no coincide con la tabla, anotar el escenario, lo que marcan HEX0 y los LED, y en qué segundo ocurrió.

## Sobre el insecto de prueba

`hdl/insecto_sim.v` no es el modelo científico del proyecto (ese es `modelo/biobot_sim.py`): es un banco
de pruebas en hardware con valores redondos. Camina a 3 cm/s, se detiene de 20 a 33 s de vez en cuando,
obedece tres de cada cuatro estímulos y gira de 15 a 21° por estímulo. El giro real que produce un pulso
de luz no está medido; ese valor solo hace que la escena converja.

## Montaje D: red de tres tarjetas (botón, puente y receptor)

Tres DE10-Lite: dos mochilas (A y B) y el receptor del rescatista. Muestra cómo llega un aviso cuando el
radio no alcanza: otra mochila lo recibe y lo reenvía.

- **Botón.** La persona atrapada sostiene **KEY1** de la mochila medio segundo: la mochila marca «persona
  encontrada» (LEDR9). Sostenerlo evita que un golpe o que el insecto se voltee lo active. KEY0 reinicia.
- **Distancia.** SW9..SW0 de cada mochila dicen a cuántos metros está del receptor, en binario (0 a 1 023 m).
  Los displays HEX3-HEX0 de la mochila la muestran en decimal.
- **Alcance del radio: 100 m.** Una trama solo se acepta si quien la manda está a 100 m o menos de quien
  la recibe. Si A está más lejos, el receptor no la oye; si B está a 100 m o menos de A y del receptor,
  B la reenvía (HEX4 de B muestra `r`, LEDR7 encendido).
- **Confirmación.** Si las dos mochilas avisan y están a 20 m o menos una de otra, el receptor da la
  detección por confirmada y estima la distancia con el promedio de las dos.

| Tarjeta | Archivo |
|---|---|
| Mochila A | `quartus_red_a/output_files/red_a.sof` |
| Mochila B | `quartus_red_b/output_files/red_b.sof` |
| Receptor | `quartus_red_receptor/output_files/red_receptor.sof` |

Cables en JP1 (cada tarjeta transmite por los pines 35 y 33, que llevan la misma señal, y recibe por el 37 y
el 39):

| De | | A | Para qué |
|---|---|---|---|
| A, pin 35 | → | receptor, pin 37 | A habla directo con el receptor |
| A, pin 33 | → | B, pin 37 | A habla con B |
| B, pin 35 | → | receptor, pin 39 | B habla con el receptor |
| A, pin 30 | — | receptor, pin 30 | tierra |
| B, pin 30 | — | receptor, pin 12 | tierra |

Pin 33: columna izquierda, 4.ª fila desde abajo. Pin 39: columna izquierda, la última de abajo. Pin 12:
columna derecha, 6.ª fila desde arriba. Con el cableado del montaje B ya están los cables de A al receptor
y la tierra; solo faltan los tres de B.

Qué muestra el receptor:

| Indicador | Significado |
|---|---|
| LEDR0 | Oye a A directo |
| LEDR1 | Oye a A a través de B (puente) |
| LEDR2 | Oye a B directo |
| LEDR3, LEDR4 | A o B encontró a una persona |
| LEDR8 | Aviso de una sola mochila: posible persona |
| LEDR9 | Aviso de las dos, a 20 m o menos: persona confirmada |
| HEX5 | Quién avisa: `A`, `b`, `C` (confirmada) o `2` (dos avisos lejanos entre sí) |
| HEX4 | Saltos del aviso: 0 directo, 1 por el puente |
| HEX3-HEX0 | Distancia a la persona en metros |

Demostración sugerida: A en 150 m (SW7, SW4, SW2 y SW1 arriba), B en 80 m (SW6 y SW4), A sostiene KEY1 →
el receptor muestra `A 1 0150` con LEDR1 encendido. Bajar B a 300 m (SW8, SW5, SW3 y SW2) → el aviso se
pierde. A en 60 m (SW5, SW4, SW3 y SW2) → `A 0 0060`, directo. B en 55 m (SW5, SW4, SW2, SW1 y SW0) y KEY1
en B → `C 0 0057`, LEDR9 encendido.

Prueba automática por USB con las tres cargadas: `quartus_stp -t sim/prueba_red.tcl` (cada tarjeta dice su
papel por la sonda; sin B hace la prueba de dos tarjetas). En simulación: `tb_red` pasa los cuatro pasos.

### Variante con solo dos tarjetas (la que se probó)

Si no hay tercera tarjeta, la mochila B va dentro del chip del receptor:

| Tarjeta | Archivo | Qué hace |
|---|---|---|
| Mochila A | `quartus_red_a/output_files/red_a.sof` | Igual que arriba: SW = distancia, KEY1 = botón |
| Receptor con B adentro | `quartus_red_rb/output_files/red_rb.sof` | Receptor; además, sus SW son la distancia de B y su KEY1 es el botón de B |

Cables: los mismos del montaje B (A pin 35 → receptor pin 37, y pin 30 con pin 30). Lo que manda A llega al
receptor y a B a la vez; B reenvía por dentro del chip. En el receptor, LEDR7 = B está reenviando, LEDR6 =
B encontró a alguien, LEDR5 = B transmite. La demostración y los displays son los mismos de arriba.

Probado el 11 de noviembre de 2026 en dos DE10-Lite reales con `quartus_stp -t sim/prueba_red.tcl`:

| Paso | Lo que mostró el receptor |
|---|---|
| A en 150 m, B en 80 m, A aprieta el botón | `A 1 0150`: el aviso llegó solo a través de B |
| B se aleja a 300 m | `- - ----`: nadie lleva el aviso, se pierde |
| A se acerca a 60 m | `A 0 0060`: directo |
| B en 55 m aprieta su botón | `C 0 0057`, LEDR9: confirmada por las dos mochilas |

Recursos: cada mochila unos 945 elementos lógicos; el receptor con B adentro, 1 299 (3 % de la FPGA),
124 MHz de frecuencia máxima.
