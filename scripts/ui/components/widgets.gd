class_name Widgets
## Componentes que leem o estado do jogo: retratos, cabeçalho de herói, cartaz de inimigo, chip de estresse.
## Funções estáticas sobre a tela principal (ui: GuildUI, a cena main).


## Cartazes de todos os inimigos da missão que têm imagem (chefe primeiro).
static func enemy_textures(ui: GuildUI, m: Dictionary) -> Array:
	var out := []
	for eid in m.get("enemies", []):
		var path := "res://art/enemies/%s.png" % eid
		if ResourceLoader.exists(path):
			out.append(load(path))
	return out


## Primeiro inimigo da missão que tem imagem (res://art/enemies/<id>.png), ou null.
static func enemy_texture(ui: GuildUI, m: Dictionary) -> Texture2D:
	for eid in m.get("enemies", []):
		var path := "res://art/enemies/%s.png" % eid
		if ResourceLoader.exists(path):
			return load(path)
	return null


## Cartaz do inimigo; "defeated" risca com um X de tinta vermelha.
static func enemy_poster(ui: GuildUI, m: Dictionary, px: int, defeated: bool = false, paint_delay: float = 0.0) -> Control:
	var tex := Widgets.enemy_texture(ui, m)
	if tex == null:
		return null
	var tr := TextureRect.new()
	tr.texture = tex
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	tr.custom_minimum_size = Vector2(px, px)
	tr.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if defeated:
		var ink := Color("#a8443c", 0.9)
		for pts in [[Vector2(0.18, 0.2), Vector2(0.82, 0.8)], [Vector2(0.82, 0.2), Vector2(0.18, 0.8)]]:
			var ln := Line2D.new()
			ln.points = PackedVector2Array([pts[0] * px, pts[1] * px])
			ln.width = max(3.0, px / 14.0)
			ln.default_color = ink
			ln.begin_cap_mode = Line2D.LINE_CAP_ROUND
			ln.end_cap_mode = Line2D.LINE_CAP_ROUND
			tr.add_child(ln)
			if paint_delay > 0.0:
				var a: Vector2 = pts[0] * px
				var b: Vector2 = pts[1] * px
				ln.points = PackedVector2Array([a, a])
				var ltw := ln.create_tween()
				ltw.tween_interval(paint_delay + (0.18 if pts[0].x > 0.5 else 0.0))
				ltw.tween_method(func(k: float): ln.points = PackedVector2Array([a, a.lerp(b, k)]), 0.0, 1.0, 0.18)
	return tr


## Cabeçalho do Quadro de Relações: retrato + nome (coluna = empilhado, linha = lado a lado).
## Estresse e condição (aflição/virtude) em um rótulo curto, com detalhes no tooltip.
static func stress_chip(ui: GuildUI, h: Dictionary) -> Control:
	var st := int(h.get("stress", 0))
	var mx := int(ui.gs.traits_data.stress_max)
	var cond: Dictionary = Mind.condition_info(ui.gs, h)
	var txt := "Estr %d/%d" % [st, mx]
	var col := GuildUI.C_MUTED if st < mx / 2 else (GuildUI.C_GOLD if st < mx else GuildUI.C_BAD)
	if not cond.is_empty():
		var virtue: bool = h.condition_kind == "virtude"
		txt += ("  ✦ " if virtue else "  ✖ ") + cond.name
		col = GuildUI.C_GOOD if virtue else GuildUI.C_BAD
	var l := UIKit.label(txt, 13, col)
	var tip := "Estresse %d/%d: no máximo, o herói testa a vontade (virtude ou aflição)." % [st, mx]
	if not cond.is_empty():
		tip += "\n%s — %s" % [cond.name, cond.desc]
	for tid in h.get("traits", []):
		var ti: Dictionary = Mind.trait_info(ui.gs, tid)
		tip += "\n%s %s — %s" %["+" if ti.positive else "−", ti.name, ti.desc]
	l.tooltip_text = tip
	l.mouse_filter = Control.MOUSE_FILTER_STOP
	return l


static func hero_header(ui: GuildUI, id: String, column: bool) -> Control:
	var h: Dictionary = ui.gs.heroes[id]
	var p := UIKit.panel(GuildUI.C_PANEL)
	p.tooltip_text = "%s — %s" % [h.name, h.archetype]
	var box: BoxContainer = VBoxContainer.new() if column else HBoxContainer.new()
	box.add_theme_constant_override("separation", 2 if column else 8)
	if column:
		box.alignment = BoxContainer.ALIGNMENT_CENTER
	p.add_child(box)
	var por := Widgets.portrait(ui, h, 44)
	por.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if column:
		por.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(por)
	var l := UIKit.label(h.name, 13, h.color.lightened(0.25))
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if column:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(l)
	p.custom_minimum_size = Vector2(96, 0) if column else Vector2(120, 52)
	return p


static func portrait(ui: GuildUI, h: Dictionary, px: int) -> Control:
	if h.get("portrait", "") != "" and ResourceLoader.exists(h.portrait):
		var tr := TextureRect.new()
		tr.texture = load(h.portrait)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		tr.custom_minimum_size = Vector2(px, px)
		tr.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		return tr
	var p = GuildUI.Portrait.new()
	p.custom_minimum_size = Vector2(px, px)
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	p.setup(h)
	return p
