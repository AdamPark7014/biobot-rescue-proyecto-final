import pya

gds = globals().get("gds")
lyp = globals().get("lyp")
png = globals().get("png", "chip.png")
zona = globals().get("zona", "")

vista = pya.LayoutView()
vista.load_layout(gds, True)
vista.load_layer_props(lyp)
vista.max_hier()

COBRE = {
    (65, 20): 0x2E8B57,
    (66, 20): 0xE04848,
    (67, 20): 0xD9A441,
    (68, 20): 0x4C7DFF,
    (69, 20): 0xC65BE0,
    (70, 20): 0x3CC6C6,
    (71, 20): 0xB87333,
    (72, 20): 0xD4AF37,
    (67, 44): 0xE8E8E8, (68, 44): 0xE8E8E8, (69, 44): 0xE8E8E8,
    (70, 44): 0xE8E8E8, (71, 44): 0xE8E8E8, (66, 44): 0xE8E8E8,
    (71, 16): 0xB87333, (72, 16): 0xD4AF37,
}
it = vista.begin_layers()
while not it.at_end():
    capa = it.current()
    if not capa.has_children():
        clave = (capa.source_layer, capa.source_datatype)
        if clave in COBRE:
            capa.visible = True
            capa.fill_color = COBRE[clave]
            capa.frame_color = COBRE[clave]
            capa.dither_pattern = 0
        else:
            capa.visible = False
    it.next()

vista.set_config("background-color", "#0d1117")
vista.set_config("grid-visible", "false")
vista.set_config("text-visible", "false")
if zona:
    x1, y1, x2, y2 = (float(v) for v in zona.split(","))
    vista.zoom_box(pya.DBox(x1, y1, x2, y2))
else:
    vista.zoom_fit()
vista.save_image(png, 1600, 1600)
print("render:", png)
