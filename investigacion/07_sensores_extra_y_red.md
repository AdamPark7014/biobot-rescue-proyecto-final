# 07 — Sensores adicionales, clasificador a bordo y red entre mochilas

Consultado el 11 de noviembre de 2026. **(†)** = cifra vista en un fragmento de búsqueda o en una copia de
terceros de la hoja de datos, no en el PDF oficial. Precios: Digi-Key EE. UU., 1 unidad, 11-11-2026.

## Micrófono MEMS: cabe y casi no gasta

| Modelo | Tamaño (mm) | Consumo | Precio | Fuente |
|---|---|---|---|---|
| TDK T5838 (PDM) | 3.50 × 2.65 × 1.11 | 120 µA (bajo consumo) a 330 µA; despertador acústico de ~20 µA (†) | 2.67 USD | [Digi-Key](https://www.digikey.com/en/products/detail/tdk-invensense/MMICT5838-00-012/16903860), [TDK AN-000278](https://invensense.tdk.com/wp-content/uploads/2022/08/AN-000278-T5838-Flex-EVB-User-Guide-v1.2.pdf) |
| Knowles SPH0641LU4H-1 (PDM) | 3.50 × 2.65 × 1.10 | 235 µA (†) a 1 mA | 3.68 USD | [Digi-Key](https://www.digikey.com/en/products/detail/syntiant/SPH0641LU4H-1/5332438) |
| TDK ICS-43434 (I2S) | 3.50 × 2.65 × 0.98 | 230 a 490 µA (†) | ~2.5 GBP (†) | [Digi-Key](https://www.digikey.com/en/products/detail/tdk-invensense/ICS-43434/6140298) |

- Ningún fabricante publica la masa; por volumen (~9 mm³) se estima en 0.01 a 0.03 g (sin confirmar).
- Lo caro no es el micrófono sino procesar el audio: conviene que el despertador acústico encienda el
  procesador solo cuando hay sonido.

## CO2 y gases: solo uno cabe

- **Sensirion STCC4**: 4 × 3 × 1.2 mm, 400 a 5 000 ppm, ±(100 ppm + 10 %), ~0.95 mA promedio (†)
  ([Sensirion](https://sensirion.com/products/catalog/STCC4)). Es el único sensor de CO2 del tamaño de la mochila.
- **STC31-C** cabe (3.5 × 3 × 1 mm) pero mide de 0 a 100 % vol: no distingue el CO2 que exhala una persona
  ([Sensirion](https://sensirion.com/products/catalog/STC31-C)).
- **SCD41** no cabe: 10.1 × 10.1 × 6.5 mm y ~15 mA ([Sensirion](https://www.sensirion.com/products/catalog/SCD41)).
- Sensores MOX (SGP40, BME688) caben pero no son específicos de un gas; no se encontró uno de amoníaco
  de menos de 0.5 g.

## Lo publicado sobre detección de personas a bordo de un insecto

- **Tran-Ngoc et al., 2023** (*Adv. Intell. Syst.* 5:2200319, [PDF](https://eprints.whiterose.ac.uk/200437/)): misma
  especie, mochila de 5.5 g, cámara térmica Heimann de 32 × 32 (0.99 g, 21.45 mW) y un clasificador HOG + SVM
  a bordo: **87 % de exactitud, 90 % de recall entre 0.5 y 1.5 m**, 18.3 kB de flash, 95 ms por imagen. El
  sistema completo consume 205.5 mW (unas 2.2 h con su batería de 120 mAh).
- **Latif et al., 2016** (*IEEE Sensors J.* 16(10):3444–3453): tres micrófonos direccionales en la mochila para
  localizar una fuente de sonido; según un trabajo posterior, alcance de ~1 m y localización fuera de la mochila
  ([arXiv 2406.03713](https://www.arxiv.org/pdf/2406.03713)). Solo se leyó el resumen.
- **No se encontró** ningún trabajo que combine térmico, sonido y CO2 en un insecto, ni uno que confirme una
  detección por consenso entre varias mochilas. Es la parte nueva que puede aportar el proyecto.

## Clasificador pequeño (TinyML)

- Imagen térmica de 8 × 8 con redes convolucionales pequeñas: 70.5 a 86.3 % de exactitud balanceada, 0.7 a
  5.3 ms y 9 a 69 µJ por inferencia en un STM32L4 ([Xie et al., 2022](https://www.paperswithcode.com/paper/privacy-preserving-social-distance-monitoring)):
  a una imagen por segundo, menos de 0.1 mW.
- Palabra clave en un nRF52840 (Arduino Nano 33 BLE Sense) con Edge Impulse: ~36 kB de RAM, 65 kB de flash,
  78.5 % de exactitud ([Hymel et al., 2022](https://arxiv.org/pdf/2212.03332)). El audio sí cuesta: cientos de
  milisegundos de procesador por segundo de sonido.

## Red y localización

- **Bai et al., 2025** (*Nat. Commun.* 16): 20 cucarachas en enjambre, pero las posiciones venían de cámaras
  externas (VICON); no hubo retransmisión entre insectos ([arXiv](https://arxiv.org/html/2403.17392v3)).
- **Tran-Ngoc et al., 2024**: posición estimada con la IMU por el paso del insecto, error menor de 1 m
  (~5 % de lo recorrido) en una arena de 4.8 × 6.6 m ([arXiv 2406.03713](https://www.arxiv.org/pdf/2406.03713)).
- **NC State** propone mapear con qué mochilas quedan al alcance de radio de otras, más IMU y RSSI; solo
  probado en simulación y con robots ([proyecto](https://research.ece.ncsu.edu/aros/project/cyborg-insect-network/)).
- **Escombro**: la atenuación va de 10 a 100 dB/m y crece con la frecuencia entre 433 MHz y 1.9 GHz
  (Oestges, URSI EMTS 2013) (†); NIST midió de 30 a 80 dB en montones de escombro entre 50 MHz y 1.8 GHz
  ([NIST](https://www.nist.gov/node/789046)) (†). Inferencia: 2.4 GHz, la única banda del nRF52840, penetra
  peor que sub-GHz; por eso la retransmisión entre mochilas importa.

## Qué significa para la mochila

| Sensor | Masa añadida | Consumo añadido | ¿Vale la pena? |
|---|---|---|---|
| Botón | ~0.05 g (sin confirmar) | nada | Sí: no falla con calor ambiente, pero depende de que la persona esté consciente |
| Micrófono T5838 | ~0.02 g (estimado) | 0.12 a 0.33 mA | Sí, como segunda señal y con despertador acústico |
| CO2 STCC4 | bastante menos de 0.5 g (estimado) | ~1 mA (†) | Probable; falta confirmar la masa |
| Cámara 32 × 32 | 0.99 g | 21 mW | No: un tercio del presupuesto de masa |

## Lo que no se pudo confirmar

- La masa de los micrófonos y del STCC4 (no se publica).
- Las cifras del STCC4 (vienen de un resumen de Mouser).
- La precisión de la localización acústica de Latif et al., 2016.
- Errores de trilateración por RSSI medidos bajo escombro real.
- Una comparación medida entre 2.4 GHz y sub-GHz en escombro.
