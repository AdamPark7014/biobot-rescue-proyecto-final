# 04 — Búsqueda y rescate urbano: el problema, la práctica actual y la señal de una persona atrapada

Fecha de la investigación: 9 de noviembre de 2026.
Ángulo: dominio de búsqueda y rescate urbano (USAR) para el proyecto de biobots (cucaracha silbadora de Madagascar con mochila de sensores).

## Cómo leer estas notas

Cada dato lleva un nivel de verificación:

- **Leído**: abrí la página o el PDF y vi el número.
- **Resumen de búsqueda**: el número salió en el extracto del buscador, con la fuente identificada, pero no abrí el texto completo (muro de pago, 403 o PDF ilegible).
- **Sin confirmar**: lo busqué y no encontré una fuente que lo sostenga. No usar ante el profesor.

Límite de la sesión: el cupo de búsquedas web se agotó antes de cerrar cuatro puntos (temperatura de la ropa, CO2 exhalado, reporte del SSN de 1985 y ensayos con escarabajos de Queensland). Están marcados en «Contradicciones y huecos».

---

## Respuesta corta

1. **La «ventana de 72 horas» es una convención de planeación, no un umbral biológico.** No encontré un artículo que la derive. Lo que sí está medido: la gran mayoría de los sobrevivientes sale en las primeras 24 horas (93 % en Italia 1980), la supervivencia cae fuerte entre el día 2 y el 3 (cerca de 30 % en Kobe) y hay rescates documentados hasta 13–14 días. La enseñanza original en Estados Unidos hablaba de «48 horas doradas».
2. **A la gente la sacan sus vecinos.** En Kobe 1995, cerca de 80 % de los rescatados de edificios colapsados fue sacado por familia y vecinos, y solo 1.7 % por equipos de rescate en otra encuesta. En Armenia 1988, 2.5 %. Los equipos USAR y su tecnología trabajan sobre la fracción difícil: personas en huecos profundos.
3. **México 2017**: M 7.1, 57 km de profundidad, límite Puebla–Morelos, 369 muertos (45 en Puebla). El número de edificios colapsados en la CDMX cambia según la fuente (38, 44 o 46) y el de rescatados con vida también (69 según el gobierno, 115 según la Marina al tercer día).
4. **Ningún robot terrestre ha encontrado a una persona viva** en un desastre real (Murphy, 2021). El robot serpiente de Carnegie Mellon en México 2017 entró a un edificio, hizo dos pasadas y no encontró a nadie.
5. **El único despliegue real de insectos cíborg** fue en Myanmar (31 de marzo y 3 de abril de 2025): 10 cucarachas de HTX/NTU/Klass con la SCDF. No encontraron sobrevivientes y los ingenieros reportaron fallas técnicas.
6. **La firma térmica de una persona es débil y local.** El grupo de NTU detecta con una matriz de 32×32 píxeles entre 0.5 y 1.5 m. Un termopila de un píxel con campo de 90° promedia todo lo que ve: a medio metro una cara ocupa menos de 4 % del campo.
7. **La radio no atraviesa escombros con holgura.** NIST midió al menos 60–80 dB de pérdida en los escombros de un edificio de 13 pisos; el único robot inalámbrico del World Trade Center se perdió a 9–12 m de la entrada.
8. **La crítica más dura es de 2004 y sigue vigente**: Murphy escribió que soltar cientos de robots insecto que reportan a un operador es «físicamente impráctico» y choca con la organización del rescate.

---

## Hallazgos por sub-pregunta

### A. Supervivencia bajo escombros contra el tiempo

**No hay curva universal.** Macintyre, Barbera y Smith (2006) revisaron 34 sismos de 1985 a 2004: 48 artículos médicos con datos de tiempo al rescate, 25 de ellos con varios rescates después de 48 horas. En prensa hubo rescates después del día 2 en 18 de los 34 sismos. La supervivencia más larga reportada de forma confiable fue de 14 días (la siguiente, 13). El máximo promedio en esos 18 sismos fue 6.8 días (mediana 5.75). En Mármara 1999 hubo 43 rescates reportados entre 12 y 146 horas. (Leído, resumen de Cambridge.)

**Los mismos autores rechazan los plazos fijos.** En 2011 (tras Haití) escribieron que el tiempo de supervivencia «varía de incidente a incidente y hasta de sitio a sitio», que el factor más influyente es que existan huecos, y que los plazos rígidos de 2, 4 o 14 días no se sostienen. El caso de 27 días en Haití fue puesto en duda. (Leído, Science Media Centre NZ y resumen de Cambridge.) Según el extracto del artículo, la enseñanza temprana en Estados Unidos hablaba de «48 horas doradas», y el rescate documentado más largo en literatura médica fue de 8.7 días tras el sismo de la Ciudad de México de 1985. (Resumen de búsqueda.)

**Datos por sismo:**

- **Italia 1980 (Campania-Irpinia)**: encuesta a 3,619 sobrevivientes. El 93 % de los atrapados que sobrevivieron fue sacado en las primeras 24 horas; 95 % de las muertes ocurrió mientras la víctima seguía atrapada. (Leído, lección de Noji.)
- **Turquía y China, casas de tierra**: entre 2 y 6 horas después queda vivo menos de 50 % de los sepultados. (Leído, lección de Noji.)
- **Armenia 1988**: la mortalidad fue 67 veces mayor y las lesiones 11 veces mayores entre atrapados que entre no atrapados (Noji et al., 1990). Según otro artículo de 1993 en Int J Epidemiol, solo 2.5 % de los atrapados que sobrevivieron fue rescatado por especialistas soviéticos; al resto lo sacó gente sin entrenamiento, con las manos. (Resumen de búsqueda.)
- **Estimación de un experto, en prensa**: más de 90 % de los sobrevivientes de un sismo sale en los primeros tres días (Ilan Kelman, University College London, citado por AFP en 2023). Es lo más cercano que encontré a un sustento de las 72 horas, y no es un estudio.
- **Kobe 1995**: en las dos primeras semanas se rescató a 1,888 residentes en la ciudad de Kobe y solo 733 sobrevivieron (Kawata, 1995; leído). Eso da 38.8 % (cálculo mío). Shuto, citando a Kawata (1996): cerca de 80 % vivo entre los liberados por vecinos al inicio, cerca de 30 % en los días 2 y 3, y casi ninguna esperanza del día 4 en adelante. (Resumen de búsqueda.)
- **Turquía 2023**: un estudio hospitalario encontró que 21 horas de extracción era el punto de corte que mejor predecía mortalidad (sensibilidad 78.9 %, especificidad 86.4 %). En otra cohorte de 637 pacientes quirúrgicos, 18 de las 25 muertes tenían síndrome de aplastamiento. Hubo rescates aislados hasta el día 13. (Resumen de búsqueda.)

**Quién rescata.** El Libro Blanco de Gestión de Desastres de Japón (2014) da dos cifras de Kobe: cerca de 80 % de los rescatados de edificios colapsados fue sacado por familia o vecinos y cerca de 20 % por bomberos, policía y Fuerzas de Autodefensa; en otra encuesta, más de 90 % salió por sí mismo o con ayuda de familia, amigos o vecinos, y 1.7 % por equipos de rescate. (Leído.) Las dos encuestas tienen denominadores distintos.

**Lo que logran los equipos internacionales.** Haití 2010: la ONU contó 132 personas rescatadas por equipos USAR internacionales al 22 de enero, 47 por equipos de Estados Unidos (seis equipos, 511 personas, 51 millones de dólares; cerca de 1.1 millones por rescate, cálculo sobre esas cifras). Turquía 2023: INSARAG habla de unos 5,000 rescatistas en 90 equipos que «salvaron 300 vidas» (leído en la página del informe); otra fuente de INSARAG y AFAD cuenta 255 equipos internacionales. Noji: los equipos que llegan más de un par de días después «difícilmente cambian» el número de muertos.

**Causas de muerte.** Inmediatas: trauma de cráneo, tórax y abdomen, hemorragia. En horas: asfixia por polvo o compresión del tórax, choque hipovolémico. Después: síndrome de aplastamiento (lesión renal al liberar el músculo), hipotermia. (Resumen de búsqueda, revisión de 2025.)

**Tiempo de reconocimiento.** Confirmar dónde hay víctimas antes de extraer toma 3 horas en promedio (Casper, Micire y Murphy, 2000, citado por Tran-Ngoc et al., 2021; leído en la cita).

### B. México

**19 de septiembre de 2017 — Reporte Especial del SSN (leído completo, 6 páginas):**

- Magnitud 7.1, a las 13:14:40, hora del centro.
- Epicentro 18.40° N, −98.72° O, profundidad 57 km, «en el límite estatal entre los estados Puebla y Morelos, a 12 km al sureste de Axochiapan, Morelos y a 120 km de la Ciudad de México».
- Falla normal (rumbo 112, echado 46, desplazamiento −93), sismo intraplaca dentro de la placa de Cocos.
- Seis réplicas hasta las 18:00.
- Aceleraciones máximas en el Valle de México: Tlamacas 112 gal, Tlalpan 90, Coyoacán 60, Ciudad Universitaria 54, Tláhuac 32, Cuajimalpa 20.
- El reporte se generó el mismo día y advierte que no es definitivo. Wikipedia dice que el SSN reubicó después el epicentro a 8 km al noroeste de Chiautla de Tapia, Puebla, y que el USGS lo pone a 1 km de San Felipe Ayutla, Puebla (una sola fuente secundaria).

**Muertos**: 369 en total. Ciudad de México 228, Morelos 74, Puebla 45, Estado de México 15, Guerrero 6, Oaxaca 1. Dos fuentes secundarias coinciden: Animal Político (19-10-2017, «cifras oficiales», leído) y Wikipedia, que atribuye la cifra final a Luis Felipe Puente, coordinador nacional de Protección Civil, el 5 de octubre de 2017. No recuperé el comunicado original de Gobernación.

**Puebla (estado)**: 45 muertos; al menos 105 heridos; más de 12,000 viviendas y 250 inmuebles históricos afectados; declaratoria de emergencia en 112 municipios; 60 templos y 209 escuelas con daño. En Atzitzihuacán murieron 15 personas al caer un templo durante misa; en Atzala cayó la cúpula del templo de Santiago Apóstol durante un bautizo. (Todo de Wikipedia: una sola fuente secundaria.)

**Edificios colapsados en la CDMX — tres cifras:**

- 44: Galvis, Miranda, Heresi, Dávalos y Ruiz-García (2020), Earthquake Spectra (leído, resumen en repositorio). También Mancera habló de «44 puntos con derrumbes o colapsos».
- 46: reporte preliminar del mismo grupo en 2017 (resumen de búsqueda).
- 38: Wikipedia y un estudio de caso de Tlalpan (resumen de búsqueda).

Del estudio de Galvis: 64 % de los edificios colapsados tenía de 1 a 5 pisos; 61 % era de columnas de concreto con losa plana; 57 % falló por planta baja débil; 91 % era anterior a 1985; 43 % estaba en esquina.

**Rescatados con vida — dos cifras:**

- 69: Mancera el 23 de septiembre y Puente el 4 de octubre (resumen de búsqueda).
- 115: Secretaría de Marina al tercer día, con 88 cuerpos recuperados (resumen de búsqueda).

No hay explicación publicada de la diferencia. Marcar «sin confirmar con fuente primaria».

**Quién rescató:**

- **Marina**: la perra Frida tiene, según la SEMAR, al menos 12 personas localizadas con vida en su historial. Algunas notas lo atribuyen a 2017 y otras al total de su carrera; una sola nota agrega 43 cuerpos. La Marina reportaba 256 binomios caninos hacia 2019. (Resumen de búsqueda; no usar la cifra de Frida como dato de 2017.)
- **Topos**: nacieron de la organización civil de 1985. Hay dos grupos distintos (Brigada de Rescate Topos Tlatelolco, de rojo, y Topos Azteca, de naranja). No encontré un conteo oficial de rescates de 2017. Un integrante de «Topos Br19 Sep» habló de 22 personas vivas en Álvaro Obregón 286 junto con otros grupos (una sola fuente). En ese edificio murieron 49 personas.
- **Equipos extranjeros**: Japón 72 rescatistas, Israel 70, Estados Unidos 60, Panamá 35 con 4 perros, Topos Chile 18 con 2 perros (Wikipedia).
- **Robot serpiente de Carnegie Mellon**: ver C.

**19 de septiembre de 1985:**

- Mw 8.1 (UNAM), 07:17:49 hora local, frente a la costa de Michoacán, 15 km de profundidad (Wikipedia citando SSN/UNAM; no recuperé el reporte del SSN).
- **Muertos — sin cifra única**: 3,192 (oficial inicial); 3,692 actas del Registro Civil (conteo de 2011, prensa); 4,610 (Registro Civil según otra tabla); 6,000 (CENAPRED, vía revisión del Banco Mundial sobre Fonden, 2012); 6,000–7,000 (gobierno); 9,089 (comisión pluripartidista); 15,000 (Cruz Roja); 20,000 (embajador Gavin); hasta 40,000 atribuidos al Sismológico. Ante el profesor: «entre 3,192 oficiales y más de 10,000 estimados».
- **Edificios**: 412 destruidos y 5,728 afectados (IV Informe de Gobierno, 1 de septiembre de 1986); un informe del 24 de septiembre de 1985 daba 252 colapsados y 165 dañados.
- **Rescatados con vida**: 3,226 a diez días del sismo (IV Informe de Gobierno, Diario de los Debates); «más de 4,000» según La Jornada. Tres recién nacidos salieron del Hospital Juárez a los 7 días (Wikipedia, sin nota al pie).

**Exposición de Puebla**: la regionalización sísmica de la CFE (1993) pone a Puebla en la zona B (resumen de búsqueda, ponencia WCEE 2012; no verifiqué el mapa vigente). Sismos intraplaca que han dañado al estado (resumen de búsqueda): 15 de junio de 1999, Tehuacán, Mw 7.0, 70–80 km de profundidad, 17 muertos; 1980, magnitud 7.1 cerca de Acatlán de Osorio; 2017. El mapa de la figura 6 del reporte del SSN muestra esos epicentros alrededor del de 2017.

**CENAPRED 2017** (presentación de CEPAL que lo cita, resumen de búsqueda): los dos sismos de septiembre sumaron 468 muertes, 82 % de las 570 muertes por desastre del año, y cerca de 92 % de las pérdidas. Animal Político suma 471 (369 + 102).

### C. Estado de la práctica

**Fases de INSARAG (Anexo B20, leído):**

| Nivel | Nombre | Qué es |
|---|---|---|
| 1 | Evaluación de área amplia | Reconocimiento preliminar para sectorizar |
| 2 | Evaluación de sector | Identificar sitios con rescate vivo viable |
| 3 | Búsqueda y rescate primario | Avance rápido para maximizar vidas |
| 4 | Búsqueda y rescate secundario | Búsqueda a fondo en todos los huecos sobrevivibles |
| 5 | Cobertura total | Búsqueda completa de vivos y fallecidos; deslaminado del colapso |

Inferencia mía: el biobot encaja en el nivel 4, después de que el perro marca y antes de mover losas. Así se usó en Myanmar (perros primero, cucarachas después).

**Herramientas y límites:**

- **Binomio canino**: turnos de 12 horas; práctica en el Pentágono de 20 a 45 minutos sobre el escombro y un descanso igual; recertificación cada dos años (FEMA, página archivada de 2004, leída). Costo por equipo certificado: 50,000, 60,000 o 75,000 dólares según la página de la Search Dog Foundation que se lea; 10 a 12 meses de entrenamiento (resumen de búsqueda). El estado de Indiana dice mínimo dos años. En el World Trade Center los perros no pudieron trabajar los huecos: el fuego interfería con el olor y luego la lluvia lo lavó (Murphy, 2004, leído).
- **Detector acústico y sísmico** (Delsar LifeDetector): sensores sísmicos para golpes transmitidos por la estructura y uno acústico para gritos. Cables de 10 m; los materiales blandos absorben la vibración y obligan a acercar los sensores. Una comparación de MSHA y Johns Hopkins concluyó que lo sísmico rinde más que lo solo acústico y que la detección depende de la homogeneidad del escombro y de dónde están los huecos. (Resumen de búsqueda.) No encontré alcance en metros ni requisitos de silencio.
- **Cámara de búsqueda**: alcanza unos 18 pies (5.5 m) según Murphy (2021); en el WTC, en poste, veía unos 2 m dentro del hueco, y varias se derritieron.
- **Cámara térmica**: en el WTC las FLIR «no sirvieron»: el interior del escombro estaba tan caliente que habría enmascarado a un sobreviviente (Murphy, 2004, leído).
- **Radar FINDER (NASA/JPL y DHS)**: dos prototipos llegaron a Nepal el 29 de abril de 2015. Detectaron dos latidos bajo cada una de dos estructuras en Chautara; se rescató a cuatro hombres bajo unos 10 pies (3 m) de ladrillo, lodo y madera. En pruebas previas: hasta 30 pies (9 m) de escombro, 20 pies (6 m) de concreto sólido y 100 pies (30 m) en espacio abierto; localiza con unos 5 pies (1.5 m) de error. Licenciado a R4 Inc. y SpecOps Group. (Leído, JPL.) Peso de unas 20 libras: una sola fuente de prensa. Costo: sin dato.
- **Drones**: mapas y ortomosaicos, inspección de balcones; desde 1,000 dólares (Murphy, 2021).
- **Robots terrestres**: 50,000 a 150,000 dólares; han entrado más de 60 pies (18 m). Los más usados: Inuktun VGTV Extreme (orugas) y Active Scope Camera (serpiente japonesa). (Murphy, 2021, leído.)

**Robot serpiente de Carnegie Mellon, México 2017 (leído, comunicado de CMU):** equipo de tres personas invitado por un empresario y la Cruz Roja Mexicana; cuatro días de trabajo. Robot de 5 cm de diámetro y 94 cm de largo, 16 módulos, con cable. Lo usaron en un solo edificio de departamentos donde faltaban tres personas: dos pasadas con video, ningún sobreviviente. Dio vista a dos huecos que las cámaras de búsqueda no alcanzaban y confirmó uno vacío. Lecciones del propio equipo: mucha espera («hurry up and wait»); cuando entra la maquinaria pesada el robot ya no sirve; le faltaban sensor de gas, micrófono y bocina; el robot tenía más de diez años.

**World Trade Center 2001 (Murphy, 2004, leído completo):**

- Robots en sitio del 11 de septiembre al 2 de octubre. En la fase de rescate salieron ocho veces, se usaron en cuatro turnos y revisaron ocho huecos.
- Entraban de 5 a 20 m en el escombro contra 2 m de una cámara en poste.
- Tiempo promedio dentro de un hueco: 6 min 44 s; máximo 24 min 40 s.
- En un turno representativo de 12 horas, 13 minutos fueron de búsqueda; el resto, espera.
- No encontraron sobrevivientes; sí varios restos.
- Hubo que acortar el tiempo de arranque a menos de 2 minutos: los rescatistas se iban si el robot tardaba.

### D. Geometría de los escombros

**Tipos de colapso** (terminología de FEMA y NFPA 1670): apoyado (lean-to), en V, panqueque, voladizo y marco en A. El panqueque deja pocos o ningún hueco; las víctimas aparecen entre losas o en huecos formados por muebles o maquinaria. El apoyado deja un hueco junto al muro que quedó en pie; la V deja dos, uno junto a cada muro exterior. Una nota de 1998 dice que cerca de 25 % de las víctimas se encuentra en la fase de búsqueda en huecos (una sola fuente, baja confianza).

**No existe una distribución medida de tamaños de hueco.** Murphy (2004): «no se conoce una caracterización del terreno de escombros que indique los claros necesarios para los robots». Lo que hay son casos:

- WTC: huecos hacia la superficie «generalmente de menos de 1 m de ancho». La mayoría de los huecos explorados eran el interior de vigas cajón de 0.3 × 0.6 m y más de 10 m de largo.
- El robot que cabía: Inuktun de 0.17 × 0.32 × 0.06 m y 4.5 kg, con cable. Un pedazo de metal de 6 mm atascó una oruga por una holgura de 3 mm.
- México 2017: un robot de 5 cm de diámetro entró a dos huecos inaccesibles para las cámaras.
- El insecto: 5.7 ± 0.6 cm de largo y 6.32 ± 1.5 g (Tran-Ngoc et al., 2021, leído); con mochila, cerca de 1.5 cm de alto y 5.7 cm de largo (resumen de la versión de 2023). Sube obstáculos de 1.5 cm (48 de 49 intentos) y no puede con paredes de 10 cm: las bordea.

Dicho con cuidado: el insecto cabe por rendijas de 2 cm donde el robot más chico usado en campo necesita 6 cm de alto y 17 de ancho. Que esas rendijas conecten con huecos sobrevivibles no está medido.

**Ambiente dentro del escombro:**

- Polvo gris que cubre todo; por eso se prefiere cámara a color (un sobreviviente que se sacudió el polvo o sangra resalta). Murphy, 2004.
- Agua y lodo de tuberías rotas y rociadores; la cámara del robot estuvo tapada 18 % del tiempo.
- Calor en incendios activos; en Myanmar, cerca de 38 °C de ambiente.
- Aire: en un simulador de hueco con voluntarios, el CO2 subió a 1.6 % en promedio en la zona de respiración y el oxígeno no se dejó bajar de 19.1 % (Huo et al., 2011, leído el resumen).
- Temperatura y humedad dentro de escombros de sismo: sin dato medido en lo que encontré.

### E. Despliegues reales de insectos cíborg

**Myanmar 2025 (leído: The Star/Straits Times del 5-4-2025, comunicado de NTU del 28-7-2025 y nota del gobierno de Singapur del 12-8-2026):**

- Sismo de magnitud 7.7 el 28 de marzo de 2025; más de 3,000 muertos.
- La SCDF lanzó la Operación Lionheart el 29 de marzo: 80 personas y cuatro perros.
- El 30 de marzo se sumaron dos ingenieros de HTX y dos de Klass Engineering and Solutions con **10 cucarachas silbadoras de Madagascar** con mochila. NTU desarrolló la tecnología; no hay constancia de personal de NTU en campo.
- Primer uso: 31 de marzo, en un hospital colapsado (sitio del tamaño de dos canchas de futbol). Los perros barrieron una parte y luego las cucarachas buscaron más adentro durante unos 45 minutos.
- Dos usos más el 3 de abril en Naipyidó (un medio coreano dice 4 de abril).
- Sensores: cámara infrarroja y sensores; un algoritmo decide si hay señal de vida y manda el resultado por radio a los ingenieros.
- **Resultado: ningún sobreviviente encontrado.**
- Lo que dijeron: Ong Ka Hing (HTX), «tuvimos problemas técnicos y no ha sido fácil»; «probar en Singapur es muy distinto». El uso en campo estaba previsto para 2026 y se adelantó.
- La nota oficial de 2026 da unas 4 horas de operación y repite que no hubo sobrevivientes, aunque su título dice que las cucarachas «salvaron vidas». El título no tiene sustento en el propio texto.

**La mochila publicada por NTU (Tran-Ngoc et al., 2021, preprint leído completo; versión en Advanced Intelligent Systems, 2023):**

- Microcontrolador MSP432P4011; radio CC1352 con **Bluetooth 5.1 a 2.4 GHz**; IMU MPU9250.
- Cámara térmica Heimann HTPA32x32: matriz de termopilas de 32×32 píxeles, campo de 90° × 90°, 0.99 g, 21.45 mW.
- BME280 (temperatura y humedad) y CCS811 (compuestos volátiles).
- Batería de 120 mAh (2.5 g). Mochila completa: 5.5 g; carga máxima del insecto: 15 g.
- Consumo total 205.5 mW: hasta 2.2 horas. El algoritmo de detección consume 24 mW.
- Detección: filtro de mediana, HOG y SVM lineal, a 1 Hz. Se activa cuando al menos 15 píxeles caen en el rango de temperatura humana. Exactitud promedio 87 %; 90 % de recuperación entre 0.5 y 1.5 m; 95 ms por imagen.
- Demostración: distinguió a dos personas de tres objetos calientes (clasificó bien a la persona 11 veces).
- Velocidad promedio del insecto: 3 cm/s.
- Navegación: 94 % de éxito con paredes altas con el algoritmo predictivo, contra 12 de 49 con el simple.
- **En los experimentos de navegación la posición venía de un sistema externo de captura de movimiento (Vicon)**; solo en la demostración se usó la IMU. Los autores piden localización a bordo como trabajo futuro.

**Producción (Lin et al., 2025, Nature Communications):** ensamble automático en 68 segundos por insecto; giros de más de 70° y reducción de velocidad de 68.2 % con estímulos de 0.4 s; cuatro insectos cubrieron 80.25 % de un terreno exterior con obstáculos en 10 min 31 s (leído, resumen de arXiv). Prensa: 86.7 % de éxito en el ensamble y mochila de 2.3 g (una sola fuente). La línea sigue en prototipo.

**Enjambre (Bai et al., 2025, Nature Communications 16:221):** un líder y 19 seguidores; cerca de 50 % menos intervenciones de control (comunicados de prensa).

**Otros grupos:**

- **NC State (Bozkurt)**: localización con IMU de bajo costo (Cole, Bozkurt y Lobaton, 2020), arreglos de micrófonos para distinguir una voz de una fuga, un dron con baliza que define el área (20 m). Etapa de simulación y laboratorio.
- **Queensland (Vo-Doan)**: él mismo estima 5 a 10 años para ver equipos de insectos en emergencias reales (prensa).

**Ratas de APOPO (RescueRATs):** mochila de menos de 100 g (menos de 10 % del peso de la rata) con cámara y comunicación en dos vías; cambiaron la transmisión a WiFi HaLow. En enero de 2025 APOPO declaró que aún no se habían desplegado en un desastre real. El 25 de junio de 2026, en Antalya, dos ratas localizaron a dos víctimas simuladas ante tres organizaciones turcas de rescate; el proyecto se describe como «investigación en etapa tardía». (Leído, APOPO.) Sin evaluación independiente.

### F. Firma de una persona atrapada

**Temperatura:**

- Piel del tronco: 33.5 a 36.9 °C (Bierman, 1936, vía Wikipedia; es piel bajo la ropa).
- Frente medida con infrarrojo: rango normal de 31.0 a 35.6 °C en 1,000 sujetos (resumen de búsqueda; no identifiqué el artículo).
- Dedo medio: 29.1 ± 0.6 °C; se mueve entre 27 y 31 °C solo por la postura (resumen de búsqueda, estudio con 500 voluntarios).
- Emisividad de la piel usada en termografía: 0.98.
- Superficie de la ropa: **sin dato verificado**. Queda entre la piel y el ambiente.
- El margen entre detectar y fallar puede ser de 1 o 2 °C (Sandia, 1992, resumen de búsqueda).

Conclusión práctica: la piel expuesta de una persona viva está entre 27 y 35 °C según la zona. Los 36.5–37.5 °C son temperatura central y no se ven desde fuera.

**Cómo cae la lectura de un píxel con la distancia** (cálculo propio con la geometría de la hoja de datos):

- El MLX90614BAA tiene campo de 90°: el diámetro de la mancha es el doble de la distancia. Melexis: el valor medido es el promedio de todo lo que hay en el campo.
- Lectura ≈ T_fondo + f × (T_blanco − T_fondo), donde f es la fracción del campo que ocupa el blanco.
- Supuestos: cara de 0.03 m², piel a 33 °C, fondo a 22 °C.

| Distancia | Área de la mancha | Fracción que ocupa una cara | Lectura esperada |
|---|---|---|---|
| 0.1 m | 0.031 m² | ~100 % | ~33 °C |
| 0.3 m | 0.28 m² | 11 % | ~23.2 °C |
| 0.5 m | 0.79 m² | 3.8 % | ~22.4 °C |
| 1 m | 3.1 m² | 1 % | ~22.1 °C |

Con la variante de 5° la mancha a 1 m mide 8.7 cm y una cara sí la llena, pero la lectura sigue siendo la de la piel: 31–35 °C.

**CO2 y otros gases:**

- 1.6 % (16,000 ppm) en promedio en la zona de respiración de un hueco simulado tras horas de encierro (Huo et al., 2011).
- CO2, amoniaco y acetona funcionaron como marcadores; el amoniaco bajó cuando los voluntarios dormían.
- Sensor TGS4161: 350 a 10,000 ppm; lento para estabilizarse (JSME, 2006).
- Güntner et al. (2018): arreglo del tamaño de una palma para acetona, amoniaco e isopreno con exactitudes de 19, 21 y 3 ppb. Advierten que el CO2 solo puede venir de un incendio.
- Zhang et al. (2018): el CO2 reduce el área sospechosa y la cámara térmica confirma la posición. (Resumen de búsqueda; la página pidió verificación y no se abrió.)
- Cuánto sube el CO2 a una distancia dada de la víctima en escombro real: sin dato.

**Sonido:** voz normal, 60 dB LAeq a 1 m; conversación medida en campo, 55–66 dBA; voz fuerte, 74 dBA a 1 m (resúmenes de búsqueda). En campo libre cae unos 6 dB cada vez que se duplica la distancia; dentro del escombro la atenuación no está caracterizada. Los golpes viajan mejor por la estructura que por el aire.

**Movimiento y latido:** ver FINDER en C.

**Falsos positivos documentados:**

- Escombro caliente por incendio (WTC).
- Ambiente a 38 °C (Myanmar): el contraste con la piel desaparece o se invierte.
- Objetos calientes: NTU los separó por forma con la matriz de 32×32, no por temperatura.
- CO2 de combustión.
- Ruido de tuberías con fuga.
- Animales: no encontré tasas reportadas.

### G. Comunicación y localización bajo escombros

**Mediciones de NIST en demoliciones** (Holloway et al.; TN 1540, 1541 y 1542; IEEE Antennas and Propagation Magazine, 2014). Frecuencias: 50, 150, 225, 450, 900 MHz y 1.8 GHz (leído en el resumen). Pérdidas (resumen de búsqueda sobre los informes):

| Estructura | Pérdida |
|---|---|
| Edificio de departamentos de 13 pisos, escombro | al menos 60–80 dB |
| Centro de convenciones, escombro | al menos 30–40 dB |
| Centro de convenciones, interior a exterior (en pie) | 58–69 dB en promedio |
| Estadio, interior a exterior | 25–50 dB; máximo ~75 dB |

Son cotas inferiores: en varios puntos el receptor solo midió ruido. A veces la señal mejoró tras el colapso, si el transmisor quedó arriba de la pila.

**Por muro:** NISTIR 6055 (Stone, 1997) midió concreto, tabique y concreto armado de 0.5 a 2 GHz y de 3 a 8 GHz (leído en la ficha). No hay dato de laboratorio de NIST a 433 MHz ni a 2.4 GHz. Tablas secundarias que dicen citar a NIST: concreto de 203 mm, 23 dB a 900 MHz; de 102 mm, 12 dB. Una guía británica: concreto pesado, 10 dB a 900 MHz y 22 dB a 2.4 GHz, sin espesor. Una ponencia de 2003: 35 dB a 433 MHz y 50–60 dB a 2.4 GHz. **Las cifras a 2.4 GHz van de 22 a 60 dB: no usar una sola.**

**En campo:** el único robot inalámbrico del WTC (Solem) tuvo 1 min 40 s de cortes en una corrida de 7 min y se perdió del todo a 30–40 pies (9–12 m) de la entrada. Murphy recomienda cable o cuerda de seguridad. GPS no entra.

**Qué usaron los grupos de biobots:**

- NTU: Bluetooth 5.1 a 2.4 GHz; decisión a bordo porque transmitir video cuesta demasiada energía; posición por captura de movimiento en laboratorio; proponen IMU o UWB.
- NC State: IMU a bordo, radio de proximidad entre insectos, baliza en dron.
- APOPO: pasó a WiFi HaLow (sub-GHz).
- HTX en Myanmar: «inalámbrico», sin especificar.

Nadie ha publicado alcance de radio de una mochila de insecto dentro de escombro real.

### H. Métricas de evaluación

**Teoría de búsqueda** (Koopman; Frost y Stone, 2001, informe CG-D-15-01 de la Guardia Costera):

- Probabilidad de éxito = probabilidad de que el blanco esté en el área × probabilidad de detectarlo si está (POS = POA × POD).
- Búsqueda aleatoria: POD = 1 − e^(−C), con cobertura C = (ancho de barrido × velocidad × tiempo) / área.

La fórmula es la estándar de la teoría; localicé el informe pero no leí la ecuación en él.

Ejemplo con datos de NTU: un insecto a 3 cm/s con ancho de barrido de 1 m (detecta hasta 0.5 m a cada lado, supuesto optimista) barre 108 m² por hora. Para 90 % de detección en 100 m² hace falta C = 2.3: 2.1 horas de un insecto, o 13 minutos de diez.

**Métodos de prueba ASTM E54.09 y NIST (lista leída en nist.gov):**

| Categoría | Norma | Prueba |
|---|---|---|
| Terreno | E2826 | Rampas continuas |
| Terreno | E2827 | Rampas cruzadas |
| Terreno | E2828 | Campo de escalones simétrico |
| Terreno | E2991 / E2992 | Grava / arena |
| Obstáculos en espacio confinado | E2801 | Huecos de largo variable |
| Obstáculos en espacio confinado | E2802 | Vallas de altura variable |
| Obstáculos en espacio confinado | E2803 | Planos inclinados |
| Obstáculos en espacio confinado | E2804 | Escaleras |
| Conciencia situacional | E2853 | Tareas de búsqueda |
| Sensado | E2566 | Agudeza visual |
| Radio | E2854 | Alcance con línea de vista |
| Radio | E2855 | Alcance sin línea de vista |
| Resistencia | E3380 | Autonomía sobre terrenos reproducibles |

No son de aprobar o reprobar: miden y cada organización fija su umbral. Se repite hasta tener confiabilidad estadística.

**Cómo se evalúan los artículos de biobots:** tasa de éxito de navegación; tiempo de navegación (48.98 s contra 33.91 s); exactitud y recuperación del clasificador; tiempo de cómputo; potencia y autonomía; porcentaje de área cubierta en un tiempo; número de intervenciones de control. Ninguno reporta probabilidad de detección por área ni tiempo a la detección en escombro real.

**Cómo midió Murphy en campo:** tiempo dentro del hueco, tirones del cable por descenso (7.75), ayudas por gravedad (9.25), colisiones por descenso (0.25), tiempo atorado (8.9 %), cámara tapada (18 %) y, sobre todo, aceptación por parte de los rescatistas.

### I. Críticas

**Robin Murphy (Texas A&M):**

- 2021: ha desplegado robots en 29 desastres. «Ningún equipo de búsqueda y rescate en ningún lugar ha encontrado a alguien vivo con un robot terrestre.» El 51 % de las fallas en despliegues fue error humano. No hay financiamiento porque los colapsos son raros y las agencias no pueden justificar el costo. «Seguimos más o menos donde estábamos hace 20 años en el World Trade Center.» El problema principal es ver dentro del escombro; el robot no puede dar la vuelta en huecos de su tamaño.
- 2004: los robots se usan «como perros»: alguien los lleva a un hueco ya identificado, los mete y los saca. «Los escenarios en que un enjambre de cientos de robots insecto se sueltan a buscar de forma autónoma y reportan a un solo operador parecen físicamente imprácticos y contrarios a la organización del rescate.» La autonomía total es «irreal» y además «indeseable»: los rescatistas no confían en ella. La detección automática de víctimas con pocos falsos negativos y pocos falsos positivos es muy difícil; en el WTC personas expertas no vieron restos que estaban en el video.

**Por qué la tecnología no llega al campo** (de las mismas fuentes): llega tarde; el tiempo útil es de minutos entre horas de espera; el arranque debe tomar menos de dos minutos; debe caber en una mochila y mojarse; el operador con experiencia en rescate vale más que el robot; cuando entra la maquinaria pesada se acaba la búsqueda fina.

**Sobre los biobots en particular:**

- Fabian Steinbeck (Bielefeld), en New Scientist: tienen que controlarse a distancia, y eso complica el rescate.
- HTX: fallas técnicas en Myanmar y cero sobrevivientes.
- Navegación publicada con localización externa; radio de 2.4 GHz en un medio que atenúa decenas de dB.
- El costo por vida salvada del USAR internacional ya es alto (cerca de un millón de dólares en Haití) y el grueso de los rescates lo hacen los vecinos el primer día.

---

## Tabla de datos duros

| Dato | Valor | Condiciones | Fuente | Año | Confianza |
|---|---|---|---|---|---|
| Sobrevivientes atrapados sacados en 24 h | 93 % | Italia 1980, 3,619 sobrevivientes | Estudio italiano (ref. 111 de la lección de Noji) | 1980 | Alta (leído en secundaria) |
| Muertes ocurridas aún atrapados | 95 % | Italia 1980 | Idem | 1980 | Alta |
| Vivos tras 2–6 h, casas de tierra | menos de 50 % | Turquía y China | Noji | — | Media |
| Supervivencia más larga confiable | 14 días | 34 sismos, 1985–2004 | Macintyre et al. | 2006 | Alta |
| Sismos con rescates después del día 2 | 18 de 34 | Prensa | Macintyre et al. | 2006 | Alta |
| Rescatados y sobrevivientes, Kobe ciudad | 1,888 y 733 | Dos primeras semanas | Kawata | 1995 | Alta |
| Supervivencia por día, Kobe | ~80 %, ~30 %, ~0 % | Inicio; días 2–3; día 4+ | Kawata 1996 vía Shuto | 1996 | Media (resumen) |
| Rescatados por familia y vecinos, Kobe | ~80 % | De edificios colapsados | Gabinete de Japón | 2014 | Alta |
| Rescatados por equipos de rescate, Kobe | 1.7 % | Otra encuesta | Gabinete de Japón | 2014 | Alta |
| Rescatados por especialistas, Armenia | 2.5 % | Atrapados sobrevivientes | Artículo en Int J Epidemiol (autores sin verificar) | 1993 | Media (resumen) |
| Rescates vivos USAR internacional, Haití | 132 | Al 22-1-2010 | ONU vía USAID | 2010 | Media (resumen) |
| «Vidas salvadas» USAR internacional, Turquía | 300 | ~5,000 rescatistas, 90 equipos | INSARAG | 2023 | Media (una fuente) |
| Magnitud, sismo 19-9-2017 | 7.1 | 13:14:40; 57 km; 18.40 N, −98.72 O | SSN, Reporte Especial | 2017 | Alta (leído) |
| Epicentro 2017 | 12 km al SE de Axochiapan | Límite Puebla–Morelos; 120 km de CDMX | SSN | 2017 | Alta; reporte preliminar |
| Muertos 2017 | 369 | CDMX 228, Mor 74, Pue 45, Méx 15, Gro 6, Oax 1 | Protección Civil vía Animal Político y Wikipedia | 2017 | Alta (dos secundarias) |
| Edificios colapsados CDMX 2017 | 44 (también 38 y 46) | Según definición | Galvis et al.; otras | 2020 | Media: tres cifras |
| Colapsados anteriores a 1985 | 91 % | De los 44 | Galvis et al. | 2020 | Alta |
| Rescatados con vida 2017 | 69 (también 115) | Gobierno; Marina al día 3 | Prensa | 2017 | Baja: sin primaria |
| Magnitud 1985 | Mw 8.1 | 07:17:49; 15 km | UNAM/SSN vía Wikipedia | 1985 | Media |
| Muertos 1985 | 3,192 a más de 10,000 | Sin cifra única | Varias | — | Baja: contradictorio |
| Rescatados con vida 1985 | 3,226 | A diez días | IV Informe de Gobierno | 1986 | Media (vía Wikipedia) |
| Costo de un binomio canino | 50,000–75,000 USD | 10–12 meses | Search Dog Foundation | 2024–25 | Media: cifras varían |
| Ciclo de trabajo del perro | 20–45 min y descanso igual | Pentágono | FEMA | 2004 | Alta |
| Alcance de cámara de búsqueda | ~5.5 m | — | Murphy | 2021 | Alta |
| Costo de robot terrestre | 50,000–150,000 USD | — | Murphy | 2021 | Alta (una fuente) |
| Personas vivas halladas por robot terrestre | 0 | Todo el mundo | Murphy | 2021 | Alta (una fuente experta) |
| Fallas por error humano | 51 % | Despliegues en desastres | Murphy | 2021 | Alta (una fuente) |
| FINDER: alcance | 9 m escombro; 6 m concreto; 30 m abierto | Pruebas previas | JPL/DHS | 2015 | Alta |
| FINDER: rescatados en Nepal | 4 | Chautara; ~3 m de escombro | JPL/DHS | 2015 | Alta |
| Robot serpiente CMU | Ø 5 cm × 94 cm | 1 edificio, 2 pasadas, 0 hallazgos | CMU | 2017 | Alta |
| Huecos en WTC | menos de 1 m; vigas de 0.3 × 0.6 m | Acero | Murphy | 2004 | Alta |
| Tiempo promedio del robot en un hueco | 6 min 44 s | WTC | Murphy | 2004 | Alta |
| Cucarachas en Myanmar | 10 | 31-3 y 3-4-2025; 0 sobrevivientes | HTX/NTU; Straits Times | 2025 | Alta |
| Insecto | 5.7 ± 0.6 cm; 6.32 ± 1.5 g | Machos | Tran-Ngoc et al. | 2021 | Alta |
| Mochila NTU | 5.5 g; 205.5 mW; 2.2 h | Batería de 120 mAh | Tran-Ngoc et al. | 2021 | Alta |
| Velocidad del insecto | 3 cm/s | Promedio | Tran-Ngoc et al. | 2021 | Alta |
| Detección térmica NTU | 87 % exactitud; 90 % a 0.5–1.5 m | Matriz 32×32, 90° | Tran-Ngoc et al. | 2021 | Alta |
| Ensamble automático | 68 s por insecto | Prototipo | Lin et al. | 2025 | Alta |
| Cobertura con 4 insectos | 80.25 % en 10 min 31 s | Exterior con obstáculos | Lin et al. | 2025 | Alta |
| Piel del tronco | 33.5–36.9 °C | Bajo la ropa | Bierman vía Wikipedia | 1936 | Media |
| Frente por infrarrojo | 31.0–35.6 °C | 1,000 sujetos | No identificada | — | Baja |
| CO2 en hueco simulado | 1.6 % | 6 h, zona de respiración | Huo et al. | 2011 | Alta |
| Voz normal | 60 dB LAeq a 1 m | — | Hopkins et al. | 2024 | Media (resumen) |
| Pérdida de RF en escombro | al menos 60–80 dB | 13 pisos; 50 MHz–1.8 GHz | NIST TN 1540 | 2005 | Media (resumen) |
| Concreto de 203 mm a 900 MHz | 23 dB | — | Tabla secundaria | — | Baja |
| Robot inalámbrico perdido | a 9–12 m de la entrada | WTC | Murphy | 2004 | Alta |

---

## Tabla comparativa de tecnologías

| Tecnología | Costo por unidad | Masa | Movilidad en rendijas | Sensor | Límites |
|---|---|---|---|---|---|
| Binomio canino | 50,000–75,000 USD por equipo | Sin dato | No entra en huecos chicos; trabaja la superficie | Olfato | Ciclos de 20–45 min; falla con fuego, lluvia y calor; no dice a qué profundidad |
| Cámara de búsqueda en poste | Sin dato | Portátil | Hasta 2–5.5 m en línea casi recta | Video, audio | No dobla esquinas; se derrite con fuego |
| Detector acústico y sísmico | Sin dato | Portátil | No entra; escucha desde fuera | Geófonos y micrófono | Necesita víctima consciente que golpee; el material blando absorbe |
| Radar FINDER | Sin dato | ~9 kg (una fuente) | No entra; ve a través de 9 m de escombro | Microondas: latido y respiración | Ubica con ±1.5 m; no dice por dónde llegar |
| Dron | desde 1,000 USD | Sin dato | Ninguna dentro del escombro | Cámara visible y térmica | Solo exterior y mapeo |
| Robot de orugas (Inuktun) | 50,000–150,000 USD | 4.5 kg | Huecos de más de 6 × 17 cm; 5–20 m con cable | Cámara a color, audio | No se endereza; el cable se enreda; 0 vivos hallados |
| Robot serpiente (CMU) | Sin dato; prototipo | Sin dato | Ø 5 cm; 94 cm de largo; con cable | Cámara y luces | Sin micrófono ni gas; una sola misión real, sin hallazgos |
| Rata con mochila (APOPO) | Sin dato | Mochila de menos de 100 g | Alta; animal entrenado que regresa | Cámara, audio en dos vías | Sin despliegue real; solo demostraciones |
| Biobot cucaracha (NTU/HTX) | Sin dato publicado | Insecto 6.3 g y mochila 5.5 g | Rendijas de ~2 cm; sube 1.5 cm, no 10 cm | Térmica 32×32, IMU, gases | 3 cm/s; 2–4 h; radio de 2.4 GHz; localización sin resolver; 1 despliegue, 0 hallazgos |

---

## Contradicciones y huecos

**Contradicciones (no promediar):**

1. **Edificios colapsados en la CDMX en 2017**: 38, 44 y 46. Usar 44 con la cita de Galvis et al. (2020) y decir que otras fuentes dan 38.
2. **Rescatados con vida en 2017**: 69 (gobierno) contra 115 (Marina, día 3). Ninguna con comunicado primario recuperado.
3. **Muertos en 1985**: de 3,192 a 40,000. No hay cifra defendible única.
4. **Muertos de los dos sismos de 2017**: 468 (CENAPRED vía CEPAL) contra 471 (suma de Animal Político).
5. **Epicentro de 2017**: Axochiapan, Morelos (reporte del día) contra Chiautla de Tapia, Puebla (revisión posterior según Wikipedia) y San Felipe Ayutla, Puebla (USGS).
6. **Rescatados por vecinos en Kobe**: «cerca de 80 %» y «más de 90 %, con 1.7 % de equipos de rescate» son encuestas con denominadores distintos.
7. **Equipos internacionales en Turquía 2023**: 90 equipos (página del informe de INSARAG), 49 o 59 clasificados y 255 en total según AFAD.
8. **Costo de un perro de rescate**: 50,000, 60,000 y 75,000 dólares en páginas de la misma fundación.
9. **Atenuación del concreto a 2.4 GHz**: de 22 a 60 dB por muro.
10. **Myanmar**: el título oficial de 2026 dice «salvaron vidas»; el texto dice que no hubo sobrevivientes. Fechas del segundo uso: 3 o 4 de abril.
11. **Frida**: «12 personas con vida» aparece como total de carrera y como cifra de 2017.

**Sin confirmar (no decir ante el profesor):**

- La curva diaria de Tangshan 1976 (81 % el primer día, 33.7 %, 36.7 %, 19 %, 7.4 %): no apareció en ninguna fuente. La pista de la consigna trae además un valor que sube del día 2 al 3.
- La curva diaria del cuerpo de bomberos de Kobe (80.5 %, 28.5 %, 21.8 %, 5.9 %): no apareció.
- El origen de la cifra de «72 horas»: ninguna fuente primaria la deriva.
- La tabla de esfuerzo vocal de ISO 9921 (54, 60, 66, 72, 78 dB): no la vi.

**Huecos por el cupo de búsqueda agotado:**

- Temperatura de la superficie de la ropa y contraste típico contra el ambiente.
- Concentración de CO2 en el aire exhalado y gradiente con la distancia a la víctima.
- Reporte del SSN o de CENAPRED sobre 1985.
- Ensayos de campo de los escarabajos de Queensland y de la cucaracha solar de RIKEN.
- Cifras de AFAD de rescatados por día en Turquía 2023.

**Huecos del estado del arte (sirven como justificación del proyecto):**

- No hay distribución medida de tamaños de hueco en colapsos de concreto.
- No hay alcance de radio publicado para una mochila de insecto dentro de escombro.
- No hay probabilidad de detección por área ni tiempo a la detección para biobots en escombro real.
- No hay costo por unidad publicado de un biobot.
- No hay temperatura ni humedad medidas dentro de escombros de sismo.

**Nota de método**: tres PDF (reporte del SSN, anexo de INSARAG, preprint de NTU) y el artículo de Murphy de 2004 no se pudieron leer en línea; la herramienta de lectura los dejó en la carpeta temporal de la sesión y se leyeron desde ahí. No se guardó nada en la carpeta del proyecto.

---

## Fuentes

**[P]** primaria (artículo revisado, informe oficial, comunicado de la institución) · **[S]** secundaria · **[Pr]** prensa

### A. Supervivencia

- [P] Macintyre, Barbera y Smith (2006). Surviving collapsed structure entrapment after earthquakes: a «time-to-rescue» analysis. Prehosp Disaster Med 21(1):4–19. https://www.cambridge.org/core/journals/prehospital-and-disaster-medicine/article/surviving-collapsed-structure-entrapment-after-earthquakes-a-timetorescue-analysis/D24F04BFBA9EDA264EA11010418B09B5
- [P] Macintyre, Barbera y Petinaux (2011). Survival interval in earthquake entrapments. Disaster Med Public Health Prep 5(1):13–22. https://www.cambridge.org/core/journals/disaster-medicine-and-public-health-preparedness/article/survival-interval-in-earthquake-entrapments-research-findings-reinforced-during-the-2010-haiti-earthquake-response/02D8C91D20040A3BA27E4580A21107DC
- [S] Science Media Centre NZ (28-2-2011), resumen del anterior. https://www.sciencemediacentre.co.nz/?p=9091
- [S] Noji, E. K. Public Health Consequences of Earthquakes, Part II (Supercourse, Universidad de Pittsburgh). https://sites.pitt.edu/~super1/lecture/lec13051/013.htm
- [P] Noji et al. (1990). The 1988 earthquake in Soviet Armenia: a case study. Ann Emerg Med 19(8):891–897. DOI 10.1016/S0196-0644(05)81563-X
- [P] Kawata, Y. (1995). The Great Hanshin-Awaji Earthquake Disaster. J Natural Disaster Science 17(2). https://jsnds.org/jnds/17_2_1.html
- [P] Gabinete de Japón, Libro Blanco de Gestión de Desastres 2014, figuras 1 y 2. https://www.bousai.go.jp/kaigirep/hakusho/h26/honbun/0b_2s_01_00.html
- [P] INSARAG, After-Action Review Türkiye. https://insarag.org/aar-turkiye/
- [P] Estudio hospitalario de Turquía 2023, Frontiers in Medicine (2025). https://www.frontiersin.org/journals/medicine/articles/10.3389/fmed.2025.1517344/full
- [P] USAID, hojas informativas de Haití (2010). https://pdf.usaid.gov/pdf_docs/PA00J2BH.pdf
- [Pr] Daily Sabah, expertos sobre supervivencia (2023). https://www.dailysabah.com/turkey/chances-of-survival-may-be-up-to-a-week-after-earthquakes-experts/news

### B. México

- [P] Servicio Sismológico Nacional, UNAM. Reporte Especial: sismo del 19 de septiembre de 2017, Puebla-Morelos (M 7.1). https://www.iingen.unam.mx/es-mx/Investigacion/Proyecto/PublishingImages/Paginas/ReporteSismos/SSNMX_rep_esp_20170919_Puebla-Morelos_M71.pdf
- [P] Galvis et al. (2020). Overview of collapsed buildings in Mexico City after the 19 September 2017 (Mw7.1) earthquake. Earthquake Spectra. DOI 10.1177/8755293020936694. Ficha: https://scripta.up.edu.mx/handle/20.500.12552/2931
- [Pr] Animal Político (19-10-2017). Lo que el #19S nos dejó. https://grupoanimal.mx/noticias/cifras-oficiales-sismo-19s
- [S] Wikipedia, Terremoto de Puebla de 2017. https://es.wikipedia.org/wiki/Terremoto_de_Puebla_de_2017
- [S] Wikipedia, Terremoto de México de 1985 (cita el IV Informe de Gobierno de 1986 y la revisión del Banco Mundial sobre Fonden, 2012). https://es.wikipedia.org/wiki/Terremoto_de_M%C3%A9xico_de_1985
- [S] CEPAL, indicadores de CENAPRED. https://cepal.org/sites/default/files/presentations/5-indicadores-cenapred.pdf
- [Pr] Eje Central, día 3: 115 sobrevivientes. https://www.ejecentral.com.mx/dia-3-esperanza-rescates-historias
- [Pr] Chilango, saldo actualizado. https://www.chilango.com/ciudad/saldo-actualizado-por-el-sismo/
- [P] Ramírez Herrera y Lugo Hubp. Efectos del sismo (Mw 7.0) del 15 de junio de 1999 en Puebla. Investigaciones Geográficas, UNAM. https://www.investigacionesgeograficas.unam.mx/index.php/rig/article/download/59122/52109/169996
- [P] Ponencia WCEE 2012 sobre Puebla (zona B de la CFE). https://wcee.nicee.org/wcee/article/WCEE2012_2467.pdf

### C y D. Práctica, robots y escombros

- [P] INSARAG Guidelines, vol. III, anexo B20. https://insarag.org/wp-content/uploads/2020/04/INSARAG_Guidelines_Vol_III_-_Annex_B20_-_Assessment_Search_and_Rescue_Level.pdf
- [P] Murphy, R. R. (2004). Trial by fire: activities of the rescue robots at the World Trade Center. IEEE Robotics and Automation Magazine 11(3):50–61. DOI 10.1109/MRA.2004.1337826. Copia: https://student.cs.uwaterloo.ca/~cs492/papers/trial.pdf
- [P] Murphy, R. R. (2021). Entrevista en The Conversation, reproducida en Robohub. https://robohub.org/an-expert-on-search-and-rescue-robots-explains-the-technologies-used-in-disasters-like-the-florida-condo-collapse/
- [P] Casper y Murphy (2003). Human-robot interactions during the robot-assisted USAR response at the WTC. IEEE Trans SMC-B 33(3):367–385. DOI 10.1109/TSMCB.2003.811794
- [P] Carnegie Mellon (27-9-2017). Snakebot en México. https://www.cmu.edu/news/stories/archives/2017/september/snakebot-mexico.html
- [P] Whitman et al. (2018). Snake Robot Urban Search After the 2017 Mexico City Earthquake. IEEE SSRR. https://ri.cmu.edu/publications/snake-robot-urban-search-after-the-2017-mexico-city-earthquake
- [P] JPL (5-5-2015). FINDER en Nepal. https://www.jpl.nasa.gov/news/dhs-and-nasa-technology-helps-save-four-in-nepal-earthquake-disaster/
- [P] JPL (8-5-2015). Transferencia de FINDER. https://www.jpl.nasa.gov/news/dhs-successfully-transitions-search-and-rescue-tool-that-pinpoints-buried-victims/
- [P] FEMA (página archivada, 2004), caninos US&R. https://webharvest.gov/peth04/20041015000252/http:/www.fema.gov/about/mediacanine.shtm
- [S] Search Dog Foundation. https://searchdogfoundation.org/our-mission/ y https://searchdogfoundation.org/faqs/
- [S] Fire Engineering, comparación de instrumentos de detección de vida. https://www.fireengineering.com/firefighting/summary-of-comparison-of-life-detection-instrumentation/
- [S] Firehouse, tipos de colapso. https://www.firehouse.com/rescue/article/10575679/collapse-rescue-101-initial-recon-of-the-structural-collapse-event

### E. Insectos cíborg y animales

- [P] Tran-Ngoc et al. (2021). Insect-Computer Hybrid System for Autonomous Search and Rescue Mission. arXiv:2105.10869. https://arxiv.org/abs/2105.10869 (versión: Advanced Intelligent Systems 5(5):2200319, 2023)
- [P] Lin et al. (2025). Cyborg Insect Factory. Nature Communications. https://www.nature.com/articles/s41467-025-60779-1 · preprint https://arxiv.org/abs/2411.13164
- [P] NTU (28-7-2025), comunicado. https://www.ntu.edu.sg/news/detail/ai-powered-robot-assembles-search-and-rescue-cyborg-insects
- [P] Bai et al. (2025). Swarm navigation of cyborg-insects in unknown obstructed soft terrain. Nat Commun 16:221. DOI 10.1038/s41467-024-55197-8
- [P] HTX (10-12-2021). Foe today, friend tomorrow. https://www.htx.gov.sg/news/featured-news-foe-today-friend-tomorrow-cyborg-cockroaches-could-save-your-life
- [P] Public Service Division, Singapur (12-8-2026). From Lab to Rubble. https://www.psd.gov.sg/challenge/articles/from-lab-to-rubble--how-cyborg-cockroaches-saved-lives/
- [Pr] The Star / The Straits Times (5-4-2025). https://www.thestar.com.my/aseanplus/aseanplus-news/2025/04/05/singapores-cyborg-cockroaches-helping-with-search-and-rescue-efforts-in-myanmar-quake
- [P] Cole, Bozkurt y Lobaton (2020). Sensors 20:4486. https://mdpi-res.com/d_attachment/sensors/sensors-20-04486/article_deploy/sensors-20-04486-v3.pdf
- [P] APOPO (25-6-2026). Demostración de RescueRATs. https://apopo.org/?p=298531

### F. Firma humana

- [P] Huo et al. (2011). The trapped human experiment. J Breath Res 5(4):046006. DOI 10.1088/1752-7155/5/4/046006. Ficha: https://dspace.lib.ntua.gr/xmlui/handle/123456789/29411?show=full
- [P] Güntner et al. (2018). Sniffing Entrapped Humans with Sensor Arrays. Anal Chem 90(8):4940–4945. DOI 10.1021/acs.analchem.8b00237
- [P] Zhang et al. (2018). Evaluation of a Sensor System for Detecting Humans Trapped under Rubble. Sensors 18(3):852. https://www.ncbi.nlm.nih.gov/pmc/articles/PMC5877370/
- [P] Melexis, hoja de datos del MLX90614. https://media.melexis.com/-/media/files/documents/datasheets/mlx90614-datasheet-melexis.pdf
- [S] SparkFun, guía del MLX90614. https://learn.sparkfun.com/tutorials/mlx90614-ir-thermometer-hookup-guide/all
- [S] Wikipedia, Skin temperature (cita a Bierman, 1936, JAMA 106(14):1158). https://en.wikipedia.org/wiki/Skin_temperature
- [P] Hopkins, Graetzer y Seiffert (2024). Sound power of normal speech. https://pub.ioa.org.uk/conference-proceeding/acoustics-2024-vol-46-pt-2/c-hopkins-s-graetzer-g-seiffert-sound-power-of-normal-speech-for-building-acoustics

### G y H. Radio y métricas

- [P] Holloway et al. (2005). NIST TN 1540. https://www.nist.gov/node/578441 · DOI 10.6028/NIST.TN.1540
- [P] Holloway et al. (2005). NIST TN 1541. https://www.nist.gov/node/578446
- [P] Holloway et al. (2006). NIST TN 1542. https://www.nist.gov/node/578456
- [P] Holloway et al. (2014). IEEE Antennas and Propagation Magazine 56(3). DOI 10.1109/MAP.2014.6867680. https://www.nist.gov/node/789046
- [P] Stone, W. C. (1997). NISTIR 6055. https://nist.gov/publications/electromagnetic-signal-attenuation-construction-materials
- [P] NIST, Standard Test Methods for Response Robots. https://www.nist.gov/node/417766
- [P] Frost y Stone (2001). Review of Search Theory. USCG CG-D-15-01. https://apps.dtic.mil/sti/pdfs/ADA397065.pdf
- [P] Frost (1996). The Theory of Search: A Simplified Explanation. https://navcen.uscg.gov/sites/default/files/pdf/Theory_of_Search.pdf
