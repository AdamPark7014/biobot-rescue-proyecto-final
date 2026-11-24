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

zona = globals().get("zona", "")
if zona:
    x1, y1, x2, y2 = (float(v) for v in zona.split(","))
    vista.zoom_box(pya.DBox(x1, y1, x2, y2))
else:
    vista.zoom_fit()

app.exec_()
