"""Diagramas de bloques del proyecto (matplotlib): marco del modelo, máquina de estados
de la política, núcleo digital, sistema completo y cronograma."""
import numpy as np
import matplotlib.pyplot as plt
from matplotlib.patches import FancyBboxPatch, FancyArrowPatch, Circle, Rectangle, Ellipse

import estilo as E


def lienzo(w, h, ancho_px=1664, alto_px=640):
    fig = plt.figure(figsize=(ancho_px / 100, alto_px / 100))
    ax = fig.add_axes([0, 0, 1, 1])
    ax.set_xlim(0, w)
    ax.set_ylim(0, h)
    ax.axis("off")
    return fig, ax


def caja(ax, x, y, w, h, titulo, cuerpo="", fc="#ECF3FA", ec=E.AZUL_OSC, tam=17, tam2=14,
         color=E.TINTA, r=0.18, lw=2.0, z=3, peso="bold", mono=False):
    ax.add_patch(FancyBboxPatch((x, y), w, h, boxstyle=f"round,pad=0,rounding_size={r}",
                                fc=fc, ec=ec, lw=lw, zorder=z))
    fam = {"family": "Consolas"} if mono else {}
    if cuerpo:
        ax.text(x + w / 2, y + h * 0.66, titulo, ha="center", va="center", fontsize=tam,
                fontweight=peso, color=color, zorder=z + 1, **fam)
        ax.text(x + w / 2, y + h * 0.27, cuerpo, ha="center", va="center", fontsize=tam2,
                color=color, zorder=z + 1, linespacing=1.2)
    else:
        ax.text(x + w / 2, y + h / 2, titulo, ha="center", va="center", fontsize=tam,
                fontweight=peso, color=color, zorder=z + 1, linespacing=1.2, **fam)
    return (x, y, w, h)


def flecha(ax, p0, p1, color=E.AZUL_OSC, lw=2.4, rad=0.0, estilo="-|>", z=2, ls="-"):
    ax.add_patch(FancyArrowPatch(p0, p1, arrowstyle=estilo, mutation_scale=22, lw=lw, color=color,
                                 connectionstyle=f"arc3,rad={rad}", zorder=z, linestyle=ls,
                                 shrinkA=0, shrinkB=0))


def etiqueta(ax, x, y, texto, tam=14, color=E.GRIS, ha="center", va="center", fondo=None, peso="normal"):
    kw = {}
    if fondo:
        kw["bbox"] = dict(boxstyle="round,pad=0.18", fc=fondo, ec="none")
    ax.text(x, y, texto, ha=ha, va=va, fontsize=tam, color=color, zorder=6, fontweight=peso,
            linespacing=1.15, **kw)


# ------------------------------------------------------------------ marco del modelo
def marco_modelo(datos: dict):
    """Cinco submodelos encadenados y la capa ética que los acota."""
    fig, ax = lienzo(16.64, 5.8, 1664, 580)
    cols = [(E.AZUL_OSC, "#E4EDF6"), (E.AZUL, "#E7F1F9"), (E.VERDE, "#E4F3EF"),
            (E.AMBAR, "#FBF0DC"), ("#6B5B95", "#EFEBF6")]
    w, h, gap = 2.92, 3.75, 0.31
    x0, y0 = 0.15, 1.85
    for i, clave in enumerate(("M1", "M2", "M3", "M4", "M5")):
        tit, cuerpo, sale = datos[clave]
        ec, fc = cols[i]
        x = x0 + i * (w + gap)
        ax.add_patch(FancyBboxPatch((x, y0), w, h, boxstyle="round,pad=0,rounding_size=0.16",
                                    fc=fc, ec=ec, lw=2.4, zorder=3))
        ax.add_patch(Rectangle((x + 0.03, y0 + h - 0.8), w - 0.06, 0.74, fc=ec, ec="none", zorder=4))
        ax.text(x + 0.2, y0 + h - 0.43, clave, ha="left", va="center", fontsize=20, fontweight="bold",
                color="white", zorder=5)
        ax.text(x + w - 0.18, y0 + h - 0.43, tit, ha="right", va="center", fontsize=18,
                fontweight="bold", color="white", zorder=5)
        ax.text(x + 0.2, y0 + h - 1.05, cuerpo, ha="left", va="top", fontsize=16.5, color=E.TINTA,
                zorder=5, linespacing=1.32)
        ax.text(x + w / 2, y0 + 0.24, sale, ha="center", va="bottom", fontsize=16.5, fontweight="bold",
                color=ec, zorder=5, linespacing=1.2)
        if i < 4:
            flecha(ax, (x + w + 0.03, y0 + h / 2), (x + w + gap - 0.03, y0 + h / 2), color=E.GRIS, lw=3)
    ax.add_patch(FancyBboxPatch((x0, 0.2), 5 * w + 4 * gap, 1.15, boxstyle="round,pad=0,rounding_size=0.16",
                                fc="#FFF7E8", ec=E.ROJO, lw=2.2, zorder=3, linestyle=(0, (6, 3))))
    ax.text(x0 + 0.25, 0.775, datos["E"][0], ha="left", va="center", fontsize=18, fontweight="bold",
            color=E.ROJO, zorder=5)
    ax.text(x0 + 3.5, 0.775, datos["E"][1], ha="left", va="center", fontsize=16.5, color=E.TINTA, zorder=5,
            linespacing=1.25)
    for i in range(5):
        xc = x0 + i * (w + gap) + w / 2
        flecha(ax, (xc, 1.37), (xc, y0 - 0.03), color=E.ROJO, lw=1.8, ls=(0, (4, 3)))
    return fig


# ---------------------------------------------------------------- máquina de estados
def fsm_politica(par: dict):
    """Política de estímulos a bordo. par: subtítulos y textos de las transiciones."""
    fig, ax = lienzo(11.6, 6.6, 1160, 660)
    W, H = 2.7, 1.05
    c1, c2, c3 = 0.3, 4.45, 8.6            # columnas
    r1, r2, r3 = 5.2, 2.78, 0.35           # filas; EXPLORAR queda al centro
    est = {
        "REPOSO": (c1, r1, "#EEF1F4", E.GRIS),
        "REORIENTAR": (c2, r1, "#FBF0DC", E.AMBAR),
        "DESCANSO": (c3, r1, "#EEF1F4", E.GRIS),
        "REACTIVAR": (c1, r2, "#FBF0DC", E.AMBAR),
        "EXPLORAR": (c2, r2, "#E4EDF6", E.AZUL_OSC),
        "ACERCAR": (c3, r2, "#E4F3EF", E.VERDE),
        "ALERTAR": (c2, r3, "#F6E3DE", E.ROJO),
        "CONFIRMAR": (c3, r3, "#E4F3EF", E.VERDE),
    }
    for n, (x, y, fc, ec) in est.items():
        caja(ax, x, y, W, H, n, par["sub"].get(n, ""), fc=fc, ec=ec, tam=17, tam2=14, r=0.3,
             lw=3.2 if n == "EXPLORAR" else 2.4)
    t = par["trans"]
    T = 14
    gris = dict(color=E.GRIS, ls=(0, (5, 3)))
    # arranque
    flecha(ax, (c1 + W, r1 + 0.2), (c2 + 0.25, r2 + H))
    etiqueta(ax, 3.3, 4.55, t["inicio"], tam=T, ha="right")
    # explorar <-> reorientar
    flecha(ax, (c2 + 0.95, r2 + H), (c2 + 0.95, r1))
    etiqueta(ax, c2 + 0.82, 4.52, t["giro"], tam=T, ha="right")
    flecha(ax, (c2 + 1.75, r1), (c2 + 1.75, r2 + H))
    etiqueta(ax, c2 + 1.88, 4.3, t["hecho"], tam=T, ha="left")
    # explorar <-> reactivar
    flecha(ax, (c2, r2 + 0.75), (c1 + W, r2 + 0.75))
    etiqueta(ax, 3.72, r2 + 0.85, t["quieto"], tam=T, va="bottom")
    flecha(ax, (c1 + W, r2 + 0.3), (c2, r2 + 0.3))
    etiqueta(ax, 3.72, r2 + 0.2, t["anda"], tam=T, va="top")
    # explorar <-> acercar
    flecha(ax, (c2 + W, r2 + 0.75), (c3, r2 + 0.75))
    etiqueta(ax, 7.87, r2 + 0.85, t["pre"], tam=T, va="bottom")
    flecha(ax, (c3, r2 + 0.3), (c2 + W, r2 + 0.3))
    etiqueta(ax, 7.87, r2 + 0.2, t["pierde"], tam=T, va="top")
    # explorar <-> descanso: presupuesto de estímulos
    flecha(ax, (c2 + W - 0.2, r2 + H), (c3 + 0.2, r1), estilo="<|-|>", **gris)
    etiqueta(ax, 8.2, 4.3, t["fallos"], tam=T, ha="left")
    # descanso -> acercar
    flecha(ax, (c3 + 1.9, r1), (c3 + 1.9, r2 + H), **gris)
    etiqueta(ax, c3 + 2.03, 4.52, t["descanso"], tam=T, ha="left")
    # acercar <-> confirmar -> alertar
    flecha(ax, (c3 + 0.95, r2), (c3 + 0.95, r3 + H))
    etiqueta(ax, c3 + 0.82, 2.1, t["umbral"], tam=T, ha="right")
    flecha(ax, (c3 + 1.75, r3 + H), (c3 + 1.75, r2), **gris)
    etiqueta(ax, c3 + 1.88, 2.1, t["falso"], tam=T, ha="left")
    flecha(ax, (c3, r3 + H / 2), (c2 + W, r3 + H / 2))
    etiqueta(ax, 7.87, r3 + H / 2 + 0.12, t["conf"], tam=T, va="bottom")
    # nota del presupuesto
    ax.add_patch(FancyBboxPatch((c1, r3 - 0.05), W + 0.95, H + 0.5, boxstyle="round,pad=0,rounding_size=0.15",
                                fc="#FFF7E8", ec=E.ROJO, lw=1.8, linestyle=(0, (5, 3)), zorder=2))
    ax.text(c1 + 0.18, r3 + H + 0.22, par["nota_t"], ha="left", va="center", fontsize=14.5, fontweight="bold",
            color=E.ROJO, zorder=5)
    ax.text(c1 + 0.18, r3 + 0.55, par["nota"], ha="left", va="center", fontsize=13.5, color=E.TINTA, zorder=5,
            linespacing=1.25)
    return fig


# ------------------------------------------------------------------- núcleo digital
def nucleo_digital(mod: dict):
    """Módulos Verilog del prototipo y sus conexiones. mod: nombre -> subtítulo."""
    fig, ax = lienzo(16.64, 6.4)
    ext = dict(fc="#FBF0DC", ec=E.AMBAR)
    enl = dict(fc="#EEF1F4", ec=E.GRIS)
    nuc = dict(fc="#ECF3FA", ec=E.AZUL_OSC)
    k = dict(tam=15.5, tam2=13.5)
    # frontera del núcleo
    ax.add_patch(FancyBboxPatch((5.55, 0.25), 7.95, 5.95, boxstyle="round,pad=0,rounding_size=0.2",
                                fc="#FAFBFC", ec=E.AZUL, lw=2.2, linestyle=(0, (7, 4)), zorder=1))
    etiqueta(ax, 13.35, 5.95, mod["marco"], tam=15, color=E.AZUL, ha="right", peso="bold")
    # entrada
    caja(ax, 0.2, 4.45, 2.2, 1.25, "ESP32", mod["esp_in"], **ext, **k)
    caja(ax, 2.95, 4.45, 2.2, 1.25, "uart_rx", mod["rx"], mono=True, **enl, **k)
    caja(ax, 2.95, 2.55, 2.2, 1.25, "receptor_trama", mod["trama"], mono=True, **enl, tam=14.5, tam2=13.5)
    # núcleo
    caja(ax, 5.85, 4.45, 2.3, 1.25, "ventana_termica", mod["ventana"], mono=True, **nuc, tam=14.5, tam2=13.5)
    caja(ax, 8.45, 4.45, 2.1, 1.25, "media_movil4", mod["media"], mono=True, **nuc, tam=14.5, tam2=13.5)
    caja(ax, 10.85, 4.45, 2.4, 1.25, "detector_presencia", mod["presencia"], mono=True, **nuc, tam=13.5, tam2=13.5)
    caja(ax, 5.85, 2.55, 2.3, 1.25, "detector_quietud", mod["quietud"], mono=True, **nuc, tam=14, tam2=13.5)
    caja(ax, 5.85, 0.65, 2.3, 1.25, "lfsr16", mod["lfsr"], mono=True, **nuc, **k)
    caja(ax, 8.9, 2.3, 2.5, 1.6, "fsm_politica", mod["fsm"], mono=True, fc="#E4EDF6", ec=E.AZUL_OSC, lw=3.0, tam=16.5, tam2=14)
    caja(ax, 10.85, 0.5, 2.4, 1.25, "gen_estimulo", mod["gen"], mono=True, **nuc, **k)
    # salida
    caja(ax, 14.0, 4.45, 2.4, 1.25, "ESP32", mod["esp_out"], **ext, **k)
    caja(ax, 14.0, 2.55, 2.4, 1.25, "emisor_estado", mod["emisor"], mono=True, **enl, tam=14.5, tam2=13.5)
    caja(ax, 14.0, 0.5, 2.4, 1.25, "Estímulo", mod["sal"], **ext, **k)
    f = lambda a, b, **kw: flecha(ax, a, b, **kw)
    f((2.4, 5.07), (2.95, 5.07))
    f((4.05, 4.45), (4.05, 3.8))
    f((5.15, 3.45), (5.85, 4.75))                 # píxeles -> ventana
    f((5.15, 3.17), (5.85, 3.17))                 # actividad -> quietud
    f((8.15, 5.07), (8.45, 5.07))
    f((10.55, 5.07), (10.85, 5.07))
    f((12.05, 4.45), (11.0, 3.9))                 # presencia -> fsm
    f((8.15, 3.17), (8.9, 3.17))                  # quietud -> fsm
    f((8.15, 1.4), (9.2, 2.3))                    # lfsr -> fsm
    f((8.6, 4.45), (9.6, 3.9), color=E.GRIS, ls=(0, (4, 3)))   # lado: ventana -> fsm
    f((10.9, 2.3), (11.7, 1.75))                  # fsm -> gen
    f((11.4, 3.17), (14.0, 3.17))                 # fsm -> emisor
    f((15.2, 3.8), (15.2, 4.45))                  # emisor -> esp32 (por uart_tx)
    f((13.25, 1.12), (14.0, 1.12))                # gen -> estímulo
    etiqueta(ax, 15.42, 4.12, "uart_tx", tam=13, ha="left")
    return fig


# --------------------------------------------------------------- sistema completo
def sistema(tx: dict):
    """Del enjambre a la estación del rescatista."""
    fig, ax = lienzo(16.64, 6.0, 1664, 600)
    rng = np.random.default_rng(4)
    ax.add_patch(Rectangle((0.2, 0.4), 6.6, 5.2, fc="#EDEAE3", ec=E.GRIS, lw=1.6, zorder=1))
    for _ in range(26):
        x, y = rng.uniform(0.4, 5.6), rng.uniform(0.6, 4.6)
        w, h = (rng.uniform(0.5, 1.6), rng.uniform(0.14, 0.34)) if rng.random() < 0.6 else (rng.uniform(0.14, 0.34), rng.uniform(0.4, 1.2))
        ax.add_patch(Rectangle((x, y), w, h, angle=rng.uniform(-18, 18), fc="#B9B3A7", ec="#7F786C", lw=1.1, zorder=2))
    ax.add_patch(Circle((5.45, 1.9), 0.4, fc="#E5A08A", ec=E.ROJO, lw=2.2, zorder=4))
    for rr in (0.62, 0.86, 1.1):
        ax.add_patch(Circle((5.45, 1.9), rr, fc="none", ec=E.ROJO, lw=1.4, alpha=0.6, linestyle=(0, (3, 3)), zorder=3))
    etiqueta(ax, 5.45, 0.66, tx["victima"], tam=15.5, color=E.ROJO, peso="bold")
    pts = [(1.3, 4.3), (2.5, 2.9), (3.6, 4.5), (4.2, 2.45), (1.6, 1.5), (4.9, 3.75)]
    for x, y in pts:
        ax.add_patch(Ellipse((x, y), 0.5, 0.24, fc="#4A2917", ec="#1A0F0A", lw=1.0, zorder=5))
        ax.add_patch(Rectangle((x - 0.07, y - 0.07), 0.2, 0.14, fc="#12463C", ec="none", zorder=6))
    for a, b in ((0, 2), (2, 5), (1, 3), (1, 4), (0, 1), (3, 5)):
        ax.plot([pts[a][0], pts[b][0]], [pts[a][1], pts[b][1]], color=E.AZUL, lw=1.4, ls=(0, (2, 3)), zorder=4)
    flecha(ax, (4.35, 2.4), (5.06, 2.05), color=E.AMBAR, lw=2.8)
    etiqueta(ax, 3.5, 5.25, tx["enjambre"], tam=16.5, color=E.AZUL_OSC, peso="bold", fondo="#EDEAE3")
    k = dict(tam=17.5, tam2=15)
    caja(ax, 7.6, 3.35, 3.1, 1.75, tx["relevo_t"], tx["relevo"], fc="#E7F1F9", ec=E.AZUL, **k)
    caja(ax, 11.6, 3.35, 4.8, 1.75, tx["base_t"], tx["base"], fc="#E4EDF6", ec=E.AZUL_OSC, **k)
    caja(ax, 7.6, 0.75, 3.1, 1.75, tx["mochila_t"], tx["mochila"], fc="#E4F3EF", ec=E.VERDE, **k)
    caja(ax, 11.6, 0.75, 4.8, 1.75, tx["salida_t"], tx["salida"], fc="#FBF0DC", ec=E.AMBAR, **k)
    flecha(ax, (6.8, 4.22), (7.6, 4.22), color=E.AZUL, lw=2.8)
    flecha(ax, (10.7, 4.22), (11.6, 4.22), color=E.AZUL, lw=2.8)
    flecha(ax, (14.0, 3.35), (14.0, 2.5), color=E.AZUL_OSC, lw=2.8)
    flecha(ax, (6.8, 1.62), (7.6, 1.62), color=E.VERDE, lw=2.2, estilo="-")
    etiqueta(ax, 7.2, 4.55, tx["enlace1"], tam=14)
    etiqueta(ax, 11.15, 4.55, tx["enlace2"], tam=14)
    return fig


# ----------------------------------------------------------------------- cronograma
def cronograma(fases: list, hitos: list, dia0: int = 9, dias: int = 24):
    """fases: (nombre, inicio, fin, color) en días de noviembre; hitos: (día, texto)."""
    fig = plt.figure(figsize=(16.64, 5.6))
    ax = fig.add_axes([0.275, 0.17, 0.71, 0.72])
    n = len(fases)
    for i, (nom, a, b, col) in enumerate(fases):
        ax.barh(n - 1 - i, b - a + 1, left=a - 0.5, height=0.56, color=col, edgecolor="none", zorder=3)
    ax.set_yticks(range(n))
    ax.set_yticklabels([f[0] for f in fases][::-1], fontsize=17.5)
    dias_l = list(range(dia0, dia0 + dias))
    ax.set_xlim(dia0 - 0.5, dia0 + dias - 0.5)
    ax.set_ylim(-0.6, n - 0.4)
    ax.set_xticks(dias_l)
    ax.set_xticklabels([str(d) if d <= 30 else str(d - 30) for d in dias_l], fontsize=15)
    ax.grid(axis="y", visible=False)
    ax.spines["left"].set_visible(False)
    ax.tick_params(axis="y", length=0)
    for d, txt in hitos:
        ax.axvline(d, color=E.ROJO, lw=2.2, ls=(0, (5, 3)), zorder=2)
        ax.text(d, n - 0.3, txt, ha="center", va="bottom", fontsize=16.5, color=E.ROJO, fontweight="bold")
    ax.axvline(30.5, color=E.GRIS, lw=1.2)
    ax.text((dia0 + 30) / 2, -1.5, "noviembre", ha="center", fontsize=16.5, color=E.GRIS)
    ax.text(30.5 + (dia0 + dias - 31) / 2, -1.5, "dic.", ha="center", fontsize=16.5, color=E.GRIS)
    return fig
