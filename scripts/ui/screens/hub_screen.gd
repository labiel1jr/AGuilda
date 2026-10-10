class_name HubScreen
## Hub da guilda: mural de quests, elenco, bastidores; fim do dia e transição.
## Funções estáticas sobre a tela principal (ui: GuildUI, a cena main).


static func show_hub(ui: GuildUI) -> void:
	ui._clear()
	match ui.gs.chapter_state:
		"intro":
			StoryScreens.show_chapter_intro(ui)
			return
		"encerrado":
			StoryScreens.show_chapter_end(ui)
			return
		"fim_do_ato", "fim_de_jogo":
			StoryScreens.show_ending(ui)
			return
	var ch: Dictionary = ui.gs.current_chapter()
	var top := HBoxContainer.new()
	ui.root.add_child(top)
	var titles := VBoxContainer.new()
	titles.add_theme_constant_override("separation", 0)
	top.add_child(titles)
	titles.add_child(UIKit.label("A Guilda do Corvo Cinzento", 24, GuildUI.C_GOLD))
	titles.add_child(UIKit.label("Capítulo %d — %s   ·   Dia %d/%d   ·   Reputação %d   ·   Ouro %d   ·   Despachos %d/%d" % [ch.number, ch.title, ui.gs.chapter_day(), int(ch.days), ui.gs.reputation, ui.gs.gold, ui.gs.dispatched_today, ui.gs.slots()], 14, GuildUI.C_TEXT))
	top.add_child(UIKit.spacer())
	top.add_child(UIKit.button("Guilda", ui.show_upgrades))
	top.add_child(UIKit.button("Mercado", ui.show_market))
	var rel := UIKit.button("Quadro" if ui.gs.affinity_visible() else "🔒 Quadro", ui.show_relations)
	rel.disabled = not ui.gs.affinity_visible()
	rel.tooltip_text = "Construa o Quadro de Relações na tela Guilda." if rel.disabled else "Quadro de Relações"
	top.add_child(rel)
	var book_btn := UIKit.button("Livro", ui.show_book.bind(0))
	UIKit.button_icon(book_btn, UIKit.tex("res://art/book/capa_fechada.png"), 22)
	top.add_child(book_btn)
	top.add_child(UIKit.button("Encerrar dia ▶", ui._on_end_day))
	top.add_child(UIKit.button("☰", ui.show_menu))

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 16)
	ui.root.add_child(body)

	# Mural
	var board_panel := UIKit.panel(GuildUI.C_PANEL)
	board_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	board_panel.size_flags_stretch_ratio = 2.0
	body.add_child(board_panel)
	var bcol := VBoxContainer.new()
	board_panel.add_child(bcol)
	var bhead := HBoxContainer.new()
	bcol.add_child(bhead)
	bhead.add_child(UIKit.label("Mural de Quests", 20, GuildUI.C_GOLD))
	bhead.add_child(UIKit.spacer())
	bhead.add_child(UIKit.label("Objetivo: " + ch.goal.text, 13, GuildUI.C_MUTED))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	bcol.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 8)
	scroll.add_child(list)
	var board: Array = ui.gs.board()
	if board.is_empty():
		list.add_child(UIKit.label("Nenhum pedido no mural hoje.", 15, GuildUI.C_MUTED))
	for i in board.size():
		var card := HubScreen.mission_card(ui, board[i])
		list.add_child(card)
		if ui._fresh_day:
			Juice.fade_in(card, 0.15 + i * 0.09, 0.4)
	ui._fresh_day = false

	# Elenco
	var cast_panel := UIKit.panel(GuildUI.C_PANEL)
	cast_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(cast_panel)
	var ccol := VBoxContainer.new()
	ccol.add_theme_constant_override("separation", 6)
	cast_panel.add_child(ccol)
	ccol.add_child(UIKit.label("Elenco", 20, GuildUI.C_GOLD))
	for id in ui.gs.hero_order:
		var h: Dictionary = ui.gs.heroes[id]
		var row := HBoxContainer.new()
		ccol.add_child(row)
		row.add_child(UIKit.swatch(h.color))
		row.add_child(UIKit.label("%s  Nv %d" % [h.name, h.level], 14, GuildUI.C_TEXT))
		if h.rest_request and not h.resting:
			row.add_child(UIKit.label(" ⚠ pede descanso", 12, GuildUI.C_BAD))
		row.add_child(UIKit.spacer())
		var state: String = "Descansando" if h.resting else ui.gs.hero_status(id)
		row.add_child(UIKit.label(state, 13, GuildUI.C_MUTED if h.resting else UIKit.fatigue_color(h)))
		row.add_child(UIKit.label("  PV %d/%d  Moral %d " % [h.hp, h.hp_max, h.morale], 13, GuildUI.C_MUTED))
		var rest := UIKit.button("Acordar" if h.resting else "Descansar", func():
			ui.gs.set_resting(id, not h.resting)
			HubScreen.show_hub(ui))
		rest.disabled = h.busy
		rest.tooltip_text = "Passa o dia descansando: no fim do dia recupera toda a fadiga, metade do PV, as magias e +1 de moral. Não pode ir em missão hoje."
		row.add_child(rest)

	if ui.gs.has_upgrade("salao"):
		var tb := UIKit.button("Salão de Treinamento: treinar uma dupla" if ui.gs.can_train() else "Salão de Treinamento: já usado hoje", ui.show_training)
		tb.disabled = not ui.gs.can_train()
		ccol.add_child(tb)

	# Bastidores
	# Ultimatos (moral baixa) vêm antes de tudo
	for u in ui.gs.open_ultimatums():
		var uc := UIKit.panel(Color("#5a2a22"))
		ccol.add_child(uc)
		var ur := HBoxContainer.new()
		uc.add_child(ur)
		ur.add_child(UIKit.swatch(ui.gs.heroes[u.id].color))
		ur.add_child(UIKit.label(" ⚠ Ultimato: %s quer ir embora" % ui.gs.heroes[u.id].name, 15, GuildUI.C_TEXT))
		ur.add_child(UIKit.spacer())
		ur.add_child(UIKit.button("Conversar", ui.show_ultimatum.bind(u)))
	for pid in ui.gs.promises:
		ccol.add_child(UIKit.label("⏳ Prometido: %s precisa ir em missão até o dia %d do capítulo" % [ui.gs.heroes[pid].name, int(ui.gs.promises[pid]) - ui.gs.chapter_start + 1], 12, GuildUI.C_GOLD))

	ccol.add_child(UIKit.label("Bastidores", 20, GuildUI.C_GOLD))
	var pending: Array = ui.gs.backstage_today.filter(func(bs): return not bs.done)
	if pending.is_empty():
		ccol.add_child(UIKit.para("A guilda está quieta hoje.", 13, GuildUI.C_MUTED))
	for bs in pending:
		var card := UIKit.panel(Color("#4a3a2a"))
		ccol.add_child(card)
		var bc := VBoxContainer.new()
		card.add_child(bc)
		var brow := HBoxContainer.new()
		bc.add_child(brow)
		brow.add_child(UIKit.swatch(ui.gs.heroes[bs.a].color))
		brow.add_child(UIKit.swatch(ui.gs.heroes[bs.b].color))
		brow.add_child(UIKit.label(" " + bs.event.title, 15, GuildUI.C_TEXT))
		brow.add_child(UIKit.spacer())
		brow.add_child(UIKit.button("Assistir cena", ui.show_backstage.bind(bs)))
		bc.add_child(UIKit.label("%s e %s" % [ui.gs.heroes[bs.a].name, ui.gs.heroes[bs.b].name], 12, GuildUI.C_MUTED))
	Moments.play_moments(ui)


static func mission_card(ui: GuildUI, m: Dictionary) -> Control:
	var card := UIKit.panel(GuildUI.C_PARCHMENT)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	card.add_child(row)
	var poster := Widgets.enemy_poster(ui, m, 84)
	if poster != null:
		row.add_child(poster)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(col)
	var head := HBoxContainer.new()
	col.add_child(head)
	head.add_child(UIKit.label(m.name, 17, GuildUI.C_INK))
	head.add_child(UIKit.spacer())
	head.add_child(UIKit.label("[%s]" % ui.gs.RISK_NAMES[m.risk], 14, GuildUI.RISK_COLORS[m.risk].darkened(0.25)))
	col.add_child(UIKit.para(m.desc, 13, GuildUI.C_INK))
	var left: int = ui.gs.expires_on(m) - ui.gs.day
	var prazo := "último dia!" if left <= 0 else "%d dia(s)" % (left + 1)
	col.add_child(UIKit.para("Tipo: %s   ·   %s + %s   ·   Prazo: %s   ·   Recompensa: %d ouro" % [m.type.capitalize(), ui.gs.ATTR_NAMES[m.primary], ui.gs.ATTR_NAMES[m.secondary], prazo, ui.gs.mission_reward(m)], 13, GuildUI.C_INK.lightened(0.25)))
	for tag in m.get("tags", []):
		col.add_child(UIKit.para("⚑ " + tag.text, 13, Color("#8a3b1f")))
	var btn := UIKit.button("Montar party", ui.show_party.bind(m))
	btn.disabled = ui.gs.free_slots() <= 0
	if btn.disabled:
		btn.tooltip_text = "Sem slots de despacho hoje."
	btn.size_flags_horizontal = Control.SIZE_SHRINK_END
	col.add_child(btn)
	return card


static func on_end_day(ui: GuildUI) -> void:
	var lines: Array = ui.gs.end_day()
	ui.gs.save_game("auto")
	ui._clear()
	var title := "Fim do dia" if ui.gs.chapter_state == "encerrado" else "Dia %d do capítulo" % ui.gs.chapter_day()
	ui.root.add_child(UIKit.label(title, 28, GuildUI.C_GOLD))
	ui.root.add_child(UIKit.para("Os aventureiros descansam. A taverna esvazia. O mural range com pergaminhos novos.", 15, GuildUI.C_TEXT))
	var items := []
	for l in lines:
		var p := UIKit.para("• " + l, 15, GuildUI.C_TEXT)
		ui.root.add_child(p)
		items.append(p)
	ui.root.add_child(UIKit.button("Abrir a guilda", ui.show_hub))
	ui._fresh_day = true
	HubScreen.day_transition(ui, title, items)


## Transição de dia: a tela escurece como uma vela apagando e volta com o novo dia.
static func day_transition(ui: GuildUI, title: String, items: Array) -> void:
	var veil := ColorRect.new()
	veil.color = Color("#120c08")
	veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(veil)
	var l := UIKit.label(title, 34, GuildUI.C_GOLD)
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
