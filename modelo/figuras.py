"""Genera todas las figuras del esquema de investigación y de la presentación.

Uso:  python figuras.py            (todas)
      python figuras.py nombre ... (solo las indicadas)
Las figuras de simulación leen resultados.json (lo escribe experimentos.py). Los datos
publicados que se grafican llevan su fuente en el comentario de cada función y en
../investigacion/.
"""
import json
import os
import sys

import numpy as np
import matplotlib.pyplot as plt
from matplotlib.patches import Polygon, Rectangle, FancyBboxPatch, Circle

import estilo as E
import ilustracion as I
import diagramas as D
import biobot_sim as S
import parametros as P

AQUI = os.path.dirname(os.path.abspath(__file__))
E.aplicar()


def lienzo(ancho_px, alto_px, **kw):
    """Figura cuyo tamaño en pantalla (px en la lámina) es ancho_px x alto_px."""
    return plt.subplots(figsize=(ancho_px / 100, alto_px / 100), layout="constrained", **kw)


def resultados():
    with open(os.path.join(AQUI, "resultados.json"), encoding="utf-8") as f:
        return json.load(f)


# ------------------------------------------------------------------ ilustraciones
def insecto_mochila():
    """Vista dorsal y lateral, a escala. Medidas: Tran-Ngoc 2023 (largo), Li 2019 (ancho y alto)."""
    fig = plt.figure(figsize=(16.64, 6.6))
    ax = fig.add_axes([0.0, 0.0, 0.61, 1.0])
    a = I.insecto_dorsal(ax, electrodos=False)
    ax.set_xlim(-47, 68.3)
    ax.set_ylim(-37.5, 37.5)
    ax.set_aspect("equal")
    ax.axis("off")
    t = 17
    I.rotulo(ax, a["antena"], (50, 29.5), "Antenas:\ntacto y olfato", tam=t)
    I.rotulo(ax, a["led"], (24, 32.5), "LED ultravioleta junto a cada ojo:\ngira hacia el lado contrario", ha="center", tam=t)
    I.rotulo(ax, a["sensor"], (38, -27.5), "Matriz térmica:\nmira al frente", tam=t)
    I.rotulo(ax, a["chip"], (10, -32), "Núcleo digital\n(FPGA o chip propio)", ha="center", tam=t)
    I.rotulo(ax, a["radio"], (-5, 31.5), "Radio e IMU", ha="center", tam=t)
    I.rotulo(ax, a["bateria"], (-30, 23.5), "Batería de 40 mAh", ha="center", tam=t)
    I.rotulo(ax, a["abdomen"], (-27, -30), "Abdomen libre: lo flexiona\npara enderezarse", ha="center", tam=t)
    I.rotulo(ax, (-32.0, -4.6), (-45.5, -13), "Cercos", ha="left", tam=t)
    I.escala(ax, 55, -33.5)
    ax.text(-45.5, 35.2, "Macho adulto:\n5.7 ± 0.6 cm, 6.3 ± 1.5 g", ha="left", va="top", fontsize=t,
            color=E.AZUL_OSC, fontweight="bold", linespacing=1.25)

    # vista lateral: componentes uno junto a otro, no apilados
    bx = fig.add_axes([0.60, 0.04, 0.40, 0.92])
    alto, desp = 13.2, 3.0
    us = np.linspace(0, 1, 140)
    xs = I.xu(us)
    lomo = desp + alto * np.sin(np.pi * us ** 0.85) ** 0.55 * (1 - 0.12 * (us - 0.5)) / 1.02
    for xb, xp in ((18, 26), (8, 4), (0, -12)):
        bx.plot([xb, (xb + xp) / 2 + 2, xp], [desp + 2.5, desp + 5.5, 0.2], color="#2A1810", lw=5,
                solid_capstyle="round", solid_joinstyle="round", zorder=2)
    bx.add_patch(Polygon(np.vstack([np.c_[xs, lomo], np.c_[xs[::-1], np.full_like(xs, desp)]]), closed=True,
                         fc="#4A2917", ec="#140B07", lw=1.8, zorder=3))
    for u in I.TERGITOS[1:] + [I.META[1], I.MESO[1]]:
        k = np.argmin(np.abs(us - u))
        bx.plot([xs[k] - 1.2, xs[k]], [desp + 0.3, lomo[k]], color="#140B07", lw=1.3, zorder=4)
    kp = us >= I.PRO[0]
    bx.add_patch(Polygon(np.vstack([np.c_[xs[kp], lomo[kp]], [[xs[-1], desp]], [[xs[kp][0], desp]]]),
                         closed=True, fc="#24150E", ec="#0E0805", lw=1.6, zorder=4))
    I._curva(bx, (29.5, desp + 2.5), (37, desp + 7), (44, desp + 2.5), 2.2, 0.8, "#2A1810", 3)
    x0, x1 = I.xu(0.56), I.xu(0.92)
    base = float(np.interp(0.74, us, lomo)) - 0.4
    bx.add_patch(Rectangle((x0, base), x1 - x0, 0.6, fc="#12463C", ec="#0A2A24", lw=1.0, zorder=6))          # placa
    bx.add_patch(Rectangle((x0 + 0.5, base + 0.6), 9.0, 4.5, fc="#C9CED4", ec="#7B848D", lw=1.0, zorder=6))  # batería
    bx.add_patch(Rectangle((x0 + 10.5, base + 0.6), 4.0, 1.0, fc="#15181C", ec="#555E68", lw=0.8, zorder=6))  # chip
    bx.add_patch(Rectangle((x1 - 6.0, base + 0.6), 6.0, 5.0, fc="#D8DCE1", ec="#6B747D", lw=1.0, zorder=6))  # sensor
    bx.add_patch(Rectangle((x1 - 0.9, base + 1.6), 0.9, 3.0, fc="#3B1E5E", ec="none", zorder=7))
    tope = base + 5.6
    bx.plot([-40, 50], [0, 0], color=E.GRIS, lw=2.2)
    bx.add_patch(Polygon([(-40, tope + 1.6), (50, tope + 0.6), (50, tope + 12), (-40, tope + 12)], closed=True,
                         fc="#B9B3A7", ec="#7F786C", lw=1.5, zorder=1))
    bx.text(5, tope + 6.6, "losa", ha="center", va="center", fontsize=t, color="#5A544A")
    I.cota(bx, -35, 0, float(lomo.max()), "1.3 cm", lado=-1, tam=t)
    I.cota(bx, 47.5, 0, tope, "≈ 1.9 cm", lado=1, tam=t)
    bx.set_xlim(-48, 66)
    bx.set_ylim(-26, 39.6)
    bx.set_aspect("equal")
    bx.axis("off")
    bx.text(5, -5.0, "La altura estorba más que el peso:\npor una rendija de 8 mm pasa el 95 %\nsin mochila y el 15 % con una de 4 mm.",
            ha="center", va="top", fontsize=t, color=E.TINTA, linespacing=1.3)
    return fig


def portada():
    fig = plt.figure(figsize=(11.0, 6.6))
    ax = fig.add_axes([0, 0, 1, 1])
    I.insecto_dorsal(ax, electrodos=False)
    ax.set_xlim(-40, 70)
    ax.set_ylim(-33, 33)
    ax.set_aspect("equal")
    ax.axis("off")
    return fig


# --------------------------------------------------------------- datos publicados
def supervivencia():
    """Kobe 1995: Kawata 1996 citado por Shuto. Italia 1980: encuesta citada por Noji."""
    fig, ax = lienzo(1000, 600)
    dias = ["Primer día", "Días 2 y 3", "Día 4 en adelante"]
    vivos = [80, 30, 3]
    b = ax.bar(dias, vivos, color=[E.VERDE, E.AMBAR, E.ROJO], width=0.62, zorder=3)
    for r, v, tx in zip(b, vivos, ["≈ 80 %", "≈ 30 %", "casi 0"]):
        ax.text(r.get_x() + r.get_width() / 2, v + 2.5, tx, ha="center", fontsize=22, fontweight="bold")
    ax.set_ylabel("Rescatados que salieron con vida (%)")
    ax.set_ylim(0, 100)
    ax.grid(axis="x", visible=False)
    ax.set_title("Kobe, 1995: cada día cuenta", loc="left")
    return fig


def mochilas_publicadas():
    """Masa de mochilas publicadas (ver investigacion/01, tabla B.4)."""
    fig, ax = lienzo(1000, 620)
    datos = [("NTU 2026, implantada", 0.5), ("NTU 2025", 2.3), ("NC State 2020", 3.0), ("NC State 2012", 4.0),
             ("NTU 2023", 5.5), ("HIT 2023", 5.5), ("Osaka 2023", 7.4), ("RIKEN 2022", 8.1), ("Telemetría 2019", 14.0)]
    nombres = [d[0] for d in datos][::-1]
    masas = [d[1] for d in datos][::-1]
    col = [E.VERDE if m <= 3 else (E.AMBAR if m <= 6.3 else E.ROJO) for m in masas]
    ax.barh(nombres, masas, color=col, height=0.62, zorder=3)
    for i, m in enumerate(masas):
        ax.text(m + 0.25, i, f"{m:.1f} g", va="center", fontsize=17, zorder=6,
                bbox=dict(boxstyle="round,pad=0.12", fc="white", ec="none", alpha=0.9))
    ax.axvspan(2, 3, color=E.VERDE, alpha=0.13, zorder=1)
    ax.axvline(6.3, color=E.AZUL_OSC, lw=2.2, ls=(0, (5, 3)), zorder=2)
    ax.text(6.5, 9.35, "masa del insecto: 6.3 g", fontsize=15.5, color=E.AZUL_OSC, va="center")
    ax.axvline(15, color=E.ROJO, lw=2.2, ls=(0, (5, 3)), zorder=2)
    ax.text(14.8, 4.0, "con 15 g\nse detiene", fontsize=15.5, color=E.ROJO, va="center", ha="right")
    ax.text(2.5, 9.35, "meta: 2 a 3 g", fontsize=15.5, color=E.VERDE, ha="center", va="center", fontweight="bold")
    ax.set_xlim(0, 16.5)
    ax.set_ylim(-0.6, 9.8)
    ax.set_xlabel("Masa de la mochila (g)")
    ax.grid(axis="y", visible=False)
    return fig


def habituacion():
    """Modelo H <- H + a(1-H) por estímulo, con recuperación exp(-dt/tau).
    Datos: Ma 2023 (antena, 10 estímulos: -57 % cada 15 s, -34 % cada 120 s); Erickson 2015
    (monofásico -80 % a los 40 ensayos de 15 s; bifásico estable 120 ensayos)."""
    fig, axs = lienzo(1664, 560, ncols=2)
    ax = axs[0]
    metodos = ["Luz UV\n(sin cirugía)", "Electrodo\nsobre la antena", "Electrodo\ntorácico", "Electrodo\nimplantado"]
    giro = [np.nan, 38.5, 75.0, 90.0]
    exito = ["94 % sale\ndel laberinto", "81 % por\nestímulo", "> 70° en\n0.4 s", "≈ 56 % de los\nindividuos"]
    col = [E.VERDE, E.VERDE, E.AMBAR, E.ROJO]
    for i, (g, c) in enumerate(zip(giro, col)):
        if np.isnan(g):
            ax.bar(i, 60, color="none", edgecolor=c, lw=2.5, ls=(0, (5, 3)), width=0.62, zorder=3)
            ax.text(i, 30, "sin dato\nde ángulo", ha="center", va="center", fontsize=15.5, color=c)
        else:
            ax.bar(i, g, color=c, width=0.62, zorder=3)
            ax.text(i, g + 2.5, f"{g:.0f}°", ha="center", fontsize=20, fontweight="bold")
    for i, tx in enumerate(exito):
        ax.text(i, 112, tx, ha="center", va="center", fontsize=14.5, color=E.GRIS, linespacing=1.15)
    ax.set_xticks(range(4))
    ax.set_xticklabels(metodos, fontsize=15.5)
    ax.set_ylim(0, 125)
    ax.set_ylabel("Giro por estímulo (grados)")
    ax.set_title("Qué logra cada tipo de estímulo", loc="left")
    ax.grid(axis="x", visible=False)

    ax = axs[1]
    n = np.arange(0, 121)

    def curva(alfa, dt, tau=600.0):
        h, out = 0.0, []
        for _ in n:
            out.append(1 - h)
            h = (h + alfa * (1 - h)) * np.exp(-dt / tau)
        return np.array(out) * 100

    ax.plot(n, curva(0.09, 15), color=E.ROJO, label="Pulso unipolar, cada 15 s")
    ax.plot(n, curva(0.09, 120), color=E.AMBAR, label="Pulso unipolar, cada 2 min")
    ax.plot(n, curva(0.002, 15), color=E.AZUL, label="Bifásico o luz, cada 15 s")
    ax.scatter([10, 10], [42.8, 66.4], s=150, color=[E.ROJO, E.AMBAR], edgecolor="white", lw=2, zorder=5)
    ax.scatter([40], [20], s=150, marker="s", color=E.ROJO, edgecolor="white", lw=2, zorder=5)
    ax.scatter([120], [97], s=150, marker="s", color=E.AZUL, edgecolor="white", lw=2, zorder=5)
    ax.text(13, 53, "● medido, Ma 2023\n■ medido, Erickson 2015", fontsize=14.5, color=E.GRIS, va="center", linespacing=1.4)
    ax.set_xlabel("Estímulos aplicados")
    ax.set_ylabel("Respuesta que queda (%)")
    ax.set_ylim(0, 105)
    ax.set_xlim(0, 124)
    ax.legend(loc="lower right", fontsize=15.5, bbox_to_anchor=(1.0, 0.28))
    ax.set_title("El insecto se acostumbra", loc="left")
    return fig


def presupuesto_masa():
    """Tres configuraciones (investigacion/03). Masas de chips estimadas; batería y sensor medidos."""
    fig, ax = lienzo(1000, 600)
    partes = ["Batería", "Sensor térmico", "Tarjeta y chips", "Base y cables"]
    col = [E.AZUL_OSC, E.AMBAR, E.AZUL, E.GRIS_CL]
    conf = {"Mínima\n25 mAh, un punto": [0.68, 0.04, 0.42, 0.18],
            "Media\n40 mAh, matriz": [1.05, 0.99, 0.69, 0.20],
            "Completa\n120 mAh, CO₂, FPGA": [2.50, 0.99, 1.20, 0.23]}
    nombres = list(conf)
    izq = np.zeros(3)
    for i, (p, c) in enumerate(zip(partes, col)):
        v = np.array([conf[k][i] for k in nombres])
        ax.barh(nombres, v, left=izq, color=c, height=0.56, label=p, zorder=3)
        izq += v
    for k, tot in zip(range(3), izq):
        ax.text(tot + 0.1, k, f"{tot:.1f} g", va="center", fontsize=19, fontweight="bold")
    ax.axvspan(2, 3, color=E.VERDE, alpha=0.14, zorder=1)
    ax.text(2.5, 2.52, "meta", ha="center", fontsize=15.5, color=E.VERDE, fontweight="bold")
    ax.axvline(6.3, color=E.AZUL_OSC, lw=2.2, ls=(0, (5, 3)))
    ax.text(6.2, 2.52, "masa del insecto", ha="right", fontsize=15.5, color=E.AZUL_OSC)
    ax.set_xlim(0, 6.9)
    ax.set_ylim(-0.55, 2.75)
    ax.invert_yaxis()
    ax.set_xlabel("Masa (g)")
    ax.grid(axis="y", visible=False)
    ax.legend(ncols=4, loc="upper center", bbox_to_anchor=(0.5, -0.17), fontsize=15, columnspacing=1.2, handlelength=1.2)
    return fig


def energia():
    """Potencias: Tran-Ngoc 2023 (matriz, clasificador, total), Erickson 2015 (estímulo),
    Herreid 1981 (metabolismo, conversión propia), hojas de datos (IMU, radio)."""
    fig, ax = lienzo(1000, 600)
    datos = [("Estímulo (mientras dura el tren)", 2.2, E.VERDE), ("IMU moderna", 2.3, E.AZUL),
             ("Radio de baja potencia", 0.3, E.AZUL), ("Clasificador a 1 cuadro/s", 2.4, E.AZUL),
             ("Matriz térmica 32×32", 21.5, E.AMBAR), ("Insecto en reposo", 5.5, "#7A4322"),
             ("Insecto caminando", 24.0, "#7A4322"), ("Mochila de NTU completa", 205.5, E.ROJO)]
    nombres = [d[0] for d in datos][::-1]
    vals = [d[1] for d in datos][::-1]
    ax.barh(nombres, vals, color=[d[2] for d in datos][::-1], height=0.62, zorder=3)
    for i, v in enumerate(vals):
        ax.text(v * 1.12, i, f"{v:g} mW", va="center", fontsize=17)
    ax.set_xscale("log")
    ax.set_xlim(0.2, 900)
    ax.set_xlabel("Potencia (mW, escala logarítmica)")
    ax.grid(axis="y", visible=False)
    return fig


def deteccion_termica():
    """Física del campo de visión. Piel expuesta a 33 °C, fondo a 22 °C, blanco de 0.03 m² (supuestos)."""
    fig, axs = lienzo(1664, 560, ncols=2)
    d = np.linspace(0.05, 4.0, 400)
    ax = axs[0]
    f = np.minimum(1.0, 0.03 / (np.pi * (d * np.tan(np.deg2rad(45))) ** 2))
    ax.plot(d, 22 + 11 * f, color=E.AZUL_OSC, label="Lectura de un solo píxel (90°)")
    ax.axhspan(35.5, 38.5, color=E.ROJO, alpha=0.16)
    ax.text(3.9, 37.0, "umbral fijo de 35.5 a 38.5 °C: nunca se alcanza", ha="right", va="center", fontsize=15.5, color=E.ROJO)
    ax.axhline(22.5, color=E.VERDE, lw=2.2, ls=(0, (5, 3)))
    ax.text(3.9, 23.1, "0.5 °C sobre el fondo", ha="right", fontsize=15.5, color=E.VERDE)
    k = np.argmin(np.abs(22 + 11 * f - 22.5))
    ax.scatter([d[k]], [22.5], s=140, color=E.VERDE, edgecolor="white", lw=2, zorder=5)
    ax.annotate(f"alcance ≈ {d[k]:.1f} m", (d[k], 22.5), (0.95, 27.0), fontsize=16, color=E.VERDE,
                arrowprops=dict(arrowstyle="-", color=E.VERDE, lw=1.4))
    ax.set_ylim(20, 40)
    ax.set_xlim(0, 4)
    ax.set_xlabel("Distancia a la persona (m)")
    ax.set_ylabel("Temperatura que lee el sensor (°C)")
    ax.set_title("Un píxel promedia todo lo que ve", loc="left")

    ax = axs[1]
    for nombre, ifov, npx, col, n_pre, n_det in (("Matriz 32×32, 90°", 90 / 32, 1024, E.AZUL_OSC, 2, 8),
                                               ("Matriz 8×8, 60°", 60 / 8, 64, E.AMBAR, 1, 2)):
        n = np.minimum(npx, 0.03 / (d * np.tan(np.deg2rad(ifov))) ** 2)
        ax.plot(d, n, color=col, label=nombre)
        for umbral, marca in ((n_pre, "o"), (n_det, "s")):
            dd = np.sqrt(0.03 / umbral) / np.tan(np.deg2rad(ifov))
            ax.scatter([dd], [umbral], s=150, marker=marca, color=col, edgecolor="white", lw=2, zorder=5)
            ax.text(dd + 0.08, umbral * 1.18, f"{dd:.1f} m", fontsize=15.5, color=col)
    ax.set_yscale("log")
    ax.set_ylim(0.5, 300)
    ax.set_xlim(0, 4)
    ax.set_xlabel("Distancia a la persona (m)")
    ax.set_ylabel("Píxeles calientes")
    ax.legend(loc="upper right", fontsize=15.5)
    ax.text(0.12, 0.62, "● se acerca    ■ confirma", fontsize=15.5, color=E.GRIS)
    ax.set_title("Una matriz cuenta píxeles", loc="left")
    return fig


def ventana_operativa():
    """Actividad del insecto: Gracidas-Reyes et al. 2026, Tabla 2 (caminadora esférica, 42 individuos):
    tasa máxima de actividad y proporción de inactividad. Contraste: piel a 33 °C menos el ambiente."""
    fig, ax = lienzo(1000, 600)
    T = np.linspace(12, 42, 300)
    ax.plot(T, np.clip(33 - T, 0, None), color=E.AMBAR, label="Contraste térmico de la piel (°C)")
    temp = np.array([18, 22, 26, 30, 34, 38])
    pico = np.array([6.18, 8.67, 10.24, 11.72, 10.80, 12.05])
    inactivo = [20, 25, 35, 40, 53, 52]
    ax.plot(temp, pico, "o-", color="#7A4322", ms=10, label="Tasa máxima de actividad (cm/s)")
    for t_, p_, i_ in zip(temp, pico, inactivo):
        if t_ == 18:
            ax.text(t_, p_ - 1.3, "inmóvil el 20 %\ndel tiempo", ha="center", va="top", fontsize=14.5, color="#7A4322",
                    linespacing=1.15)
        elif t_ == 38:
            ax.text(t_ - 0.5, p_ - 1.3, f"{i_} %", ha="right", va="top", fontsize=14.5, color="#7A4322")
        else:
            ax.text(t_, p_ - 1.3, f"{i_} %", ha="center", va="top", fontsize=14.5, color="#7A4322")
    ax.axvspan(34, 42, color=E.ROJO, alpha=0.13)
    ax.text(38, 21.3, "más de la mitad del\ntiempo inmóvil y\nsin contraste", ha="center", va="center", fontsize=15, color=E.ROJO)
    ax.axvspan(22, 30, color=E.VERDE, alpha=0.13)
    ax.text(26, 22.0, "ventana útil\n22 a 30 °C", ha="center", va="center", fontsize=15.5, color=E.VERDE, fontweight="bold")
    ax.plot([38, 38], [0, 16.3], color=E.ROJO, lw=1.6, ls=(0, (4, 3)))
    ax.text(38, 16.9, "Myanmar, 2025", fontsize=14.5, color=E.ROJO, ha="center")
    ax.set_xlim(12, 42)
    ax.set_ylim(0, 25)
    ax.set_xlabel("Temperatura ambiente (°C)")
    ax.legend(loc="upper center", bbox_to_anchor=(0.5, -0.16), ncols=2, fontsize=15)
    return fig


def radio_escombro():
    """Atenuación en concreto con ITU-R P.2040-1 (cálculo en investigacion/03). Es un piso optimista."""
    fig, ax = lienzo(1000, 600)
    f = ["433 MHz", "915 MHz", "2.4 GHz\n(Bluetooth)", "6.5 GHz\n(UWB)"]
    a = [12, 22, 47, 105]
    b = ax.bar(f, a, color=[E.VERDE, E.VERDE, E.AMBAR, E.ROJO], width=0.6, zorder=3)
    for r, v in zip(b, a):
        ax.text(r.get_x() + r.get_width() / 2, v + 2.5, f"{v} dB/m", ha="center", fontsize=19, fontweight="bold")
    ax.axhline(60, color=E.AZUL_OSC, lw=2.2, ls=(0, (5, 3)))
    ax.text(-0.42, 62.5, "margen de un enlace sub-GHz: ≈ 60 dB", ha="left", fontsize=15.5, color=E.AZUL_OSC)
    ax.set_ylabel("Pérdida en concreto macizo (dB por metro)")
    ax.set_ylim(0, 122)
    ax.grid(axis="x", visible=False)
    return fig


def localizacion():
    """Error de la posición por IMU: 5 % de la distancia en 2D y 10 % en 3D (Tran-Ngoc 2024)."""
    fig, ax = lienzo(1000, 600)
    d = np.linspace(0, 30, 100)
    ax.fill_between(d, 0.05 * d, 0.10 * d, color=E.AZUL, alpha=0.25, zorder=2)
    ax.plot(d, 0.05 * d, color=E.AZUL_OSC, label="Navegación inercial, terreno plano (5 %)")
    ax.plot(d, 0.10 * d, color=E.AZUL, label="Con desniveles (10 %)")
    ax.axhline(1.25, color=E.AMBAR, lw=2.2, ls=(0, (5, 3)))
    ax.text(29.5, 1.33, "alcance de confirmación de la matriz: 1.25 m", ha="right", fontsize=15.5, color=E.AMBAR)
    ax.axhline(0.5, color=E.VERDE, lw=2.2, ls=(0, (5, 3)))
    ax.text(29.5, 0.58, "baliza de radio y luz: último medio metro", ha="right", fontsize=15.5, color=E.VERDE)
    ax.set_xlim(0, 30)
    ax.set_ylim(0, 3.2)
    ax.set_xlabel("Distancia recorrida por el insecto (m)")
    ax.set_ylabel("Error de posición (m)")
    ax.legend(loc="upper left", fontsize=15.5)
    return fig


def costos():
    """Costos por unidad. Biobot: piezas a precio de mostrador en México (UNIT Electronics, 09-11-2026)
    a 18.8 MXN por USD. Lo demás: Murphy 2021, Search Dog Foundation, IEEE Spectrum 2020."""
    fig, ax = lienzo(1000, 600)
    datos = [("Mochila de prototipo\n(matriz 8×8)", 55, 55, E.VERDE), ("Mochila de prototipo\n(matriz 32×24)", 81, 81, E.VERDE),
             ("Enjambre de 20\ncon relevo", 1300, 1800, E.AZUL), ("Dron pequeño", 1000, 1000, E.GRIS),
             ("Binomio canino", 50000, 75000, E.AMBAR), ("Robot terrestre\nde rescate", 50000, 150000, E.ROJO)]
    nombres = [d[0] for d in datos][::-1]
    for i, (_, lo, hi, c) in enumerate(datos[::-1]):
        ax.barh(i, hi, color=c, height=0.6, zorder=3)
        tx = f"{lo:,.0f} USD".replace(",", " ") if lo == hi else f"{lo:,.0f} a {hi:,.0f} USD".replace(",", " ")
        ax.text(hi * 1.15, i, tx, va="center", fontsize=16.5)
    ax.set_yticks(range(len(nombres)))
    ax.set_yticklabels(nombres, fontsize=15.5)
    ax.set_xscale("log")
    ax.set_xlim(20, 3e6)
    ax.set_xlabel("Costo por unidad (USD, escala logarítmica)")
    ax.grid(axis="y", visible=False)
    return fig


def recursos_fpga():
    """Síntesis real en Quartus Prime 24.1 para el 10M50DAF484C7G (quartus/output_files/biobot.fit.rpt)."""
    fig, ax = lienzo(1000, 600)
    mod = [("fsm_politica", 181, 64), ("ventana_termica", 160, 61), ("gen_estimulo", 64, 47), ("media_movil4", 40, 28),
           ("lfsr16", 16, 16), ("detector_quietud", 10, 4), ("detector_presencia", 9, 4)]
    y = np.arange(len(mod))[::-1]
    ax.barh(y + 0.19, [m[1] for m in mod], height=0.36, color=E.AZUL_OSC, label="Elementos lógicos", zorder=3)
    ax.barh(y - 0.19, [m[2] for m in mod], height=0.36, color=E.AMBAR, label="Registros", zorder=3)
    for yy, m in zip(y, mod):
        ax.text(m[1] + 3, yy + 0.19, str(m[1]), va="center", fontsize=15.5)
        ax.text(m[2] + 3, yy - 0.19, str(m[2]), va="center", fontsize=15.5)
    ax.set_yticks(y)
    ax.set_yticklabels([m[0] for m in mod], fontsize=16, family="Consolas")
    ax.set_xlim(0, 215)
    ax.set_xlabel("Recursos en la MAX 10 (DE10-Lite)")
    ax.grid(axis="y", visible=False)
    ax.legend(loc="lower right", fontsize=15.5)
    ax.text(213, 2.6, "Núcleo completo:\n477 elementos lógicos\n224 registros", ha="right", va="center", fontsize=17,
            fontweight="bold", color=E.AZUL_OSC, linespacing=1.3)
    return fig


# -------------------------------------------------------------------- simulación
def mapa_trayectorias():
    fig, axs = lienzo(1664, 640, ncols=2)
    m = S.generar_mapa(12, 8.0, 6.0)
    p = P.con()
    ext = (0, m.forma[1] * m.res, m.forma[0] * m.res, 0)
    col = [E.AZUL, E.AMBAR, E.VERDE, "#6B5B95", E.ROJO, "#2E7D6B"]
    for ax, pol, tit in zip(axs, (S.PASIVA, S.GUIADA), ("Sin estímulos", "Con la política guiada")):
        r = S.simular(m, p, pol, 6, 2, 2700.0, semilla=21, guardar_tray=True)
        ax.imshow(np.where(m.libre, np.nan, 1.0), cmap="Greys", vmin=0, vmax=1.6, extent=ext, zorder=1)
        zona = np.where(m.vis_v & (m.dist_v <= S.alcance(p, p["n_det"])), 1.0, np.nan)
        ax.imshow(zona, cmap="autumn", alpha=0.30, extent=ext, zorder=2)
        T = np.array([[t[0], t[1]] for t in r["tray"]])
        for i in range(T.shape[2]):
            ax.plot(T[:, 0, i], T[:, 1, i], lw=1.5, color=col[i], alpha=0.9, zorder=3)
        ax.plot((m.victima[1] + .5) * m.res, (m.victima[0] + .5) * m.res, "*", ms=30, color=E.ROJO, mec="white", mew=2, zorder=6)
        ax.plot((m.entrada[1] + .5) * m.res, (m.entrada[0] + .5) * m.res, "s", ms=15, color=E.VERDE, mec="white", mew=2, zorder=6)
        cob = r["visit0"].sum() / m.alcanzable.sum() * 100
        td = r["t_det"][0]
        det = f"detecta a los {td / 60:.0f} min" if np.isfinite(td) else "no detecta en 45 min"
        ax.set_title(f"{tit}: cubre {cob:.0f} % y {det}", loc="left", fontsize=19)
        ax.set_xlim(0, ext[1])
        ax.set_ylim(ext[2], 0)
        ax.set_aspect("equal")
        ax.grid(False)
        ax.set_xlabel("metros")
        for s in ax.spines.values():
            s.set_visible(False)
    return fig


def separar(valores, minimo):
    """Posiciones para rotular varias curvas al final sin que los textos se encimen."""
    orden = np.argsort(valores)
    pos = np.array(valores, dtype=float)
    for a, b in zip(orden[:-1], orden[1:]):
        if pos[b] - pos[a] < minimo:
            pos[b] = pos[a] + minimo
    return pos


def resultados_politicas():
    r = resultados()["politicas"]
    fig, axs = lienzo(1664, 560, ncols=2)
    col = {"Pasiva": E.GRIS, "Antipausa": E.AZUL, "Estocástica": E.AMBAR, "Guiada": E.VERDE}
    t = np.arange(0, 61)
    ax = axs[0]
    fin = [r[k]["cdf_min"][-1] * 100 for k in col]
    for (k, c), y in zip(col.items(), separar(fin, 5.5)):
        ax.plot(t, np.array(r[k]["cdf_min"]) * 100, color=c, label=k)
        ax.text(60.8, y, f"{r[k]['cdf_min'][-1] * 100:.0f} %", color=c, fontsize=16, va="center")
    ax.axvline(45, color=E.GRIS, lw=1.4, ls=(0, (4, 3)))
    ax.text(44.3, 4, "sesión de 45 min\n(Myanmar)", ha="right", fontsize=14.5, color=E.GRIS)
    ax.set_xlim(0, 66)
    ax.set_ylim(0, 100)
    ax.set_xlabel("Minutos desde la liberación")
    ax.set_ylabel("Misiones con detección (%)")
    ax.set_title("Probabilidad de encontrar a la persona", loc="left")
    ax.legend(loc="upper left", fontsize=15.5)
    ax = axs[1]
    tm = np.arange(1, 61)
    fin = [r[k]["cob_media"][-1] * 100 for k in col]
    for (k, c), y in zip(col.items(), separar(fin, 5.5)):
        ax.plot(tm, np.array(r[k]["cob_media"]) * 100, color=c, label=k)
        ax.text(60.8, y, f"{r[k]['cob_media'][-1] * 100:.0f} %", color=c, fontsize=16, va="center")
    ax.set_xlim(0, 66)
    ax.set_ylim(0, 100)
    ax.set_xlabel("Minutos desde la liberación")
    ax.set_ylabel("Huecos recorridos (%)")
    ax.set_title("Cobertura del colapso", loc="left")
    return fig


def enjambre():
    r = resultados()["enjambre"]
    fig, ax = lienzo(1000, 600)
    n = r["n"]
    for k, c in (("Pasiva", E.GRIS), ("Guiada", E.VERDE)):
        p45 = [x["p_det"]["45"] * 100 for x in r[k]]
        ax.plot(n, p45, "o-", color=c, label=f"{k}", ms=11)
        for xx, yy in zip(n, p45):
            ax.text(xx, yy + (4 if k == "Guiada" else -7.5), f"{yy:.0f}", ha="center", fontsize=15.5, color=c)
    ax.set_xscale("log")
    ax.set_xticks(n)
    ax.set_xticklabels([str(x) for x in n])
    ax.minorticks_off()
    ax.set_ylim(0, 105)
    ax.set_xlabel("Insectos liberados")
    ax.set_ylabel("Misiones con detección en 45 min (%)")
    ax.legend(loc="lower right", fontsize=16)
    return fig


def por_mapa():
    """Dispersión entre colapsos: detección a 60 min, mapa por mapa, ordenados por distancia a la persona."""
    res = resultados()
    r = res["por_mapa"]
    orden = np.argsort(r["dist_victima"])
    series = [("Diez pasivos", [x["p60"] * 100 for x in r["Pasiva"]], E.GRIS),
              ("Diez guiados", [x["p60"] * 100 for x in r["Guiada"]], E.VERDE)]
    if "mixto" in res:
        series.append(("Cinco y cinco", [x * 100 for x in res["mixto"]["p60"]], E.AMBAR))
    fig, ax = lienzo(1000, 600)
    ancho = 0.8 / len(series)
    for k, (nombre, v, c) in enumerate(series):
        x = np.arange(len(orden)) + (k - (len(series) - 1) / 2) * ancho
        ax.bar(x, [max(v[j], 1.2) for j in orden], width=ancho * 0.92, color=c, label=nombre, zorder=3)
    ax.set_xticks(range(len(orden)))
    ax.set_xticklabels([f"{r['dist_victima'][j]:.0f} m" for j in orden], fontsize=16)
    ax.set_ylim(0, 118)
    ax.set_yticks([0, 20, 40, 60, 80, 100])
    ax.set_xlabel("Colapsos, ordenados por el recorrido de la entrada a la persona")
    ax.set_ylabel("Misiones con detección en 60 min (%)")
    ax.grid(axis="x", visible=False)
    ax.legend(loc="upper center", fontsize=15.5, ncols=len(series), frameon=False)
    return fig


REGRESO_SERIES = [
    # caso en resultados.json, rótulo, color, trazo
    ("Solo trampa", "Solo el refugio", E.GRIS, "-"),
    ("Mantenerlo caminando", "Mantenerlo caminando", E.AZUL, "-"),
    ("Rumbo directo", "Rumbo a ciegas", E.ROJO, "-"),
    ("Ruta inversa", "Desandar la ruta", E.AMBAR, "-"),
    ("Faro, alcanza 6 m de camino", "Faro que alcanza 6 m", E.VERDE, "-"),
    ("Faro, sin límite de alcance", "Faro sin límite", E.VERDE, (0, (4, 3))),
]


def regreso():
    """Recuperación: insectos de vuelta en el refugio de la entrada según cómo se les haga volver."""
    r = resultados()["regreso"]
    t = [0] + r["cortes"]
    series = [s for s in REGRESO_SERIES if s[0] in r["casos"]]
    fin = [r["casos"][k]["recogidos"][str(r["cortes"][-1])] * 100 for k, _, _, _ in series]
    fig, ax = lienzo(1000, 600)
    for (k, nombre, c, ls), y in zip(series, separar(fin, 6.5)):
        v = [0.0] + [r["casos"][k]["recogidos"][str(m)] * 100 for m in r["cortes"]]
        ax.plot(t, v, color=c, ls=ls, marker="o", ms=7)
        ax.text(t[-1] + 4, y, f"{v[-1]:.0f} %  {nombre}", color=c, fontsize=15, va="center")
    ax.set_xlim(0, 208)
    ax.set_xticks(t)
    ax.set_ylim(0, 105)
    ax.set_yticks([0, 20, 40, 60, 80, 100])
    ax.set_xlabel("Minutos desde la orden de regreso", loc="left")
    ax.set_ylabel("Insectos recogidos en la entrada (%)")
    ax.grid(axis="x", visible=False)
    for lado in ("top", "right"):
        ax.spines[lado].set_visible(False)
    return fig


def sensores_habituacion():
    res = resultados()
    fig, axs = lienzo(1664, 560, ncols=2)
    ax = axs[0]
    s = res["sensor"]
    nombres = list(s)
    x = np.arange(len(nombres))
    for j, (corte, c) in enumerate((("30", E.AZUL), ("45", E.AZUL_OSC), ("60", E.AMBAR))):
        v = [s[k]["p_det"][corte] * 100 for k in nombres]
        b = ax.bar(x + (j - 1) * 0.26, v, width=0.25, color=c, label=f"{corte} min", zorder=3)
        for r, vv in zip(b, v):
            ax.text(r.get_x() + r.get_width() / 2, vv + 1.5, f"{vv:.0f}", ha="center", fontsize=15)
    ax.set_xticks(x)
    ax.set_xticklabels([k.replace(", ", "\n") for k in nombres], fontsize=16)
    ax.set_ylim(0, 100)
    ax.set_ylabel("Misiones con detección (%)")
    ax.set_title("Tres sensores, la misma política", loc="left")
    ax.grid(axis="x", visible=False)
    ax.legend(loc="upper left", fontsize=15.5)

    ax = axs[1]
    h = res["habituacion"]
    nombres = ["Pasiva", "Unipolar sin dosificar", "Unipolar dosificado", "Sin habituación, dosificado"]
    etiquetas = ["Sin\nestímulos", "Unipolar,\nsin límite", "Unipolar,\ndosificado", "Bifásico o luz,\ndosificado"]
    det = [h[k]["cdf_min"][-1] * 100 for k in nombres]
    est = [h[k]["est_por_hora"] for k in nombres]
    resp = [(1 - h[k]["hab_fin"]) * 100 for k in nombres]
    b = ax.bar(range(4), det, color=[E.GRIS, E.ROJO, E.AMBAR, E.VERDE], width=0.62, zorder=3)
    for i, r in enumerate(b):
        ax.text(r.get_x() + r.get_width() / 2, det[i] + 1.5, f"{det[i]:.0f} %", ha="center", fontsize=19, fontweight="bold")
        if i:
            etiquetas[i] += f"\n{est[i]:.0f} por hora\nresponde {resp[i]:.0f} %"
        else:
            etiquetas[i] += "\n\n"
    ax.set_xticks(range(4))
    ax.set_xticklabels(etiquetas, fontsize=14.5, linespacing=1.25)
    ax.set_ylim(0, 108)
    ax.set_yticks([0, 20, 40, 60, 80, 100])
    ax.set_ylabel("Misiones con detección en 2 h (%)")
    ax.set_title("Dosificar: lo mismo con un tercio de los estímulos", loc="left")
    ax.grid(axis="x", visible=False)
    return fig


def sensibilidad():
    res = resultados()
    s, base = res["sensibilidad"], res["sensibilidad_base"]["Guiada"]["p45"] * 100
    nombres = {"p_rodea": "Dobla esquinas pegado a la pared (0.5 a 0.95)", "k_refugio": "Pausas más largas a oscuras (×1 a ×3)",
               "area_blanco": "Piel a la vista (0.01 a 0.10 m²)", "p_resp": "Obedece al estímulo (50 a 90 %)",
               "frac_responde": "Individuos que responden (56 a 100 %)", "t_pausa": "Duración de las pausas (18 a 74 s)",
               "tasa_perdida": "Insectos perdidos por hora (0 a 50 %)", "pen_carga": "Velocidad perdida por la carga (0 a 30 %)",
               "v_natural": "Velocidad de marcha (1.4 a 2.5 cm/s)", "alfa_hab": "Habituación por estímulo (0 a 6 %)",
               "k_foto": "Huida de la luz (0 a 2)", "l_tramo": "Largo del tramo recto (9 a 35 cm)"}
    filas = []
    for k, v in s.items():
        lo, hi = v["bajo_Guiada"]["p45"] * 100, v["alto_Guiada"]["p45"] * 100
        filas.append((abs(hi - lo), nombres[k], lo, hi))
    filas.sort()
    fig, ax = lienzo(1200, 640)
    # Margen de muestreo de un porcentaje cercano a 80 % con 160 misiones (95 %): unos 6 puntos
    ax.axvspan(base - 6, base + 6, color=E.GRIS, alpha=0.13, zorder=1)
    ax.text(base - 3, len(filas) - 0.38, "margen de\nmuestreo", ha="center", va="bottom", fontsize=13, color=E.GRIS,
            linespacing=1.1)
    for i, (_, nom, lo, hi) in enumerate(filas):
        ax.barh(i, hi - base, left=base, color=E.AZUL_OSC, height=0.6, zorder=3)
        ax.barh(i, lo - base, left=base, color=E.AMBAR, height=0.6, zorder=3)
    ax.axvline(base, color=E.TINTA, lw=1.6)
    ax.set_yticks(range(len(filas)))
    ax.set_yticklabels([f[1] for f in filas], fontsize=15)
    ax.set_ylim(-0.7, len(filas) + 0.75)
    ax.set_xlabel("Detección en 45 min con la política guiada (%)")
    ax.grid(axis="y", visible=False)
    ax.barh([np.nan], [np.nan], color=E.AMBAR, label="valor bajo")
    ax.barh([np.nan], [np.nan], color=E.AZUL_OSC, label="valor alto")
    ax.legend(loc="lower left", fontsize=15)
    return fig


# ------------------------------------------------------------------- diagramas
def marco_modelo():
    return D.marco_modelo({
        "M1": ("El insecto", "Masa, tamaño y fuerza.\nCuánto camina y cuánto\nse detiene.\nQué rendijas pasa.", "Carga útil: 2 a 3 g"),
        "M2": ("El estímulo", "Qué estímulo produce\nqué conducta.\nCuántas veces obedece\ny cuándo se acostumbra.", "Giros útiles por hora"),
        "M3": ("La mochila", "Masa y energía de\ncada componente.\nMicrocontrolador,\nFPGA o chip propio.", "Gramos, mW y horas"),
        "M4": ("La detección", "Calor de una persona\ncontra la distancia.\nPíxeles calientes y\nfalsas alarmas.", "Alcance en metros"),
        "M5": ("La misión", "Enjambre dentro de\nun colapso simulado.\nPolítica de estímulos\nque corre a bordo.", "Tiempo a la detección"),
        "E": ("Ética y normativa", "Acotan todo lo anterior: carga máxima, estímulos por hora, descanso, método sin cirugía\ny recuperación de insectos y equipo."),
    })


def fsm_politica():
    return D.fsm_politica({
        "sub": {"REPOSO": "espera el arranque", "EXPLORAR": "marcha natural", "REACTIVAR": "pulso de avance",
                "REORIENTAR": "giro al azar", "DESCANSO": "sin presupuesto", "ACERCAR": "gira hacia el calor",
                "CONFIRMAR": "deja de estimular", "ALERTAR": "avisa por radio"},
        "trans": {"inicio": "arranque", "giro": "al azar,\n1 cada 51 s", "hecho": "tras\n0.5 s", "quieto": "quieto\n15 s × 2ⁿ",
                  "anda": "camina o\npasan 3 s", "fallos": "12 estímulos:\ndescansa", "descanso": "ve calor",
                  "pre": "2 píxeles", "pierde": "5 s sin calor", "umbral": "8 píxeles", "conf": "4 cuadros\nseguidos",
                  "falso": "baja"},
        "nota_t": "Presupuesto de estímulos",
        "nota": "Cada estímulo suma 1 a una cuenta\nque se vacía sola en unos 10 min.\nCon 12, el insecto descansa.",
    })


def nucleo_digital():
    return D.nucleo_digital({
        "marco": "nucleo_biobot: 477 elementos lógicos, 224 registros",
        "esp_in": "matriz 8×8 e IMU", "rx": "9600 baudios", "trama": "píxeles y actividad",
        "ventana": "píxeles calientes", "media": "4 cuadros", "presencia": "2 y 8 píxeles",
        "quietud": "1 s sin moverse", "lfsr": "giros al azar", "fsm": "8 estados",
        "gen": "50 Hz, 0.5 s", "esp_out": "Wi-Fi al rescatista", "emisor": "4 bytes de estado",
        "sal": "LED UV o electrodos",
    })


def sistema():
    return D.sistema({
        "victima": "persona atrapada", "enjambre": "10 a 20 insectos dentro de los huecos",
        "relevo_t": "Relevo en la entrada", "relevo": "radio sub-GHz:\nrecibe las alertas",
        "base_t": "Estación del rescatista", "base": "qué insecto avisó, por dónde entró\ny cuánto caminó",
        "mochila_t": "Cada mochila", "mochila": "decide sola:\nnadie pilotea",
        "salida_t": "Resultado", "salida": "un punto donde cavar primero,\ncon su margen de error",
        "enlace1": "alerta", "enlace2": "cable",
    })


def cronograma():
    return D.cronograma(
        [("Modelo y simulación", 9, 12, E.AZUL), ("Núcleo en Verilog y bancos de prueba", 10, 15, E.AZUL_OSC),
         ("Sensor térmico y ESP32", 13, 19, E.VERDE), ("Integración en la DE10-Lite", 17, 23, E.AMBAR),
         ("Mediciones y demostración", 22, 25, E.ROJO), ("Reporte final", 24, 32, E.GRIS)],
        [(25, "Demostración"), (32, "Reporte")], dia0=9, dias=24)


FIGURAS = {
    "portada": portada, "insecto_mochila": insecto_mochila, "supervivencia": supervivencia,
    "mochilas_publicadas": mochilas_publicadas, "habituacion": habituacion, "presupuesto_masa": presupuesto_masa,
    "energia": energia, "deteccion_termica": deteccion_termica, "ventana_operativa": ventana_operativa,
    "radio_escombro": radio_escombro, "localizacion": localizacion, "costos": costos, "recursos_fpga": recursos_fpga,
    "marco_modelo": marco_modelo, "fsm_politica": fsm_politica, "nucleo_digital": nucleo_digital, "sistema": sistema,
    "cronograma": cronograma, "mapa_trayectorias": mapa_trayectorias, "resultados_politicas": resultados_politicas,
    "enjambre": enjambre, "por_mapa": por_mapa, "sensores_habituacion": sensores_habituacion,
    "sensibilidad": sensibilidad, "regreso": regreso,
}

# --------------------------------------------------- números y tablas para LaTeX
SENS_NOMBRES = {
    "p_rodea": ("Dobla esquinas pegado a la pared", "0.5", "0.95"),
    "k_refugio": ("Pausas más largas a oscuras", "×1", "×3"),
    "area_blanco": ("Piel a la vista", "0.01 m$^2$", "0.10 m$^2$"),
    "p_resp": ("Obedece al estímulo", "50 \\%", "90 \\%"),
    "frac_responde": ("Individuos que responden", "56 \\%", "100 \\%"),
    "t_pausa": ("Duración de las pausas", "18 s", "74 s"),
    "tasa_perdida": ("Insectos perdidos por hora", "0 \\%", "50 \\%"),
    "pen_carga": ("Velocidad perdida por la carga", "0 \\%", "30 \\%"),
    "v_natural": ("Velocidad de marcha", "1.4 cm/s", "2.5 cm/s"),
    "alfa_hab": ("Habituación por estímulo", "0 \\%", "6 \\%"),
    "k_foto": ("Huida de la luz", "0", "2"),
    "l_tramo": ("Largo del tramo recto", "9 cm", "35 cm"),
}


def numeros():
    """Escribe latex/figs/numeros.tex (macros) y las tablas de resultados, todo desde resultados.json."""
    res = resultados()
    pct = lambda x: f"{100 * x:.0f}"
    mac = {}
    m = res["meta"]
    mac["numMisiones"] = str(len(m["mapas"]) * m["corridas"])
    mac["numMapas"] = str(len(m["mapas"]))
    mac["numCorridas"] = str(m["corridas"])
    mac["areaLibre"] = f"{m['area_libre_media']:.0f}"
    mac["distVictima"] = f"{m['dist_victima_media']:.1f}"
    cortes = {"15": "Quince", "30": "Treinta", "45": "CuarentaCinco", "60": "Sesenta"}
    pol = {"Pasiva": "Pasiva", "Antipausa": "Antipausa", "Estocástica": "Estocastica", "Guiada": "Guiada"}
    for k, nom in pol.items():
        r = res["politicas"][k]
        for c, cn in cortes.items():
            mac[f"p{nom}{cn}"] = pct(r["p_det"][c])
        mac[f"est{nom}"] = f"{r['est_por_hora']:.0f}"
        mac[f"cob{nom}"] = pct(r["cob_media"][-1])
        mac[f"tMed{nom}"] = f"{r['t_mediana'] / 60:.0f}"
        mac[f"anda{nom}"] = pct(r["frac_anda"])
    v = res["validacion"]
    for k, nom in (("natural", "Nat"), ("comandos", "Com")):
        mac[f"valAnda{nom}"] = f"{v[k]['frac_anda']:.2f}"
        mac[f"valPausa{nom}"] = f"{v[k]['pausa_media']:.1f}"
        mac[f"valSalida{nom}"] = f"{v[k]['p_salida']:.3f}"
    mac["valEstCom"] = f"{v['comandos']['est_por_hora']:.0f}"
    tam = {1: "Uno", 2: "Dos", 5: "Cinco", 10: "Diez", 20: "Veinte", 40: "Cuarenta"}
    e = res["enjambre"]
    for k in ("Pasiva", "Guiada"):
        for n, r in zip(e["n"], e[k]):
            mac[f"enj{k}{tam[n]}"] = pct(r["p_det"]["45"])
            mac[f"enjHora{k}{tam[n]}"] = pct(r["p_det"]["60"])
    for k, nom in (("Un píxel, 90°", "Pixel"), ("Matriz 8×8, 60°", "Ocho"), ("Matriz 32×32, 90°", "TreintaDos")):
        for c in ("30", "45", "60"):
            mac[f"sen{nom}{cortes[c]}"] = pct(res["sensor"][k]["p_det"][c])
    for k, nom in (("Pasiva", "Pasiva"), ("Unipolar sin dosificar", "SinLimite"), ("Unipolar dosificado", "Dosificado"),
                   ("Sin habituación, dosificado", "Bifasico")):
        r = res["habituacion"][k]
        mac[f"habCob{nom}"] = pct(r["cob_media"][-1])
        mac[f"habEst{nom}"] = f"{r['est_por_hora']:.0f}"
        mac[f"habResp{nom}"] = pct(1 - r["hab_fin"])
        mac[f"habDet{nom}"] = pct(r["cdf_min"][-1])
    sb = res["sensibilidad_base"]
    mac["sensBaseGuiada"] = pct(sb["Guiada"]["p45"])
    mac["sensBasePasiva"] = pct(sb["Pasiva"]["p45"])
    cortos = {"p_rodea": "Rodea", "k_refugio": "Refugio", "area_blanco": "Area", "p_resp": "Obedece",
              "frac_responde": "Responden", "t_pausa": "Pausa", "tasa_perdida": "Perdida", "pen_carga": "Carga",
              "v_natural": "Velocidad", "alfa_hab": "Habituacion", "k_foto": "Foto", "l_tramo": "Tramo"}
    for k, s in res["sensibilidad"].items():
        for nivel in ("bajo", "alto"):
            for p_ in ("Guiada", "Pasiva"):
                mac[f"sens{cortos[k]}{nivel.capitalize()}{p_}"] = pct(s[f"{nivel}_{p_}"]["p45"])
    a = res["alcances"]
    for k, nom in (("matriz32", "TreintaDos"), ("matriz8", "Ocho"), ("un_pixel", "Pixel")):
        mac[f"alcPre{nom}"] = f"{a[k][0]:.2f}"
        mac[f"alcDet{nom}"] = f"{a[k][1]:.2f}"

    if "por_mapa" in res:
        pm = res["por_mapa"]
        pas = [x["p60"] for x in pm["Pasiva"]]
        gui = [x["p60"] for x in pm["Guiada"]]
        mac["mapaMinPasiva"], mac["mapaMaxPasiva"] = pct(min(pas)), pct(max(pas))
        mac["mapaMinGuiada"], mac["mapaMaxGuiada"] = pct(min(gui)), pct(max(gui))
        mac["mapasGanaGuiada"] = str(sum(g > p_ + 0.05 for g, p_ in zip(gui, pas)))
        mac["mapasPierdeGuiada"] = str(sum(g < p_ - 0.05 for g, p_ in zip(gui, pas)))
        mac["mapasEmpate"] = str(sum(abs(g - p_) <= 0.05 for g, p_ in zip(gui, pas)))
        dif = [g - p_ for g, p_ in zip(gui, pas)]
        mejor, peor = int(np.argmax(dif)), int(np.argmin(dif))
        mac["mapaMejorPasiva"], mac["mapaMejorGuiada"] = pct(pas[mejor]), pct(gui[mejor])
        mac["mapaPeorPasiva"], mac["mapaPeorGuiada"] = pct(pas[peor]), pct(gui[peor])
        if "mixto" in res:
            mx = res["mixto"]
            mac["mixtoCuarentaCinco"], mac["mixtoSesenta"] = pct(mx["p_det"]["45"]), pct(mx["p_det"]["60"])
            mac["mixtoMejor"], mac["mixtoPeor"] = pct(mx["p60"][mejor]), pct(mx["p60"][peor])
            mac["mixtoMin"] = pct(min(mx["p60"]))

    # Filas de las tablas de resultados, como macros que se expanden dentro del tabular
    fin = " \\\\\n"
    tablas = {"tablaPoliticas": "", "tablaEnjambre": "", "tablaSensibilidad": "", "tablaRegreso": ""}
    if "regreso" in res:
        rg = res["regreso"]["casos"]
        casos_reg = [("Solo trampa", "Trampa", "Solo el refugio en la entrada"),
                     ("Mantenerlo caminando", "Andar", "Refugio y mantenerlo caminando"),
                     ("Rumbo directo", "Rumbo", "Rumbo a ciegas hacia la entrada"),
                     ("Ruta inversa", "Ruta", "Desandar la ruta guardada"),
                     ("Solo trampa, alcance 1 m", "TrampaMetro", "Refugio que atrae desde 1 m"),
                     ("Mantenerlo caminando, alcance 1 m", "AndarMetro", "Refugio de 1 m y mantenerlo caminando"),
                     ("Faro, alcanza 6 m de camino", "Faro", "Faro que alcanza 6 m de camino"),
                     ("Faro, 6 m y el doble de ruido", "FaroRuido", "Faro de 6 m con el doble de ruido"),
                     ("Faro de 6 m y trampa de 1 m", "FaroMetro", "Faro de 6 m y refugio de 1 m"),
                     ("Faro, sin límite de alcance", "FaroLibre", "Faro sin límite de alcance")]
        mac["regInsectos"] = f"{next(iter(rg.values()))['n']:,}".replace(",", "\\,")
        for k, nom, rotulo in casos_reg:
            if k not in rg:
                continue
            rec = rg[k]["recogidos"]
            mac[f"reg{nom}Treinta"], mac[f"reg{nom}Sesenta"] = pct(rec["30"]), pct(rec["60"])
            mac[f"reg{nom}Dos"] = pct(rec["120"])
            mac[f"reg{nom}Perdidos"] = pct(1 - rec["120"])
            mac[f"regEst{nom}"] = f"{rg[k]['estimulos']:.0f}"
            tablas["tablaRegreso"] += " & ".join([rotulo, pct(rec["30"]), pct(rec["60"]), pct(rec["120"]),
                                                  f"{rg[k]['estimulos']:.0f}"]) + fin
    for k in pol:
        r = res["politicas"][k]
        celdas = [k] + [pct(r["p_det"][c]) for c in cortes] + [f"{r['t_mediana'] / 60:.0f}", pct(r["cob_media"][-1]),
                                                                f"{r['est_por_hora']:.0f}", pct(r["frac_anda"])]
        tablas["tablaPoliticas"] += " & ".join(celdas) + fin
    for i, n in enumerate(e["n"]):
        celdas = [str(n)]
        for k in ("Pasiva", "Guiada"):
            celdas += [pct(e[k][i]["p_det"]["30"]), pct(e[k][i]["p_det"]["45"]), pct(e[k][i]["p_det"]["60"])]
        tablas["tablaEnjambre"] += " & ".join(celdas) + fin
    filas = sorted(res["sensibilidad"].items(),
                   key=lambda kv: -abs(kv[1]["alto_Guiada"]["p45"] - kv[1]["bajo_Guiada"]["p45"]))
    for k, s in filas:
        nom, lo, hi = SENS_NOMBRES[k]
        celdas = [nom, f"{lo} a {hi}", pct(s["bajo_Guiada"]["p45"]), pct(s["alto_Guiada"]["p45"]),
                  pct(s["bajo_Pasiva"]["p45"]), pct(s["alto_Pasiva"]["p45"])]
        tablas["tablaSensibilidad"] += " & ".join(celdas) + fin

    carpeta = os.path.join(AQUI, "..", "latex", "figs")
    with open(os.path.join(carpeta, "numeros.tex"), "w", encoding="utf-8") as f:
        f.write("% Generado por modelo/figuras.py a partir de modelo/resultados.json. No editar a mano.\n")
        for k, val in mac.items():
            f.write("\\newcommand{\\%s}{%s}\n" % (k, val))
        for k, val in tablas.items():
            f.write("\\newcommand{\\%s}{%%\n%s}\n" % (k, val))
    return mac


if __name__ == "__main__":
    pedir = sys.argv[1:] or list(FIGURAS) + ["numeros"]
    for nombre in pedir:
        try:
            if nombre == "numeros":
                print("numeros ->", len(numeros()), "macros")
            else:
                print(nombre, "->", os.path.relpath(E.guardar(FIGURAS[nombre](), nombre), AQUI))
        except FileNotFoundError as e:
            print(nombre, ": falta", e.filename)
