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
const Portrait := preload("res://scripts/ui/portrait.gd")
const WaxSeal := preload("res://scripts/ui/wax_seal.gd")

var gs  # GameState
var root: VBoxContainer
var title_bg: TextureRect   # arte da tela de título (só visível no título)

const TITLE_ART := "res://art/geralimagem/titulo.png"
var selected: Array = []
var prepared: Dictionary = {}   # magia preparada por conjurador na montagem de party
var last_result := {}
var moments_enabled := true     # encenar ruptura/saída (os testes de screenshot desligam)
var _moment_open := false
var _moment_layer: Control = null
var _fresh_day := false
var _last_toggle := ""
var _map_prev := {}
var _dice_box: Control = null


func _ready() -> void:
	gs = get_node("/root/GameState")
	Juice.load_settings()
	var bg := ColorRect.new()
	bg.color = C_BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	title_bg = TextureRect.new()
	title_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	title_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	title_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	title_bg.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	title_bg.visible = false
	if ResourceLoader.exists(TITLE_ART):
		title_bg.texture = load(TITLE_ART)
	add_child(title_bg)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	add_child(margin)
	root = VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	margin.add_child(root)
	show_title()


# ================= Tela da Guilda =================

func show_hub() -> void:
	_clear()
	match gs.chapter_state:
		"intro":
			show_chapter_intro()
			return
		"encerrado":
			show_chapter_end()
			return
		"fim_do_ato", "fim_de_jogo":
			show_ending()
			return
	var ch: Dictionary = gs.current_chapter()
	var top := HBoxContainer.new()
	root.add_child(top)
	var titles := VBoxContainer.new()
	titles.add_theme_constant_override("separation", 0)
	top.add_child(titles)
	titles.add_child(_label("A Guilda do Corvo Cinzento", 24, C_GOLD))
	titles.add_child(_label("Capítulo %d — %s   ·   Dia %d/%d   ·   Reputação %d   ·   Ouro %d   ·   Despachos %d/%d" % [ch.number, ch.title, gs.chapter_day(), int(ch.days), gs.reputation, gs.gold, gs.dispatched_today, gs.slots()], 14, C_TEXT))
	top.add_child(_spacer())
	top.add_child(_button("Guilda", show_upgrades))
	top.add_child(_button("Mercado", show_market))
	var rel := _button("Quadro" if gs.affinity_visible() else "🔒 Quadro", show_relations)
	rel.disabled = not gs.affinity_visible()
	rel.tooltip_text = "Construa o Quadro de Relações na tela Guilda." if rel.disabled else "Quadro de Relações"
	top.add_child(rel)
	var book_btn := _button("Livro", show_book.bind(0))
	_button_icon(book_btn, _tex("res://art/book/capa_fechada.png"), 22)
	top.add_child(book_btn)
	top.add_child(_button("Encerrar dia ▶", _on_end_day))
	top.add_child(_button("☰", show_menu))

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
	var bhead := HBoxContainer.new()
	bcol.add_child(bhead)
	bhead.add_child(_label("Mural de Quests", 20, C_GOLD))
	bhead.add_child(_spacer())
	bhead.add_child(_label("Objetivo: " + ch.goal.text, 13, C_MUTED))
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
	for i in board.size():
		var card := _mission_card(board[i])
		list.add_child(card)
		if _fresh_day:
			Juice.fade_in(card, 0.15 + i * 0.09, 0.4)
	_fresh_day = false

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
		row.add_child(_label("%s  Nv %d" % [h.name, h.level], 14, C_TEXT))
		if h.rest_request and not h.resting:
			row.add_child(_label(" ⚠ pede descanso", 12, C_BAD))
		row.add_child(_spacer())
		var state: String = "Descansando" if h.resting else gs.hero_status(id)
		row.add_child(_label(state, 13, C_MUTED if h.resting else _fatigue_color(h)))
		row.add_child(_label("  PV %d/%d  Moral %d " % [h.hp, h.hp_max, h.morale], 13, C_MUTED))
		var rest := _button("Acordar" if h.resting else "Descansar", func():
			gs.set_resting(id, not h.resting)
			show_hub())
		rest.disabled = h.busy
		rest.tooltip_text = "Passa o dia descansando: no fim do dia recupera toda a fadiga, metade do PV, as magias e +1 de moral. Não pode ir em missão hoje."
		row.add_child(rest)

	if gs.has_upgrade("salao"):
		var tb := _button("Salão de Treinamento: treinar uma dupla" if gs.can_train() else "Salão de Treinamento: já usado hoje", show_training)
		tb.disabled = not gs.can_train()
		ccol.add_child(tb)

	# Bastidores
	# Ultimatos (moral baixa) vêm antes de tudo
	for u in gs.open_ultimatums():
		var uc := _panel(Color("#5a2a22"))
		ccol.add_child(uc)
		var ur := HBoxContainer.new()
		uc.add_child(ur)
		ur.add_child(_swatch(gs.heroes[u.id].color))
		ur.add_child(_label(" ⚠ Ultimato: %s quer ir embora" % gs.heroes[u.id].name, 15, C_TEXT))
		ur.add_child(_spacer())
		ur.add_child(_button("Conversar", show_ultimatum.bind(u)))
	for pid in gs.promises:
		ccol.add_child(_label("⏳ Prometido: %s precisa ir em missão até o dia %d do capítulo" % [gs.heroes[pid].name, int(gs.promises[pid]) - gs.chapter_start + 1], 12, C_GOLD))

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
	_play_moments()


func _mission_card(m: Dictionary) -> Control:
	var card := _panel(C_PARCHMENT)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	card.add_child(row)
	var poster := _enemy_poster(m, 84)
	if poster != null:
		row.add_child(poster)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(col)
	var head := HBoxContainer.new()
	col.add_child(head)
	head.add_child(_label(m.name, 17, C_INK))
	head.add_child(_spacer())
	head.add_child(_label("[%s]" % gs.RISK_NAMES[m.risk], 14, RISK_COLORS[m.risk].darkened(0.25)))
	col.add_child(_para(m.desc, 13, C_INK))
	var left: int = gs.expires_on(m) - gs.day
	var prazo := "último dia!" if left <= 0 else "%d dia(s)" % (left + 1)
	col.add_child(_para("Tipo: %s   ·   %s + %s   ·   Prazo: %s   ·   Recompensa: %d ouro" % [m.type.capitalize(), gs.ATTR_NAMES[m.primary], gs.ATTR_NAMES[m.secondary], prazo, gs.mission_reward(m)], 13, C_INK.lightened(0.25)))
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
	gs.save_game("auto")
	_clear()
	var title := "Fim do dia" if gs.chapter_state == "encerrado" else "Dia %d do capítulo" % gs.chapter_day()
	root.add_child(_label(title, 28, C_GOLD))
	root.add_child(_para("Os aventureiros descansam. A taverna esvazia. O mural range com pergaminhos novos.", 15, C_TEXT))
	var items := []
	for l in lines:
		var p := _para("• " + l, 15, C_TEXT)
		root.add_child(p)
		items.append(p)
	root.add_child(_button("Abrir a guilda", show_hub))
	_fresh_day = true
	_day_transition(title, items)


## Transição de dia: a tela escurece como uma vela apagando e volta com o novo dia.
func _day_transition(title: String, items: Array) -> void:
	var veil := ColorRect.new()
	veil.color = Color("#120c08")
	veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(veil)
	var l := _label(title, 34, C_GOLD)
	l.set_anchors_preset(Control.PRESET_CENTER)
	l.grow_horizontal = Control.GROW_DIRECTION_BOTH
	l.grow_vertical = Control.GROW_DIRECTION_BOTH
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	veil.add_child(l)
	var hold := 0.15 if Juice.reduce_motion else 0.55
	var tw := veil.create_tween()
	tw.tween_interval(hold)
	tw.tween_property(veil, "modulate:a", 0.0, 0.5)
	tw.tween_callback(veil.queue_free)
	for i in items.size():
		Juice.fade_in(items[i], hold + 0.2 + i * 0.12, 0.35)


# ================= Montagem de Party =================

func show_party(m: Dictionary) -> void:
	selected = []
	prepared = {}
	_render_party(m)


func _render_party(m: Dictionary) -> void:
	_clear()
	var head := HBoxContainer.new()
	root.add_child(head)
	var poster := _enemy_poster(m, 56)
	if poster != null:
		head.add_child(poster)
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
		var ea: Dictionary = HeroRPG.effective_attrs(gs, id)
		row.add_child(_label("Nv %d · %s %d / %s %d" % [h.level, gs.ATTR_NAMES[m.primary].left(3), ea[m.primary], gs.ATTR_NAMES[m.secondary].left(3), ea[m.secondary]], 13, C_TEXT))
		row.add_child(_spacer())
		row.add_child(_stress_chip(h))
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
		var prow := HBoxContainer.new()
		rcol.add_child(prow)
		if id == _last_toggle:
			Juice.fade_in(prow, 0.0, 0.25)
			Juice.pop(prow, 0.1, 0.25, 0.02)
		prow.add_child(_label("→ %s%s" % [h.name, tired], 14, C_TEXT))
		if HeroRPG.is_caster(gs, id):
			prow.add_child(_spacer())
			prow.add_child(_spell_picker(m, id))

	var pairs := ScoreCalc.pairs_of(selected)
	if pairs.size() > 0:
		rcol.add_child(_label("AFINIDADE DA PARTY:", 14, C_GOLD))
		for pr in pairs:
			var v: int = gs.pair_value(pr[0], pr[1])
			var lbl: String = gs.bond_label(pr[0], pr[1])
			var extra := "  · " + lbl if lbl != "" else ""
			var pl := _label("%s ↔ %s  %s%s" % [gs.heroes[pr[0]].name, gs.heroes[pr[1]].name, gs.describe_aff(v), extra], 14, _aff_color(v))
			rcol.add_child(pl)
			if v <= -3 and _last_toggle in pr:
				Juice.blink(pl, Color(2.0, 0.7, 0.6), 0.8)
	for act in gs.active_bond_actions(selected):
		rcol.add_child(_label("✦ Ação de Vínculo: %s (%s & %s)" % [act.action, gs.heroes[act.a].name, gs.heroes[act.b].name], 14, C_GOLD))

	var unmet: Array = gs.unmet_tags(m, selected)
	if not selected.is_empty():
		var est := ScoreCalc.compute(gs, m, selected, null, prepared)
		if est.powers > 0:
			rcol.add_child(_label("✦ Poderes (itens, talentos, magias): +%d" % est.powers, 14, C_GOLD))
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
		if HeroRPG.reveals_hidden(gs, selected, prepared):
			rcol.add_child(_para("👁 Revelado: " + m.hidden.text, 13, C_GOLD))
		else:
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
		prepared.erase(id)
	elif selected.size() < 4:
		selected.append(id)
	_last_toggle = id
	_render_party(m)
	_last_toggle = ""


func _on_dispatch(m: Dictionary) -> void:
	Expedition.start(gs, m, selected.duplicate(), prepared.duplicate())
	selected = []
	prepared = {}
	show_map(m)
	_stamp_seal()


## O Selo de Cera desce e carimba: a decisão está tomada.
func _stamp_seal() -> void:
	var seal = WaxSeal.new()
	seal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	seal.size = Vector2(170, 170)
	seal.position = get_viewport_rect().size / 2.0 - seal.size / 2.0
	seal.pivot_offset = seal.size / 2.0
	add_child(seal)
	var tw := seal.create_tween()
	if Juice.reduce_motion:
		seal.modulate.a = 0.0
		tw.tween_property(seal, "modulate:a", 1.0, 0.15)
	else:
		seal.scale = Vector2.ONE * 2.4
		seal.modulate.a = 0.0
		tw.set_parallel(true)
		tw.tween_property(seal, "scale", Vector2.ONE, 0.18).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		tw.tween_property(seal, "modulate:a", 1.0, 0.12)
		tw.set_parallel(false)
		tw.tween_callback(func(): Juice.shake(self, 6.0, 0.25); Juice.flash(self, Color("#a8443c"), 0.18, 0.3))
	tw.tween_interval(0.55)
	tw.tween_property(seal, "modulate:a", 0.0, 0.35)
	tw.tween_callback(seal.queue_free)


# ================= Mapa Mágico (expedição) =================

var _map
var _map_party: VBoxContainer
var _map_status: Label
var _map_log: VBoxContainer
var _map_scroll: ScrollContainer
var _map_action: VBoxContainer


func show_map(m: Dictionary) -> void:
	_clear()
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 16)
	root.add_child(body)

	var frame := _panel(Color("#1a1420"))
	frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	frame.size_flags_stretch_ratio = 2.2
	body.add_child(frame)
	_map = MagicMap.new()
	_map.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_map.clip_contents = true
	frame.add_child(_map)

	var side := _panel(C_PANEL)
	side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(side)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	side.add_child(col)
	col.add_child(_label("Mapa Mágico de Escrutínio", 13, C_MUTED))
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	col.add_child(head)
	head.add_child(_para(m.name, 20, C_GOLD))
	head.add_child(_badge(gs.RISK_NAMES[m.risk], RISK_COLORS[m.risk].darkened(0.2)))
	_map_party = VBoxContainer.new()
	_map_party.add_theme_constant_override("separation", 2)
	col.add_child(_map_party)
	_map_status = _para("", 13, C_TEXT)
	col.add_child(_map_status)
	col.add_child(HSeparator.new())
	_map_scroll = ScrollContainer.new()
	_map_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_map_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(_map_scroll)
	_map_log = VBoxContainer.new()
	_map_log.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_map_log.add_theme_constant_override("separation", 6)
	_map_scroll.add_child(_map_log)
	_map_action = VBoxContainer.new()
	_map_action.add_theme_constant_override("separation", 6)
	col.add_child(_map_action)

	var tokens := []
	for id in gs.expedition.party:
		var h: Dictionary = gs.heroes[id]
		tokens.append({"id": id, "name": h.name, "color": h.color, "tex": _tex("res://art/tokens/%s_parado.png" % id)})
	var et := _enemy_texture(m)
	if et != null:
		_map.goal_texture = et
	_map.type_info = gs.route_data.types
	var ets := _enemy_textures(m)
	if ets.size() >= 2:
		_map.mini_texture = ets[1]
	_map.setup(m, tokens, gs.day * 1000 + gs.missions.find(m), gs.expedition)
	_map.node_chosen.connect(_on_node_chosen)
	_map.arrived.connect(_on_node_arrived)
	_log_lines([String(gs.narration.start[0]).replace("{party}", ", ".join(gs.expedition.party.map(func(id): return gs.heroes[id].name)))], C_TEXT)
	_map_refresh()


func _map_refresh() -> void:
	var exp: Dictionary = gs.expedition
	if exp.is_empty() or not is_instance_valid(_map_party):
		return
	for c in _map_party.get_children():
		c.queue_free()
	var prev: Dictionary = _map_prev
	_map_prev = {"provisions": exp.provisions, "gold": exp.gold, "bonus": exp.bonus, "items": exp.items.size(), "hp": {}, "stress": {}}
	for id in exp.party:
		var h: Dictionary = gs.heroes[id]
		_map_prev.hp[id] = h.hp
		_map_prev.stress[id] = int(h.get("stress", 0))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		_map_party.add_child(row)
		if not prev.is_empty():
			if h.hp < int(prev.hp.get(id, h.hp)):
				Juice.blink(row, Color(2.0, 0.6, 0.55), 0.7)
			elif int(h.get("stress", 0)) > int(prev.stress.get(id, 0)):
				Juice.blink(row, Color(1.5, 0.8, 1.6), 0.7)
			elif h.hp > int(prev.hp.get(id, h.hp)):
				Juice.blink(row, Color(0.8, 1.7, 0.9), 0.7)
		row.add_child(_portrait(h, 26))
		row.add_child(_label(h.name, 14, h.color.lightened(0.25)))
		row.add_child(_spacer())
		var low: bool = h.hp <= h.hp_max / 3
		row.add_child(_stress_chip(h))
		row.add_child(_label("PV %d/%d" % [h.hp, h.hp_max], 13, C_BAD if low else C_MUTED))
	var mod := Expedition.route_mod(gs)
	_map_status.text = "Provisões %d   ·   Bolsa da rota %d ouro   ·   Itens %d\nPreparação %+d   ·   Desgaste −%d   ·   Fome −%d   →   Rota no score %+d" % [
		exp.provisions, exp.gold, exp.items.size(), exp.bonus, Expedition.wear(gs), mini(exp.hunger, 2), mod]
	if not prev.is_empty():
		var at := _map_status.global_position + Vector2(_map_status.size.x * 0.35, -6)
		var deltas := [["gold", "%+d ouro", C_GOLD], ["provisions", "%+d provisões", C_TEXT], ["bonus", "%+d preparação", C_GOOD], ["items", "%+d item", C_GOLD]]
		var k := 0
		for d in deltas:
			var dv: int = int(_map_prev[d[0]]) - int(prev[d[0]])
			if dv != 0:
				var colr: Color = C_BAD if dv < 0 else d[2]
				var txt: String = d[1] % dv
				get_tree().create_timer(0.18 * k).timeout.connect(func(): Juice.fly_text(self, txt, at, colr))
				k += 1
		if k > 0:
			Juice.pop(_map_status, 0.05, 0.3)
		if exp.provisions == 0 and int(prev.provisions) > 0:
			Juice.blink(_map_status, Color(2.0, 0.7, 0.6), 1.0)
	_map.reachable = Expedition.choices(gs)
	if exp.pending == "" and not Expedition.at_boss(gs) and _map_action.get_child_count() == 0:
		var hint := "Escolha o próximo caminho no mapa (passe o mouse para ver o que há em cada ponto)."
		if exp.provisions == 0:
			hint += "\nSem provisões: o próximo passo será com fome."
		_map_action.add_child(_para(hint, 14, C_GOLD))


func _log_lines(lines: Array, color: Color = C_TEXT) -> void:
	for l in lines:
		var lbl := _para(l, 14, color)
		lbl.modulate.a = 0.0
		_map_log.add_child(lbl)
		create_tween().tween_property(lbl, "modulate:a", 1.0, 0.5)
	await get_tree().process_frame
	if is_instance_valid(_map_scroll):
		_map_scroll.scroll_vertical = int(_map_scroll.get_v_scroll_bar().max_value)


func _clear_action() -> void:
	for c in _map_action.get_children():
		_map_action.remove_child(c)
		c.queue_free()


func _on_node_chosen(pos: Array) -> void:
	_clear_action()
	_map.move_to(pos)


func _on_node_arrived(pos: Array) -> void:
	var out: Dictionary = Expedition.enter(gs, pos)
	var node: Dictionary = Expedition.node_at(gs, pos)
	_log_lines(["— %s —" % gs.route_data.types[node.type].name], C_GOLD)
	_log_lines(out.lines, C_MUTED)
	_clear_action()
	if out.get("boss", false):
		Juice.flash(self, Color("#a8443c"), 0.15, 0.6)
	if out.get("boss", false):
		var m := Expedition.mission(gs)
		_map_action.add_child(_para("O grupo chegou ao alvo. Rota no score: %+d." % Expedition.route_mod(gs), 14, C_GOLD))
		_map_action.add_child(_button("Enfrentar: " + m.name, _on_face_boss))
	elif out.has("event"):
		_map.caller = out.caller
		_show_call(out.event, out.caller)
	elif out.has("shop"):
		_show_shop(out.shop)
	_map_refresh()
	_play_moments()


## O herói chama pelo Mapa Mágico e pede uma decisão.
func _show_call(ev: Dictionary, caller: String) -> void:
	_clear_action()
	var h: Dictionary = gs.heroes[caller]
	var call := _panel(C_PARCHMENT)
	_map_action.add_child(call)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	call.add_child(row)
	row.add_child(_portrait(h, 56))
	var txt := VBoxContainer.new()
	txt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(txt)
	txt.add_child(_label("%s chama pelo Mapa Mágico:" % h.name, 12, C_INK.lightened(0.3)))
	txt.add_child(_label(ev.title, 17, C_INK))
	txt.add_child(_para(Expedition._fill(gs, ev.text, caller), 14, C_INK))
	for opt in ev.options:
		var hint := Expedition.test_hint(gs, opt)
		var b := _button(opt.label + ("   [%s]" % hint if hint != "" else ""), _on_call_choice.bind(opt))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var block := Expedition.option_block(gs, opt)
		if block != "":
			b.disabled = true
			b.tooltip_text = block
		_map_action.add_child(b)


func _on_call_choice(opt: Dictionary) -> void:
	var r: Dictionary = Expedition.choose(gs, opt)
	_map.caller = ""
	_log_lines(["» " + opt.label], C_GOLD)
	_clear_action()
	var finish := func():
		if not is_instance_valid(_map_log) or gs.expedition.is_empty():
			return
		_log_lines(r.lines, C_TEXT)
		_map_refresh()
		_play_moments()
	if r.has("dice"):
		_roll_dice(r.dice, finish)
	else:
		finish.call()


## d20 visível: gira, quica e para no resultado. Só visual — o teste já foi resolvido.
func _roll_dice(d: Dictionary, done: Callable) -> void:
	var box := _panel(C_PARCHMENT)
	_dice_box = box
	box.top_level = true
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(box)
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(col)
	var who := _label("%s testa %s (CD %d, %+d)" % [gs.heroes[d.hero].name, gs.ATTR_NAMES[d.attr], d.dc, d.mod], 14, C_INK)
	who.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(who)
	var num := _label("20", 54, C_INK)
	num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(num)
	var verdict := _label("", 18, C_INK)
	verdict.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(verdict)
	box.custom_minimum_size = Vector2(260, 150)
	var frame_rect: Rect2 = _map.get_global_rect() if is_instance_valid(_map) else get_viewport_rect()
	box.global_position = frame_rect.get_center() - box.custom_minimum_size / 2.0
	var ok: bool = d.ok
	var color: Color = Color("#3f6b2f") if ok else Color("#8a2f1f")
	var tw := box.create_tween()
	if not Juice.reduce_motion:
		tw.tween_method(func(_v: float): num.text = str(randi_range(1, 20)), 0.0, 1.0, 0.7)
	tw.tween_callback(func():
		num.text = str(d.roll)
		num.add_theme_color_override("font_color", color)
		verdict.text = "%d %+d = %d  —  %s" % [d.roll, d.mod, d.roll + d.mod, "SUCESSO" if ok else "FALHOU"]
		verdict.add_theme_color_override("font_color", color)
		Juice.pop(num, 0.35, 0.3)
		if d.roll == 20:
			Juice.flash(self, Color("#f2d27a"), 0.3, 0.5)
			Juice.shake(self, 3.0, 0.2)
		elif d.roll == 1:
			Juice.flash(self, Color("#8a2f1f"), 0.25, 0.5)
			Juice.shake(self, 5.0, 0.3))
	tw.tween_interval(0.25 if Juice.reduce_motion else 0.8)
	tw.tween_property(box, "modulate:a", 0.0, 0.25)
	tw.tween_callback(func():
		box.queue_free()
		done.call())


func _show_shop(stock: Array) -> void:
	_clear_action()
	_map_action.add_child(_label("Mercador de estrada — ouro da guilda: %d" % gs.gold, 15, C_GOLD))
	for iid in stock:
		var it: Dictionary = HeroRPG.item(gs, iid)
		var b := _button("%s — %d ouro" % [it.name, int(it.price)], func():
			if HeroRPG.buy(gs, iid):
				_log_lines(["Comprado: %s (vai para o Baú)." % it.name], C_TEXT)
				stock.erase(iid)
			_show_shop(stock))
		b.tooltip_text = it.get("desc", "")
		_button_icon(b, _item_tex(iid), 32)
		b.disabled = gs.gold < int(it.price)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		_map_action.add_child(b)
	var sp: Dictionary = gs.route_data.shop_provisions
	var pb := _button("Provisões (+%d) — %d ouro" % [int(sp.amount), int(sp.price)], func():
		if Expedition.buy_provisions(gs):
			_log_lines(["Provisões compradas (+%d)." % int(sp.amount)], C_TEXT)
		_show_shop(stock)
		_map_refresh())
	_button_icon(pb, _tex("res://art/items/provisoes.png"), 32)
	pb.disabled = gs.gold < int(sp.price)
	pb.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_map_action.add_child(pb)
	_map_action.add_child(_button("Seguir viagem ▶", func():
		_clear_action()
		_map_refresh()))


func _on_face_boss() -> void:
	var res: Dictionary = Expedition.finish(gs)
	last_result = res
	show_result(res)


# ================= Resolução =================

func show_result(res: Dictionary) -> void:
	_clear()
	var m: Dictionary = res.mission
	var rhead := HBoxContainer.new()
	rhead.add_theme_constant_override("separation", 14)
	root.add_child(rhead)
	var reveal := 0.15 if Juice.reduce_motion else 1.0   # tempo até o veredito
	var poster := _enemy_poster(m, 104, res.outcome != "falha", reveal)
	if poster != null:
		rhead.add_child(poster)
	var rtitles := VBoxContainer.new()
	rtitles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rhead.add_child(rtitles)
	rtitles.add_child(_label(m.name, 22, C_GOLD))
	var verdict := _label(gs.OUTCOME_NAMES[res.outcome], 30, OUTCOME_COLORS[res.outcome])
	rtitles.add_child(verdict)
	verdict.modulate.a = 0.0

	# Placar: a barra enche até o resultado, com as linhas de custo e limpo
	var sc: Dictionary = res.score
	var t: Array = ScoreCalc.THRESHOLDS[m.risk]
	var meter := HBoxContainer.new()
	meter.add_theme_constant_override("separation", 10)
	rtitles.add_child(meter)
	var num := _label("0.0", 20, C_TEXT)
	num.custom_minimum_size.x = 56
	meter.add_child(num)
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.max_value = t[1] + 3
	bar.custom_minimum_size = Vector2(260, 14)
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var fill := StyleBoxFlat.new()
	fill.bg_color = OUTCOME_COLORS[res.outcome]
	bar.add_theme_stylebox_override("fill", fill)
	meter.add_child(bar)
	meter.add_child(_label("custo ≥ %d · limpo ≥ %d" % [t[0], t[1]], 13, C_MUTED))
	Juice.count(num, 0.0, sc.total, "%.1f", reveal * 0.9)
	var btw := bar.create_tween()
	btw.tween_property(bar, "value", clampf(sc.total, 0.0, bar.max_value), reveal * 0.9).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	btw.tween_callback(func():
		verdict.modulate.a = 1.0
		Juice.pop(verdict, 0.35, 0.35)
		match res.outcome:
			"limpo":
				Juice.flash(self, Color("#f2d27a"), 0.18, 0.5)
			"falha":
				Juice.shake(self, 4.0, 0.3)
		_play_moments())

	var p := _panel(C_PARCHMENT)
	root.add_child(p)
	Juice.fade_in(p, reveal + 0.1, 0.4)
	var col := VBoxContainer.new()
	p.add_child(col)
	for l in res.lines:
		col.add_child(_para(l, 16, C_INK))

	root.add_child(_para("Score %.1f  =  Base %.1f  + Cobertura %d  + Afinidade %+.1f  + Vínculo %d  + Poderes %d  + Oculto %d  + Mente %+d  + Rota %+d  + Sorte %+d      (custo ≥ %d · limpo ≥ %d)" % [sc.total, sc.base, sc.coverage, sc.affinity, sc.bond, sc.powers, sc.hidden, int(sc.get("mind", 0)), int(sc.get("route", 0)), sc.luck, t[0], t[1]], 13, C_MUTED))
	if res.has("route"):
		var rt: Dictionary = res.route
		root.add_child(_para("Rota: preparação %+d · desgaste −%d · fome −%d" % [rt.bonus, rt.wear, mini(rt.hunger, 2)], 13, C_MUTED))

	if not res.affinity.is_empty():
		root.add_child(_label("Vínculos", 16, C_GOLD))
		for ch in res.affinity:
			var arrow := "▲" if ch.after > ch.before else ("▼" if ch.after < ch.before else "=")
			var al := _label("%s ↔ %s   %s  %s" % [gs.heroes[ch.a].name, gs.heroes[ch.b].name, gs.describe_change(ch.before, ch.after), arrow], 14, _aff_color(ch.after))
			root.add_child(al)
			Juice.fade_in(al, reveal + 0.4 + res.affinity.find(ch) * 0.12, 0.3)
	root.add_child(_spacer_v())
	root.add_child(_button("Continuar", _after_result))


## Encena um momento de personagem por vez (ruptura, saída), por cima da tela atual.
func _play_moments() -> void:
	if not moments_enabled or _moment_open or gs.pending_moments.is_empty():
		return
	var mo: Dictionary = gs.pending_moments.pop_front()
	if not gs.heroes.has(mo.id):
		_play_moments()
		return
	_moment_open = true
	var h: Dictionary = gs.heroes[mo.id]
	var layer := Control.new()
	layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(layer)
	_moment_layer = layer
	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.03, 0.02, 0.82)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(center)
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 12)
	col.custom_minimum_size.x = 560
	center.add_child(col)
	var por := _portrait(h, 150)
	por.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(por)
	var title := ""
	var tcol := C_GOLD
	match mo.type:
		"ruptura":
			var virtue: bool = mo.kind == "virtude"
			title = ("✦ %s encontra força: %s" if virtue else "%s quebra: %s") % [h.name, mo.name]
			tcol = Color("#f2d27a") if virtue else C_BAD
			if virtue:
				Juice.flash(self, Color("#f2d27a"), 0.35, 0.8)
				Juice.pop(por, 0.15, 0.5)
			else:
				Juice.flash(self, Color("#8a2f1f"), 0.35, 0.8)
				Juice.shake(self, 7.0, 0.4)
		"saida":
			title = "%s deixou a guilda" % h.name
			tcol = C_MUTED
			Juice.desaturate(por, Color(0.75, 0.66, 0.52, 0.75), 1.4)
	var tl := _label(title, 26, tcol)
	tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(tl)
	var body := _para(String(mo.text), 17, C_TEXT)
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(body)
	Juice.typewrite(body)
	var btn := _button("Continuar", func():
		layer.queue_free()
		_moment_open = false
		_play_moments())
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(btn)
	Juice.fade_in(layer, 0.0, 0.3)


func _after_result() -> void:
	if not gs.pending_events.is_empty():
		show_bond_event(gs.pending_events.pop_front())
	elif not gs.pending_levelups.is_empty():
		show_levelup(gs.pending_levelups.pop_front())
	else:
		show_hub()


# ================= Evento de Vínculo =================

func show_bond_event(ev: Dictionary) -> void:
	_clear()
	var info: Dictionary = gs.THRESHOLD_EVENTS[ev.threshold]
	var a: Dictionary = gs.heroes[ev.a]
	var b: Dictionary = gs.heroes[ev.b]
	root.add_child(_label("Bastidores da guilda", 16, C_MUTED))
	var bt := _label("\"%s\"" % info.title, 28, C_GOLD)
	root.add_child(bt)
	var pair := HBoxContainer.new()
	pair.alignment = BoxContainer.ALIGNMENT_CENTER
	pair.add_theme_constant_override("separation", 0)
	root.add_child(pair)
	var pa := _portrait(a, 84)
	var pb := _portrait(b, 84)
	var thread := ColorRect.new()
	thread.color = C_GOLD if ev.threshold > 0 else C_BAD
	thread.custom_minimum_size = Vector2(0, 3)
	thread.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pair.add_child(pa)
	pair.add_child(thread)
	pair.add_child(pb)
	Juice.fade_in(pa, 0.0, 0.4)
	Juice.fade_in(pb, 0.15, 0.4)
	var ttw := thread.create_tween()
	ttw.tween_interval(0.05 if Juice.reduce_motion else 0.35)
	ttw.tween_property(thread, "custom_minimum_size:x", 140.0, 0.1 if Juice.reduce_motion else 0.5).set_ease(Tween.EASE_OUT)
	Juice.pop(bt, 0.1, 0.3, 0.3)
	root.add_child(_label("%s e %s  ·  %s" % [a.name, b.name, gs.describe_aff(gs.pair_value(ev.a, ev.b))], 18, C_TEXT))
	root.add_child(_label("Como você enxerga o que existe entre eles?", 15, C_TEXT))
	for lbl in info.labels:
		var action: String = gs.BOND_ACTIONS.get(lbl, "")
		var hint := "  — desbloqueia \"%s\" em Laço Forte" % action if action != "" else ""
		root.add_child(_button(lbl + hint, _on_label_chosen.bind(ev, lbl)))


func _on_label_chosen(ev: Dictionary, lbl: String) -> void:
	gs.choose_bond_label(ev, lbl)
	Juice.flash(self, C_GOLD if ev.threshold > 0 else C_BAD, 0.2, 0.5)
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
	who.add_child(_label("   " + gs.describe_aff(gs.pair_value(bs.a, bs.b)), 14, _aff_color(gs.pair_value(bs.a, bs.b))))
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
		grid.add_child(_hero_header(id, true))
	for a in gs.hero_order:
		grid.add_child(_hero_header(a, false))
		for b in gs.hero_order:
			if a == b:
				var self_cell := _cell("—", C_PANEL, C_MUTED, "")
				self_cell.custom_minimum_size = Vector2(96, 52)
				grid.add_child(self_cell)
				continue
			var v: int = gs.pair_value(a, b)
			var lbl: String = gs.bond_label(a, b)
			var tip := "%s → %s: %+d\n%s → %s: %+d\n%s%s" % [gs.heroes[a].name, gs.heroes[b].name, gs.affinity[a][b], gs.heroes[b].name, gs.heroes[a].name, gs.affinity[b][a], gs.band(v).label, ("\nVínculo: " + lbl) if lbl != "" else ""]
			tip += "\nSem missão juntos há %d dia(s)" % gs.days_apart(a, b)
			if gs.has_upgrade("arquivo"):
				var hist: Array = gs.pair_missions(a, b)
				tip += "\n— Arquivo: %d missão(ões) juntos —" % hist.size()
				for e in hist:
					tip += "\nDia %d · %s · %s" % [e.day, e.mission, gs.OUTCOME_NAMES[e.outcome]]
			var cell := _cell("%+d%s" % [v, " ✦" if lbl != "" else ""], _aff_color(v).darkened(0.55), C_TEXT, tip)
			cell.custom_minimum_size = Vector2(96, 52)
			grid.add_child(cell)
	root.add_child(_spacer_v())
	root.add_child(_button("◀ Voltar", show_hub))


# ================= Livro da Guilda =================

func show_book(index: int) -> void:
	_clear()
	var desk := _tex("res://art/book/livro_aberto.png")
	if desk != null:
		title_bg.texture = desk
		title_bg.modulate = Color(0.32, 0.27, 0.22)
		title_bg.visible = true
	var book = GuildBook.new()
	root.add_child(book)
	book.setup(self, gs, index)
	book.closed.connect(show_hub)


# ================= Capítulos =================

func show_chapter_intro() -> void:
	_clear()
	var ch: Dictionary = gs.current_chapter()
	root.add_child(_label(gs.act.title, 16, C_MUTED))
	root.add_child(_label("Capítulo %d" % ch.number, 20, C_GOLD))
	root.add_child(_label(ch.title, 36, C_GOLD))
	var p := _panel(C_PARCHMENT)
	root.add_child(p)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	p.add_child(col)
	for l in gs.chapter_intro():
		col.add_child(_para(l, 17, C_INK))
	for rid in gs.chapter_recruits():
		col.add_child(_para("✦ " + gs.heroes[rid].joins_text, 17, Color("#3f6b2f")))
	root.add_child(_label("Objetivo: %s   ·   Duração: %d dias" % [ch.goal.text, int(ch.days)], 15, C_TEXT))
	root.add_child(_spacer_v())
	root.add_child(_button("Começar o capítulo", func():
		gs.begin_chapter()
		show_hub()))


func show_chapter_end() -> void:
	_clear()
	var r: Dictionary = gs.chapter_result
	var ch: Dictionary = r.chapter
	root.add_child(_label("Fim do Capítulo %d — %s" % [ch.number, ch.title], 28, C_GOLD))
	root.add_child(_label(("✓ Objetivo cumprido: " if r.success else "✗ Objetivo não cumprido: ") + ch.goal.text, 17, C_GOOD if r.success else C_BAD))
	var p := _panel(C_PARCHMENT)
	root.add_child(p)
	p.add_child(_para(r.text, 17, C_INK))
	var done := 0
	var total := 0
	for m in gs.missions:
		if ch.missions.has(m.id):
			total += 1
			if m.status == "concluida":
				done += 1
	root.add_child(_label("Missões concluídas: %d/%d   ·   Reputação: %d   ·   Ouro: %d" % [done, total, gs.reputation, gs.gold], 15, C_TEXT))
	root.add_child(_spacer_v())
	root.add_child(_button("Continuar", func():
		gs.next_chapter()
		show_hub()))


# ================= Upgrades da Guilda =================

func show_upgrades() -> void:
	_clear()
	var top := HBoxContainer.new()
	root.add_child(top)
	top.add_child(_label("Melhorias da Guilda", 24, C_GOLD))
	top.add_child(_spacer())
	top.add_child(_label("Ouro %d   ·   Reputação %d" % [gs.gold, gs.reputation], 16, C_TEXT))
	root.add_child(_para("A guilda está caindo aos pedaços. Cada reforma muda o que você enxerga — e o que seus aventureiros conseguem fazer.", 14, C_MUTED))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	root.add_child(grid)
	for up in gs.upgrades_data.upgrades:
		var owned: bool = gs.has_upgrade(up.id)
		var card := _panel(C_PARCHMENT if owned else Color("#4a3a2a"))
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(card)
		var col := VBoxContainer.new()
		card.add_child(col)
		var ink := C_INK if owned else C_TEXT
		col.add_child(_label(("✓ " if owned else "") + up.name, 18, ink))
		col.add_child(_para(up.desc, 13, ink))
		var row := HBoxContainer.new()
		col.add_child(row)
		row.add_child(_label("%d ouro · Reputação %d+" % [int(up.cost), int(up.rep)], 13, C_MUTED if not owned else C_INK.lightened(0.3)))
		row.add_child(_spacer())
		var reason: String = gs.upgrade_block_reason(up)
		var b := _button("Construir" if reason == "" else reason, func():
			gs.buy_upgrade(up.id)
			show_upgrades())
		b.disabled = reason != ""
		row.add_child(b)
	var slots_info := "Slots de missão por dia: %d (Reputação 5 → 2 slots · Reputação 12 → 3 slots)" % gs.slots()
	root.add_child(_label(slots_info, 14, C_TEXT))
	root.add_child(_spacer_v())
	root.add_child(_button("◀ Voltar", show_hub))


# ================= Salão de Treinamento =================

var _train_pick: Array = []

func show_training() -> void:
	_clear()
	root.add_child(_label("Salão de Treinamento", 24, C_GOLD))
	root.add_child(_para("Escolha dois aventureiros prontos. A dupla ganha afinidade, mas os dois ficam Cansados para o resto do dia.", 14, C_MUTED))
	for id in gs.hero_order:
		var h: Dictionary = gs.heroes[id]
		var reason: String = gs.train_reason(id)
		var row := HBoxContainer.new()
		root.add_child(row)
		row.add_child(_swatch(h.color))
		var sel := _train_pick.has(id)
		var b := _button(("✓ " if sel else "") + h.name, func():
			if _train_pick.has(id):
				_train_pick.erase(id)
			elif _train_pick.size() < 2:
				_train_pick.append(id)
			show_training())
		b.custom_minimum_size.x = 120
		b.disabled = reason != "" or (not sel and _train_pick.size() >= 2)
		row.add_child(b)
		row.add_child(_label("  " + (reason if reason != "" else gs.hero_status(id)), 13, C_BAD if reason != "" else C_GOOD))
	if _train_pick.size() == 2:
		root.add_child(_label("%s ↔ %s: %s" % [gs.heroes[_train_pick[0]].name, gs.heroes[_train_pick[1]].name, gs.describe_aff(gs.pair_value(_train_pick[0], _train_pick[1]))], 15, C_TEXT))
	root.add_child(_spacer_v())
	var foot := HBoxContainer.new()
	root.add_child(foot)
	foot.add_child(_button("◀ Voltar", func():
		_train_pick = []
		show_hub()))
	foot.add_child(_spacer())
	var go := _button("Treinar", func():
		var lines: Array = gs.train_pair(_train_pick[0], _train_pick[1])
		_train_pick = []
		_clear()
		root.add_child(_label("Salão de Treinamento", 24, C_GOLD))
		var p := _panel(C_PARCHMENT)
		root.add_child(p)
		p.add_child(_para(lines[0], 17, C_INK))
		root.add_child(_spacer_v())
		root.add_child(_button("Continuar", _after_result)))
	go.disabled = _train_pick.size() != 2
	foot.add_child(go)


# ================= RPG: magias na montagem =================

func _spell_picker(m: Dictionary, id: String) -> Control:
	var h: Dictionary = gs.heroes[id]
	var ob := OptionButton.new()
	ob.add_item("Sem magia (%d espaço(s))" % h.slots)
	ob.set_item_metadata(0, "")
	var i := 1
	for sid in h.spells_known:
		ob.add_item(HeroRPG.spell(gs, sid).name)
		ob.set_item_metadata(i, sid)
		ob.set_item_tooltip(i, HeroRPG.spell(gs, sid).desc)
		if prepared.get(id, "") == sid:
			ob.select(i)
		i += 1
	ob.disabled = h.slots <= 0
	ob.tooltip_text = "Sem espaços de magia: precisa descansar." if h.slots <= 0 else "Magia preparada para esta missão (gasta 1 espaço)."
	ob.item_selected.connect(func(idx: int):
		var sid: String = ob.get_item_metadata(idx)
		if sid == "":
			prepared.erase(id)
		else:
			prepared[id] = sid
		_render_party(m))
	return ob


# ================= RPG: subida de nível =================

func show_levelup(entry: Dictionary) -> void:
	_clear()
	var h: Dictionary = gs.heroes[entry.id]
	var opts: Dictionary = HeroRPG.levelup_options(gs, entry)
	var pick := {"attr": "", "choice": {}}
	var head := HBoxContainer.new()
	root.add_child(head)
	var lp := _portrait(h, 72)
	head.add_child(lp)
	var lt := _label("  %s chegou ao nível %d!" % [h.name, entry.level], 28, C_GOLD)
	head.add_child(lt)
	Juice.flash(self, Color("#f2d27a"), 0.2, 0.6)
	Juice.pop(lp, 0.2, 0.4, 0.05)
	Juice.pop(lt, 0.1, 0.35, 0.15)
	root.add_child(_label("%s · %s" % [h["class"], h.archetype], 15, C_MUTED))

	root.add_child(_label("Escolha um atributo para melhorar (+1):", 16, C_TEXT))
	var arow := HBoxContainer.new()
	arow.add_theme_constant_override("separation", 8)
	root.add_child(arow)
	var attr_buttons := []
	for k in gs.ATTRS:
		var b := _button("%s\n%d → %d" % [gs.ATTR_NAMES[k], h.attrs[k], h.attrs[k] + 1], func(): pass)
		b.toggle_mode = true
		b.custom_minimum_size = Vector2(140, 56)
		b.disabled = not opts.attrs.has(k)
		attr_buttons.append(b)
		arow.add_child(b)
	var choice_buttons := []
	if not opts.choices.is_empty():
		var kind: String = "uma nova magia" if opts.choices[0].kind == "spell" else "um novo talento"
		root.add_child(_label("Nível marcante! Escolha %s:" % kind, 16, C_GOLD))
		for c in opts.choices:
			var b := _button("%s — %s" % [c.name, c.desc], func(): pass)
			b.toggle_mode = true
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT
			choice_buttons.append(b)
			root.add_child(b)
	root.add_child(_spacer_v())
	var confirm := _button("Confirmar", func():
		HeroRPG.apply_levelup(gs, entry, pick.attr, pick.choice)
		_after_result())
	confirm.disabled = true
	root.add_child(confirm)
	var refresh := func():
		confirm.disabled = (pick.attr == "" and not opts.attrs.is_empty()) or (pick.choice.is_empty() and not opts.choices.is_empty())
	for i in attr_buttons.size():
		var k: String = gs.ATTRS[i]
		attr_buttons[i].pressed.connect(func():
			pick.attr = k
			for j in attr_buttons.size():
				attr_buttons[j].button_pressed = j == i
			refresh.call())
	for i in choice_buttons.size():
		var c: Dictionary = opts.choices[i]
		choice_buttons[i].pressed.connect(func():
			pick.choice = c
			for j in choice_buttons.size():
				choice_buttons[j].button_pressed = j == i
			refresh.call())
	refresh.call()


# ================= RPG: mercado =================

func show_market() -> void:
	_clear()
	var top := HBoxContainer.new()
	root.add_child(top)
	top.add_child(_label("Mercado de Pedravale", 24, C_GOLD))
	top.add_child(_spacer())
	top.add_child(_label("Ouro %d" % gs.gold, 18, C_TEXT))
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 16)
	root.add_child(body)

	var lp := _panel(C_PANEL)
	lp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(lp)
	var lcol := VBoxContainer.new()
	lp.add_child(lcol)
	lcol.add_child(_label("À venda", 18, C_GOLD))
	for iid in HeroRPG.shop_items(gs):
		var it := HeroRPG.item(gs, iid)
		lcol.add_child(_item_row(it, "Comprar %d" % int(it.price), gs.gold < int(it.price), func():
			HeroRPG.buy(gs, iid)
			show_market()))

	var rp := _panel(C_PANEL)
	rp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(rp)
	var rcol := VBoxContainer.new()
	rp.add_child(rcol)
	rcol.add_child(_label("Baú da Guilda (vender)", 18, C_GOLD))
	if gs.inventory.is_empty():
		rcol.add_child(_label("O baú está vazio.", 14, C_MUTED))
	for i in gs.inventory.size():
		var iid: String = gs.inventory[i]
		var it := HeroRPG.item(gs, iid)
		rcol.add_child(_item_row(it, "Vender %d" % HeroRPG.sell_price(gs, iid), false, func():
			HeroRPG.sell(gs, i)
			show_market()))
	root.add_child(_button("◀ Voltar", show_hub))


func _item_row(it: Dictionary, action: String, disabled: bool, cb: Callable, iid: String = "") -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	if iid == "":
		for k in gs.items_data.items:
			if is_same(gs.items_data.items[k], it):
				iid = k
	var tex := _item_tex(iid)
	if tex != null:
		row.add_child(_icon(tex, 40))
	var name := _label(("★ " if it.get("rare", false) else "") + it.name, 14, C_GOLD if it.get("rare", false) else C_TEXT)
	name.custom_minimum_size.x = 190
	row.add_child(name)
	var d := _para(it.desc, 12, C_MUTED)
	row.add_child(d)
	var b := _button(action, cb)
	b.disabled = disabled
	row.add_child(b)
	return row


# ================= RPG: equipamento =================

func show_equip(index: int) -> void:
	_clear()
	var id: String = gs.hero_order[index]
	var h: Dictionary = gs.heroes[id]
	var top := HBoxContainer.new()
	root.add_child(top)
	top.add_child(_swatch(h.color, 24))
	top.add_child(_label("  Equipamento de %s" % h.name, 24, C_GOLD))
	top.add_child(_spacer())
	var armor: Array = HeroRPG.class_info(gs, id).get("armor", [])
	top.add_child(_label("%s · armaduras: %s" % [h["class"], ", ".join(armor.map(func(a): return HeroRPG.ARMOR_NAMES[a])) if not armor.is_empty() else "nenhuma"], 14, C_MUTED))
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 16)
	root.add_child(body)

	var lp := _panel(C_PANEL)
	lp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(lp)
	var lcol := VBoxContainer.new()
	lcol.add_theme_constant_override("separation", 8)
	lp.add_child(lcol)
	lcol.add_child(_label("Equipado", 18, C_GOLD))
	for slot in HeroRPG.SLOTS:
		var row := HBoxContainer.new()
		lcol.add_child(row)
		var sl := _label(HeroRPG.SLOT_NAMES[slot], 14, C_MUTED)
		sl.custom_minimum_size.x = 100
		row.add_child(sl)
		var cur: String = h.equip[slot]
		if cur == "":
			row.add_child(_label("—", 14, C_MUTED))
		else:
			var it := HeroRPG.item(gs, cur)
			var et := _item_tex(cur)
			if et != null:
				row.add_child(_icon(et, 36))
			row.add_child(_label(it.name, 14, C_TEXT))
			row.add_child(_para(it.desc, 12, C_MUTED))
			row.add_child(_button("Remover", func():
				HeroRPG.unequip(gs, id, slot)
				show_equip(index)))

	var rp := _panel(C_PANEL)
	rp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(rp)
	var rcol := VBoxContainer.new()
	rcol.add_theme_constant_override("separation", 6)
	rp.add_child(rcol)
	rcol.add_child(_label("Baú da Guilda", 18, C_GOLD))
	if gs.inventory.is_empty():
		rcol.add_child(_label("O baú está vazio. Missões trazem saque; o Mercado vende o básico.", 13, C_MUTED))
	for i in gs.inventory.size():
		var iid: String = gs.inventory[i]
		var it := HeroRPG.item(gs, iid)
		var target := ""
		if it.slot == "consumivel":
			target = "consumivel1" if h.equip.consumivel1 == "" else "consumivel2"
		else:
			target = it.slot
		var reason := HeroRPG.equip_block_reason(gs, id, target, iid)
		var row := _item_row(it, "Equipar" if reason == "" else reason, reason != "", func():
			HeroRPG.equip(gs, id, target, i)
			show_equip(index))
		rcol.add_child(row)
		if it.has("hub"):
			row.add_child(_button("Usar em %s" % h.name, func():
				var msg := HeroRPG.use_item_hub(gs, i, id)
				_toast(msg, show_equip.bind(index))))
	root.add_child(_button("◀ Voltar ao Livro", show_book.bind(index)))


## Lançar magia da guilda: escolhe o alvo.
func show_cast(caster: String, sid: String, back_index: int) -> void:
	_clear()
	var sp := HeroRPG.spell(gs, sid)
	root.add_child(_label("%s — %s" % [gs.heroes[caster].name, sp.name], 24, C_GOLD))
	root.add_child(_para(sp.desc, 14, C_MUTED))
	root.add_child(_label("Em quem?", 16, C_TEXT))
	for id in gs.hero_order:
		var h: Dictionary = gs.heroes[id]
		var b := _button("%s   PV %d/%d   %s" % [h.name, h.hp, h.hp_max, gs.hero_status(id)], func():
			_toast(HeroRPG.cast_hub(gs, caster, sid, id), show_book.bind(back_index)))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.disabled = h.busy
		root.add_child(b)
	root.add_child(_spacer_v())
	root.add_child(_button("◀ Voltar", show_book.bind(back_index)))


func _toast(msg: String, next: Callable) -> void:
	_clear()
	var p := _panel(C_PARCHMENT)
	root.add_child(p)
	p.add_child(_para(msg, 17, C_INK))
	root.add_child(_spacer_v())
	root.add_child(_button("Continuar", next))


# ================= Ultimato =================

func show_ultimatum(u: Dictionary) -> void:
	_clear()
	var h: Dictionary = gs.heroes[u.id]
	root.add_child(_label("Ultimato", 16, C_BAD))
	var head := HBoxContainer.new()
	root.add_child(head)
	var up := _portrait(h, 72)
	head.add_child(up)
	Juice.desaturate(root, Color(0.86, 0.8, 0.74), 1.2)
	Juice.blink(up, Color(1.6, 0.7, 0.6), 0.9)
	head.add_child(_label("  %s está no limite" % h.name, 28, C_GOLD))
	root.add_child(_label("Moral %d/10   ·   %s   ·   Nível %d" % [h.morale, gs.hero_status(u.id), h.level], 15, C_TEXT))
	var p := _panel(C_PARCHMENT)
	root.add_child(p)
	p.add_child(_para(gs.ultimatum_text(u.id, gs.ultimatum_data.text), 17, C_INK))
	root.add_child(_para("Se você não responder hoje, %s parte amanhã — e o equipamento fica no Baú." % h.name, 13, C_MUTED))
	for choice in gs.ultimatum_data.choices:
		var reason: String = gs.ultimatum_block_reason(choice)
		var b := _button(gs.ultimatum_text(u.id, choice.label) + ("" if reason == "" else "  (%s)" % reason), func():
			_toast("\n".join(gs.resolve_ultimatum(u, choice)), show_hub))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.disabled = reason != ""
		root.add_child(b)
	root.add_child(_spacer_v())
	root.add_child(_button("◀ Voltar (decidir depois)", show_hub))


# ================= Fim do Ato =================

func show_ending() -> void:
	_clear()
	root.add_child(_label(gs.act.title, 30, C_GOLD))
	var p := _panel(C_PARCHMENT)
	root.add_child(p)
	p.add_child(_para(gs.act.ending, 18, C_INK))
	for cid in gs.act.chapters:
		for ch in gs.chapters_data.chapters:
			if ch.id == cid:
				var ok: bool = gs.flags.has(ch.get("flag_success", ""))
				root.add_child(_label("%s Capítulo %d — %s" % ["✓" if ok else "✗", ch.number, ch.title], 15, C_GOOD if ok else C_BAD))
	root.add_child(_label("Reputação final: %d   ·   Ouro: %d   ·   Melhorias: %d/%d" % [gs.reputation, gs.gold, gs.upgrades_owned.size(), gs.upgrades_data.upgrades.size()], 16, C_TEXT))
	for key in gs.bond_labels:
		var ids: PackedStringArray = key.split("|")
		root.add_child(_label("✦ %s & %s — %s" % [gs.heroes[ids[0]].name, gs.heroes[ids[1]].name, gs.bond_labels[key]], 15, C_TEXT))
	for did in gs.departed:
		root.add_child(_label("✗ %s deixou a guilda" % gs.heroes[did].name, 15, C_BAD))
	root.add_child(_spacer_v())
	if gs.chapter_state == "fim_do_ato" and gs.has_next_act():
		var nxt: Dictionary = gs.chapters_data.acts[gs.act_index + 1]
		root.add_child(_button("Continuar: " + nxt.title, func():
			gs.next_act()
			show_hub()))
	else:
		root.add_child(_button("Ver o epílogo", show_epilogue))


# ================= Epílogo =================

func show_epilogue() -> void:
	_clear()
	if gs.chapter_state != "fim_de_jogo":
		gs.next_act()   # fecha o último ato
	gs.save_game("auto")
	var ep: Dictionary = gs.epilogue()
	root.add_child(_label("Epílogo", 16, C_MUTED))
	root.add_child(_label(ep.title, 32, C_GOLD))
	var p := _panel(C_PARCHMENT)
	root.add_child(p)
	p.add_child(_para(ep.text, 17, C_INK))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 8)
	scroll.add_child(col)
	for e in ep.heroes:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		col.add_child(row)
		var h: Dictionary = gs.heroes[e.id]
		var por := _portrait(h, 48)
		if gs.departed.has(e.id):
			por.modulate = Color(1, 1, 1, 0.45)
		row.add_child(por)
		row.add_child(_para(e.text, 15, C_MUTED if gs.departed.has(e.id) else C_TEXT))
	for b in ep.bonds:
		col.add_child(_para("✦ " + b, 15, C_GOLD))
	var foot := HBoxContainer.new()
	root.add_child(foot)
	foot.add_child(_label("Reputação final %d   ·   Ouro %d" % [gs.reputation, gs.gold], 14, C_MUTED))
	foot.add_child(_spacer())
	foot.add_child(_button("Voltar ao título", show_title))


# ================= Título, menu, salvar e carregar =================

func show_title() -> void:
	_clear()
	var has_art := title_bg.texture != null
	title_bg.visible = has_art
	var t := _label("A Guilda", 64, C_GOLD)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_constant_override("outline_size", 12)
	t.add_theme_color_override("font_outline_color", Color("#1a120c"))
	root.add_child(t)
	var st := _label("Quem você envia define quem eles se tornam", 18, C_TEXT if has_art else C_MUTED)
	st.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	st.add_theme_constant_override("outline_size", 6)
	st.add_theme_color_override("font_outline_color", Color("#1a120c"))
	root.add_child(st)
	if not has_art:
		var faces := HBoxContainer.new()
		faces.alignment = BoxContainer.ALIGNMENT_CENTER
		faces.add_theme_constant_override("separation", 10)
		root.add_child(faces)
		for id in gs.hero_order:
			faces.add_child(_portrait(gs.heroes[id], 64))
	root.add_child(_spacer_v())
	# Botões numa faixa no rodapé, para não cobrir a arte do grupo
	var bar := PanelContainer.new()
	bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.1, 0.07, 0.05, 0.78)
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(8)
	bar.add_theme_stylebox_override("panel", sb)
	root.add_child(bar)
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	bar.add_child(box)
	var latest: String = gs.latest_save()
	var cont := _button("Continuar", func():
		if gs.load_game(latest):
			show_hub())
	cont.disabled = latest == ""
	if latest != "":
		var m: Dictionary = gs.save_meta(latest)
		cont.tooltip_text = "%s — %s, dia %d" % [m.act, m.chapter, m.chapter_day]
	box.add_child(cont)
	box.add_child(_button("Novo jogo", _on_new_game))
	var ld := _button("Carregar", show_load.bind(true))
	ld.disabled = not gs.has_any_save()
	box.add_child(ld)
	box.add_child(_button("Sair", func(): get_tree().quit()))
	for b in box.get_children():
		b.custom_minimum_size.x = 150


func show_menu() -> void:
	_clear()
	root.add_child(_label("Menu", 28, C_GOLD))
	root.add_child(_label("Salvar o jogo", 18, C_TEXT))
	for slot in ["1", "2", "3"]:
		var m: Dictionary = gs.save_meta(slot)
		var desc := "vazio" if m.is_empty() else "%s — %s, dia %d · %s" % [m.act, m.chapter, m.chapter_day, m.saved_at]
		var b := _button("Espaço %s:  %s" % [slot, desc], func():
			var ok: bool = gs.save_game(slot)
			_toast("Jogo salvo no espaço %s." % slot if ok else "Não foi possível salvar.", show_menu))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		root.add_child(b)
	root.add_child(_label("O jogo também salva sozinho ao fim de cada dia (espaço automático).", 13, C_MUTED))
	root.add_child(_button("Carregar um jogo", show_load.bind(false)))
	root.add_child(_label("Opções", 18, C_TEXT))
	root.add_child(_button("Reduzir movimento (sem tremor, sem zoom, animações curtas): %s" % ("Sim" if Juice.reduce_motion else "Não"), func():
		Juice.set_reduce_motion(not Juice.reduce_motion)
		show_menu()))
	root.add_child(_button("Voltar ao título", show_title))
	root.add_child(_spacer_v())
	root.add_child(_button("◀ Voltar ao jogo", show_hub))


func show_load(from_title: bool) -> void:
	_clear()
	root.add_child(_label("Carregar", 28, C_GOLD))
	for slot in gs.SAVE_SLOTS:
		var m: Dictionary = gs.save_meta(slot)
		var name: String = "Automático" if slot == "auto" else "Espaço " + slot
		var desc := "vazio" if m.is_empty() else "%s — %s, dia %d · Rep. %d · Ouro %d · %s" % [m.act, m.chapter, m.chapter_day, m.reputation, m.gold, m.saved_at]
		var b := _button("%s:  %s" % [name, desc], func():
			if gs.load_game(slot):
				show_hub())
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.disabled = m.is_empty()
		root.add_child(b)
	root.add_child(_spacer_v())
	root.add_child(_button("◀ Voltar", show_title if from_title else show_menu))


## Cartazes de todos os inimigos da missão que têm imagem (chefe primeiro).
func _enemy_textures(m: Dictionary) -> Array:
	var out := []
	for eid in m.get("enemies", []):
		var path := "res://art/enemies/%s.png" % eid
		if ResourceLoader.exists(path):
			out.append(load(path))
	return out


## Primeiro inimigo da missão que tem imagem (res://art/enemies/<id>.png), ou null.
func _enemy_texture(m: Dictionary) -> Texture2D:
	for eid in m.get("enemies", []):
		var path := "res://art/enemies/%s.png" % eid
		if ResourceLoader.exists(path):
			return load(path)
	return null


## Cartaz do inimigo; "defeated" risca com um X de tinta vermelha.
func _enemy_poster(m: Dictionary, px: int, defeated: bool = false, paint_delay: float = 0.0) -> Control:
	var tex := _enemy_texture(m)
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
func _stress_chip(h: Dictionary) -> Control:
	var st := int(h.get("stress", 0))
	var mx := int(gs.traits_data.stress_max)
	var cond: Dictionary = Mind.condition_info(gs, h)
	var txt := "Estr %d/%d" % [st, mx]
	var col := C_MUTED if st < mx / 2 else (C_GOLD if st < mx else C_BAD)
	if not cond.is_empty():
		var virtue: bool = h.condition_kind == "virtude"
		txt += ("  ✦ " if virtue else "  ✖ ") + cond.name
		col = C_GOOD if virtue else C_BAD
	var l := _label(txt, 13, col)
	var tip := "Estresse %d/%d: no máximo, o herói testa a vontade (virtude ou aflição)." % [st, mx]
	if not cond.is_empty():
		tip += "
%s — %s" % [cond.name, cond.desc]
	for tid in h.get("traits", []):
		var ti: Dictionary = Mind.trait_info(gs, tid)
		tip += "
%s %s — %s" % ["+" if ti.positive else "−", ti.name, ti.desc]
	l.tooltip_text = tip
	l.mouse_filter = Control.MOUSE_FILTER_STOP
	return l


## Textura se existir (arte entregue), senão null.
func _tex(path: String) -> Texture2D:
	return load(path) if ResourceLoader.exists(path) else null


## Ícone do item (res://art/items/<id>.png).
func _item_tex(iid: String) -> Texture2D:
	return _tex("res://art/items/%s.png" % iid) if iid != "" else null


func _icon(tex: Texture2D, px: int) -> TextureRect:
	var tr := TextureRect.new()
	tr.texture = tex
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	tr.custom_minimum_size = Vector2(px, px)
	tr.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return tr


## Põe um ícone de textura num botão (tamanho máximo em px).
func _button_icon(b: Button, tex: Texture2D, px: int) -> void:
	if tex == null:
		return
	b.icon = tex
	b.add_theme_constant_override("icon_max_width", px)


func _hero_header(id: String, column: bool) -> Control:
	var h: Dictionary = gs.heroes[id]
	var p := _panel(C_PANEL)
	p.tooltip_text = "%s — %s" % [h.name, h.archetype]
	var box: BoxContainer = VBoxContainer.new() if column else HBoxContainer.new()
	box.add_theme_constant_override("separation", 2 if column else 8)
	if column:
		box.alignment = BoxContainer.ALIGNMENT_CENTER
	p.add_child(box)
	var por := _portrait(h, 44)
	por.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if column:
		por.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(por)
	var l := _label(h.name, 13, h.color.lightened(0.25))
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if column:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(l)
	p.custom_minimum_size = Vector2(96, 0) if column else Vector2(120, 52)
	return p


func _portrait(h: Dictionary, px: int) -> Control:
	if h.get("portrait", "") != "" and ResourceLoader.exists(h.portrait):
		var tr := TextureRect.new()
		tr.texture = load(h.portrait)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		tr.custom_minimum_size = Vector2(px, px)
		tr.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		return tr
	var p = Portrait.new()
	p.custom_minimum_size = Vector2(px, px)
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	p.setup(h)
	return p


func _on_new_game() -> void:
	gs.new_game()
	show_hub()


# ================= Helpers =================

func _clear() -> void:
	title_bg.visible = false
	title_bg.modulate = Color.WHITE
	if is_instance_valid(_dice_box):
		_dice_box.queue_free()   # a rolagem é só da tela do mapa
	if ResourceLoader.exists(TITLE_ART):
		title_bg.texture = load(TITLE_ART)
	root.modulate = Color.WHITE
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
