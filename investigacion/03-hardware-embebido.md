# 03 — Hardware embebido que cabe en la mochila

Investigación del 9 de noviembre de 2026. Ángulo: masa, tamaño, consumo y capacidad de cada componente
que una cucaracha silbadora de Madagascar (*Gromphadorhina portentosa*, adulto de 6–8 g) puede cargar,
y qué han montado otros grupos.

**Cómo leer este documento**

- Confianza **Alta**: leí el número en la hoja de datos o en el artículo (texto extraído del PDF o de la página).
- Confianza **Media**: página del fabricante vista a través de un resumen, o una sola fuente primaria.
- Confianza **Baja**: distribuidor, prensa, o valor **estimado** por mí (se indica cómo).
- «n/r» = no reportado por la fuente. «Sin verificar» = no pude abrir la fuente en esta sesión.
- Las masas de circuitos integrados casi nunca vienen en la hoja de datos. Donde aparece «est.» la calculé
  como volumen del encapsulado × densidad (silicio 2.33 g/cm³ para WLCSP; ~2 g/cm³ para QFN/LGA moldeados).
  Sirven para sumar presupuestos, no para citarlas como dato.

**Límite de esta investigación.** A media tarea se agotó la cuota de búsquedas web de la sesión. Desde ese
punto solo pude abrir direcciones que ya conocía (hojas de datos, DOI, páginas de fabricante). Lo que quedó
sin verificar está listado en «Contradicciones y huecos»; no lo rellené de memoria.

---

## Respuesta corta

1. **La mochila de referencia para esta especie pesa 5.5 g y dura 2.2 h.** Tran-Ngoc et al. (NTU, 2023)
   montaron microcontrolador MSP432, radio CC1352 (BLE), cámara térmica Heimann 32×32 (0.99 g), IMU y una
   LiPo de 120 mAh (2.5 g) con un consumo total medido de 205.5 mW. Es la única mochila publicada para
   *G. portentosa* con detección de personas a bordo. La generación 2025 del mismo grupo (Lin et al.) bajó a
   **2.3 g con 50 mAh** y radio sub-1 GHz, pero sin sensor de personas.
2. **La batería manda en la masa; el sensor térmico manda en la energía.** En la mochila de 5.5 g la batería es
   el 45 % y la cámara térmica el 18 %. En consumo, la matriz térmica (21 mW) y la IMU antigua (11.5 mW)
   son cargas permanentes; el clasificador (24 mW) solo consume mientras calcula (95 ms por cuadro).
3. **Radio: nRF52 sí, ESP32-C3 no.** El nRF52840 transmite a 0 dBm con 6.4 mA; el módulo ESP32-C3-MINI-1 pide
   170 mA de pico para el mismo 0 dBm en BLE y 335–350 mA en Wi-Fi. Con una celda de 25–50 mAh eso descarta al
   ESP32-C3 salvo para un prototipo de mesa.
4. **Una FPGA sí cabe (2–6 mg el chip, estimado), pero no hace falta para detectar personas.** iCE40 UltraPlus UP5K:
   2.15 × 2.55 mm, 75 µA en reposo. El clasificador de NTU (HOG + SVM lineal) corre en un microcontrolador con
   18.3 kB de flash y 95 ms por cuadro. La FPGA se justifica como pieza didáctica o como paso previo al silicio.
5. **Bajo escombro conviene sub-GHz.** Con el modelo ITU-R P.2040 el concreto atenúa ~22 dB/m a 915 MHz,
   ~47 dB/m a 2.4 GHz y ~105 dB/m a 6.5 GHz (UWB). NIST midió hasta ~90 dB en 305 mm a 8 GHz, más del doble de
   lo que predice el modelo: el concreto real y húmedo es peor.
6. **Las dos afirmaciones del reporte del equipo no se sostienen como están escritas.** «Menos de 60 celdas»
   no alcanza para promedio móvil + comparador + UART (un transmisor UART solo ya ronda 55–75 celdas);
   lo creíble es **130–250 celdas lógicas**. «Dado de 1.0 × 1.0 mm» es físicamente posible pero engañoso:
   la lógica ocupa ~0.005–0.011 mm² (cerca del 1 % de ese dado) y ningún servicio abierto de 2026 vende un dado
   propio de 1 mm²; lo real es **un tile de Tiny Tapeout (160 × 100 µm)**.

---

## Hallazgos

### A. Mochilas publicadas

| Grupo, año | Especie (masa) | Masa total | Dimensiones | Microcontrolador y radio | Batería | Autonomía | Sensores | Consumo | Fuente | Confianza |
|---|---|---|---|---|---|---|---|---|---|---|
| NTU (Sato) — Tran-Ngoc et al., 2023 | *G. portentosa* macho, 5.7 ± 0.6 cm, 6.32 ± 1.5 g | **5.5 g** con batería | Robot ≈1.5 cm alto × 5.7 cm largo; tarjeta n/r (escala de 1 cm en Fig. 1b) | TI MSP432P4011 (Cortex-M4F, 48 MHz, 2 MB flash, 256 kB SRAM) + TI CC1352 (BLE 5.1, 2.4 GHz) | LiPo 3.7 V, **120 mAh, 10 × 15 mm, 2.5 g** | **hasta 2.2 h** | Heimann HTPA 32×32 (8×8×5 mm, 0.99 g, 21.45 mW medio, 8 µW dormido, 90°×90°); MPU9250 (11.55 mW); BME280; CCS811; flash MX25R1635F | **205.5 mW** total; detección de personas 24 mW al 100 % | Adv. Intell. Syst. 5, 2200319, §1, §2.3 y Sección Experimental | Alta |
| NTU (Sato) — Lin et al., 2025 | *G. portentosa* macho, 5–7 cm, 6–8 g | **2.3 g** | n/r | Microcontrolador no nombrado; radio **sub-1 GHz** | LiPo 3.7 V, **50 mAh**; masa n/r | n/r | Ninguno a bordo (control de locomoción) | n/r | Nat. Commun. 2025, DOI 10.1038/s41467-025-60779-1 (texto en PMC12304280) | Alta |
| Osaka / Hiroshima / NTU — Bai et al., 2025 | *G. portentosa* (20 individuos) | n/r en el texto principal | n/r | «módulo de comunicación inalámbrica» sin modelo; posición por captura de movimiento externa | LiPo recargable, capacidad n/r | n/r | Sin IMU ni UWB a bordo (se proponen como trabajo futuro) | n/r | Nat. Commun. 16 (2025), DOI 10.1038/s41467-024-55197-8; arXiv 2403.17392 | Alta (para lo que **no** reporta) |
| RIKEN / Waseda / NTU — Kakei et al., 2022 | Cucaracha de Madagascar, ~6 cm | n/r en la nota de RIKEN | Celda solar de **0.004 mm** de espesor sobre el abdomen; mochila impresa en 3D sobre el tórax | Módulo inalámbrico de control (modelo sin verificar) | LiPo; carga en 30 min con luz solar simulada | n/r | — | Celda solar orgánica: **17.2 mW** | npj Flex. Electron. 6, 78; nota de prensa de RIKEN (05-09-2022) | Media (no pude abrir el artículo) |
| NC State (Bozkurt) — Latif y Bozkurt, 2012 | *G. portentosa* | **4 g** (tarjeta ~1 g + batería 3 g) | PCB rígido delgado | PIC16F630 + receptor FSK IA4320 (banda ISM) | LiPo **90 mAh, 3 g** | n/r | — | n/r | EMBC 2012, «Line Following Terrestrial Insect Biobots», §II.C | Alta |
| NC State — versión ligera, 2012 | *G. portentosa* | **0.5 g** (sin batería, según el texto) | n/r | TI CC2530 (SoC 8051 + radio 802.15.4/ZigBee) | n/r | n/r | Monitoreo de la interfaz electrodo-tejido con los ADC | n/r | Mismo artículo, §II.C | Alta |
| NC State — Whitmire, Latif y Bozkurt, 2014 | *G. portentosa* | n/r (batería de 0.5 g según prensa) | «tamaño de una moneda» (prensa) | CC2530 | LiPo 3 V (prensa) | n/r | 3 micrófonos direccionales + preamplificadores, muestreo ~2 kHz | **36 mW** solo para transmitir audio (citado por Tran-Ngoc 2023) | Resumen HDIAC/DTIC; Popular Science; cita en Tran-Ngoc 2023 §1 | Baja (no leí el artículo original) |
| Backyard Brains RoboRoach | *Blaberus discoidalis* (recomendada) | **4.4 g** con batería | n/r | BLE (chip no declarado) | Pila de botón 1632 | «más de un mes» por pila | — | n/r | docs.backyardbrains.com (fabricante) | Media |
| Texas A&M — Sanchez et al., 2015 | *B. discoidalis* | n/r (no pude abrir el texto) | n/r | Microcontrolador + receptor (prensa) | n/r | n/r | Estimulación de ganglio protorácico; 60 % de repetibilidad | n/r | J. R. Soc. Interface 12, 20141363 | Baja |
| U. Washington — Iyer et al., 2020 | Escarabajos (*death-feigning* y Pinacate); cargan >0.5 g | **248 mg** (prensa) / «~250 mg» (UW) | n/r | BLE, alcance hasta 120 m | **10 mAh** | 1–2 h transmitiendo; ≥6 h si el acelerómetro dispara la captura | Cámara monocromática orientable (brazo de 60°), 1–5 cuadros/s | n/r | Sci. Robot. 5, eabb0839 (resumen); nota de UW ECE | Media |
| U. Queensland — ZoBorg, 2025 | *Zophobas morio*, 750–950 mg, 25–32 mm | Mochila **160 mg**; batería aparte **680 mg** | 15.8 × 5.8 mm | ATtiny85V + receptor infrarrojo TSOP37238 (sin radio) | LiPo **25 mAh, 4 × 8 × 8 mm, 680 mg** | n/r | — | n/r | Adv. Sci. 2025, DOI 10.1002/advs.202502095 (texto en PMC12376601) | Alta |

**Lecturas de la tabla**

- **Carga útil.** Tran-Ngoc cita 15 g de carga máxima y Lin dice que tras su mochila de 2.3 g quedan
  «~12.7 g» de capacidad. Pero Latif y Bozkurt (2012) escriben que, aunque la especie carga «más de 5 g»,
  el peso de la mochila de 4 g «afectó adversamente» la respuesta a la estimulación y solo el 10 % de los
  recorridos en S se completó; con la versión ligera la velocidad subió. Kakei reporta que películas más gruesas
  duplicaron el tiempo de recorrido. **Poder cargar 15 g no es lo mismo que caminar bien con 5 g.**
- **Tendencia del grupo de Sato:** 5.5 g (2023, con sensores) → 2.3 g (2025, sin sensores). La reducción vino de
  quitar la cámara térmica y pasar de 120 a 50 mAh.
- **Densidad de tarjeta ensamblada como ancla:** ZoBorg mide 160 mg en 15.8 × 5.8 mm → 0.17 g/cm²
  (tarjeta sencilla con ATtiny85 y receptor IR).

### B. Microcontrolador y radio

| Componente | Tamaño | Masa | Consumo activo | Consumo en reposo | Interfaz / notas | Precio | Fuente | Confianza |
|---|---|---|---|---|---|---|---|---|
| Nordic **nRF52832** (chip) | aQFN48 6 × 6 mm; **WLCSP50 3.0 × 3.2 mm** | n/p; ~11 mg est. (WLCSP) | TX 5.3 mA a 0 dBm; 7.5 mA a +4 dBm; RX 5.4 mA (DC/DC, 3 V); CPU 58 CoreMark/mA | 0.3 µA sin retención; 1.2 µA periféricos en reposo; 1.6 µA con RTC | BLE 5, ANT, NFC; 1.7–3.6 V | n/v | Nordic, nRF52832 product brief | Alta |
| Nordic **nRF52840** (chip) | aQFN73 7 × 7 mm; **WLCSP94 3.5 × 3.6 mm** | n/p; ~15 mg est. (WLCSP), ~100 mg est. (aQFN) | TX **6.40 mA a 0 dBm**, 16.40 mA a +8 dBm; RX 6.26 mA (DC/DC, 3 V) | 0.4 µA System OFF; 0.97 µA System ON sin RAM; 3.16 µA con RAM completa y RTC | BLE 5 (incl. 125 kbps), 802.15.4, USB; 1 MB / 256 kB; 1.7–5.5 V | n/v | Nordic, nRF52840 SoC PB v2.3 | Alta |
| Seeed **XIAO nRF52840** (tarjeta) | 21 × 17.8 mm | **n/p** por Seeed | n/p | «menos de 5 µA» en espera | Cargador LiPo 50/100 mA; antena integrada | US$9.90 | wiki y tienda de Seeed | Media |
| Espressif **ESP32-C3** (chip) | QFN32 5 × 5 mm | n/p; ~50 mg est. | Wi-Fi TX **335 mA** pico (802.11b, 21 dBm); RX 84–87 mA; modem-sleep 13–28 mA | Light-sleep 130 µA; deep-sleep **5 µA**; apagado 1 µA | RISC-V 160 MHz; Wi-Fi 4 + BLE 5 | n/v | Hoja de datos v2.4, Tablas 5-7 a 5-9 | Alta |
| Espressif **ESP32-C3-MINI-1** (módulo) | 13.2 × 16.6 × 2.4 mm (MINI-1U: 13.2 × 12.5 × 2.4) | n/p; ~0.8–1.0 g est. | **BLE TX pico: 170 mA a 0 dBm, 190 mA a 9 dBm, 340 mA a 20 dBm; BLE RX 86 mA**; Wi-Fi TX 350 mA | Igual que el chip | 4 MB flash | n/v | Hoja de datos del módulo v2.2, Tablas 6-4 y 6-5 | Alta |
| Seeed **XIAO ESP32C3** (tarjeta) | 21 × 17.8 mm | n/p por Seeed; un distribuidor lista «4 g» (probablemente con empaque) | Wi-Fi activo 75 mA; modem-sleep 25 mA (Wi-Fi) / 27 mA (BLE); light-sleep 4 / 10 mA | Deep-sleep **44 µA** (9 veces el chip solo) | Cargador LiPo | US$4.90 | wiki de Seeed; Pimoroni (masa) | Media / Baja la masa |
| **ESP32-C3 SuperMini** (genérica) | ~22.5 × 18 mm | **no encontrada** | Como el chip | «43 µA» solo si se quita el LED; medidas de terreno 100–500 µA y 0.6–1.5 mA en la variante con LED RGB | Sin cargador | n/v | Blog Mischianti (terreno) | Baja |
| TI **CC2640R2F** | **DSBGA34 2.7 × 2.7 mm**; VQFN 4×4, 5×5, 7×7 | n/p; ~8 mg est. (DSBGA) | RX 5.9 mA; TX 6.1 mA a 0 dBm, 9.1 mA a +5 dBm; CPU 61 µA/MHz | Standby 1.1 µA; shutdown 100 nA | BLE | n/v | TI SWRS204C (rev. sep-2020) | Alta |
| TI **CC1352R** (el de NTU 2023) | VQFN48 7 × 7 mm | n/p; ~100 mg est. | RX 5.8 mA (868 MHz) / 6.9 mA (2.4 GHz); TX 0 dBm 8.0 / 7.1 mA; **TX +14 dBm 24.9 mA (868 MHz)**; CPU 2.9 mA a 48 MHz | Standby 0.85 µA; shutdown 150 nA | Sub-1 GHz + 2.4 GHz en un chip | n/v | TI SWRS196I (rev. feb-2021) | Alta |
| Microchip **ATtiny85/V** (el de ZoBorg) | SOIC8, QFN20 | n/p | 300 µA a 1 MHz y 1.8 V | 0.1 µA a 1.8 V | **Sin radio** | n/v | Atmel 2586Q (08/2013) | Alta |
| STM32L0 / STM32WB | — | — | — | — | — | — | **Sin verificar** (st.com no respondió) | — |

**Lo que decide:**

- **ESP32-C3 con radio encendido no es viable en la mochila.** 170 mA de pico en BLE a 0 dBm contra 6.4 mA del
  nRF52840: 27 veces más. Una celda de 25 mAh con resistencia interna de varios ohmios se cae de voltaje con
  picos así. Además el reposo real de las tarjetas (44 µA en la XIAO; cientos de µA en las SuperMini) queda muy
  por encima de los 5 µA del chip. Sirve para la maqueta de mesa alimentada por USB.
- **Las cifras «de catálogo» de Nordic cambiaron entre revisiones.** Ver contradicciones.
- **Masa de las tarjetas XIAO y SuperMini: ningún fabricante la publica.** Hay que pesarlas. Estimación propia para
  una XIAO (PCB 3.7 cm² + blindaje + USB-C): 1.5–2.5 g, es decir, **la tarjeta de desarrollo sola ya consume la
  configuración «mínima»**. La mochila real exige PCB propio con el chip soldado.

### C. FPGA ultraligeras

| Dispositivo | LUT / lógica | Memoria | Encapsulado más chico | Masa (est.) | Corriente estática | Consumo típico | Precio | Fuente | Confianza |
|---|---|---|---|---|---|---|---|---|---|
| Lattice **iCE40 UltraPlus UP5K** | 5,280 LUT4; 8 DSP 16×16 | 120 kbit EBR + **1,024 kbit SPRAM** | **WLCSP 30 bolas, 2.15 × 2.55 mm**, paso 0.4 mm, 21 E/S (también QFN48 7×7) | ~6 mg | **75 µA** | «1–10 mA activos en la mayoría de las aplicaciones» | ~US$8–10 (agregadores, sin confirmar) | Página de producto de Lattice (hoja FPGA-DS-02008 v2.4, 2025) | Alta (precio Baja) |
| Lattice iCE40 UltraPlus UP3K | 2,800 LUT4; 4 DSP | 80 kbit + 1,024 kbit SPRAM | WLCSP 30, 2.15 × 2.55 mm | ~6 mg | 75 µA | — | n/v | Ídem | Alta |
| Lattice **iCE40 UltraLite UL1K** | 1,248 LUT4 | 56 kbit EBR | **WLCSP 16 bolas, 1.4 × 1.4 × 0.45 mm**, paso 0.35 mm, 10 E/S; ucBGA36 2.5×2.5 | ~2 mg | **35 µA** | — | ~US$2.6–4 (agregadores, sin confirmar) | Página iCE40 Ultra / UltraLite de Lattice | Alta (precio Baja) |
| Lattice iCE40 UltraLite UL640 | 640 LUT4 | 56 kbit | WLCSP 16, 1.4 × 1.4 mm | ~2 mg | 35 µA | — | n/v | Ídem | Alta |
| Lattice iCE40 Ultra (iCE5LP1K/2K/4K) | 1,100 / 2,048 / 3,520 | 64 / 80 / 80 kbit | WLCSP 36, 2.08 × 2.08 mm | ~4 mg | 71 µA | — | n/v | Ídem | Alta |
| Lattice iCE40 LP384 / LP1K | 384 / 1,280 celdas | — | WLCSP 16 de 1.40 × 1.48 mm; ucBGA36 2.5 × 2.5 mm | ~2 mg | 21 µA (LP384); 100 µA (LP1K) | — | n/v | Página iCE40 LP/HX (vía resumen) | Media |
| Gowin **GW1NZ-1** (LittleBee) | 1,152 LUT4; 864 FF | 72 kbit BSRAM; 64 kbit flash de usuario | **CS16 1.8 × 1.8 mm** (11 E/S); CG25 1.8 × 1.8 (20 E/S); FN32 4×4 | ~3.5 mg | Versión LV: **3 mA** en núcleo (1.2 V) + 0.5 mA VCCX. Versión ZV (0.9 V): decenas de µA (la tabla lista 30–50 µA; la asignación por grado no salió limpia del PDF) | — | n/v | Gowin DS841-2.8E (04/2026), Tablas 3-9 y 3-10 | Alta (LV), Media (ZV) |
| Renesas **ForgeFPGA SLG47910** | 1,120 LUT5; 1,120 FF | 5 kbit distribuida + 32 kbit BRAM | **WLCSP 20, 1.85 × 1.64 × 0.47 mm** (16 E/S); STQFN24 3×3×0.55 | ~3 mg | Reposo total no extraído; BRAM inactiva 5.76 µA; oscilador de 50 MHz 422 µA | Núcleo 47 mA a 100 MHz con 90 % de utilización (caso «power virus») | n/v (el «menos de US$0.50» no lo pude confirmar) | Renesas R19DS0120EU0106 Rev 1.06 (nov-2026), §3.3.6 | Alta |
| Efinix **Trion T8** (T4: 3,888 LE) | 7,384 LE; 8 multiplicadores | 122.88 kbit | **FBGA49 3 × 3 mm** (paso 0.4); FBGA81 5×5 | ~15 mg | «Menos de 150 µA típicos de fuga del núcleo a 1.1 V» (F49/F81) | — | n/v | Efinix DST8-v5.5 | Alta |
| QuickLogic **EOS S3** | Cortex-M4F + eFPGA de 891 celdas («2,400 efectivas») | 64 kbit | **WLCSP 42, 2.66 × 2.42 × 0.51 mm**; BGA64 3.5×3.5 | ~8 mg | Standby 17.5–20.7 µA (SRAM de 32 kB en sueño profundo) | M4: 75–84 µA/MHz | n/v | QuickLogic, hoja v3.3d, Tabla 48 | Alta |
| Microchip **IGLOO nano AGLN010** | 260 VersaTiles (10 k compuertas); sin PLL ni RAM | — | UC36 3 × 3 mm, 23 E/S | ~10 mg | **Sin verificar** (el «2 µW en Flash\*Freeze» no lo confirmé) | — | n/v | Microsemi DS0110 rev. 20 (vía resumen) | Media |
| Intel/Altera **MAX 10 10M02** | 2,000 LE | 108 kbit | V36 WLCSP «3 × 3 mm» (cuerpo real 3.396 × 3.466 mm según aviso de Intel) | ~12 mg | **Sin verificar** | — | n/v | Intel, vista general MAX 10 (vía resumen) | Media |

**Tarjetas mínimas y su masa**

| Tarjeta | FPGA | Tamaño | Masa | Fuente | Confianza |
|---|---|---|---|---|---|
| Fomu | iCE40UP5K-UWG30 | PCB 9.4 × 13 × 0.6 mm | n/p. Mouser lista 7.15 g para un clon (peso de envío, no del PCB). Estimado propio: 0.2–0.3 g | Guía de taricorp (terreno); Mouser | Baja |
| UPduino v3.x | iCE40UP5K-SG48 | — | **no encontrada** | — | — |
| TinyFPGA BX | iCE40LP8K | — | **no encontrada** | — | — |
| iCESugar-nano | iCE40LP1K | — | **no encontrada** | — | — |

**¿Existe un diseño de referencia de presencia humana por debajo de 1 mW?** Con matices:

- El diseño **Human Presence Detection** de Lattice sensAI para iCE40 UltraPlus declara **7 mW** con entrada de
  64 × 64 × 3 y hasta 8 cuadros/s. La misma página dice que se puede bajar a «unos pocos mW» intercambiando
  velocidad por consumo, y la versión japonesa de la página dice 1 mW. Lattice lo marca
  **«Support Discontinued — For Reference Only»** (Radiant 1.1).
- La página de producto del UltraPlus sí afirma «menos de 1 mW» pero para **detección de rostro** y **detección
  de frase clave**, sin condiciones de prueba.
- Usa **cámara CMOS de luz visible**, no matriz térmica: bajo escombro, sin luz, no sirve tal cual.
- Conclusión: «menos de 1 mW» es una cifra de mercadotecnia sin condiciones; lo documentado es 7 mW.

### D. Sensores de presencia humana

| Sensor | Tamaño | Masa | Campo de visión | Resolución | Exactitud | Interfaz | Corriente | Alcance realista para una persona | Fuente | Confianza |
|---|---|---|---|---|---|---|---|---|---|---|
| Melexis **MLX90640** | TO-39, 4 pines | n/p; ~1 g est. (comparable al HTPA en TO-39) | 55° × 35° o 110° × 75° | **32 × 24** | NETD 0.1 K RMS a 1 Hz | I²C; 0.5–64 Hz | **< 23 mA** a 3.3 V | ~3–5 m con 55° (un torso de 40 cm ocupa 4–5 píxeles a 3 m; cálculo geométrico propio) | Hoja de datos Melexis, p. 1 | Alta (alcance: estimado) |
| Melexis MLX90641 | TO-39 | n/p | — | 16 × 12 | — | I²C | **Sin verificar** | — | Página de Melexis (rev. 4, sep-2023) | Baja |
| Melexis **MLX90632** | SFN 3 × 3 × 1 mm | n/p; ~20 mg est. | 50° | 1 punto | Grado médico y estándar (cifra exacta sin verificar) | I²C | 1 mA; reposo < 2.5 µA | < 0.5–1 m (promedia todo el cono) | Hoja Melexis rev. 2 (dic-2017); vigente rev. 13 (jun-2025) | Alta |
| Melexis MLX90614 | TO-39 | n/p | — | 1 punto | — | SMBus | **Sin verificar** (403) | < 0.5–1 m | — | — |
| Panasonic **AMG8833** Grid-EYE | SMD de 14 terminales (cotas sin verificar) | n/p | 60° típico | **8 × 8** | ±2.5 °C típico; NETD 0.05 K (1 Hz), 0.16 K (10 Hz) | I²C; 10 o 1 cuadros/s | **4.5 mA** normal; 0.8 mA en espera; 3.3 V | 1–3 m útil (a 3 m cada píxel cubre ~39 cm: una persona es un píxel). Distribuidores anuncian 5 m y 7 m | Hoja Panasonic «03 Feb. 2019» | Alta (alcance: Baja) |
| Heimann **HTPA32x32d** | TO-39; 8 × 8 × 5 mm según NTU | **0.99 g** (medido por NTU) | 90°, 43°, 33° o 23° según óptica | **32 × 32** | NETD estimada ~150 mK a 1 Hz | I²C; hasta 15–60 Hz | **8 ± 1 mA** (26 mW) según Heimann; **21.45 mW medio** (6.5 mA), 8 µW dormido según NTU | **0.5–1.5 m** (90 % de sensibilidad medida por NTU con óptica de 90°) | Heimann, Overview Rev. 03 (2016); Tran-Ngoc 2023 | Alta |
| Heimann HTPA8x8d | TO-39 | n/p | — | 8 × 8 | — | I²C | 4 ± 0.5 mA | 1–3 m | Heimann Overview Rev. 3 (vía resumen) | Media |
| Omron **D6T-44L-06** / D6T-32L-01A | Módulo con conector | n/p | 44.2° × 45.7° / 90° × 90° | 4 × 4 / 32 × 32 | ±1.5 °C sin confirmar | I²C | ~5 mA / ~19 mA; **alimentación 4.5–5.5 V** | 1–3 m | Catálogo Omron (extracción parcial) | Baja |
| ST **STHS34PF80** | LGA-10, 3.2 × 4.2 × 1.455 mm | n/p; ~40 mg est. | 80° | 1 punto (presencia y movimiento) | — | I²C / SPI; 1.7–3.6 V | **10 µA** | **4 m sin lente** para un objeto de 70 × 25 cm (dato de ST) | Página de producto de ST | Media (ST muestra estados de ciclo de vida contradictorios; revisar antes de comprar) |
| Teledyne FLIR **Lepton 3.5** | 11.5 × 12.7 × 6.9 mm sin zócalo | **0.9–1.0 g** sin zócalo según variante (la hoja lista 0.9 g para un modelo de 160 × 120; no confirmé que esa columna sea la del 3.5) | 57° horizontal (dato de distribuidor) | **160 × 120**, 12 µm, 8.7 Hz | Radiométrica | SPI (video) + I²C (control) | **150 mW** operando; **650 mW** durante el obturador (0.5 s); 5 mW en espera | ~10 m (una persona de 0.5 m ocupa ~7 píxeles; cálculo propio) | Hoja de la serie Lepton, REV1 23-12-2025 | Alta (alcance: estimado) |
| Micrófono MEMS TDK **T5838** | 3.5 × 2.65 × 0.98 mm | n/p; ~20 mg est. | Omnidireccional | — | SNR 68 dBA (alta calidad), 65 dBA (bajo consumo) | PDM | 310 µA alta calidad; **120 µA** bajo consumo; **20 µA** en detección de actividad acústica; 9 µA dormido | Voz o golpes a pocos metros en silencio; no localiza con un solo micrófono | TDK DS-000383 vía distribuidor Edom; guía EVB de TDK (120 µA) | Media |
| Sensirion **SCD40 / SCD41** (CO₂ fotoacústico) | 10.1 × 10.1 × 6.5 mm | **n/p en la hoja** | — | 400–5,000 ppm (especificado) | ±(40–50 ppm + 2.5–5 % de la lectura) según intervalo | I²C; 2.4–5.5 V | Periódico **15 mA** medio (máx. 18); bajo consumo 3.2 mA; disparo único cada 5 min **0.45 mA** (solo SCD41); **picos de 175–205 mA** | No mide distancia. Respuesta τ63 % = 60 s: demasiado lenta para un insecto que camina a 3 cm/s | Hoja SCD4x v1.5 (jul-2023), Tabla 2 | Alta |
| Sensirion **STCC4** (CO₂ por conductividad térmica) | **4 × 3 × 1.2 mm** | n/p; ~30 mg est. | — | 400–5,000 ppm | ±(100 ppm + 10 %) | I²C; 2.7–5.5 V | **950 µA** medio; 4.2 mA máx. | Ídem; τ63 % = 20 s; opera de 10 a 40 °C | Página de producto de Sensirion | Media |
| Infineon **BGT60TR13C** (radar 60 GHz FMCW) | Antena en encapsulado, 6.5 × 5.0 × 0.9 mm | n/p; ~60 mg est. | — | 1 TX + 3 RX | — | SPI; 1.8 V | **Activo 175–201 mA típico** (~315–360 mW); sueño profundo 0.12 mA | Requiere ciclo de trabajo muy bajo; alcance de signos vitales sin verificar | Hoja de datos v01, Tabla 6 (vigente V2.4.9, 2023) | Alta (corrientes) |
| Acconeer **A121** (radar 60 GHz pulsado) | fcCSP50, 5.2 × 5.5 × 0.88 mm | n/p; ~50 mg est. | — | — | mm en distancia | SPI; 1.8 V | Hibernación ~0.06 µA; medición de decenas de mA en ráfagas. Acconeer anuncia presencia con < 80 µW (0.1–1 m), ~0.5 mW (hasta 3 m), ~0.55 mW (hasta 5 m) | **Presencia hasta 7 m** sin lente (hoja de datos) | Hoja A121 v1.3, §4.5; nota de Acconeer (cifras de potencia sin condiciones) | Alta (hoja) / Baja (µW) |
| Bosch **BME688** (gas) | LGA 3.0 × 3.0 × 0.93 mm | n/p; ~17 mg est. | — | COV, CO, H₂, compuestos de azufre | — | I²C / SPI | 2.1 µA (T+H a 1 Hz); modo ULP 90 µA; LP 0.9 mA; barrido de gas estándar **3.9 mA** | No hay base para afirmar un alcance | Página de producto de Bosch | Media |

**Lecturas**

- **El único sensor con detección de personas demostrada sobre esta especie es la matriz térmica de 32 × 32**:
  87 % de exactitud y 90 % de sensibilidad entre 0.5 y 1.5 m (Tran-Ngoc 2023). Pesa 0.99 g: es el componente
  individual más pesado después de la batería.
- **Radar de 60 GHz:** el A121 es el único con consumo compatible (ráfagas); el BGT60TR13C activo consume más
  que toda la mochila de NTU. Ninguno de los dos tiene, en lo que leí, evidencia de funcionar a través de
  escombro; por el mismo modelo de la sección F, 60 GHz atenúa en concreto más que 8 GHz (inferencia, no medición).
- **CO₂:** el SCD41 tiene picos de 175–205 mA (mismo problema que el ESP32 para una celda chica) y mide
  10 × 10 × 6.5 mm. El STCC4 es 50 veces más chico en volumen pero menos exacto. La respuesta de 20–60 s limita
  su uso a «olfatear» parado, no en marcha.
- **Sensor de 10 µA (STHS34PF80):** es el candidato natural para la configuración mínima, pero es de un solo
  punto: dice «algo tibio entró al cono», no distingue una persona de un tubo caliente.

### E. IMU

| IMU | Tamaño | Masa (est.) | Consumo | Fuente | Confianza |
|---|---|---|---|---|---|
| Bosch **BMI270** | LGA14, 2.5 × 3.0 × 0.8 mm | ~14 mg | Acel+giro: 970 µA (performance), **685 µA** (normal), 420 µA (bajo consumo); solo acel: 210 µA normal, **10 µA** bajo consumo; suspendido 3.5 µA | Hoja BST-BMI270-DS000 rev. 1.2, tabla de corriente | Alta |
| TDK **ICM-42688-P** | LGA14, 2.5 × 3 × 0.91 mm | ~15 mg | 6 ejes bajo ruido **0.88 mA**; solo acelerómetro 0.28 mA; 1.71–3.6 V | Página de producto TDK (hoja DS-000347 v1.8) | Media |
| ST **LSM6DSO** | — | — | **Sin verificar** (st.com no respondió) | — | — |
| InvenSense MPU9250 (la de NTU 2023) | — | — | **11.55 mW** medido en la mochila | Tran-Ngoc 2023, Sección Experimental | Alta |

Cambiar la MPU9250 por una BMI270 en modo normal baja la IMU de 11.55 mW a ~2.3 mW (685 µA × 3.3 V).

### F. Radio a través de escombros

**Transceptores**

| Radio | Tamaño | Masa | RX | TX | Reposo | Fuente | Confianza |
|---|---|---|---|---|---|---|---|
| BLE 2.4 GHz — nRF52840 | WLCSP 3.5 × 3.6 mm | ~15 mg est. | 6.26 mA; sensibilidad −95 dBm (1 Mbps), **−103 dBm (125 kbps)** | 6.40 mA a 0 dBm; 16.40 mA a +8 dBm | 0.4–3.2 µA | nRF52840 PB v2.3 | Alta |
| Sub-GHz LoRa — Semtech **SX1262** | QFN24 4 × 4 mm | ~35 mg est. | **4.6 mA** (LoRa 125 kHz, DC-DC); 5.3 mA con RX reforzado; 8–9.3 mA con LDO | 868/915 MHz: **45 mA a +14 dBm**, 118 mA a +22 dBm. 434 MHz: 32 mA a +14 dBm, 107 mA a +22 dBm | 160 nA (arranque en frío); 600 nA con configuración retenida; 1.2 µA con RC de 64 kHz | Semtech DS.SX1261-2 Rev. 1.2, Tablas 3-5 y 3-6 | Alta |
| Sub-GHz — TI CC1352R (radio + microcontrolador) | VQFN48 7 × 7 mm | ~100 mg est. | 5.8 mA (868 MHz) | **24.9 mA a +14 dBm** | 0.85 µA | TI SWRS196I | Alta |
| UWB — Qorvo **DW3110 / DWM3000** | Módulo DWM3000: 23 × 13 × 2.9 mm | **no encontrada** | **Sin verificar** | **Sin verificar** | **Sin verificar** | Qorvo devolvió error 429; solo dimensiones vía distribuidor RFMW | Baja |

El SX1262 declara presupuesto de enlace máximo de 170 dB y sensibilidad de hasta −148 dBm (página de Semtech;
es el caso extremo: +22 dBm y la tasa de datos más lenta). BLE codificado con +8 dBm y −103 dBm da 111 dB.
La diferencia, hasta ~60 dB, es lo que LoRa puede «gastar» en concreto; a +14 dBm el margen baja a ~50 dB.

**Atenuación en concreto** (calculada por mí con ITU-R P.2040-1, ec. 27a: A = 1636·σ/√ε′ dB/m; concreto:
ε′ = 5.31, σ = 0.0326·f^0.8095 S/m con f en GHz, intervalo nominal 1–100 GHz)

| Frecuencia | σ (S/m) | Atenuación | En 0.3 m | En 1 m | Nota |
|---|---|---|---|---|---|
| 433 MHz | 0.0166 | ~12 dB/m | ~3.5 dB | ~12 dB | Fuera del intervalo nominal del modelo |
| 868 MHz | 0.0291 | ~21 dB/m | ~6 dB | ~21 dB | Ídem (la ITU aclara que los límites no son rígidos) |
| 915 MHz | 0.0303 | ~22 dB/m | ~6.5 dB | ~22 dB | Ídem |
| 2.4 GHz (BLE) | 0.0662 | ~47 dB/m | ~14 dB | ~47 dB | — |
| 6.5 GHz (UWB canal 5) | 0.148 | ~105 dB/m | ~32 dB | ~105 dB | — |
| 8 GHz (UWB canal 9) | 0.175 | ~125 dB/m | ~38 dB | ~125 dB | — |

**Contraste con medición real:** NISTIR 6055 (Stone, 1997) midió concreto de 102, 203 y 305 mm entre 0.5–2 GHz
y 3–8 GHz y concluye que una señal que cruza un muro de **305 mm pierde ~90 dB a 8 GHz**. El modelo de la ITU
predice 38 dB para ese caso. El concreto real (húmedo, con agregados, armado) puede atenuar más del doble en dB.
Las cifras de la tabla son un piso optimista. No pude extraer del reporte de NIST los valores a 0.5–2 GHz
(están en gráficas).

**Qué implica**

- A 1 m de concreto macizo, BLE pierde ~47 dB o más y UWB más de 100 dB: **UWB no atraviesa escombro macizo**;
  sirve para localizar entre insectos con línea de vista dentro de un hueco.
- Sub-GHz pierde ~22 dB/m y además tiene ~60 dB más de presupuesto. El costo es el transmisor (45 mA a +14 dBm)
  y la antena: un cuarto de onda mide 8.2 cm a 915 MHz y 17 cm a 433 MHz (más que el insecto), contra 3.1 cm a
  2.4 GHz. La eficiencia de una antena acortada no la encontré cuantificada en esta sesión.
- El grupo de Sato migró de BLE (2023) a sub-1 GHz (2025), coherente con esto.

### G. Energía

**Celdas LiPo reales de 10 a 150 mAh**

| Capacidad | Dimensiones | Masa | Wh/kg (a 3.7 V) | Origen del dato | Confianza |
|---|---|---|---|---|---|
| 10 mAh | 2 × 12 × 12.5 mm | 0.45 g | 82 | PowerStream PGEB201212 | Media |
| 10 mAh | — | n/r | — | Iyer et al. 2020 (hasta 6 h con cámara de 248 mg) | Media |
| 25 mAh | 4 × 8 × 8 mm | **0.68 g** | 136 | ZoBorg 2025 (Adv. Sci.) | Alta |
| 20–40 mAh (ultradelgada) | 0.5 × 20 × 81 mm | 1.7 g | 44–87 | PowerStream PGEB0052081 | Media |
| 50 mAh | n/r | n/r (1.0–1.6 g estimado con 115–180 Wh/kg) | — | Lin et al. 2025 (mochila completa de 2.3 g) | Alta la capacidad |
| 90 mAh | n/r | 3 g | 111 | Latif y Bozkurt 2012 | Alta |
| 100 mAh | 11.5 × 31 × 3.8 mm | 3 g (con protección y cable) | 123 | Adafruit 1570 | Media |
| 120 mAh | 10 × 15 mm (espesor n/r) | **2.5 g** | 178 | Tran-Ngoc et al. 2023 | Alta |
| 130 mAh (delgada) | 1 × 43 × 48 mm | 3.5 g | 137 | PowerStream PGEB0104348 | Media |
| 150 mAh | 19.75 × 26.02 × 3.8 mm | 4.65 g (con protección y cable) | 119 | Adafruit 1317 | Media |

Densidad de energía observada: **80–180 Wh/kg**; las celdas más chicas y las que traen circuito de protección
quedan abajo. Regla práctica para presupuestar: **~20–25 mg por mAh** (40–48 mAh por gramo).

**Celda solar ultrafina.** Kakei et al. (2022): módulo orgánico de 4 µm de espesor sobre el abdomen, 17.2 mW,
recarga la LiPo en 30 min con luz solar simulada; pegado en segmentos para no estorbar la marcha. Bajo escombro
no hay luz: sirve para recargar en la zona de espera, no durante la búsqueda.

**Biocelda de combustible con trehalosa.** Pista: Shoji et al. (2016), *Biosensors and Bioelectronics*
(DOI 10.1016/j.bios.2015.11.077, el DOI existe y resuelve a Elsevier). **No pude leer el artículo.** La cifra que
recuerdo, del orden de 0.3 mW, queda **sin verificar** y no debe citarse hasta abrir la fuente. Aun si fuera
correcta, es ~1 % de lo que consume la matriz térmica.

**Masa de PCB por cm²** (estimado con densidades típicas: FR-4 1.85 g/cm³, cobre 8.96 g/cm³, poliimida
1.42 g/cm³; dos capas de cobre de 35 µm al 50 % de cobertura ≈ 0.031 g/cm²; no leí una hoja de laminado)

| Sustrato | g/cm² desnudo (est.) |
|---|---|
| Rígido FR-4 de 0.2 mm | ~0.07 |
| Rígido FR-4 de 0.4 mm | ~0.105 |
| Rígido FR-4 de 0.6 mm | ~0.14 |
| Rígido FR-4 de 0.8 mm | ~0.18 |
| Flexible de poliimida, 2 capas de 18 µm + cubierta | ~0.03 |

Ancla medida: la mochila ZoBorg ya ensamblada pesa 0.17 g/cm².

### H. IA en el borde con matrices térmicas

| Trabajo | Sensor | Modelo | Exactitud | Tamaño | Tiempo | Consumo | Plataforma | Fuente | Confianza |
|---|---|---|---|---|---|---|---|---|---|
| Tran-Ngoc et al., 2023 | Heimann HTPA 32 × 32, 90° | Filtro de mediana 3×3 → HOG (celda 4 × 4, 1,764 características) → **SVM lineal** | **87 %** media; sensibilidad **90 %** a 0.5–1.5 m | **18.3 kB de flash** (≈1 %) y **52.2 kB de SRAM** (≈20 %) | **95 ms** por imagen; opera a 1 Hz | **24 mW** al 100 % de ciclo | MSP432P4011 (Cortex-M4F, 48 MHz) | Adv. Intell. Syst. 5, 2200319, §2.3 | Alta |
| Referencia [20] citada por Tran-Ngoc | — | Clasificador lineal equivalente | — | — | — | 566 mW | FPGA Virtex-7 | Citado en §2.3 del mismo artículo | Media (cita indirecta) |
| Lattice sensAI Human Presence Detection | Cámara CMOS visible, 64 × 64 × 3 | CNN compacta | n/r | n/r | hasta 8 cuadros/s | **7 mW** | iCE40 UltraPlus | Página del diseño de referencia (descontinuado) | Media |

Detalles útiles del trabajo de NTU: entrenaron con 11,171 imágenes de personas y 11,493 de objetos calientes
tomadas a 0.5, 1.0 y 1.5 m; el clasificador solo se activa si más de 15 píxeles caen entre 28 y 38 °C;
en la demostración clasificó bien a la persona 11 veces sin falsos positivos con objetos calientes.
Probaron SVM cuadrática y cúbica: exactitud parecida y costo de cómputo mucho mayor.

**Hueco:** no pude buscar literatura de CNN sobre matrices de 8 × 8 (Grid-EYE) ni de 32 × 24 (MLX90640) en
microcontrolador. La fila de NTU es el único dato primario de esta sección.

### I. Camino a silicio en 2026

**Quién fabrica hoy con PDK abierto**

| Vía | Proceso | Qué se compra | Costo | Tamaño | Plazo | Fuente | Confianza |
|---|---|---|---|---|---|---|---|
| **Tiny Tapeout** (SKY) | SkyWater SKY130 | Uno o más *tiles* en un chip compartido | Calculadora en línea (no hay precio fijo en la página) | **Tile ≈ 160 × 100 µm, ~1,000 compuertas** | TTSKY26d y 26e abiertos, cierran **30-11-2026**; chips 25-05-2027; envío 25-06-2027. La FAQ advierte «hasta un año» | tinytapeout.com/chips y /faq (leídos el 09-11-2026) | Alta |
| Tiny Tapeout (GF) | GF180MCU | Ídem; chip pegado directo al PCB | Calculadora | n/v | TTGF26c y 26d cierran **07-12-2026**; envío 09-06-2027 | Ídem | Alta |
| Tiny Tapeout (IHP) | IHP SG13G2 | Ídem | Calculadora | n/v | TTIHP26b cerró 21-09-2026 (envío 20-09-2027); siguiente TTIHP27a en marzo de 2027 | Ídem | Alta |
| **wafer.space** | GF180MCU, 5 metales | 1,000 dados propios por *slot* | Slot completo US$8,000 (3.93 × 5.12 mm); medio US$5,000; **cuarto US$3,000 (1.94 × 2.53 mm)** | Mínimo 4.9 mm² | Corrida 3: compra hasta 09-12-2026, GDS 16-12-2026, envío segundo trimestre de 2027 | wafer.space | Alta |
| **ChipFoundry** chipIgnite | SkyWater 130 nm (socio declarado) | 100 piezas en QFN o dado desnudo, sobre un SoC RISC-V prefabricado con 38 E/S | **US$14,950** por tapeout | Hasta 15 mm² | CI2612: compromiso 04-11-2026, tapeout 07-12-2026, entrega 25-05-2027 | chipfoundry.io | Alta |
| IHP Open MPW directo | SG13G2 | — | — | — | — | **Sin verificar** (la página devolvió 404) | — |

**Efabless.** efabless.com redirige hoy a chipfoundry.io/efabless, que dice: «Umbralogic Technologies LLC,
doing business as ChipFoundry, has acquired the assets of Efabless Corporation». La página no da fecha. En la
lista de Tiny Tapeout, **TT10 aparece «Cancelled»** con liga a una FAQ sobre Efabless, TT09 con envío
«TBD» y TT08 enviado el 01-12-2025. Es decir: el camino SKY130 siguió vivo (ChipFoundry + Tiny Tapeout),
con una corrida perdida y otra muy retrasada.

**Tamaño de celda en SKY130** (biblioteca de alta densidad `sky130_fd_sc_hd`)

| Elemento | Dimensión | Área | Fuente |
|---|---|---|---|
| Sitio de colocación | 0.46 × 2.72 µm | 1.25 µm² | Documentación del PDK |
| Flip-flop `dfxtp_1` | 7.36 × 2.72 µm | **20.02 µm²** | LEF de la celda en el repositorio del PDK |
| NAND de 2 entradas `nand2_1` | 1.38 × 2.72 µm | **3.75 µm²** | LEF de la celda |

**Conteo estimado para «promedio móvil + comparador + UART»** (estimación propia a mano; no la sinteticé porque
en la máquina hay Icarus Verilog pero no Yosys)

| Bloque | Flip-flops | Celdas combinacionales | Total |
|---|---|---|---|
| Transmisor UART 8N1: registro de corrimiento de 10 bits, contador de bits de 4, divisor de baudios de 7 bits (16 si es programable), bandera de ocupado | 22–31 | 35–40 | **55–75** |
| Promedio móvil de 4 muestras de 8 bits: línea de retardo 32, suma corrida 10, sumador-restador de 10 bits | ~42 | 20 (con celdas sumador completo) a 60 (con compuertas simples) | **60–100** |
| Ídem con 8 muestras | ~75 | 25–65 | 100–140 |
| Comparador de 8 bits contra umbral fijo (más 8 FF y ~15 celdas si el umbral es programable) | 0–8 | 8–30 | **8–40** |
| **Total (4 a 8 muestras)** | **~65–115** | **~65–135** | **~130–250** |

A eso se suman búferes del árbol de reloj y celdas de relleno, *tap* y desacoplo, que el flujo cuenta como
celdas y suelen superar en número a las lógicas.

Área: 65–115 flip-flops × 20 µm² + 65–135 celdas × 5–10 µm² ≈ **2,000–4,000 µm² de celdas**. Con 40–60 % de
utilización: **0.005–0.011 mm²**, un cuadrado de 70–105 µm de lado. **Cabe en un solo tile de Tiny Tapeout**
(0.016 mm²).

**Veredicto sobre las dos afirmaciones del reporte**

- **«Menos de 60 celdas estándar»: no es creíble** para los tres bloques juntos. El transmisor UART solo ya
  está en 55–75. Solo sería cierto si se cuenta un sub-bloque (por ejemplo el comparador), si el promedio móvil
  es de 2 muestras de 1 bit, o si el reloj de baudios viene de fuera. Cifra defendible: **«del orden de 150 a
  250 celdas lógicas, unos 100 flip-flops»**, y lo correcto es reportar el número que dé la síntesis.
- **«Dado de 1.0 mm × 1.0 mm»: plausible como objeto físico, incorrecto como descripción del diseño.** La lógica
  ocupa ~0.005–0.011 mm², cerca del 1 % de ese dado; un dado de 1 mm² estaría limitado por el anillo de
  terminales, no por la lógica. Y ningún servicio abierto vigente entrega un dado propio de 1 mm²: el mínimo de
  wafer.space es 1.94 × 2.53 mm (US$3,000, proceso GF180, no SKY130), chipIgnite es un SoC de hasta 15 mm²
  (US$14,950) y Tiny Tapeout entrega un tile dentro de un chip compartido. Redacción defendible:
  **«un tile de Tiny Tapeout (160 × 100 µm) en SKY130, con entrega estimada a mediados de 2027»**.
- Para la mochila, un dado desnudo de 1 mm² y 0.3 mm de espesor pesaría ~0.7 mg; la masa nunca es el problema,
  lo es el encapsulado y el plazo (7–12 meses, fuera del semestre).

---

## Propuesta de tres configuraciones

Supuestos comunes: PCB propio con chips soldados (no tarjetas de desarrollo); energía útil = 85 % de la nominal;
regulador al 90 % donde se indica. **Todas las autonomías son estimadas, no medidas.** El único dato medido
en un sistema integrado es el de NTU: 205.5 mW y 2.2 h con 120 mAh.

### 1. Mínima (objetivo ≤ 1.5 g): caminar, orientarse y avisar «algo tibio»

| Elemento | Masa | Origen |
|---|---|---|
| PCB rígido de 0.4 mm, 12 × 16 mm (1.92 cm²) | 0.20 g | est. |
| nRF52832 WLCSP + 2 cristales + antena cerámica + ~20 pasivos + regulador | 0.15 g | est. |
| IMU BMI270 | 0.014 g | est. |
| Sensor de presencia STHS34PF80 | 0.04 g | est. |
| Terminales y cables de estimulación | 0.08 g | est. |
| Soldadura y recubrimiento | 0.06 g | est. |
| LiPo de 25 mAh (4 × 8 × 8 mm) | 0.68 g | medido (ZoBorg) |
| Base y adhesivo | 0.10 g | est. |
| **Total** | **≈ 1.3 g** (16–22 % de un insecto de 6–8 g) | |

| Consumidor | Corriente media |
|---|---|
| nRF52832: CPU 3.7 mA al 5 % + enlace BLE a 1 paquete/s | ~0.25 mA |
| BMI270, acelerómetro + giroscopio en bajo consumo | 0.42 mA |
| STHS34PF80 | 0.01 mA |
| Estimulación (≈0.1 mW) y fugas | ~0.05 mA |
| **Total** | **≈ 0.73 mA (≈ 2.4 mW a 3.3 V)** |

Autonomía: 25 mAh × 0.85 ÷ 0.73 mA ≈ 29 h en papel; **15–29 h** con margen de 2× por picos, frío y
retransmisiones.

### 2. Media (objetivo ≤ 3 g): detección de personas con matriz térmica

| Elemento | Masa | Origen |
|---|---|---|
| PCB rígido de 0.4 mm, 15 × 20 mm (3 cm²) | 0.32 g | est. |
| nRF52840 WLCSP + cristales + antena + pasivos + regulador | 0.18 g | est. |
| IMU BMI270 | 0.014 g | est. |
| Matriz térmica 32 × 32 (Heimann HTPA32x32d; alternativa MLX90640) | 0.99 g | medido (NTU) |
| Micrófono T5838 | 0.02 g | est. |
| Terminales, soldadura, recubrimiento | 0.16 g | est. |
| LiPo de 40 mAh | ~1.05 g (0.85–1.3 g) | est. con 115–180 Wh/kg |
| Base y adhesivo | 0.12 g | est. |
| **Total** | **≈ 2.9 g** (36–48 % del insecto) | |

| Consumidor | Potencia media |
|---|---|
| Matriz térmica encendida todo el tiempo | 21.5 mW (medido por NTU) |
| Clasificador HOG + SVM a 1 Hz (95 ms por cuadro ≈ 10 % de 24 mW) | ~2.4 mW |
| BMI270 en modo normal | 2.3 mW |
| Micrófono en bajo consumo | 0.4 mW |
| BLE y estimulación | ~0.3 mW |
| **Total con sensor continuo** (más 10 % de regulador) | **≈ 30 mW** |
| **Total con el sensor al 25 % de ciclo** | **≈ 12 mW** |

Autonomía: 40 mAh × 3.7 V × 0.85 = 126 mWh → **≈ 4 h** con sensor continuo; **≈ 9–10 h** con el sensor al 25 %.

Nota: con 50 mAh (como Lin 2025) el total sube a ~3.2 g; el límite de 3 g obliga a ~40 mAh mientras la matriz
térmica pese 1 g.

### 3. Completa (objetivo ≤ 5 g): térmica + CO₂ + micrófono + FPGA + enlace sub-GHz

| Elemento | Masa | Origen |
|---|---|---|
| PCB rígido de 0.4 mm, 18 × 25 mm (4.5 cm²), 4 capas | 0.55 g | est. |
| nRF52840 + SX1262 + TCXO + conmutador RF + redes + 2 antenas + iCE40UP5K WLCSP + flash + reguladores | 0.45 g | est. |
| IMU BMI270 | 0.014 g | est. |
| Matriz térmica 32 × 32 | 0.99 g | medido (NTU) |
| Micrófono T5838 + CO₂ STCC4 | 0.05 g | est. |
| Terminales, soldadura, recubrimiento | 0.18 g | est. |
| LiPo de 120 mAh (10 × 15 mm) | 2.5 g | medido (NTU) |
| Base y adhesivo | 0.15 g | est. |
| **Total** | **≈ 4.9 g** (61–82 % del insecto; sin margen) | |

| Consumidor | Potencia media |
|---|---|
| Matriz térmica continua | 21.5 mW |
| Microcontrolador | ~5 mW |
| FPGA durante inferencia (cifra del diseño de Lattice) | ~7 mW |
| BMI270 | 2.3 mW |
| STCC4 (950 µA) | 3.1 mW |
| Micrófono | 0.4 mW |
| LoRa: TX +14 dBm al 1 % (45 mA) + RX al 5 % (4.6 mA) | ~2.3 mW |
| BLE y estimulación | ~0.4 mW |
| **Total** (más 10 % de regulador) | **≈ 47 mW** |

Autonomía: 444 mWh × 0.85 ÷ 47 mW ≈ **8 h en papel**. **Piso empírico: 2.2 h**, que es lo que NTU midió con
esta misma batería y una carga de 205.5 mW. La diferencia de 4× entre mi presupuesto y su medición se explica
en parte por sus componentes (MPU9250 de 11.5 mW, sensor de gas CCS811 con calefactor, DAC de alto voltaje
AD5504 con elevador a 12 V, microcontrolador a 48 MHz sin dormir), pero mientras no se mida un prototipo
**hay que reportar 2–8 h, no 8 h**.

**Resumen**

| Configuración | Masa | % del insecto (6–8 g) | Batería | Consumo medio | Autonomía estimada |
|---|---|---|---|---|---|
| Mínima | ≈ 1.3 g | 16–22 % | 25 mAh | ≈ 2.4 mW | 15–29 h |
| Media | ≈ 2.9 g | 36–48 % | 40 mAh | 12–30 mW | 4–10 h |
| Completa | ≈ 4.9 g | 61–82 % | 120 mAh | ≈ 47 mW (piso medido por NTU: 205 mW) | 2–8 h |

---

## Contradicciones y huecos

**Contradicciones encontradas (no promediadas)**

1. **Carga útil.** «15 g máximo» (Tran-Ngoc 2023, citando a otro trabajo) y «12.7 g restantes» (Lin 2025)
   contra «el peso de 4 g afectó adversamente» y 10 % de éxito (Latif y Bozkurt 2012) y «el doble de tiempo» con
   películas gruesas (Kakei 2022). Ninguna fuente que leí da una curva de velocidad contra masa de mochila.
2. **Masa de la mochila ligera de NC State:** 500 mg en el artículo, 0.7 g en la nota de prensa de NCSU.
3. **Corriente de radio del nRF52840:** el *product brief* v2.3 dice 6.40 mA (TX, 0 dBm) y 6.26 mA (RX). Las
   cifras que circulan de versiones anteriores (4.8 y 4.6 mA) no las pude verificar; solo hay un indicio
   indirecto en un folleto de otro chip de Nordic. Para el nRF52832 pasa algo parecido: el folleto dice
   5.3 / 5.4 mA y un hilo del foro de Nordic cita 7.1 / 6.5 mA de la especificación con el reloj de alta
   frecuencia incluido. **Usar las cifras altas.**
4. **ESP32-C3:** 5 µA de sueño profundo en el chip contra 44 µA en la XIAO y 100 µA–1.5 mA en SuperMini
   (terreno). La hoja del chip no lista corriente de BLE; la del módulo sí (170 mA a 0 dBm).
5. **Matriz Heimann 32 × 32:** 8 ± 1 mA según Heimann (≈26 mW) contra 21.45 mW medidos por NTU.
6. **Grid-EYE:** alcance de 5 m en un distribuidor y 7 m en otro; la hoja de datos de Panasonic que leí no da
   alcance. Mi cálculo geométrico dice que a 3 m una persona es un solo píxel.
7. **Lattice Human Presence Detection:** 7 mW en la página en inglés, «unos pocos mW» en el mismo texto y 1 mW
   en la versión japonesa. Diseño descontinuado.
8. **Atenuación en concreto:** 38 dB predichos por ITU-R P.2040-1 contra ~90 dB medidos por NIST para 305 mm a
   8 GHz.
9. **Autonomía de la configuración completa:** 8 h en mi presupuesto contra 2.2 h medidas por NTU con la misma
   batería.
10. **iCE40 UL1K:** 1,248 LUT según Lattice, 1,280 según Wikipedia. WLCSP del UP5K: 2.15 × 2.55 mm en la tabla
    y 2.15 × 2.50 mm en el texto de la misma página de Lattice.
11. **Año de Iyer et al.:** 2020 según la Universidad de Washington; un agregador lo fecha en 2021.
12. **STHS34PF80:** una vista de la página de ST lo marca «Obsolete» y otra «Active».

**Huecos (no encontrado o no verificado en esta sesión)**

- Masa real de **todas** las tarjetas de desarrollo (XIAO, SuperMini, UPduino, TinyFPGA BX, iCESugar-nano, Fomu).
  Ningún fabricante la publica; hay que pesarlas.
- Masa de módulos de radio LoRa y UWB; corrientes del DW3110 / DWM3000.
- STM32L0, STM32WB y LSM6DSO (st.com no respondió); MLX90614 y MLX90641 (Melexis devolvió 403).
- Corriente de reposo total del SLG47910, estática del IGLOO nano y del MAX 10; precios de casi todas las FPGA.
- Detalle del artículo de Kakei 2022 (masa de la mochila, batería, minutos de control por carga) y de
  Sanchez 2015 (masa); artículo original de Whitmire 2014; trabajos de Cole.
- Suplemento de Bai 2025: ahí está el hardware de la mochila del enjambre.
- Biocelda de trehalosa (Shoji 2016): sin leer.
- Literatura de CNN sobre matrices térmicas de 8 × 8 y 32 × 24 en microcontrolador (sección H incompleta).
- Valores de NIST a 0.5–2 GHz (en gráficas); versión vigente de ITU-R P.2040 (usé la P.2040-1 de 2015; la
  vigente cambia ligeramente los coeficientes del concreto).
- Alcance de detección por CO₂, gas y micrófono: no encontré ninguna fuente que lo cuantifique para una víctima.
- Precio por tile de Tiny Tapeout (solo en calculadora); condiciones del MPW abierto de IHP; fecha exacta del
  cierre de Efabless.
- Eficiencia de antenas sub-GHz acortadas al tamaño del insecto.

**Lo que conviene medir en el laboratorio antes de escribir cifras en el reporte**

1. Pesar cada tarjeta y cada batería en báscula de 0.01 g.
2. Medir la corriente media y de pico del prototipo con un perfilador de potencia.
3. Sintetizar el bloque digital (Yosys o el flujo de Tiny Tapeout) y reportar el conteo real de celdas.

---

## Fuentes

**Primarias — artículos**

- [P] Tran-Ngoc, P. T. et al. (2023). *Intelligent Insect–Computer Hybrid Robot: Installing Innate Obstacle
  Negotiation and Onboard Human Detection onto Cyborg Insect.* Adv. Intell. Syst. 5, 2200319.
  https://doi.org/10.1002/aisy.202200319 — PDF abierto: https://eprints.whiterose.ac.uk/200437/
- [P] Lin, Qifeng et al. (2025). *Cyborg insect factory: automatic assembly for insect-computer hybrid robot via
  vision-guided robotic arm manipulation of custom bipolar electrodes.* Nat. Commun.
  https://doi.org/10.1038/s41467-025-60779-1 — texto: https://pmc.ncbi.nlm.nih.gov/articles/PMC12304280/ —
  preimpresión: https://arxiv.org/abs/2411.13164
- [P] «Bai et al.» (2025) según la pista del encargo; **no verifiqué el primer autor**. *Swarm navigation of
  cyborg-insects in unknown obstructed soft terrain.* Nat. Commun.
  https://doi.org/10.1038/s41467-024-55197-8 — https://arxiv.org/abs/2403.17392
- [P] *Zoborg: On-Demand Climbing Control for Cyborg Beetles* (2025). Adv. Sci. (U. de Queensland, UNSW y NTU;
  **no verifiqué la lista de autores**, tomarla del DOI al citar).
  https://doi.org/10.1002/advs.202502095 — texto: https://pmc.ncbi.nlm.nih.gov/articles/PMC12376601/
- [P] Latif, T. y Bozkurt, A. (2012). *Line Following Terrestrial Insect Biobots.* IEEE EMBC.
  https://ibionics.ece.ncsu.edu/assets/EMBC_12.pdf
- [P, no leído completo] Kakei et al. (2022). *Integration of body-mounted ultrasoft organic solar cell on cyborg
  insects with intact mobility.* npj Flex. Electron. 6, 78.
  https://doi.org/10.1038/s41528-022-00207-2 — nota de RIKEN:
  https://www.riken.jp/en/news_pubs/research_news/pr/2022/20220905_2/index.html
- [P, solo resumen] Iyer et al. (2020). *Wireless steerable vision for live insects and insect-scale robots.*
  Sci. Robot. 5, eabb0839. https://doi.org/10.1126/scirobotics.abb0839 —
  nota de UW: https://www.ece.uw.edu/spotlight/beetles/
- [P, no leído] Sanchez et al. (2015). *Locomotion control of hybrid cockroach robots.* J. R. Soc. Interface 12,
  20141363. https://doi.org/10.1098/rsif.2014.1363
- [P, no leído] Shoji et al. (2016), según la pista del encargo. Biosens. Bioelectron.
  https://doi.org/10.1016/j.bios.2015.11.077 (el DOI resuelve a Elsevier; no confirmé título ni autores)
- [P] Stone, W. C. (1997). *Electromagnetic Signal Attenuation in Construction Materials.* NISTIR 6055.
  https://nvlpubs.nist.gov/nistpubs/Legacy/IR/nistir6055.pdf
- [P] UIT-R, Recomendación P.2040-1 (07/2015), Tabla 3 y ec. 27a.
  https://www.itu.int/dms_pubrec/itu-r/rec/p/R-REC-P.2040-1-201507-S!!PDF-E.pdf

**Primarias — hojas de datos y páginas de fabricante**

- [P] Nordic nRF52840 SoC product brief v2.3:
  https://www.rutronik.com/fileadmin/Rutronik/Supplier/Nordic/Micropage_2020/nRF52840_SoC_PB_2.3.pdf —
  https://www.nordicsemi.com/Products/nRF52840
- [P] Nordic nRF52832 product brief:
  https://www.nordicsemi.com/-/media/Software-and-other-downloads/Product-Briefs/nRF52832-product-brief.pdf
- [P] Espressif ESP32-C3 Series Datasheet v2.4: https://documentation.espressif.com/esp32-c3_datasheet_en.pdf
- [P] Espressif ESP32-C3-MINI-1 Datasheet v2.2: https://documentation.espressif.com/esp32-c3-mini-1_datasheet_en.pdf
- [P] Seeed, wiki XIAO ESP32C3: https://wiki.seeedstudio.com/XIAO_ESP32C3_Getting_Started/ — XIAO nRF52840:
  https://wiki.seeedstudio.com/XIAO_BLE/
- [P] TI CC2640R2F (SWRS204C): https://www.ti.com/lit/ds/symlink/cc2640r2f.pdf — CC1352R (SWRS196I):
  https://www.ti.com/lit/ds/symlink/cc1352r.pdf
- [P] Microchip/Atmel ATtiny25/45/85 (2586Q):
  https://ww1.microchip.com/downloads/en/DeviceDoc/Atmel-2586-AVR-8-bit-Microcontroller-ATtiny25-ATtiny45-ATtiny85_Datasheet.pdf
- [P] Lattice iCE40 UltraPlus: https://www.latticesemi.com/Products/FPGAandCPLD/iCE40UltraPlus — iCE40 Ultra /
  UltraLite: https://www.latticesemi.com/Products/FPGAandCPLD/iCE40Ultra — Human Presence Detection:
  https://www.latticesemi.com/Products/DesignSoftwareAndIP/IntellectualProperty/ReferenceDesigns/ReferenceDesign04/HumanPresenceDetection
- [P] Gowin GW1NZ DS841-2.8E: https://cdn.gowinsemi.com.cn/DS841E.pdf
- [P] Renesas SLG47910 Rev 1.06: https://www.renesas.com/en/document/dst/slg47910-datasheet
- [P] Efinix Trion T8 DST8-v5.5: https://www.efinixinc.com/docs/trion8-ds-v5.5.pdf
- [P, copia] QuickLogic EOS S3 v3.3d:
  https://cdn.sparkfun.com/assets/7/a/c/c/e/QL-EOS-S3-Ultra-Low-Power-multicore-MCU-Datasheet-v3_3d.pdf
- [P, copia] Melexis MLX90640: https://cdn.sparkfun.com/assets/3/1/c/6/f/MLX90640-Datasheet.pdf — MLX90632 rev. 2:
  https://cdn.sparkfun.com/assets/2/4/a/7/e/MLX90632-Datasheet-Melexis.pdf
- [P, copia] Panasonic Grid-EYE AMG88 (03 Feb. 2019): https://media.e-sonic.com/productfiles/mf-PSC/PSC-AMG8833.pdf
- [P, copia] Heimann HTPA32x32d Overview Rev. 03:
  https://azimp.ru/upload/pdf-static/Heimann%20Sensor/matrix/Overview-HTPA32x32d_Rev3.pdf
- [P] ST STHS34PF80: https://www.st.com/en/mems-and-sensors/sths34pf80.html
- [P, copia] Teledyne FLIR Lepton, hoja de la serie REV1 (23-12-2025):
  https://www.acalbfi.com/file/12305/Lepton-Series-Datasheet-3.pdf
- [P, copia] Sensirion SCD4x v1.5: https://cdn.sparkfun.com/assets/9/7/5/7/0/Sensirion_SCD4x_Datasheet.pdf — SCD41:
  https://sensirion.com/products/catalog/SCD41 — STCC4: https://sensirion.com/products/catalog/STCC4
- [P, copia] Infineon BGT60TR13C v01: https://cdn.hackaday.io/files/1901478135249248/BGT60TR13C_Datasheet-v01.pdf
- [P, copia] Acconeer A121 v1.3:
  https://docs.sparkfun.com/SparkFun_Qwiic_Pulsed_Radar_Sensor_XM125/assets/component_documentation/A121%20datasheet.pdf
- [P] Bosch BME688: https://www.bosch-sensortec.com/products/environmental-sensors/gas-sensors/bme688/
- [P, copia] Bosch BMI270 rev. 1.2: https://cdn.sparkfun.com/assets/9/a/2/9/6/bst-bmi270-ds000.pdf
- [P] TDK ICM-42688-P: https://invensense.tdk.com/products/icm-42688-p/
- [P, copia] Semtech SX1261/2 Rev. 1.2: https://cdn.sparkfun.com/assets/6/b/5/1/4/SX1262_datasheet.pdf — página:
  https://www.semtech.com/products/wireless-rf/lora-connect/sx1262
- [P] Backyard Brains RoboRoach: https://docs.backyardbrains.com/neuroengineering/roboroach/
- [P] PowerStream, celdas delgadas: https://www.powerstream.com/thin-lithium-ion.htm
- [P] Adafruit 100 mAh: https://www.adafruit.com/product/1570 — 150 mAh: https://www.adafruit.com/product/1317
- [P] Tiny Tapeout: https://tinytapeout.com/chips/ — https://tinytapeout.com/faq/
- [P] wafer.space: https://wafer.space/
- [P] ChipFoundry: https://chipfoundry.io/ — aviso sobre Efabless: http://chipfoundry.io/efabless
- [P] SkyWater PDK, bibliotecas: https://skywater-pdk.readthedocs.io/en/main/contents/libraries/foundry-provided.html
- [P] LEF de celdas SKY130:
  https://raw.githubusercontent.com/google/skywater-pdk-libs-sky130_fd_sc_hd/main/cells/dfxtp/sky130_fd_sc_hd__dfxtp_1.lef —
  https://raw.githubusercontent.com/google/skywater-pdk-libs-sky130_fd_sc_hd/main/cells/nand2/sky130_fd_sc_hd__nand2_1.lef

**Secundarias o de terreno (no usar como cita principal)**

- NTU, nota sobre la «fábrica» de insectos cíborg:
  https://www.ntu.edu.sg/news/detail/ai-powered-robot-assembles-search-and-rescue-cyborg-insects
- Hackster, sobre la mochila de 5.5 g: https://hackster.io/news/remote-control-cockroach-a85203533b4e
- HDIAC/DTIC, resumen de los biobots de NC State: https://hdiac.dtic.mil/?p=1637
- Popular Science, «Cyborg Cockroaches: How They Work»: https://www.popsci.com/cyborg-roach-how-it-works/
- NC State News (0.7 g): https://news.ncsu.edu/2012/09/wms-cockroach-steering/
- U. Queensland, nota de ZoBorg: https://news.uq.edu.au/2025-07-01-cyborg-beetles-could-revolutionise-urban-search-and-rescue
- Mischianti, ESP32-C3 SuperMini (consumos medidos):
  https://mischianti.org/esp32-c3-super-mini-high-resolution-pinout-datasheet-and-specs/
- Espressif, guía de medición de corriente (advierte no medir sobre tarjetas de desarrollo):
  https://docs.espressif.com/projects/esp-idf/en/v5.4/esp32c3/api-guides/current-consumption-measurement-modules.html
- Foro Nordic DevZone, corrientes de radio del nRF52832:
  https://devzone.nordicsemi.com/f/nordic-q-a/17076/nrf52832-current-consumption
- Pimoroni, XIAO ESP32C3 («4 g»): https://shop.pimoroni.com/products/seeed-studio-xiao-esp32c3
- taricorp, guía de Fomu (dimensiones del PCB): https://taricorp.net/2019/fomu-beginners-guide/
- Acconeer, nota de «menos de 80 µW»:
  https://acconeer.com/mfn_news/acconeers-latest-radar-sensor-achieves-a-power-consumption-less-than-80-µw-for-human-presence-detection/
- Edom Technology, ficha del T5838: https://www.edomtech.com/zh-tw/product-detail/t5838-multi-mode-digital-microphone/
- RFMW, DWM3000 (dimensiones): https://www.rfmw.com/ProductDetail/DWM3000-Qorvo/681949
- findchips, precios de iCE40 (rango, fecha desconocida): https://www.findchips.com/search/iCE40
