"""Simulación de misión de un enjambre de biobots en una estructura colapsada.

Modelo de agentes vectorizado con numpy. Cada agente es una cucaracha de Madagascar
(Gromphadorhina portentosa) con mochila. La marcha natural sigue el modelo de
Dirafzoon et al. (2017), con los valores que usan Tran-Ngoc et al. (2024): tramos
rectos de longitud exponencial, pausa con probabilidad P_stop al final de cada tramo,
seguimiento de paredes y salida de la pared con probabilidad p_exit. Sobre esa marcha
actúa la política de estímulos que corre en la mochila.

Todas las corridas de Monte Carlo de un mismo mapa avanzan a la vez en arreglos de
forma (corridas, agentes). Unidades: m, s, rad. Valores y fuentes en parametros.py.
"""
from __future__ import annotations

from collections import deque
from dataclasses import dataclass

import numpy as np

# Políticas de estímulo que puede ejecutar la mochila
PASIVA = 0        # sin estímulos: solo conducta natural (propuesta original)
ANTIPAUSA = 1     # reinicia la marcha cuando el insecto lleva demasiado quieto
ESTOCASTICA = 2   # antipausa + giros al azar para soltarlo de las paredes
GUIADA = 3        # estocástica + acercamiento hacia la mancha de calor

NOMBRES = {PASIVA: "Pasiva", ANTIPAUSA: "Antipausa", ESTOCASTICA: "Estocástica", GUIADA: "Guiada"}

# fase de regreso (solo si se llama a simular con t_regreso)
REGRESO_PASIVO = 0     # sin estímulos: solo el refugio-trampa en el boquete
REGRESO_INERCIAL = 1   # rumbo directo: la mochila estima dónde quedó el boquete y gira hacia él
REGRESO_RUTA = 2       # ruta inversa: la mochila guardó migas de por dónde vino y las desanda
REGRESO_ANDAR = 3      # solo se evita que el insecto se quede quieto; llega por su cuenta
REGRESO_FARO = 4       # faro infrarrojo en el boquete: dos fotodiodos dicen de qué lado llega más luz
NOMBRES_REGRESO = {REGRESO_PASIVO: "Solo trampa", REGRESO_ANDAR: "Mantenerlo caminando",
                   REGRESO_INERCIAL: "Rumbo directo", REGRESO_RUTA: "Ruta inversa", REGRESO_FARO: "Faro infrarrojo"}

# modos de marcha
CAMINA, PARED, PAUSA = 0, 1, 2


# --------------------------------------------------------------------------- mapa
@dataclass
class Mapa:
    libre: np.ndarray        # (H, W) bool: celda transitable
    res: float               # m por celda
    entrada: tuple           # (fila, columna) del punto de liberación
    victima: tuple           # (fila, columna) de la persona atrapada
    geo: np.ndarray          # distancia geodésica a la entrada, m (inf si no se alcanza)
    luz: np.ndarray          # 0..1, luz que llega desde la entrada
    gx: np.ndarray           # dirección unitaria hacia lo oscuro (componente x)
    gy: np.ndarray
    dist_v: np.ndarray       # distancia euclidiana a la víctima, m
    vis_v: np.ndarray        # bool: línea de vista libre hasta la víctima
    alcanzable: np.ndarray   # bool: celdas conectadas con la entrada

    @property
    def forma(self):
        return self.libre.shape

    @property
    def area_libre(self):
        return float(self.alcanzable.sum()) * self.res ** 2


def _componente(libre: np.ndarray, semilla: tuple) -> np.ndarray:
    """Distancia geodésica (en celdas, 8 vecinos) desde `semilla`; inf donde no llega."""
    H, W = libre.shape
    d = np.full((H, W), np.inf)
    d[semilla] = 0.0
    cola = deque([semilla])
    vec = [(-1, 0, 1.0), (1, 0, 1.0), (0, -1, 1.0), (0, 1, 1.0),
           (-1, -1, 1.4142), (-1, 1, 1.4142), (1, -1, 1.4142), (1, 1, 1.4142)]
    while cola:
        f, c = cola.popleft()
        base = d[f, c]
        for df, dc, w in vec:
            nf, nc = f + df, c + dc
            if 0 <= nf < H and 0 <= nc < W and libre[nf, nc] and base + w < d[nf, nc] - 1e-9:
                if df and dc and not (libre[f, nc] and libre[nf, c]):
                    continue                     # en diagonal no se cruza una esquina cerrada
                d[nf, nc] = base + w
                cola.append((nf, nc))
    return d


def _linea_de_vista(libre: np.ndarray, origen: tuple) -> np.ndarray:
    """Para cada celda, True si el segmento hasta `origen` no toca un obstáculo."""
    H, W = libre.shape
    ff, cc = np.mgrid[0:H, 0:W]
    f0, c0 = origen
    n = int(np.hypot(H, W)) + 1
    t = np.linspace(0.0, 1.0, n)[:, None, None]
    fs = np.rint(f0 + (ff - f0)[None] * t).astype(int)
    cs = np.rint(c0 + (cc - c0)[None] * t).astype(int)
    return libre[fs, cs].all(axis=0)


def generar_mapa(semilla: int, ancho: float = 6.0, alto: float = 4.0, res: float = 0.05,
                 ocupacion: float = 0.45, escala_luz: float = 1.0) -> Mapa:
    """Colapso sintético: losas y escombro menor con huecos conectados.

    La entrada queda a media altura del borde izquierdo y la víctima en un hueco
    lejano (entre los percentiles 60 y 90 de distancia geodésica).
    """
    rng = np.random.default_rng(semilla)
    H, W = int(round(alto / res)), int(round(ancho / res))
    libre = np.ones((H, W), bool)
    libre[0, :] = libre[-1, :] = libre[:, 0] = libre[:, -1] = False

    intentos = 0
    while (~libre).mean() < ocupacion and intentos < 4000:     # losas y vigas
        intentos += 1
        largo = rng.uniform(0.4, 1.8)
        grueso = rng.uniform(0.10, 0.40)
        w, h = (largo, grueso) if rng.random() < 0.5 else (grueso, largo)
        cw, ch = max(1, int(w / res)), max(1, int(h / res))
        f = rng.integers(1, H - ch - 1)
        c = rng.integers(1, W - cw - 1)
        libre[f:f + ch, c:c + cw] = False
    for _ in range(int(0.004 * H * W)):                        # escombro menor
        f, c = rng.integers(1, H - 2), rng.integers(1, W - 2)
        s = rng.integers(1, 3)
        libre[f:f + s, c:c + s] = False

    fe = H // 2                                                # boquete de entrada
    libre[fe - 3:fe + 4, 0:8] = True
    libre[fe - 3:fe + 4, 0] = False
    entrada = (fe, 2)

    d0 = _componente(libre, entrada)
    alcanz = np.isfinite(d0)
    cand = np.argwhere(alcanz)
    dd = d0[alcanz]
    lo, hi = np.percentile(dd, [60, 90])
    sel = cand[(dd >= lo) & (dd <= hi)]
    vf, vc = sel[rng.integers(len(sel))]
    hf, hc = int(0.35 / res / 2), int(0.5 / res / 2)           # hueco de 0.5 x 0.35 m
    f1, f2 = max(1, vf - hf), min(H - 1, vf + hf + 1)
    c1, c2 = max(1, vc - hc), min(W - 1, vc + hc + 1)
    libre[f1:f2, c1:c2] = True
    victima = (int(vf), int(vc))

    geo_c = _componente(libre, entrada)
    alcanz = np.isfinite(geo_c)
    geo = geo_c * res
    luz = np.where(alcanz, np.exp(-geo / escala_luz), 0.0)

    g = np.where(alcanz, geo, np.nan)                          # hacia lo oscuro
    gf = np.nan_to_num(np.roll(g, -1, 0) - g) - np.nan_to_num(np.roll(g, 1, 0) - g)
    gc = np.nan_to_num(np.roll(g, -1, 1) - g) - np.nan_to_num(np.roll(g, 1, 1) - g)
    norma = np.hypot(gf, gc)
    norma[norma == 0] = 1.0

    ff, cc = np.mgrid[0:H, 0:W]
    dist_v = np.hypot(ff - vf, cc - vc) * res
    vis_v = _linea_de_vista(libre, victima) & alcanz
    return Mapa(libre, res, entrada, victima, geo, luz, gc / norma, gf / norma, dist_v, vis_v, alcanz)


# --------------------------------------------------------------------- detección
def pixeles_calientes(d, p: dict):
    """Píxeles del sensor que llena un blanco de área A a distancia d (vista libre).

    Matriz: n = A / (d tan(ifov))^2. Termopila de un píxel con campo circular: fracción
    del campo que llena el blanco, f = A / (pi (d tan(fov/2))^2), acotada a 1.
    """
    d = np.maximum(d, 1e-3)
    if p["un_pixel"]:
        r = d * np.tan(np.deg2rad(p["fov_total_deg"]) / 2.0)
        return np.minimum(1.0, p["area_blanco"] / (np.pi * r * r))
    lado = d * np.tan(np.deg2rad(p["ifov_deg"]))
    return np.minimum(float(p["n_pixeles"]), p["area_blanco"] / (lado * lado))


def alcance(p: dict, umbral: float) -> float:
    """Distancia máxima a la que la señal alcanza `umbral`."""
    d = np.linspace(0.02, 20.0, 20000)
    ok = pixeles_calientes(d, p) >= umbral
    return float(d[ok].max()) if ok.any() else 0.0


# -------------------------------------------------------------------- simulación
def simular(mapa: Mapa, p: dict, politica: int, n_agentes: int, corridas: int,
            t_max: float, semilla: int = 0, guardar_tray: bool = False,
            t_regreso: float = None, modo_regreso: int = REGRESO_INERCIAL) -> dict:
    """Corre `corridas` misiones independientes sobre el mismo mapa.

    Con `t_regreso` (s), a partir de ese momento la misión cambia a la fase de regreso:
    la mochila deja de buscar y trata de llevar al insecto de vuelta al boquete, donde lo
    recoge un refugio-trampa. Sin `t_regreso` la simulación es idéntica a la de siempre
    (no se consume ni un número al azar de más).
    """
    rng = np.random.default_rng(semilla)
    R, N = corridas, n_agentes
    S = (R, N)
    dt, res = p["dt"], mapa.res
    H, W = mapa.forma
    pasos = int(t_max / dt)
    libre = mapa.libre

    def celda(xx, yy):
        return (np.clip((yy / res).astype(int), 0, H - 1), np.clip((xx / res).astype(int), 0, W - 1))

    def es_libre(xx, yy):
        iy_, ix_ = celda(xx, yy)
        return libre[iy_, ix_]

    def pausa_nueva():
        k = (p["t_pausa"] / p["t_pausa_sd"]) ** 2            # gamma con esa media y desviación
        return rng.gamma(k, p["t_pausa"] / k, S)

    fe, ce = mapa.entrada
    x = (ce + 0.5 + rng.uniform(-0.4, 0.4, S)) * res
    y = (fe + 0.5 + rng.uniform(-2.0, 2.0, S)) * res
    th = rng.uniform(-0.6, 0.6, S)                          # salen hacia adentro (+x)
    modo = np.full(S, CAMINA)
    previo = np.full(S, CAMINA)                             # modo al que vuelve tras una pausa
    lado = np.ones(S)                                       # +1 pared a la izquierda, -1 a la derecha
    tramo = rng.exponential(p["l_tramo"], S)                # m que faltan del tramo actual
    ciego = np.zeros(S)                                     # m sin revisar el costado tras doblar
    t_pausa = np.zeros(S)
    t_quieto = np.zeros(S)
    t_impulso = np.zeros(S)                                 # s que quedan de marcha acelerada
    v_nat = np.clip(rng.normal(p["v_natural"], p["v_natural_sd"], S), 0.005, None) * (1 - p["pen_carga"])
    responde = rng.random(S) < p["frac_responde"]           # individuos que obedecen al estímulo
    hab = np.zeros(S)                                       # habituación del insecto, 0..1
    cuenta = np.zeros(S)                                    # cuenta con fugas que lleva la mochila
    retro = np.zeros(S)
    t_ult = np.full(S, 1e9)
    n_est = np.zeros(S)
    activo = np.ones(S, bool)
    conf = np.zeros(S, int)
    t_det = np.full(R, np.inf)
    visit = np.zeros((R, H, W), bool)
    ridx = np.arange(R)[:, None]
    n_alc = int(mapa.alcanzable.sum())
    cada = int(60.0 / dt)
    cobertura, tray = [], ([] if guardar_tray else None)
    t_anda = np.zeros(S)                                    # s en movimiento (para validar)
    n_pausas = np.zeros(S)
    t_en_pausa = np.zeros(S)
    n_decis_pared = np.zeros(S)
    n_salidas = np.zeros(S)
    vf, vc = mapa.victima
    semi_fov = np.deg2rad(p["fov_total_deg"]) / 2.0
    lam_perdida = p["tasa_perdida"] / 3600.0
    k_rec = np.exp(-dt / p["tau_rec"])
    k_fuga = np.exp(-dt / p["tau_cuenta"])
    p_giro = 1.0 - np.exp(-dt / p["t_giro_medio"])

    # ---- fase de regreso: lo que la mochila necesita para volver al boquete
    regreso = t_regreso is not None
    if regreso:
        x_e, y_e = (ce + 0.5) * res, (fe + 0.5) * res       # centro del boquete
        ex, ey = x.copy(), y.copy()                         # posición que la mochila cree tener
        beta = np.zeros(S)                                  # error de rumbo acumulado por la IMU, rad
        sig_beta = p.get("deriva_rumbo", 0.033)             # rad por raíz de metro caminado
        d_ref = np.hypot(ex - x_e, ey - y_e)                # distancia estimada en la última revisión
        n_chk = max(1, int(p.get("t_progreso", 20.0) / dt))
        capturado = np.zeros(S, bool)
        t_cap = np.full(S, np.inf)                          # s desde la orden de regreso hasta la captura
        n_est_ida = None                                    # estímulos gastados antes de regresar
        ruta = modo_regreso == REGRESO_RUTA
        if ruta:
            # Migas: una posición estimada cada paso_miga metros, en una pila. Si el insecto
            # vuelve a pasar cerca de una miga vieja, las posteriores se olvidan (lazo cerrado).
            K = int(p.get("migas_max", 800))
            paso_miga = p.get("paso_miga", 0.25)
            r_miga = p.get("r_miga", 0.20)
            migas = np.zeros((R, N, K, 2))
            migas[:, :, 0, 0], migas[:, :, 0, 1] = ex, ey
            n_migas = np.ones(S, int)
            rr, nn = np.meshgrid(np.arange(R), np.arange(N), indexing="ij")
            k_idx = np.arange(K)[None, None, :]

    def estimular(mascara):
        """Aplica un estímulo a `mascara`; devuelve quién respondió."""
        nonlocal hab, cuenta, n_est, t_ult
        ok = mascara & responde & (rng.random(S) < p["p_resp"] * (1.0 - hab))
        hab = np.where(mascara, hab + p["alfa_hab"] * (1.0 - hab), hab)
        cuenta = np.where(mascara, cuenta + 1.0, cuenta)
        n_est = n_est + mascara
        t_ult = np.where(mascara, 0.0, t_ult)
        return ok

    for k in range(pasos):
        t = (k + 1) * dt
        iy, ix = celda(x, y)
        luz = mapa.luz[iy, ix]

        # ---- fin de pausa natural
        en_pausa = modo == PAUSA
        t_pausa = np.where(en_pausa, t_pausa - dt, 0.0)
        fin = en_pausa & (t_pausa <= 0.0)
        modo = np.where(fin, previo, modo)
        t_quieto = np.where(modo == PAUSA, t_quieto + dt, 0.0)

        # ---- señal térmica vista por el sensor (mira al frente)
        dist = mapa.dist_v[iy, ix]
        rumbo = np.arctan2((vf + 0.5) * res - y, (vc + 0.5) * res - x)
        err = np.angle(np.exp(1j * (rumbo - th)))
        visible = mapa.vis_v[iy, ix] & (np.abs(err) <= semi_fov)
        senal = np.where(visible, pixeles_calientes(dist, p), 0.0)
        ve_pre = senal >= p["n_pre"]

        # ---- política de estímulos (corre en la mochila)
        hab *= k_rec
        cuenta *= k_fuga
        t_ult += dt
        puede = (t_ult >= p["t_refractario"]) & activo & (cuenta < p["cuenta_lim"])

        # En la fase de regreso ya no se busca: queda la antipausa y la regla de regreso
        en_regreso = regreso and t > t_regreso
        pol = politica
        if en_regreso:
            pol = PASIVA if modo_regreso == REGRESO_PASIVO else ANTIPAUSA
            if n_est_ida is None:
                n_est_ida = n_est.copy()
                d_ref = np.hypot(ex - x_e, ey - y_e)

        if pol >= ANTIPAUSA:
            disp = (modo == PAUSA) & (t_quieto >= p["t_espera"] * 2.0 ** retro) & puede
            if disp.any():
                ok = estimular(disp)
                modo = np.where(ok, previo, modo)
                t_impulso = np.where(ok, p["t_impulso"], t_impulso)
                retro = np.where(ok, 0.0, np.where(disp, np.minimum(retro + 1, p["retro_max"]), retro))
                t_quieto = np.where(disp, 0.0, t_quieto)
                puede &= ~disp

        if pol >= ESTOCASTICA:
            guia = (pol >= GUIADA) & ve_pre
            disp = (modo != PAUSA) & (rng.random(S) < p_giro) & puede & ~guia
            if disp.any():
                ok = estimular(disp)
                sg = rng.choice((-1.0, 1.0), S)
                ang = np.abs(rng.normal(p["giro"], p["giro_sd"], S))
                # contra la pared el giro no sirve; hacia afuera lo suelta
                util = ok & ((modo == CAMINA) | (sg == -lado))
                sale = util & (modo == PARED)
                n_salidas += sale
                th = np.where(util, th + sg * ang, th)
                modo = np.where(sale, CAMINA, modo)
                tramo = np.where(util, rng.exponential(p["l_tramo"], S), tramo)
                puede &= ~disp

            if pol >= GUIADA:
                disp = guia & (np.abs(err) > p["banda_muerta"]) & (modo != PAUSA) & puede
                if disp.any():
                    ok = estimular(disp)
                    ang = np.minimum(np.abs(err), np.abs(rng.normal(p["giro"], p["giro_sd"], S)))
                    th = np.where(ok, th + np.sign(err) * ang, th)
                    modo = np.where(ok, CAMINA, modo)
                    tramo = np.where(ok, np.maximum(tramo, 0.3), tramo)

        # ---- regla de regreso: cada t_progreso, si la mochila calcula que no se acercó al
        #      boquete, corrige. En marcha libre gira hacia el boquete; pegado a una pared,
        #      gira hacia afuera para soltarla. Si va acercándose, no se le toca.
        if en_regreso and modo_regreso == REGRESO_INERCIAL and k % n_chk == 0:
            d_est = np.hypot(ex - x_e, ey - y_e)
            sin_avance = (d_ref - d_est) < p.get("d_progreso", 0.10)
            d_ref = d_est
            disp = sin_avance & (modo != PAUSA) & puede
            if disp.any():
                ok = estimular(disp)
                rumbo_casa = np.arctan2(y_e - ey, x_e - ex)
                err_c = np.angle(np.exp(1j * (rumbo_casa - (th + beta))))
                ang = np.minimum(np.abs(err_c), np.abs(rng.normal(p["giro"], p["giro_sd"], S)))
                en_libre = ok & (modo == CAMINA)
                th = np.where(en_libre, th + np.sign(err_c) * ang, th)
                tramo = np.where(en_libre, np.maximum(tramo, 0.3), tramo)
                en_pared = ok & (modo == PARED)
                ang2 = np.abs(rng.normal(p["giro"], p["giro_sd"], S))
                th = np.where(en_pared, th - lado * ang2, th)
                modo = np.where(en_pared, CAMINA, modo)
                tramo = np.where(en_pared, rng.exponential(p["l_tramo"], S), tramo)

        # ---- ruta inversa: el blanco es la última miga de la pila. Cada t_progreso se quitan
        #      las migas ya alcanzadas y, si el insecto no va hacia la siguiente, se corrige.
        if en_regreso and modo_regreso == REGRESO_RUTA and k % n_chk == 0:
            dk = np.hypot(migas[..., 0] - ex[..., None], migas[..., 1] - ey[..., None])
            cerca = (dk < r_miga) & (k_idx < n_migas[..., None])
            primera = np.where(cerca.any(axis=2), cerca.argmax(axis=2), n_migas)
            n_migas = np.minimum(n_migas, np.maximum(primera, 1))
            tx, ty = migas[rr, nn, n_migas - 1, 0], migas[rr, nn, n_migas - 1, 1]
            err_c = np.angle(np.exp(1j * (np.arctan2(ty - ey, tx - ex) - (th + beta))))
            desviado = ((modo == CAMINA) & (np.abs(err_c) > p.get("banda_regreso", 0.6))) | \
                       ((modo == PARED) & (np.abs(err_c) > 2.0))
            disp = desviado & puede
            if disp.any():
                ok = estimular(disp)
                ang = np.minimum(np.abs(err_c), np.abs(rng.normal(p["giro"], p["giro_sd"], S)))
                en_libre = ok & (modo == CAMINA)
                th = np.where(en_libre, th + np.sign(err_c) * ang, th)
                tramo = np.where(en_libre, np.maximum(tramo, 0.3), tramo)
                en_pared = ok & (modo == PARED)
                ang2 = np.abs(rng.normal(p["giro"], p["giro_sd"], S))
                th = np.where(en_pared, th - lado * ang2, th)
                modo = np.where(en_pared, CAMINA, modo)
                tramo = np.where(en_pared, rng.exponential(p["l_tramo"], S), tramo)

        # ---- faro infrarrojo: la luz de una lámpara en el boquete se cuela por los huecos, así
        #      que crece a lo largo del camino libre hacia la salida (no atraviesa el concreto,
        #      como sí hace la radio). El insecto no ve el infrarrojo; la mochila, con un fotodiodo
        #      a cada lado, sabe hacia dónde aumenta y gira hacia allá. Solo funciona mientras la
        #      luz alcanza (alcance_faro, en metros de camino) y la dirección se mide con ruido.
        if en_regreso and modo_regreso == REGRESO_FARO and k % n_chk == 0:
            iyf, ixf = celda(x, y)
            ve_faro = mapa.geo[iyf, ixf] <= p.get("alcance_faro", 1e9)
            rumbo_f = np.arctan2(-mapa.gy[iyf, ixf], -mapa.gx[iyf, ixf]) + rng.normal(0.0, p.get("ruido_faro", 0.5), S)
            err_c = np.angle(np.exp(1j * (rumbo_f - th)))
            desviado = ((modo == CAMINA) & (np.abs(err_c) > p.get("banda_regreso", 0.6))) | \
                       ((modo == PARED) & (np.abs(err_c) > 2.0))
            disp = desviado & ve_faro & puede
            if disp.any():
                ok = estimular(disp)
                ang = np.minimum(np.abs(err_c), np.abs(rng.normal(p["giro"], p["giro_sd"], S)))
                en_libre = ok & (modo == CAMINA)
                th = np.where(en_libre, th + np.sign(err_c) * ang, th)
                tramo = np.where(en_libre, np.maximum(tramo, 0.3), tramo)
                en_pared = ok & (modo == PARED)
                ang2 = np.abs(rng.normal(p["giro"], p["giro_sd"], S))
                th = np.where(en_pared, th - lado * ang2, th)
                modo = np.where(en_pared, CAMINA, modo)
                tramo = np.where(en_pared, rng.exponential(p["l_tramo"], S), tramo)

        if regreso:
            x_prev, y_prev = x.copy(), y.copy()

        # ---- velocidad
        t_impulso = np.maximum(t_impulso - dt, 0.0)
        v = np.where(t_impulso > 0, p["v_impulso"], v_nat)
        paso = v * dt

        # ---- marcha libre: tramo recto; al topar, sigue la pared
        cam = (modo == CAMINA) & activo
        nx, ny = x + paso * np.cos(th), y + paso * np.sin(th)
        ok_xy = es_libre(nx, ny)
        ok_x = es_libre(nx, y)
        ok_y = es_libre(x, ny)
        avanza = cam & ok_xy
        topa = cam & ~ok_xy
        x = np.where(avanza, nx, x)
        y = np.where(avanza, ny, y)
        tramo = np.where(avanza, tramo - paso, tramo)
        # pared en x: avanza en ±y; pared en y: avanza en ±x; rincón: media vuelta
        px = topa & ok_y & ~ok_x
        py = topa & ok_x & ~ok_y
        amb = topa & ~px & ~py
        cx, sy = np.sign(np.cos(th)), np.sign(np.sin(th))
        sy = np.where(sy == 0, 1.0, sy)
        cx = np.where(cx == 0, 1.0, cx)
        th_px = np.where(sy > 0, np.pi / 2, -np.pi / 2)          # rumbo a lo largo de la pared
        th_py = np.where(cx > 0, 0.0, np.pi)
        lado = np.where(px, -cx * sy, lado)                      # pared a la izq. si cruz(h, s) > 0
        lado = np.where(py, cx * sy, lado)
        th = np.where(px, th_px, np.where(py, th_py, th))
        th = np.where(amb, th + np.pi + rng.normal(0, 0.5, S), th)
        modo = np.where(px | py, PARED, modo)

        # ---- seguimiento de pared (regla de la mano)
        par = (modo == PARED) & activo & ~(px | py)
        hx, hy = np.cos(th), np.sin(th)
        sx, sy2 = -lado * hy, lado * hx                          # unitario hacia la pared
        costado = es_libre(x + sx * res, y + sy2 * res)
        frente = es_libre(x + hx * paso + hx * 0.4 * res, y + hy * paso + hy * 0.4 * res)
        ciego = np.maximum(ciego - np.where(par, paso, 0.0), 0.0)
        fin_pared = par & costado & (ciego <= 0)
        rodea = fin_pared & (rng.random(S) < p["p_rodea"])
        suelta = fin_pared & ~rodea
        th = np.where(rodea, th + lado * np.pi / 2, th)          # dobla hacia la pared
        ciego = np.where(rodea, 1.6 * res, ciego)
        modo = np.where(suelta, CAMINA, modo)
        tramo = np.where(suelta, rng.exponential(p["l_tramo"], S), tramo)
        rincon = par & ~fin_pared & ~frente
        th = np.where(rincon, th - lado * np.pi / 2, th)         # rincón: dobla hacia afuera
        hx, hy = np.cos(th), np.sin(th)
        mueve = par & ~suelta & es_libre(x + hx * paso, y + hy * paso)
        x = np.where(mueve, x + hx * paso, x)
        y = np.where(mueve, y + hy * paso, y)
        tramo = np.where(mueve, tramo - paso, tramo)

        # ---- decisiones al final de cada tramo
        decide = (tramo <= 0.0) & (modo != PAUSA) & activo
        if decide.any():
            en_pared = decide & (modo == PARED)
            n_decis_pared += en_pared
            u = rng.random(S)
            para = decide & (u < p["p_stop"])
            sale = en_pared & ~para & (rng.random(S) < p["p_exit"])
            n_salidas += sale
            giro_nat = rng.normal(0.0, p["giro_natural_sd"], S)
            th = np.where(decide & (modo == CAMINA) & ~para, th + giro_nat, th)
            th = np.where(sale, th - lado * np.abs(rng.normal(p["ang_salida"], p["ang_salida_sd"], S)), th)
            modo = np.where(sale, CAMINA, modo)
            previo = np.where(para, modo, previo)
            t_pausa = np.where(para, pausa_nueva() * (1.0 + p["k_refugio"] * (1.0 - luz)), t_pausa)
            n_pausas += para
            modo = np.where(para, PAUSA, modo)
            tramo = np.where(decide, rng.exponential(p["l_tramo"], S), tramo)
            # cerca de la entrada, el nuevo tramo se sesga hacia lo oscuro
            libre_dec = decide & (modo == CAMINA)
            gana = p["k_foto"] * luz
            hx2 = np.cos(th) + gana * mapa.gx[iy, ix]
            hy2 = np.sin(th) + gana * mapa.gy[iy, ix]
            th = np.where(libre_dec, np.arctan2(hy2, hx2), th)

        t_anda += ((modo != PAUSA) & activo) * dt
        t_en_pausa += ((modo == PAUSA) & activo) * dt

        if lam_perdida > 0:
            activo &= rng.random(S) >= lam_perdida * dt

        if regreso:
            # La mochila integra lo caminado con un rumbo que deriva: su estimación se aparta
            # de la posición real en proporción a la distancia recorrida.
            dxr, dyr = x - x_prev, y - y_prev
            beta = beta + rng.normal(0.0, 1.0, S) * sig_beta * np.sqrt(np.hypot(dxr, dyr))
            cb, sb = np.cos(beta), np.sin(beta)
            ex = ex + dxr * cb - dyr * sb
            ey = ey + dxr * sb + dyr * cb
            if ruta and not en_regreso:
                # en la ida se van dejando migas
                ux, uy = migas[rr, nn, n_migas - 1, 0], migas[rr, nn, n_migas - 1, 1]
                for r_, a_ in np.argwhere(np.hypot(ex - ux, ey - uy) >= paso_miga):
                    k_ = int(n_migas[r_, a_])
                    d = np.hypot(migas[r_, a_, :k_, 0] - ex[r_, a_], migas[r_, a_, :k_, 1] - ey[r_, a_])
                    viejas = np.nonzero(d[:max(k_ - 2, 0)] < paso_miga)[0]
                    if viejas.size:
                        k_ = int(viejas[0]) + 1             # lazo cerrado: se olvida la vuelta
                    if k_ < K:
                        migas[r_, a_, k_, 0], migas[r_, a_, k_, 1] = ex[r_, a_], ey[r_, a_]
                        k_ += 1
                    n_migas[r_, a_] = k_
            if en_regreso:
                # El refugio-trampa del boquete recoge al que llega a menos de r_captura
                iyc, ixc = celda(x, y)
                llega = activo & ~capturado & (mapa.geo[iyc, ixc] <= p.get("r_captura", 0.30))
                t_cap = np.where(llega, t - t_regreso, t_cap)
                capturado |= llega
                activo &= ~llega

        # ---- detección: señal sobre el umbral en n cuadros seguidos
        iy, ix = celda(x, y)
        dist = mapa.dist_v[iy, ix]
        rumbo = np.arctan2((vf + 0.5) * res - y, (vc + 0.5) * res - x)
        visible = mapa.vis_v[iy, ix] & (np.abs(np.angle(np.exp(1j * (rumbo - th)))) <= semi_fov)
        senal = np.where(visible, pixeles_calientes(dist, p), 0.0)
        sobre = (senal >= p["n_det"]) & activo
        conf = np.where(sobre, conf + 1, 0)
        hay = (conf >= p["n_confirma"]).any(axis=1) & ~np.isfinite(t_det)
        t_det[hay] = t

        visit[ridx, iy, ix] = True
        if (k + 1) % cada == 0:
            cobertura.append(visit.reshape(R, -1).sum(axis=1) / n_alc)
        if guardar_tray:
            tray.append((x[0].copy(), y[0].copy(), modo[0].copy()))

    return {
        "t_det": t_det,
        "cobertura": np.array(cobertura).T if cobertura else np.zeros((R, 0)),
        "estimulos": n_est,
        "frac_anda": t_anda / np.maximum(t_anda + t_en_pausa, 1e-9),
        "pausa_media": t_en_pausa.sum() / max(n_pausas.sum(), 1.0),
        "p_salida": n_salidas.sum() / max(n_decis_pared.sum(), 1.0),
        "activos_fin": activo.mean(axis=1),
        "hab_fin": hab,
        "tray": tray,
        "visit0": visit[0],
        # fase de regreso (None si no se pidió)
        "t_cap": t_cap if regreso else None,
        "est_regreso": (n_est - n_est_ida) if (regreso and n_est_ida is not None) else None,
        "geo_fin": mapa.geo[celda(x, y)] if regreso else None,
        "err_pos": np.hypot(ex - x, ey - y) if regreso else None,
        "n_migas": n_migas if (regreso and ruta) else None,
    }
