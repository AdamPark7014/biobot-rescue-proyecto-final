"""Experimentos de Monte Carlo con la simulación de misión.

Corre todo y deja los números en resultados.json; figuras.py dibuja a partir de ahí.
Uso:  python experimentos.py                    (todo; cerca de dos horas)
      python experimentos.py rapido             (menos corridas, para probar)
      python experimentos.py solo habituacion   (rehace solo ese bloque; también: por_mapa, mixto)
"""
import json
import os
import sys
import time

import numpy as np

import biobot_sim as S
import parametros as P

AQUI = os.path.dirname(os.path.abspath(__file__))
RAPIDO = len(sys.argv) > 1 and sys.argv[1] == "rapido"
MAPAS = [11, 12, 13, 14] if RAPIDO else [11, 12, 13, 14, 15, 16, 17, 18]
CORRIDAS = 12 if RAPIDO else 40
ANCHO, ALTO = 8.0, 6.0
T_MAX = 3600.0                       # s por misión
CORTES = (900.0, 1800.0, 2700.0, 3600.0)

_mapas = {}


def mapa(semilla):
    if semilla not in _mapas:
        _mapas[semilla] = S.generar_mapa(semilla, ANCHO, ALTO)
    return _mapas[semilla]


def lote(p, politica, n, t_max=T_MAX, corridas=None, mapas=None):
    """Junta las corridas de todos los mapas para una configuración."""
    t_det, cob, est, anda, hab = [], [], [], [], []
    for i, sm in enumerate(mapas or MAPAS):
        r = S.simular(mapa(sm), p, politica, n, corridas or CORRIDAS, t_max, semilla=1000 * sm + n + politica)
        t_det.append(r["t_det"])
        cob.append(r["cobertura"])
        est.append(r["estimulos"].mean(axis=1))
        anda.append(r["frac_anda"].mean(axis=1))
        hab.append(r["hab_fin"].mean(axis=1))
    t_det = np.concatenate(t_det)
    cob = np.concatenate(cob)
    ok = np.isfinite(t_det)
    return {
        "p_det": {str(int(c / 60)): float((t_det <= c).mean()) for c in CORTES},
        "t_mediana": float(np.median(t_det[ok])) if ok.any() else None,
        "t_q25": float(np.percentile(t_det[ok], 25)) if ok.any() else None,
        "t_q75": float(np.percentile(t_det[ok], 75)) if ok.any() else None,
        "cdf_min": [float((t_det <= 60.0 * m).mean()) for m in range(0, int(t_max / 60) + 1)],
        "cob_media": cob.mean(axis=0).tolist(),
        "cob_q25": np.percentile(cob, 25, axis=0).tolist(),
        "cob_q75": np.percentile(cob, 75, axis=0).tolist(),
        "est_por_hora": float(np.concatenate(est).mean() * 3600.0 / t_max),
        "frac_anda": float(np.concatenate(anda).mean()),
        "hab_fin": float(np.concatenate(hab).mean()),
        "n": int(t_det.size),
    }


def validar_marcha():
    """Arena abierta de 1 x 1 m: marcha natural contra marcha con comandos al azar."""
    m = S.generar_mapa(1, 1.0, 1.0, ocupacion=0.0)
    out = {}
    for nombre, pol in (("natural", S.PASIVA), ("comandos", S.ESTOCASTICA)):
        r = S.simular(m, P.con(k_foto=0.0), pol, 20, 20, 1800.0, semilla=5)
        out[nombre] = {"frac_anda": float(r["frac_anda"].mean()), "pausa_media": float(r["pausa_media"]),
                       "p_salida": float(r["p_salida"]), "est_por_hora": float(r["estimulos"].mean() * 2)}
    return out


def habituacion(base):
    """E4: habituación y dosificación (10 insectos, 2 h para que se note)."""
    sin_tope = dict(cuenta_lim=1e9, t_refractario=2.0, retro_max=0)
    return {
        "Unipolar sin dosificar": lote(P.con(**P.UNIPOLAR, **sin_tope), S.GUIADA, 10, t_max=7200.0),
        "Unipolar dosificado": lote(P.con(**P.UNIPOLAR), S.GUIADA, 10, t_max=7200.0),
        "Sin habituación, dosificado": lote(P.con(alfa_hab=0.0), S.GUIADA, 10, t_max=7200.0),
        "Pasiva": lote(base, S.PASIVA, 10, t_max=7200.0),
    }


def por_mapa(base):
    """E6: dispersión entre colapsos. Mismas corridas que E1, separadas mapa por mapa."""
    out = {"mapas": MAPAS, "dist_victima": [float(mapa(s).geo[mapa(s).victima]) for s in MAPAS],
           "area_libre": [float(mapa(s).area_libre) for s in MAPAS]}
    for nombre, pol in (("Pasiva", S.PASIVA), ("Guiada", S.GUIADA)):
        out[nombre] = []
        for sm in MAPAS:
            r = lote(base, pol, 10, mapas=[sm])
            out[nombre].append({"p30": r["p_det"]["30"], "p45": r["p_det"]["45"], "p60": r["p_det"]["60"],
                                "cob60": r["cob_media"][-1]})
    return out


def mixto(base):
    """E7: enjambre mixto, cinco insectos pasivos y cinco guiados. Los agentes no interactúan, así
    que la misión mixta detecta cuando lo hace el primero de los dos grupos."""
    out = {"mapas": MAPAS, "p45": [], "p60": []}
    todos = []
    for sm in MAPAS:
        t = [S.simular(mapa(sm), base, pol, 5, CORRIDAS, T_MAX, semilla=1000 * sm + 5 + pol)["t_det"]
             for pol in (S.PASIVA, S.GUIADA)]
        tm = np.minimum(t[0], t[1])
        todos.append(tm)
        out["p45"].append(float((tm <= 2700.0).mean()))
        out["p60"].append(float((tm <= 3600.0).mean()))
    tm = np.concatenate(todos)
    out["p_det"] = {str(int(c / 60)): float((tm <= c).mean()) for c in CORTES}
    return out


CASOS_REGRESO = [(S.NOMBRES_REGRESO[m], m, {}) for m in
                 (S.REGRESO_PASIVO, S.REGRESO_ANDAR, S.REGRESO_INERCIAL, S.REGRESO_RUTA)]
CASOS_REGRESO += [("Solo trampa, alcance 1 m", S.REGRESO_PASIVO, {"r_captura": 1.0}),
                  ("Mantenerlo caminando, alcance 1 m", S.REGRESO_ANDAR, {"r_captura": 1.0})]
CASOS_FARO = [("Faro, sin límite de alcance", S.REGRESO_FARO, {}),
              ("Faro, alcanza 6 m de camino", S.REGRESO_FARO, {"alcance_faro": 6.0}),
              ("Faro, 6 m y el doble de ruido", S.REGRESO_FARO, {"alcance_faro": 6.0, "ruido_faro": 1.0}),
              ("Faro de 6 m y trampa de 1 m", S.REGRESO_FARO, {"alcance_faro": 6.0, "r_captura": 1.0})]


def regreso(base, casos=None, previo=None):
    """E8: recuperación de los insectos. Tras 45 min de búsqueda guiada se ordena el regreso y
    un refugio-trampa en el boquete recoge a los que llegan. Se comparan cuatro formas de
    regresar sin ayuda externa, un refugio con más alcance (1 m) y un faro infrarrojo en el
    boquete que la mochila sigue con dos fotodiodos. Con `previo` se conservan los casos ya
    calculados y solo se añaden los de `casos`."""
    t_ida, t_vuelta = 2700.0, 7200.0
    cortes = (15, 30, 45, 60, 90, 120)
    if casos is None:
        casos = CASOS_REGRESO + CASOS_FARO
    out = {"t_ida": t_ida, "t_vuelta": t_vuelta, "cortes": list(cortes), "mapas": MAPAS,
           "casos": dict(previo["casos"]) if previo else {}}
    for nombre, modo, extra in casos:
        p = P.con(**extra)
        tc, est, por_mapa = [], [], []
        for sm in MAPAS:
            r = S.simular(mapa(sm), p, S.GUIADA, 10, CORRIDAS, t_ida + t_vuelta, semilla=7000 + sm,
                          t_regreso=t_ida, modo_regreso=modo)
            tc.append(r["t_cap"].ravel())
            est.append(r["est_regreso"].ravel())
            por_mapa.append(float((r["t_cap"] <= 3600.0).mean()))
        tc, est = np.concatenate(tc), np.concatenate(est)
        out["casos"][nombre] = {
            "recogidos": {str(c): float((tc <= 60.0 * c).mean()) for c in cortes},
            "por_mapa_60": por_mapa,
            "estimulos": float(est.mean()),
            "n": int(tc.size),
        }
        print("  regreso", nombre, out["casos"][nombre]["recogidos"], "est %.0f" % est.mean(), flush=True)
    return out


def solo(bloque):
    """Rehace un bloque y lo guarda en resultados.json sin tocar los demás."""
    ruta = os.path.join(AQUI, "resultados.json")
    with open(ruta, encoding="utf-8") as f:
        res = json.load(f)
    t0 = time.time()
    if bloque == "faro":      # añade los casos con faro al estudio del regreso ya calculado
        res["regreso"] = regreso(P.con(), casos=CASOS_FARO, previo=res.get("regreso"))
    else:
        res[bloque] = {"habituacion": habituacion, "por_mapa": por_mapa, "mixto": mixto, "regreso": regreso}[bloque](P.con())
    with open(ruta, "w", encoding="utf-8") as f:
        json.dump(res, f, ensure_ascii=False, indent=1)
    print("%s rehecho en %.0f s" % (bloque, time.time() - t0))


def main():
    t0 = time.time()
    res = {"meta": {"mapas": MAPAS, "corridas": CORRIDAS, "ancho": ANCHO, "alto": ALTO, "t_max": T_MAX,
                    "area_libre_media": float(np.mean([mapa(s).area_libre for s in MAPAS])),
                    "dist_victima_media": float(np.mean([mapa(s).geo[mapa(s).victima] for s in MAPAS]))}}
    base = P.con()
    res["alcances"] = {
        "matriz32": [S.alcance(base, base["n_pre"]), S.alcance(base, base["n_det"])],
        "matriz8": [S.alcance(P.con(**P.MATRIZ_8X8), 1.0), S.alcance(P.con(**P.MATRIZ_8X8), 2.0)],
        "un_pixel": [S.alcance(P.con(**P.UN_PIXEL), 0.03), S.alcance(P.con(**P.UN_PIXEL), 0.055)],
    }
    res["validacion"] = validar_marcha()
    print("validación", res["validacion"], flush=True)

    # E1: políticas con 10 insectos
    res["politicas"] = {S.NOMBRES[k]: lote(base, k, 10) for k in (S.PASIVA, S.ANTIPAUSA, S.ESTOCASTICA, S.GUIADA)}
    print("E1 %.0f s" % (time.time() - t0), {k: (v["p_det"], v["est_por_hora"]) for k, v in res["politicas"].items()}, flush=True)

    # E2: tamaño del enjambre
    tam = [1, 2, 5, 10, 20, 40]
    res["enjambre"] = {"n": tam}
    for nombre, pol in (("Pasiva", S.PASIVA), ("Guiada", S.GUIADA)):
        res["enjambre"][nombre] = [lote(base, pol, n) for n in tam]
    print("E2 %.0f s" % (time.time() - t0), flush=True)

    # E3: sensor térmico (política guiada, 10 insectos)
    res["sensor"] = {
        "Un píxel, 90°": lote(P.con(**P.UN_PIXEL), S.GUIADA, 10),
        "Matriz 8×8, 60°": lote(P.con(**P.MATRIZ_8X8), S.GUIADA, 10),
        "Matriz 32×32, 90°": res["politicas"]["Guiada"],
    }
    print("E3 %.0f s" % (time.time() - t0), flush=True)

    # E4: habituación y dosificación
    res["habituacion"] = habituacion(base)
    print("E4 %.0f s" % (time.time() - t0), flush=True)

    # E5: sensibilidad de la política guiada (10 insectos) a los supuestos
    barridos = {
        "p_rodea": (0.5, 0.95), "k_refugio": (0.0, 2.0), "area_blanco": (0.01, 0.10),
        "p_resp": (0.5, 0.9), "frac_responde": (0.56, 1.0), "t_pausa": (18.4, 73.6),
        "tasa_perdida": (0.0, 0.5), "pen_carga": (0.0, 0.3), "v_natural": (0.0136, 0.0252),
        "alfa_hab": (0.0, 0.06), "k_foto": (0.0, 2.0), "l_tramo": (0.088, 0.352),
    }
    res["sensibilidad"] = {}
    mapas_s = MAPAS[:4]
    for nombre, (lo, hi) in barridos.items():
        fila = {}
        for etiqueta, valor in (("bajo", lo), ("alto", hi)):
            extra = {"t_pausa_sd": valor * 24.1 / 36.8} if nombre == "t_pausa" else {}
            for pol_n, pol in (("Pasiva", S.PASIVA), ("Guiada", S.GUIADA)):
                r = lote(P.con(**{nombre: valor}, **extra), pol, 10, mapas=mapas_s)
                fila[f"{etiqueta}_{pol_n}"] = {"valor": valor, "p45": r["p_det"]["45"], "cob60": r["cob_media"][-1]}
        res["sensibilidad"][nombre] = fila
        print("  sens", nombre, fila, flush=True)
    res["sensibilidad_base"] = {pol_n: (lambda r: {"p45": r["p_det"]["45"], "cob60": r["cob_media"][-1]})(
        lote(base, pol, 10, mapas=mapas_s)) for pol_n, pol in (("Pasiva", S.PASIVA), ("Guiada", S.GUIADA))}

    # E6: dispersión entre mapas; E7: enjambre mixto
    res["por_mapa"] = por_mapa(base)
    res["mixto"] = mixto(base)

    # E8: recuperación de los insectos
    res["regreso"] = regreso(base)

    res["meta"]["segundos"] = time.time() - t0
    with open(os.path.join(AQUI, "resultados.json"), "w", encoding="utf-8") as f:
        json.dump(res, f, ensure_ascii=False, indent=1)
    print("listo en %.0f s" % (time.time() - t0))


if __name__ == "__main__":
    if len(sys.argv) > 2 and sys.argv[1] == "solo":
        solo(sys.argv[2])
    else:
        main()
