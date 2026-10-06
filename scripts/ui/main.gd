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
var prepared: Dictionary = {}   # magia preparada por conjurador na montagem de party
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
	top.add_child(_button("Livro", show_book.bind(0)))
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
	_clear()
	root.add_child(_label("Fim do dia" if gs.chapter_state == "encerrado" else "Dia %d do capítulo" % gs.chapter_day(), 28, C_GOLD))
	root.add_child(_para("Os aventureiros descansam. A taverna esvazia. O mural range com pergaminhos novos.", 15, C_TEXT))
	for l in lines:
		root.add_child(_para("• " + l, 15, C_TEXT))
	root.add_child(_button("Abrir a guilda", show_hub))


# ================= Montagem de Party =================

func show_party(m: Dictionary) -> void:
	selected = []
	prepared = {}
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
		var ea: Dictionary = HeroRPG.effective_attrs(gs, id)
		row.add_child(_label("Nv %d · %s %d / %s %d" % [h.level, gs.ATTR_NAMES[m.primary].left(3), ea[m.primary], gs.ATTR_NAMES[m.secondary].left(3), ea[m.secondary]], 13, C_TEXT))
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
		var prow := HBoxContainer.new()
		rcol.add_child(prow)
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
			rcol.add_child(_label("%s ↔ %s  %s%s" % [gs.heroes[pr[0]].name, gs.heroes[pr[1]].name, gs.describe_aff(v), extra], 14, _aff_color(v)))
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
	_render_party(m)


func _on_dispatch(m: Dictionary) -> void:
	var res: Dictionary = gs.dispatch(m, selected.duplicate(), prepared.duplicate())
	selected = []
	prepared = {}
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
	root.add_child(_para("Score %.1f  =  Base %.1f  + Cobertura %d  + Afinidade %+.1f  + Vínculo %d  + Poderes %d  + Oculto %d  + Sorte %+d      (custo ≥ %d · limpo ≥ %d)" % [sc.total, sc.base, sc.coverage, sc.affinity, sc.bond, sc.powers, sc.hidden, sc.luck, t[0], t[1]], 13, C_MUTED))

	if not res.affinity.is_empty():
		root.add_child(_label("Vínculos", 16, C_GOLD))
		for ch in res.affinity:
			var arrow := "▲" if ch.after > ch.before else ("▼" if ch.after < ch.before else "=")
			root.add_child(_label("%s ↔ %s   %s  %s" % [gs.heroes[ch.a].name, gs.heroes[ch.b].name, gs.describe_change(ch.before, ch.after), arrow], 14, _aff_color(ch.after)))
	root.add_child(_spacer_v())
	root.add_child(_button("Continuar", _after_result))


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
	root.add_child(_label("\"%s\"" % info.title, 28, C_GOLD))
	root.add_child(_label("%s e %s  ·  %s" % [a.name, b.name, gs.describe_aff(gs.pair_value(ev.a, ev.b))], 18, C_TEXT))
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
			if gs.has_upgrade("arquivo"):
				var hist: Array = gs.pair_missions(a, b)
				tip += "\n— Arquivo: %d missão(ões) juntos —" % hist.size()
				for e in hist:
					tip += "\nDia %d · %s · %s" % [e.day, e.mission, gs.OUTCOME_NAMES[e.outcome]]
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
	head.add_child(_swatch(h.color, 28))
	head.add_child(_label("  %s chegou ao nível %d!" % [h.name, entry.level], 28, C_GOLD))
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


func _item_row(it: Dictionary, action: String, disabled: bool, cb: Callable) -> Control:
	var row := HBoxContainer.new()
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
	head.add_child(_swatch(h.color, 28))
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
		root.add_child(_label("Fim do jogo — por enquanto. Obrigado por comandar o Corvo Cinzento.", 16, C_GOLD))
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
