extends VBoxContainer
## Livro da Guilda (GDD §14): ficha resumida no estilo D&D 5e, uma por aventureiro.
## Página esquerda = identidade; direita = atributos, personalidade e afinidades.
## Seções trancadas vêm de data/book.json e são os slots de expansão.

signal closed

const C_PAGE := Color("#ead9b0")
const C_PAGE_EDGE := Color("#c9b083")
const C_INK := Color("#2a1f14")
const C_INK_SOFT := Color("#5a4630")
const C_RUBRIC := Color("#8a2f1f")
const C_GOLD := Color("#b8892e")
const C_HP := Color("#a8443c")

var ui    # main.gd (helpers de UI)
var gs    # GameState
var index := 0
var _open_locks := {}


func setup(p_ui, p_gs, p_index: int) -> void:
	ui = p_ui
	gs = p_gs
	index = p_index
	add_theme_constant_override("separation", 8)
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	_render()


func _render() -> void:
	for c in get_children():
		c.queue_free()
	var id: String = gs.hero_order[index]
	var h: Dictionary = gs.heroes[id]

	# Navegação
	var nav := HBoxContainer.new()
	add_child(nav)
	nav.add_child(ui._label("Livro da Guilda", 22, ui.C_GOLD))
	nav.add_child(ui._spacer())
	nav.add_child(ui._button("◀", _go.bind(index - 1)))
	for i in gs.hero_order.size():
		var dot: Button = ui._button("●" if i == index else "○", _go.bind(i))
		dot.flat = true
		dot.tooltip_text = gs.heroes[gs.hero_order[i]].name
		dot.add_theme_color_override("font_color", gs.heroes[gs.hero_order[i]].color)
		nav.add_child(dot)
	nav.add_child(ui._button("▶", _go.bind(index + 1)))
	nav.add_child(ui._label("  %s (%d/%d)" % [h.name, index + 1, gs.hero_order.size()], 15, ui.C_TEXT))
	nav.add_child(ui._spacer())
	nav.add_child(ui._button("Fechar o livro", func(): closed.emit()))

	# Livro aberto (spread)
	var spread := HBoxContainer.new()
	spread.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spread.add_theme_constant_override("separation", 0)
	add_child(spread)
	spread.add_child(_page(_left_page(id, h)))
	var spine := ColorRect.new()
	spine.color = Color("#6b4e2e")
	spine.custom_minimum_size.x = 6
	spread.add_child(spine)
	spread.add_child(_page(_right_page(id, h)))


func _go(i: int) -> void:
	index = posmod(i, gs.hero_order.size())
	_render()


# ---------- página esquerda: identidade ----------

func _left_page(id: String, h: Dictionary) -> Control:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	col.add_child(head)
	head.add_child(_portrait(h))
	var idcol := VBoxContainer.new()
	idcol.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(idcol)
	idcol.add_child(_illuminated(h.title))
	idcol.add_child(_text(h.archetype, 14, C_INK_SOFT, true))
	idcol.add_child(_text("%s · %s · Nível %d" % [h["class"], h.race, h.level], 15, C_INK))
	var status: String = gs.hero_status(id)
	idcol.add_child(_badge(status, _status_color(status)))

	col.add_child(_rule())
	col.add_child(_pips_row("PV", h.hp, h.hp_max, C_HP, "%d/%d" % [h.hp, h.hp_max]))
	col.add_child(_pips_row("Moral", h.morale, 10, C_GOLD, "%d/10" % h.morale))
	col.add_child(_pips_row("Estresse", int(h.get("stress", 0)), int(gs.traits_data.stress_max), C_RUBRIC, Mind.stress_label(gs, h)))
	var cond: Dictionary = Mind.condition_info(gs, h)
	var marks := HFlowContainer.new()
	marks.add_theme_constant_override("h_separation", 6)
	marks.add_theme_constant_override("v_separation", 4)
	if not cond.is_empty():
		var virtue: bool = h.condition_kind == "virtude"
		var cb := _badge(("✦ " if virtue else "✖ ") + cond.name, Color("#3f6b2f") if virtue else C_RUBRIC)
		cb.tooltip_text = cond.desc + ("" if virtue else "
Um dia de descanso na guilda cura a aflição.")
		cb.mouse_filter = Control.MOUSE_FILTER_STOP
		marks.add_child(cb)
	for tid in h.get("traits", []):
		var ti: Dictionary = Mind.trait_info(gs, tid)
		var tb := _tag(("+ " if ti.positive else "− ") + ti.name)
		tb.tooltip_text = ti.desc
		tb.mouse_filter = Control.MOUSE_FILTER_STOP
		marks.add_child(tb)
	if marks.get_child_count() > 0:
		col.add_child(marks)
	col.add_child(_xp_row(id, h))

	col.add_child(_heading("Equipamento"))
	for slot in HeroRPG.SLOTS:
		var cur: String = h.equip[slot]
		var t := _text("%s: %s" % [HeroRPG.SLOT_NAMES[slot], HeroRPG.item(gs, cur).name if cur != "" else "—"], 13, C_INK if cur != "" else C_INK_SOFT, cur == "")
		if cur != "":
			t.tooltip_text = HeroRPG.item(gs, cur).desc
			t.mouse_filter = Control.MOUSE_FILTER_STOP
		col.add_child(t)
	var eb := Button.new()
	eb.text = "Gerenciar equipamento ▸"
	eb.flat = true
	eb.alignment = HORIZONTAL_ALIGNMENT_LEFT
	eb.add_theme_color_override("font_color", C_RUBRIC)
	eb.pressed.connect(func(): ui.show_equip(index))
	col.add_child(eb)

	col.add_child(_heading("Proficiências"))
	var tags := HFlowContainer.new()
	tags.add_theme_constant_override("h_separation", 6)
	tags.add_theme_constant_override("v_separation", 6)
	for p in h.proficiencies:
		tags.add_child(_tag(p))
	col.add_child(tags)

	col.add_child(_heading("Histórico de missões"))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size.y = 70
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)
	var log := VBoxContainer.new()
	scroll.add_child(log)
	if h.history.is_empty():
		log.add_child(_text("Ainda não foi despachado.", 13, C_INK_SOFT, true))
	for i in range(h.history.size() - 1, -1, -1):
		var e: Dictionary = h.history[i]
		var icon: String = {"limpo": "✓", "custo": "~", "falha": "✗"}[e.result]
		var c: Color = {"limpo": Color("#3f6b2f"), "custo": Color("#8a6a1f"), "falha": C_RUBRIC}[e.result]
		log.add_child(_text("%s  Dia %d — %s" % [icon, e.day, e.mission], 13, c))

	_add_locked(col, "left")
	return col


# ---------- página direita: atributos e relações ----------

func _right_page(id: String, h: Dictionary) -> Control:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)

	col.add_child(_heading("Atributos"))
	var grid := HBoxContainer.new()
	grid.add_theme_constant_override("separation", 6)
	col.add_child(grid)
	for k in gs.ATTRS:
		grid.add_child(_attr_box(gs.ATTR_NAMES[k], h.attrs[k]))

	_add_powers(col, id, h)

	col.add_child(_heading("Personalidade"))
	var pers: Dictionary = h.personality
	for key in [["trait", "Traço"], ["ideal", "Ideal"], ["bond", "Vínculo"], ["flaw", "Defeito"]]:
		if pers.has(key[0]):
			var row := HBoxContainer.new()
			col.add_child(row)
			var l := _text(key[1], 13, C_RUBRIC, false)
			l.custom_minimum_size.x = 64
			row.add_child(l)
			var t := _text("\"%s\"" % pers[key[0]], 13, C_INK, true)
			t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(t)

	col.add_child(_heading("Afinidades" if gs.affinity_visible() else "Afinidades (impressões — construa o Quadro de Relações para ver os números)"))
	for other in gs.hero_order:
		if other == id:
			continue
		var v: int = gs.pair_value(id, other)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		col.add_child(row)
		var n := _text(gs.heroes[other].name, 13, C_INK, false)
		n.custom_minimum_size.x = 52
		row.add_child(n)
		var lbl: String = gs.bond_label(id, other)
		if gs.affinity_visible():
			row.add_child(_aff_bar(v))
			row.add_child(_text("%+d" % v, 13, C_INK, false))
			row.add_child(_text(gs.band(v).label + ("  ✦ " + lbl if lbl != "" else ""), 12, C_INK_SOFT, true))
		else:
			row.add_child(_text(gs.describe_aff(v) + ("  ✦ " + lbl if lbl != "" else ""), 13, C_INK_SOFT, true))

	_add_locked(col, "right")
	return col


# ---------- RPG ----------

func _xp_row(id: String, h: Dictionary) -> Control:
	var row := HBoxContainer.new()
	var l := _text("XP", 14, C_INK, false)
	l.custom_minimum_size.x = 52
	row.add_child(l)
	var need: int = HeroRPG.xp_to_next(gs, h.level)
	var bar := ProgressBar.new()
	bar.max_value = need
	bar.value = h.xp
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(180, 10)
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("#4f7a3a")
	bar.add_theme_stylebox_override("fill", fill)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(C_INK, 0.12)
	bar.add_theme_stylebox_override("background", bg)
	row.add_child(bar)
	row.add_child(_text("  %d/%d para o nível %d" % [h.xp, need, h.level + 1], 13, C_INK_SOFT, false))
	return row


## Magias (conjuradores) ou talentos (demais), com espaços de magia e magias de guilda.
func _add_powers(col: VBoxContainer, id: String, h: Dictionary) -> void:
	if HeroRPG.is_caster(gs, id):
		var mx := HeroRPG.max_slots(gs, id)
		col.add_child(_heading("Magias  —  espaços %s" % ("●".repeat(h.slots) + "○".repeat(max(0, mx - h.slots)))))
		for sid in h.spells_known:
			var sp := HeroRPG.spell(gs, sid)
			var row := HBoxContainer.new()
			col.add_child(row)
			var t := _text("✦ %s — %s" % [sp.name, sp.desc], 13, C_INK, false)
			t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(t)
			if sp.has("hub"):
				var b := Button.new()
				b.text = "Lançar"
				b.disabled = h.slots <= 0 or h.busy
				b.tooltip_text = "Gasta 1 espaço de magia." if not b.disabled else "Sem espaços: precisa descansar."
				b.pressed.connect(func(): ui.show_cast(id, sid, index))
				row.add_child(b)
		if h.spells_known.is_empty():
			col.add_child(_text("Nenhuma magia ainda.", 13, C_INK_SOFT, true))
	else:
		col.add_child(_heading("Talentos"))
		for tid in h.talents:
			var t: Dictionary = gs.classes_data.talents[tid]
			col.add_child(_text("✦ %s — %s" % [t.name, t.desc], 13, C_INK, false))
		if h.talents.is_empty():
			col.add_child(_text("Talentos chegam nos níveis %s." % ", ".join(gs.classes_data.xp.milestones.map(func(x): return str(x))), 13, C_INK_SOFT, true))


# ---------- seções trancadas (expansão) ----------

func _add_locked(col: VBoxContainer, page: String) -> void:
	for sec in gs.book.get("locked_sections", []):
		if sec.page != page:
			continue
		var key: String = sec.title
		var b := Button.new()
		b.text = "🔒 %s — %s %s" % [sec.title, sec.version, "▾" if _open_locks.get(key, false) else "▸"]
		b.flat = true
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_color_override("font_color", C_INK_SOFT)
		b.add_theme_color_override("font_hover_color", C_RUBRIC)
		b.pressed.connect(func():
			_open_locks[key] = not _open_locks.get(key, false)
			_render())
		col.add_child(b)
		if _open_locks.get(key, false):
			var t := _text("Disponível na %s. %s" % [sec.version, sec.desc], 12, C_INK_SOFT, true)
			t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			col.add_child(t)


# ---------- peças visuais ----------

func _page(content: Control) -> PanelContainer:
	var p := PanelContainer.new()
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sb := StyleBoxFlat.new()
	sb.bg_color = C_PAGE
	sb.border_color = C_PAGE_EDGE
	sb.set_border_width_all(2)
	sb.set_content_margin_all(18)
	p.add_theme_stylebox_override("panel", sb)
	p.add_child(content)
	return p


func _portrait(h: Dictionary) -> Control:
	var frame := PanelContainer.new()
	frame.custom_minimum_size = Vector2(112, 112)
	frame.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var has_image: bool = h.portrait != "" and ResourceLoader.exists(h.portrait)
	if has_image:
		# a arte já traz o medalhão: sem moldura extra
		frame.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
		var tex := TextureRect.new()
		tex.texture = load(h.portrait)
		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		frame.add_child(tex)
	else:
		var sb := StyleBoxFlat.new()
		sb.bg_color = h.color.darkened(0.15)
		sb.border_color = C_GOLD
		sb.set_border_width_all(3)
		sb.set_corner_radius_all(56)
		frame.add_theme_stylebox_override("panel", sb)
		var por = load("res://scripts/ui/portrait.gd").new()
		por.setup(h)
		frame.add_child(por)
	return frame


## Nome com inicial iluminada.
func _illuminated(title: String) -> Control:
	var rt := RichTextLabel.new()
	rt.bbcode_enabled = true
	rt.fit_content = true
	rt.scroll_active = false
	rt.autowrap_mode = TextServer.AUTOWRAP_OFF
	rt.add_theme_color_override("default_color", C_INK)
	rt.add_theme_font_size_override("normal_font_size", 22)
	rt.text = "[font_size=34][color=#8a2f1f]%s[/color][/font_size]%s" % [title.left(1), title.substr(1)]
	return rt


func _attr_box(name: String, v: int) -> Control:
	var p := PanelContainer.new()
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#f4e8c8")
	sb.border_color = C_INK_SOFT
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(4)
	p.add_theme_stylebox_override("panel", sb)
	p.tooltip_text = "%s %d — modificador %+d" % [name, v, gs.attr_mod(v)]
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)
	p.add_child(col)
	for part in [[name.left(3).to_upper(), 11, C_INK_SOFT], [str(v), 24, C_INK], ["%+d" % gs.attr_mod(v), 13, C_RUBRIC]]:
		var l := _text(part[0], part[1], part[2], false)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(l)
	return p


func _pips_row(label: String, value: int, max_value: int, color: Color, suffix: String) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 3)
	var l := _text(label, 14, C_INK, false)
	l.custom_minimum_size.x = 52
	row.add_child(l)
	for i in max_value:
		var pip := PanelContainer.new()
		var sb := StyleBoxFlat.new()
		sb.bg_color = color if i < value else Color(color, 0.12)
		sb.border_color = color.darkened(0.3)
		sb.set_border_width_all(1)
		sb.set_corner_radius_all(6)
		pip.add_theme_stylebox_override("panel", sb)
		pip.custom_minimum_size = Vector2(12, 12)
		pip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(pip)
	row.add_child(_text("  " + suffix, 13, C_INK_SOFT, false))
	return row


## Barra −5..+10 com marca no zero.
func _aff_bar(v: int) -> Control:
	var w := 150.0
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(w, 10)
	holder.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var bg := ColorRect.new()
	bg.color = Color(C_INK, 0.12)
	bg.size = Vector2(w, 10)
	holder.add_child(bg)
	var zero := w * 5.0 / 15.0
	var x := w * (v + 5) / 15.0
	var fill := ColorRect.new()
	fill.color = ui._aff_color(v).darkened(0.2)
	fill.position = Vector2(minf(zero, x), 0)
	fill.size = Vector2(absf(x - zero), 10)
	holder.add_child(fill)
	var mark := ColorRect.new()
	mark.color = C_INK
	mark.position = Vector2(zero - 1, -2)
	mark.size = Vector2(2, 14)
	holder.add_child(mark)
	return holder


func _heading(t: String) -> Control:
	var l := _text(t.to_upper(), 13, C_RUBRIC, false)
	return l


func _rule() -> Control:
	var r := ColorRect.new()
	r.color = Color(C_INK_SOFT, 0.4)
	r.custom_minimum_size.y = 1
	return r


func _tag(t: String) -> Control:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#d9c391")
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 2
	sb.content_margin_bottom = 2
	p.add_theme_stylebox_override("panel", sb)
	p.add_child(_text(t, 12, C_INK, false))
	return p


func _badge(t: String, c: Color) -> Control:
	var p := PanelContainer.new()
	p.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var sb := StyleBoxFlat.new()
	sb.bg_color = c
	sb.set_corner_radius_all(4)
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	p.add_theme_stylebox_override("panel", sb)
	p.add_child(_text(t, 12, Color.WHITE, false))
	return p


func _status_color(s: String) -> Color:
	match s:
		"Pronto":
			return Color("#4f7a3a")
		"Cansado":
			return Color("#9a7420")
		"Ferido":
			return Color("#b0602e")
		"Em missão":
			return Color("#5a6e8a")
	return C_RUBRIC


func _text(t: String, size: int, color: Color, italic: bool = false) -> Label:
	var l: Label = ui._label(t, size, color)
	if italic:
		l.add_theme_font_override("font", _italic_font())
	return l


var _italic: FontVariation
func _italic_font() -> FontVariation:
	if _italic == null:
		_italic = FontVariation.new()
		_italic.base_font = ThemeDB.fallback_font
		_italic.variation_transform = Transform2D(Vector2(1, 0), Vector2(0.2, 1), Vector2.ZERO)
	return _italic
