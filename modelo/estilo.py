"""Estilo común de las figuras (reporte y presentación)."""
import os

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib import font_manager

AZUL_OSC = "#0E2A47"
AZUL = "#1D6FA5"
AMBAR = "#D98B12"
VERDE = "#1F7A6C"
ROJO = "#B5452F"
GRIS = "#5B6770"
GRIS_CL = "#C9D1D9"
PAPEL = "#F7F5F0"
TINTA = "#1E293B"

SERIE = [AZUL, AMBAR, VERDE, ROJO, "#6B5B95", GRIS]

AQUI = os.path.dirname(os.path.abspath(__file__))
SALIDA = os.path.join(AQUI, "..", "latex", "figs")


def _fuente():
    disponibles = {f.name for f in font_manager.fontManager.ttflist}
    for nombre in ("Segoe UI", "Arial", "DejaVu Sans"):
        if nombre in disponibles:
            return nombre
    return "sans-serif"


def aplicar(base: float = 19.0):
    """Tamaños pensados para una figura de 16.6 in de ancho vista a 1664 px."""
    plt.rcParams.update({
        "font.family": _fuente(),
        "font.size": base,
        "axes.titlesize": base + 2,
        "axes.titleweight": "bold",
        "axes.labelsize": base,
        "axes.edgecolor": GRIS,
        "axes.labelcolor": TINTA,
        "axes.linewidth": 1.2,
        "axes.spines.top": False,
        "axes.spines.right": False,
        "axes.grid": True,
        "grid.color": "#E3E6EA",
        "grid.linewidth": 1.0,
        "xtick.color": GRIS,
        "ytick.color": GRIS,
        "xtick.labelsize": base - 2,
        "ytick.labelsize": base - 2,
        "legend.fontsize": base - 2,
        "legend.frameon": False,
        "text.color": TINTA,
        "lines.linewidth": 3.0,
        "figure.facecolor": "none",
        "axes.facecolor": "none",
        "savefig.facecolor": "none",
        "savefig.dpi": 200,
    })


def guardar(fig, nombre: str):
    os.makedirs(SALIDA, exist_ok=True)
    ruta = os.path.join(SALIDA, nombre + ".png")
    fig.savefig(ruta, transparent=True)
    plt.close(fig)
    return ruta
