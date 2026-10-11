class_name DecisionScreen
## Decisão de arco: a cena, a opinião de cada herói que estava na missão e as escolhas.
## Funções estáticas sobre a tela principal (ui: GuildUI, a cena main).


static func show_decision(ui: GuildUI, pending: Dictionary) -> void:
	var d := Arcs.decision(ui.gs, pending.id)
	if d.is_empty():
		ui._after_result()
		return
	ui._clear()
	ui.root.add_child(UIKit.label("Decisão da guilda", 16, GuildUI.C_MUTED))
	var title := UIKit.label(d.title, 28, GuildUI.C_GOLD)
	ui.root.add_child(title)
	Juice.pop(title, 0.1, 0.3, 0.05)
	var img := UIKit.tex(String(d.get("image", "")))
	if img != null:
		var tr := UIKit.icon(img, 0)
		tr.custom_minimum_size = Vector2(0, 160)
		tr.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ui.root.add_child(tr)
	var p := UIKit.panel(GuildUI.C_PARCHMENT)
	ui.root.add_child(p)
	p.add_child(UIKit.para(String(d.text), 17, GuildUI.C_INK))

	# o que cada um que esteve lá acha
	var vs := Arcs.voices(ui.gs, d, pending.party)
	for i in vs.size():
		var v: Dictionary = vs[i]
		var h: Dictionary = ui.gs.heroes[v.id]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		ui.root.add_child(row)
		row.add_child(Widgets.portrait(ui, h, 44))
		var t := UIKit.para("%s: \"%s\"" % [h.name, v.text], 15, h.color.lightened(0.35))
		row.add_child(t)
		Juice.fade_in(row, 0.2 + i * 0.25, 0.4)

	ui.root.add_child(UIKit.label("O que a guilda decide?", 15, GuildUI.C_TEXT))
	for c in Arcs.choices(ui.gs, d):
		var who: Array = vs.filter(func(v): return v.leans == c.id).map(func(v): return ui.gs.heroes[v.id].name)
		var label: String = c.label + ("   — %s apoia" % ", ".join(who) if not who.is_empty() else "")
		var b := UIKit.button(label, func(): DecisionScreen.choose(ui, pending, c), "escolha")
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		ui.root.add_child(b)


static func choose(ui: GuildUI, pending: Dictionary, choice: Dictionary) -> void:
	var lines := Arcs.resolve(ui.gs, pending, choice)
	Juice.flash(ui, GuildUI.C_GOLD, 0.15, 0.4)
	ui._clear()
	var p := UIKit.panel(GuildUI.C_PARCHMENT)
	ui.root.add_child(p)
	var col := VBoxContainer.new()
	p.add_child(col)
	if not lines.is_empty():
		col.add_child(UIKit.para(lines[0], 17, GuildUI.C_INK))
	for i in range(1, lines.size()):
		ui.root.add_child(UIKit.label(lines[i], 14, GuildUI.C_TEXT))
	ui.root.add_child(UIKit.spacer_v())
	ui.root.add_child(UIKit.button("Continuar", ui._after_result))
