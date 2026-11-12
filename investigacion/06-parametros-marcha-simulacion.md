# 06 · Parámetros de marcha natural y estimulada de *Gromphadorhina portentosa* para la simulación

Fecha de consulta: 9 de noviembre de 2026. Todo número de este archivo viene de un artículo, tabla o figura que se leyó directamente; cuando un valor se leyó de una gráfica, se calculó aquí o llegó por un resumen automático, la columna «confianza» lo dice.

## Hallazgo que cambia el plan

El modelo de simulación del insecto (P_stop, T_stop, umbral de 2 cm, tabla de parámetros) **no está en Bai et al. 2025**. Está en **Tran-Ngoc et al. 2024 (arXiv 2406.03713), Extended Data Table 1 y Extended Data Fig. 2**, y sus valores de marcha natural vienen de **Dirafzoon et al. 2017 (ICASSP)**. Bai et al. solo dice que simuló un enjambre para escoger un umbral (M = 10) y no publica parámetros de marcha.

## Fuentes (títulos y autores confirmados)

| Clave | Referencia | Dónde se leyó |
|---|---|---|
| S1 | Tran-Ngoc P. T., Nguyen H. D., Le D. L., Li R., Chong B. S., Sato H. «Gait-Adaptive Navigation and Human Searching in field with Cyborg Insect». arXiv:2406.03713v1, 6 jun 2024, 35 págs. | PDF completo: https://arxiv.org/pdf/2406.03713 (ficha: https://arxiv.org/abs/2406.03713). La versión HTML da 404. |
| S2 | Bai Y., Tran Ngoc P. T., Nguyen H. D., Le D. L., Ha Q. H., Kai K., See To Y. X., Deng Y., Song J., Wakamiya N., Sato H., Ogura M. «Swarm navigation of cyborg-insects in unknown obstructed soft terrain». Nature Communications 16, 221 (2025). DOI 10.1038/s41467-024-55197-8. PMCID PMC11704230. Preprint arXiv:2403.17392 (v1 se titulaba «Natural-artificial hybrid swarm: Cyborg-insect group navigation in unknown obstructed soft terrain»). | Texto completo (XML de Europe PMC): https://www.ebi.ac.uk/europepmc/webservices/rest/PMC11704230/fullTextXML · Información suplementaria (PDF): https://static-content.springer.com/esm/art%3A10.1038%2Fs41467-024-55197-8/MediaObjects/41467_2024_55197_MOESM1_ESM.pdf · Preprint: https://arxiv.org/abs/2403.17392 · Código: https://github.com/OguraLab-HU/Cyborg-Swarm |
| S3 | Dirafzoon A., Latif T., Gong F., Sichitiu M., Bozkurt A., Lobaton E. «Biobotic motion and behavior analysis in response to directional neurostimulation». ICASSP 2017, págs. 2457-2461. DOI 10.1109/ICASSP.2017.7952598. | El artículo de 5 páginas es de pago (IEEE) y **no se leyó**. Se leyó el **póster oficial** de los autores: https://sigport.org/sites/default/files/docs/Poster_3.pdf (ficha: https://sigport.org/documents/biobotic-motion-and-behavior-analysis-response-directional-neurostimulation). Nota de prensa: https://phys.org/news/2017-02-tracking-movement-cyborg-cockroaches.html y https://news.ncsu.edu/2017/02/tracking-cyborg-cockroaches-2017 |
| S4 | Tran-Ngoc P. T., Le D. L., Chong B. S., Nguyen H. D., Dung V. T., Cao F., Li Y., Kai K., Gan J. H., Vo-Doan T. T., Nguyen T. L., Sato H. «Insect-Computer Hybrid System for Autonomous Search and Rescue Mission». arXiv:2105.10869v3 (2021). Publicado como «Intelligent Insect–Computer Hybrid Robot: Installing Innate Obstacle Negotiation and Onboard Human Detection onto Cyborg Insect», Advanced Intelligent Systems 5(5), 2200319 (2023), DOI 10.1002/aisy.202200319 (CC BY 4.0). | Preprint completo: https://arxiv.org/pdf/2105.10869 . La página de Wiley respondió 403, así que **los valores son del preprint v3**; el título y los datos de la versión de revista se confirmaron en Crossref (https://api.crossref.org/works/10.1002/aisy.202200319). |
| S5 | Herreid C. F. II, Full R. J., Prawel D. A. «Energetics of cockroach locomotion». J. exp. Biol. 94, 189-202 (1981). | PDF escaneado: https://polypedal.berkeley.edu/publications/002_Herreid_EnergeticsofCockroachLocomotion_JExpBiol_1981.pdf . Se leyeron las págs. 189-196 (resumen, métodos, resultados e inicio de la discusión); las págs. 197-202 no se revisaron. |
| S6 (extra) | Erickson J. C., Herrera M., Bustamante M., Shingiro A., Bowen T. «Effective Stimulus Parameters for Directed Locomotion in Madagascar Hissing Cockroach Biobot». PLoS ONE 10(8): e0134348 (2015). DOI 10.1371/journal.pone.0134348. | https://pmc.ncbi.nlm.nih.gov/articles/PMC4550421/ . Fuera de la lista pedida; se añadió porque es la única que da ángulo de giro y tasa de respuesta. **Leído a través de un resumen automático**: verificar contra la tabla original antes de citar. |

Escala de confianza: **alta** = leído directamente en el texto o la tabla de la fuente primaria; **media** = leído en el póster (no en el artículo), citado por la fuente desde otro trabajo, o extraído por resumen automático; **baja** = leído de una gráfica o derivado aquí con una cuenta.

Cómo se leyó cada una: S1, S4, S5, el póster de S3 y la información suplementaria de S2 se leyeron completos y de forma directa (texto extraído del PDF y páginas vistas como imagen). El texto principal de S2 se leyó por extracción automática con citas literales, en dos pasadas independientes (preprint v3 y XML de Europe PMC) que coincidieron.

---

## A. Marcha natural (sin estímulo)

| Parámetro | Valor | Unidades | Condiciones | Fuente | Ubicación en la fuente | Confianza |
|---|---|---|---|---|---|---|
| Velocidad lineal media (zona central) v_m | 1.94 ± 0.29 (μ ± σ) | cm/s | Insecto con mochila, sin comandos, arena circular | S3 | Póster, tabla «(b) Natural Motion Parameters» | Media |
| Velocidad lineal natural v | 2.0 ± 0.3 | cm/s | Valor usado en la simulación ARGoS; S1 lo atribuye a S3 | S1 | Extended Data Table 1 | Alta (coincide con S3) |
| Fracción del tiempo en movimiento F_move | 0.372 ± 0.199 | fracción | Natural | S3 | Póster, tabla (b) | Media |
| Fracción del tiempo quieto | 0.628 | fracción | 1 − F_move; cuenta propia | S3 | Derivado de la tabla (b) | Baja |
| Fracción del tiempo en la zona central F_C | 0.632 ± 0.165 | fracción | Natural; la arena se divide en partición central (C) y perimetral (P) | S3 | Póster, tabla (b) | Media |
| Fracción del tiempo pegado a la pared (partición P) | 0.368 | fracción | 1 − F_C; cuenta propia. El ancho de la franja perimetral (r_P) no trae valor en el póster | S3 | Derivado de la tabla (b) | Baja |
| Probabilidad de detenerse P_stop | 0.211 ± 0.099 | probabilidad por decisión | Natural; se evalúa al terminar cada tramo o cada pausa, en campo abierto y en pared («CRW / WF») | S3 | Póster, tabla (b) | Media |
| P_stop usado en simulación | 21 | % | Igual en campo abierto y siguiendo pared | S1 | Extended Data Table 1 y Extended Data Fig. 2b | Alta |
| Duración de la pausa τ_stop | 36.77 ± 24.08 | s | Natural; «characteristic length of stop». μ y σ son entre ensayos, no la forma de la distribución | S3 | Póster, tabla (b) | Media |
| T_stop usado en simulación | 36 ± 24, distribución normal | s | «drawn from a normal distribution». Ojo: una normal con esa σ da valores negativos; hay que truncarla | S1 | Métodos, «Development of the ROS Simulation Environment», y Extended Data Table 1 | Alta |
| Longitud característica del tramo recto l* | 17.586 ± 4.79 | cm | Natural; caminata aleatoria correlacionada con p(l) = (1/l*)·e^(−l/l*) (exponencial) | S3 | Póster, sección «Motion Model» y tabla (b) | Media |
| Longitud del tramo recto L usada en simulación | 17.5 ± 4.8, distribución normal | cm | S1 la muestrea como normal; S3 la define como exponencial de media l* (ver discrepancias) | S1 | Extended Data Table 1; Métodos | Alta |
| Ángulo de giro entre tramos α | Distribución de von Mises, **sin parámetros numéricos** | grados | Giro instantáneo tras cada tramo; S1 cita la tesis de Daltorio (2013) | S1 | Extended Data Table 1 | Alta (que no hay número) |
| Histograma de ángulos de giro | Centrado en 0°, casi todo dentro de ±40° | grados | No se indica si es natural o estimulado | S3 | Póster, «Distribution of turn angles» | Baja (gráfica) |
| Probabilidad de repetir el sentido de giro P_persist | 71 | % | S1 lo toma de Jeanson et al. 2003 (*Blattella germanica*, no *G. portentosa*) | S1 | Extended Data Table 1 | Alta (otra especie) |
| Frecuencia de la sacudida del cuerpo al caminar | 3 a 9 | Hz | Citado de Bender et al. 2011 (*Blaberus discoidalis*); en el registro propio la mayoría de la señal queda bajo 10 Hz | S1 | Resultados, «Localization methods…», y Fig. 2 | Media |
| Modos de marcha | No aparece | — | «Gait-adaptive» se refiere a estimar la velocidad con la varianza de la aceleración, no a modos de marcha | S1 | Todo el texto | Alta |
| Marcha observada | Trípode, sin cambio visible de marcha entre velocidades | — | Caminadora a 0.03-0.12 km/h | S5 | Resultados, pág. 192 | Alta |

## B. Marcha estimulada

| Parámetro | Valor | Unidades | Condiciones | Fuente | Ubicación en la fuente | Confianza |
|---|---|---|---|---|---|---|
| Velocidad lineal bajo estímulo | 8.4 ± 3.8 | cm/s | Reacción a la estimulación de los cercos, N = 4 insectos, n = 80 ensayos | S1 | Extended Data Table 1; Métodos (pág. 29) | Alta |
| Velocidad angular bajo estímulo | 86.5 ± 43.5 | °/s | Misma medición (N = 4, n = 80) | S1 | Extended Data Table 1 | Alta |
| Velocidad media durante navegación guiada (seguimiento externo) | 3.7 | cm/s | Fase II hacia una fuente de calor a 4 m, 30 ensayos, N = 3 | S1 | Resultados, «With the external optical tracking system» | Alta |
| Velocidad media durante navegación guiada (IMU a bordo) | 5.0 | cm/s | 9 ensayos | S1 | Resultados, «Utilizing onboard IMU-based localization system» | Alta |
| Velocidad media «del insecto» | 3 | cm/s | S4 la cita de Latif y Bozkurt 2012; no la mide | S4 | Resultados, «On-board Human Detection System» | Media |
| Velocidad media con comandos aleatorios v_m | 2.49 ± 0.714 | cm/s | Estimulación estocástica y periódica (izquierda, derecha, adelante) | S3 | Póster, tabla «(a) Biobotic Motion Parameters» | Media |
| Fracción del tiempo en movimiento con comandos | 0.643 ± 0.190 | fracción | Natural: 0.372, es decir ×1.73 (cuenta propia) | S3 | Póster, tabla (a) | Media |
| Fracción del tiempo en zona central con comandos F_C | 0.599 ± 0.250 | fracción | Casi igual a la natural (0.632) | S3 | Póster, tabla (a) | Media |
| P_stop con comandos | 0.107 ± 0.200 | probabilidad | Natural: 0.211 | S3 | Póster, tabla (a) | Media |
| Duración de la pausa con comandos | 5.55 ± 3.34 | s | Natural: 36.77 | S3 | Póster, tabla (a) | Media |
| Longitud característica del tramo con comandos | 8.714 ± 3.848 | cm | Natural: 17.586 | S3 | Póster, tabla (a) | Media |
| Velocidad de los ciborgs en enjambre | Media aprox. 3 a 5; rango 0 a 8 | cm/s | 10 ensayos, 20 insectos, arena | S2 | Supplementary Fig. 6 (solo gráfica; el texto no da número) | Baja (gráfica) |
| Giro medio tras un comando de giro | Pico de aprox. 1 rad (≈57°) a los ≈3 s | rad | Respuesta angular media contra el retardo | S3 | Póster, «Angular Response Analysis» | Baja (gráfica) |
| Correlación estímulo-respuesta ρ | Máximo ≈0.7 con retardo ≈2 s (L ≈0.9, R ≈0.6) | — | Correlación entre señal de estímulo y velocidad angular | S3 | Póster, gráfica de ρ_λ | Baja (gráfica) |
| Ángulo de giro por estímulo | Mediana 130° (61.6 a 190°) con 2 V bipolar y 1.5 s; tasa de giro mediana 62.7 °/s | ° | Antena + cercos | S6 | Tabla 4 y Discusión | Media (resumen automático) |
| Avance por estímulo | 15.6 a 25.6 cm a 3.9 a 5.6 cm/s | cm, cm/s | Amplitudes altas | S6 | Resumen | Media (resumen automático) |
| Tasa de respuesta al estímulo | ≈50 % de los animales responden bien (56 % a 2 V y 50 Hz bipolar; 59.4 ± 4.4 % «strong responders») | % de animales | Es por animal, no por pulso | S6 | Resumen, Fig. 5B, Tabla 2 | Media (resumen automático) |
| Habituación | Con pulso monopolar, tras 20 a 80 estímulos; avance −80 % a los 40 ensayos; con bipolar ≥2 V, estable 120 ensayos | — | — | S6 | Fig. 6, Tabla 2 | Media (resumen automático) |
| Tasa de respuesta por pulso | **No aparece** | — | Ninguna de S1 a S5 da una probabilidad de obedecer por estímulo | S1-S5 | — | Alta (ausencia) |
| Marcha hacia atrás por estímulo | No se puede inducir | — | Solo giro (antenas) o aceleración (cercos) | S2 | Inf. suplementaria, «Obstacle negotiation», Claim 1 | Alta |

## C. Pared y obstáculos

| Parámetro | Valor | Unidades | Condiciones | Fuente | Ubicación en la fuente | Confianza |
|---|---|---|---|---|---|---|
| Distancia a la que empieza a seguir la pared | ≤ 2 | cm | Modelo de marcha natural; S1 lo atribuye a S3 | S1 | Métodos, «Development of the ROS Simulation Environment» | Alta |
| Probabilidad de dejar la pared p_exit (natural) | 0.005 ± 0.001 | probabilidad por decisión | Natural | S3 | Póster, tabla (b) | Media |
| p_exit con comandos aleatorios | 0.052 ± 0.097 | probabilidad | ×10.4 respecto a la natural (cuenta propia) | S3 | Póster, tabla (a) | Media |
| «Al menos cinco veces más probable» alejarse de la pared | ≥ 5 | veces | Comandos aleatorios contra sin guía; la nota no da más cifras | S3 | Nota de prensa (phys.org y NC State) | Alta (como cita de prensa) |
| P_exit usado en simulación | 5 % en la tabla; 0.5 % en el diagrama | % | **Contradicción interna de S1**; 0.5 % coincide con el valor natural de S3 | S1 | Extended Data Table 1 contra Extended Data Fig. 2b | Alta (la contradicción) |
| Ángulo de salida de la pared β | Log-normal, μ = 36.6, σ = 2.1 | grados | S1 lo toma de Jeanson et al. 2003 (*B. germanica*); no aclara si μ y σ son del ángulo o de su logaritmo | S1 | Extended Data Table 1 | Alta (valor); interpretación incierta |
| Cobertura con marcha natural en 24 h | ≈33 | % | Simulación, arena de 20 × 20 m; «strong wall-following tendency» | S1 | Fig. 5a-b (gráfica) | Baja (gráfica) |
| Obstáculo bajo (1.5 cm): lo trepa | 96 | % de los casos | Insecto de ≈1 cm de alto; ángulo al trepar 74.89 ± 10.24° | S4 | Resultados; Extended Data Fig. 2 y 4 | Alta |
| Pared alta (10 cm): no la trepa, se alinea con ella | — | — | Con control simple falla 37 de 49 ensayos | S4 | Resultados, Fig. 3 | Alta |
| Tiempo en reversa atrapado contra la pared | 40.93 ± 13.34 de 100 (control simple); 5.15 ± 5.33 (control predictivo) | s | Ensayos con paredes altas | S4 | Resultados; Extended Data Fig. 5c | Alta |
| Distancia de «enredo» entre insectos | < 6 | cm | Enjambre de 20 | S2 | Fig. 4d, pie de figura | Media (extracción automática, dos pasadas iguales) |
| Volteado: tiempo para enderezarse | 26.5 forcejeando solo; 4.5 una vez que se agarra de un vecino | s | Un caso (Caso 3) | S2 | Discusión; Fig. 5b | Media (extracción automática, dos pasadas iguales) |

## D. Estimulación eléctrica y control

| Parámetro | Valor | Unidades | Condiciones | Fuente | Ubicación en la fuente | Confianza |
|---|---|---|---|---|---|---|
| Forma de onda | Cuadrada bifásica, 40 Hz, ciclo de trabajo 50 % | — | — | S4 y S2 | S4 Métodos, «Electrode implantation and stimulation»; S2 Inf. suplementaria, «Preparation of cyborg insects» | Alta |
| Voltaje | 6 a 8 | V | Cercos y tercer segmento abdominal (preprint v3; no se pudo cotejar con la versión de revista) | S4 | Métodos | Alta (preprint) |
| Voltaje | 1 a 2.5 (máximo que «soporta» el insecto: 2.5) | V | Antenas (giro) y cercos (aceleración), tierra en el segundo segmento abdominal | S2 | Inf. suplementaria; Resultados, «Swarm navigation algorithm design» | Alta |
| Duración de un estímulo | 0.6 | s | — | S2 | Inf. suplementaria, «Platforms and experiment setup» | Alta |
| Sitio y efecto | Cerco izquierdo: gira a la derecha, y al revés; dos cercos a la vez: acelera | — | — | S4, S1 | S4 Resultados; S1 Métodos | Alta |
| Sitio y efecto | Antena: gira al lado contrario; cercos: acelera | — | — | S2 | Inf. suplementaria | Alta |
| Electrodos | Alambre de platino, 0.08 mm sin aislar; 10 mm en cercos, 5 mm en abdomen | mm | — | S4 | Métodos | Alta |
| Umbral de ángulo para corregir rumbo | 25 | grados | Control predictivo; lazo cada 30 ms | S4, S2 | S4 Extended Data Table 1; S2 Inf. suplementaria, «Parameter settings» | Alta |
| Umbral de ángulo | 20 | grados | Exploración con IMU; distancia de llegada 10 cm | S1 | Fig. 6, pie de figura | Alta |
| Umbral de velocidad lineal para acelerar | 2 | cm/s | — | S4 | Extended Data Table 1 | Alta |
| Umbral de velocidad lineal para acelerar | 3 | cm/s | Enjambre | S2 | Inf. suplementaria, «Parameter settings» | Alta |
| Umbral de velocidad angular (atascado mientras gira) | 5 | °/s | — | S4 | Extended Data Table 1 | Alta |
| Duración de la aceleración | 2000 | ms | — | S4 | Extended Data Table 1 | Alta |
| Estímulo máximo antes de medir velocidad | 2000 | ms | — | S4 | Extended Data Table 1 | Alta |
| Intervalo de medición de velocidad | 500 | ms | — | S4 | Extended Data Table 1 | Alta |
| Marcha libre antes de acelerar / después de acelerar / tras un giro | 250 / 500 / 250 | ms | — | S4 | Extended Data Table 1 | Alta |
| Criterio de «inmóvil» | Desplazamiento < 0.5 cm durante más de 5 s | — | — | S4 | Métodos, «Navigation Experiment» | Alta |
| Perfil de estímulo de S3 | N_L,R = 6 ráfagas para girar, N_F = 1 para avanzar | — | t_on, t_off, T_S y los retardos no traen valor en el póster | S3 | Póster, esquema de estímulo | Media |
| Potencia del control de locomoción | «unos cientos de μW» / «unas décimas de mW» | — | — | S4, S1 | Introducción de ambos | Alta |

## E. Insecto, mochila, sensores y detección de personas

| Parámetro | Valor | Unidades | Condiciones | Fuente | Ubicación en la fuente | Confianza |
|---|---|---|---|---|---|---|
| Tamaño y masa del insecto | 5.7 ± 0.6 cm; 6.32 ± 1.5 g | cm, g | Machos | S4 y S2 | S4 Métodos, «Animals»; S2 Inf. suplementaria | Alta |
| Tamaño y masa (aprox.) | ≈6 cm, ≈6 g | cm, g | — | S1 | Métodos | Alta |
| Tamaño medio | 6 × 2 | cm | — | S4 | Introducción | Alta |
| Carga máxima declarada | 15 | g | S4 la cita de Latif et al. 2016 | S4 | Introducción | Media (cita) |
| Masa total de la mochila | 5.5 | g | Con batería | S4 | Métodos, «Miniature Wireless Communication Stimulator» | Alta |
| Batería | LiPo de 120 mAh, 10 × 15 mm, 2.5 g | — | — | S4 | Métodos | Alta |
| Cámara infrarroja | Heimann HTPA32x32: 32 × 32 px, campo 90° × 90°, 8 × 8 × 5 mm, 0.99 g, 21.45 mW en promedio, 8 μW dormida | — | Opera a 1 Hz | S4 | Métodos; Fig. 5 | Alta |
| IMU | MPU9250, 11.55 mW | mW | 6 ejes con procesador de movimiento | S4 | Métodos | Alta |
| Otros componentes | MSP432P4011 (principal), CC1352 (Bluetooth 5.1), AD5504 (estímulo, hasta 12 V), BME280, CCS811, memoria de 2 MB | — | No se da la masa de cada uno; solo cámara y batería | S4 | Métodos | Alta |
| Consumo total y autonomía | 205.5 mW; hasta 2.2 h con 120 mAh | mW, h | — | S4 | Resultados, «On-board Human Detection System» | Alta |
| Mochila del enjambre | 15 × 15 mm, 2.5 g en total; LiPo de 50 mAh (10 × 15 mm, 1.2 g); radio Sub-1 GHz; CC1352P | — | Sin cámara | S2 | Inf. suplementaria, «Platforms and experiment setup» | Alta |
| Masa de la mochila y batería en S1 | No aparece | — | Dice que hereda la mochila de S4 | S1 | Métodos | Alta (ausencia) |
| Algoritmo de detección | HOG (celda 4 × 4) + SVM lineal sobre imagen térmica filtrada (mediana 3 × 3) | — | Se activa con más de 15 píxeles entre 28 y 38 °C | S4 | Resultados; Métodos; Extended Data Table 2 | Alta |
| Exactitud | 87 % promedio (humano contra no humano); recuperación 90 % entre 0.5 y 1.5 m | % | Validación con 2831 imágenes positivas | S4 | Resultados; Extended Data Fig. 7 | Alta |
| Cómputo y memoria | 95 ms por imagen; 24 mW al 100 %; 18.3 kB de Flash y 52.2 kB de SRAM | — | — | S4 | Resultados; Extended Data Table 3 | Alta |
| Entrenamiento | 11 171 imágenes con humano y 11 493 sin humano; a 0.5, 1.0 y 1.5 m | — | — | S4 | Métodos, «Human Detection Experiment» | Alta |
| Detección de persona en S1 | Hasta 90 % entre 0.5 y 1.5 m (≥4.9 % de la imagen, ≈50 píxeles, entre 28 y 38 °C) | % | Mismo algoritmo de S4 | S1 | Métodos; Resultados | Alta |
| Localización de la mancha de calor | Fiable hasta 4.2 m, exactitud > 86.9 %; al aire libre baja a 1.8 m | m, % | Umbral de paso de fase: 0.8 % de la imagen (8 píxeles) | S1 | Resultados, «Design and Demonstration…»; Fig. 7a | Alta |
| Tiempos de cómputo en S1 | Mancha 350 ms; detección 95 ms; localización con IMU 10 ms | ms | — | S1 | Resultados | Alta |
| Error de la posición por IMU | < 1 m; ≈5 % de la distancia recorrida en 2D y 10 % en 3D | — | Ganancia calibrada con 5 s de caminata libre | S1 | Resultados; Fig. 2 y 3 | Alta |

## F. Resultados de navegación y pruebas de campo

| Parámetro | Valor | Unidades | Condiciones | Fuente | Ubicación en la fuente | Confianza |
|---|---|---|---|---|---|---|
| Éxito hacia una fuente de calor | 28 de 30 (93.3 %) con seguimiento externo; 100 % (n = 9) con IMU | % | Horno a 4 m; éxito = llegar a menos de 0.5 m en 180 s | S1 | Resultados; Métodos, «Evaluation…» | Alta |
| Tiempo medio de navegación | 111.5 (externo); 124.7 (IMU) | s | — | S1 | Resultados | Alta |
| Arena interior / exterior | 4.8 × 6.6 / 3.5 × 6.0 | m | Interior a 25 °C; exterior de noche a 28 °C | S1 | Resumen; Métodos, «Demonstration Setup» | Alta |
| Prueba exterior | Persona a ≈3 m de la salida; detectada a ≈1.7 m | m | Tres falsas alarmas por aire caliente, descartadas | S1 | Resultados; Métodos | Alta |
| Duración de las demostraciones interior y exterior | No aparece en el texto (solo en video) | — | — | S1 | — | Alta (ausencia) |
| Cobertura con caminata de Lévy e IMU | 22.8 ± 5.5 % en 10 min | % | 600 celdas de 10 × 10 cm (6 m², cuenta propia); N = 3, n = 9 | S1 | Resultados, «Stochastic Exploration Strategy with IMU»; Fig. 6c | Alta |
| Simulación de estrategias (24 h, 20 × 20 m, sensor de 0.5 m) | Tramo fijo 61 %; Lévy, uniforme y browniana > 90 %; búsqueda con Lévy 221 min | %, min | — | S1 | Resultados; Fig. 5 | Alta |
| Éxito del control simple | Con obstáculos bajos: 48 de 49; con paredes altas falla 37 de 49; sin obstáculos el texto no da cifra (solo Fig. 3a) | ensayos | N = 5 insectos, 10 ensayos por terreno; 65 cm (sin obstáculos) o 45 cm; límite 100 s | S4 | Resultados; Fig. 3a; Extended Data Fig. 2 | Alta |
| Éxito del control predictivo | 100 % sin obstáculos y con bajos; 94 % con paredes altas | % | Mismo protocolo | S4 | Resultados; Fig. 3a | Alta |
| Tiempo de navegación | Obstáculos bajos: 8.29 ± 6.29 (simple) y 6.35 ± 4.92 (predictivo); paredes altas: 48.98 ± 19.49 y 33.91 ± 18.35 | s | — | S4 | Resultados; Fig. 3b | Alta |
| Demostración de rescate simulado | Arena de 420 × 600 cm; 5 destinos de 8 cm de radio; 9 aceleraciones automáticas; 11 detecciones correctas de persona | — | 2 personas y 3 objetos calientes | S4 | Resultados; Métodos, «Demonstration» | Alta |

## G. Enjambre (S2)

| Parámetro | Valor | Unidades | Condiciones | Fuente | Ubicación en la fuente | Confianza |
|---|---|---|---|---|---|---|
| Número de insectos | 20 (1 líder y 19 seguidores) | — | — | S2 | Resultados, «Experimental verification» | Alta |
| Arena | 3.5 × 3.5, arena con rocas y lomas | m | Dimensiones de rocas y lomas: no aparecen | S2 | Resultados; Supplementary Fig. 5c | Alta |
| Ensayos y duración | 10 ensayos: 52, 42, 54, 146, 45, 99, 80, 85, 57 y 53 s (media 71.3 s, cuenta propia) | s | — | S2 | Inf. suplementaria, «Walking speed of cyborgs» | Alta |
| Grado de autonomía (tiempo sin estímulo ÷ tiempo total) | Líder con control convencional 0.26; seguidores 0.5 | fracción | Promedio de 10 ensayos | S2 | Resultados; Fig. 3e | Media (extracción automática, dos pasadas iguales) |
| Tiempo que el líder va estimulado | 73.6 ± 15.4 | % | — | S2 | Inf. suplementaria, «Stimulated period of the leader» | Alta |
| Reducción de estimulación | ≈50 % en promedio; «casi duplica» el tiempo de marcha libre | % | Contra el control individual | S2 | Discusión; Fig. 3 | Media (extracción automática, dos pasadas iguales) |
| Reducción de enredos | > 85 % en promedio | % | Contra BOIDS; los conteos solo están en la gráfica (Fig. 4a) | S2 | Discusión | Media (extracción automática, dos pasadas iguales) |
| Umbral de vecinos para marcha libre (M) | 10 | vecinos | Escogido por simulación (valores 1 a 19, 50 repeticiones) | S2 | Inf. suplementaria, «Parameter settings» | Alta |
| Seguimiento | VICON, 24 cámaras a 100 Hz; posición cada 0.03 s | — | Sin UWB ni IMU: eso queda como trabajo futuro | S2 | Inf. suplementaria; Supplementary Fig. 5 | Alta |
| Radio de detección r_s, radio libre r_free, sectores, ganancias, paso de tiempo | No aparecen (solo símbolos) | — | — | S2 | Métodos, ecs. 1-8 | Alta (ausencia) |
| Modelo de marcha del insecto en la simulación | No aparece | — | Solo: «sin estímulo, movimiento aleatorio». El código publicado (`TGI.m`, MATLAB) es adimensional: sin estímulo suma ruido uniforme de ±0.01 a la velocidad en cada paso; no tiene pausas, pared ni velocidades en cm/s, y usa umbral de 5 vecinos en vez de los 10 del texto | S2 | Inf. suplementaria, «Parameter settings»; https://raw.githubusercontent.com/OguraLab-HU/Cyborg-Swarm/main/TGI.m | Alta (ausencia en el artículo); media (código, leído por resumen automático) |

## H. Energética (S5)

Conversión: 1 ml O2/(g·h) × 20.1 J/ml ÷ 3600 s/h = **5.583 mW/g**. Potencia por animal con la masa media del artículo, 5.2 g.

| Parámetro | Valor | Unidades | Condiciones | Fuente | Ubicación en la fuente | Confianza |
|---|---|---|---|---|---|---|
| Masa de los ejemplares | 3.4 a 6.5 (media 5.2) | g | Machos adultos | S5 | Métodos, pág. 191; pág. 194 | Alta |
| Velocidades de caminadora | 0.03, 0.07 y 0.12 (= 0.83, 1.94 y 3.33 cm/s) | km/h | 20 min por corrida; ≈10 animales; 23.6 ± 0.6 °C | S5 | Métodos, pág. 191-192 | Alta |
| Velocidad máxima sostenible | 0.12 (3.33 cm/s) | km/h | «the highest speed this species could maintain for the experimental period» (20 min); algunos mostraron fatiga | S5 | Pág. 191 y 192 | Alta |
| Consumo en reposo | 0.19 ± 0.05 (d. e.) | ml O2/(g·h) | 7 individuos, ≈24 °C | S5 | Resultados, pág. 192 | Alta |
| Potencia en reposo | 0.19 × 5.583 = 1.06 mW/g; × 5.2 g = 5.52 mW (3.61 a 6.90 mW para 3.4 a 6.5 g) | mW | Cuenta propia | S5 | Derivado | Baja (derivado) |
| Consumo estable a 0.03 / 0.07 / 0.12 km/h | 0.58 / 0.81 / 1.06 (3.1, 4.3 y 5.6 veces el reposo) | ml O2/(g·h) | Estado estable en menos de 4 min | S5 | Resultados, pág. 193 | Alta |
| Potencia a 0.03 / 0.07 / 0.12 km/h | 3.24 / 4.52 / 5.92 mW/g; 16.84 / 23.52 / 30.78 mW por animal | mW | Cuenta propia (× 5.583; × 5.2 g) | S5 | Derivado | Baja (derivado) |
| Regresión | V̇O2 = 0.45 + 4.92·V (V en km/h; IC 95 %: ±2.19 y ±0.19; 25 corridas) | ml O2/(g·h) | 24 °C | S5 | Fig. 2 y pág. 194 | Alta |
| Regresión en unidades de simulación | P ≈ 2.51 + 0.989·v (mW/g, v en cm/s); por animal de 5.2 g: P ≈ 13.07 + 5.14·v (mW) | — | Cuenta propia; válida de 0.8 a 3.3 cm/s | S5 | Derivado | Baja (derivado) |
| Costo mínimo de transporte | 4.92 ml O2/(g·km) = 98.9 J/(g·km); 0.514 J/m para 5.2 g | — | Conversión propia | S5 | Pág. 194 | Alta (valor); baja (conversión) |
| Costo de transporte por velocidad | 16.3 / 9.9 / 8.2 | ml O2/(g·km) | A 0.03, 0.07 y 0.12 km/h | S5 | Pág. 194 | Alta |
| Efecto de la temperatura en reposo | 0.09 ± 0.04 (15 °C); 0.17 ± 0.06 (25 °C); 0.37 ± 0.06 (35 °C); Q10 ≈ 2 | ml O2/(g·h) | — | S5 | Pág. 195 | Alta |
| Recuperación | Mitad en 4, 4 y 6 min; completa en 15, 30 y 45 min | min | Lenta, media y rápida | S5 | Pág. 193 | Alta |
| Pendiente | Sin diferencia entre −25° y +25° | — | A 0.07 km/h | S5 | Fig. 4, pág. 195 | Alta |

---

## Discrepancias y advertencias

1. **P_exit en S1**: la tabla dice 5 % y el diagrama de estados dice 0.5 %. El póster de S3 da 0.005 para marcha natural y 0.052 con comandos. Para marcha natural usar 0.5 %; el 5 % corresponde al insecto estimulado.
2. **Forma de las distribuciones**: S3 define el tramo recto como exponencial de longitud característica l*; el «± σ» de sus tablas es la variación entre ensayos. S1 reinterpreta esos mismos números como una normal (17.5 ± 4.8 cm; 36 ± 24 s). Las dos opciones tienen fuente, pero dan trayectorias distintas; la exponencial es la del trabajo original.
3. **Pared**: según S3 el insecto sin guía pasa casi la misma fracción de tiempo en la zona central (0.63) que el estimulado (0.60). Lo que cambia diez veces es la probabilidad de soltarse de la pared, junto con moverse más (0.37 → 0.64) y pausas más cortas (37 s → 5.6 s). La frase de prensa «prefiere pegarse a la pared» no viene acompañada de una fracción de tiempo.
4. **Velocidad estimulada**: 8.4 ± 3.8 cm/s (S1) es la reacción inmediata a un estímulo de cercos; las medias de trayecto son 3.7 a 5.0 cm/s (S1) y aprox. 3 a 5 cm/s (S2, gráfica). S5 pone el tope sostenible por 20 min en 3.33 cm/s. La simulación no debería sostener 8 cm/s de forma continua.
5. **S5, velocidades nominales**: los costos de transporte publicados (16.3, 9.9 y 8.2) equivalen a 0.036, 0.082 y 0.129 km/h si se dividen los consumos entre ellos (cuenta propia), y así se ven los puntos en la Fig. 2. Las velocidades reales fueron algo mayores que las nominales 0.03, 0.07 y 0.12.
6. **S2, Algoritmo 1**: impreso dice «si m_i < M, sin estimulación», pero el texto y la Fig. suplementaria 4 dicen que la marcha libre se activa cuando los vecinos **superan** M. Seguir el texto.
7. **Voltajes**: S4 usa 6 a 8 V en cercos y abdomen; S2, 1 a 2.5 V con antenas. No son comparables; la versión de revista de S4 no se pudo abrir para cotejar.
8. **Otras especies**: P_persist (71 %) y el ángulo de salida de la pared vienen de *Blattella germanica*; la banda de 3 a 9 Hz, de *Blaberus discoidalis*.

## Qué quedó con fuente y qué no (para la simulación)

| Parámetro de simulación | Estado | Valor recomendado y fuente |
|---|---|---|
| Velocidad natural | Con fuente | 1.94 ± 0.29 cm/s (S3) o 2.0 ± 0.3 (S1) |
| Velocidad estimulada | Con fuente | Reacción 8.4 ± 3.8 cm/s (S1); media de trayecto 3.7 a 5.0 cm/s (S1) |
| Probabilidad de pausa | Con fuente | 0.211 natural; 0.107 estimulado (S3; S1 usa 21 %) |
| Duración de pausa | Con fuente; forma de la distribución incierta | 36.77 ± 24.08 s natural; 5.55 ± 3.34 s estimulado (S3); S1 usa normal 36 ± 24 s |
| Longitud de tramo | Con fuente | l* = 17.6 cm natural; 8.7 cm estimulado (S3) |
| Giro por estímulo | Parcial | Velocidad angular 86.5 ± 43.5 °/s (S1). Ángulo por pulso: solo gráfica de S3 (≈1 rad a los 3 s) o fuente extra S6 |
| Tasa de respuesta por pulso | **Sin fuente** en S1 a S5 | Único dato cercano: ≈50 a 59 % de los animales responden bien (S6), que no es lo mismo |
| Seguimiento de pared | Con fuente | Entra a ≤ 2 cm (S1); sale con p = 0.005 natural y 0.052 estimulado (S3); ángulo de salida log-normal 36.6 / 2.1 (S1, otra especie) |
| Ángulo de giro natural (von Mises) | **Sin valor numérico** | Solo el histograma del póster de S3 (dentro de ±40°) |
| Ancho de la franja de pared (r_P) y tamaño de la arena de S3 | **Sin valor** | El eje del póster va de −50 a 50 sin unidades |
| Habituación al estímulo | Sin fuente en S1 a S5 | Solo S6 |
| Potencia metabólica | Con fuente | 5.5 mW en reposo; 17 a 31 mW caminando, animal de 5.2 g (S5, conversión propia) |
| Mochila y autonomía | Con fuente | 5.5 g, 205.5 mW, 2.2 h con 120 mAh (S4); 2.5 g con 50 mAh sin cámara (S2) |

## Lo que no se pudo verificar

- El artículo completo de S3 en IEEE Xplore (de pago). Todo lo de S3 sale del póster y de la nota de prensa; S1 cita los mismos valores, lo que los respalda.
- Si S1 ya tiene versión de revista: la búsqueda web se agotó antes de comprobarlo.
- La versión de revista de S4 (Wiley devolvió 403).
- Las páginas 197-202 de S5.
- S6 se leyó por resumen automático.
