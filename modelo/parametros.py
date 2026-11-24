BASE = dict(
    dt=0.5,

    # marcha natural
    v_natural=0.0194,
    v_natural_sd=0.0029,
    l_tramo=0.176,
    p_stop=0.211,
    t_pausa=36.8,
    t_pausa_sd=24.1,
    p_exit=0.005,
    giro_natural_sd=0.35,
    ang_salida=0.64,
    ang_salida_sd=0.30,
    p_rodea=0.80,
    k_foto=1.0,
    k_refugio=0.0,
    pen_carga=0.0,
    tasa_perdida=0.0,

    # estímulo y respuesta
    p_resp=0.78,
    frac_responde=1.0,
    giro=0.90,
    giro_sd=0.40,
    v_impulso=0.05,
    t_impulso=4.0,
    alfa_hab=0.01,
    tau_rec=600.0,

    # política a bordo
    t_espera=15.0,
    retro_max=3,
    t_refractario=10.0,
    t_giro_medio=51.2,
    banda_muerta=0.26,
    tau_cuenta=600.0,
    cuenta_lim=12.0,

    # detección térmica
    un_pixel=False,
    n_pixeles=1024,
    ifov_deg=90.0 / 32,
    fov_total_deg=90.0,
    area_blanco=0.03,
    n_pre=2.0,
    n_det=8.0,
    n_confirma=4,
)


def con(**cambios):
    p = dict(BASE)
    p.update(cambios)
    return p


UN_PIXEL = dict(un_pixel=True, fov_total_deg=90.0, n_pre=0.03, n_det=0.055)

MATRIZ_8X8 = dict(un_pixel=False, n_pixeles=64, ifov_deg=60.0 / 8, fov_total_deg=60.0, n_pre=1.0, n_det=2.0)

# estímulo eléctrico unipolar
UNIPOLAR = dict(alfa_hab=0.09)
