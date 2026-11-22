# captura_klayout.py - Dibuja el GDS final con los colores de capa de sky130A y lo guarda en PNG.
# Se corre con KLayout en modo lote (sin ventana):
#   klayout -zz -r captura_klayout.py -rd gds=<archivo.gds> -rd lyp=<sky130A.lyp> -rd png=<salida.png>
import pya

gds = globals().get("gds")
lyp = globals().get("lyp", "")
png = globals().get("png", "nucleo_biobot.png")
ancho = int(globals().get("ancho", "1600"))
alto = int(globals().get("alto", "1600"))

vista = pya.LayoutView()
vista.load_layout(gds, True)
if lyp:
    vista.load_layer_props(lyp)
# Solo las capas fisicas (difusion, polisilicio, contactos y los cinco metales). Las de
# marcado tapan el dibujo: areaid.standardc (81/4) pinta de magenta todo el nucleo.
# Con -rd todas=1 se dibujan todas las capas.
FISICAS = {(65, 20), (65, 44), (66, 20), (66, 44), (67, 20), (67, 44), (68, 20), (68, 44),
           (69, 20), (69, 44), (70, 20), (70, 44), (71, 20), (71, 44), (72, 20)}
if globals().get("todas", "") == "":
    it = vista.begin_layers()
    while not it.at_end():
        capa = it.current()
        if not capa.has_children():
            capa.visible = (capa.source_layer, capa.source_datatype) in FISICAS
        it.next()
vista.max_hier()
vista.set_config("background-color", "#ffffff")
vista.set_config("grid-visible", "false")
vista.set_config("text-visible", "false")
zona = globals().get("zona", "")   # "x1,y1,x2,y2" en micras para un acercamiento
if zona:
    x1, y1, x2, y2 = (float(v) for v in zona.split(","))
    vista.zoom_box(pya.DBox(x1, y1, x2, y2))
else:
    vista.zoom_fit()
vista.save_image(png, ancho, alto)
print("captura:", png)
