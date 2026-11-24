import os
import random

# parámetros
COLS, N_PIX = 8, 64
T_MIN, T_MAX, DELTA = 112, 152, 8
COL_IZQ, COL_DER = 3, 5
N_PRE, N_DET, N_CONF = 2, 8, 4
U_ACT, N_QUIETO = 8, 10
T_ESPERA, RETRO_MAX, T_REF, T_OBS, T_EST, T_PERD = 150, 3, 100, 30, 5, 50
T_FUGA, LIM, T_BALIZA = 23, 3072, 50
SEMILLA = 0xACE1

REPOSO, EXPLORAR, REACTIVAR, REORIENTAR, ACERCAR, CONFIRMAR, ALERTAR, DESCANSO = range(8)
NOMBRE = ["REPOSO", "EXPLORAR", "REACTIVAR", "REORIENTAR", "ACERCAR", "CONFIRMAR", "ALERTAR", "DESCANSO"]
C_AVANCE, C_IZQ, C_DER = 0, 1, 2


class Nucleo:
    def __init__(self):
        self.reset()

    def reset(self):
        # ventana_termica
        self.fondo = 255
        self.n_cal = 0
        self.lado = 0
        # media_movil4
        self.m = [0, 0, 0, 0]
        self.seguidos = 0
        self.cnt_q = 0
        self.lfsr = SEMILLA
        # fsm_politica
        self.estado = REPOSO
        self.canal = C_AVANCE
        self.alerta = 0
        self.cuenta = 0
        self.n_est = 0
        self.cnt_quieto = 0
        self.retro = 0
        self.t_ref = 0
        self.t_obs = 0
        self.t_perd = 0
        self.div_fuga = 0
        self.cnt_baliza = 0

    @property
    def n_fil(self):
        return sum(self.m) >> 2

    def _ventana(self, pix):
        cal = izq = der = suma = 0
        for i, t in enumerate(pix):
            col = i % COLS
            caliente = (T_MIN <= t <= T_MAX) and (t >= self.fondo + DELTA)
            cal += caliente
            izq += caliente and col < COL_IZQ
            der += caliente and col >= COL_DER
            suma += t
        cen = cal - izq - der
        if cal == 0:
            lado = 0
        elif izq > der and izq >= cen:
            lado = 1
        elif der > izq and der >= cen:
            lado = 2
        else:
            lado = 0
        self.n_cal, self.lado, self.fondo = cal, lado, suma >> 6

    def cuadro(self, pix, actividad, habilita=1):
        # procesa un cuadro
        assert len(pix) == N_PIX
        self._ventana(pix)

        n_fil = self.n_fil
        pre, sobre = n_fil >= N_PRE, n_fil >= N_DET
        confirmado = self.seguidos >= N_CONF
        quieto = self.cnt_q >= N_QUIETO
        azar = self.lfsr
        lado = self.lado
        est = self.estado

        espera = (T_ESPERA << self.retro) & 0xFFFF
        espero = self.cnt_quieto >= espera
        libre = self.t_ref == 0
        puede = libre and self.cuenta < LIM
        toca = self.div_fuga == T_FUGA - 1
        alta = self.cuenta >> 8
        fuga = alta if alta else (1 if self.cuenta else 0)

        dispara, canal_n, est_n = False, self.canal, est
        if est == REPOSO:
            if habilita:
                est_n = EXPLORAR
        elif est == EXPLORAR:
            if pre:
                est_n = ACERCAR
            elif self.cuenta >= LIM:
                est_n = DESCANSO
            elif quieto and espero and libre:
                dispara, canal_n, est_n = True, C_AVANCE, REACTIVAR
            elif (not quieto) and (azar & 0x1FF) == 0 and libre:
                dispara, canal_n, est_n = True, (C_DER if (azar >> 9) & 1 else C_IZQ), REORIENTAR
        elif est == REACTIVAR:
            if (not quieto) or self.t_obs == 0:
                est_n = EXPLORAR
        elif est == REORIENTAR:
            if self.t_obs == 0:
                est_n = EXPLORAR
        elif est == ACERCAR:
            if sobre:
                est_n = CONFIRMAR
            elif (not pre) and self.t_perd == 0:
                est_n = EXPLORAR
            elif pre and puede:
                if quieto:
                    dispara, canal_n = True, C_AVANCE
                elif lado == 1:
                    dispara, canal_n = True, C_IZQ
                elif lado == 2:
                    dispara, canal_n = True, C_DER
        elif est == CONFIRMAR:
            if confirmado:
                est_n = ALERTAR
            elif not sobre:
                est_n = ACERCAR
        elif est == ALERTAR:
            est_n = ALERTAR
        elif est == DESCANSO:
            if pre:
                est_n = ACERCAR
            elif self.cuenta < LIM:
                est_n = EXPLORAR

        # escritura de registros
        if (not quieto) or (est == REACTIVAR and self.t_obs == 0):
            cnt_quieto = 0
        elif self.cnt_quieto != 0x1FFF:
            cnt_quieto = self.cnt_quieto + 1
        else:
            cnt_quieto = self.cnt_quieto
        retro = self.retro
        if est == REACTIVAR:
            if not quieto:
                retro = 0
            elif self.t_obs == 0 and self.retro != RETRO_MAX:
                retro = self.retro + 1
        t_ref = T_REF if dispara else (self.t_ref - 1 if self.t_ref else 0)
        t_obs = (T_OBS if canal_n == C_AVANCE else T_EST) if dispara else (self.t_obs - 1 if self.t_obs else 0)
        if est != ACERCAR or pre:
            t_perd = T_PERD
        else:
            t_perd = self.t_perd - 1 if self.t_perd else 0
        div_fuga = 0 if toca else self.div_fuga + 1
        cuenta, n_est = self.cuenta, self.n_est
        if dispara:
            n_est = (n_est + 1) & 0xFFFF
            cuenta = (cuenta - (fuga if toca else 0) + 256) & 0xFFFF
        elif toca:
            cuenta -= fuga
        baliza = 0
        if est_n == ALERTAR:
            if self.cnt_baliza == 0:
                baliza, cnt_baliza = 1, T_BALIZA - 1
            else:
                cnt_baliza = self.cnt_baliza - 1
        else:
            cnt_baliza = 0

        # media
        self.m = [self.n_cal] + self.m[:3]
        self.seguidos = 0 if not sobre else min(self.seguidos + 1, 15)
        self.cnt_q = 0 if actividad >= U_ACT else min(self.cnt_q + 1, 15)
        bit = (azar ^ (azar >> 2) ^ (azar >> 3) ^ (azar >> 5)) & 1
        self.lfsr = (bit << 15) | (azar >> 1)

        self.estado, self.canal, self.alerta = est_n, canal_n, int(est_n == ALERTAR)
        self.cnt_quieto, self.retro = cnt_quieto, retro
        self.t_ref, self.t_obs, self.t_perd = t_ref, t_obs, t_perd
        self.div_fuga, self.cuenta, self.n_est, self.cnt_baliza = div_fuga, cuenta, n_est, cnt_baliza
        return {"estado": est_n, "disparo": int(dispara), "canal": canal_n, "alerta": self.alerta,
                "n_fil": self.n_fil, "cuenta": cuenta, "n_est": n_est, "baliza": baliza}


# escenarios
def cuadro_sintetico(rng, ambiente, n_cal=0, lado="centro", t_blanco=132, ruido=1):
    # cuadro de 8 x 8
    pix = [max(0, min(255, ambiente + rng.randint(-ruido, ruido))) for _ in range(N_PIX)]
    cols = {"izquierda": [0, 1, 2], "centro": [3, 4], "derecha": [5, 6, 7], "todo": list(range(8))}[lado]
    celdas = [(f, c) for f in range(8) for c in cols]
    rng.shuffle(celdas)
    for f, c in celdas[:n_cal]:
        pix[f * COLS + c] = max(0, min(255, t_blanco + rng.randint(-2, 2)))
    return pix


def escenarios(semilla=2026):
    rng = random.Random(semilla)
    v = []

    def tramo(n, ambiente=88, activo=True, n_cal=0, lado="centro", t_blanco=132, reinicia=False):
        for i in range(n):
            act = rng.randint(20, 70) if activo else rng.randint(0, 5)
            v.append((int(reinicia and i == 0), 1, act, cuadro_sintetico(rng, ambiente, n_cal, lado, t_blanco)))

    # A
    tramo(40, reinicia=True)
    for _ in range(16):
        tramo(170, activo=False)
        tramo(rng.randint(25, 60), activo=True)
    tramo(2600, activo=False)
    tramo(1500, activo=True)
    # B
    escenarios.inicio_b = len(v)
    tramo(60, reinicia=True)
    tramo(140, n_cal=3, lado="izquierda")
    tramo(70)
    tramo(120, n_cal=4, lado="derecha")
    tramo(12, n_cal=12, lado="centro")
    tramo(40, n_cal=3, lado="centro", activo=False)
    tramo(30, n_cal=14, lado="centro")
    tramo(160, n_cal=14, lado="centro")
    # C
    tramo(80, ambiente=120, reinicia=True)
    tramo(60, ambiente=120, n_cal=10, t_blanco=190)
    tramo(60, ambiente=120, n_cal=10, t_blanco=138, lado="derecha")
    tramo(60, ambiente=150, n_cal=10, t_blanco=150)
    # D
    v.append((1, 1, 30, cuadro_sintetico(rng, 88)))
    for _ in range(3000):
        lado = rng.choice(["izquierda", "centro", "derecha", "todo"])
        n = rng.choice([0, 0, 0, 1, 2, 3, 5, 9, 16])
        v.append((int(rng.random() < 0.01), int(rng.random() < 0.95),
                  rng.choice([0, 2, 4, 30, 60, 255]) if rng.random() < 0.3 else rng.randint(0, 80),
                  cuadro_sintetico(rng, rng.choice([80, 88, 100, 120]), n, lado, rng.choice([120, 132, 140, 156]))))
    return v


def generar_vectores(carpeta):
    nuc = Nucleo()
    vec = escenarios()
    visitas = [0] * 8
    with open(os.path.join(carpeta, "vectores.hex"), "w") as fv, \
            open(os.path.join(carpeta, "esperado.hex"), "w") as fe:
        for reinicia, hab, act, pix in vec:
            if reinicia:
                nuc.reset()
            r = nuc.cuadro(pix, act, hab)
            visitas[r["estado"]] += 1
            fv.write("%02x%02x%s\n" % ((hab << 1) | reinicia, act, "".join("%02x" % p for p in pix)))
            fe.write("%x%x%x%x%02x%04x%04x\n" % (r["estado"], r["disparo"], r["canal"], r["alerta"],
                                               r["n_fil"], r["cuenta"], r["n_est"]))
    with open(os.path.join(carpeta, "casos.vh"), "w") as fc:
        print("localparam integer N_VEC    = %d;" % len(vec), file=fc)
        print("localparam integer INICIO_B = %d;" % escenarios.inicio_b, file=fc)
    return len(vec), visitas, nuc


if __name__ == "__main__":
    aqui = os.path.dirname(os.path.abspath(__file__))
    n, visitas, _ = generar_vectores(os.path.join(aqui, "..", "sim"))
    print("cuadros:", n)
    for nombre, k in zip(NOMBRE, visitas):
        print("  %-10s %6d" % (nombre, k))
