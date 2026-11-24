import json
import os
import re

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.image import imread

AQUI = os.path.dirname(os.path.abspath(__file__))
RES = os.path.join(AQUI, "resultados")
AZUL, CIELO, NARANJA, VERDE, GRIS = "#0E2A47", "#1D6FA5", "#D98B12", "#1D7A46", "#8A94A3"
VDD = {"tt": 1.80, "ss": 1.60, "ff": 1.95}
NOMBRE = {"tt": "típica", "ss": "lenta", "ff": "rápida"}


# potencia por esquina y condicion
def lee_potencia():
    p = {}
    txt = open(os.path.join(RES, "potencia.rpt"), encoding="utf-8").read()
    for esq, cond, cuerpo in re.findall(r"== (\w+) (\w+)\n(.*?)== fin", txt, re.S):
        m = re.search(r"^Total\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)", cuerpo, re.M)
        p[esq, cond] = [float(x) for x in m.groups()]
    return p


def mA(pot, esq):
    return 1000 * pot / VDD[esq]


m = json.load(open(os.path.join(RES, "metrics.json"), encoding="utf-8"))
p = lee_potencia()
x0, y0, x1, y1 = (float(v) for v in m["design__die__bbox"].split())
ancho, alto = x1 - x0, y1 - y0
dado = m["design__die__area"]
celdas = m["design__instance__area__stdcell"]
A = "design__instance__area__class:"
partes = [
    ("Compuertas", m[A + "multi_input_combinational_cell"] + m[A + "inverter"], CIELO),
    ("Flip-flops", m[A + "sequential_cell"], AZUL),
    ("Búferes de tiempo", m[A + "timing_repair_buffer"], NARANJA),
    ("Árbol de reloj", m[A + "clock_buffer"] + m[A + "clock_inverter"], VERDE),
    ("Celdas de pozo", m[A + "tap_cell"] + m.get(A + "antenna_cell", 0), GRIS),
]
CONDS = [("espera", "En espera"), ("estimulo", "Estímulo"), ("cuadro", "Cuadro continuo"), ("omision", "Por omisión")]

# resumen en texto
L = ["NUCLEO DE BIOBOT-RESCUE EN SKY130 - AREA Y CORRIENTE", "",
     f"Dado              {ancho:.1f} x {alto:.1f} um = {dado:,.0f} um2 = {dado/1e6:.4f} mm2",
     f"Celdas colocadas  {celdas:,.0f} um2 = {celdas/1e6:.4f} mm2 (ocupacion {100*m['design__instance__utilization']:.1f} %)"]
L += [f"  {n:<18}{a:>9,.0f} um2  {100*a/celdas:5.1f} %" for n, a, _ in partes]
L += ["", "Reloj de 50 MHz        " + "".join(f"{NOMBRE[e]+f' {VDD[e]:.2f} V':>22}" for e in VDD)]
for c, n in CONDS:
    L.append(f"{n:<23}" + "".join(f"{1000*p[e,c][3]:>9.3f} mW {mA(p[e,c][3],e):>6.3f} mA " for e in VDD))
L.append(f"{'Fuga':<23}" + "".join(f"{1e6*p[e,'espera'][2]:>9.3f} uW {1000*mA(p[e,'espera'][2],e):>6.3f} uA " for e in VDD))
dens = 1000 * p["tt", "espera"][3] / (dado / 1e6)
L += ["", f"Densidad de potencia en espera: {dens:.1f} mW/mm2 de dado"]
texto = "\n".join(L).replace("í", "i").replace("á", "a")
open(os.path.join(RES, "area_y_corriente.txt"), "w", encoding="utf-8", newline="\n").write(texto + "\n")
print(texto)

# figura
plt.rcParams.update({"font.family": "DejaVu Sans", "font.size": 8.5, "axes.spines.top": False, "axes.spines.right": False})
fig = plt.figure(figsize=(10.2, 4.7), dpi=200)
gs = fig.add_gridspec(2, 2, width_ratios=[1.0, 1.15], height_ratios=[1, 1.15], wspace=0.32, hspace=0.5,
                      left=0.055, right=0.985, top=0.92, bottom=0.10)

ax = fig.add_subplot(gs[:, 0])
img = imread(os.path.join(RES, "chip_color.png"))
n = img.shape[0]
ax.imshow(img, extent=(0, n, n, 0))
izq, der, arr, aba = 75, 1525, 38, 1562
ax.annotate("", (der, n + 60), (izq, n + 60), arrowprops=dict(arrowstyle="<->", color=AZUL, lw=1.2), annotation_clip=False)
ax.text((izq + der) / 2, n + 130, f"{ancho:.1f} µm", ha="center", va="center", color=AZUL, weight="bold")
ax.annotate("", (-60, aba), (-60, arr), arrowprops=dict(arrowstyle="<->", color=AZUL, lw=1.2), annotation_clip=False)
ax.text(-125, n / 2, f"{alto:.1f} µm", ha="center", va="center", rotation=90, color=AZUL, weight="bold")
ax.set_title(f"Área: {dado/1e6:.3f} mm²    Corriente: {mA(p["tt","espera"][3],"tt"):.2f} mA a 1.8 V", color=AZUL, weight="bold", fontsize=10)
ax.set_xlim(0, n); ax.set_ylim(n, 0); ax.axis("off")

ax = fig.add_subplot(gs[0, 1])
for i, (nom, a, c) in enumerate(partes):
    ax.barh(i, a, color=c, height=0.64)
    ax.text(a + 110, i, f"{a:,.0f} µm²  ({100*a/celdas:.0f} %)", va="center", color=AZUL)
ax.set_yticks(range(len(partes)), [q[0] for q in partes]); ax.invert_yaxis()
ax.set_xlim(0, 14800); ax.set_xticks([]); ax.spines["bottom"].set_visible(False); ax.tick_params(length=0)
ax.set_title(f"Área de celdas: {celdas/1e6:.4f} mm² (ocupación {100*m['design__instance__utilization']:.1f} %)", loc="left", color=AZUL, weight="bold")

ax = fig.add_subplot(gs[1, 1])
w = 0.26
for j, (e, c) in enumerate(zip(("ss", "tt", "ff"), (CIELO, AZUL, NARANJA))):
    for i, (cond, _) in enumerate(CONDS):
        v = mA(p[e, cond][3], e)
        ax.bar(i + (j - 1) * w, v, w * 0.92, color=c, label=f"{NOMBRE[e]}, {VDD[e]:.2f} V" if i == 0 else None)
        ax.text(i + (j - 1) * w, v + 0.02, f"{v:.2f}", ha="center", va="bottom", fontsize=7, color=AZUL)
ax.set_xticks(range(len(CONDS)), [q[1] for q in CONDS]); ax.tick_params(axis="x", length=0)
ax.set_ylabel("mA"); ax.set_ylim(0, 1.75); ax.grid(axis="y", color="#E3E8EE", lw=0.6); ax.set_axisbelow(True)
ax.legend(frameon=False, ncol=3, loc="upper left", fontsize=7.5, handlelength=1.2)
ax.set_title("Corriente del núcleo con reloj de 50 MHz", loc="left", color=AZUL, weight="bold")
fig.savefig(os.path.join(RES, "layout_area_corriente.png"))
