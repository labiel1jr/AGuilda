class_name ExpeditionScreen
## Mapa Mágico da expedição: painel do grupo, log, chamadas, dado, mercador e alvo.
## Funções estáticas sobre a tela principal (ui: GuildUI, a cena main).


static func show_map(ui: GuildUI, m: Dictionary) -> void:
	ui._clear()
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 16)
	ui.root.add_child(body)

	var frame := UIKit.panel(Color("#1a1420"))
	frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	frame.size_flags_stretch_ratio = 2.2
	body.add_child(frame)
	ui._map = GuildUI.MagicMap.new()
	ui._map.size_flags_vertical = Control.SIZE_EXPAND_FILL
	ui._map.clip_contents = true
	frame.add_child(ui._map)

	var side := UIKit.panel(GuildUI.C_PANEL)
	side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(side)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	side.add_child(col)
	col.add_child(UIKit.label("Mapa Mágico de Escrutínio", 13, GuildUI.C_MUTED))
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	col.add_child(head)
	head.add_child(UIKit.para(m.name, 20, GuildUI.C_GOLD))
	head.add_child(UIKit.badge(ui.gs.RISK_NAMES[m.risk], GuildUI.RISK_COLORS[m.risk].darkened(0.2)))
	ui._map_party = VBoxContainer.new()
	ui._map_party.add_theme_constant_override("separation", 2)
	col.add_child(ui._map_party)
	ui._map_status = UIKit.para("", 13, GuildUI.C_TEXT)
	col.add_child(ui._map_status)
	col.add_child(HSeparator.new())
	ui._map_scroll = ScrollContainer.new()
	ui._map_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	ui._map_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(ui._map_scroll)
	ui._map_log = VBoxContainer.new()
	ui._map_log.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ui._map_log.add_theme_constant_override("separation", 6)
	ui._map_scroll.add_child(ui._map_log)
	ui._map_action = VBoxContainer.new()
	ui._map_action.add_theme_constant_override("separation", 6)
	col.add_child(ui._map_action)

	var tokens := []
	for id in ui.gs.expedition.party:
		var h: Dictionary = ui.gs.heroes[id]
		tokens.append({"id": id, "name": h.name, "color": h.color, "tex": UIKit.tex("res://art/tokens/%s_parado.png" % id)})
	var et := Widgets.enemy_texture(ui, m)
	if et != null:
		ui._map.goal_texture = et
	ui._map.type_info = ui.gs.route_data.types
	var ets := Widgets.enemy_textures(ui, m)
	if ets.size() >= 2:
		ui._map.mini_texture = ets[1]
	ui._map.setup(m, tokens, ui.gs.day * 1000 + ui.gs.missions.find(m), ui.gs.expedition)
	ui._map.node_chosen.connect(ui._on_node_chosen)
	ui._map.arrived.connect(ui._on_node_arrived)
	ExpeditionScreen.log_lines(ui, [String(ui.gs.narration.start[0]).replace("{party}", ", ".join(ui.gs.expedition.party.map(func(id): return ui.gs.heroes[id].name)))], GuildUI.C_TEXT)
	ExpeditionScreen.map_refresh(ui)


static func map_refresh(ui: GuildUI) -> void:
	var exp: Dictionary = ui.gs.expedition
	if exp.is_empty() or not is_instance_valid(ui._map_party):
		return
	for c in ui._map_party.get_children():
		c.queue_free()
	var prev: Dictionary = ui._map_prev
	ui._map_prev = {"provisions": exp.provisions, "gold": exp.gold, "bonus": exp.bonus, "items": exp.items.size(), "hp": {}, "stress": {}}
	for id in exp.party:
		var h: Dictionary = ui.gs.heroes[id]
		ui._map_prev.hp[id] = h.hp
		ui._map_prev.stress[id] = int(h.get("stress", 0))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		ui._map_party.add_child(row)
		if not prev.is_empty():
			if h.hp < int(prev.hp.get(id, h.hp)):
				Juice.blink(row, Color(2.0, 0.6, 0.55), 0.7)
			elif int(h.get("stress", 0)) > int(prev.stress.get(id, 0)):
				Juice.blink(row, Color(1.5, 0.8, 1.6), 0.7)
			elif h.hp > int(prev.hp.get(id, h.hp)):
				Juice.blink(row, Color(0.8, 1.7, 0.9), 0.7)
		row.add_child(Widgets.portrait(ui, h, 26))
		row.add_child(UIKit.label(h.name, 14, h.color.lightened(0.25)))
		row.add_child(UIKit.spacer())
		var low: bool = h.hp <= h.hp_max / 3
		row.add_child(Widgets.stress_chip(ui, h))
		row.add_child(UIKit.label("PV %d/%d" % [h.hp, h.hp_max], 13, GuildUI.C_BAD if low else GuildUI.C_MUTED))
	var mod := Expedition.route_mod(ui.gs)
	ui._map_status.text = "Provisões %d   ·   Bolsa da rota %d ouro   ·   Itens %d\nPreparação %+d   ·   Desgaste −%d   ·   Fome −%d   →   Rota no score %+d" % [
		exp.provisions, exp.gold, exp.items.size(), exp.bonus, Expedition.wear(ui.gs), mini(exp.hunger, 2), mod]
	if not prev.is_empty():
		var at := ui._map_status.global_position + Vector2(ui._map_status.size.x * 0.35, -6)
		var deltas := [["gold", "%+d ouro", GuildUI.C_GOLD], ["provisions", "%+d provisões", GuildUI.C_TEXT], ["bonus", "%+d preparação", GuildUI.C_GOOD], ["items", "%+d item", GuildUI.C_GOLD]]
		var k := 0
		for d in deltas:
			var dv: int = int(ui._map_prev[d[0]]) - int(prev[d[0]])
			if dv != 0:
				var colr: Color = GuildUI.C_BAD if dv < 0 else d[2]
				var txt: String = d[1] % dv
				ui.get_tree().create_timer(0.18 * k).timeout.connect(func(): Juice.fly_text(ui, txt, at, colr))
				k += 1
		if k > 0:
			Juice.pop(ui._map_status, 0.05, 0.3)
		if exp.provisions == 0 and int(prev.provisions) > 0:
			Juice.blink(ui._map_status, Color(2.0, 0.7, 0.6), 1.0)
	ui._map.reachable = Expedition.choices(ui.gs)
	if exp.pending == "" and not Expedition.at_boss(ui.gs) and ui._map_action.get_child_count() == 0:
		var hint := "Escolha o próximo caminho no mapa (passe o mouse para ver o que há em cada ponto)."
		if exp.provisions == 0:
			hint += "\nSem provisões: o próximo passo será com fome."
		ui._map_action.add_child(UIKit.para(hint, 14, GuildUI.C_GOLD))


static func log_lines(ui: GuildUI, lines: Array, color: Color = GuildUI.C_TEXT) -> void:
	for l in lines:
		var lbl := UIKit.para(l, 14, color)
		lbl.modulate.a = 0.0
		ui._map_log.add_child(lbl)
		ui.create_tween().tween_property(lbl, "modulate:a", 1.0, 0.5)
	await ui.get_tree().process_frame
	if is_instance_valid(ui._map_scroll):
		ui._map_scroll.scroll_vertical = int(ui._map_scroll.get_v_scroll_bar().max_value)


static func clear_action(ui: GuildUI) -> void:
	for c in ui._map_action.get_children():
		ui._map_action.remove_child(c)
		c.queue_free()


static func on_node_chosen(ui: GuildUI, pos: Array) -> void:
	ExpeditionScreen.clear_action(ui)
	ui._map.move_to(pos)


static func on_node_arrived(ui: GuildUI, pos: Array) -> void:
	var out: Dictionary = Expedition.enter(ui.gs, pos)
	var node: Dictionary = Expedition.node_at(ui.gs, pos)
	ExpeditionScreen.log_lines(ui, ["— %s —" % ui.gs.route_data.types[node.type].name], GuildUI.C_GOLD)
	ExpeditionScreen.log_lines(ui, out.lines, GuildUI.C_MUTED)
	ExpeditionScreen.clear_action(ui)
	if out.get("boss", false):
		Juice.flash(ui, Color("#a8443c"), 0.15, 0.6)
	if out.get("boss", false):
		var m := Expedition.mission(ui.gs)
		ui._map_action.add_child(UIKit.para("O grupo chegou ao alvo. Rota no score: %+d." % Expedition.route_mod(ui.gs), 14, GuildUI.C_GOLD))
		ui._map_action.add_child(UIKit.button("Enfrentar: " + m.name, ui._on_face_boss))
	elif out.has("event"):
		ui._map.caller = out.caller
		ExpeditionScreen.show_call(ui, out.event, out.caller)
	elif out.has("shop"):
		ExpeditionScreen.show_shop(ui, out.shop)
	ExpeditionScreen.map_refresh(ui)
	Moments.play_moments(ui)


## O herói chama pelo Mapa Mágico e pede uma decisão.
static func show_call(ui: GuildUI, ev: Dictionary, caller: String) -> void:
	ExpeditionScreen.clear_action(ui)
	var h: Dictionary = ui.gs.heroes[caller]
	var call := UIKit.panel(GuildUI.C_PARCHMENT)
	ui._map_action.add_child(call)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	call.add_child(row)
	row.add_child(Widgets.portrait(ui, h, 56))
	var txt := VBoxContainer.new()
	txt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(txt)
	txt.add_child(UIKit.label("%s chama pelo Mapa Mágico:" % h.name, 12, GuildUI.C_INK.lightened(0.3)))
	txt.add_child(UIKit.label(ev.title, 17, GuildUI.C_INK))
	txt.add_child(UIKit.para(Expedition._fill(ui.gs, ev.text, caller), 14, GuildUI.C_INK))
	for opt in ev.options:
		var hint := Expedition.test_hint(ui.gs, opt)
		var b := UIKit.button(opt.label + ("   [%s]" % hint if hint != "" else ""), ui._on_call_choice.bind(opt))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var block := Expedition.option_block(ui.gs, opt)
		if block != "":
			b.disabled = true
			b.tooltip_text = block
		ui._map_action.add_child(b)


static func on_call_choice(ui: GuildUI, opt: Dictionary) -> void:
	var r: Dictionary = Expedition.choose(ui.gs, opt)
	ui._map.caller = ""
	ExpeditionScreen.log_lines(ui, ["» " + opt.label], GuildUI.C_GOLD)
	ExpeditionScreen.clear_action(ui)
	var finish := func():
		if not is_instance_valid(ui._map_log) or ui.gs.expedition.is_empty():
			return
		ExpeditionScreen.log_lines(ui, r.lines, GuildUI.C_TEXT)
		ExpeditionScreen.map_refresh(ui)
		Moments.play_moments(ui)
	if r.has("dice"):
		ExpeditionScreen.roll_dice(ui, r.dice, finish)
	else:
		finish.call()


## d20 visível: gira, quica e para no resultado. Só visual — o teste já foi resolvido.
static func roll_dice(ui: GuildUI, d: Dictionary, done: Callable) -> void:
	if is_instance_valid(ui._dice_box):
		ui._dice_box.queue_free()   # uma rolagem por vez
	var box := UIKit.panel(GuildUI.C_PARCHMENT)
	ui._dice_box = box
	box.top_level = true
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(box)
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(col)
	var who := UIKit.label("%s testa %s (CD %d, %+d)" % [ui.gs.heroes[d.hero].name, ui.gs.ATTR_NAMES[d.attr], d.dc, d.mod], 14, GuildUI.C_INK)
	who.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(who)
	var num := UIKit.label("20", 54, GuildUI.C_INK)
	num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(num)
	var verdict := UIKit.label("", 18, GuildUI.C_INK)
	verdict.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(verdict)
	box.custom_minimum_size = Vector2(260, 150)
	var frame_rect: Rect2 = ui._map.get_global_rect() if is_instance_valid(ui._map) else ui.get_viewport_rect()
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
			Juice.flash(ui, Color("#f2d27a"), 0.3, 0.5)
			Juice.shake(ui, 3.0, 0.2)
		elif d.roll == 1:
			Juice.flash(ui, Color("#8a2f1f"), 0.25, 0.5)
			Juice.shake(ui, 5.0, 0.3))
	tw.tween_interval(0.25 if Juice.reduce_motion else 0.8)
	tw.tween_property(box, "modulate:a", 0.0, 0.25)
	tw.tween_callback(func():
		box.queue_free()
		done.call())


static func show_shop(ui: GuildUI, stock: Array) -> void:
	ExpeditionScreen.clear_action(ui)
	ui._map_action.add_child(UIKit.label("Mercador de estrada — ouro da guilda: %d" % ui.gs.gold, 15, GuildUI.C_GOLD))
	for iid in stock:
		var it: Dictionary = HeroRPG.item(ui.gs, iid)
		var b := UIKit.button("%s — %d ouro" % [it.name, int(it.price)], func():
			if HeroRPG.buy(ui.gs, iid):
				ExpeditionScreen.log_lines(ui, ["Comprado: %s (vai para o Baú)." % it.name], GuildUI.C_TEXT)
				stock.erase(iid)
			ExpeditionScreen.show_shop(ui, stock))
		b.tooltip_text = it.get("desc", "")
		UIKit.button_icon(b, UIKit.item_tex(iid), 32)
		b.disabled = ui.gs.gold < int(it.price)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		ui._map_action.add_child(b)
	var sp: Dictionary = ui.gs.route_data.shop_provisions
	var pb := UIKit.button("Provisões (+%d) — %d ouro" % [int(sp.amount), int(sp.price)], func():
		if Expedition.buy_provisions(ui.gs):
			ExpeditionScreen.log_lines(ui, ["Provisões compradas (+%d)." % int(sp.amount)], GuildUI.C_TEXT)
		ExpeditionScreen.show_shop(ui, stock)
		ExpeditionScreen.map_refresh(ui))
	UIKit.button_icon(pb, UIKit.tex("res://art/items/provisoes.png"), 32)
	pb.disabled = ui.gs.gold < int(sp.price)
	pb.alignment = HORIZONTAL_ALIGNMENT_LEFT
	ui._map_action.add_child(pb)
	ui._map_action.add_child(UIKit.button("Seguir viagem ▶", func():
		ExpeditionScreen.clear_action(ui)
		ExpeditionScreen.map_refresh(ui)))


static func on_face_boss(ui: GuildUI) -> void:
	var res: Dictionary = Expedition.finish(ui.gs)
	ui.last_result = res
	ResultScreen.show_result(ui, res)
