import os
import re

import pya

FISICAS = {
    (65, 20), (65, 44),
    (66, 20), (66, 44),
    (67, 20), (67, 44),
    (68, 20), (68, 44),
    (69, 20), (69, 44),
    (70, 20), (70, 44),
    (71, 20), (71, 44),
    (72, 20),
}

app = pya.Application.instance()
vista = app.main_window().current_view()

it = vista.begin_layers()
while not it.at_end():
    capa = it.current()
    if not capa.has_children():
        capa.visible = (capa.source_layer, capa.source_datatype) in FISICAS
    it.next()

vista.max_hier()
vista.set_config("text-visible", "false")

# medidas del dado
def regla(x1, y1, x2, y2, texto):
    a = pya.Annotation()
    a.p1, a.p2 = pya.DPoint(x1, y1), pya.DPoint(x2, y2)
    a.fmt = texto
    a.style = pya.Annotation.StyleArrowBoth
    a.outline = pya.Annotation.OutlineDiag
    vista.insert_annotation(a)


# area y corriente
def datos():
    ruta = os.path.join(os.path.dirname(os.path.abspath(globals().get("__file__", "ver_layout.py"))), "resultados", "area_y_corriente.txt")
    if not os.path.exists(ruta):
        ruta = os.path.join("resultados", "area_y_corriente.txt")
    if not os.path.exists(ruta):
        return ""
    t = open(ruta, encoding="utf-8").read()
    area = re.search(r"= ([\d.]+) mm2", t).group(1)
    esp = re.search(r"En espera.*?([\d.]+) mA", t).group(1)
    omi = re.search(r"omisi.n.*?([\d.]+) mA", t).group(1)
    return f"Area {area} mm2   |   Corriente a 1.8 V y 50 MHz: {esp} mA en espera, {omi} mA por omision"


vista.clear_annotations()
caja = vista.active_cellview().cell.dbbox()
regla(caja.left, caja.bottom - 8, caja.right, caja.bottom - 8, "%.1f um" % caja.width())
regla(caja.left - 8, caja.bottom, caja.left - 8, caja.top, "%.1f um" % caja.height())
aviso = datos()
if aviso:
    regla(caja.left, caja.top + 10, caja.right, caja.top + 10, aviso)
    app.main_window().message(aviso, 0)

zona = globals().get("zona", "")
if zona:
    x1, y1, x2, y2 = (float(v) for v in zona.split(","))
    vista.zoom_box(pya.DBox(x1, y1, x2, y2))
else:
    vista.zoom_box(caja.enlarged(24, 24))

app.exec_()
