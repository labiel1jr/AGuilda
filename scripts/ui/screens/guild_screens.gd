class_name GuildScreens
## Telas de serviço da guilda: bastidor, Quadro de Relações, Livro, melhorias, treino, ultimato, aviso.
## Funções estáticas sobre a tela principal (ui: GuildUI, a cena main).


static func show_backstage(ui: GuildUI, bs: Dictionary) -> void:
	ui._clear()
	ui.root.add_child(UIKit.label("Bastidores da guilda", 16, GuildUI.C_MUTED))
	ui.root.add_child(UIKit.label(bs.event.title, 28, GuildUI.C_GOLD))
	var who := HBoxContainer.new()
	ui.root.add_child(who)
	for id in [bs.a, bs.b]:
		who.add_child(UIKit.badge(ui.gs.heroes[id].name, ui.gs.heroes[id].color.darkened(0.2)))
	who.add_child(UIKit.label("   " + ui.gs.describe_aff(ui.gs.pair_value(bs.a, bs.b)), 14, UIKit.aff_color(ui.gs.pair_value(bs.a, bs.b))))
	var p := UIKit.panel(GuildUI.C_PARCHMENT)
	ui.root.add_child(p)
	p.add_child(UIKit.para(ui.gs.backstage_text(bs, bs.event.text), 17, GuildUI.C_INK))
	ui.root.add_child(UIKit.label("O que você faz?", 15, GuildUI.C_TEXT))
	for choice in bs.event.choices:
		var block := Backstage.choice_block(ui.gs, choice)
		var b := UIKit.button(ui.gs.backstage_text(bs, choice.label) + ("   (%s)" % block if block != "" else ""), ui._on_backstage_choice.bind(bs, choice), "escolha")
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.disabled = block != ""
		ui.root.add_child(b)
	ui.root.add_child(UIKit.spacer_v())
	ui.root.add_child(UIKit.button("◀ Voltar (decidir depois)", ui.show_hub))


static func on_backstage_choice(ui: GuildUI, bs: Dictionary, choice: Dictionary) -> void:
	var lines: Array = ui.gs.resolve_backstage(bs, choice)
	ui._clear()
	ui.root.add_child(UIKit.label(bs.event.title, 24, GuildUI.C_GOLD))
	var p := UIKit.panel(GuildUI.C_PARCHMENT)
	ui.root.add_child(p)
	var col := VBoxContainer.new()
	p.add_child(col)
	col.add_child(UIKit.para(lines[0], 17, GuildUI.C_INK))
	for i in range(1, lines.size()):
		ui.root.add_child(UIKit.label(lines[i], 14, GuildUI.C_TEXT))
	ui.root.add_child(UIKit.spacer_v())
	ui.root.add_child(UIKit.button("Continuar", ui._after_result))


static func show_relations(ui: GuildUI) -> void:
	ui._clear()
	var top := HBoxContainer.new()
	ui.root.add_child(top)
	top.add_child(UIKit.label("Quadro de Relações", 24, GuildUI.C_GOLD))
	top.add_child(UIKit.spacer())
	top.add_child(UIKit.button("◀ Voltar", ui.show_hub))   # no topo: a grade pode passar da altura da tela
	ui.root.add_child(UIKit.label("Valor do par = o menor dos dois lados. Passe o mouse para ver os dois valores e o vínculo.", 13, GuildUI.C_MUTED))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	ui.root.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = ui.gs.hero_order.size() + 1
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	scroll.add_child(grid)
	grid.add_child(UIKit.label("", 14, GuildUI.C_TEXT))
	for id in ui.gs.hero_order:
		grid.add_child(Widgets.hero_header(ui, id, true))
	for a in ui.gs.hero_order:
		grid.add_child(Widgets.hero_header(ui, a, false))
		for b in ui.gs.hero_order:
			if a == b:
				var self_cell := UIKit.cell("—", GuildUI.C_PANEL, GuildUI.C_MUTED, "")
				self_cell.custom_minimum_size = Vector2(96, 52)
				grid.add_child(self_cell)
				continue
			var v: int = ui.gs.pair_value(a, b)
			var lbl: String = ui.gs.bond_label(a, b)
			var tip := "%s → %s: %+d\n%s → %s: %+d\n%s%s" % [ui.gs.heroes[a].name, ui.gs.heroes[b].name, ui.gs.affinity[a][b], ui.gs.heroes[b].name, ui.gs.heroes[a].name, ui.gs.affinity[b][a], ui.gs.band(v).label, ("\nVínculo: " + lbl) if lbl != "" else ""]
			tip += "\nSem missão juntos há %d dia(s)" % ui.gs.days_apart(a, b)
			if ui.gs.has_upgrade("arquivo"):
				var hist: Array = ui.gs.pair_missions(a, b)
				tip += "\n— Arquivo: %d missão(ões) juntos —" % hist.size()
				for e in hist:
					tip += "\nDia %d · %s · %s" % [e.day, e.mission, ui.gs.OUTCOME_NAMES[e.outcome]]
			var cell := UIKit.cell("%+d%s" % [v, " ✦" if lbl != "" else ""], UIKit.aff_color(v).darkened(0.55), GuildUI.C_TEXT, tip)
			cell.custom_minimum_size = Vector2(96, 52)
			grid.add_child(cell)
	ui.root.add_child(UIKit.button("◀ Voltar", ui.show_hub))


static func show_book(ui: GuildUI, index: int) -> void:
	ui._clear()
	var desk := UIKit.tex("res://art/book/livro_aberto.png")
	if desk != null:
		ui.title_bg.texture = desk
		ui.title_bg.modulate = Color(0.32, 0.27, 0.22)
		ui.title_bg.visible = true
	var book = GuildUI.GuildBook.new()
	ui.root.add_child(book)
	book.setup(ui, ui.gs, index)
	book.closed.connect(ui.show_hub)


static func show_upgrades(ui: GuildUI) -> void:
	ui._clear()
	var top := HBoxContainer.new()
	ui.root.add_child(top)
	top.add_child(UIKit.label("Melhorias da Guilda", 24, GuildUI.C_GOLD))
	top.add_child(UIKit.spacer())
	top.add_child(UIKit.label("Ouro %d   ·   Reputação %d" % [ui.gs.gold, ui.gs.reputation], 16, GuildUI.C_TEXT))
	ui.root.add_child(UIKit.para("A guilda está caindo aos pedaços. Cada reforma muda o que você enxerga — e o que seus aventureiros conseguem fazer.", 14, GuildUI.C_MUTED))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	ui.root.add_child(grid)
	for up in Economy.visible_upgrades(ui.gs):
		var owned: bool = ui.gs.has_upgrade(up.id)
		var card := UIKit.panel(GuildUI.C_PARCHMENT if owned else Color("#4a3a2a"))
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(card)
		var col := VBoxContainer.new()
		card.add_child(col)
		var ink := GuildUI.C_INK if owned else GuildUI.C_TEXT
		col.add_child(UIKit.label(("✓ " if owned else ("✦ " if up.get("hidden", false) else "")) + up.name, 18, ink))
		col.add_child(UIKit.para(up.desc, 13, ink))
		var row := HBoxContainer.new()
		col.add_child(row)
		row.add_child(UIKit.label("%d ouro · Reputação %d+" % [int(up.cost), int(up.rep)], 13, GuildUI.C_MUTED if not owned else GuildUI.C_INK.lightened(0.3)))
		row.add_child(UIKit.spacer())
		var reason: String = ui.gs.upgrade_block_reason(up)
		var b := UIKit.button("Construir" if reason == "" else reason, func():
			ui.gs.buy_upgrade(up.id)
			GuildScreens.show_upgrades(ui))
		b.disabled = reason != ""
		row.add_child(b)
	var hidden_left: int = ui.gs.upgrades_data.upgrades.size() - Economy.visible_upgrades(ui.gs).size()
	if hidden_left > 0:
		ui.root.add_child(UIKit.para("✦ Há %d melhoria(s) ainda por descobrir. Preste atenção aos bastidores: às vezes um aventureiro traz uma ideia — ou alguém — para a guilda." % hidden_left, 14, GuildUI.C_GOLD))
	var slots_info := "Slots de missão por dia: %d (Reputação 5 → 2 slots · Reputação 12 → 3 slots)" % ui.gs.slots()
	ui.root.add_child(UIKit.label(slots_info, 14, GuildUI.C_TEXT))
	ui.root.add_child(UIKit.spacer_v())
	ui.root.add_child(UIKit.button("◀ Voltar", ui.show_hub))


static func show_training(ui: GuildUI) -> void:
	ui._clear()
	ui.root.add_child(UIKit.label("Salão de Treinamento", 24, GuildUI.C_GOLD))
	ui.root.add_child(UIKit.para("Escolha dois aventureiros prontos. A dupla ganha afinidade, mas os dois ficam Cansados para o resto do dia.", 14, GuildUI.C_MUTED))
	for id in ui.gs.hero_order:
		var h: Dictionary = ui.gs.heroes[id]
		var reason: String = ui.gs.train_reason(id)
		var row := HBoxContainer.new()
		ui.root.add_child(row)
		row.add_child(UIKit.swatch(h.color))
		var sel := ui._train_pick.has(id)
		var b := UIKit.button(("✓ " if sel else "") + h.name, func():
			if ui._train_pick.has(id):
				ui._train_pick.erase(id)
			elif ui._train_pick.size() < 2:
				ui._train_pick.append(id)
			GuildScreens.show_training(ui))
		b.custom_minimum_size.x = 120
		b.disabled = reason != "" or (not sel and ui._train_pick.size() >= 2)
		row.add_child(b)
		row.add_child(UIKit.label("  " + (reason if reason != "" else ui.gs.hero_status(id)), 13, GuildUI.C_BAD if reason != "" else GuildUI.C_GOOD))
	if ui._train_pick.size() == 2:
		ui.root.add_child(UIKit.label("%s ↔ %s: %s" % [ui.gs.heroes[ui._train_pick[0]].name, ui.gs.heroes[ui._train_pick[1]].name, ui.gs.describe_aff(ui.gs.pair_value(ui._train_pick[0], ui._train_pick[1]))], 15, GuildUI.C_TEXT))
	ui.root.add_child(UIKit.spacer_v())
	var foot := HBoxContainer.new()
	ui.root.add_child(foot)
	foot.add_child(UIKit.button("◀ Voltar", func():
		ui._train_pick = []
		HubScreen.show_hub(ui)))
	foot.add_child(UIKit.spacer())
	var go := UIKit.button("Treinar", func():
		var lines: Array = ui.gs.train_pair(ui._train_pick[0], ui._train_pick[1])
		ui._train_pick = []
		ui._clear()
		ui.root.add_child(UIKit.label("Salão de Treinamento", 24, GuildUI.C_GOLD))
		var p := UIKit.panel(GuildUI.C_PARCHMENT)
		ui.root.add_child(p)
		p.add_child(UIKit.para(lines[0], 17, GuildUI.C_INK))
		ui.root.add_child(UIKit.spacer_v())
		ui.root.add_child(UIKit.button("Continuar", ui._after_result)))
	go.disabled = ui._train_pick.size() != 2
	foot.add_child(go)


static func toast(ui: GuildUI, msg: String, next: Callable) -> void:
	ui._clear()
	var p := UIKit.panel(GuildUI.C_PARCHMENT)
	ui.root.add_child(p)
	p.add_child(UIKit.para(msg, 17, GuildUI.C_INK))
	ui.root.add_child(UIKit.spacer_v())
	ui.root.add_child(UIKit.button("Continuar", next))


static func show_ultimatum(ui: GuildUI, u: Dictionary) -> void:
	ui._clear()
	var h: Dictionary = ui.gs.heroes[u.id]
	ui.root.add_child(UIKit.label("Ultimato", 16, GuildUI.C_BAD))
	var head := HBoxContainer.new()
	ui.root.add_child(head)
	var up := Widgets.portrait(ui, h, 72)
	head.add_child(up)
	Juice.desaturate(ui.root, Color(0.86, 0.8, 0.74), 1.2)
	Juice.blink(up, Color(1.6, 0.7, 0.6), 0.9)
	head.add_child(UIKit.label("  %s está no limite" % h.name, 28, GuildUI.C_GOLD))
	ui.root.add_child(UIKit.label("Moral %d/10   ·   %s   ·   Nível %d" % [h.morale, ui.gs.hero_status(u.id), h.level], 15, GuildUI.C_TEXT))
	var p := UIKit.panel(GuildUI.C_PARCHMENT)
	ui.root.add_child(p)
	p.add_child(UIKit.para(ui.gs.ultimatum_text(u.id, ui.gs.ultimatum_data.text), 17, GuildUI.C_INK))
	ui.root.add_child(UIKit.para("Se você não responder hoje, %s parte amanhã — e o equipamento fica no Baú." % h.name, 13, GuildUI.C_MUTED))
	for choice in ui.gs.ultimatum_data.choices:
		var reason: String = ui.gs.ultimatum_block_reason(choice)
		var b := UIKit.button(ui.gs.ultimatum_text(u.id, choice.label) + ("" if reason == "" else "  (%s)" % reason), func():
			GuildScreens.toast(ui, "\n".join(ui.gs.resolve_ultimatum(u, choice)), ui.show_hub), "escolha")
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.disabled = reason != ""
		ui.root.add_child(b)
	ui.root.add_child(UIKit.spacer_v())
	ui.root.add_child(UIKit.button("◀ Voltar (decidir depois)", ui.show_hub))
