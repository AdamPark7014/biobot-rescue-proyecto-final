"""Figuras de la red de tres FPGA: el montaje, el mapa con el alcance y la triangulación, y la trama.

Uso:  python red.py
Deja en latex/figs: red_tres_fpga.png, red_mapa.png y red_trama.png.
Las posiciones, el alcance y la trama son los de hdl/tri_red.v.
"""
import math
import os

import matplotlib.pyplot as plt
from matplotlib.patches import Circle, FancyArrowPatch, FancyBboxPatch, Rectangle

import estilo as E

E.aplicar()
AQUI = os.path.dirname(os.path.abspath(__file__))
SALIDA = os.path.join(AQUI, "..", "latex", "figs")

PERSONA = (25.50, 19.25)
POS_A = (25.75, 19.00)          # posición 1 de la tabla: a 32.00 m del receptor
POS_B = (25.25, 19.00)          # posición 0: a 31.60 m
ALCANCE = 511 / 16.0            # 31.94 m


def caja(ax, x, y, w, h, color, relleno, titulo, lineas, tam=14.5):
    ax.add_patch(FancyBboxPatch((x, y), w, h, boxstyle="round,pad=0,rounding_size=0.12", lw=2.2,
                                edgecolor=color, facecolor=relleno, zorder=2))
    ax.text(x + w / 2, y + h - 0.28, titulo, ha="center", va="top", fontsize=tam + 2.5, fontweight="bold",
            color=E.TINTA, zorder=3)
    ax.text(x + w / 2, y + h - 0.88, "\n".join(lineas), ha="center", va="top", fontsize=tam, color=E.TINTA,
            linespacing=1.35, zorder=3)


def flecha(ax, p0, p1, color, texto="", dx=0.0, dy=0.0, tam=13, ha="center", va="center", rad=0.0, ls="-"):
    ax.add_patch(FancyArrowPatch(p0, p1, arrowstyle="-|>", mutation_scale=20, lw=2.3, color=color, zorder=4,
                                 connectionstyle="arc3,rad=%g" % rad, linestyle=ls))
    if texto:
        ax.text((p0[0] + p1[0]) / 2 + dx, (p0[1] + p1[1]) / 2 + dy, texto, ha=ha, va=va, fontsize=tam, color=color,
                linespacing=1.25, zorder=5)


def tres_fpga():
    """Las tres tarjetas, sus enlaces por UART y la computadora del operador."""
    fig = plt.figure(figsize=(16.64, 7.6))
    ax = fig.add_axes([0, 0, 1, 1])
    ax.set_xlim(0, 16.64)
    ax.set_ylim(0, 7.6)
    ax.axis("off")
    caja(ax, 0.3, 4.2, 5.4, 2.6, E.AMBAR, "#FBF0DC", "FPGA 1: mochila A",
         ["Núcleo del proyecto + sensor simulado", "SW5–SW0: temperatura (35 a 38 °C)", "KEY1: botón de ayuda",
          "Tono propio: 1 kHz"])
    caja(ax, 0.3, 0.75, 5.4, 2.6, E.VERDE, "#E3F1EE", "FPGA 2: mochila B",
         ["Núcleo del proyecto + sensor simulado", "SW5–SW0: temperatura (35 a 38 °C)", "KEY1: botón de ayuda",
          "Tono propio: 2 kHz"])
    caja(ax, 7.9, 2.35, 4.9, 2.85, E.AZUL_OSC, "#E4ECF5", "FPGA 3: receptor",
         ["Cuenta las personas detectadas", "Triangula con CORDIC y divisor", "Cuenta tramas perdidas (CRC-16)",
          "Tono propio: 4 kHz"])
    caja(ax, 13.75, 2.6, 2.6, 2.35, E.GRIS, "#F1F3F5", "Computadora",
         ["Terminal en vivo:", "coordenadas, grados", "y distancias"], tam=13)
    flecha(ax, (5.7, 5.6), (7.9, 4.6), E.AMBAR, "pin 35 → pin 37", dx=0.3, dy=0.45)
    flecha(ax, (5.7, 1.95), (7.9, 2.95), E.VERDE, "pin 35 → pin 39", dx=0.3, dy=-0.45)
    flecha(ax, (2.2, 4.2), (2.2, 3.35), E.AMBAR, "pin 33 → pin 37", dx=-0.12, ha="right")
    flecha(ax, (3.8, 3.35), (3.8, 4.2), E.VERDE, "pin 33 → pin 37", dx=0.12, ha="left")
    flecha(ax, (12.8, 3.78), (13.75, 3.78), E.GRIS, "USB", dy=0.28)
    ax.text(8.32, 7.25, "UART a 115 200 baudios · trama de 16 bytes cada 100 ms · CRC-16 y número de secuencia",
            ha="center", va="center", fontsize=14, color=E.GRIS)
    ax.text(8.32, 0.3, "Si A queda a 32 m o más del receptor, B retransmite su aviso (multisalto)", ha="center",
            va="center", fontsize=14, color=E.GRIS)
    return fig


def mapa():
    """El mapa de 64 m con el alcance de 32 m, y el acercamiento donde se cruzan los rumbos."""
    fig, (ax, az) = plt.subplots(1, 2, figsize=(16.64, 7.4), gridspec_kw={"width_ratios": [1.0, 1.0]}, layout="constrained")
    # ---- mapa completo
    ax.add_patch(Circle((0, 0), ALCANCE, facecolor="#E4ECF5", edgecolor=E.AZUL_OSC, lw=2.0, ls=(0, (5, 3)), zorder=1))
    ax.plot([0], [0], marker="s", ms=13, color=E.AZUL_OSC, zorder=5)
    ax.text(1.0, -2.0, "receptor (0, 0)", fontsize=14, color=E.AZUL_OSC, va="top")
    ax.plot([PERSONA[0]], [PERSONA[1]], marker="*", ms=22, color=E.ROJO, zorder=6)
    ax.text(PERSONA[0] + 3.2, PERSONA[1], "persona\n(25.50, 19.25) m", fontsize=14, color=E.ROJO, va="center")
    ax.plot([4.5], [3.0], marker="o", ms=10, color=E.VERDE, zorder=5)
    ax.text(6.0, 3.0, "posición 7 (4.5, 3.0):\nsirve de puente", fontsize=13, color=E.VERDE, va="center")
    ax.plot([40], [30], marker="o", ms=10, color=E.GRIS, zorder=5)
    ax.text(41.2, 30.0, "posición 5 (40, 30):\nfuera de alcance", fontsize=13, color=E.GRIS, va="center")
    ang = math.radians(100)
    ax.annotate("", xy=(ALCANCE * math.cos(ang), ALCANCE * math.sin(ang)), xytext=(0, 0),
                arrowprops=dict(arrowstyle="-|>", color=E.AZUL_OSC, lw=1.8))
    ax.text(-1.2, 16.5, "alcance: 31.94 m\n(radio y tonos)", fontsize=13.5, color=E.AZUL_OSC, ha="left", va="center")
    ax.set_xlim(-10, 60)
    ax.set_ylim(-12, 44)
    ax.set_aspect("equal")
    ax.set_xlabel("x (m)")
    ax.set_ylabel("y (m)")
    ax.set_title("El mapa: 64 m en 10 bits, 6.25 cm por cuenta", loc="left")
    # ---- acercamiento
    az.plot([PERSONA[0]], [PERSONA[1]], marker="*", ms=26, color=E.ROJO, zorder=6)
    for (x, y), nombre, color, grados, dist, lado in ((POS_A, "A", E.AMBAR, 135, "a 32.00 m: no se oye", 1),
                                                      (POS_B, "B", E.VERDE, 45, "a 31.60 m: se oye", -1)):
        az.plot([x], [y], marker="o", ms=15, color=color, zorder=5)
        u = (math.cos(math.radians(grados)), math.sin(math.radians(grados)))
        az.plot([x, x + 0.6 * u[0]], [y, y + 0.6 * u[1]], color=color, lw=2.4, ls=(0, (5, 3)), zorder=3)
        az.text(x + 0.06 * lado, y - 0.02, "mochila %s\nrumbo de %d°\n%s" % (nombre, grados, dist),
                ha="left" if lado > 0 else "right", va="top", fontsize=13.5, color=color, linespacing=1.3)
    # el arco del alcance pasa entre las dos mochilas
    ts = [math.radians(a / 50.0) for a in range(1700, 2000)]
    az.plot([ALCANCE * math.cos(t) for t in ts], [ALCANCE * math.sin(t) for t in ts], color=E.AZUL_OSC, lw=2.0,
            ls=(0, (2, 3)), zorder=2)
    az.text(24.70, 19.70, "borde del alcance", fontsize=13, color=E.AZUL_OSC, ha="left", va="center")
    az.text(25.80, 19.62, "los dos rumbos se cruzan\nen la persona", ha="center", va="center",
            fontsize=13.5, color=E.ROJO)
    az.set_xlim(24.65, 26.35)
    az.set_ylim(18.55, 19.85)
    az.set_aspect("equal")
    az.set_xlabel("x (m)")
    az.set_title("Acercamiento: triangulación y puente", loc="left")
    return fig


def trama():
    """Los 16 bytes de la trama de una mochila."""
    campos = [(1, "A5", "sincronía", E.GRIS), (1, "ruta", "origen,\nemisor\ny saltos", E.AZUL),
              (1, "estado", "térmica,\nbotón y\nestado", E.ROJO),
              (6, "medida del origen", "posición x, y · rumbo hacia el calor · distancia estimada · píxeles calientes", E.AMBAR),
              (3, "emisor", "posición de quien\ntransmite esta copia", E.VERDE),
              (1, "tonos", "a quién\noye, y\ngrados", "#6B5B95"), (1, "sec", "número\nde\nsecuencia", E.AZUL),
              (2, "CRC-16", "polinomio 0x1021", E.AZUL_OSC)]
    fig = plt.figure(figsize=(16.64, 2.9))
    ax = fig.add_axes([0, 0, 1, 1])
    ax.set_xlim(-0.3, 16.3)
    ax.set_ylim(0.4, 3.3)
    ax.axis("off")
    x = 0
    for n, nombre, detalle, color in campos:
        ax.add_patch(Rectangle((x + 0.04, 1.55), n - 0.08, 0.95, facecolor=color, edgecolor="white", lw=1.5, zorder=2))
        ax.text(x + n / 2, 2.02, nombre, ha="center", va="center", fontsize=14, color="white", fontweight="bold", zorder=3)
        ax.text(x + n / 2, 1.42, detalle, ha="center", va="top", fontsize=11.5 if n == 1 else 12.5, color=E.TINTA, linespacing=1.25)
        for k in range(n):
            ax.text(x + k + 0.5, 2.62, str(x + k), ha="center", va="bottom", fontsize=11.5, color=E.GRIS)
        x += n
    ax.text(8.0, 3.08, "Trama de una mochila: 16 bytes por UART a 115 200 baudios, diez veces por segundo", ha="center",
            va="center", fontsize=14.5, color=E.TINTA, fontweight="bold")
    return fig


if __name__ == "__main__":
    for nombre, f in (("red_tres_fpga", tres_fpga), ("red_mapa", mapa), ("red_trama", trama)):
        fig = f()
        ruta = os.path.join(SALIDA, nombre + ".png")
        fig.savefig(ruta, dpi=120)
        plt.close(fig)
        print(nombre, "->", os.path.relpath(ruta, AQUI))
