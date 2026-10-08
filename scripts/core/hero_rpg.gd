class_name HeroRPG
## Progressão de RPG dos heróis: XP e níveis, equipamento, consumíveis, magias, talentos, saque e mercado.
## Funções estáticas que operam sobre o GameState (gs). Dados em data/classes.json e data/items.json.
##
## Efeitos (de itens, talentos e magias preparadas) — ver _doc de classes.json:
##   attr, mission_type, score, affinity, damage_reduction, fatigue_resist,
##   heal_after, morale_after, xp_pct, reveal_hidden.
##   "party": true faz o efeito valer para todos da party; senão vale só para o dono
##   (relevante para damage_reduction, fatigue_resist e morale_after).

const SLOTS := ["arma", "armadura", "acessorio", "consumivel1", "consumivel2"]
const SLOT_NAMES := {"arma": "Arma", "armadura": "Armadura", "acessorio": "Acessório", "consumivel1": "Consumível", "consumivel2": "Consumível"}
const ARMOR_NAMES := {"leve": "leve", "media": "média", "pesada": "pesada"}


static func init_hero(gs, h: Dictionary, src: Dictionary) -> void:
	h.xp = 0
	h.spells_known = src.get("spells_known", []).duplicate()
	h.talents = []
	h.equip = {}
	for s in SLOTS:
		h.equip[s] = ""
	h.resting = false
	h.rest_request = false
	h.slots = max_slots(gs, h.id, h)
	Mind.ensure(h)


# ---------- classe e níveis ----------

static func class_info(gs, id: String) -> Dictionary:
	return gs.classes_data.classes.get(gs.heroes[id]["class"], {})


static func is_caster(gs, id: String) -> bool:
	return class_info(gs, id).get("caster", false)


static func max_slots(gs, id: String, h: Dictionary = {}) -> int:
	if h.is_empty():
		h = gs.heroes[id]
	if not gs.classes_data.classes.get(h["class"], {}).get("caster", false):
		return 0
	return 1 + int(h.level) / 3


static func xp_to_next(gs, level: int) -> int:
	var x: Dictionary = gs.classes_data.xp
	return int(x.next_level_base) + int(x.next_level_step) * (level - 1)


static func gain_xp(gs, id: String, amount: int) -> Array:
	var h: Dictionary = gs.heroes[id]
	var x: Dictionary = gs.classes_data.xp
	var lines := []
	amount = int(round(amount * (1.0 + xp_pct(gs, id) / 100.0)))
	if h.level >= int(x.max_level):
		return lines
	h.xp += amount
	while h.level < int(x.max_level) and h.xp >= xp_to_next(gs, h.level):
		h.xp -= xp_to_next(gs, h.level)
		h.level += 1
		var hp_gain: int = int(class_info(gs, id).get("hp_per_level", 2))
		h.hp_max += hp_gain
		h.hp += hp_gain
		h.slots = max_slots(gs, id)
		gs.pending_levelups.append({"id": id, "level": h.level})
		lines.append("%s subiu para o nível %d! (+%d PV máx.)" % [h.name, h.level, hp_gain])
	return lines


static func is_milestone(gs, level: int) -> bool:
	return gs.classes_data.xp.milestones.has(level)


## Opções da tela de subida de nível: atributos disponíveis e, em nível marcante, 2 magias ou talentos.
static func levelup_options(gs, entry: Dictionary) -> Dictionary:
	var id: String = entry.id
	var h: Dictionary = gs.heroes[id]
	var cap: int = int(gs.classes_data.xp.max_attr)
	var attrs := []
	for k in gs.ATTRS:
		if h.attrs[k] < cap:
			attrs.append(k)
	var choices := []
	if is_milestone(gs, entry.level):
		var ci := class_info(gs, id)
		if ci.get("caster", false):
			for sid in ci.get("spells", []):
				var sp: Dictionary = gs.classes_data.spells[sid]
				if not h.spells_known.has(sid) and int(sp.level) <= entry.level:
					choices.append({"kind": "spell", "id": sid, "name": sp.name, "desc": sp.desc})
		else:
			for tid in ci.get("talents", []):
				if not h.talents.has(tid):
					var t: Dictionary = gs.classes_data.talents[tid]
					choices.append({"kind": "talent", "id": tid, "name": t.name, "desc": t.desc})
		# Duas opções sorteadas, estáveis para esta subida
		var seed_rng := RandomNumberGenerator.new()
		seed_rng.seed = hash(id + str(entry.level) + str(gs.day))
		while choices.size() > 2:
			choices.remove_at(seed_rng.randi_range(0, choices.size() - 1))
	return {"attrs": attrs, "choices": choices}


static func apply_levelup(gs, entry: Dictionary, attr: String, choice: Dictionary) -> void:
	var h: Dictionary = gs.heroes[entry.id]
	if attr != "":
		h.attrs[attr] = min(int(gs.classes_data.xp.max_attr), h.attrs[attr] + 1)
	if not choice.is_empty():
		if choice.kind == "spell":
			h.spells_known.append(choice.id)
		else:
			h.talents.append(choice.id)


# ---------- efeitos ----------

static func item(gs, item_id: String) -> Dictionary:
	return gs.items_data.items.get(item_id, {})


static func spell(gs, spell_id: String) -> Dictionary:
	return gs.classes_data.spells.get(spell_id, {})


## Efeitos permanentes do herói (talentos + equipamento) e da magia preparada, se houver.
static func hero_effects(gs, id: String, prepared_spell: String = "") -> Array:
	var h: Dictionary = gs.heroes[id]
	var out := []
	for tid in h.talents:
		out.append_array(gs.classes_data.talents[tid].effects)
	for s in SLOTS:
		if h.equip[s] != "":
			out.append_array(item(gs, h.equip[s]).get("effects", []))
	if prepared_spell != "":
		out.append_array(spell(gs, prepared_spell).get("effects", []))
	out.append_array(Mind.effects(gs, h))
	return out


static func effective_attrs(gs, id: String) -> Dictionary:
	var a: Dictionary = gs.heroes[id].attrs.duplicate()
	for e in hero_effects(gs, id):
		if e.type == "attr":
			a[e.attr] += int(e.value)
	return a


## [{owner, effect}] de toda a party, com as magias preparadas.
static func party_effects(gs, party: Array, prepared: Dictionary) -> Array:
	var out := []
	for id in party:
		for e in hero_effects(gs, id, prepared.get(id, "")):
			out.append({"owner": id, "e": e})
	return out


static func power_bonus(gs, mission: Dictionary, party: Array, prepared: Dictionary) -> int:
	var total := 0
	for pe in party_effects(gs, party, prepared):
		var e: Dictionary = pe.e
		if e.type == "score":
			total += int(e.value)
		elif e.type == "mission_type" and e.mission_type == mission.get("type", ""):
			total += int(e.value)
	return mini(total, int(gs.classes_data.power_cap))


static func affinity_bonus(gs, party: Array, prepared: Dictionary) -> int:
	if party.size() < 2:
		return 0
	var total := 0
	for pe in party_effects(gs, party, prepared):
		if pe.e.type == "affinity":
			total += int(pe.e.value)
	return mini(total, 2)


static func reveals_hidden(gs, party: Array, prepared: Dictionary) -> bool:
	for pe in party_effects(gs, party, prepared):
		if pe.e.type == "reveal_hidden":
			return true
	return false


## Soma de um efeito para um membro: os dele + os "party" de qualquer membro.
static func member_value(gs, id: String, party: Array, prepared: Dictionary, type: String) -> int:
	var total := 0
	for pe in party_effects(gs, party, prepared):
		if pe.e.type == type and (pe.owner == id or pe.e.get("party", false)):
			total += int(pe.e.get("value", 1))
	return total


static func xp_pct(gs, id: String) -> int:
	var total := 0
	for e in hero_effects(gs, id):
		if e.type == "xp_pct":
			total += int(e.value)
	return total


# ---------- missão: antes e depois ----------

## Gasta espaços de magia e consumíveis "on_dispatch". Chamado no despacho.
static func on_dispatch(gs, party: Array, prepared: Dictionary) -> Array:
	var lines := []
	for id in party:
		var h: Dictionary = gs.heroes[id]
		var sid: String = prepared.get(id, "")
		if sid != "" and h.slots > 0:
			h.slots -= 1
			lines.append("%s conjurou %s." % [h.name, spell(gs, sid).name])
	return lines


## Consumíveis "on_dispatch" saem do equipamento depois do cálculo do score.
static func consume_on_dispatch(gs, party: Array) -> void:
	for id in party:
		var h: Dictionary = gs.heroes[id]
		for s in ["consumivel1", "consumivel2"]:
			if h.equip[s] != "" and item(gs, h.equip[s]).get("auto", "") == "on_dispatch":
				h.equip[s] = ""


static func after_mission(gs, mission: Dictionary, party: Array, prepared: Dictionary, result: String) -> Array:
	var lines := []
	# Curas de magias preparadas
	var heal := 0
	for pe in party_effects(gs, party, prepared):
		if pe.e.type == "heal_after":
			heal += int(pe.e.value)
	if heal > 0:
		for id in party:
			var h: Dictionary = gs.heroes[id]
			h.hp = min(h.hp_max, h.hp + heal)
		lines.append("As curas da party restauram até %d PV de cada um." % heal)
	# Poções automáticas
	for id in party:
		var h: Dictionary = gs.heroes[id]
		for s in ["consumivel1", "consumivel2"]:
			var it := item(gs, h.equip[s])
			if not it.is_empty() and it.get("auto", "") == "after_damage" and h.hp <= h.hp_max / 2:
				h.hp = min(h.hp_max, h.hp + int(it.hub.heal))
				h.equip[s] = ""
				lines.append("%s bebeu uma %s na volta." % [h.name, it.name])
	# Moral extra
	for id in party:
		var bonus := member_value(gs, id, party, prepared, "morale_after")
		if bonus > 0:
			gs.heroes[id].morale = clampi(gs.heroes[id].morale + bonus, 0, 10)
	# XP
	var x: Dictionary = gs.classes_data.xp
	var base: int = int(round(int(x.by_risk[mission.risk]) * float(x.outcome_mult[result])))
	lines.append("Cada aventureiro ganha %d de XP." % base)
	for id in party:
		lines.append_array(gain_xp(gs, id, base))
	# Saque
	var loot := roll_loot(gs, mission, result)
	if loot != "":
		gs.inventory.append(loot)
		lines.append("Saque: %s foi para o Baú da Guilda." % item(gs, loot).name)
	return lines


static func roll_loot(gs, mission: Dictionary, result: String) -> String:
	var chance: float = float(gs.items_data.loot_chance[result])
	if gs.rng.randf() > chance:
		return ""
	var table: Array = mission.get("loot", gs.items_data.loot.get(mission.risk, []))
	if table.is_empty():
		return ""
	return table[gs.rng.randi_range(0, table.size() - 1)]


# ---------- equipamento ----------

static func slot_accepts(slot: String, it: Dictionary) -> bool:
	if slot.begins_with("consumivel"):
		return it.slot == "consumivel"
	return it.slot == slot


static func equip_block_reason(gs, id: String, slot: String, item_id: String) -> String:
	var it := item(gs, item_id)
	if not slot_accepts(slot, it):
		return "Não vai neste espaço"
	if it.slot == "armadura":
		var allowed: Array = class_info(gs, id).get("armor", [])
		if not allowed.has(it.armor_type):
			return "%s não usa armadura %s" % [gs.heroes[id]["class"], ARMOR_NAMES[it.armor_type]]
	return ""


## Equipa um item do Baú (índice) no espaço; o item anterior volta para o Baú.
static func equip(gs, id: String, slot: String, inv_index: int) -> bool:
	var item_id: String = gs.inventory[inv_index]
	if equip_block_reason(gs, id, slot, item_id) != "":
		return false
	gs.inventory.remove_at(inv_index)
	unequip(gs, id, slot)
	gs.heroes[id].equip[slot] = item_id
	return true


static func unequip(gs, id: String, slot: String) -> void:
	var cur: String = gs.heroes[id].equip[slot]
	if cur != "":
		gs.inventory.append(cur)
		gs.heroes[id].equip[slot] = ""


# ---------- guilda: magias e itens fora de missão ----------

static func hub_spells(gs, id: String) -> Array:
	var out := []
	for sid in gs.heroes[id].spells_known:
		if spell(gs, sid).has("hub"):
			out.append(sid)
	return out


static func apply_hub_effect(gs, hub: Dictionary, target: String) -> String:
	var t: Dictionary = gs.heroes[target]
	if hub.has("heal"):
		var before: int = t.hp
		t.hp = min(t.hp_max, t.hp + int(hub.heal))
		return "%s recupera %d PV." % [t.name, t.hp - before]
	if hub.get("restore", false):
		t.fatigue = max(0, t.fatigue - 1)
		return "%s se sente revigorado(a) (%s)." % [t.name, gs.FATIGUE_NAMES[t.fatigue]]
	return ""


static func cast_hub(gs, caster: String, sid: String, target: String) -> String:
	var h: Dictionary = gs.heroes[caster]
	if h.slots <= 0 or h.busy:
		return ""
	h.slots -= 1
	return "%s lança %s. %s" % [h.name, spell(gs, sid).name, apply_hub_effect(gs, spell(gs, sid).hub, target)]


static func use_item_hub(gs, inv_index: int, target: String) -> String:
	var it := item(gs, gs.inventory[inv_index])
	if not it.has("hub"):
		return ""
	gs.inventory.remove_at(inv_index)
	return "%s usado. %s" % [it.name, apply_hub_effect(gs, it.hub, target)]


# ---------- mercado ----------

static func shop_items(gs) -> Array:
	var out := []
	for iid in gs.items_data.items:
		if gs.items_data.items[iid].get("shop", false):
			out.append(iid)
	return out


static func buy(gs, item_id: String) -> bool:
	var price: int = int(item(gs, item_id).price)
	if gs.gold < price:
		return false
	gs.gold -= price
	gs.inventory.append(item_id)
	return true


static func sell_price(gs, item_id: String) -> int:
	return int(item(gs, item_id).price) / 2


static func sell(gs, inv_index: int) -> void:
	gs.gold += sell_price(gs, gs.inventory[inv_index])
	gs.inventory.remove_at(inv_index)
