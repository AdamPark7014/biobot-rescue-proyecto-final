"""Figuras del procesamiento numérico en punto fijo: CORDIC y filtros.

Uso:  python numerico.py
Lee los registros de los bancos de prueba (sim/tb_cordic_iter.log y sim/tb_tonos.log, que deja
sim/simular.ps1) y escribe en latex/figs: cordic_iteraciones.png y filtros.png.
Los puntos de las gráficas son lo que midió la simulación del circuito; la única curva teórica es
la respuesta en frecuencia de la media móvil, y así se rotula.
"""
import math
import os
import re
import sys

import matplotlib.pyplot as plt

import estilo as E

E.aplicar()
AQUI = os.path.dirname(os.path.abspath(__file__))
SIM = os.path.join(AQUI, "..", "sim")
SALIDA = os.path.join(AQUI, "..", "latex", "figs")


def lee(nombre):
    ruta = os.path.join(SIM, nombre)
    if not os.path.exists(ruta):
        sys.exit("Falta %s: correr antes  pwsh -File sim\\simular.ps1" % ruta)
    with open(ruta, encoding="utf-8", errors="replace") as f:
        return f.read()


def cordic():
    """Error del CORDIC según el número de iteraciones (medido en la simulación)."""
    filas = re.findall(r"N=(\d+): K=[\d.]+; angulo, error maximo ([\d.]+) grados y eficaz ([\d.]+); "
                       r"magnitud, error maximo ([\d.]+) %; coseno y seno, error maximo ([\d.]+) %",
                       lee("tb_cordic_iter.log"))
    if len(filas) < 5:
        sys.exit("tb_cordic_iter.log no trae las medidas esperadas")
    n = [int(f[0]) for f in filas]
    amax, aef, mag, rot = ([float(f[k]) for f in filas] for k in (1, 2, 3, 4))

    fig, (a, b) = plt.subplots(1, 2, figsize=(16.64, 6.0))
    fig.subplots_adjust(left=0.075, right=0.985, top=0.88, bottom=0.15, wspace=0.24)
    a.semilogy(n, amax, "o-", color=E.AZUL, label="máximo", ms=9)
    a.semilogy(n, aef, "s--", color=E.AMBAR, label="eficaz", ms=8)
    a.axhline(360.0 / 65536, color=E.GRIS, lw=1.6, ls=":")
    a.text(n[0], 360.0 / 65536 * 1.25, "una cuenta del ángulo: 0.0055°", fontsize=14, color=E.GRIS, va="bottom")
    a.set_title("Vectorización: error del ángulo", loc="left")
    a.set_xlabel("Iteraciones (N)")
    a.set_ylabel("Error (grados)")
    a.set_xticks(n)
    a.legend(loc="upper right")
    b.semilogy(n, rot, "o-", color=E.VERDE, label="coseno y seno (rotación)", ms=9)
    b.semilogy(n, mag, "s--", color=E.ROJO, label="magnitud (vectorización)", ms=8)
    b.set_title("Error máximo, en porcentaje de la escala", loc="left")
    b.set_xlabel("Iteraciones (N)")
    b.set_ylabel("Error (%)")
    b.set_xticks(n)
    b.legend(loc="upper right")
    for ax in (a, b):
        ax.axvline(16, color=E.AZUL_OSC, lw=1.4, ls=(0, (4, 3)), zorder=1)
    a.text(16.2, 0.32, "N = 16:\nel diseño", fontsize=14, color=E.AZUL_OSC, va="top")
    return fig


def filtros():
    """Media móvil (FIR) y potencias medidas por los filtros de Goertzel (IIR)."""
    fig, (a, b) = plt.subplots(1, 2, figsize=(16.64, 6.0))
    fig.subplots_adjust(left=0.07, right=0.985, top=0.88, bottom=0.2, wspace=0.22)

    # FIR: media de cuatro cuadros a 10 cuadros por segundo
    fs, m = 10.0, 4
    f = [k * (fs / 2) / 600.0 for k in range(601)]
    h = []
    for x in f:
        w = math.pi * x / fs
        h.append(1.0 if x == 0 else abs(math.sin(m * w) / (m * math.sin(w))))
    a.plot(f, h, color=E.AZUL)
    a.set_title("FIR: media móvil de 4 cuadros (teórica)", loc="left")
    a.set_xlabel("Frecuencia (Hz), con 10 cuadros por segundo")
    a.set_ylabel("Ganancia")
    a.set_ylim(0, 1.05)
    a.set_xlim(0, 5)
    a.annotate("nulo en 2.5 Hz", xy=(2.5, 0.0), xytext=(2.0, 0.42), fontsize=14, color=E.GRIS,
               arrowprops=dict(arrowstyle="-", color=E.GRIS, lw=1.2))
    a.annotate("nulo en 5 Hz", xy=(5.0, 0.0), xytext=(3.75, 0.52), fontsize=14, color=E.GRIS,
               arrowprops=dict(arrowstyle="-", color=E.GRIS, lw=1.2))

    # IIR: potencias que midió la mochila A en tb_tonos (emite 1 kHz y escucha 2 y 4 kHz)
    casos = re.findall(r"llegan (\d{3}): oye (\d{3}); potencia 4 kHz (\d+), 1 kHz (\d+), 2 kHz (\d+)", lee("tb_tonos.log"))
    nombres = {"000": "ninguno", "001": "receptor", "100": "B", "101": "B y\nreceptor", "111": "los tres",
               "010": "solo el\npropio"}
    vistos, etiquetas, p4, p2 = set(), [], [], []
    for llegan, _oye, c4, _c1, c2 in casos:
        if llegan in vistos:
            continue
        vistos.add(llegan)
        etiquetas.append(nombres.get(llegan, llegan))
        p4.append(max(int(c4), 1))
        p2.append(max(int(c2), 1))
    x = range(len(etiquetas))
    b.bar([k - 0.2 for k in x], p4, 0.4, color=E.AZUL, label="filtro de 4 kHz (receptor)")
    b.bar([k + 0.2 for k in x], p2, 0.4, color=E.AMBAR, label="filtro de 2 kHz (mochila B)")
    b.set_yscale("log")
    b.axhline(4000, color=E.ROJO, lw=1.8, ls="--")
    b.text(-0.42, 4000 * 1.3, "umbral:\n4 000", fontsize=14, color=E.ROJO, ha="left", va="bottom", linespacing=1.15)
    b.set_xticks(list(x))
    b.set_xticklabels(etiquetas, fontsize=14)
    b.set_ylim(0.8, 3e5)
    b.set_title("IIR: potencia medida por Goertzel en la mochila A", loc="left")
    b.set_xlabel("Tonos que llegan")
    b.set_ylabel("Potencia (unidades del filtro)")
    b.legend(loc="upper left", fontsize=14, ncol=2, columnspacing=1.2)
    return fig


def pid():
    """Respuesta del PID al escalón grande, con y sin integración condicional (sim/trazas/pid.csv)."""
    import csv
    ruta = os.path.join(SIM, "trazas", "pid.csv")
    if not os.path.exists(ruta):
        sys.exit("Falta %s: correr  vvp -n tb_pid.out +traza  en sim/" % ruta)
    with open(ruta, encoding="ascii") as f:
        filas = list(csv.DictReader(f))
    n = [int(r["muestra"]) for r in filas][:200]
    y_con = [int(r["y_con"]) for r in filas][:200]
    y_sin = [int(r["y_sin"]) for r in filas][:200]
    u_con = [int(r["u_con"]) for r in filas][:200]
    u_sin = [int(r["u_sin"]) for r in filas][:200]
    ref = int(filas[0]["ref"])

    fig, (a, b) = plt.subplots(1, 2, figsize=(16.64, 6.0))
    fig.subplots_adjust(left=0.075, right=0.985, top=0.88, bottom=0.15, wspace=0.2)
    a.axhline(ref, color=E.GRIS, lw=1.6, ls=":")
    a.plot(n, y_sin, color=E.ROJO, ls=(0, (5, 2)), label="sin protección del integrador")
    a.plot(n, y_con, color=E.AZUL, label="con integración condicional")
    a.set_title("Salida de la planta", loc="left")
    a.set_xlabel("Muestra")
    a.set_ylabel("Medida (cuentas)")
    a.set_ylim(0, ref * 1.08)
    a.legend(loc="lower right")
    # acercamiento al sobrepaso
    ins = a.inset_axes([0.42, 0.32, 0.54, 0.36])
    ins.axhline(ref, color=E.GRIS, lw=1.2, ls=":")
    ins.plot(n, y_sin, color=E.ROJO, ls=(0, (5, 2)), lw=2.2)
    ins.plot(n, y_con, color=E.AZUL, lw=2.2)
    ins.set_xlim(30, 140)
    ins.set_ylim(ref * 0.97, ref * 1.03)
    ins.tick_params(labelsize=12)
    ins.set_title("sobrepaso", fontsize=13, loc="left")
    b.axhline(255, color=E.GRIS, lw=1.6, ls=":")
    b.text(n[-1], 258, "tope del actuador: 255", ha="right", va="bottom", fontsize=14, color=E.GRIS)
    b.plot(n, u_sin, color=E.ROJO, ls=(0, (5, 2)), label="sin protección")
    b.plot(n, u_con, color=E.AZUL, label="con integración condicional")
    b.set_title("Acción de control", loc="left")
    b.set_xlabel("Muestra")
    b.set_ylabel("u (cuentas)")
    b.set_ylim(0, 285)
    b.legend(loc="lower right")
    return fig


if __name__ == "__main__":
    for nombre, f in (("cordic_iteraciones", cordic), ("filtros", filtros), ("pid_respuesta", pid)):
        fig = f()
        ruta = os.path.join(SALIDA, nombre + ".png")
        fig.savefig(ruta, dpi=120)
        plt.close(fig)
        print(nombre, "->", os.path.relpath(ruta, AQUI))
