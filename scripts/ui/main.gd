extends Control
## Telas do protótipo (GDD §8), montadas por código.
## Cada show_* limpa a tela e reconstrói. A regra fica em GameState/ScoreCalc.

const C_BG := Color("#2b2118")
const C_PANEL := Color("#3d2f22")
const C_PARCHMENT := Color("#e8d9b5")
const C_INK := Color("#2a1f14")
const C_GOLD := Color("#d4a94a")
const C_TEXT := Color("#f1e6cc")
const C_MUTED := Color("#b5a283")
const C_GOOD := Color("#7fb069")
const C_BAD := Color("#d1603d")
const RISK_COLORS := {"baixo": Color("#7fb069"), "medio": Color("#d4a94a"), "alto": Color("#d1603d"), "lendario": Color("#a26ad1")}
const OUTCOME_COLORS := {"limpo": Color("#7fb069"), "custo": Color("#d4a94a"), "falha": Color("#d1603d")}

const MagicMap := preload("res://scripts/ui/magic_map.gd")
const GuildBook := preload("res://scripts/ui/guild_book.gd")

var gs  # GameState
var root: VBoxContainer
var selected: Array = []
var last_result := {}


func _ready() -> void:
	gs = get_node("/root/GameState")
	var bg := ColorRect.new()
	bg.color = C_BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	add_child(margin)
	root = VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	margin.add_child(root)
	show_hub()


# ================= Tela da Guilda =================

func show_hub() -> void:
	_clear()
	if gs.is_over():
		show_ending()
		return
	var top := HBoxContainer.new()
	root.add_child(top)
	top.add_child(_label("A Guilda do Corvo Cinzento", 26, C_GOLD))
	top.add_child(_spacer())
	top.add_child(_label("Dia %d/%d   ·   Reputação %d   ·   Despachos %d/%d" % [gs.day, gs.LAST_DAY, gs.reputation, gs.dispatched_today, gs.slots()], 16, C_TEXT))
	top.add_child(_button("Quadro de Relações", show_relations))
	top.add_child(_button("Livro da Guilda", show_book.bind(0)))
	top.add_child(_button("Encerrar dia ▶", _on_end_day))

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 16)
	root.add_child(body)

	# Mural
	var board_panel := _panel(C_PANEL)
	board_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	board_panel.size_flags_stretch_ratio = 2.0
	body.add_child(board_panel)
	var bcol := VBoxContainer.new()
	board_panel.add_child(bcol)
	bcol.add_child(_label("Mural de Quests", 20, C_GOLD))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	bcol.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 8)
	scroll.add_child(list)
	var board: Array = gs.board()
	if board.is_empty():
		list.add_child(_label("Nenhum pedido no mural hoje.", 15, C_MUTED))
	for m in board:
		list.add_child(_mission_card(m))

	# Elenco
	var cast_panel := _panel(C_PANEL)
	cast_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(cast_panel)
	var ccol := VBoxContainer.new()
	ccol.add_theme_constant_override("separation", 6)
	cast_panel.add_child(ccol)
	ccol.add_child(_label("Elenco", 20, C_GOLD))
	for id in gs.hero_order:
		var h: Dictionary = gs.heroes[id]
		var row := HBoxContainer.new()
		ccol.add_child(row)
		row.add_child(_swatch(h.color))
		row.add_child(_label("%s — %s" % [h.name, h.archetype], 14, C_TEXT))
		row.add_child(_spacer())
		var state: String = gs.hero_status(id)
		row.add_child(_label(state, 13, _fatigue_color(h)))
		row.add_child(_label("  PV %d/%d" % [h.hp, h.hp_max], 13, C_MUTED))
		row.add_child(_label("  Moral %d" % h.morale, 13, C_MUTED))

	# Bastidores
	ccol.add_child(_label("Bastidores", 20, C_GOLD))
	var pending: Array = gs.backstage_today.filter(func(bs): return not bs.done)
	if pending.is_empty():
		ccol.add_child(_para("A guilda está quieta hoje.", 13, C_MUTED))
	for bs in pending:
		var card := _panel(Color("#4a3a2a"))
		ccol.add_child(card)
		var bc := VBoxContainer.new()
		card.add_child(bc)
		var brow := HBoxContainer.new()
		bc.add_child(brow)
		brow.add_child(_swatch(gs.heroes[bs.a].color))
		brow.add_child(_swatch(gs.heroes[bs.b].color))
		brow.add_child(_label(" " + bs.event.title, 15, C_TEXT))
		brow.add_child(_spacer())
		brow.add_child(_button("Assistir cena", show_backstage.bind(bs)))
		bc.add_child(_label("%s e %s" % [gs.heroes[bs.a].name, gs.heroes[bs.b].name], 12, C_MUTED))


func _mission_card(m: Dictionary) -> Control:
	var card := _panel(C_PARCHMENT)
	var col := VBoxContainer.new()
	card.add_child(col)
	var head := HBoxContainer.new()
	col.add_child(head)
	head.add_child(_label(m.name, 17, C_INK))
	head.add_child(_spacer())
	head.add_child(_label("[%s]" % gs.RISK_NAMES[m.risk], 14, RISK_COLORS[m.risk].darkened(0.25)))
	col.add_child(_para(m.desc, 13, C_INK))
	var left: int = gs.expires_on(m) - gs.day
	var prazo := "último dia!" if left <= 0 else "%d dia(s)" % (left + 1)
	col.add_child(_para("Tipo: %s   ·   %s + %s   ·   Prazo: %s" % [m.type.capitalize(), gs.ATTR_NAMES[m.primary], gs.ATTR_NAMES[m.secondary], prazo], 13, C_INK.lightened(0.25)))
	for tag in m.get("tags", []):
		col.add_child(_para("⚑ " + tag.text, 13, Color("#8a3b1f")))
	var btn := _button("Montar party", show_party.bind(m))
	btn.disabled = gs.free_slots() <= 0
	if btn.disabled:
		btn.tooltip_text = "Sem slots de despacho hoje."
	btn.size_flags_horizontal = Control.SIZE_SHRINK_END
	col.add_child(btn)
	return card


func _on_end_day() -> void:
	var lines: Array = gs.end_day()
	_clear()
	root.add_child(_label("Dia %d" % gs.day, 28, C_GOLD))
	root.add_child(_para("Os aventureiros descansam. A taverna esvazia. O mural range com pergaminhos novos.", 15, C_TEXT))
	for l in lines:
		root.add_child(_para("• " + l, 15, C_TEXT))
	root.add_child(_button("Abrir a guilda", show_hub))


# ================= Montagem de Party =================

func show_party(m: Dictionary) -> void:
	selected = []
	_render_party(m)


func _render_party(m: Dictionary) -> void:
	_clear()
	var head := HBoxContainer.new()
	root.add_child(head)
	head.add_child(_label("MISSÃO: " + m.name, 22, C_GOLD))
	head.add_child(_spacer())
	head.add_child(_label("[%s]" % gs.RISK_NAMES[m.risk], 18, RISK_COLORS[m.risk]))
	root.add_child(_label("Atributo: %s + %s" % [gs.ATTR_NAMES[m.primary], gs.ATTR_NAMES[m.secondary]], 15, C_TEXT))
	for tag in m.get("tags", []):
		root.add_child(_para("⚑ " + tag.text, 14, C_BAD))

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 16)
	root.add_child(body)

	# Aventureiros
	var lp := _panel(C_PANEL)
	lp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(lp)
	var lcol := VBoxContainer.new()
	lcol.add_theme_constant_override("separation", 6)
	lp.add_child(lcol)
	lcol.add_child(_label("AVENTUREIROS", 16, C_GOLD))
	for id in gs.hero_order:
		var h: Dictionary = gs.heroes[id]
		var reason: String = gs.unavailable_reason(id, m)
		var row := HBoxContainer.new()
		lcol.add_child(row)
		row.add_child(_swatch(h.color))
		var is_sel := selected.has(id)
		var b := _button(("✓ " if is_sel else "") + h.name, _toggle_hero.bind(m, id))
		b.custom_minimum_size.x = 110
		b.disabled = reason != "" or (not is_sel and selected.size() >= 4)
		row.add_child(b)
		row.add_child(_label("%s %d / %s %d" % [gs.ATTR_NAMES[m.primary].left(3), h.attrs[m.primary], gs.ATTR_NAMES[m.secondary].left(3), h.attrs[m.secondary]], 13, C_TEXT))
		row.add_child(_spacer())
		var state: String = reason if reason != "" else gs.hero_status(id)
		row.add_child(_label(state, 13, C_BAD if reason != "" else _fatigue_color(h)))

	# Party selecionada
	var rp := _panel(C_PANEL)
	rp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(rp)
	var rcol := VBoxContainer.new()
	rcol.add_theme_constant_override("separation", 6)
	rp.add_child(rcol)
	rcol.add_child(_label("PARTY SELECIONADA", 16, C_GOLD))
	if selected.is_empty():
		rcol.add_child(_label("Selecione de 1 a 4 aventureiros.", 14, C_MUTED))
	for id in selected:
		var h: Dictionary = gs.heroes[id]
		var tired := "  (Cansado: −40%)" if h.fatigue == 1 else ""
		rcol.add_child(_label("→ %s%s" % [h.name, tired], 14, C_TEXT))

	var pairs := ScoreCalc.pairs_of(selected)
	if pairs.size() > 0:
		rcol.add_child(_label("AFINIDADE DA PARTY:", 14, C_GOLD))
		for pr in pairs:
			var v: int = gs.pair_value(pr[0], pr[1])
			var bd: Dictionary = gs.band(v)
			var lbl: String = gs.bond_label(pr[0], pr[1])
			var extra := "  · " + lbl if lbl != "" else ""
			rcol.add_child(_label("%s ↔ %s  %+d  [%s]%s" % [gs.heroes[pr[0]].name, gs.heroes[pr[1]].name, v, bd.label, extra], 14, _aff_color(v)))
	for act in gs.active_bond_actions(selected):
		rcol.add_child(_label("✦ Ação de Vínculo: %s (%s & %s)" % [act.action, gs.heroes[act.a].name, gs.heroes[act.b].name], 14, C_GOLD))

	var unmet: Array = gs.unmet_tags(m, selected)
	if not selected.is_empty():
		var est := ScoreCalc.compute(gs, m, selected)
		var t: Array = ScoreCalc.THRESHOLDS[m.risk]
		var txt := "Arriscado"
		var col := C_BAD
		if est.total >= t[1]:
			txt = "Promissor"
			col = C_GOOD
		elif est.total >= t[0]:
			txt = "Incerto"
			col = C_GOLD
		var bar := ProgressBar.new()
		bar.max_value = t[1] + 2
		bar.value = clampf(est.total, 0, bar.max_value)
		bar.show_percentage = false
		bar.custom_minimum_size.y = 14
		var fill := StyleBoxFlat.new()
		fill.bg_color = col
		bar.add_theme_stylebox_override("fill", fill)
		rcol.add_child(_label("Expectativa: " + txt, 15, col))
		rcol.add_child(bar)
	if m.has("hidden"):
		rcol.add_child(_para("⚠ Algo nesta missão não está no pergaminho...", 13, C_MUTED))
	for u in unmet:
		rcol.add_child(_para("✗ " + u, 13, C_BAD))

	var foot := HBoxContainer.new()
	root.add_child(foot)
	foot.add_child(_button("◀ Voltar", show_hub))
	foot.add_child(_spacer())
	var go := _button("  DESPACHAR PARTY — Selo de Cera  ", _on_dispatch.bind(m))
	go.disabled = selected.is_empty() or not unmet.is_empty()
	foot.add_child(go)


func _toggle_hero(m: Dictionary, id: String) -> void:
	if selected.has(id):
		selected.erase(id)
	elif selected.size() < 4:
		selected.append(id)
	_render_party(m)


func _on_dispatch(m: Dictionary) -> void:
	var res: Dictionary = gs.dispatch(m, selected.duplicate())
	selected = []
	last_result = res
	show_map(res)


# ================= Mapa Mágico =================

func show_map(res: Dictionary) -> void:
	_clear()
	var m: Dictionary = res.mission
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 16)
	root.add_child(body)

	var frame := _panel(Color("#1a1420"))
	frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	frame.size_flags_stretch_ratio = 2.6
	body.add_child(frame)
	var map = MagicMap.new()
	map.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map.clip_contents = true
	frame.add_child(map)

	var side := _panel(C_PANEL)
	side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(side)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	side.add_child(col)
	col.add_child(_label("Mapa Mágico de Escrutínio", 13, C_MUTED))
	col.add_child(_para(m.name, 20, C_GOLD))
	col.add_child(_badge(gs.RISK_NAMES[m.risk], RISK_COLORS[m.risk].darkened(0.2)))
	var chips := HFlowContainer.new()
	chips.add_theme_constant_override("h_separation", 6)
	chips.add_theme_constant_override("v_separation", 6)
	col.add_child(chips)
	var tokens := []
	for id in res.party:
		var h: Dictionary = gs.heroes[id]
		chips.add_child(_badge(h.name, h.color.darkened(0.2)))
		tokens.append({"name": h.name, "color": h.color})
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.max_value = 1.0
	bar.custom_minimum_size.y = 10
	var fill := StyleBoxFlat.new()
	fill.bg_color = C_GOLD
	bar.add_theme_stylebox_override("fill", fill)
	col.add_child(bar)
	var narr := VBoxContainer.new()
	narr.size_flags_vertical = Control.SIZE_EXPAND_FILL
	narr.add_theme_constant_override("separation", 10)
	col.add_child(narr)
	var foot := HBoxContainer.new()
	col.add_child(foot)
	var fast := _button("Acelerar ⏩", map.skip)
	foot.add_child(fast)
	foot.add_child(_spacer())
	var go := _button("Ver Resultado", show_result.bind(res))
	go.visible = false
	foot.add_child(go)

	var lines: Array = gs.map_narration(res)
	map.waypoint_reached.connect(func(i: int):
		var l := _para(lines[i], 15, C_TEXT)
		l.modulate.a = 0.0
		narr.add_child(l)
		create_tween().tween_property(l, "modulate:a", 1.0, 0.8))
	map.finished.connect(func():
		fast.visible = false
		go.visible = true)
	map.set_process(true)
	map.draw.connect(func(): bar.value = map.progress)
	map.setup(m, tokens, gs.day * 1000 + gs.missions.find(m))


# ================= Resolução =================

func show_result(res: Dictionary) -> void:
	_clear()
	var m: Dictionary = res.mission
	root.add_child(_label(m.name, 22, C_GOLD))
	root.add_child(_para(gs.OUTCOME_NAMES[res.outcome], 30, OUTCOME_COLORS[res.outcome]))
	var p := _panel(C_PARCHMENT)
	root.add_child(p)
	var col := VBoxContainer.new()
	p.add_child(col)
	for l in res.lines:
		col.add_child(_para(l, 16, C_INK))

	var sc: Dictionary = res.score
	var t: Array = ScoreCalc.THRESHOLDS[m.risk]
	root.add_child(_para("Score %.1f  =  Base %.1f  + Cobertura %d  + Afinidade %+.1f  + Vínculo %d  + Oculto %d  + Sorte %+d      (custo ≥ %d · limpo ≥ %d)" % [sc.total, sc.base, sc.coverage, sc.affinity, sc.bond, sc.hidden, sc.luck, t[0], t[1]], 13, C_MUTED))

	if not res.affinity.is_empty():
		root.add_child(_label("Vínculos", 16, C_GOLD))
		for ch in res.affinity:
			var arrow := "▲" if ch.after > ch.before else ("▼" if ch.after < ch.before else "=")
			root.add_child(_label("%s ↔ %s   %+d → %+d  %s  [%s]" % [gs.heroes[ch.a].name, gs.heroes[ch.b].name, ch.before, ch.after, arrow, gs.band(ch.after).label], 14, _aff_color(ch.after)))
	root.add_child(_spacer_v())
	root.add_child(_button("Continuar", _after_result))


func _after_result() -> void:
	if not gs.pending_events.is_empty():
		show_bond_event(gs.pending_events.pop_front())
	else:
		show_hub()


# ================= Evento de Vínculo =================

func show_bond_event(ev: Dictionary) -> void:
	_clear()
	var info: Dictionary = gs.THRESHOLD_EVENTS[ev.threshold]
	var a: Dictionary = gs.heroes[ev.a]
	var b: Dictionary = gs.heroes[ev.b]
	root.add_child(_label("Bastidores da guilda", 16, C_MUTED))
	root.add_child(_label("\"%s\"" % info.title, 28, C_GOLD))
	root.add_child(_label("%s e %s  ·  afinidade %+d" % [a.name, b.name, gs.pair_value(ev.a, ev.b)], 18, C_TEXT))
	root.add_child(_label("Como você enxerga o que existe entre eles?", 15, C_TEXT))
	for lbl in info.labels:
		var action: String = gs.BOND_ACTIONS.get(lbl, "")
		var hint := "  — desbloqueia \"%s\" em Laço Forte" % action if action != "" else ""
		root.add_child(_button(lbl + hint, _on_label_chosen.bind(ev, lbl)))


func _on_label_chosen(ev: Dictionary, lbl: String) -> void:
	gs.choose_bond_label(ev, lbl)
	_after_result()


# ================= Evento de Bastidor =================

func show_backstage(bs: Dictionary) -> void:
	_clear()
	root.add_child(_label("Bastidores da guilda", 16, C_MUTED))
	root.add_child(_label(bs.event.title, 28, C_GOLD))
	var who := HBoxContainer.new()
	root.add_child(who)
	for id in [bs.a, bs.b]:
		who.add_child(_badge(gs.heroes[id].name, gs.heroes[id].color.darkened(0.2)))
	who.add_child(_label("   afinidade %+d  [%s]" % [gs.pair_value(bs.a, bs.b), gs.band(gs.pair_value(bs.a, bs.b)).label], 14, _aff_color(gs.pair_value(bs.a, bs.b))))
	var p := _panel(C_PARCHMENT)
	root.add_child(p)
	p.add_child(_para(gs.backstage_text(bs, bs.event.text), 17, C_INK))
	root.add_child(_label("O que você faz?", 15, C_TEXT))
	for choice in bs.event.choices:
		var b := _button(gs.backstage_text(bs, choice.label), _on_backstage_choice.bind(bs, choice))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		root.add_child(b)
	root.add_child(_spacer_v())
	root.add_child(_button("◀ Voltar (decidir depois)", show_hub))


func _on_backstage_choice(bs: Dictionary, choice: Dictionary) -> void:
	var lines: Array = gs.resolve_backstage(bs, choice)
	_clear()
	root.add_child(_label(bs.event.title, 24, C_GOLD))
	var p := _panel(C_PARCHMENT)
	root.add_child(p)
	var col := VBoxContainer.new()
	p.add_child(col)
	col.add_child(_para(lines[0], 17, C_INK))
	for i in range(1, lines.size()):
		root.add_child(_label(lines[i], 14, C_TEXT))
	root.add_child(_spacer_v())
	root.add_child(_button("Continuar", _after_result))


# ================= Quadro de Relações =================

func show_relations() -> void:
	_clear()
	root.add_child(_label("Quadro de Relações", 24, C_GOLD))
	root.add_child(_label("Valor do par = o menor dos dois lados. Passe o mouse para ver os dois valores e o vínculo.", 13, C_MUTED))
	var grid := GridContainer.new()
	grid.columns = gs.hero_order.size() + 1
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	root.add_child(grid)
	grid.add_child(_label("", 14, C_TEXT))
	for id in gs.hero_order:
		grid.add_child(_cell(gs.heroes[id].name, C_PANEL, C_GOLD, ""))
	for a in gs.hero_order:
		grid.add_child(_cell(gs.heroes[a].name, C_PANEL, C_GOLD, ""))
		for b in gs.hero_order:
			if a == b:
				grid.add_child(_cell("—", C_PANEL, C_MUTED, ""))
				continue
			var v: int = gs.pair_value(a, b)
			var lbl: String = gs.bond_label(a, b)
			var tip := "%s → %s: %+d\n%s → %s: %+d\n%s%s" % [gs.heroes[a].name, gs.heroes[b].name, gs.affinity[a][b], gs.heroes[b].name, gs.heroes[a].name, gs.affinity[b][a], gs.band(v).label, ("\nVínculo: " + lbl) if lbl != "" else ""]
			tip += "\nSem missão juntos há %d dia(s)" % gs.days_apart(a, b)
			grid.add_child(_cell("%+d%s" % [v, " ✦" if lbl != "" else ""], _aff_color(v).darkened(0.55), C_TEXT, tip))
	root.add_child(_spacer_v())
	root.add_child(_button("◀ Voltar", show_hub))


# ================= Livro da Guilda =================

func show_book(index: int) -> void:
	_clear()
	var book = GuildBook.new()
	root.add_child(book)
	book.setup(self, gs, index)
	book.closed.connect(show_hub)


# ================= Fim =================

func show_ending() -> void:
	_clear()
	root.add_child(_label("Fim do capítulo", 30, C_GOLD))
	var done := 0
	for m in gs.missions:
		if m.status == "concluida":
			done += 1
	root.add_child(_label("Reputação final: %d   ·   Missões concluídas: %d/%d" % [gs.reputation, done, gs.missions.size()], 18, C_TEXT))
	for key in gs.bond_labels:
		var ids: PackedStringArray = key.split("|")
		root.add_child(_label("✦ %s & %s — %s" % [gs.heroes[ids[0]].name, gs.heroes[ids[1]].name, gs.bond_labels[key]], 15, C_TEXT))
	root.add_child(_button("Novo jogo", _on_new_game))


func _on_new_game() -> void:
	gs.new_game()
	show_hub()


# ================= Helpers =================

func _clear() -> void:
	for c in root.get_children():
		c.queue_free()


func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


func _para(text: String, size: int, color: Color) -> Label:
	var l := _label(text, size, color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l


func _badge(text: String, color: Color) -> PanelContainer:
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
	p.add_child(_label(text, 13, Color.WHITE))
	return p


func _button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.pressed.connect(cb)
	return b


func _panel(color: Color) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(12)
	sb.border_color = C_GOLD.darkened(0.4)
	sb.set_border_width_all(1)
	p.add_theme_stylebox_override("panel", sb)
	return p


func _cell(text: String, bg: Color, fg: Color, tip: String) -> Control:
	var p := _panel(bg)
	p.custom_minimum_size = Vector2(90, 40)
	p.tooltip_text = tip
	var l := _label(text, 14, fg)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(l)
	return p


func _swatch(color: Color, size: int = 14) -> ColorRect:
	var r := ColorRect.new()
	r.color = color
	r.custom_minimum_size = Vector2(size, size)
	r.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return r


func _spacer() -> Control:
	var c := Control.new()
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return c


func _spacer_v() -> Control:
	var c := Control.new()
	c.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return c


func _fatigue_color(h: Dictionary) -> Color:
	if h.busy:
		return C_MUTED
	return [C_GOOD, C_GOLD, C_BAD][h.fatigue]


func _aff_color(v: int) -> Color:
	if v <= -3:
		return C_BAD
	if v < 0:
		return Color("#d18a5d")
	if v == 0:
		return C_MUTED
	if v <= 5:
		return C_GOOD
	return C_GOLD
