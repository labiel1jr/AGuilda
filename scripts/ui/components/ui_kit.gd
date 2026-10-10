class_name UIKit
## Peças básicas de interface (rótulos, painéis, botões, ícones, cores de estado). Sem estado.
## Funções estáticas.


## Textura se existir (arte entregue), senão null.
static func tex(path: String) -> Texture2D:
	return load(path) if ResourceLoader.exists(path) else null


## Ícone do item (res://art/items/<id>.png).
static func item_tex(iid: String) -> Texture2D:
	return UIKit.tex("res://art/items/%s.png" % iid) if iid != "" else null


static func icon(tex: Texture2D, px: int) -> TextureRect:
	var tr := TextureRect.new()
	tr.texture = tex
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	tr.custom_minimum_size = Vector2(px, px)
	tr.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return tr


## Põe um ícone de textura num botão (tamanho máximo em px).
static func button_icon(b: Button, tex: Texture2D, px: int) -> void:
	if tex == null:
		return
	b.icon = tex
	b.add_theme_constant_override("icon_max_width", px)


static func label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


static func para(text: String, size: int, color: Color) -> Label:
	var l := UIKit.label(text, size, color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l


static func badge(text: String, color: Color) -> PanelContainer:
	var p := PanelContainer.new()
	p.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(4)
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 2
	sb.content_margin_bottom = 2
	p.add_theme_stylebox_override("panel", sb)
	p.add_child(UIKit.label(text, 13, Color.WHITE))
	return p


static func button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.pressed.connect(cb)
	return b


static func panel(color: Color) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(12)
	sb.border_color = GuildUI.C_GOLD.darkened(0.4)
	sb.set_border_width_all(1)
	p.add_theme_stylebox_override("panel", sb)
	return p


static func cell(text: String, bg: Color, fg: Color, tip: String) -> Control:
	var p := UIKit.panel(bg)
	p.custom_minimum_size = Vector2(90, 40)
	p.tooltip_text = tip
	var l := UIKit.label(text, 14, fg)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(l)
	return p


static func swatch(color: Color, size: int = 14) -> ColorRect:
	var r := ColorRect.new()
	r.color = color
	r.custom_minimum_size = Vector2(size, size)
	r.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return r


static func spacer() -> Control:
	var c := Control.new()
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return c


static func spacer_v() -> Control:
	var c := Control.new()
	c.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return c


static func fatigue_color(h: Dictionary) -> Color:
	if h.busy:
		return GuildUI.C_MUTED
	return [GuildUI.C_GOOD, GuildUI.C_GOLD, GuildUI.C_BAD][h.fatigue]


static func aff_color(v: int) -> Color:
	if v <= -3:
		return GuildUI.C_BAD
	if v < 0:
		return Color("#d18a5d")
	if v == 0:
		return GuildUI.C_MUTED
	if v <= 5:
		return GuildUI.C_GOOD
	return GuildUI.C_GOLD
