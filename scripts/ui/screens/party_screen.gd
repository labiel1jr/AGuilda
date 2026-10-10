class_name PartyScreen
## Montagem de party: seleção, preview de afinidade, magias, despacho com o Selo de Cera.
## Funções estáticas sobre a tela principal (ui: GuildUI, a cena main).


static func show_party(ui: GuildUI, m: Dictionary) -> void:
	ui.selected = []
	ui.prepared = {}
	PartyScreen.render_party(ui, m)


static func render_party(ui: GuildUI, m: Dictionary) -> void:
	ui._clear()
	var head := HBoxContainer.new()
	ui.root.add_child(head)
	var poster := Widgets.enemy_poster(ui, m, 56)
	if poster != null:
		head.add_child(poster)
	head.add_child(UIKit.label("MISSÃO: " + m.name, 22, GuildUI.C_GOLD))
	head.add_child(UIKit.spacer())
	head.add_child(UIKit.label("[%s]" % ui.gs.RISK_NAMES[m.risk], 18, GuildUI.RISK_COLORS[m.risk]))
	ui.root.add_child(UIKit.label("Atributo: %s + %s" % [ui.gs.ATTR_NAMES[m.primary], ui.gs.ATTR_NAMES[m.secondary]], 15, GuildUI.C_TEXT))
	for tag in m.get("tags", []):
		ui.root.add_child(UIKit.para("⚑ " + tag.text, 14, GuildUI.C_BAD))

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 16)
	ui.root.add_child(body)

	# Aventureiros
	var lp := UIKit.panel(GuildUI.C_PANEL)
	lp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(lp)
	var lcol := VBoxContainer.new()
	lcol.add_theme_constant_override("separation", 6)
	lp.add_child(lcol)
	lcol.add_child(UIKit.label("AVENTUREIROS", 16, GuildUI.C_GOLD))
	for id in ui.gs.hero_order:
		var h: Dictionary = ui.gs.heroes[id]
		var reason: String = ui.gs.unavailable_reason(id, m)
		var row := HBoxContainer.new()
		lcol.add_child(row)
		row.add_child(UIKit.swatch(h.color))
		var is_sel := ui.selected.has(id)
		var b := UIKit.button(("✓ " if is_sel else "") + h.name, ui._toggle_hero.bind(m, id))
		b.custom_minimum_size.x = 110
		b.disabled = reason != "" or (not is_sel and ui.selected.size() >= 4)
		row.add_child(b)
		var ea: Dictionary = HeroRPG.effective_attrs(ui.gs, id)
		row.add_child(UIKit.label("Nv %d · %s %d / %s %d" % [h.level, ui.gs.ATTR_NAMES[m.primary].left(3), ea[m.primary], ui.gs.ATTR_NAMES[m.secondary].left(3), ea[m.secondary]], 13, GuildUI.C_TEXT))
		row.add_child(UIKit.spacer())
		row.add_child(Widgets.stress_chip(ui, h))
		var state: String = reason if reason != "" else ui.gs.hero_status(id)
		row.add_child(UIKit.label(state, 13, GuildUI.C_BAD if reason != "" else UIKit.fatigue_color(h)))

	# Party selecionada
	var rp := UIKit.panel(GuildUI.C_PANEL)
	rp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(rp)
	var rcol := VBoxContainer.new()
	rcol.add_theme_constant_override("separation", 6)
	rp.add_child(rcol)
	rcol.add_child(UIKit.label("PARTY SELECIONADA", 16, GuildUI.C_GOLD))
	if ui.selected.is_empty():
		rcol.add_child(UIKit.label("Selecione de 1 a 4 aventureiros.", 14, GuildUI.C_MUTED))
	for id in ui.selected:
		var h: Dictionary = ui.gs.heroes[id]
		var tired := "  (Cansado: −40%)" if h.fatigue == 1 else ""
		var prow := HBoxContainer.new()
		rcol.add_child(prow)
		if id == ui._last_toggle:
			Juice.fade_in(prow, 0.0, 0.25)
			Juice.pop(prow, 0.1, 0.25, 0.02)
		prow.add_child(UIKit.label("→ %s%s" % [h.name, tired], 14, GuildUI.C_TEXT))
		if HeroRPG.is_caster(ui.gs, id):
			prow.add_child(UIKit.spacer())
			prow.add_child(PartyScreen.spell_picker(ui, m, id))

	var pairs := ScoreCalc.pairs_of(ui.selected)
	if pairs.size() > 0:
		rcol.add_child(UIKit.label("AFINIDADE DA PARTY:", 14, GuildUI.C_GOLD))
		for pr in pairs:
			var v: int = ui.gs.pair_value(pr[0], pr[1])
			var lbl: String = ui.gs.bond_label(pr[0], pr[1])
			var extra := "  · " + lbl if lbl != "" else ""
			var pl := UIKit.label("%s ↔ %s  %s%s" % [ui.gs.heroes[pr[0]].name, ui.gs.heroes[pr[1]].name, ui.gs.describe_aff(v), extra], 14, UIKit.aff_color(v))
			rcol.add_child(pl)
			if v <= -3 and ui._last_toggle in pr:
				Juice.blink(pl, Color(2.0, 0.7, 0.6), 0.8)
	for act in ui.gs.active_bond_actions(ui.selected):
		rcol.add_child(UIKit.label("✦ Ação de Vínculo: %s (%s & %s)" % [act.action, ui.gs.heroes[act.a].name, ui.gs.heroes[act.b].name], 14, GuildUI.C_GOLD))

	var unmet: Array = ui.gs.unmet_tags(m, ui.selected)
	if not ui.selected.is_empty():
		var est := ScoreCalc.compute(ui.gs, m, ui.selected, null, ui.prepared)
		if est.powers > 0:
			rcol.add_child(UIKit.label("✦ Poderes (itens, talentos, magias): +%d" % est.powers, 14, GuildUI.C_GOLD))
		var t: Array = ScoreCalc.THRESHOLDS[m.risk]
		var txt := "Arriscado"
		var col := GuildUI.C_BAD
		if est.total >= t[1]:
			txt = "Promissor"
			col = GuildUI.C_GOOD
		elif est.total >= t[0]:
			txt = "Incerto"
			col = GuildUI.C_GOLD
		var bar := ProgressBar.new()
		bar.max_value = t[1] + 2
		bar.value = clampf(est.total, 0, bar.max_value)
		bar.show_percentage = false
		bar.custom_minimum_size.y = 14
		var fill := StyleBoxFlat.new()
		fill.bg_color = col
		bar.add_theme_stylebox_override("fill", fill)
		rcol.add_child(UIKit.label("Expectativa: " + txt, 15, col))
		rcol.add_child(bar)
	if m.has("hidden"):
		if HeroRPG.reveals_hidden(ui.gs, ui.selected, ui.prepared):
			rcol.add_child(UIKit.para("👁 Revelado: " + m.hidden.text, 13, GuildUI.C_GOLD))
		else:
			rcol.add_child(UIKit.para("⚠ Algo nesta missão não está no pergaminho...", 13, GuildUI.C_MUTED))
	for u in unmet:
		rcol.add_child(UIKit.para("✗ " + u, 13, GuildUI.C_BAD))

	var foot := HBoxContainer.new()
	ui.root.add_child(foot)
	foot.add_child(UIKit.button("◀ Voltar", ui.show_hub))
	foot.add_child(UIKit.spacer())
	var go := UIKit.button("  DESPACHAR PARTY — Selo de Cera  ", ui._on_dispatch.bind(m))
	go.disabled = ui.selected.is_empty() or not unmet.is_empty()
	foot.add_child(go)


static func toggle_hero(ui: GuildUI, m: Dictionary, id: String) -> void:
	if ui.selected.has(id):
		ui.selected.erase(id)
		ui.prepared.erase(id)
	elif ui.selected.size() < 4:
		ui.selected.append(id)
	ui._last_toggle = id
	PartyScreen.render_party(ui, m)
	ui._last_toggle = ""


static func on_dispatch(ui: GuildUI, m: Dictionary) -> void:
	Expedition.start(ui.gs, m, ui.selected.duplicate(), ui.prepared.duplicate())
	ui.selected = []
	ui.prepared = {}
	ExpeditionScreen.show_map(ui, m)
	PartyScreen.stamp_seal(ui)


## O Selo de Cera desce e carimba: a decisão está tomada.
static func stamp_seal(ui: GuildUI) -> void:
	var seal = GuildUI.WaxSeal.new()
	seal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	seal.size = Vector2(170, 170)
	seal.position = ui.get_viewport_rect().size / 2.0 - seal.size / 2.0
	seal.pivot_offset = seal.size / 2.0
	ui.add_child(seal)
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
		tw.tween_callback(func(): Juice.shake(ui, 6.0, 0.25); Juice.flash(ui, Color("#a8443c"), 0.18, 0.3))
	tw.tween_interval(0.55)
	tw.tween_property(seal, "modulate:a", 0.0, 0.35)
	tw.tween_callback(seal.queue_free)


static func spell_picker(ui: GuildUI, m: Dictionary, id: String) -> Control:
	var h: Dictionary = ui.gs.heroes[id]
	var ob := OptionButton.new()
	ob.add_item("Sem magia (%d espaço(s))" % h.slots)
	ob.set_item_metadata(0, "")
	var i := 1
	for sid in h.spells_known:
		ob.add_item(HeroRPG.spell(ui.gs, sid).name)
		ob.set_item_metadata(i, sid)
		ob.set_item_tooltip(i, HeroRPG.spell(ui.gs, sid).desc)
		if ui.prepared.get(id, "") == sid:
			ob.select(i)
		i += 1
	ob.disabled = h.slots <= 0
	ob.tooltip_text = "Sem espaços de magia: precisa descansar." if h.slots <= 0 else "Magia preparada para esta missão (gasta 1 espaço)."
	ob.item_selected.connect(func(idx: int):
		var sid: String = ob.get_item_metadata(idx)
		if sid == "":
			ui.prepared.erase(id)
		else:
			ui.prepared[id] = sid
		PartyScreen.render_party(ui, m))
	return ob
