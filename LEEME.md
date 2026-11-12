# BioBot-Rescue — proyecto final de Sistemas Embebidos (O26-LRT3032-2)

Equipo: Roberto Orozco Ramírez (184595), Adam Del Pozo Ontiveros (185611) y Enrique Bernal Martín Prieto (184878).

**Qué es:** una mochila electrónica de menos de 3 g que convierte a una cucaracha de Madagascar en un
buscador de personas atrapadas. Detecta calor, decide sola cuándo estimular al insecto y avisa por radio.

**Qué hay aquí:** la investigación con fuentes, el modelo completo con su simulación, el circuito en Verilog
ya verificado y sintetizado, el esquema de investigación en PDF y la presentación.

## Entregables

| Qué | Dónde |
|---|---|
| Esquema de investigación (PDF) | `Esquema_Investigacion_BioBot-Rescue.pdf` |
| Resumen de una página | `BioBot-Rescue_en_una_pagina.pdf`: cómo funciona, cómo se prueba con dos DE10-Lite y la mochila real con pesos y costos |
| Presentación | https://claude.ai/artifact/C9tMwMu5J31PDZcERo8Ek3 (privada; se comparte o se exporta a PowerPoint o PDF desde la propia página). Fuentes en `presentacion/` |
| Guía para probar en la DE10-Lite | `GUIA_LABORATORIO.md`: qué `.sof` cargar, cableado, interruptores y qué debe verse |
| Investigación con fuentes | `investigacion/01` a `07` (la 07: micrófono, CO2, clasificador a bordo y red entre mochilas) |
| Simulación de misión | `modelo/` |
| Núcleo en Verilog | `hdl/`, bancos de prueba en `sim/`, proyecto de Quartus en `quartus/` |

## Carpetas

- `investigacion/` — seis notas con cada dato, su fuente, su nivel de confianza y las contradicciones
  entre fuentes: biología, estimulación, hardware, búsqueda y rescate, ética y normativa, y parámetros de marcha.
- `modelo/`
  - `parametros.py` — todos los parámetros con su origen: `[F]` publicado, `[D]` decisión de diseño, `[S]` supuesto.
  - `biobot_sim.py` — simulación de agentes: marcha, respuesta al estímulo, habituación, detección térmica y las cuatro políticas.
  - `experimentos.py` — lote de Monte Carlo; escribe `resultados.json`.
  - `politica_ref.py` — modelo de referencia con enteros, idéntico registro por registro al Verilog; genera los vectores de prueba.
  - `figuras.py`, `diagramas.py`, `ilustracion.py`, `estilo.py` — todas las figuras, los números y las tablas del PDF.
- `hdl/` — `ventana_termica.v`, `detectores.v`, `fsm_politica.v`, `gen_estimulo.v`, `nucleo_biobot.v`,
  `enlace_serie.v`, `top_biobot_de10lite.v`, y `uart_rx.v` / `uart_tx.v` de la práctica 4.
  Para probar solo con tarjetas (11 de noviembre): `insecto_sim.v` (insecto y escena de prueba),
  `top_demo_de10lite.v` (todo en una tarjeta) y `top_insecto_de10lite.v` (segunda tarjeta, en lugar del ESP32).
  `top_lab_sondas.v` envuelve los tres circuitos con una sonda de Quartus para leerlos y manejarlos por el cable USB.
- `sim/` — `tb_nucleo.v`, `tb_gen_estimulo.v`, `tb_top.v`, `tb_demo.v`, `tb_dos_tarjetas.v` y `simular.ps1`.
  Para las tarjetas reales: `prueba_tarjetas.tcl` (dos tarjetas), `prueba_una_tarjeta.tcl` y `traza_mochila.tcl`;
  se corren con `quartus_stp -t` como explica `GUIA_LABORATORIO.md`.
- `quartus_demo/` y `quartus_insecto/` — proyectos de las dos tarjetas nuevas, con su `.sof` en `output_files/`.
- `quartus_lab_mochila/`, `quartus_lab_insecto/` y `quartus_lab_demo/` — los mismos circuitos con la sonda;
  son los que quedaron cargados en las tarjetas el 11 de noviembre.
- Red de mochilas (botón, puente y receptor; `GUIA_LABORATORIO.md`, montaje D): `hdl/red_mochilas.v`,
  `hdl/top_lab_red.v` (una tarjeta por nodo) y `hdl/top_lab_red_rb.v` (receptor con la mochila B adentro,
  para hacerlo con dos tarjetas); proyectos `quartus_red_a`, `quartus_red_b`, `quartus_red_receptor` y
  `quartus_red_rb`; banco `sim/tb_red.v` y prueba por USB `sim/prueba_red.tcl`. Probado el 11-11 en dos
  DE10-Lite: los cuatro pasos correctos.
- `activehdl/` — macros para abrir el proyecto en Active-HDL: en su consola,
  `do ".../activehdl/crear_workspace.do"` crea el espacio de trabajo; después `compilar.do`,
  `simular_demo.do` y `simular_dos_tarjetas.do`.
- `esp32/mochila_esp32/` — programa del ESP32 DevKit V1. Manda a la tarjeta diez cuadros térmicos por
  segundo y muestra en el monitor serie (115 200 baudios) el estado que contesta el núcleo. Con
  `USAR_SENSOR 0` genera una escena sintética con un insecto simulado que obedece los estímulos: sirve
  para demostrar el núcleo solo con el ESP32 y la DE10-Lite, sin comprar nada. Con `USAR_SENSOR 1` lee
  una AMG8833 real por I2C. Cableado igual al de la práctica 4 (GPIO17 → UART_RX, GPIO16 ← UART_TX, tierra común).
- `quartus/` — proyecto para la DE10-Lite (10M50DAF484C7G); el `.sof` queda en `quartus/output_files/biobot.sof`.
- `latex/` — fuentes del PDF; `latex/figs/` se genera, no se edita a mano.
- `referencia/` — el reporte SO-4 que el equipo entregó el 4 de noviembre.

## Cómo reproducir

```powershell
# Bancos de prueba (Icarus Verilog 12 en C:\iverilog\bin)
pwsh -File sim\simular.ps1

# Simulación de misión (cerca de dos horas en esta laptop; rehace resultados.json)
cd modelo; python experimentos.py
python experimentos.py solo faro   # solo añade los casos del faro al estudio del regreso (unos 20 min)

# Figuras, números y PDF
pwsh -File compilar.ps1            # figuras + PDF
pwsh -File compilar.ps1 -SoloPdf   # solo el PDF
pwsh -File compilar_hoja.ps1       # la hoja de una página

# Síntesis
& 'C:\intelFPGA_lite\24.1std\quartus\bin64\quartus_sh.exe' --flow compile quartus\biobot

# Programa del ESP32 (añadir --upload -p COMx para cargarlo)
& 'C:\Program Files\Arduino CLI\arduino-cli.exe' compile --fqbn esp32:esp32:esp32doit-devkit-v1 esp32\mochila_esp32
```

Para la demostración sin sensor: cargar `quartus/output_files/biobot.sof` en la DE10-Lite, cargar el
programa del ESP32, cablear como en la práctica 4, abrir el monitor serie y subir SW0. Los LED muestran el
estado, HEX0 el estado en número, HEX3-HEX2 los píxeles calientes y KEY0 reinicia la misión.

## Estado al 11 de noviembre de 2026

Hecho y comprobado:

- Núcleo en Verilog: `tb_nucleo` 11 424 de 11 424 cuadros idénticos al modelo de referencia, con los ocho
  estados visitados; `tb_gen_estimulo` 3 de 3 trenes (25 periodos de 20.000 ms); `tb_top` 500 de 500
  respuestas por UART.
- Síntesis en Quartus Prime 24.1: 722 elementos lógicos, 372 registros, 43 pines, 72.08 MHz, holgura de
  6.13 ns a 50 MHz, sin advertencias críticas. El núcleo solo: 477 elementos lógicos y 224 registros.
- Simulación de misión validada contra la marcha publicada (sección 6.1 del PDF) y lote completo de
  experimentos: políticas, tamaño del enjambre, sensor, habituación, sensibilidad, resultado por colapso y
  enjambre mixto. Resultado principal con diez insectos: la detección en una hora sube de 58 % sin
  estímulos a 73 % con la política guiada (320 misiones por caso, margen de ±5 puntos).
- Lo que la simulación dice en contra, y que conviene presentar tal cual: la mejora depende del colapso
  (en tres de ocho cambia el resultado, en cuatro da igual y **en uno guiar empeora, de 98 a 52 %**);
  girar hacia el calor casi no añade a explorar bien; y dosificar no mejora la detección, solo reduce los
  estímulos a un tercio. Un enjambre mixto, cinco pasivos y cinco guiados, conserva el promedio y evita
  el caso malo, pero el núcleo todavía no tiene modo de solo detección.
- Programa del ESP32: compila en sus dos modos (300 591 y 295 620 bytes).
- Prueba solo con tarjetas (11 de noviembre). Una tarjeta: `biobot_demo.sof`, 1 015 elementos lógicos,
  73.4 MHz; `tb_demo` pasa sus cuatro escenarios y con persona alerta en el cuadro 558 (56 s). Dos tarjetas:
  `biobot_insecto.sof`, 799 elementos lógicos, 65.0 MHz; `tb_dos_tarjetas` llega a la alerta por UART en el
  cuadro 557 y no alerta con el objeto caliente. Síntesis sin errores ni advertencias críticas.
- **Prueba en las tarjetas físicas (11 de noviembre).** Una DE10-Lite: con persona alerta a los 7.4 s en
  modo rápido y no alerta en los otros escenarios. Dos DE10-Lite unidas por tres cables, en tiempo real:
  con persona, acercar a los 26.3 s, 8 píxeles a los 54.6 s y **alerta a los 55.1 s** (la simulación da
  55.6 s); con el objeto a 47.5 °C, sin persona y con el insecto que no responde, sin alerta. La tabla
  completa está en `GUIA_LABORATORIO.md`.
- Regreso de los insectos (simulación, sección 6.7 del PDF; 3 200 insectos por caso tras 45 min de búsqueda):
  solo un refugio en la entrada recoge 76 % en dos horas; guiarlos a ciegas, 66 a 67 % (peor que esperar); un
  faro infrarrojo en la entrada que la mochila sigue con dos fotodiodos, 91 % si se percibe hasta 6 m. Ningún
  método recupera a todos, el faro es un supuesto sin medir y su modo no está en el Verilog.

No hecho:

- El programa del ESP32 **compila en sus dos modos, pero no se ha probado en hardware**: ni contra la
  tarjeta ni contra una AMG8833. El orden de los píxeles del sensor depende de cómo se monte; si la
  mochila gira al lado contrario, hay que espejear las columnas.
- No existe el programa de la computadora que conecta la simulación de misión con la tarjeta (circuito
  en el lazo completo). El modo de escena sintética del ESP32 es una versión reducida de eso.
- El área en SKY130 es una estimación por conteo de celdas; no se corrió el flujo de SKY130.
- No se compró nada. Para la demostración faltan la matriz térmica AMG8833 (599 MXN) y los LED ultravioleta (281 MXN).
- No se hizo ninguna prueba con insectos.
- **No se entregó nada en Blackboard.** «Reporte Proyecto Final y práctica 5» vence el 2 de diciembre de
  2026 a las 23:59 y tiene un solo intento.

## Lo que este trabajo corrige de los documentos anteriores del equipo

| Decía | Lo que sostienen las fuentes |
|---|---|
| El insecto carga 15 g | Con 15 g se detiene por completo; con 4 g ya camina peor. Meta: 2 a 3 g |
| El insecto pesa 10 a 15 g | Macho adulto: 6.3 ± 1.5 g |
| Camina a 0.3 m/s | De 2 a 9 cm/s; 0.3 m/s es diez veces más |
| Umbral fijo de 35.5 a 38.5 °C | Es temperatura central. La piel está entre 27 y 35 °C y un sensor de un punto, a medio metro, lee casi el fondo |
| Menos de 60 celdas y un dado de 1 mm² | 224 registros y unas 450 celdas combinacionales: cerca de 0.014 mm² |
| Menos de 12 dólares por unidad | Unos 55 dólares con piezas de mostrador en México |

Conviene decirlo en el reporte final como evolución del diseño, no ocultarlo.

## Datos que no se pudieron leer en la fuente original

Están marcados en `investigacion/` y aquí se resumen para no citarlos con más fuerza de la que tienen:

- Supervivencia por día en Kobe (80 %, 30 %, casi cero): viene de Kawata (1996) a través de una cita secundaria.
- Casco de luz ultravioleta de Osaka (Refat et al., 2025): solo resumen y nota de prensa. El ángulo de
  giro por pulso no está publicado; es el dato que más falta.
- Un mes sin comida ni agua (Yoder y Grojean, 1997): solo el resumen.
- El origen de los «15 g» es una fuente de 2016 que no se pudo leer.
- Las fuentes no coinciden en el sentido del giro al estimular un cerco: hay que medirlo.

## Dos hallazgos que cambian el proyecto

1. **El profesor es coautor de un artículo sobre esta misma especie** (Gracidas-Reyes, Diaz-Arango,
   Vazquez-Leal y Marroquin-Gutierrez, *Biology*, 2026): caminadora esférica con control de temperatura y
   ensayos de luz con la colonia de la UDLAP. De ahí salen la ventana de 22 a 30 °C y la elección de la
   luz ultravioleta como estímulo. Esa plataforma permitiría medir el dato que falta.
2. **La Ley General de Vida Silvestre** trata a la especie como exótica y solo permite manejarla en
   confinamiento (artículos 27 y 122). Las pruebas son en recinto cerrado; un despliegue real en escombros
   requeriría una autorización que hoy no existe. Está dicho en el PDF y en la presentación.

## Imágenes

Todas las figuras son propias: se generan con `modelo/figuras.py`. No se descargó ninguna fotografía.
