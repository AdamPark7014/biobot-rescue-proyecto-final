"""Figuras de la red de tres FPGA a partir de las trazas de la simulación.

Uso:  python trazas.py
Lee sim/trazas/tri_7.csv y tri_9.csv, que escribe el banco sim/tb_tri.v con +traza (una muestra
cada 10 ms de lo que se ve en las tres tarjetas), y deja en latex/figs:
  red_seguimiento.png   el conteo de personas sigue al sensor (escenario 7)
  red_umbral.png        el corte de 32 m con la mochila A en distintas posiciones (escenario 9)
Para regenerar las trazas, en sim/:
  vvp -n tb_tri.out +desde=7 +hasta=7 +traza      (y lo mismo con 9)
"""
import csv
import os
import sys

import matplotlib.pyplot as plt

import estilo as E

E.aplicar()
AQUI = os.path.dirname(os.path.abspath(__file__))
TRAZAS = os.path.join(AQUI, "..", "sim", "trazas")
SALIDA = os.path.join(AQUI, "..", "latex", "figs")


def lee(n):
    ruta = os.path.join(TRAZAS, "tri_%d.csv" % n)
    if not os.path.exists(ruta):
        sys.exit("Falta %s: correr el banco tb_tri con +traza" % ruta)
    with open(ruta, encoding="ascii") as f:
        filas = list(csv.DictReader(f))
    return {k: [int(fila[k]) for fila in filas] for k in filas[0]}


def digital(ax, t, senales, colores):
    """Dibuja señales de un bit apiladas, cada una en su renglón."""
    n = len(senales)
    for i, ((nombre, v), color) in enumerate(zip(senales, colores)):
        base = (n - 1 - i) * 1.5
        ax.step(t, [base + x for x in v], where="post", color=color, lw=2.6)
        ax.fill_between(t, base, [base + x for x in v], step="post", color=color, alpha=0.18, lw=0)
    ax.set_yticks([(n - 1 - i) * 1.5 + 0.5 for i in range(n)])
    ax.set_yticklabels([s[0] for s in senales], fontsize=14)
    ax.set_ylim(-0.3, n * 1.5 - 0.2)
    ax.grid(axis="y", visible=False)


def seguimiento():
    """Escenario 7: la detección térmica sigue al sensor y el conteo baja y sube en las tres tarjetas."""
    d = lee(7)
    t = [m / 100.0 for m in d["muestra"]]
    fig, (a, b, c) = plt.subplots(3, 1, figsize=(16.64, 8.6), sharex=True,
                                  gridspec_kw={"height_ratios": [1.25, 1.0, 1.0]})
    fig.subplots_adjust(left=0.115, right=0.985, top=0.93, bottom=0.09, hspace=0.16)
    a.axhspan(35, 38.99, color=E.VERDE, alpha=0.14, lw=0)
    a.text(6.75, 37.0, "ventana de 35 a 38 °C", ha="center", va="center", fontsize=14, color=E.VERDE)
    a.step(t, d["temp_a"], where="post", color=E.AMBAR, label="sensor de A")
    a.step(t, d["temp_b"], where="post", color=E.AZUL, ls=(0, (5, 2)), label="sensor de B")
    a.set_ylabel("Temperatura (°C)")
    a.set_ylim(20, 44)
    a.legend(loc="upper left", ncol=2)
    a.set_title("El conteo de personas sigue al sensor (simulación de las tres FPGA)", loc="left")
    digital(b, t, [("A detecta", d["termica_a"]), ("B detecta", d["termica_b"])], [E.AMBAR, E.AZUL])
    c.step(t, d["cuenta_r"], where="post", color=E.AZUL_OSC, lw=4.0, label="receptor")
    c.step(t, d["cuenta_a"], where="post", color=E.AMBAR, lw=2.0, ls=(0, (4, 2)), label="mochila A")
    c.step(t, d["cuenta_b"], where="post", color=E.ROJO, lw=2.0, ls=(0, (1, 2)), label="mochila B")
    c.set_ylabel("Personas (Pd)")
    c.set_yticks([0, 1, 2])
    c.set_ylim(-0.25, 2.6)
    c.set_xlabel("Tiempo (s)")
    c.legend(loc="upper right", ncol=3)
    c.set_xlim(0, t[-1])
    return fig


def umbral():
    """Escenario 9: la mochila A cambia de posición; se oye a menos de 32 m y a 32 m o más, no."""
    d = lee(9)
    t = [m / 100.0 for m in d["muestra"]]
    dist = [x / 16.0 for x in d["d_a_rec"]]
    directo = [(e >> 3) & 1 for e in d["enlaces"]]
    led = [x >> 5 for x in d["led_r"]]
    fig, (a, b, c) = plt.subplots(3, 1, figsize=(16.64, 8.6), sharex=True,
                                  gridspec_kw={"height_ratios": [1.25, 1.2, 1.0]})
    fig.subplots_adjust(left=0.135, right=0.985, top=0.93, bottom=0.09, hspace=0.16)
    a.axhline(32.0, color=E.ROJO, lw=1.8, ls="--")
    a.text(t[-1], 32.07, "alcance: 32 m", ha="right", va="bottom", fontsize=14, color=E.ROJO)
    a.step(t, dist, where="post", color=E.AMBAR)
    a.set_ylabel("Distancia de A\nal receptor (m)")
    a.set_ylim(30.6, 32.6)
    a.set_title("El corte del alcance con la mochila A en siete posiciones (simulación de las tres FPGA)", loc="left")
    # rótulo de cada tramo: dónde está A
    x_prev, y_prev, inicio = None, None, 0
    tramos = []
    for i, (x, y) in enumerate(zip(d["xa"], d["ya"])):
        if (x, y) != (x_prev, y_prev):
            if x_prev is not None:
                tramos.append((inicio, i, x_prev, y_prev))
            x_prev, y_prev, inicio = x, y, i
    tramos.append((inicio, len(t) - 1, x_prev, y_prev))
    for i0, i1, x, y in tramos:
        if t[i1] - t[i0] < 0.8:
            continue
        a.text((t[i0] + t[i1]) / 2, 30.72, "(%.2f, %.2f)" % (x / 16.0, y / 16.0), ha="center", va="bottom",
               fontsize=12.5, color=E.GRIS)
    digital(b, t, [("radio directo", directo), ("el receptor\noye a A", d["r_oye_a"]), ("A oye al\nreceptor", d["a_oye_r"])],
            [E.AZUL_OSC, E.AZUL, E.VERDE])
    c.step(t, led, where="post", color=E.AZUL_OSC)
    c.set_ylabel("LED del receptor:\nmetros a A")
    c.set_yticks([0, 16, 31])
    c.set_ylim(-3, 36)
    c.set_xlabel("Tiempo (s)")
    c.set_xlim(0, t[-1])
    return fig


if __name__ == "__main__":
    for nombre, f in (("red_seguimiento", seguimiento), ("red_umbral", umbral)):
        fig = f()
        ruta = os.path.join(SALIDA, nombre + ".png")
        fig.savefig(ruta, dpi=120)
        plt.close(fig)
        print(nombre, "->", os.path.relpath(ruta, AQUI))
