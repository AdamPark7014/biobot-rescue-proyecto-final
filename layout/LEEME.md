# Layout del núcleo de BioBot-Rescue en SkyWater SKY130

El núcleo digital de la mochila (`nucleo_biobot` y sus cuatro módulos de `hdl/`) pasó por el flujo abierto
RTL-a-GDS completo con la PDK `sky130A`: síntesis, plano, colocación, árbol de reloj, ruteo y verificación
física. El resultado es un GDS que pasa DRC y LVS sin errores y cumple tiempos en todas las esquinas.
Este layout sustituye la estimación por conteo de celdas (≈ 0.014 mm²) que traía el reporte.

Corrida final: 21-11-2026, LibreLane 3.0.17, biblioteca `sky130_fd_sc_hd`, reloj objetivo de 20 ns (50 MHz).

## Resultados

| Medida | Valor |
|---|---|
| **Área del chip (dado)** | **49 731 µm² = 0.050 mm²** (217.7 × 228.4 µm) |
| Área de núcleo (dentro del anillo de alimentación) | 42 134 µm² = 0.042 mm² |
| Área de celdas estándar colocadas (sin relleno) | 22 615 µm² = 0.023 mm², ocupación 53.7 % |
| Área de la lógica recién sintetizada (Yosys, antes de búferes) | 17 085 µm² = 0.017 mm² |
| **Celdas estándar** | **2 671** (más 5 798 de relleno: 8 469 instancias) |
| — flip-flops | 253 (237 `dfrtp_2` y 16 `dfstp_2`) |
| — lógica combinacional (compuertas de 2 o más entradas) | 991 |
| — inversores | 297 |
| — búferes de reparación de tiempo (219 son de hold) | 485 |
| — árbol de reloj | 51 búferes y 16 inversores |
| — celdas de pozo (tap) y diodo de antena | 577 y 1 |
| **Frecuencia máxima estimada**, esquina lenta (ss, 100 °C, 1.60 V) | **≈ 72 MHz** |
| Frecuencia máxima estimada, típica (tt, 25 °C, 1.80 V) | ≈ 143 MHz |
| Frecuencia máxima estimada, rápida (ff, −40 °C, 1.95 V) | ≈ 220 MHz |
| Margen de setup a 50 MHz (peor esquina) | +4.94 ns (+6.07 ns entre registros) |
| Margen de hold (peor esquina) | +0.11 ns |
| Potencia a 50 MHz (tt, estimación sin vectores) | 2.47 mW (1.59 interna, 0.89 de conmutación, fuga ≈ 0) |
| Cable ruteado | 37 178 µm |
| Pines | 88 de señal + VPWR y VGND |

Verificación física, todo en cero: DRC de Magic, DRC de KLayout, LVS de Netgen («Circuits match uniquely»),
DRC del ruteador, antenas, XOR Magic contra KLayout, traslapes ilegales, violaciones de setup y hold, y
violaciones de slew, capacitancia y fanout en las nueve esquinas.

**Cómo se calcula la frecuencia.** El flujo se corrió a 20 ns, y la frecuencia máxima se estima con el margen
medido: f ≈ 1 / (20 ns − margen). En la esquina lenta el camino más largo entre registros deja 6.07 ns de margen,
así que tarda 13.9 ns: 72 MHz. Los caminos de entrada y salida dan casi lo mismo (72.4 MHz), porque el SDC les
reserva el 20 % del periodo. Es una estimación sin volver a optimizar para esa frecuencia, igual que la Fmax que
reporta Quartus para la MAX 10 (72.08 MHz en el modelo lento de 1.2 V y 85 °C, proyecto `quartus/`).

**Comparación con lo que había.**

| | Estimación anterior | FPGA DE10-Lite (Quartus) | SKY130 (este layout) |
|---|---|---|---|
| Tamaño | ≈ 0.014 mm² de celdas | 477 elementos lógicos | 0.017 mm² de lógica, 0.023 mm² colocada, **0.050 mm² de dado** |
| Registros | — | 224 | 253 flip-flops |
| Frecuencia | — | 72.08 MHz (modelo lento, 85 °C) | ≈ 72 MHz (ss), ≈ 143 MHz (tt) |

La estimación anterior se quedó corta por tres cosas que solo aparecen al hacer el layout: los búferes que se
agregan para cumplir hold y slew, el árbol de reloj y las celdas de pozo; además, el dado deja espacio para rutear
(se pidió 40 % de ocupación y quedó en 54 %). Hay más registros que en Quartus porque en la tarjeta algunas salidas
del núcleo no se usan (por ejemplo `n_est` y `fondo`) y Quartus quita sus registros. En el chip las 67 salidas son
pines y no se elimina nada.

## Imágenes

- [`resultados/nucleo_biobot_klayout.png`](resultados/nucleo_biobot_klayout.png): el chip completo en KLayout,
  con los colores de capa de sky130A.
- [`resultados/nucleo_biobot_detalle.png`](resultados/nucleo_biobot_detalle.png): acercamiento de 25 × 25 µm al
  centro; se ven las filas de celdas, las difusiones (verde), el polisilicio y las capas de metal.
- [`resultados/klayout_escritorio_vm.png`](resultados/klayout_escritorio_vm.png): KLayout abierto con el GDS en el
  escritorio de la máquina virtual (captura de pantalla real).
- [`resultados/nucleo_biobot_render_librelane.png`](resultados/nucleo_biobot_render_librelane.png): la imagen que
  genera el propio flujo con KLayout.

## Qué hay en esta carpeta

| Archivo | Para qué |
|---|---|
| `config.json` | Configuración de LibreLane: top, archivos de `../hdl/`, reloj y ajustes de reparación |
| `correr_flujo.sh` | Corre el flujo dentro de la VM y junta lo importante en `resultados/` |
| `captura_klayout.py` | Dibuja el GDS a PNG con KLayout sin abrir ventana (completo o con acercamiento) |
| `vm/crear_vm.ps1` | Crea la VM Ubuntu 24.04 en VMware a partir de la imagen oficial de Canonical, sin instalador |
| `vm/instalar_herramientas.sh` | Instala dentro de la VM Docker, LibreLane, Magic, KLayout y el escritorio |
| `resultados/nucleo_biobot.gds` | El layout final (SHA-256 `905f698a…6586ac`) |
| `resultados/metrics.json` | Todas las métricas de la corrida final |
| `resultados/sta_resumen.rpt` | Márgenes de setup y hold por esquina |
| `resultados/sintesis_celdas.rpt` | Celdas por tipo después de la síntesis |
| `resultados/lvs.rpt` | Reporte de LVS de Netgen |

La corrida completa (`runs/`, unos 330 MB) no se versiona; se regenera con `correr_flujo.sh`.

## Cómo se reproduce

**1. VMware Workstation Pro.** Es gratis para uso personal. Se baja del portal de soporte de Broadcom
(`support.broadcom.com` → *My Downloads* → *VMware Workstation Pro*) con una cuenta de Broadcom. Se usó la versión
26H1u1 (build 25688693). Corre encima de Hyper-V sin cambiar ajustes de seguridad de Windows.

**2. La máquina virtual.** Se usa la imagen de nube oficial de Ubuntu 24.04 LTS
(`ubuntu-24.04-server-cloudimg-amd64.ova`, de `cloud-images.ubuntu.com`; comparar con su `SHA256SUMS`).
`cloud-init` crea el usuario y pone la llave SSH al primer arranque, así que no hay instalador que contestar:

```powershell
ssh-keygen -t ed25519 -f C:\VMs\biobot-sky130\ssh\id_ed25519
pwsh -File vm\crear_vm.ps1 -Ova <ruta del .ova> -Destino C:\VMs\biobot-sky130\vm `
     -LlavePublica C:\VMs\biobot-sky130\ssh\id_ed25519.pub -HashContrasena '<salida de: openssl passwd -6>'
```

Queda con 6 GB de RAM, 8 núcleos, disco de 80 GB y red NAT; el script imprime la IP.

**3. Herramientas dentro de la VM.** Copiar `vm/instalar_herramientas.sh` a la VM y correrlo una vez:

```bash
./instalar_herramientas.sh
sg docker -c 'librelane --dockerized --smoke-test'   # baja la imagen de LibreLane y la PDK sky130A, y prueba
```

La PDK la baja `ciel` a `~/.ciel` (versión `8afc8346a57fe1ab7934ba5a6056ea8b43078e71`, la que fija LibreLane 3.0.17).

**4. Correr el flujo.** Copiar a la VM los cinco módulos y esta carpeta, conservando la estructura:

```bash
mkdir -p ~/biobot/hdl ~/biobot/layout
# desde Windows: scp hdl/{ventana_termica,detectores,fsm_politica,gen_estimulo,nucleo_biobot}.v adam@<IP>:~/biobot/hdl/
#                scp layout/{config.json,correr_flujo.sh,captura_klayout.py} adam@<IP>:~/biobot/layout/
cd ~/biobot/layout && ./correr_flujo.sh
```

Tarda unos 7 minutos. LibreLane necesita una terminal interactiva: desde una terminal del escritorio de la VM
funciona directo; por SSH sin terminal hay que envolverlo, `script -qefc ./correr_flujo.sh flujo.log`.

**5. Ver el layout.** En el escritorio de la VM:

```bash
LYP=$(find ~/.ciel -path '*sky130A/libs.tech/klayout/tech/sky130A.lyp' | head -1)
klayout -l "$LYP" ~/biobot/layout/resultados/nucleo_biobot.gds
```

Con Magic: `magic -T $(find ~/.ciel -name sky130A.tech | head -1)` y luego `gds read nucleo_biobot.gds`.

## Por qué la configuración es así

- **Reloj de 20 ns.** Es el reloj de 50 MHz de la DE10-Lite, y `gen_estimulo` cuenta sus pulsos con
  `CLK_FREQ = 50 MHz`.
- **`FP_CORE_UTIL` 40 y densidad de colocación 55 %.** Dejan espacio para rutear sin congestión.
- **Reparación de slew (`RUN_POST_GRT_DESIGN_REPAIR`, márgenes de 50 %, grupos de reloj de 10).** La primera
  corrida, con los valores por omisión, pasaba DRC y LVS pero dejaba 140 transiciones lentas (más de 0.75 ns) en las
  esquinas ss. Las causaban los búferes débiles que agrega la reparación de hold. Con 30 % de margen bajaron a 98;
  con 50 % y la reparación después del ruteo global quedaron en cero.
- **SDC genérico de LibreLane.** No se escribió un SDC propio: incertidumbre de reloj de 0.25 ns, retardo de
  entrada y salida del 20 % del periodo y carga de 33.4 fF en cada salida.

## Avisos que quedan (no son errores)

- **Tres pines de entrada sin conectar: `actividad[2:0]`.** El detector de quietud compara `actividad >= 8`, y eso
  solo depende de los bits 7 a 3; la síntesis quita los tres bits bajos con razón.
- **460 avisos de lint de Verilator, 0 errores:** 446 `TIMESCALEMOD` (unos módulos declaran `timescale` y otros no),
  11 `WIDTHEXPAND` y 3 `UNUSEDSIGNAL` (`ocupado` en `nucleo_biobot`, `suma[1:0]` en `media_movil4` y
  `azar[15:10]` en `fsm_politica`).
- **La potencia es una estimación sin vectores.** Supone una actividad de conmutación por omisión. En la mochila la
  lógica cambia una vez por cuadro (10 Hz), así que el consumo real es menor y lo domina el árbol de reloj.

## Versiones

- HDL: commit `6f2446b` de `main`; los cinco módulos son idénticos a los de ese commit.
- LibreLane 3.0.17, imagen `ghcr.io/librelane/librelane:3.0.17`
  (`sha256:24640bd645ae992fa22d4a3e18fde10d728763c78fb140184f9975aa6c7d3e5e`). Dentro: Yosys 0.62,
  OpenROAD `dcf36133`, Magic 8.3.623, Netgen 1.5.316 y KLayout 0.30.7.
- PDK `sky130A`, `ciel` versión `8afc8346a57fe1ab7934ba5a6056ea8b43078e71`, biblioteca `sky130_fd_sc_hd`.
- VM: Ubuntu 24.04.5 LTS; Magic 8.3.105 y KLayout 0.28.16 de Ubuntu para ver el layout.
- VMware Workstation Pro 26H1u1 (build 25688693) en Windows 11.

## En la laptop de Adam

- La VM está en `C:\VMs\biobot-sky130\vm\biobot-sky130.vmx`; se abre con VMware Workstation (*File → Open*) o con
  `vmrun -T ws start C:\VMs\biobot-sky130\vm\biobot-sky130.vmx`. Entra sola al escritorio con el usuario `adam`.
- La contraseña de `adam` y la llave SSH están en `C:\VMs\biobot-sky130\` (`acceso.txt` y `ssh\`), fuera del
  repositorio. La IP la da VMware por DHCP (`vmrun -T ws getGuestIPAddress <vmx>`); en la corrida fue
  192.168.124.129.
- La copia de trabajo dentro de la VM está en `~/biobot/`: la corrida final en `layout/runs/nucleo/` y la de 30 %
  de margen en `layout/runs/nucleo_margen30/`.
- La VM usa 6 GB de RAM. Con la laptop justa de memoria conviene apagarla cuando no se use:
  `vmrun -T ws stop <vmx> soft`.
