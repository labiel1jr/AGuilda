extends Control
## Retrato procedural de um herói: busto em silhueta na cor do herói,
## detalhe de raça (barba, orelhas, presas, tamanho) e emblema da classe.
## Usado quando o herói não tem "portrait" (imagem) definido em heroes.json.

const SKIN := [Color("#e8c4a0"), Color("#c99a6e"), Color("#a5734d"), Color("#f0d2b4"), Color("#8f5d3b")]

var hero: Dictionary = {}


func setup(h: Dictionary) -> void:
	hero = h
	queue_redraw()


func _draw() -> void:
	if hero.is_empty():
		return
	var s := minf(size.x, size.y)
	var c := size / 2.0
	var col: Color = hero.color
	var skin: Color = SKIN[abs(hash(hero.id)) % SKIN.size()]
	var hair := col.darkened(0.55)
	var race: String = hero.get("race", "")
	var small := race == "Halfling"
	var k := s / 100.0 * (0.88 if small else 1.0)

	# fundo
	draw_circle(c, s * 0.5, col.darkened(0.35))
	draw_circle(c + Vector2(0, -s * 0.08), s * 0.42, col.darkened(0.15))

	# ombros e pescoço
	var base_y := c.y + s * 0.5
	var shoulders := PackedVector2Array([
		Vector2(c.x - 38 * k, base_y), Vector2(c.x - 34 * k, base_y - 18 * k),
		Vector2(c.x - 14 * k, base_y - 26 * k), Vector2(c.x + 14 * k, base_y - 26 * k),
		Vector2(c.x + 34 * k, base_y - 18 * k), Vector2(c.x + 38 * k, base_y)])
	draw_colored_polygon(shoulders, col.darkened(0.05))
	draw_rect(Rect2(c.x - 7 * k, base_y - 34 * k, 14 * k, 12 * k), skin.darkened(0.1))

	# cabeça
	var head := Vector2(c.x, base_y - 50 * k)
	var hr := 17 * k
	if race in ["Meio-elfa", "Meio-elfo", "Elfa", "Elfo"]:
		draw_colored_polygon(PackedVector2Array([head + Vector2(-hr + 2, -2), head + Vector2(-hr - 9 * k, -10 * k), head + Vector2(-hr + 3, 5 * k)]), skin)
		draw_colored_polygon(PackedVector2Array([head + Vector2(hr - 2, -2), head + Vector2(hr + 9 * k, -10 * k), head + Vector2(hr - 3, 5 * k)]), skin)
	draw_circle(head, hr, skin)
	# cabelo
	draw_arc(head + Vector2(0, -2 * k), hr + 1, PI * 1.05, PI * 1.95, 24, hair, 8 * k, true)
	# olhos
	draw_circle(head + Vector2(-6 * k, 0), 1.8 * k, Color("#2a1f14"))
	draw_circle(head + Vector2(6 * k, 0), 1.8 * k, Color("#2a1f14"))
	if race == "Anã" or race == "Anão":
		draw_colored_polygon(PackedVector2Array([head + Vector2(-13 * k, 5 * k), head + Vector2(13 * k, 5 * k), head + Vector2(0, 26 * k)]), hair)
	elif race == "Meio-orc":
		draw_line(head + Vector2(-5 * k, 9 * k), head + Vector2(-5 * k, 5 * k), Color.WHITE, 2 * k)
		draw_line(head + Vector2(5 * k, 9 * k), head + Vector2(5 * k, 5 * k), Color.WHITE, 2 * k)
	else:
		draw_line(head + Vector2(-4 * k, 8 * k), head + Vector2(4 * k, 8 * k), skin.darkened(0.35), 1.5 * k)

	# emblema da classe
	var e := Vector2(c.x + s * 0.3, c.y + s * 0.3)
	draw_circle(e, s * 0.15, Color("#2a1f14"))
	draw_arc(e, s * 0.15, 0, TAU, 32, Color("#d4a94a"), 2.0, true)
	_emblem(hero.get("class", ""), e, s * 0.1, Color("#e8c060"))


func _emblem(cls: String, p: Vector2, r: float, g: Color) -> void:
	match cls:
		"Paladino":
			draw_colored_polygon(PackedVector2Array([p + Vector2(-r * 0.8, -r), p + Vector2(r * 0.8, -r), p + Vector2(r * 0.8, r * 0.1), p + Vector2(0, r), p + Vector2(-r * 0.8, r * 0.1)]), g)
			draw_line(p + Vector2(0, -r * 0.7), p + Vector2(0, r * 0.6), Color("#2a1f14"), 2.0)
			draw_line(p + Vector2(-r * 0.5, -r * 0.2), p + Vector2(r * 0.5, -r * 0.2), Color("#2a1f14"), 2.0)
		"Ladina":
			draw_colored_polygon(PackedVector2Array([p + Vector2(0, -r), p + Vector2(r * 0.25, r * 0.3), p + Vector2(-r * 0.25, r * 0.3)]), g)
			draw_line(p + Vector2(-r * 0.5, r * 0.35), p + Vector2(r * 0.5, r * 0.35), g, 2.0)
			draw_line(p + Vector2(0, r * 0.35), p + Vector2(0, r), g, 2.5)
		"Maga":
			draw_line(p + Vector2(-r * 0.4, r), p + Vector2(r * 0.3, -r * 0.5), g, 2.5)
			draw_circle(p + Vector2(r * 0.4, -r * 0.7), r * 0.35, Color("#9fd0ff"))
		"Guerreira", "Guerreiro":
			draw_line(p + Vector2(-r * 0.8, r * 0.8), p + Vector2(r * 0.8, -r * 0.8), g, 2.5)
			draw_line(p + Vector2(r * 0.8, r * 0.8), p + Vector2(-r * 0.8, -r * 0.8), g, 2.5)
		"Bardo":
			draw_circle(p + Vector2(-r * 0.2, r * 0.3), r * 0.55, g)
			draw_line(p + Vector2(0, r * 0.1), p + Vector2(r * 0.7, -r * 0.9), g, 2.5)
		"Clérigo", "Clériga":
			draw_circle(p, r * 0.45, g)
			for i in 8:
				var a := TAU * i / 8.0
				draw_line(p + Vector2(cos(a), sin(a)) * r * 0.55, p + Vector2(cos(a), sin(a)) * r, g, 1.5)
		_:
			draw_circle(p, r * 0.5, g)
