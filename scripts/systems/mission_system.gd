class_name Missions
## Missões e despacho: slots, mural, prazos, disponibilidade, requisitos e a resolução do despacho
## (score, fadiga, PV, moral, reputação, ouro, saque da rota, afinidade, flags) (GDD §5.1, §5.2, §5.6, §5.8).
## Funções estáticas sobre o estado (gs: GuildState, o autoload GameState).


static func slots(gs: GuildState) -> int:
	if gs.reputation >= 12:
		return 3
	if gs.reputation >= 5:
		return 2
	return 1


static func free_slots(gs: GuildState) -> int:
	return Missions.slots(gs) - gs.dispatched_today


static func expires_on(gs: GuildState, m: Dictionary) -> int:
	return m.day + m.deadline - 1


static func board(gs: GuildState) -> Array:
	var out := []
	for m in gs.missions:
		if m.status == "aberta" and m.day <= gs.day:
			out.append(m)
	return out


## Status exibido (Livro e elenco).
static func hero_status(gs: GuildState, id: String) -> String:
	var h: Dictionary = gs.heroes[id]
	if h.busy:
		return "Em missão"
	if h.hp <= 0:
		return "Incapacitado"
	if h.fatigue >= 2:
		return "Exausto"
	if h.hp < h.hp_max:
		return "Ferido"
	if h.get("condition_kind", "") == "aflicao":
		return "Aflito"
	return GuildState.FATIGUE_NAMES[h.fatigue]


## "" se pode ir; senão, o motivo.
static func unavailable_reason(gs: GuildState, id: String, mission: Dictionary) -> String:
	var h: Dictionary = gs.heroes[id]
	if h.busy:
		return "Em missão"
	if h.resting:
		return "Descansando"
	if h.hp <= 0:
		return "Incapacitado"
	if h.fatigue >= 2:
		return "Exausto"
	if h.morale <= 1 and not gs.promises.has(id):
		return "Recusa (moral baixa)"
	for tag in mission.get("tags", []):
		if tag.type == "forbid_hero" and tag.hero == id:
			return "Proibido nesta missão"
	return ""


## Requisitos de composição não atendidos.
static func unmet_tags(gs: GuildState, mission: Dictionary, party: Array) -> Array:
	var out := []
	for tag in mission.get("tags", []):
		if tag.type == "requires_attr":
			var ok := false
			for id in party:
				if gs.heroes[id].attrs[tag.attr] >= int(tag.min):
					ok = true
			if not ok:
				out.append(tag.text)
		elif tag.type == "requires_hero" and not party.has(tag.hero):
			out.append(tag.text)
		elif tag.type == "min_party" and party.size() < int(tag.min):
			out.append(tag.text)
	return out


## Descanso (dia inteiro): recupera fadiga, PV, magia e moral no fim do dia.
static func set_resting(gs: GuildState, id: String, on: bool) -> void:
	var h: Dictionary = gs.heroes[id]
	if not h.busy:
		h.resting = on


## prepared: {id_do_herói: id_da_magia} para os conjuradores da party.
## route: resultado do mapa de expedição {mod, gold, items, days} (vazio = despacho direto).
static func dispatch(gs: GuildState, mission: Dictionary, party: Array, prepared: Dictionary = {}, route: Dictionary = {}) -> Dictionary:
	var prep := {}
	for id in prepared:
		if party.has(id) and prepared[id] != "" and gs.heroes[id].slots > 0 and gs.heroes[id].spells_known.has(prepared[id]):
			prep[id] = prepared[id]
	var luck := gs.rng.randi_range(-2, 2)
	var sc := ScoreCalc.compute(gs, mission, party, luck, prep, int(route.get("mod", 0)))
	var rpg_lines := HeroRPG.on_dispatch(gs, party, prep)
	HeroRPG.consume_on_dispatch(gs, party)
	var result := ScoreCalc.outcome(sc.total, mission.risk)
	var actions: Array = sc.actions
	var action_names := actions.map(func(x): return x.action)
	var lines := []
	var aff_changes := []

	if result == "falha" and action_names.has("Sincronia Perfeita"):
		result = "custo"
		lines.append("Sincronia Perfeita: a dupla transformou o desastre em vitória amarga.")

	var names := ", ".join(party.map(func(id): return gs.heroes[id].name))
	lines.push_front(String(mission.texts[result]).replace("{party}", names))
	if sc.hidden != 0:
		lines.append(mission.hidden.text)
	for act in actions:
		match act.action:
			"Impulso do Mentor":
				lines.append("%s e %s: Impulso do Mentor — o mais novo lutou acima do próprio nível." % [gs.heroes[act.a].name, gs.heroes[act.b].name])
			"Esforço Extra":
				lines.append("%s e %s se esforçaram além da conta um pelo outro." % [gs.heroes[act.a].name, gs.heroes[act.b].name])
			"Competição":
				lines.append("%s e %s disputaram quem resolvia primeiro." % [gs.heroes[act.a].name, gs.heroes[act.b].name])

	# Fadiga
	var protected := ""
	if result == "falha":
		for act in actions:
			if act.action == "Cobertura Mútua":
				protected = act.b
				lines.append("Cobertura Mútua: %s absorveu o pior para que %s voltasse ileso." % [gs.heroes[act.a].name, gs.heroes[act.b].name])
	for id in party:
		var h: Dictionary = gs.heroes[id]
		h.busy = true
		if id == protected:
			continue
		var fat := 2 if (mission.risk in ["alto", "lendario"] or h.fatigue >= 1) else 1
		if HeroRPG.member_value(gs, id, party, prep, "fatigue_resist") > 0:
			fat -= 1
		h.fatigue = max(h.fatigue, fat)
	for act in actions:
		if act.action == "Esforço Extra":
			gs.heroes[act.a].fatigue = 2
			gs.heroes[act.b].fatigue = 2

	# Dano (PV): custo fere um membro; falha fere todos (exceto o protegido)
	var hurt := []
	if result == "custo":
		hurt.append(party[gs.rng.randi_range(0, party.size() - 1)])
	elif result == "falha":
		hurt = party.filter(func(id): return id != protected)
	var dmg: int = {"baixo": 1, "medio": 2, "alto": 3, "lendario": 4}[mission.risk]
	for id in hurt:
		var taken: int = max(0, dmg - HeroRPG.member_value(gs, id, party, prep, "damage_reduction"))
		gs.heroes[id].hp = max(0, gs.heroes[id].hp - taken)
		if taken > 0:
			lines.append("%s voltou ferido (−%d PV)." % [gs.heroes[id].name, taken])
		else:
			lines.append("%s levou um golpe, mas a proteção segurou." % gs.heroes[id].name)

	# Moral e reputação
	var morale_delta: int = {"limpo": 1, "custo": 0, "falha": -1}[result]
	for id in party:
		var h: Dictionary = gs.heroes[id]
		var dm := morale_delta
		if party.size() == 1 and result != "limpo":
			dm -= 1
		h.morale = clampi(h.morale + dm, 0, 10)
		h.history.append({"day": gs.day, "mission": mission.name, "result": result})
		h.last_dispatch = gs.day
	gs.reputation = max(0, gs.reputation + {"limpo": 2, "custo": 1, "falha": -1}[result])
	var earned: int = {"limpo": Economy.mission_reward(gs, mission), "custo": Economy.mission_reward(gs, mission) / 2, "falha": 0}[result]
	gs.gold += earned
	if earned > 0:
		lines.append("A guilda recebe %d de ouro." % earned)
	# Saque da rota: inteiro no sucesso, metade no custo; na falha fica pelo caminho
	if not route.is_empty():
		var rg: int = {"limpo": int(route.gold), "custo": int(route.gold) / 2, "falha": 0}[result]
		gs.gold += rg
		if rg > 0:
			lines.append("Saque da rota: %d de ouro." % rg)
		if result == "falha":
			if int(route.gold) > 0 or not route.items.is_empty():
				lines.append("Na fuga, o saque da rota ficou para trás.")
		else:
			for it in route.items:
				gs.inventory.append(it)
				lines.append("Saque da rota: %s vai para o Baú." % HeroRPG.item(gs, it).name)
		if int(route.days) > 0:
			for id in party:
				gs.heroes[id].away_until = gs.day + int(route.days)
			lines.append("A viagem atrasou: o grupo fica fora da guilda por mais %d dia(s)." % int(route.days))

	for pr in ScoreCalc.pairs_of(party):
		var key := GuildState.pair_key(pr[0], pr[1])
		gs.last_together[key] = gs.day
		if not gs.pair_history.has(key):
			gs.pair_history[key] = []
		gs.pair_history[key].append({"day": gs.day, "mission": mission.name, "outcome": result})

	# Afinidade (GDD §5.4)
	var pair_delta: int = {"limpo": 1, "custo": 0, "falha": -1}[result]
	for pr in ScoreCalc.pairs_of(party):
		if pair_delta != 0:
			Relations.change_logged(gs, pr[0], pr[1], pair_delta, pair_delta, aff_changes)
	if result == "custo" and party.size() >= 2 and gs.rng.randf() < 0.4:
		var pairs := ScoreCalc.pairs_of(party)
		var pr: Array = pairs[gs.rng.randi_range(0, pairs.size() - 1)]
		lines.append("%s protegeu %s no pior momento." % [gs.heroes[pr[0]].name, gs.heroes[pr[1]].name])
		Relations.change_logged(gs, pr[0], pr[1], 2, 2, aff_changes)
	if result == "falha" and party.size() >= 2 and gs.rng.randf() < 0.4:
		var pairs := ScoreCalc.pairs_of(party)
		var pr: Array = pairs[gs.rng.randi_range(0, pairs.size() - 1)]
		lines.append("%s culpa %s pelo fracasso." % [gs.heroes[pr[0]].name, gs.heroes[pr[1]].name])
		Relations.change_logged(gs, pr[0], pr[1], -2, -1, aff_changes)

	var fx: Dictionary = mission.get("effects", {}).get(result, {})
	for hid in fx.get("morale", {}):
		if gs.heroes.has(hid):
			gs.heroes[hid].morale = clampi(gs.heroes[hid].morale + int(fx.morale[hid]), 0, 10)
	if fx.has("flag") and not gs.flags.has(fx.flag):
		gs.flags.append(fx.flag)
	if fx.has("text"):
		lines.append(fx.text)
	for id in party:
		gs.promises.erase(id)

	mission.status = "concluida"
	mission.result = {"outcome": result, "party": party.duplicate(), "day": gs.day}
	lines = rpg_lines + lines
	lines.append_array(HeroRPG.after_mission(gs, mission, party, prep, result))
	lines.append_array(Mind.after_mission(gs, mission, party, prep, result))
	gs.dispatched_today += 1
	return {"mission": mission, "party": party, "score": sc, "outcome": result, "lines": lines, "affinity": aff_changes, "prepared": prep}


## Narração do Mapa Mágico: uma linha por waypoint (GDD §5.9).
static func map_narration(gs: GuildState, res: Dictionary) -> Array:
	var m: Dictionary = res.mission
	var party: Array = res.party
	var names := ", ".join(party.map(func(id): return gs.heroes[id].name))
	var lider: String = gs.heroes[party[0]].name
	var lines := []
	lines.append(Missions._pick(gs, gs.narration.start))
	lines.append(Missions._pick(gs, gs.narration.biomes.get(m.get("biome", "estrada"), gs.narration.biomes.estrada)))
	var third: String = Missions._pick(gs, gs.narration.outcome[res.outcome])
	if res.score.hidden != 0:
		third = String(gs.narration.hidden).replace("{heroi}", gs.heroes[m.hidden.hero].name) + " " + third
	lines.append(third)
	return lines.map(func(l): return String(l).replace("{party}", names).replace("{lider}", lider))


static func _pick(gs: GuildState, arr: Array) -> String:
	return arr[gs.rng.randi_range(0, arr.size() - 1)]
