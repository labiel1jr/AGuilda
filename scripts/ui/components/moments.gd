class_name Moments
## Encena momentos de personagem (ruptura, saída) por cima da tela atual.
## Funções estáticas sobre a tela principal (ui: GuildUI, a cena main).


## Encena um momento de personagem por vez (ruptura, saída), por cima da tela atual.
static func play_moments(ui: GuildUI) -> void:
	if not ui.moments_enabled or ui._moment_open or ui.gs.pending_moments.is_empty():
		return
	var mo: Dictionary = ui.gs.pending_moments.pop_front()
	if not ui.gs.heroes.has(mo.id):
		Moments.play_moments(ui)
		return
	ui._moment_open = true
	var h: Dictionary = ui.gs.heroes[mo.id]
	var layer := Control.new()
	layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.mouse_filter = Control.MOUSE_FILTER_STOP
	ui.add_child(layer)
	ui._moment_layer = layer
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
	var por := Widgets.portrait(ui, h, 150)
	por.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(por)
	var title := ""
	var tcol := GuildUI.C_GOLD
	match mo.type:
		"ruptura":
			var virtue: bool = mo.kind == "virtude"
			title = ("✦ %s encontra força: %s" if virtue else "%s quebra: %s") % [h.name, mo.name]
			tcol = Color("#f2d27a") if virtue else GuildUI.C_BAD
			if virtue:
				Juice.flash(ui, Color("#f2d27a"), 0.35, 0.8)
				Juice.pop(por, 0.15, 0.5)
			else:
				Juice.flash(ui, Color("#8a2f1f"), 0.35, 0.8)
				Juice.shake(ui, 7.0, 0.4)
		"saida":
			title = "%s deixou a guilda" % h.name
			tcol = GuildUI.C_MUTED
			Juice.desaturate(por, Color(0.75, 0.66, 0.52, 0.75), 1.4)
	var tl := UIKit.label(title, 26, tcol)
	tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(tl)
	var body := UIKit.para(String(mo.text), 17, GuildUI.C_TEXT)
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(body)
	Juice.typewrite(body)
	var btn := UIKit.button("Continuar", func():
		layer.queue_free()
		ui._moment_open = false
		Moments.play_moments(ui))
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(btn)
	Juice.fade_in(layer, 0.0, 0.3)
