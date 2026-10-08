class_name Mind
## Estresse, aflições, virtudes e traços (v0.9). Dados em data/traits.json.
## Estado no herói: stress (0..máx), condition ("" ou id), condition_kind ("aflicao"|"virtude"),
## condition_left (missões restantes da virtude), traits ([ids]).
## Os efeitos de traços e condições entram em HeroRPG.hero_effects.


static func data(gs) -> Dictionary:
	return gs.traits_data


## Garante os campos (heróis novos e saves antigos).
static func ensure(h: Dictionary) -> void:
	if not h.has("stress"):
		h.stress = 0
	if not h.has("condition"):
		h.condition = ""
	if not h.has("condition_kind"):
		h.condition_kind = ""
	if not h.has("condition_left"):
		h.condition_left = 0
	if not h.has("traits"):
		h.traits = []
	if not h.has("away_until"):
		h.away_until = 0


static func condition_info(gs, h: Dictionary) -> Dictionary:
	if h.get("condition", "") == "":
		return {}
	var pool: Dictionary = data(gs).afflictions if h.condition_kind == "aflicao" else data(gs).virtues
	return pool.get(h.condition, {})


static func trait_info(gs, tid: String) -> Dictionary:
	return data(gs).traits.get(tid, {})


## Efeitos permanentes vindos da mente: traços + condição atual.
static func effects(gs, h: Dictionary) -> Array:
	var out := []
	for tid in h.get("traits", []):
		out.append_array(trait_info(gs, tid).get("effects", []))
	out.append_array(condition_info(gs, h).get("effects", []))
	return out


## Termo Mente do score: efeitos "mind" e "biome" dos membros, limitado a ±mind_cap.
static func score_bonus(gs, mission: Dictionary, party: Array, prepared: Dictionary = {}) -> int:
	var total := 0
	for pe in HeroRPG.party_effects(gs, party, prepared):
		var e: Dictionary = pe.e
		if e.type == "mind":
			total += int(e.value)
		elif e.type == "biome" and e.biome == mission.get("biome", ""):
			total += int(e.value)
	var cap := int(data(gs).mind_cap)
	return clampi(total, -cap, cap)


## Soma estresse no herói (com resistência). Devolve as linhas do que aconteceu.
## party: grupo atual, para resistências que valem para todos.
static func add_stress(gs, id: String, n: int, party: Array = [], prepared: Dictionary = {}) -> Array:
	var h: Dictionary = gs.heroes[id]
	ensure(h)
	var lines := []
	if n <= 0:
		return lines
	var resist := HeroRPG.member_value(gs, id, party if not party.is_empty() else [id], prepared, "stress_resist")
	n = maxi(0, n - resist)
	if n == 0:
		return lines
	var mx := int(data(gs).stress_max)
	if h.stress >= mx:
		# já no limite: o corpo cobra
		h.hp = maxi(1, h.hp - 1)
		lines.append("%s está no limite: colapso nervoso (−1 PV)." % h.name)
		return lines
	h.stress = mini(mx, h.stress + n)
	if h.stress >= mx:
		lines.append_array(_breaking_point(gs, id))
	return lines


static func relieve(gs, id: String, n: int) -> void:
	var h: Dictionary = gs.heroes[id]
	ensure(h)
	h.stress = maxi(0, h.stress - n)


## Ponto de ruptura: Virtude ou Aflição (Darkest Dungeon).
static func _breaking_point(gs, id: String) -> Array:
	var h: Dictionary = gs.heroes[id]
	var d := data(gs)
	if h.condition_kind == "aflicao":
		return []
	var chance := float(d.virtue_chance) + float(d.virtue_per_res) * (int(HeroRPG.effective_attrs(gs, id).resistencia) - 5)
	var virtue: bool = gs.rng.randf() < chance
	var pool: Dictionary = d.virtues if virtue else d.afflictions
	var keys: Array = pool.keys()
	var cid: String = keys[gs.rng.randi_range(0, keys.size() - 1)]
	h.condition = cid
	h.condition_kind = "virtude" if virtue else "aflicao"
	var info: Dictionary = pool[cid]
	var lines := []
	if virtue:
		h.condition_left = int(d.virtue_missions)
		h.stress = int(d.virtue_stress)
		lines.append("✦ %s testa a própria vontade... e encontra força: VIRTUDE — %s." % [h.name, info.name])
	else:
		lines.append("✖ %s testa a própria vontade... e quebra: AFLIÇÃO — %s." % [h.name, info.name])
	lines.append(String(info.text).replace("{heroi}", h.name))
	return lines


## Ao fim de uma missão: estresse pelo resultado, virtudes se gastam, chance de traço.
static func after_mission(gs, mission: Dictionary, party: Array, prepared: Dictionary, result: String) -> Array:
	var d := data(gs)
	var lines := []
	var n := int(d.mission_stress[result]) + int(d.risk_stress.get(mission.risk, 0))
	for id in party:
		var h: Dictionary = gs.heroes[id]
		ensure(h)
		var had_virtue: bool = h.condition_kind == "virtude"
		lines.append_array(add_stress(gs, id, n, party, prepared))
		if had_virtue and h.condition_kind == "virtude":
			h.condition_left -= 1
			if h.condition_left <= 0:
				lines.append("%s volta ao normal (a virtude passou)." % h.name)
				_clear_condition(h)
		var tc := float(d.trait_chance.get(result, 0.0))
		if tc > 0.0 and gs.rng.randf() < tc:
			lines.append_array(gain_trait(gs, id, result == "limpo"))
	return lines


static func _clear_condition(h: Dictionary) -> void:
	h.condition = ""
	h.condition_kind = ""
	h.condition_left = 0


## Um dia na guilda: descanso tira aflição e muito estresse; ocioso alivia um pouco.
static func end_day(gs, id: String, rested: bool, idle: bool) -> Array:
	var h: Dictionary = gs.heroes[id]
	ensure(h)
	var d := data(gs)
	var lines := []
	if rested:
		relieve(gs, id, int(d.rest_relief))
		if h.condition_kind == "aflicao":
			lines.append("%s descansou e se livrou da aflição (%s)." % [h.name, condition_info(gs, h).name])
			_clear_condition(h)
	elif idle:
		relieve(gs, id, int(d.idle_relief))
	return lines


## Ganha um traço positivo ou negativo (ou o id dado). Devolve linhas.
static func gain_trait(gs, id: String, positive: bool, tid: String = "") -> Array:
	var h: Dictionary = gs.heroes[id]
	ensure(h)
	if h.traits.size() >= int(data(gs).max_traits):
		return []
	if tid == "":
		var pool := []
		for k in data(gs).traits:
			if bool(data(gs).traits[k].positive) == positive and not h.traits.has(k):
				pool.append(k)
		if pool.is_empty():
			return []
		tid = pool[gs.rng.randi_range(0, pool.size() - 1)]
	if h.traits.has(tid):
		return []
	h.traits.append(tid)
	var info := trait_info(gs, tid)
	return ["%s ganhou o traço %s: %s (%s)" % [h.name, "positivo" if info.positive else "negativo", info.name, info.desc]]


static func stress_label(gs, h: Dictionary) -> String:
	return "%d/%d" % [h.get("stress", 0), int(data(gs).stress_max)]
