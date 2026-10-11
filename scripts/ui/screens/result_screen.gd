class_name ResultScreen
## Resolução da missão, evento de vínculo e subida de nível.
## Funções estáticas sobre a tela principal (ui: GuildUI, a cena main).


static func show_result(ui: GuildUI, res: Dictionary) -> void:
	ui._clear()
	var m: Dictionary = res.mission
	var rhead := HBoxContainer.new()
	rhead.add_theme_constant_override("separation", 14)
	ui.root.add_child(rhead)
	var reveal := 0.15 if Juice.reduce_motion else 1.0   # tempo até o veredito
	var poster := Widgets.enemy_poster(ui, m, 104, res.outcome != "falha", reveal)
	if poster != null:
		rhead.add_child(poster)
	var rtitles := VBoxContainer.new()
	rtitles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rhead.add_child(rtitles)
	rtitles.add_child(UIKit.label(m.name, 22, GuildUI.C_GOLD))
	var verdict := UIKit.label(ui.gs.OUTCOME_NAMES[res.outcome], 30, GuildUI.OUTCOME_COLORS[res.outcome])
	rtitles.add_child(verdict)
	verdict.modulate.a = 0.0

	# Placar: a barra enche até o resultado, com as linhas de custo e limpo
	var sc: Dictionary = res.score
	var t: Array = ScoreCalc.THRESHOLDS[m.risk]
	var meter := HBoxContainer.new()
	meter.add_theme_constant_override("separation", 10)
	rtitles.add_child(meter)
	var num := UIKit.label("0.0", 20, GuildUI.C_TEXT)
	num.custom_minimum_size.x = 56
	meter.add_child(num)
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.max_value = t[1] + 3
	bar.custom_minimum_size = Vector2(260, 14)
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var fill := StyleBoxFlat.new()
	fill.bg_color = GuildUI.OUTCOME_COLORS[res.outcome]
	bar.add_theme_stylebox_override("fill", fill)
	meter.add_child(bar)
	meter.add_child(UIKit.label("custo ≥ %d · limpo ≥ %d" % [t[0], t[1]], 13, GuildUI.C_MUTED))
	Juice.count(num, 0.0, sc.total, "%.1f", reveal * 0.9)
	var btw := bar.create_tween()
	btw.tween_property(bar, "value", clampf(sc.total, 0.0, bar.max_value), reveal * 0.9).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	btw.tween_callback(func():
		verdict.modulate.a = 1.0
		Juice.pop(verdict, 0.35, 0.35)
		match res.outcome:
			"limpo":
				Juice.flash(ui, Color("#f2d27a"), 0.18, 0.5)
			"falha":
				Juice.shake(ui, 4.0, 0.3)
		Moments.play_moments(ui))

	# O porquê, em frases (os números ficam em "ver detalhes")
	var story: Array = res.get("story", [])
	if not story.is_empty():
		var srow := HBoxContainer.new()
		srow.add_theme_constant_override("separation", 12)
		ui.root.add_child(srow)
		for i in story.size():
			var card := ResultScreen.story_card(ui, story[i])
			srow.add_child(card)
			Juice.fade_in(card, reveal + 0.15 + i * 0.25, 0.45)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	ui.root.add_child(scroll)
	var p := UIKit.panel(GuildUI.C_PARCHMENT)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(p)
	Juice.fade_in(p, reveal + 0.1, 0.4)
	var col := VBoxContainer.new()
	p.add_child(col)
	for l in res.lines:
		col.add_child(UIKit.para(l, 15, GuildUI.C_INK))

	var details := VBoxContainer.new()
	details.visible = false
	var dbtn := UIKit.button("Ver detalhes do score ▸", func(): pass)
	dbtn.flat = true
	dbtn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	dbtn.pressed.connect(func():
		details.visible = not details.visible
		dbtn.text = ("Esconder detalhes ▾" if details.visible else "Ver detalhes do score ▸"))
	ui.root.add_child(dbtn)
	ui.root.add_child(details)
	details.add_child(UIKit.para("Score %.1f  =  Base %.1f  + Cobertura %d  + Afinidade %+.1f  + Vínculo %d  + Poderes %d  + Oculto %d  + Mente %+d  + Rota %+d  + Sorte %+d      (custo ≥ %d · limpo ≥ %d)" % [sc.total, sc.base, sc.coverage, sc.affinity, sc.bond, sc.powers, sc.hidden, int(sc.get("mind", 0)), int(sc.get("route", 0)), sc.luck, t[0], t[1]], 13, GuildUI.C_MUTED))
	if res.has("route"):
		var rt: Dictionary = res.route
		details.add_child(UIKit.para("Rota: preparação %+d · desgaste −%d · fome −%d" % [rt.bonus, rt.wear, mini(rt.hunger, 2)], 13, GuildUI.C_MUTED))

	if not res.affinity.is_empty():
		ui.root.add_child(UIKit.label("Vínculos", 16, GuildUI.C_GOLD))
		for ch in res.affinity:
			var arrow := "▲" if ch.after > ch.before else ("▼" if ch.after < ch.before else "=")
			var al := UIKit.label("%s ↔ %s   %s  %s" % [ui.gs.heroes[ch.a].name, ui.gs.heroes[ch.b].name, ui.gs.describe_change(ch.before, ch.after), arrow], 14, UIKit.aff_color(ch.after))
			ui.root.add_child(al)
			Juice.fade_in(al, reveal + 0.4 + res.affinity.find(ch) * 0.12, 0.3)
	ui.root.add_child(UIKit.button("Continuar", ui._after_result))


## Cartão de um momento do resultado: a cena ilustrada (se existir) ou os retratos, e a frase.
static func story_card(ui: GuildUI, beat: Dictionary) -> Control:
	var card := UIKit.panel(Color("#4a3a2a"))
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	card.add_child(col)
	var img: Texture2D = UIKit.tex(String(beat.get("image", "")))
	if img != null:
		var tr := UIKit.icon(img, 0)
		tr.custom_minimum_size = Vector2(0, 120)
		tr.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.add_child(tr)
	else:
		# sem a ilustração: os retratos de quem protagonizou o momento
		var heroes: Array = beat.get("heroes", [])
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 0)
		row.custom_minimum_size.y = 64
		col.add_child(row)
		var good: bool = beat.type in ["sinergia", "laco_lendario", "acao_vinculo", "virtude", "destaque", "preparacao", "poderes", "sorte"]
		for i in heroes.size():
			if i == 1:
				var thread := ColorRect.new()
				thread.color = GuildUI.C_GOLD if good else GuildUI.C_BAD
				thread.custom_minimum_size = Vector2(36, 3)
				thread.size_flags_vertical = Control.SIZE_SHRINK_CENTER
				row.add_child(thread)
			row.add_child(Widgets.portrait(ui, ui.gs.heroes[heroes[i]], 60))
		if heroes.is_empty():
			var mark := UIKit.label("✦" if good else "✖", 34, GuildUI.C_GOLD if good else GuildUI.C_BAD)
			mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			row.add_child(mark)
	var t := UIKit.para(String(beat.text), 15, GuildUI.C_TEXT)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(t)
	return card


static func after_result(ui: GuildUI) -> void:
	if not ui.gs.pending_decisions.is_empty():
		DecisionScreen.show_decision(ui, ui.gs.pending_decisions.pop_front())
	elif not ui.gs.pending_events.is_empty():
		ResultScreen.show_bond_event(ui, ui.gs.pending_events.pop_front())
	elif not ui.gs.pending_levelups.is_empty():
		ResultScreen.show_levelup(ui, ui.gs.pending_levelups.pop_front())
	else:
		HubScreen.show_hub(ui)


static func show_bond_event(ui: GuildUI, ev: Dictionary) -> void:
	ui._clear()
	var info: Dictionary = ui.gs.THRESHOLD_EVENTS[ev.threshold]
	var a: Dictionary = ui.gs.heroes[ev.a]
	var b: Dictionary = ui.gs.heroes[ev.b]
	ui.root.add_child(UIKit.label("Bastidores da guilda", 16, GuildUI.C_MUTED))
	var bt := UIKit.label("\"%s\"" % info.title, 28, GuildUI.C_GOLD)
	ui.root.add_child(bt)
	var pair := HBoxContainer.new()
	pair.alignment = BoxContainer.ALIGNMENT_CENTER
	pair.add_theme_constant_override("separation", 0)
	ui.root.add_child(pair)
	var pa := Widgets.portrait(ui, a, 84)
	var pb := Widgets.portrait(ui, b, 84)
	var thread := ColorRect.new()
	thread.color = GuildUI.C_GOLD if ev.threshold > 0 else GuildUI.C_BAD
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
	ui.root.add_child(UIKit.label("%s e %s  ·  %s" % [a.name, b.name, ui.gs.describe_aff(ui.gs.pair_value(ev.a, ev.b))], 18, GuildUI.C_TEXT))
	ui.root.add_child(UIKit.label("Como você enxerga o que existe entre eles?", 15, GuildUI.C_TEXT))
	for lbl in info.labels:
		var action: String = ui.gs.BOND_ACTIONS.get(lbl, "")
		var hint := "  — desbloqueia \"%s\" em Laço Forte" % action if action != "" else ""
		ui.root.add_child(UIKit.button(lbl + hint, ui._on_label_chosen.bind(ev, lbl), "escolha"))


static func on_label_chosen(ui: GuildUI, ev: Dictionary, lbl: String) -> void:
	ui.gs.choose_bond_label(ev, lbl)
	Juice.flash(ui, GuildUI.C_GOLD if ev.threshold > 0 else GuildUI.C_BAD, 0.2, 0.5)
	ResultScreen.after_result(ui)


static func show_levelup(ui: GuildUI, entry: Dictionary) -> void:
	ui._clear()
	var h: Dictionary = ui.gs.heroes[entry.id]
	var opts: Dictionary = HeroRPG.levelup_options(ui.gs, entry)
	var pick := {"attr": "", "choice": {}}
	var head := HBoxContainer.new()
	ui.root.add_child(head)
	var lp := Widgets.portrait(ui, h, 72)
	head.add_child(lp)
	var lt := UIKit.label("  %s chegou ao nível %d!" % [h.name, entry.level], 28, GuildUI.C_GOLD)
	head.add_child(lt)
	Juice.flash(ui, Color("#f2d27a"), 0.2, 0.6)
	Juice.pop(lp, 0.2, 0.4, 0.05)
	Juice.pop(lt, 0.1, 0.35, 0.15)
	ui.root.add_child(UIKit.label("%s · %s" % [h["class"], h.archetype], 15, GuildUI.C_MUTED))

	ui.root.add_child(UIKit.label("Escolha um atributo para melhorar (+1):", 16, GuildUI.C_TEXT))
	var arow := HBoxContainer.new()
	arow.add_theme_constant_override("separation", 8)
	ui.root.add_child(arow)
	var attr_buttons := []
	for k in ui.gs.ATTRS:
		var b := UIKit.button("%s\n%d → %d" % [ui.gs.ATTR_NAMES[k], h.attrs[k], h.attrs[k] + 1], func(): pass)
		b.toggle_mode = true
		b.custom_minimum_size = Vector2(140, 56)
		b.disabled = not opts.attrs.has(k)
		attr_buttons.append(b)
		arow.add_child(b)
	var choice_buttons := []
	if not opts.choices.is_empty():
		var kind: String = "uma nova magia" if opts.choices[0].kind == "spell" else "um novo talento"
		ui.root.add_child(UIKit.label("Nível marcante! Escolha %s:" % kind, 16, GuildUI.C_GOLD))
		for c in opts.choices:
			var b := UIKit.button("%s — %s" % [c.name, c.desc], func(): pass)
			b.toggle_mode = true
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT
			choice_buttons.append(b)
			ui.root.add_child(b)
	ui.root.add_child(UIKit.spacer_v())
	var confirm := UIKit.button("Confirmar", func():
		HeroRPG.apply_levelup(ui.gs, entry, pick.attr, pick.choice)
		ResultScreen.after_result(ui))
	confirm.disabled = true
	ui.root.add_child(confirm)
	var refresh := func():
		confirm.disabled = (pick.attr == "" and not opts.attrs.is_empty()) or (pick.choice.is_empty() and not opts.choices.is_empty())
	for i in attr_buttons.size():
		var k: String = ui.gs.ATTRS[i]
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
