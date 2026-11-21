"""Tabla de distancia estimada a partir de los píxeles calientes, con el mismo modelo de mancha
que hdl/insecto_sim.v y hdl/tri_escena.v (radio al cuadrado por tramos de 64 mm).

Uso: python tabla_rango.py
Imprime cuántos píxeles calientes ve la matriz de 8x8 según la distancia (mancha centrada) y la
tabla inversa que usa la mochila trianguladora para estimar a qué distancia está la persona.
"""
RADIO2 = [1023, 957, 344, 176, 106, 71, 51, 38, 30, 24, 20, 16, 14, 12, 10, 9, 8, 7, 6, 6, 5, 5,
          4, 4, 4, 3, 3, 3, 3, 2, 2, 2, 2, 2, 2, 2, 2, 2]


def pixeles(dist_mm, rumbo_q=0):
    tramo = dist_mm >> 6
    r2 = RADIO2[tramo] if tramo < len(RADIO2) else 1
    cx, cy = 16 + rumbo_q, 16
    n = 0
    for fila in range(8):
        for col in range(8):
            dx, dy = 4 * col + 2 - cx, 4 * fila + 2 - cy
            n += dx * dx + dy * dy <= r2
    return n


if __name__ == "__main__":
    print("dist_mm  pixeles (centrada)  pixeles (rumbo +2)")
    filas = []
    for d in range(64, 2400, 64):
        filas.append((d, pixeles(d), pixeles(d, 2)))
        print("%6d %10d %16d" % filas[-1])
    # Tabla inversa: para cada umbral de pixeles, la distancia media de los tramos que lo dan
    print("\nUmbral -> distancia estimada (mm, y en 1/64 m)")
    umbrales = [40, 24, 16, 12, 8, 6, 4, 3, 2, 1]
    previo = 10 ** 9
    for u in umbrales:
        ds = [d + 32 for d, n, _ in filas if u <= n < previo]
        if ds:
            med = sum(ds) / len(ds)
            print("n >= %2d : %5.0f mm  -> %3d" % (u, med, round(med * 64 / 1000)))
        previo = u
