class_name StoryScreens
## Abertura e fim de capítulo, fim do ato e epílogo.
## Funções estáticas sobre a tela principal (ui: GuildUI, a cena main).


static func show_chapter_intro(ui: GuildUI) -> void:
	ui._clear()
	var ch: Dictionary = ui.gs.current_chapter()
	ui.root.add_child(UIKit.label(ui.gs.act.title, 16, GuildUI.C_MUTED))
	ui.root.add_child(UIKit.label("Capítulo %d" % ch.number, 20, GuildUI.C_GOLD))
	ui.root.add_child(UIKit.label(ch.title, 36, GuildUI.C_GOLD))
	var p := UIKit.panel(GuildUI.C_PARCHMENT)
	ui.root.add_child(p)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	p.add_child(col)
	for l in ui.gs.chapter_intro():
		col.add_child(UIKit.para(l, 17, GuildUI.C_INK))
	for rid in ui.gs.chapter_recruits():
		col.add_child(UIKit.para("✦ " + ui.gs.heroes[rid].joins_text, 17, Color("#3f6b2f")))
	ui.root.add_child(UIKit.label("Objetivo: %s   ·   Duração: %d dias" % [ch.goal.text, int(ch.days)], 15, GuildUI.C_TEXT))
	ui.root.add_child(UIKit.spacer_v())
	ui.root.add_child(UIKit.button("Começar o capítulo", func():
		ui.gs.begin_chapter()
		HubScreen.show_hub(ui)))


static func show_chapter_end(ui: GuildUI) -> void:
	ui._clear()
	var r: Dictionary = ui.gs.chapter_result
	var ch: Dictionary = r.chapter
	ui.root.add_child(UIKit.label("Fim do Capítulo %d — %s" % [ch.number, ch.title], 28, GuildUI.C_GOLD))
	ui.root.add_child(UIKit.label(("✓ Objetivo cumprido: " if r.success else "✗ Objetivo não cumprido: ") + ch.goal.text, 17, GuildUI.C_GOOD if r.success else GuildUI.C_BAD))
	var p := UIKit.panel(GuildUI.C_PARCHMENT)
	ui.root.add_child(p)
	p.add_child(UIKit.para(r.text, 17, GuildUI.C_INK))
	var done := 0
	var total := 0
	for m in ui.gs.missions:
		if ch.missions.has(m.id):
			total += 1
			if m.status == "concluida":
				done += 1
	ui.root.add_child(UIKit.label("Missões concluídas: %d/%d   ·   Reputação: %d   ·   Ouro: %d" % [done, total, ui.gs.reputation, ui.gs.gold], 15, GuildUI.C_TEXT))
	ui.root.add_child(UIKit.spacer_v())
	ui.root.add_child(UIKit.button("Continuar", func():
		ui.gs.next_chapter()
		HubScreen.show_hub(ui)))


static func show_ending(ui: GuildUI) -> void:
	ui._clear()
	ui.root.add_child(UIKit.label(ui.gs.act.title, 30, GuildUI.C_GOLD))
	var p := UIKit.panel(GuildUI.C_PARCHMENT)
	ui.root.add_child(p)
	p.add_child(UIKit.para(ui.gs.act.ending, 18, GuildUI.C_INK))
	for cid in ui.gs.act.chapters:
		for ch in ui.gs.chapters_data.chapters:
			if ch.id == cid:
				var ok: bool = ui.gs.flags.has(ch.get("flag_success", ""))
				ui.root.add_child(UIKit.label("%s Capítulo %d — %s" % ["✓" if ok else "✗", ch.number, ch.title], 15, GuildUI.C_GOOD if ok else GuildUI.C_BAD))
	ui.root.add_child(UIKit.label("Reputação final: %d   ·   Ouro: %d   ·   Melhorias: %d/%d" % [ui.gs.reputation, ui.gs.gold, ui.gs.upgrades_owned.size(), ui.gs.upgrades_data.upgrades.size()], 16, GuildUI.C_TEXT))
	for key in ui.gs.bond_labels:
		var ids: PackedStringArray = key.split("|")
		ui.root.add_child(UIKit.label("✦ %s & %s — %s" % [ui.gs.heroes[ids[0]].name, ui.gs.heroes[ids[1]].name, ui.gs.bond_labels[key]], 15, GuildUI.C_TEXT))
	for did in ui.gs.departed:
		ui.root.add_child(UIKit.label("✗ %s deixou a guilda" % ui.gs.heroes[did].name, 15, GuildUI.C_BAD))
	ui.root.add_child(UIKit.spacer_v())
	if ui.gs.chapter_state == "fim_do_ato" and ui.gs.has_next_act():
		var nxt: Dictionary = ui.gs.chapters_data.acts[ui.gs.act_index + 1]
		ui.root.add_child(UIKit.button("Continuar: " + nxt.title, func():
			ui.gs.next_act()
			HubScreen.show_hub(ui)))
	else:
		ui.root.add_child(UIKit.button("Ver o epílogo", ui.show_epilogue))


static func show_epilogue(ui: GuildUI) -> void:
	ui._clear()
	if ui.gs.chapter_state != "fim_de_jogo":
		ui.gs.next_act()   # fecha o último ato
	ui.gs.save_game("auto")
	var ep: Dictionary = ui.gs.epilogue()
	ui.root.add_child(UIKit.label("Epílogo", 16, GuildUI.C_MUTED))
	ui.root.add_child(UIKit.label(ep.title, 32, GuildUI.C_GOLD))
	var p := UIKit.panel(GuildUI.C_PARCHMENT)
	ui.root.add_child(p)
	p.add_child(UIKit.para(ep.text, 17, GuildUI.C_INK))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	ui.root.add_child(scroll)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 8)
	scroll.add_child(col)
	for e in ep.heroes:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		col.add_child(row)
		var h: Dictionary = ui.gs.heroes[e.id]
		var por := Widgets.portrait(ui, h, 48)
		if ui.gs.departed.has(e.id):
			por.modulate = Color(1, 1, 1, 0.45)
		row.add_child(por)
		row.add_child(UIKit.para(e.text, 15, GuildUI.C_MUTED if ui.gs.departed.has(e.id) else GuildUI.C_TEXT))
	for b in ep.bonds:
		col.add_child(UIKit.para("✦ " + b, 15, GuildUI.C_GOLD))
	var foot := HBoxContainer.new()
	ui.root.add_child(foot)
	foot.add_child(UIKit.label("Reputação final %d   ·   Ouro %d" % [ui.gs.reputation, ui.gs.gold], 14, GuildUI.C_MUTED))
	foot.add_child(UIKit.spacer())
	foot.add_child(UIKit.button("Voltar ao título", ui.show_title))
