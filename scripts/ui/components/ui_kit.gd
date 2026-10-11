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


## Botão com a peça de arte do tipo (madeira, pergaminho, escolha, perigo, medalhao, barra).
## Sem tipo, escolhe pelo texto: "◀ Voltar…" → pergaminho, setas e ☰ → medalhão, resto → madeira.
## Ações conhecidas ganham o ícone de art/ui/icones (e perdem a seta de texto).
static func button(text: String, cb: Callable, kind: String = "") -> Button:
	var b := Button.new()
	b.pressed.connect(cb)
	var ic := UIKit._action_icon(text)
	if ic != "":
		text = text.replace("◀", "").replace("▶", "").strip_edges()
	b.text = text
	UIKit.style_button(b, kind if kind != "" else UIKit._kind_for(text, ic))
	if ic != "":
		UIKit.button_icon(b, UIKit.tex("res://art/ui/icones/%s.png" % ic), 20)
	return b


const _ICON_BY_TEXT := {
	"voltar": "voltar", "continuar": "continuar", "confirmar": "confirmar", "construir": "construir",
	"treinar": "treinar", "assistir cena": "assistir_cena", "conversar": "conversar",
	"seguir viagem": "seguir_viagem", "enfrentar": "enfrentar", "começar o capítulo": "comecar_capitulo",
	"abrir a guilda": "abrir_guilda", "fechar": "fechar", "ver detalhes": "ver_detalhes", "sair": "sair",
	"novo jogo": "novo_jogo", "remover": "remover", "salão de treinamento": "treinar",
}
const _INK_KINDS := ["pergaminho", "escolha"]
static var _styles := {}


static func _action_icon(text: String) -> String:
	var t := text.replace("◀", "").replace("▶", "").strip_edges().to_lower()
	for k in _ICON_BY_TEXT:
		if t.begins_with(k):
			return _ICON_BY_TEXT[k]
	return ""


static func _kind_for(text: String, ic: String) -> String:
	if text.strip_edges() in ["◀", "▶", "☰", "●"]:
		return "medalhao"
	if ic == "voltar" or ic == "fechar":
		return "pergaminho"
	if ic == "enfrentar":
		return "perigo"
	return "madeira"


## Peça 9-slice: (margens da textura, margens do conteúdo [esq, cima, dir, baixo]).
const _PIECES := {
	"madeira": [16, [18, 8, 18, 8]], "perigo": [16, [18, 8, 18, 8]],
	"pergaminho": [14, [16, 6, 16, 6]], "escolha": [10, [50, 8, 14, 8]],
	"medalhao": [0, [10, 8, 10, 8]], "barra": [12, [18, 8, 14, 8]],
}


## Aplica a peça ao botão; sem arte entregue, fica o botão padrão.
static func style_button(b: Button, kind: String) -> void:
	var t := UIKit.tex("res://art/ui/btn_%s_normal.png" % kind)
	if t == null or not _PIECES.has(kind):
		return
	var states := {"normal": Color.WHITE, "hover": Color(1.18, 1.14, 1.08), "pressed": Color(0.78, 0.74, 0.7),
		"disabled": Color(0.6, 0.6, 0.6, 0.7), "hover_pressed": Color(0.85, 0.8, 0.75)}
	for st in states:
		var key: String = kind + ":" + st
		if not _styles.has(key):
			var sb := StyleBoxTexture.new()
			sb.texture = t
			var m: int = _PIECES[kind][0]
			# a fita da escolha e o nicho da barra ficam inteiros na margem esquerda
			sb.texture_margin_left = {"escolha": 44, "barra": 58}.get(kind, m)
			sb.texture_margin_top = m
			sb.texture_margin_right = m
			sb.texture_margin_bottom = m
			var cm: Array = _PIECES[kind][1]
			sb.content_margin_left = cm[0]
			sb.content_margin_top = cm[1]
			sb.content_margin_right = cm[2]
			sb.content_margin_bottom = cm[3]
			sb.modulate_color = states[st]
			_styles[key] = sb
		b.add_theme_stylebox_override(st, _styles[key])
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	var ink := kind in _INK_KINDS
	var fg := GuildUI.C_INK if ink else Color("#f3e6c8")
	b.add_theme_color_override("font_color", fg)
	b.add_theme_color_override("font_hover_color", fg.lightened(0.15) if not ink else fg.darkened(0.2))
	b.add_theme_color_override("font_pressed_color", fg)
	b.add_theme_color_override("font_focus_color", fg)
	b.add_theme_color_override("font_hover_pressed_color", fg)
	b.add_theme_color_override("font_disabled_color", fg.darkened(0.35) if not ink else Color(GuildUI.C_INK, 0.5))
	if kind == "barra":
		b.add_theme_constant_override("h_separation", 18)   # ícone no nicho, texto depois dele
	if kind == "medalhao":
		b.custom_minimum_size = Vector2(44, 44)


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
