extends Control
## Selo de cera do despacho, desenhado por código (até chegar a arte ui_selo_despachar).

const C_WAX := Color("#a8443c")
const C_WAX_DARK := Color("#7a2e28")
const C_WAX_LIGHT := Color("#c8645a")


func _draw() -> void:
	var c := size / 2.0
	var r := minf(size.x, size.y) * 0.42
	# borda irregular de lacre escorrido
	var pts := PackedVector2Array()
	for i in 28:
		var a := TAU * i / 28.0
		var k := 1.0 + 0.08 * sin(a * 5.0) + 0.05 * sin(a * 11.0 + 1.3)
		pts.append(c + Vector2(cos(a), sin(a)) * r * k)
	draw_colored_polygon(pts, C_WAX_DARK)
	draw_circle(c, r * 0.86, C_WAX)
	draw_arc(c, r * 0.72, 0, TAU, 40, C_WAX_DARK, 3.0, true)
	draw_arc(c + Vector2(-2, -2), r * 0.8, PI * 1.05, PI * 1.6, 12, Color(C_WAX_LIGHT, 0.8), 3.0, true)
	# corvo estilizado: corpo, asas e bico
	var s := r * 0.5
	var body := PackedVector2Array([c + Vector2(-0.15, 0.35) * s, c + Vector2(0.35, 0.05) * s, c + Vector2(0.55, -0.2) * s, c + Vector2(0.85, -0.18) * s,
		c + Vector2(0.55, -0.35) * s, c + Vector2(0.2, -0.3) * s, c + Vector2(-0.6, 0.0) * s, c + Vector2(-0.9, 0.4) * s, c + Vector2(-0.45, 0.3) * s])
	draw_colored_polygon(body, C_WAX_DARK)
	var wing := PackedVector2Array([c + Vector2(-0.3, -0.05) * s, c + Vector2(-0.1, -0.85) * s, c + Vector2(0.25, -0.25) * s])
	draw_colored_polygon(wing, C_WAX_DARK)
