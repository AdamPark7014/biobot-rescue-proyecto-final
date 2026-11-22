# ver_layout.py - Abre el GDS en la ventana de KLayout dejando a la vista solo las capas
# fisicas del chip: difusion, polisilicio, contactos y los cinco metales. Las capas de
# marcado (areaid, implantes, pozos, pines y etiquetas) quedan apagadas en la lista
# "Layers" y se encienden con doble clic. Sin este filtro, el marcador de zona de celdas
# estandar (areaid.standardc, 81/4) pinta todo el nucleo de magenta y tapa el diseno.
#   klayout -l <sky130A.lyp> <archivo.gds> -r ver_layout.py [-rd zona=x1,y1,x2,y2]
import pya

FISICAS = {
    (65, 20), (65, 44),            # difusion y tomas de pozo
    (66, 20), (66, 44),            # polisilicio y contactos
    (67, 20), (67, 44),            # interconexion local (li1) y contactos a metal 1
    (68, 20), (68, 44),            # metal 1 y via
    (69, 20), (69, 44),            # metal 2 y via2
    (70, 20), (70, 44),            # metal 3 y via3
    (71, 20), (71, 44),            # metal 4 y via4
    (72, 20),                      # metal 5
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

zona = globals().get("zona", "")   # "x1,y1,x2,y2" en micras para abrir con un acercamiento
if zona:
    x1, y1, x2, y2 = (float(v) for v in zona.split(","))
    vista.zoom_box(pya.DBox(x1, y1, x2, y2))
else:
    vista.zoom_fit()

app.exec_()   # deja la ventana abierta: con -r, KLayout saldria al terminar el script
