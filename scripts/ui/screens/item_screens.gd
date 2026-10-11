class_name ItemScreens
## Mercado, equipamento e magia lançada na guilda.
## Funções estáticas sobre a tela principal (ui: GuildUI, a cena main).


static func show_market(ui: GuildUI) -> void:
	ui._clear()
	var top := HBoxContainer.new()
	ui.root.add_child(top)
	top.add_child(UIKit.label("Mercado de Pedravale", 24, GuildUI.C_GOLD))
	top.add_child(UIKit.spacer())
	top.add_child(UIKit.label("Ouro %d" % ui.gs.gold, 18, GuildUI.C_TEXT))
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 16)
	ui.root.add_child(body)

	var lp := UIKit.panel(GuildUI.C_PANEL)
	lp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(lp)
	var lcol := VBoxContainer.new()
	lp.add_child(lcol)
	lcol.add_child(UIKit.label("À venda", 18, GuildUI.C_GOLD))
	for iid in HeroRPG.shop_items(ui.gs):
		var it := HeroRPG.item(ui.gs, iid)
		lcol.add_child(ItemScreens.item_row(ui, it, "Comprar %d" % HeroRPG.buy_price(ui.gs, iid), ui.gs.gold < HeroRPG.buy_price(ui.gs, iid), func():
			HeroRPG.buy(ui.gs, iid)
			ItemScreens.show_market(ui)))

	var rp := UIKit.panel(GuildUI.C_PANEL)
	rp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(rp)
	var rcol := VBoxContainer.new()
	rp.add_child(rcol)
	rcol.add_child(UIKit.label("Baú da Guilda (vender)", 18, GuildUI.C_GOLD))
	if ui.gs.inventory.is_empty():
		rcol.add_child(UIKit.label("O baú está vazio.", 14, GuildUI.C_MUTED))
	for i in ui.gs.inventory.size():
		var iid: String = ui.gs.inventory[i]
		var it := HeroRPG.item(ui.gs, iid)
		rcol.add_child(ItemScreens.item_row(ui, it, "Vender %d" % HeroRPG.sell_price(ui.gs, iid), false, func():
			HeroRPG.sell(ui.gs, i)
			ItemScreens.show_market(ui)))
	ui.root.add_child(UIKit.button("◀ Voltar", ui.show_hub))


static func item_row(ui: GuildUI, it: Dictionary, action: String, disabled: bool, cb: Callable, iid: String = "") -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	if iid == "":
		for k in ui.gs.items_data.items:
			if is_same(ui.gs.items_data.items[k], it):
				iid = k
	var tex := UIKit.item_tex(iid)
	if tex != null:
		row.add_child(UIKit.icon(tex, 40))
	var name := UIKit.label(("★ " if it.get("rare", false) else "") + it.name, 14, GuildUI.C_GOLD if it.get("rare", false) else GuildUI.C_TEXT)
	name.custom_minimum_size.x = 190
	row.add_child(name)
	var d := UIKit.para(it.desc, 12, GuildUI.C_MUTED)
	row.add_child(d)
	var b := UIKit.button(action, cb)
	b.disabled = disabled
	row.add_child(b)
	return row


static func show_equip(ui: GuildUI, index: int) -> void:
	ui._clear()
	var id: String = ui.gs.hero_order[index]
	var h: Dictionary = ui.gs.heroes[id]
	var top := HBoxContainer.new()
	ui.root.add_child(top)
	top.add_child(UIKit.swatch(h.color, 24))
	top.add_child(UIKit.label("  Equipamento de %s" % h.name, 24, GuildUI.C_GOLD))
	top.add_child(UIKit.spacer())
	var armor: Array = HeroRPG.class_info(ui.gs, id).get("armor", [])
	top.add_child(UIKit.label("%s · armaduras: %s" % [h["class"], ", ".join(armor.map(func(a): return HeroRPG.ARMOR_NAMES[a])) if not armor.is_empty() else "nenhuma"], 14, GuildUI.C_MUTED))
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 16)
	ui.root.add_child(body)

	var lp := UIKit.panel(GuildUI.C_PANEL)
	lp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(lp)
	var lcol := VBoxContainer.new()
	lcol.add_theme_constant_override("separation", 8)
	lp.add_child(lcol)
	lcol.add_child(UIKit.label("Equipado", 18, GuildUI.C_GOLD))
	for slot in HeroRPG.SLOTS:
		var row := HBoxContainer.new()
		lcol.add_child(row)
		var sl := UIKit.label(HeroRPG.SLOT_NAMES[slot], 14, GuildUI.C_MUTED)
		sl.custom_minimum_size.x = 100
		row.add_child(sl)
		var cur: String = h.equip[slot]
		if cur == "":
			row.add_child(UIKit.label("—", 14, GuildUI.C_MUTED))
		else:
			var it := HeroRPG.item(ui.gs, cur)
			var et := UIKit.item_tex(cur)
			if et != null:
				row.add_child(UIKit.icon(et, 36))
			row.add_child(UIKit.label(it.name, 14, GuildUI.C_TEXT))
			row.add_child(UIKit.para(it.desc, 12, GuildUI.C_MUTED))
			row.add_child(UIKit.button("Remover", func():
				HeroRPG.unequip(ui.gs, id, slot)
				ItemScreens.show_equip(ui, index)))

	var rp := UIKit.panel(GuildUI.C_PANEL)
	rp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(rp)
	var rcol := VBoxContainer.new()
	rcol.add_theme_constant_override("separation", 6)
	rp.add_child(rcol)
	rcol.add_child(UIKit.label("Baú da Guilda", 18, GuildUI.C_GOLD))
	if ui.gs.inventory.is_empty():
		rcol.add_child(UIKit.label("O baú está vazio. Missões trazem saque; o Mercado vende o básico.", 13, GuildUI.C_MUTED))
	for i in ui.gs.inventory.size():
		var iid: String = ui.gs.inventory[i]
		var it := HeroRPG.item(ui.gs, iid)
		var target := ""
		if it.slot == "consumivel":
			target = "consumivel1" if h.equip.consumivel1 == "" else "consumivel2"
		else:
			target = it.slot
		var reason := HeroRPG.equip_block_reason(ui.gs, id, target, iid)
		var row := ItemScreens.item_row(ui, it, "Equipar" if reason == "" else reason, reason != "", func():
			HeroRPG.equip(ui.gs, id, target, i)
			ItemScreens.show_equip(ui, index))
		rcol.add_child(row)
		if it.has("hub"):
			row.add_child(UIKit.button("Usar em %s" % h.name, func():
				var msg := HeroRPG.use_item_hub(ui.gs, i, id)
				GuildScreens.toast(ui, msg, ui.show_equip.bind(index))))
	ui.root.add_child(UIKit.button("◀ Voltar ao Livro", ui.show_book.bind(index)))


## Lançar magia da guilda: escolhe o alvo.
static func show_cast(ui: GuildUI, caster: String, sid: String, back_index: int) -> void:
	ui._clear()
	var sp := HeroRPG.spell(ui.gs, sid)
	ui.root.add_child(UIKit.label("%s — %s" % [ui.gs.heroes[caster].name, sp.name], 24, GuildUI.C_GOLD))
	ui.root.add_child(UIKit.para(sp.desc, 14, GuildUI.C_MUTED))
	ui.root.add_child(UIKit.label("Em quem?", 16, GuildUI.C_TEXT))
	for id in ui.gs.hero_order:
		var h: Dictionary = ui.gs.heroes[id]
		var b := UIKit.button("%s   PV %d/%d   %s" % [h.name, h.hp, h.hp_max, ui.gs.hero_status(id)], func():
			GuildScreens.toast(ui, HeroRPG.cast_hub(ui.gs, caster, sid, id), ui.show_book.bind(back_index)))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.disabled = h.busy
		ui.root.add_child(b)
	ui.root.add_child(UIKit.spacer_v())
	ui.root.add_child(UIKit.button("◀ Voltar", ui.show_book.bind(back_index)))
