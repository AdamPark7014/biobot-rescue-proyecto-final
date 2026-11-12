"""Parámetros del modelo, con su origen.

Etiquetas: [F] valor publicado (clave de la fuente entre paréntesis; ver
../investigacion/), [D] decisión de diseño de la mochila, [S] supuesto del modelo que
se explora en el análisis de sensibilidad.

Fuentes: DIR17 Dirafzoon et al. 2017 (póster ICASSP); TRA24 Tran-Ngoc et al. 2024
(arXiv 2406.03713, Extended Data Table 1); TRA23 Tran-Ngoc et al. 2023 (Adv. Intell.
Syst.); ERI15 Erickson et al. 2015 (PLoS ONE); LIN23 Lin et al. 2023 (npj Flex.
Electron.); LIN25 Lin et al. 2025 (Nat. Commun.); MA23 Ma et al. 2023 (Cyborg Bionic
Syst.); SAN15 Sanchez et al. 2015 (J. R. Soc. Interface); JEA03 Jeanson et al. 2003.
"""

BASE = dict(
    dt=0.5,                # s, paso de simulación

    # --- marcha natural (modelo de DIR17 con los valores de TRA24)
    v_natural=0.0194,      # m/s   1.94 cm/s                                   [F] DIR17
    v_natural_sd=0.0029,   # m/s   entre individuos                            [F] DIR17
    l_tramo=0.176,         # m     longitud característica del tramo recto     [F] DIR17
    p_stop=0.211,          # prob. de pausa al terminar un tramo               [F] DIR17
    t_pausa=36.8,          # s     duración media de la pausa                  [F] DIR17
    t_pausa_sd=24.1,       # s                                                 [F] DIR17
    p_exit=0.005,          # prob. de soltarse de la pared por decisión        [F] DIR17
    giro_natural_sd=0.35,  # rad   giro entre tramos (casi todo en ±40°)       [F] DIR17 (gráfica)
    ang_salida=0.64,       # rad   ángulo al dejar la pared (36.6°)            [F] JEA03 (otra especie)
    ang_salida_sd=0.30,    # rad                                               [S]
    p_rodea=0.80,          # prob. de doblar la esquina pegado a la pared      [S]
    k_foto=1.0,            # sesgo hacia lo oscuro cerca de la entrada         [S]
    k_refugio=0.0,         # alargamiento de la pausa a oscuras                [S]
    pen_carga=0.0,         # fracción de velocidad perdida por la carga        [S]
    tasa_perdida=0.0,      # 1/h   insectos que dejan de servir                [S]

    # --- estímulo y respuesta
    p_resp=0.78,           # prob. de obedecer un estímulo (80.7 % giro, 74 % avance)  [F] LIN23
    frac_responde=1.0,     # fracción de individuos que responden (0.56 implantado)    [F] ERI15
    giro=0.90,             # rad   giro por estímulo (38° a 90° publicados)    [F] LIN23, LIN25, MA23
    giro_sd=0.40,          # rad                                               [F] LIN23
    v_impulso=0.05,        # m/s   marcha tras un estímulo de avance           [F] TRA24, ERI15
    t_impulso=4.0,         # s     duración del impulso (15 a 25 cm)           [F] ERI15
    alfa_hab=0.01,         # habituación por estímulo (0.04 a 0.08 con pulso unipolar; ~0 con
                           # bifásico o con luz)                               [F] ERI15, MA23
    tau_rec=600.0,         # s     recuperación con descanso (5 a 20 min)      [F] SAN15

    # --- política a bordo
    t_espera=15.0,         # s quieto antes del primer estímulo de avance      [D]
    retro_max=3,           # la espera se duplica hasta 2^3 si no responde     [D]
    t_refractario=10.0,    # s mínimos entre estímulos                         [D] como MA23
    t_giro_medio=51.2,     # s entre giros al azar (9 bits del LFSR a 10 Hz)   [D]
    banda_muerta=0.26,     # rad   error de rumbo tolerado al acercarse (15°)  [D] TRA23 usa 20-25°
    tau_cuenta=600.0,      # s     fuga de la cuenta de estímulos              [D]
    cuenta_lim=12.0,       # estímulos acumulados que obligan a descansar      [D]

    # --- detección térmica: matriz de 32 x 32 con campo de 90° (Heimann HTPA32x32)
    un_pixel=False,
    n_pixeles=1024,        #                                                   [F] TRA23
    ifov_deg=90.0 / 32,    # ° por píxel                                       [F] TRA23
    fov_total_deg=90.0,    #                                                   [F] TRA23
    area_blanco=0.03,      # m²    piel expuesta a la vista (una cara)         [S]
    n_pre=2.0,             # píxeles calientes para empezar a acercarse        [D]
    n_det=8.0,             # píxeles calientes para declarar detección         [F] TRA24 (0.8 % de la imagen)
    n_confirma=4,          # cuadros seguidos sobre el umbral                  [D]
)


def con(**cambios):
    """Copia de BASE con los cambios indicados."""
    p = dict(BASE)
    p.update(cambios)
    return p


# Termopila de un solo píxel con campo de 90° (MLX90614BAA), como en la propuesta
# inicial. La "señal" es la fracción del campo que llena el blanco: con piel 9 °C
# sobre el fondo, 0.055 equivale a un contraste leído de 0.5 °C.
UN_PIXEL = dict(un_pixel=True, fov_total_deg=90.0, n_pre=0.03, n_det=0.055)

# Matriz de 8 x 8 con campo de 60° (Panasonic AMG8833)
MATRIZ_8X8 = dict(un_pixel=False, n_pixeles=64, ifov_deg=60.0 / 8, fov_total_deg=60.0, n_pre=1.0, n_det=2.0)

# Estímulo eléctrico unipolar: se habitúa rápido. Con alfa = 0.09 y tau = 600 s el modelo
# reproduce los tres datos publicados: queda 46 % tras 10 estímulos cada 15 s (MA23 mide
# 43 %), 71 % cada 120 s (MA23: 66 %) y 22 % tras 40 ensayos de 15 s (ERI15: 20 %).
UNIPOLAR = dict(alfa_hab=0.09)
