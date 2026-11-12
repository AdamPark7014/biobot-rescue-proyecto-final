# 02 — Estimulación y control de la locomoción en biobots de cucaracha

Proyecto final, Lab. de Sistemas Embebidos (UDLAP). Notas de investigación del 09-11-2026.
Especie objetivo: *Gromphadorhina portentosa* (cucaracha silbadora de Madagascar).

**Cómo leer estas notas.** Cada número lleva su fuente con clave entre corchetes (por ejemplo [P1]); la lista completa está al final. «Derivado» significa que la cuenta es mía a partir de números publicados, no un dato del artículo. La confianza es: **alta** (dos fuentes independientes o leído directamente en el artículo y coherente con otros), **media** (una sola fuente primaria), **baja** (prensa, resumen, o artículo con inconsistencias internas).

**Límites de esta búsqueda.** Leí el texto completo de [P1]–[P12], [P15] y [P17] (por HTML o PDF). De [P13] (habituación, Soft Robotics) y [P14] (casco UV, Osaka) solo conseguí el resumen: el texto completo está tras muro de pago o dio 403. No pude abrir Whitmire 2013, Latif 2016, Dirafzoon 2017, Cole 2020 ni Moore 1998; lo que digo de ellos viene de resúmenes o de cómo los citan otros y está marcado. El presupuesto de búsquedas web de la sesión se agotó antes de buscar copias alternativas de esos cinco. No se consultaron los materiales suplementarios (ahí están, por ejemplo, los umbrales del algoritmo de [P4] y los parámetros de [P6]). La mayoría de los artículos se leyó a través de un extractor automático de la página; [P2], [P4] y el preprint de [P5] los leí directamente en PDF. Antes de citar una cifra en el reporte final conviene abrir la tabla o figura indicada.

---

## Respuesta corta

1. **Cómo se dirige.** Se engaña a los sensores del insecto. Estimular una **antena** simula un obstáculo y el insecto gira hacia el lado contrario [P1][P2][P10][P11]. Estimular los **cercos** (o el abdomen) simula un depredador por detrás y el insecto acelera [P4][P5][P10]. Estimular un solo cerco también produce giro, pero las fuentes no coinciden en el sentido (ver «Contradicciones»).
2. **Con qué señal.** Hay consenso amplio en onda **cuadrada bifásica, 40–55 Hz, 50 % de ciclo de trabajo, trenes de 0.4–1 s** [P1][P4][P5][P7][P10][P12][S4]. El voltaje útil con electrodo implantado en antena o cerco está en **2–3 V** [P1][P6][P7][P11]; con electrodos no invasivos sube a **2–4 V** [P5][P12]. Hay un valor atípico de 6–8 V [P4].
3. **Qué tan bien responde.** Mal para un robot, bien para un animal: por estímulo, **74–81 % de éxito** con electrodos no invasivos [P5]; solo **≈50–60 % de los individuos** responde fuerte y en la dirección esperada [P1]; **60 %** con electrodos en el ganglio protorácico [P3]. El ángulo por estímulo va de 0 a ≈110° con medias de 38° (1 s, no invasivo) [P5] a 70–80° (0.4 s, torácico) [P7], y la correlación estímulo–respuesta por ensayo es débil (|r| ≈ 0.1–0.4) [P1].
4. **Habituación.** Es real y rápida: tras 10 estímulos seguidos en la misma antena la velocidad de giro cae **34–58 %** [P10]; con pulsos monofásicos el avance cae ≈80 % en 40 ensayos, mientras que con bifásicos ≥2 V se mantiene 120 ensayos [P1]. Se recupera con descanso de minutos (10–20 min) [P3][S1]. Las mitigaciones que funcionan: onda bifásica [P1], alternar sitio cada 5 estímulos (>100 giros efectivos) [P10], estimular solo cuando el insecto se detiene o se desvía [P4][P6][P9], y regular el voltaje (control hasta 3 h, solo resumen) [P13].
5. **Lazo cerrado.** Lo mejor documentado: 94 % de éxito de navegación entre muros de 10 cm con «control predictivo» basado en IMU, contra 26 % del control simple [P4]; detección de personas a bordo con cámara térmica 32×32 y HOG+SVM, 87 % de exactitud [P4]; enjambre de 20 insectos con la mitad de estimulación y 85 % menos enredos [P6].
6. **Costo eléctrico.** La estimulación es casi gratis: ≈2.2 mW mientras dura el tren [P1], frente a 73–205 mW del resto de la mochila [P4][P8]. El problema de diseño no es la potencia del estímulo sino el radio, los sensores y el peso.

---

## Hallazgos

### A. Sitios y modos de estimulación

| Sitio | Invasivo | Conducta | Mecanismo propuesto | Fuentes |
|---|---|---|---|---|
| Antena (flagelo recortado, electrodo dentro) | Sí | Giro hacia el lado contrario al estimulado | Simula contacto con un obstáculo | [P1] (antena derecha → giro a la izquierda), [P2], [P10], [P11], [S2] |
| Antena, electrodo sobre la superficie (gel de poli-líquido iónico + oro sobre poliimida, o conector cobreado en el escapo) | No | Giro | Igual; conserva la antena para sentir obstáculos | [P5], [P12] |
| Cercos, ambos a la vez | Sí | Aceleración / arranque | Simula corriente de aire de un depredador (respuesta de escape) | [P4], [P9], [P11] |
| Un solo cerco (par cerco–abdomen del mismo lado) | Sí | Giro | Escape lateralizado | [P4] dice **contralateral** (cerco izquierdo → giro a la derecha); [P8] y [P10] dicen **ipsilateral** |
| Abdomen, entre segmentos (hilo de plata + gel; o hebilla cobreada en el 6.º segmento) | No | Aceleración | Estímulo táctil dorsal | [P5] (tierra entre 3.º y 4.º, aceleración entre 6.º y 7.º), [P12] |
| Membrana entre pronoto y mesotórax (par bipolar con microaguja y gancho) | Sí, poco profundo | Giro y **desaceleración** (lo que leí no detalla qué combinación de electrodos produce cada una) | No explicado como reflejo sensorial; elegido porque un brazo robótico puede implantarlo | [P7] |
| Ganglio protorácico (dos orificios en el pronoto) | Sí | Giro hacia el lado contrario; señal sostenida >2 V detiene la marcha | Actúa sobre el control motor de las patas delanteras | [P3] (*Blaberus discoidalis* y *Periplaneta americana*) |
| Ojos compuestos, LED ultravioleta en un casco | No, sin electricidad | Giro (ojo izquierdo → giro a la derecha) y reanudar marcha | Fototaxia negativa | [P14] (resumen), [S5] (prensa) |
| Patas | — | — | No encontré control por estimulación de patas en cucaracha. [P8] menciona «control de patas» en prensa, pero el artículo estimula cercos | — |
| Estímulo térmico o mecánico a bordo | — | — | No encontré uso en mochila; [P1] cita 330 mW por estímulo para un microcalentador piezoeléctrico de otro trabajo, unas 100 veces más que el eléctrico | [P1] |

Notas:
- En [P1] cada ensayo estimulaba **ambos cercos más una antena** (con 100 ms de retraso entre antena y cercos). Sus números mezclan giro y avance; no separan el efecto de cada sitio.
- La implantación en antena la inutiliza como sensor. [P12] lo midió: insectos con antenas cortadas e implantadas tardaron 78.25 ± 45.12 s en superar un bloque grande contra 23.16 ± 14.34 s con el dispositivo que se pone por fuera (3 insectos, 30 ensayos por condición, p = 0.011).
- La estimulación de cercos deja libres las antenas, por eso el grupo de Sato la usa cuando quiere que el insecto negocie obstáculos solo [P4].

### B. Parámetros eléctricos

**Forma de onda.** Cuadrada bifásica (positivo primero) con 50 % de ciclo de trabajo es el estándar [P1][P4][P5][P7][P12]. Monofásica en trabajos antiguos o con mochila sencilla: 3 V CC [P2], +2.5 V [P3], pulsos unipolares de 3–4 V [P10] (los autores dicen que no les cupo el circuito bifásico). [P1] comparó ambas: bifásica gana en respondedores (59.4 ± 4.4 % contra 46.9 ± 3.0 %, Tabla 2) y sobre todo en habituación (2.9 % contra 31.3 % de los sujetos).

**Voltaje.**
- 1–4 V probados; recomendado **2 V** bifásico [P1]. A ≥3 V aparecen giros en sentido contrario al esperado en cerca de la mitad de los sujetos; a 4 V y 200 Hz, sacudidas con las patas abiertas [P1].
- 3 V CC en antena [P2]; 3 V antena y 4 V cerco [P10]; menos de 3 V en navegación [P11]; máximo 2.5 V «que soporta el insecto» en el enjambre [P6].
- Torácico: 3.0 V; las espigas neuronales suben hasta 3.0 V, se aplanan en 3.0–3.5 V y bajan 23.5 % a 4.0 V [P7].
- No invasivo en antena: 4 V (las espigas se estabilizan arriba de 2.5 V y se aplanan en 4 V) [P5]; 2.0–3.5 V con el casco cobreado [P12].
- Atípico: **6–8 V** para el par cerco–abdomen en [P4]. No lo explica; el mismo grupo usa <3 V un año después [P11].
- Ganglio: 1 V atado, 2.5 V en la mochila; más de 2 V sostenido detiene al insecto [P3].
- Controlada por corriente: 50–150 µA; 150 µA a 50 Hz dio 54 % de respondedores fuertes [P1].

**Frecuencia.** 50 Hz [P1][P8][P9][P10]; 40 Hz [P4]; 42 Hz [P5][P7][P12]; 55 Hz [S4]. [P1] probó 50, 100, 200 y 300 Hz y no halló dependencia fuerte. En el ganglio se usa 1–20 Hz y 20 Hz dio los giros más cerrados [P3].

**Ancho de pulso.** Casi nadie lo reporta aparte; se deduce del 50 % de ciclo: 10 ms por fase a 50 Hz, ≈12 ms a 42 Hz ([P5] sí escribe «onda bipolar de 12 ms»).

**Duración del tren.** 0.25–1.5 s probados; [P1] recomienda 0.5 s en el resumen y 0.25 s en la discusión (los giros más grandes salieron con los trenes más cortos, mediana 127.4°). 1 s [P5][P10]; 0.6 s [P12]; 0.4 s [P7]; 0.5 s avance, 1 s giro y 0.2 s de corrección inversa [P10]. Con ≥0.5 s a veces el insecto se «congela» con las patas abiertas antes de correr [P1].

**Electrodos.**

| Material | Diámetro | Sitio y profundidad | Fuente |
|---|---|---|---|
| Plata con teflón | 0.127 mm (0.005") | Antena recortada a ≈1 cm, hasta la base; cercos 3–5 mm; tierra en 2.º segmento abdominal | [P1] |
| Acero inoxidable con PFA | 0.2 mm (aislante 0.25 mm), 3 mm expuestos | Antena; tierra por el primer segmento del tórax | [P2] |
| Platino con teflón | 0.08 mm desnudo, 0.14 mm con aislante | Cerco, 10 mm; 3.er segmento abdominal, 5 mm | [P4], [P10] (mismas medidas; antena 3 mm) |
| Platino | 0.127 mm | Cerco ≈3 mm; tierra en tórax a 3 mm | [P9] |
| Cobre esmaltado | 0.08 mm, dos hebras | Dos orificios en el pronoto sobre el ganglio | [P3] |
| Plata | 0.076 mm (calibre 40) | Antena recortada 3–6 mm; tierra 1–3 mm en el tórax | [S2], [S4] |
| Resina impresa cobreada (2.5 µm de Cu), con microaguja y gancho | 0.6 mm de espesor, separación 1.0 cm | Membrana pronoto–mesotórax | [P7] |
| Gel PIL + oro de 70 nm sobre poliimida | — | Sobre la antena, parte baja | [P5] |

**Rango seguro.** La única regla electroquímica explícita es de [P2]: mantener la caída en la interfaz electrodo–tejido por debajo de **0.7 V** (ventana del agua) para no generar oxígeno ni dañar la interfaz; con 3.5 V aplicados midieron 0.68 V en el electrodo de trabajo y 0.37 V en el contraelectrodo (en solución salina al 0.09 %, no en el insecto). Advierten que una interfaz dañada se confunde con habituación. Como criterio conductual, [P1] y [P7] muestran que pasar de 3–3.5 V empeora la respuesta.

### C. Respuesta cuantitativa

**Giro.**
- [P1] (bifásico, antena + cercos, sobre esfera): al subir de 1 a 4 V el giro **baja** de 149° a 80.0° y la velocidad angular de 62.8 a 41.2 °/s. Pendiente a 50 Hz: −21.2° por volt y −7.70 °/s por volt (Tabla 3). A 2 V, 1.5 s: 130° (rango intercuartil 61.6–190°). Radio de curvatura ≈10–25 cm, graduable con la amplitud.
- [P5] (no invasivo, 4 V, 42 Hz, 1 s): media 38.5° a la izquierda y 38.4° a la derecha (error estándar ≈2°), máximo ≈106–109°, velocidad angular ≈60 °/s.
- [P7] (torácico, 3 V, 42 Hz, 0.4 s): 70.9° izquierda y 79.5° derecha (ensamble automático); 68.0° y 82.6° (manual); pico de 240–298 °/s.
- [P10] (3–4 V unipolar, 50 Hz, 1 s): ≈90° por estímulo; 60 °/s en tubo iluminado, 33 °/s a oscuras, 80 °/s en modo autónomo.
- [P12] (casco no invasivo, 2–3 V, 0.6 s): la velocidad angular sube de 25.36 ± 13.86 a 64.95 ± 33.43 °/s (izquierda) y de 20.41 ± 19.35 a 52.96 ± 22.79 °/s (derecha).
- [P2] (3 V CC, pulsos manuales de 0.15–1.06 s): cambios de rumbo de 2.5° a 25.2° por pulso, en 0.05–0.82 s (leídos de la Fig. 4).

**Avance.**
- [P1]: 15.6–25.6 cm extra por estímulo a 3.9–5.6 cm/s; **sube** con la amplitud: +4.66 cm por volt a 50 Hz, +6.90 cm por volt a 200 Hz.
- [P5]: ≈+60 mm/s durante la estimulación abdominal. [P12]: de 23.81 ± 15.75 a 56.78 ± 20.86 mm/s.
- Velocidad de crucero de referencia: ≈3 cm/s [P2][P4]; 3–5.5 cm/s en tubería [P10].

**Alto.** [P7]: el estímulo de desaceleración en el tórax baja la velocidad de 6.3 a 2.0 cm/s (68.2 %), con el mínimo a 0.33 s. [P3]: señal sostenida >2 V en el ganglio detiene la marcha.

**Retroceso.** Ninguna fuente lo produce a propósito. En [P4] aparece como conducta natural frente a un muro.

**Tasa de éxito.**

| Métrica | Valor | Fuente |
|---|---|---|
| Individuos «respondedores fuertes», bifásico 2 V / 50 Hz / 1.5 s | 56 % | [P1] Fig. 5 |
| Ídem, 3 V / 200 Hz | 63 % | [P1] Fig. 5 |
| Ídem, monofásico positivo | 41–47 % | [P1] |
| Por estímulo, giro izquierda y derecha, no invasivo | 80.7 % | [P5] (10 insectos, 150 estímulos) |
| Por estímulo, aceleración, no invasivo | 74.0 % | [P5] |
| Giro a un círculo objetivo, ganglio protorácico | ≈60 % (izquierda 63 ± 4.8 %, derecha 56 ± 15.0 %) | [P3] (10 insectos × 20 ensayos) |
| Atado, *Periplaneta*, ganglio | ≈70 % | [P3] |
| Vuelta completa a una trayectoria en S, ida y vuelta | ≈10 % | [P2] |
| Sujetos dirigibles en zigzag con cable (1998) | 3 de 50 | Moore et al. 1998, citado en [P1]; no leído |

**Latencia y duración.** Está mal documentada. [P1] no la mide; dice que casi todo el movimiento ocurre en los primeros 3–4 s y se apaga 1.5–2.5 s después del tren. [P7]: mínimo de velocidad a 0.33 s. [P3]: la latencia aumenta con los ensayos (valores solo en figuras). [P8] reporta 0.10–0.12 s, pero es el retraso de la señal electrónica, no del insecto.

### D. Habituación

**Cómo decae.**
- [P1]: con monofásico, el avance cayó ≈80 % tras ~40 ensayos y el giro ≈30 % (un ejemplo, Fig. 6); suele aparecer entre los 20 y 80 estímulos. Con bifásico ≥2 V, estable 120 ensayos. Habituados: 31.3 % de los sujetos con monofásico (N = 32) contra 2.9 % con bifásico (N = 35). El intervalo entre ensayos no se declara; cada ensayo duraba 15 s.
- [P10]: reducción de la velocidad de giro tras 10 estímulos (5 insectos):

| Sitio | Cada 15 s | Cada 60 s | Cada 120 s |
|---|---|---|---|
| Antena (3 V) | 57.2 % | 57.9 % | 33.6 % |
| Cerco (4 V) | 47.5 % | 20 % | 30 % |

  Los datos no son monótonos (el cerco empeora de 60 a 120 s), así que hay ruido entre individuos.
- [S4]: la respuesta baja de forma notable tras unos 10 ensayos. [S1]: «unos minutos».
- [P3]: tras ≈1 h de control los insectos dejan de responder (lo atribuyen a fatiga, estimulación repetida y peso).
- [P13] (resumen): sin regulación, el control efectivo dura minutos.
- [P17] (confianza baja): la habituación de corto plazo empieza tras 6–12 episodios; vida media de la respuesta ≈68 estímulos con PID.

**Tasa por estímulo (derivado, suponiendo decaimiento multiplicativo sin recuperación):**
- Monofásico, avance [P1]: 0.2^(1/40) ≈ 0.961, es decir ≈3.9 % por estímulo. Giro: 0.7^(1/40) ≈ 0.991, ≈0.9 %.
- Antena cada 15 s [P10]: 0.428^(1/10) ≈ 0.919, ≈8.1 % por estímulo. Cada 120 s: ≈4.0 %.
- Cerco cada 15 s [P10]: ≈6.2 % por estímulo.

**Recuperación.**
- 10 min de descanso devuelven el control por otros 30–60 min, hasta ≈2 h en total [P3].
- ≈20 min en la jaula [S1]; «un par de horas» según los mismos autores en 2012 [S4]. No coinciden.
- 65 % a los 5 min y completa a los 15 min [P17] (confianza baja). Derivado: si fuera exponencial, constante de tiempo ≈4.8 min.
- Hay un componente lento que el descanso no arregla: umbral que sube pasados 45 min [P17]; la estimulación deja de servir del todo a los 2–7 días [S1] o ≈1 semana [S4], lo que apunta al electrodo y no a la habituación neural [P2][P15].

**Mitigaciones y resultado.**

| Estrategia | Resultado | Fuente |
|---|---|---|
| Onda bifásica en vez de monofásica | Habituados 2.9 % contra 31.3 %; índice de eficacia 20.5 contra 1.5 | [P1] |
| Alternar antena y cerco cada 5 estímulos (10 s entre estímulos, 57.5 s de descanso por sitio) | Más de 100 giros efectivos, velocidad >45 °/s | [P10] |
| Alternar cada 2 estímulos (23 s por sitio) | Falla: <30 °/s después de 29 giros | [P10] |
| Estimular solo cuando hace falta (umbral de ángulo, IMU detecta alto) | 94 % de éxito; el artículo no mide habituación | [P4] |
| Aprendizaje automático para detectar alto y estimular 1 s después | 3.4 s de estimulación por ensayo de 7 min; +70 % distancia, −78 % tiempo detenido | [P9] |
| Enjambre líder–seguidores | 50 % menos estimulación; seguidores libres la mitad del tiempo (0.5 contra 0.26) | [P6] |
| Regulador de voltaje + estímulo distinto para «reactivar» | Control hasta 3 h | [P13] (solo resumen; [P12] cita un trabajo de Li et al., probablemente este, como ≈3 veces más marcha con amplitud variable) |
| Luz UV en vez de electricidad | Sin habituación en 150 ensayos | [P14] resumen, [S5] prensa |
| Controlador difuso adaptativo (ANFIS) | Vida media >250 estímulos contra ≈68; 47 contra 26 min de control | [P17] (confianza baja) |

No encontré ningún trabajo que aleatorice parámetros como estrategia medida, pese a que la pista lo sugería.

### E. Modelo eléctrico del tejido y circuito

**Impedancia.**
- Implantado, antena + cercos: no medida. A 3 V bifásico y 50 Hz, corriente media 737 ± 44 µA, pico 2.78 mA, transitorio exponencial con constante RC ≈ 1 ms [P1] Fig. 11. El artículo no aclara si la corriente es por electrodo o la suma de los tres.
  - Derivado: resistencia serie ≈ 3 V / 2.78 mA ≈ **1.1 kΩ**; capacitancia de doble capa ≈ 1 ms / 1.1 kΩ ≈ **0.9 µF**; resistencia efectiva media ≈ 3 V / 0.737 mA ≈ 4.1 kΩ; carga por fase (10 ms) ≈ 7.4 µC.
- Modelo de circuito: resistencia de transferencia de carga en paralelo con capacitancia de doble capa en cada interfaz, en serie con la resistencia del tejido [P2] Fig. 2B (sin valores).
- No invasivo, a 1 kHz: antena–tierra 123.0 ± 14.2 kΩ (izquierda) y 123.3 ± 16.6 kΩ (derecha); 6.º segmento–tierra 70.3 ± 6.2 kΩ (3 insectos) [P12] Tabla 5.
- [P7] da <70 Ω para su electrodo cobreado y «más de 1000 Ω» para el no invasivo de [P5]; parece ser la impedancia del electrodo, no del conjunto con tejido. No cuadra con los 70–123 kΩ de [P12].
- [P5]: el implantado tiene menor impedancia que el no invasivo entre 10 y 100 Hz, sin cifras en el texto.

**Potencia.**
- Estimulación: 2.2 ± 0.13 mW a 3 V, 50 Hz, bifásico [P1]. Derivado: un tren de 0.5 s cuesta ≈1.1 mJ.
- [P4] cita «tan poco como 0.1 mW» para control de locomoción en trabajos previos (no verificado).
- Sistema completo: 205.5 mW (2.2 h con 120 mAh), de los cuales IMU 11.55 mW, cámara térmica 21.45 mW, detección de personas 24 mW [P4]. 73.3 mW, casi todo en el radio [P8].
- [P1] estima ≈6,500 estímulos y 1.62 km con una batería de 2000 mAh; con su propia corriente la cuenta da unas mil veces más. No usar ese número.

**Circuito generador.**

| Circuito | Detalle | Fuente |
|---|---|---|
| Salida directa del microcontrolador | PIC16F630, pulsos de 3 V CC; luego CC2530 con ADC para vigilar la interfaz | [P2] |
| Salida directa | CC2531, 2 pines, +2.5 V, 1–20 Hz | [P3] |
| PWM por interrupción | SAMD21, 50 Hz, 50 % | [P9] |
| PWM | Arduino Pro Mini, 3.3 V pico a pico, 50 Hz, 50 % | [P8] |
| DAC | AD5504 de 4 canales y 12 bits (7.3 mV por paso), alimentado hasta 12 V por un elevador TPS61046; MSP432P4011 | [P4], [P11] |
| Pin + potenciómetro digital + capacitor en serie | Batería de 3 V; el capacitor quita la componente continua | [S3] |
| Temporizador 551 astable + capacitor de salida | Versión de 2012, 55 Hz | [S4] |
| Banco de pruebas | Tarjetas NI USB-6251 + estimulador tipo Wagenaar, modo voltaje (0–5 V) o corriente (0–200 µA) | [P1] |

Ninguna fuente describe un puente H. Inferencia de diseño (mía, no de las fuentes): dos pines del microcontrolador en contrafase a través del par de electrodos dan una bifásica de ±Vdd sin componentes extra; un capacitor en serie, como en [S3], garantiza el balance de carga.

### F. Control en lazo cerrado

**Navegación con IMU y obstáculos [P4]** (5 insectos, 49–50 ensayos por condición, límite 100 s, posición por captura de movimiento Vicon a 100 cuadros/s):

| Condición | Control simple | Control predictivo |
|---|---|---|
| Obstáculos bajos (1.5 cm), éxito | 100 % | 100 % |
| Obstáculos bajos, tiempo | 8.29 ± 6.29 s | 6.35 ± 4.92 s (p = 0.09) |
| Muros altos (10 cm), éxito | 26 % (13 de 50; derivado de 37 fallos) | 94 % (el texto dice 3 fallos de 49; el pie de la Fig. 4 dice 45 éxitos y 4 fallos, que daría 92 %) |
| Muros altos, tiempo | 48.98 ± 19.49 s | 33.91 ± 18.35 s (p < 0.01) |
| Tiempo en reversa | 40.93 ± 13.34 s de 100 s en los fallos por tiempo | 5.15 ± 5.33 s |

- Algoritmo simple: cada 30 ms calcula el ángulo entre el rumbo y el destino; si supera un umbral, estimula el cerco correspondiente.
- Algoritmo predictivo (máquina de estados): si al dirigir la velocidad angular cae bajo su umbral (el insecto está atorado) o si al caminar libre la velocidad lineal cae bajo el suyo (se va a detener), corta el giro y manda una aceleración con ambos cercos. Los umbrales están en la Tabla S4, que no pude leer.
- De los 37 fallos del simple: 17 inmóvil con estimulación, 16 inmóvil sin estimulación, 4 por tiempo.

**Detección de personas [P4].** Termopila Heimann HTPA 32×32 (90° × 90°, 0.99 g, 21.45 mW). Filtro de mediana 3×3 → HOG con celda 4×4 → SVM lineal en un MSP432P4011. Exactitud media **87 %**, exhaustividad 90 % entre 0.5 y 1.5 m, 95 ms por imagen, 18.3 kB de flash y 52.2 kB de RAM, 24 mW. Entrenado con 11,171 imágenes de personas y 11,493 de objetos calientes. Se activa solo si hay más de 15 pixeles entre 28 y 38 °C. En la demostración (arena de 4.2 × 6 m, 5 destinos, 2 personas y 3 objetos calientes) clasificó bien a la persona 11 veces sin falsos positivos; hubo 9 aceleraciones automáticas. La posición seguía viniendo de cámaras externas.

**Otros resultados.**
- Evasión con cámara monocular y estimación de profundidad (procesada en una PC por Wi-Fi): éxito de 6.7 % a 73.3 % (15 ensayos por condición, 3 robots) [P11].
- Tubería oscura, autónomo con cámara e IMU: 4 robots, 20 ensayos, ≈10 vueltas y ≈40 cruces por corrida a 0.04 m/s; sin la estrategia, 0 de 10 completaron una vuelta. Umbral de IMU: 70° de giro; si no llega, otro pulso de 1 s [P10].
- Seguimiento manual de una S de 142.95 cm con dispositivo no invasivo: error cuadrático medio 2.91 ± 1.17 cm (5 ensayos, 3 insectos); por ensayo, 12.4 órdenes de giro a la izquierda, 14.2 a la derecha y 16.6 de aceleración [P12].
- Escarabajo tenebriónido (otra especie): controlador proporcional para giro y de empuje para avance; 71 % de éxito, 94 % con ajuste fino, precisión de medio cuerpo [P16] (resumen).
- Cobertura con 4 robots y estimulación aleatoria cada 10 s: 80.25 % de 2 × 2 m en 10 min 31 s; un solo robot, 14–46 % [P7].
- Laberinto con casco UV: 94 % de escape contra 24 % sin control; 81.3 % del movimiento fue natural y solo 18.7 % necesitó estímulo [S5] (prensa).
- Clasificador de movimiento con IMU (SVM lineal): 99.85 % en «detenido» y 98.64 % en «en movimiento» [P9]. Corre en una PC, no en la mochila.

**Enjambre [P6].** 20 insectos (1 líder, 19 seguidores) en arena de 3.5 × 3.5 m con rocas y lomas, 10 ensayos. Grado de autonomía (tiempo sin estimulación entre tiempo total): 0.26 en el líder con control convencional, 0.5 en los seguidores. Estimulación ≈50 % menor que con control individual. Enredos (distancia <6 cm) 85 % menos que con el algoritmo BOIDS. Un insecto volteado luchó 26.5 s solo y se enderezó en 4.5 s al agarrarse de un vecino. El artículo no da tasa de éxito ni velocidad, y la localización es centralizada.

**Grupo de Bozkurt (NC State), sin números verificados.** Whitmire 2013 (Kinect para seguir líneas de forma automática), Latif 2016 (arreglo de micrófonos para ir hacia un sonido; [P4] le atribuye 36 mW solo en transmitir audio), Cole 2020 (odometría con IMU, «precisión de centímetros» en 9 ensayos, procesada después) y Dirafzoon 2017 (mapeo topológico; las pruebas físicas parecen ser con robots Hexbug, no con insectos). Todo esto viene de resúmenes.

### G. Efecto en el insecto

- **Supervivencia tras implantar:** ningún artículo leído da una curva de supervivencia. [P3] regresa los insectos a la colonia sin seguimiento. [P1] no reporta nada. Es el hueco más grande.
- **Vida útil del electrodo:** 2–7 días [S1]; ≈1 semana [S4]; meta de ≥1 semana, con decaimiento gradual observado a veces [P15]. El acero inoxidable es electroquímicamente mediocre; el oro recubierto con PEDOT:PSS tiene ≈50 veces la capacidad de carga del oro solo (en solución salina, no en el insecto) [P15].
- **Daño funcional:** la antena implantada deja de servir para sentir obstáculos [P5][P12]. La estimulación sube el metabolismo: 23.2 ml/h de CO2 caminando estimulado con mochila contra 12 ml/h caminando sin mochila [P10].
- **No invasivo:** adhesión ≈100 kPa; impedancia del gel estable 140 días en aire [P5]. No hay datos de cuánto dura puesto en un insecto.
- **Anestesia:** hielo o 4 °C por 30–60 min [P1][P2][P9]; CO2 por 30 s [P4][P12], 1 min [P10] o 10 min [P7]. Recuperación de 30–60 min con lámpara [P1] o más de 24 h [P9].
- **Tiempo de ensamble:** 68 s con brazo robótico contra ≈15 min a mano [P7][P11]; ≈2 min para dos orificios en el pronoto [P3]; 1–2 h para un principiante con el kit [S2].
- **Carga:** capacidad citada de 15 g [P4][P5]; mochilas de 2.3 g [P7], 3.0 g [P3], 4 g [P2], 4.4 g [S1], 5.5 g [P4][P10] y ≈7.4 g con batería [P9] (derivado). [P2] observó que el peso empeora el resultado y [P10] que 5.5 g es casi el peso del insecto (6.1 g).

### H. Límites y fracasos documentados

- La mitad de los individuos no responde bien ni con los mejores parámetros [P1]; en 1998, 3 de 50 (Moore, vía [P1]).
- Giros al revés con ≥3 V; sacudidas o congelamiento con 4 V / 200 Hz o trenes ≥0.5 s [P1].
- Más difícil evocar respuesta con temperatura externa de ≈30 °C; tras la cirugía los calentaban a 35 °C [P1].
- Respuesta no predecible ensayo a ensayo: |r| de 0.1 a 0.4; ángulo de 0 a 109° con los mismos parámetros [P1][P5].
- Insecto que se queda quieto: 16 de 37 fallos fueron inmovilidad sin estimulación [P4]; un insecto sin estimular estuvo detenido los 420 s completos y aun estimulado hubo paros de 118 s [P9].
- Un fallo por estímulo de cada cinco (19.3 % en giro, 26 % en aceleración) [P5].
- Asimetría izquierda–derecha: 10.8 % a 21.7 % [P7]; giros a la izquierda más fáciles [P3].
- Electrodos que se zafan y batería que al bajar degrada la señal [P3].
- El ensamble automático falla en insectos grandes: 86.7 % de éxito para 5.5–6.0 cm, 13 % para 6.5–7.0 cm [P7].
- Todo el lazo cerrado publicado depende de captura de movimiento externa o de una PC [P4][P6][P9][P11]. Nadie ha cerrado el lazo solo con lo que va en la mochila.

---

## Tabla de datos duros

| Dato | Valor | Condiciones | Fuente | Año | Confianza |
|---|---|---|---|---|---|
| Forma de onda recomendada | Cuadrada bifásica, 50 % de ciclo | Varios sitios | [P1][P4][P5][P7][P12] | 2015–2025 | Alta |
| Frecuencia | 40–55 Hz | Antena, cerco, abdomen, tórax | [P1] 50; [P4] 40; [P5][P7][P12] 42; [P10] 50; [S4] 55 | 2012–2025 | Alta |
| Dependencia con la frecuencia | No fuerte entre 50 y 300 Hz | Antena + cercos | [P1] | 2015 | Media |
| Voltaje, implantado (antena, cerco o tórax) | 2–3 V (2 V recomendado en antena + cercos) | Bifásico | [P1][P7][P11]; ≤2.5 V [P6] | 2015–2025 | Alta |
| Voltaje, no invasivo | 4 V; 2.0–3.5 V | Gel + oro; cobreado | [P5]; [P12] | 2023; 2025 | Media |
| Voltaje atípico | 6–8 V | Cerco–abdomen, 40 Hz | [P4] | 2023 | Media (una fuente, contradice a las demás) |
| Corriente controlada eficaz | 150 µA a 50 Hz → 54 % | Bifásica | [P1] | 2015 | Media |
| Duración del tren | 0.25–1 s | — | [P1] 0.25–0.5; [P7] 0.4; [P12] 0.6; [P5][P10] 1 | 2015–2025 | Alta |
| Respondedores fuertes | 56 % (2 V, 50 Hz); 63 % (3 V, 200 Hz) | Bifásico, 1.5 s, sobre esfera | [P1] | 2015 | Media |
| Éxito por estímulo, giro | 80.7 % | No invasivo, 4 V, 42 Hz, 1 s, 10 insectos | [P5] | 2023 | Media |
| Éxito por estímulo, aceleración | 74.0 % | Ídem | [P5] | 2023 | Media |
| Éxito de giro, ganglio | ≈60 % | 2.5 V monofásico, 10 insectos | [P3] | 2015 | Media |
| Giro por estímulo | 149° → 80° al subir de 1 a 4 V | Bifásico, 1.5 s | [P1] | 2015 | Media |
| Pendiente giro–voltaje | −21.2° por V (50 Hz) | r = −0.24 | [P1] Tabla 3 | 2015 | Media |
| Pendiente avance–voltaje | +4.66 cm por V (50 Hz) | r = 0.23 | [P1] Tabla 3 | 2015 | Media |
| Giro medio, no invasivo | 38.5° / 38.4° (máx. ≈106–109°) | 4 V, 1 s | [P5] | 2023 | Media |
| Giro medio, torácico | 70.9° / 79.5° | 3 V, 42 Hz, 0.4 s | [P7] | 2025 | Media |
| Giro, unipolar | ≈90° | 3–4 V, 50 Hz, 1 s | [P10] | 2023 | Media |
| Velocidad angular inducida | ≈60 °/s | Varias | [P1] 41–63; [P5] ≈60; [P12] 53–65; [P10] 33–80 | 2015–2025 | Alta |
| Avance por estímulo | 15.6–25.6 cm a 3.9–5.6 cm/s | Antena + cercos | [P1] | 2015 | Media |
| Aumento de velocidad lineal | ≈+60 mm/s; 23.8 → 56.8 mm/s | Abdomen no invasivo | [P5]; [P12] | 2023; 2025 | Alta |
| Desaceleración | 6.3 → 2.0 cm/s (68.2 %) en 0.33 s | Tórax, 3 V, 42 Hz, 0.4 s | [P7] | 2025 | Media |
| Habituación, monofásico | Avance −80 % en ~40 ensayos | Un ejemplo | [P1] Fig. 6 | 2015 | Media |
| Habituación, bifásico ≥2 V | Estable 120 ensayos | Un ejemplo | [P1] Fig. 6 | 2015 | Media |
| Sujetos habituados | 31.3 % monofásico; 2.9 % bifásico | N = 32 y 35 | [P1] Tabla 2 | 2015 | Media |
| Habituación antena, 10 estímulos | −57.2 % (15 s), −57.9 % (60 s), −33.6 % (120 s) | 3 V, 50 Hz, unipolar | [P10] Fig. 4 | 2023 | Media |
| Habituación cerco, 10 estímulos | −47.5 %, −20 %, −30 % | 4 V | [P10] Fig. 4 | 2023 | Media |
| Alternar sitio cada 5 | >100 giros efectivos | 10 s entre estímulos | [P10] | 2023 | Media |
| Recuperación con descanso | 10 min → 30–60 min más de control | Tras ≈1 h | [P3] | 2015 | Media |
| Recuperación con descanso | ≈20 min; «un par de horas» | Kit comercial | [S1]; [S4] | —; 2012 | Baja (se contradicen) |
| Control sostenido con regulador | Hasta 3 h | Solo resumen | [P13] | 2024 | Baja |
| Corriente de estimulación | 737 ± 44 µA media; 2.78 mA pico | 3 V, 50 Hz, bifásico | [P1] Fig. 11 | 2015 | Media (una sola fuente) |
| Potencia de estimulación | 2.2 ± 0.13 mW | Ídem | [P1] | 2015 | Media (una sola fuente) |
| Constante RC de la interfaz | ≈1 ms | Ídem | [P1] | 2015 | Media (una sola fuente) |
| Resistencia serie implantado | ≈1.1 kΩ | Derivado de [P1] | — | — | Baja (derivado) |
| Impedancia no invasiva a 1 kHz | 123 kΩ antena; 70 kΩ abdomen | 3 insectos | [P12] Tabla 5 | 2025 | Media (una sola fuente) |
| Límite en la interfaz | <0.7 V | Ventana del agua | [P2] | 2012 | Media |
| Potencia total de mochila | 205.5 mW; 73.3 mW | Con cámara e IMU; solo radio + estímulo | [P4]; [P8] | 2023; 2022 | Alta |
| Navegación, muros de 10 cm | 94 % predictivo; 26 % simple | 5 insectos, 49–50 ensayos | [P4] | 2023 | Media |
| Tiempo de navegación, muros | 33.91 ± 18.35 s contra 48.98 ± 19.49 s | Ídem | [P4] | 2023 | Media |
| Detección de personas | 87 % exactitud; 90 % exhaustividad a 0.5–1.5 m | IR 32×32, HOG + SVM lineal, 95 ms | [P4] | 2023 | Media (una sola fuente) |
| Evasión con cámara | 6.7 % → 73.3 % | 15 ensayos por condición | [P11] | 2024 | Media |
| Enjambre | 20 insectos; −50 % estimulación; −85 % enredos | Arena de 3.5 m, 10 ensayos | [P6] | 2025 | Media |
| Aprendizaje automático | +68 % búsqueda, +70 % distancia, −78 % paro | 3 insectos × 3 ensayos | [P9] | 2023 | Media (muestra pequeña) |
| Casco UV | 94 % contra 24 % de escape; 150 ensayos sin habituación | Laberinto | [S5] | 2025 | Baja (prensa) |
| Ensamble | 68 s automático; ≈15 min manual | Brazo UR3e | [P7]; [P11] | 2025; 2024 | Alta |
| Vida útil del implante | 2–7 días; ≈1 semana | Kit comercial | [S1]; [S4] | —; 2012 | Media |
| Paso de obstáculo grande | 23.16 s no invasivo contra 78.25 s implantado | 30 ensayos por condición | [P12] | 2025 | Media |

---

## Tabla comparativa de estudios

| Grupo | Especie | Sitio | Forma de onda | V | Hz | Conducta | Tasa de éxito |
|---|---|---|---|---|---|---|---|
| Erickson et al., Bowdoin [P1] | *G. portentosa* | Antena + ambos cercos, implantado | Bifásica cuadrada, 50 % | 2 (1–4 probados) | 50 (50–300) | Giro contralateral + avance | 56–63 % de individuos |
| Latif y Bozkurt, NC State [P2] | *G. portentosa* | Antena, implantado | Monofásica CC | 3 | No reportado | Giro contralateral | ≈10 % (vuelta en S) |
| Sanchez, Liang et al., Texas A&M [P3] | *B. discoidalis*, *P. americana* | Ganglio protorácico | Monofásica | 2.5 (1 atado) | 1–20 | Giro contralateral; alto | ≈60 % (70 % atado) |
| Tran-Ngoc, Sato et al., NTU [P4] | *G. portentosa* | Cerco–abdomen, implantado | Bifásica, 50 % | 6–8 | 40 | Giro (un cerco), aceleración (ambos) | 94 % de navegaciones (predictivo) |
| Lin, Sato et al., NTU [P5] | *G. portentosa* | Antena y abdomen, no invasivo | Bifásica, 12 ms | 4 | 42 | Giro y aceleración | 80.7 % y 74.0 % por estímulo |
| Bai, Sato, Ogura et al. [P6] | *G. portentosa* | No declarado en el texto principal | No declarado | ≤2.5 | No declarado | Giro y aceleración | No reportada |
| Lin, Sato et al., NTU [P7] | *G. portentosa* | Membrana pronoto–mesotórax | Bifásica | 3.0 | 42 | Giro y desaceleración | Giro >70°; ensamble 80–87 % en tallas chicas |
| Kakei, Fukuda et al., RIKEN [P8] | *G. portentosa* | Cerco, implantado | PWM rectangular, 50 % | 3.3 pico a pico | 50 | Giro ipsilateral | No reportada (5 intentos) |
| Ariyanto, Morishima et al., Osaka [P9] | *G. portentosa* | Ambos cercos, implantado | PWM, 50 % | No reportado | 50 | Arranque | No aplica (−78 % de paro) |
| Ma, Li et al. [P10] | *G. portentosa* | Antena y cerco, implantado | Unipolar, 50 % | 3 antena, 4 cerco | 50 | Giro (antena contralateral, cerco ipsilateral), avance | ≈10 vueltas por corrida autónoma (4 robots, 20 ensayos); 0 de 10 sin estrategia |
| Li, Sato et al., NTU [P11] | *G. portentosa* | Antenas (giro), cercos (avance) | No reportada | <3 | No reportado | Giro contralateral, avance | 73.3 % con evasión |
| Tran-Ngoc, Sato et al., NTU [P12] | *G. portentosa* | Escapo de antena y abdomen, no invasivo | Bifásica, 50 % | 2.0–3.5 | 42 | Giro y aceleración | No reportada (error 2.91 cm) |
| Refat, Morishima et al., Osaka [P14] | Cucaracha (especie no confirmada en lo leído) | Ojos compuestos, luz UV | No eléctrico | — | — | Giro contralateral, arranque | 94 % de escape (prensa) |
| Backyard Brains [S1]–[S4] | Cucaracha discoide | Antena, implantado | Bifásica | ≈3 (batería) | 55 | Giro contralateral | No reportada |

---

## Contradicciones y huecos

**Contradicciones entre fuentes (sin promediar).**

1. **Sentido del giro al estimular un cerco.** [P4]: cerco izquierdo → giro a la derecha. [P8] y [P10]: cerco derecho → giro a la derecha. [P4] y [P8] comparten coautor (H. Sato). Puede depender de cómo se cierra el circuito (cerco–abdomen del mismo lado en [P4]), pero ninguno lo explica. Hay que medirlo en el prototipo antes de fijar el signo del controlador.
2. **Voltaje.** 2 V [P1], ≤2.5 V [P6], <3 V [P11], 3 V [P7] contra 6–8 V [P4]. Además [P3] dice que más de 2 V sostenido detiene al insecto y aun así usa 2.5 V.
3. **Más voltaje no es más giro.** En [P1] el giro baja al subir el voltaje (más avance, menos giro). En [P5] y [P7] las espigas neuronales suben con el voltaje hasta aplanarse. [P14] reporta más giro con más luz UV. No son comparables de forma directa, pero un modelo lineal «más amplitud, más giro» sería falso para el caso eléctrico.
4. **Recuperación de la habituación.** 10 min [P3], ≈20 min [S1], «un par de horas» [S4], 15 min [P17].
5. **Intervalo y habituación.** En [P10] 15 s y 60 s dan lo mismo en antena (57.2 % y 57.9 %), y en cerco 60 s sale mejor que 120 s. No hay una curva limpia.
6. **Impedancia no invasiva.** «Más de 1000 Ω» según [P7] contra 70–123 kΩ medidos en [P12]. Distintas definiciones y frecuencias.
7. **Duración óptima.** El resumen de [P1] dice 0.5 s y su discusión 0.25 s; el mejor porcentaje (63 %) sale a 3 V / 200 Hz, no a los 2 V / 50 Hz que recomienda.
8. **Tiempo de preparación.** ≈2 min [P3], ≈15 min [P7][P11], 1–2 h [S2]. Procedimientos y pericia distintos.
9. **Autoría.** La pista atribuía Ariyanto 2023 al grupo de Sato; es del grupo de Morishima (Osaka) [P9].
10. **Kakei 2022.** La prensa habla de Bluetooth y de «control de patas»; el artículo usa un radio nRF24L01+ y estimula cercos [P8].
11. **[P17]** tiene inconsistencias internas (5 o 24 insectos; 3.5 veces o 1.8 veces más duración; referencias que no corresponden). Úsese solo como indicio.
12. **Éxito del control predictivo en [P4].** El texto dice 94 % con 3 fallos de 49; el pie de la Fig. 4 cuenta 45 éxitos y 4 fallos (92 %). Citar 94 % como «según el texto».
13. **Autonomía de batería en [P1].** Los ≈6,500 estímulos por batería de 2000 mAh no salen de su propia corriente medida (737 µA); la cuenta da unas mil veces más.

**Huecos.**

- No hay curva de supervivencia tras implantar en ningún artículo leído.
- No hay latencia estímulo–respuesta medida en *G. portentosa*.
- No hay impedancia electrodo–tejido medida con electrodo implantado en antena o cerco; solo la estimación derivada de [P1].
- No hay una curva de habituación con constante de tiempo ajustada; solo puntos sueltos ([P1] Fig. 6, [P10] Fig. 4).
- El artículo que más importa para habituación [P13] quedó sin leer completo.
- Los umbrales del control predictivo de [P4] y los parámetros del enjambre [P6] están en suplementos que no consulté.
- Nadie reporta un sistema que navegue solo con sensores a bordo, sin cámaras externas.
- No encontré estimulación de patas, ni térmica o mecánica a bordo, ni aleatorización de parámetros como estrategia medida.

---

## Parámetros recomendados para un modelo estímulo–respuesta con habituación

**Estructura sugerida** (un estado de habituación por sitio y uno lento global):

- Respuesta del ensayo n: giro = B(n) · θ0(V, T) · (1 − H_sitio) · (1 − H_lento) + ruido, donde B(n) es 1 con probabilidad p y 0 si no responde.
- Tras cada estímulo: H_sitio ← H_sitio + α · (1 − H_sitio).
- Entre estímulos: H_sitio ← H_sitio · exp(−Δt / τ_r).
- H_lento crece con el tiempo total de sesión y se recupera con descansos de minutos.

| Parámetro | Valor inicial | Con qué se ajusta |
|---|---|---|
| Señal | Bifásica, 50 Hz, 50 %, 2–3 V, tren de 0.5 s | [P1], [P7] |
| p (probabilidad de responder por estímulo) | 0.75–0.80 | [P5]: 80.7 % giro, 74.0 % aceleración |
| Fracción de individuos buenos | 0.5–0.6 | [P1]: 56–63 % |
| θ0, giro por estímulo | 40–90° para 0.4–1 s | [P5] 38°, [P7] 71–80°, [P10] ≈90° |
| Dependencia con el voltaje | −21° por V (giro), +4.7 cm por V (avance), con dispersión grande | [P1] Tabla 3 y datos crudos |
| Velocidad angular durante el tren | ≈60 °/s | [P1][P5][P12] |
| Avance por estímulo de cercos | 15–25 cm, o +3 a +6 cm/s | [P1], [P5], [P12] |
| α, habituación por estímulo | 0.04–0.08 (unipolar o monofásico); ≈0 con bifásico ≥2 V en la primera hora | Derivado de [P1] Fig. 6 y [P10] Fig. 4 |
| τ_r, recuperación | 5–20 min (probar 10 min) | [P3], [S1], [P17] |
| Estado lento | Pérdida de respuesta a ≈60 min; 10 min de descanso la restauran | [P3] |
| Ruido | Desviación del orden de la media (ángulo de 0 a ≈110°) | [P5] Fig. 5, [P1] rangos intercuartiles |

**Datos para el ajuste.** Los únicos datos crudos abiertos son los de [P1] en Harvard Dataverse (doi:10.7910/DVN/DFHXMM): respuestas por ensayo en esfera, con 16–20 ensayos por condición y sujetos de hasta 120 ensayos, suficientes para ajustar θ0(V, f, T) y α. Para τ_r solo hay los tres intervalos de [P10] (15, 60 y 120 s), que habría que digitalizar de su Fig. 4; es un ajuste pobre y conviene decirlo en el reporte. Los valores de α y τ_r de la tabla son órdenes de magnitud, no constantes publicadas.

---

## Fuentes

**Primarias (artículos revisados por pares o preprints de los mismos).**

- **[P1]** Erickson J. C., Herrera M., Bustamante M., Shingiro A., Bowen T. (2015). Effective Stimulus Parameters for Directed Locomotion in Madagascar Hissing Cockroach Biobot. *PLoS ONE* 10(8): e0134348. https://pmc.ncbi.nlm.nih.gov/articles/PMC4550421/ — datos: https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/DFHXMM
- **[P2]** Latif T., Bozkurt A. (2012). Line Following Terrestrial Insect Biobots. *Proc. IEEE EMBC 2012*, pp. 972–975. https://ibionics.ece.ncsu.edu/assets/EMBC_12.pdf
- **[P3]** Sanchez C. J., Chiu C.-W., Zhou Y., González J. M., Vinson S. B., Liang H. (2015). Locomotion control of hybrid cockroach robots. *J. R. Soc. Interface* 12(105): 20141363. https://pmc.ncbi.nlm.nih.gov/articles/PMC4387526/
- **[P4]** Tran-Ngoc P. T., Le D. L., Chong B. S., Nguyen H. D., Dung V. T., Cao F., Li Y., Kai K., Gan J. H., Vo-Doan T. T., Nguyen T. L., Sato H. (2023). Intelligent Insect–Computer Hybrid Robot: Installing Innate Obstacle Negotiation and Onboard Human Detection onto Cyborg Insect. *Adv. Intell. Syst.* 5(5): 2200319. DOI 10.1002/aisy.202200319. Copia abierta: https://eprints.whiterose.ac.uk/200437/ (preprint: arXiv:2105.10869)
- **[P5]** Lin Q., Li R., Zhang F., Kai K., Ong Z. C., Chen X., Sato H. (2023). Resilient conductive membrane synthesized by in-situ polymerisation for wearable non-invasive electronics on moving appendages of cyborg insect. *npj Flexible Electronics* 7: 42. https://www.nature.com/articles/s41528-023-00274-z (preprint: https://arxiv.org/abs/2303.10990)
- **[P6]** Bai Y., Tran-Ngoc P. T., Nguyen H. D., Le D. L., Ha Q. H., Kai K., See To Y. X., Deng Y., Song J., Wakamiya N., Sato H., Ogura M. (2025). Swarm navigation of cyborg-insects in unknown obstructed soft terrain. *Nature Communications*. https://www.nature.com/articles/s41467-024-55197-8 (preprint: https://arxiv.org/abs/2403.17392)
- **[P7]** Lin et al., grupo de H. Sato (2025). Cyborg insect factory: automatic assembly for insect-computer hybrid robot via vision-guided robotic arm manipulation of custom bipolar electrodes. *Nature Communications*. https://www.nature.com/articles/s41467-025-60779-1 (preprint: https://arxiv.org/abs/2411.13164). Lista completa de autores no verificada.
- **[P8]** Kakei Y. et al., equipo de K. Fukuda, RIKEN (2022). Integration of body-mounted ultrasoft organic solar cell on cyborg insects with intact mobility. *npj Flexible Electronics* 6: 78. https://www.nature.com/articles/s41528-022-00207-2
- **[P9]** Ariyanto M., Refat C. M. M., Hirao K., Morishima K. (2023). Movement Optimization for a Cyborg Cockroach in a Bounded Space Incorporating Machine Learning. *Cyborg and Bionic Systems* 4: 0012. https://pmc.ncbi.nlm.nih.gov/articles/PMC10019993/
- **[P10]** Ma S., Chen Y., Yang S., Liu S., Tang L., Li B., Li Y. (2023). The Autonomous Pipeline Navigation of a Cockroach Bio-Robot with Enhanced Walking Stimuli. *Cyborg and Bionic Systems* 4: 0067. https://pmc.ncbi.nlm.nih.gov/articles/PMC10631459/
- **[P11]** Li R., Lin Q., Tran-Ngoc P. T., Le D. L., Sato H. (2024). Smart insect-computer hybrid robots empowered with enhanced obstacle avoidance capabilities using onboard monocular camera. *npj Robotics* 2: 2. https://www.nature.com/articles/s44182-024-00010-3
- **[P12]** Tran-Ngoc P. T., Song K., Tran T. H., Kai K., Lin Q., Sato H. (2025). Ergonomic Insect Headgear and Abdominal Buckle with Surface Stimulators Manufactured via Multimaterial 3D Printing. *Cyborg and Bionic Systems* 6: 0406. https://pmc.ncbi.nlm.nih.gov/articles/PMC12451109/
- **[P13]** Li R., Lin Q., Kai K., Nguyen H. D., Sato H. (2024). A Navigation Algorithm to Enable Sustainable Control of Insect-Computer Hybrid Robot with Stimulus Signal Regulator and Habituation-Breaking Function. *Soft Robotics* 11(3): 473–483. https://doi.org/10.1089/soro.2023.0064 — **solo resumen** (muro de pago).
- **[P14]** Refat C. M. M., Ariyanto M., Tanaka R., Yamamoto K., Morishima K. (2025). Autonomous Navigation of Bio-Intelligent Cyborg Insect Based on Insect Visual Perception. *Adv. Intell. Syst.* 7(10): 2400838. https://doi.org/10.1002/aisy.202400838 — **solo resumen** (403).
- **[P15]** Latif T., McKnight M., Dickey M. D., Bozkurt A. (2018). In vitro electrochemical assessment of electrodes for neurostimulation in roach biobots. *PLoS ONE* 13(10): e0203880. https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0203880
- **[P16]** Nguyen H. D., Dung V. T., Sato H., Vo-Doan T. T. (2023). Efficient autonomous navigation for terrestrial insect-machine hybrid systems. *Sensors and Actuators B* 376: 132988. https://arxiv.org/abs/2204.13281 — solo resumen; escarabajo, no cucaracha.
- **[P17]** Le M. T., Nguyen T. T. (2025). Mitigating Neural Habituation in Insect Bio-Bots: A Dual-Timescale Adaptive Control Approach. *Biomimetics* 11(1): 13. https://pmc.ncbi.nlm.nih.gov/articles/PMC12838690/ — confianza baja por inconsistencias internas.

**Secundarias (documentación comercial y prensa).**

- **[S1]** Backyard Brains, documentación del RoboRoach. https://docs.backyardbrains.com/neuroengineering/roboroach/
- **[S2]** Backyard Brains, cirugía del RoboRoach. https://backyardbrains.com/experiments/roboRoachSurgery
- **[S3]** Backyard Brains, foro: cómo funciona la mochila. https://forum.backyardbrains.com/t/how-does-the-roboroach-backpack-work/82
- **[S4]** Marzullo T., Gage G. (24-07-2012). Robo Roach. *Make*. https://makezine.com/article/science/robo-roach/
- **[S5]** Universidad de Osaka, nota de prensa (12-05-2025). https://resou.osaka-u.ac.jp/en/research/2025/20250512_1

**Citadas pero no leídas (verificar antes de usar en el reporte).**

- Whitmire E., Latif T., Bozkurt A. (2013). Kinect-based system for automated control of terrestrial insect biobots. *Proc. IEEE EMBC 2013*, pp. 1470–1473. PMID 24109976.
- Latif T., Whitmire E., Novak T., Bozkurt A. (2016). Sound Localization Sensors for Search and Rescue Biobots. *IEEE Sensors Journal* 16(10): 3444–3453. DOI 10.1109/JSEN.2015.2477443.
- Dirafzoon A., Bozkurt A., Lobaton E. (2017). A framework for mapping with biobotic insect networks: From local to global maps. *Robotics and Autonomous Systems*. DOI 10.1016/j.robot.2016.11.004.
- Cole J., Bozkurt A., Lobaton E. (2020). Localization of Biobotic Insects Using Low-Cost Inertial Measurement Units. *Sensors* 20(16): 4486. https://pmc.ncbi.nlm.nih.gov/articles/PMC7472076/
- Moore T. E., Crary S. B., Koditschek D. E., Conklin T. A. (1998). Directed locomotion in cockroaches: Biobots. *Acta Entomologica Slovenica* 6(2): 71–78.
- Holzer R., Shimoyama I. (1997). Locomotion control of a bio-robotic system via electric stimulation. *Proc. IEEE/RSJ IROS 1997*, pp. 1514–1519.
