"""Ilustración vectorial de Gromphadorhina portentosa con la mochila (vista dorsal y lateral).

Dibujo esquemático propio, a escala en milímetros. No es una fotografía.
"""
import numpy as np
from matplotlib.patches import Polygon, Ellipse, FancyBboxPatch, Circle, Rectangle
from matplotlib.path import Path
from matplotlib.patches import PathPatch

import estilo as E

L = 60.0          # largo del cuerpo, mm
W = 12.8          # semiancho máximo, mm


def semiancho(u):
    """Perfil dorsal: u=0 en el extremo posterior, u=1 en el frente del pronoto."""
    u = np.clip(u, 0, 1)
    return W * np.sin(np.pi * u ** 0.9) ** 0.42 * (1 + 0.15 * (0.45 - u))


def xu(u):
    return -L / 2 + L * np.asarray(u)


# límites de los segmentos (de atrás hacia adelante)
TERGITOS = [0.0, 0.06, 0.135, 0.215, 0.30, 0.39, 0.48, 0.57]
META, MESO, PRO = (0.57, 0.66), (0.66, 0.76), (0.76, 1.0)


def _banda(ua, ub, n=40, comba=0.7):
    """Polígono del segmento entre ua (posterior) y ub (anterior)."""
    us = np.linspace(ua, ub, n)
    sup = np.c_[xu(us), semiancho(us)]
    inf = np.c_[xu(us[::-1]), -semiancho(us[::-1])]
    wa = semiancho(ua)
    ys = np.linspace(-wa, wa, 15)
    borde = np.c_[xu(ua) - comba * (1 - (ys / max(wa, 1e-6)) ** 2), ys]
    return np.vstack([borde, sup, inf])


def _mezcla(c1, c2, t):
    a = np.array([int(c1[i:i + 2], 16) for i in (1, 3, 5)])
    b = np.array([int(c2[i:i + 2], 16) for i in (1, 3, 5)])
    c = (a + (b - a) * t).astype(int)
    return "#%02x%02x%02x" % tuple(c)


def _curva(ax, p0, p1, p2, lw0, lw1, color, z, n=40):
    """Bézier cuadrática con grosor que se afina."""
    t = np.linspace(0, 1, n)[:, None]
    pts = (1 - t) ** 2 * np.array(p0) + 2 * (1 - t) * t * np.array(p1) + t ** 2 * np.array(p2)
    for i in range(n - 1):
        ax.plot(pts[i:i + 2, 0], pts[i:i + 2, 1], color=color, lw=lw0 + (lw1 - lw0) * i / (n - 1),
                solid_capstyle="round", zorder=z)
    return pts


def _pata(ax, pts, lado, z=2):
    """pts: base, rodilla, tobillo, punta (para y>0); lado=+1/-1 refleja."""
    p = np.array(pts, float)
    p[:, 1] *= lado
    oscuro, medio = "#2A1810", "#4A2A18"
    ax.plot(p[0:2, 0], p[0:2, 1], color=oscuro, lw=13, solid_capstyle="round", zorder=z)
    ax.plot(p[0:2, 0], p[0:2, 1], color=medio, lw=8, solid_capstyle="round", zorder=z)
    ax.plot(p[1:3, 0], p[1:3, 1], color=oscuro, lw=7.5, solid_capstyle="round", zorder=z)
    ax.plot(p[2:4, 0], p[2:4, 1], color=oscuro, lw=3.4, solid_capstyle="round", zorder=z)
    # espinas de la tibia
    d = p[2] - p[1]
    n = np.array([-d[1], d[0]]) / np.hypot(*d)
    for s in np.linspace(0.2, 0.9, 5):
        b = p[1] + d * s
        for sg in (-1, 1):
            ax.plot([b[0], b[0] + sg * n[0] * 1.5 + d[0] * 0.04],
                    [b[1], b[1] + sg * n[1] * 1.5 + d[1] * 0.04], color=oscuro, lw=1.3, zorder=z)


def insecto_dorsal(ax, mochila=True, electrodos=True, leds=True):
    """Dibuja el insecto con la cabeza hacia +x. Devuelve puntos de anclaje para rotular."""
    anc = {}
    # patas (debajo del cuerpo)
    for lado in (1, -1):
        _pata(ax, [(20, 7.5), (25.5, 14.5), (32.0, 17.5), (36.5, 19.5)], lado)
        _pata(ax, [(10, 10), (7.5, 19.0), (2.0, 25.0), (-1.5, 28.5)], lado)
        _pata(ax, [(3, 10), (-6.0, 18.5), (-19.0, 24.5), (-26.0, 27.5)], lado)
    anc["pata"] = (-19.0, -24.5)

    # cercos
    for lado in (1, -1):
        ax.add_patch(Polygon([(-29.0, lado * 2.4), (-32.6, lado * 4.9), (-29.2, lado * 4.6)],
                             closed=True, fc="#3A2114", ec="#1A0F0A", lw=1.2, zorder=3))
    anc["cerco"] = (-32.0, 4.6)

    # antenas
    for lado in (1, -1):
        _curva(ax, (28.5, lado * 2.6), (44, lado * 6), (63, lado * 23), 2.6, 0.8, "#2A1810", 3)
    anc["antena"] = (52, 13.5)
    # cabeza asomando bajo el pronoto
    ax.add_patch(Ellipse((29.0, 0), 4.6, 8.4, fc="#1C110B", ec="#0E0805", lw=1.0, zorder=3))

    # abdomen: de atrás hacia adelante para que cada tergito tape al siguiente
    for i in range(len(TERGITOS) - 1):
        ua, ub = TERGITOS[i], TERGITOS[i + 1]
        t = i / (len(TERGITOS) - 2)
        base = _mezcla("#3A2114", "#7A4322", t)
        ax.add_patch(Polygon(_banda(ua, ub), closed=True, fc=base, ec="#1A0F0A", lw=1.6,
                             joinstyle="round", zorder=4 + i))
        # brillo central y franja oscura posterior
        um = (ua + ub) / 2
        ax.add_patch(Ellipse((xu(um) + 0.4, 0), L * (ub - ua) * 0.55, semiancho(um) * 1.25,
                             fc="#D49A5A", ec="none", alpha=0.16, zorder=4 + i))
    anc["abdomen"] = (xu(0.26), -semiancho(0.26) * 0.55)

    # tórax
    z = 12
    for (ua, ub), col in ((META, "#4A2917"), (MESO, "#3C2114")):
        ax.add_patch(Polygon(_banda(ua, ub, comba=0.5), closed=True, fc=col, ec="#140B07", lw=1.6,
                             joinstyle="round", zorder=z))
        z += 1
    # pronoto con las dos protuberancias del macho
    ax.add_patch(Polygon(_banda(*PRO, comba=0.9), closed=True, fc="#24150E", ec="#0E0805", lw=1.8,
                         joinstyle="round", zorder=z))
    ax.add_patch(Ellipse((21.5, 0), 9.5, 13.5, fc="#5A3A28", ec="none", alpha=0.25, zorder=z + 1))
    for lado in (1, -1):
        ax.add_patch(Ellipse((24.3, lado * 3.6), 4.6, 4.2, fc="#3A2418", ec="#0E0805", lw=1.0, zorder=z + 1))
        ax.add_patch(Ellipse((24.8, lado * 3.9), 1.8, 1.4, fc="#8A6A55", ec="none", alpha=0.55, zorder=z + 2))
    anc["pronoto"] = (26.5, -6.8)
    # brillo longitudinal
    ax.add_patch(Ellipse((-4, 2.2), 42, 2.0, fc="white", ec="none", alpha=0.07, zorder=z + 2))

    if not mochila:
        return anc
    z = 30
    # batería bajo la placa (asoma hacia atrás)
    ax.add_patch(FancyBboxPatch((-1.5, -5.5), 15.5, 11, boxstyle="round,pad=0,rounding_size=1.4",
                                fc="#C9CED4", ec="#7B848D", lw=1.3, zorder=z))
    ax.add_patch(Rectangle((-1.5, -1.6), 2.2, 3.2, fc="#E0B64A", ec="#7B848D", lw=0.8, zorder=z))
    anc["bateria"] = (0.2, 4.2)
    # placa
    ax.add_patch(FancyBboxPatch((4.0, -7.2), 19.0, 14.4, boxstyle="round,pad=0,rounding_size=1.6",
                                fc="#12463C", ec="#0A2A24", lw=1.6, zorder=z + 1))
    anc["placa"] = (13.0, 7.2)
    # pistas
    for yy in (-4.6, -3.4, 3.4, 4.6):
        ax.plot([6.2, 12.0], [yy, yy], color="#2E7D6B", lw=1.0, zorder=z + 2)
    # FPGA / ASIC
    ax.add_patch(FancyBboxPatch((9.4, -2.6), 5.2, 5.2, boxstyle="round,pad=0,rounding_size=0.4",
                                fc="#15181C", ec="#555E68", lw=1.0, zorder=z + 3))
    ax.add_patch(Circle((10.2, 1.8), 0.32, fc="#8A929B", ec="none", zorder=z + 4))
    for k in np.linspace(-2.0, 2.0, 5):
        for xx in (9.0, 15.0):
            ax.plot([xx, xx + (0.4 if xx < 12 else -0.4)], [k, k], color="#C9CED4", lw=1.1, zorder=z + 3)
    anc["chip"] = (12.0, -2.6)
    # radio y antena en meandro
    ax.add_patch(Rectangle((5.4, -1.5), 2.6, 3.0, fc="#2B3138", ec="#555E68", lw=0.8, zorder=z + 3))
    mx = np.array([5.0, 5.0, 6.4, 6.4, 7.8, 7.8, 9.2, 9.2])
    my = np.array([4.0, 6.2, 6.2, 4.6, 4.6, 6.2, 6.2, 4.0])
    ax.plot(mx, my, color="#E0B64A", lw=1.4, zorder=z + 3)
    anc["radio"] = (6.4, 6.2)
    # IMU
    ax.add_patch(Rectangle((16.4, 3.0), 2.4, 2.4, fc="#2B3138", ec="#555E68", lw=0.8, zorder=z + 3))
    # sensor térmico al frente
    ax.add_patch(FancyBboxPatch((18.6, -3.6), 5.6, 5.4, boxstyle="round,pad=0,rounding_size=0.6",
                                fc="#D8DCE1", ec="#6B747D", lw=1.2, zorder=z + 3))
    ax.add_patch(Rectangle((22.6, -2.5), 1.6, 3.2, fc="#3B1E5E", ec="#22123A", lw=0.8, zorder=z + 4))
    anc["sensor"] = (21.4, -3.6)
    # cono del campo de visión
    ax.add_patch(Polygon([(24.2, -0.9), (58, -16), (58, 14)], closed=True, fc=E.AMBAR, ec="none",
                         alpha=0.10, zorder=1))
    anc["fov"] = (50, -9.5)

    if leds:
        for lado in (1, -1):
            ax.plot([22.5, 28.2], [lado * 6.6, lado * 7.6], color="#0A2A24", lw=2.0, zorder=z + 2)
            ax.add_patch(Circle((28.8, lado * 7.7), 1.15, fc="#7BE06A", ec="#1E6B2A", lw=1.0, zorder=z + 4))
            ax.add_patch(Circle((28.8, lado * 7.7), 2.6, fc="#7BE06A", ec="none", alpha=0.22, zorder=z + 3))
        anc["led"] = (28.8, 7.7)
    if electrodos:
        for lado in (1, -1):
            # hacia la base de la antena
            _curva(ax, (22.8, lado * 5.6), (27.5, lado * 5.4), (30.2, lado * 3.0), 1.3, 1.3, E.AMBAR, z + 2, n=12)
            ax.add_patch(Circle((30.4, lado * 2.9), 0.75, fc=E.AMBAR, ec="#7A4D08", lw=0.8, zorder=z + 4))
            # hacia el cerco
            _curva(ax, (4.2, lado * 6.0), (-14, lado * 8.5), (-29.6, lado * 4.0), 1.3, 1.3, E.AMBAR, z + 2, n=24)
            ax.add_patch(Circle((-30.0, lado * 3.8), 0.75, fc=E.AMBAR, ec="#7A4D08", lw=0.8, zorder=z + 4))
        anc["e_antena"] = (30.4, 2.9)
        anc["e_cerco"] = (-16.0, 6.6)
    return anc


def rotulo(ax, xy, xytext, texto, ha="left", va="center", color=E.TINTA, peso="normal", tam=None):
    ax.annotate(texto, xy=xy, xytext=xytext, ha=ha, va=va, color=color, fontweight=peso,
                fontsize=tam, zorder=60, linespacing=1.15,
                bbox=dict(boxstyle="square,pad=0.15", fc="none", ec="none"),   # corta la guía en el borde del texto
                arrowprops=dict(arrowstyle="-", color=E.GRIS, lw=1.4, shrinkA=4, shrinkB=2,
                                connectionstyle="arc3,rad=0"))
    ax.add_patch(Circle(xy, 0.55, fc="white", ec=E.GRIS, lw=1.2, zorder=61))


def escala(ax, x0, y0, largo=10, texto="10 mm"):
    ax.plot([x0, x0 + largo], [y0, y0], color=E.TINTA, lw=3, solid_capstyle="butt", zorder=50)
    for xx in (x0, x0 + largo):
        ax.plot([xx, xx], [y0 - 0.8, y0 + 0.8], color=E.TINTA, lw=2, zorder=50)
    ax.text(x0 + largo / 2, y0 - 1.6, texto, ha="center", va="top", fontsize=15)


def insecto_lateral(ax, alto=13.0, despeje=3.5, pila=(("adhesivo", 0.4, "#E0B64A"), ("batería", 3.6, "#C9CED4"),
                                                      ("placa", 0.8, "#12463C"), ("sensor", 4.3, "#D8DCE1"))):
    """Vista lateral con la mochila apilada sobre el tórax. Devuelve cotas (mm)."""
    us = np.linspace(0, 1, 120)
    lomo = despeje + alto * np.sin(np.pi * us ** 0.85) ** 0.55 * (1 - 0.12 * (us - 0.5))
    panza = despeje + 1.6 * np.sin(np.pi * us) ** 0.5 * 0 + 0.0 * us
    xs = xu(us)
    # patas
    for xb, xp in ((18, 26), (8, 4), (0, -12)):
        ax.plot([xb, (xb + xp) / 2 + 2, xp], [despeje + 2.5, despeje + 5.5, 0.2], color="#2A1810", lw=5,
                solid_capstyle="round", solid_joinstyle="round", zorder=2)
    # cuerpo
    cuerpo = np.vstack([np.c_[xs, lomo], np.c_[xs[::-1], panza[::-1]]])
    ax.add_patch(Polygon(cuerpo, closed=True, fc="#4A2917", ec="#140B07", lw=1.8, zorder=3))
    for u in TERGITOS[1:] + [META[1], MESO[1]]:
        k = np.argmin(np.abs(us - u))
        ax.plot([xs[k] - 1.2, xs[k]], [despeje + 0.3, lomo[k]], color="#140B07", lw=1.3, zorder=4)
    kp = us >= PRO[0]
    ax.add_patch(Polygon(np.vstack([np.c_[xs[kp], lomo[kp]], [[xs[-1], despeje]], [[xs[kp][0], despeje]]]),
                         closed=True, fc="#24150E", ec="#0E0805", lw=1.6, zorder=4))
    _curva(ax, (29.5, despeje + 2.5), (42, despeje + 9), (58, despeje + 3), 2.2, 0.8, "#2A1810", 3)
    # pila de la mochila sobre el tórax (u de 0.57 a 0.92)
    x0, x1 = xu(0.57), xu(0.90)
    base = float(np.interp(0.74, us, lomo)) - 0.6
    y = base
    cotas = {"cuerpo": float(lomo.max()), "base": base}
    for nombre, esp, col in pila:
        if nombre == "sensor":
            ax.add_patch(Rectangle((x1 - 6.2, y), 6.2, esp, fc=col, ec="#6B747D", lw=1.2, zorder=6))
            ax.add_patch(Rectangle((x1 - 0.9, y + 0.7), 0.9, esp - 1.4, fc="#3B1E5E", ec="none", zorder=7))
            ax.add_patch(Rectangle((x0 + 4.5, y), 4.2, 1.1, fc="#15181C", ec="#555E68", lw=0.8, zorder=6))
            cotas["sensor"] = (x1 - 3.1, y + esp)
        else:
            xi = x0 + (1.5 if nombre == "batería" else 0)
            xf = x1 - (3.0 if nombre == "batería" else 0)
            ax.add_patch(Rectangle((xi, y), xf - xi, esp, fc=col, ec="#3A4047", lw=1.0, zorder=6))
            cotas[nombre] = ((xi + xf) / 2, y + esp / 2)
        y += esp
    cotas["tope"] = y
    return cotas


def cota(ax, x, y0, y1, texto, lado=1, tam=15, color=None):
    color = color or E.AZUL_OSC
    ax.annotate("", xy=(x, y0), xytext=(x, y1), arrowprops=dict(arrowstyle="<->", color=color, lw=1.8,
                                                              shrinkA=0, shrinkB=0), zorder=40)
    ax.text(x + lado * 1.2, (y0 + y1) / 2, texto, ha="left" if lado > 0 else "right", va="center",
            fontsize=tam, color=color, fontweight="bold", zorder=41)
