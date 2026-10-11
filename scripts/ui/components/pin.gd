extends Control
## Prego/tachinha desenhado no topo de um cartaz do quadro de avisos (até chegar a arte).
## Ocupa o retângulo do pai e desenha só o prego no alto, centralizado.

var offset_x := 0.0   # deslocamento horizontal (cada cartaz pregado num ponto um pouco diferente)
static var _nail: Texture2D = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)


func _draw() -> void:
	var c := Vector2(size.x / 2.0 + offset_x, -8.0)   # na margem de cima do papel (fora da área de texto)
	if _nail == null and ResourceLoader.exists("res://art/guild/prego_ferro.png"):
		_nail = load("res://art/guild/prego_ferro.png")
	if _nail != null:
		draw_texture_rect(_nail, Rect2(c - Vector2(12, 14), Vector2(24, 24)), false)
		return
	draw_circle(c + Vector2(1.5, 2.0), 6.0, Color(0, 0, 0, 0.35))   # sombra
	draw_circle(c, 6.0, Color("#3a3530"))
	draw_circle(c, 4.0, Color("#6e655a"))
	draw_circle(c + Vector2(-1.5, -1.5), 1.6, Color("#b8ad9c"))
