"""Figuras de la hoja de una página: la prueba con dos tarjetas y la mochila real a escala.

Uso:  python hoja.py
Deja latex/figs/hoja_dos_tarjetas.png y latex/figs/hoja_mochila.png.
"""
import matplotlib.pyplot as plt
from matplotlib.patches import FancyBboxPatch, Rectangle, Circle, FancyArrowPatch

import estilo as E

E.aplicar()


def caja(ax, x, y, w, h, color, relleno, titulo, lineas, tam=15):
    ax.add_patch(FancyBboxPatch((x, y), w, h, boxstyle="round,pad=0,rounding_size=0.12", lw=2.2,
                                edgecolor=color, facecolor=relleno, zorder=2))
    ax.text(x + w / 2, y + h - 0.32, titulo, ha="center", va="top", fontsize=tam + 2.5, fontweight="bold",
            color=E.TINTA, zorder=3)
    ax.text(x + w / 2, y + h - 0.95, "\n".join(lineas), ha="center", va="top", fontsize=tam, color=E.TINTA,
            linespacing=1.35, zorder=3)


def flecha(ax, x1, y1, x2, y2, color, texto, arriba=True, tam=14):
    ax.add_patch(FancyArrowPatch((x1, y1), (x2, y2), arrowstyle="-|>", mutation_scale=22, lw=2.4, color=color, zorder=4))
    ax.text((x1 + x2) / 2, y1 + (0.16 if arriba else -0.16), texto, ha="center", va="bottom" if arriba else "top",
            fontsize=tam, color=color, linespacing=1.25)


def dos_tarjetas():
    """Montaje de laboratorio: la tarjeta insecto manda la imagen y la mochila decide."""
    fig = plt.figure(figsize=(16.64, 5.4))
    ax = fig.add_axes([0, 0, 1, 1])
    ax.set_xlim(0, 16.64)
    ax.set_ylim(0, 5.4)
    ax.axis("off")
    caja(ax, 0.3, 0.9, 5.3, 4.1, E.AMBAR, "#FBF0DC", "Tarjeta B: insecto y sensor de prueba",
         ["Genera la imagen térmica de 8 × 8", "que vería el sensor y dice si el", "insecto camina o está quieto.", "",
          "Cuando recibe un estímulo, el", "insecto de prueba gira o avanza."])
    caja(ax, 11.04, 0.9, 5.3, 4.1, E.AZUL_OSC, "#E4ECF5", "Tarjeta A: la mochila",
         ["El circuito del proyecto: cuenta", "píxeles tibios, sigue los 8 estados", "y decide cuándo estimular.", "",
          "Con 8 píxeles durante cuatro", "cuadros seguidos, alerta (LEDR9)."])
    flecha(ax, 5.75, 3.75, 10.9, 3.75, E.AMBAR, "66 bytes, 10 veces por segundo:\nimagen de 8 × 8 y actividad")
    flecha(ax, 10.9, 2.35, 5.75, 2.35, E.AZUL_OSC, "4 bytes: estado, estímulo\ny píxeles calientes", arriba=False)
    ax.plot([5.75, 10.9], [1.15, 1.15], color=E.GRIS, lw=2.0, zorder=4)
    ax.text(8.32, 1.02, "tierra común (pin 30 con pin 30)", ha="center", va="top", fontsize=13.5, color=E.GRIS)
    ax.text(8.32, 3.05, "pin 35 → pin 37   ·   9600 baudios   ·   pin 37 ← pin 35", ha="center", va="center",
            fontsize=13.5, color=E.GRIS)
    ax.text(2.95, 0.5, "hace de: insecto + matriz térmica + IMU", ha="center", fontsize=14, color="#8A5200", fontweight="bold")
    ax.text(13.69, 0.5, "es: el núcleo que iría en el chip", ha="center", fontsize=14, color=E.AZUL_OSC, fontweight="bold")
    return fig


def mochila():
    """Distribución propuesta de la mochila real, a escala. Medidas de las hojas de datos."""
    fig = plt.figure(figsize=(16.64, 4.9))
    ax = fig.add_axes([0, 0, 1, 1])
    ax.set_xlim(-2.5, 76.0)
    ax.set_ylim(-11.3, 11.8)
    ax.set_aspect("equal")
    ax.axis("off")

    def numero(x, y, n):
        ax.add_patch(Circle((x, y), 1.05, facecolor="white", edgecolor=E.TINTA, lw=1.4, zorder=8))
        ax.text(x, y - 0.04, str(n), ha="center", va="center", fontsize=13, fontweight="bold", color=E.TINTA, zorder=9)

    # tarjeta de 22 x 13 mm
    ax.add_patch(FancyBboxPatch((0, -6.5), 22, 13, boxstyle="round,pad=0,rounding_size=1.2", lw=2.4,
                                edgecolor="#0F3D2E", facecolor="#17513D", zorder=1))
    piezas = [(0.6, -5.0, 12.0, 10.0, "#C9CED6", 1),        # batería
              (13.6, 1.8, 3.5, 3.6, "#1B1B1F", 2),          # nRF52840
              (14.6, -1.4, 1.4, 1.4, "#1B1B1F", 3),         # FPGA
              (13.6, -5.4, 2.5, 3.0, "#3A3F4A", 4)]         # IMU
    for x, y, w, h, c, n in piezas:
        ax.add_patch(Rectangle((x, y), w, h, facecolor=c, edgecolor="#0B0B0D", lw=1.2, zorder=3))
    numero(6.6, 0.0, 1)
    numero(15.35, 3.6, 2)
    numero(12.9, -0.7, 3)
    ax.plot([13.7, 14.6], [-0.7, -0.7], color="white", lw=1.4, zorder=7)
    numero(14.85, -3.9, 4)

    # matriz térmica al frente, mirando hacia adelante
    ax.add_patch(Rectangle((18.2, -5.8), 8.0, 11.6, facecolor="#E9E4DA", edgecolor="#0B0B0D", lw=1.2, zorder=3))
    ax.add_patch(Rectangle((22.9, -2.6), 3.0, 5.2, facecolor="#4B2A7B", edgecolor="#0B0B0D", lw=1.0, zorder=4))
    numero(20.5, 0.0, 5)

    # LED ultravioleta, uno a cada lado, por delante
    for sy in (1, -1):
        ax.plot([20.0, 28.6], [sy * 6.0, sy * 7.7], color="#0F3D2E", lw=2.0, zorder=2)
        ax.add_patch(Circle((29.4, sy * 7.9), 1.2, facecolor="#7BE06A", edgecolor="#2E7D32", lw=1.2, zorder=4))
    numero(29.4, 7.9, 6)
    numero(29.4, -7.9, 6)

    ax.annotate("", xy=(34.0, 0.0), xytext=(28.2, 0.0), arrowprops=dict(arrowstyle="-|>", color=E.AMBAR, lw=2.6))
    ax.text(31.1, 0.8, "frente", ha="center", fontsize=13.5, color=E.AMBAR, fontweight="bold")

    # cotas y escala
    ax.plot([0, 22], [9.3, 9.3], color=E.AZUL_OSC, lw=1.6)
    for xx in (0, 22):
        ax.plot([xx, xx], [8.8, 9.8], color=E.AZUL_OSC, lw=1.6)
    ax.text(11, 9.9, "22 mm: el ancho del insecto", ha="center", va="bottom", fontsize=13.5, color=E.AZUL_OSC, fontweight="bold")
    ax.plot([0, 5], [-9.6, -9.6], color=E.TINTA, lw=3)
    ax.text(2.5, -10.0, "5 mm", ha="center", va="top", fontsize=12.5, color=E.TINTA)

    # leyenda
    filas = [
        (1, "Batería LiPo de 40 mAh", "12 × 10 × 4 mm · ≈ 1 g · 41 MXN"),
        (2, "nRF52840: radio y lectura del sensor", "3.5 × 3.6 mm · ≈ 15 mg · 6 a 9 USD"),
        (3, "FPGA iCE40 UltraLite: el núcleo que decide", "1.4 × 1.4 mm · ≈ 2 mg · 2 a 3 USD"),
        (4, "IMU: dice si el insecto camina", "2.5 × 3.0 mm · miligramos"),
        (5, "Matriz térmica de 8 × 8: ve el calor", "11.6 × 8 mm · ≈ 1 g · 599 MXN"),
        (6, "LED ultravioleta junto a cada ojo: el estímulo", "3 MXN cada uno"),
    ]
    y0 = 9.4
    for n, nombre, det in filas:
        numero(38.2, y0, n)
        ax.text(40.2, y0 + 0.75, nombre, ha="left", va="center", fontsize=14.5, fontweight="bold", color=E.TINTA)
        ax.text(40.2, y0 - 0.85, det, ha="left", va="center", fontsize=13.5, color=E.GRIS)
        y0 -= 3.72
    return fig


if __name__ == "__main__":
    for nombre, f in (("hoja_dos_tarjetas", dos_tarjetas), ("hoja_mochila", mochila)):
        print(nombre, "->", E.guardar(f(), nombre))
