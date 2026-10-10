class_name TitleScreen
## Título, menu, salvar e carregar, novo jogo.
## Funções estáticas sobre a tela principal (ui: GuildUI, a cena main).


static func show_title(ui: GuildUI) -> void:
	ui._clear()
	var has_art := ui.title_bg.texture != null
	ui.title_bg.visible = has_art
	var t := UIKit.label("A Guilda", 64, GuildUI.C_GOLD)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_constant_override("outline_size", 12)
	t.add_theme_color_override("font_outline_color", Color("#1a120c"))
	ui.root.add_child(t)
	var st := UIKit.label("Quem você envia define quem eles se tornam", 18, GuildUI.C_TEXT if has_art else GuildUI.C_MUTED)
	st.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	st.add_theme_constant_override("outline_size", 6)
	st.add_theme_color_override("font_outline_color", Color("#1a120c"))
	ui.root.add_child(st)
	if not has_art:
		var faces := HBoxContainer.new()
		faces.alignment = BoxContainer.ALIGNMENT_CENTER
		faces.add_theme_constant_override("separation", 10)
		ui.root.add_child(faces)
		for id in ui.gs.hero_order:
			faces.add_child(Widgets.portrait(ui, ui.gs.heroes[id], 64))
	ui.root.add_child(UIKit.spacer_v())
	# Botões numa faixa no rodapé, para não cobrir a arte do grupo
	var bar := PanelContainer.new()
	bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.1, 0.07, 0.05, 0.78)
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(8)
	bar.add_theme_stylebox_override("panel", sb)
	ui.root.add_child(bar)
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	bar.add_child(box)
	var latest: String = ui.gs.latest_save()
	var cont := UIKit.button("Continuar", func():
		if ui.gs.load_game(latest):
			HubScreen.show_hub(ui))
	cont.disabled = latest == ""
	if latest != "":
		var m: Dictionary = ui.gs.save_meta(latest)
		cont.tooltip_text = "%s — %s, dia %d" % [m.act, m.chapter, m.chapter_day]
	box.add_child(cont)
	box.add_child(UIKit.button("Novo jogo", ui._on_new_game))
	var ld := UIKit.button("Carregar", ui.show_load.bind(true))
	ld.disabled = not ui.gs.has_any_save()
	box.add_child(ld)
	box.add_child(UIKit.button("Sair", func(): ui.get_tree().quit()))
	for b in box.get_children():
		b.custom_minimum_size.x = 150


static func show_menu(ui: GuildUI) -> void:
	ui._clear()
	ui.root.add_child(UIKit.label("Menu", 28, GuildUI.C_GOLD))
	ui.root.add_child(UIKit.label("Salvar o jogo", 18, GuildUI.C_TEXT))
	for slot in ["1", "2", "3"]:
		var m: Dictionary = ui.gs.save_meta(slot)
		var desc := "vazio" if m.is_empty() else "%s — %s, dia %d · %s" % [m.act, m.chapter, m.chapter_day, m.saved_at]
		var b := UIKit.button("Espaço %s:  %s" % [slot, desc], func():
			var ok: bool = ui.gs.save_game(slot)
			GuildScreens.toast(ui, "Jogo salvo no espaço %s." % slot if ok else "Não foi possível salvar.", ui.show_menu))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		ui.root.add_child(b)
	ui.root.add_child(UIKit.label("O jogo também salva sozinho ao fim de cada dia (espaço automático).", 13, GuildUI.C_MUTED))
	ui.root.add_child(UIKit.button("Carregar um jogo", ui.show_load.bind(false)))
	ui.root.add_child(UIKit.label("Opções", 18, GuildUI.C_TEXT))
	ui.root.add_child(UIKit.button("Reduzir movimento (sem tremor, sem zoom, animações curtas): %s" % ("Sim" if Juice.reduce_motion else "Não"), func():
		Juice.set_reduce_motion(not Juice.reduce_motion)
		TitleScreen.show_menu(ui)))
	ui.root.add_child(UIKit.button("Voltar ao título", ui.show_title))
	ui.root.add_child(UIKit.spacer_v())
	ui.root.add_child(UIKit.button("◀ Voltar ao jogo", ui.show_hub))


static func show_load(ui: GuildUI, from_title: bool) -> void:
	ui._clear()
	ui.root.add_child(UIKit.label("Carregar", 28, GuildUI.C_GOLD))
	for slot in ui.gs.SAVE_SLOTS:
		var m: Dictionary = ui.gs.save_meta(slot)
		var name: String = "Automático" if slot == "auto" else "Espaço " + slot
		var desc := "vazio" if m.is_empty() else "%s — %s, dia %d · Rep. %d · Ouro %d · %s" % [m.act, m.chapter, m.chapter_day, m.reputation, m.gold, m.saved_at]
		var b := UIKit.button("%s:  %s" % [name, desc], func():
			if ui.gs.load_game(slot):
				HubScreen.show_hub(ui))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.disabled = m.is_empty()
		ui.root.add_child(b)
	ui.root.add_child(UIKit.spacer_v())
	ui.root.add_child(UIKit.button("◀ Voltar", ui.show_title if from_title else ui.show_menu))


static func on_new_game(ui: GuildUI) -> void:
	ui.gs.new_game()
	HubScreen.show_hub(ui)
