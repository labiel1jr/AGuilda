class_name Backstage
## Eventos de bastidor: sorteio do dia por afinidade, capítulo e flag, e as escolhas do jogador (GDD §5.4, §5.12).
## Funções estáticas sobre o estado (gs: GuildState, o autoload GameState).


static func roll_backstage(gs: GuildState) -> void:
	gs.backstage_today.clear()
	var used := []
	var events: Array = gs.backstage_data.get("events", [])
	for _i in int(gs.backstage_data.get("per_day", 2)):
		var options := []   # [peso, evento, a, b]
		for ev in events:
			if ev.get("once", false) and gs.backstage_once.has(ev.id):
				continue
			for pr in Backstage._candidate_pairs(gs, ev):
				if used.has(pr[0]) or used.has(pr[1]):
					continue
				options.append([float(ev.get("weight", 1)), ev, pr[0], pr[1]])
		if options.is_empty():
			break
		var total := 0.0
		for o in options:
			total += o[0]
		var roll := gs.rng.randf() * total
		for o in options:
			roll -= o[0]
			if roll <= 0.0:
				gs.backstage_today.append({"event": o[1], "a": o[2], "b": o[3], "done": false})
				used.append(o[2])
				used.append(o[3])
				if o[1].get("once", false):
					gs.backstage_once.append(o[1].id)
				break


static func _candidate_pairs(gs: GuildState, ev: Dictionary) -> Array:
	var out := []
	var fixed: Array = ev.get("heroes", [null, null])
	for a in gs.hero_order:
		for b in gs.hero_order:
			if a == b:
				continue
			if fixed[0] != null and fixed[0] != a:
				continue
			if fixed[1] != null and fixed[1] != b:
				continue
			if fixed[0] == null and fixed[1] == null and a > b:
				continue   # par sem ordem: considera uma vez só
			if gs.heroes[a].hp <= 0 or gs.heroes[b].hp <= 0:
				continue
			var v := Relations.pair_value(gs, a, b)
			if ev.has("min") and v < int(ev.min):
				continue
			if ev.has("chapters") and not ev.chapters.has(Chapters.current_chapter(gs).id):
				continue
			if ev.has("requires_flag") and not gs.flags.has(ev.requires_flag):
				continue
			if ev.has("reveals") and (gs.upgrades_revealed.has(ev.reveals) or gs.upgrades_owned.has(ev.reveals)):
				continue   # a melhoria que a cena revelaria já é conhecida
			if ev.has("min_esteem") and gs.town_esteem < int(ev.min_esteem):
				continue
			if ev.has("max_esteem") and gs.town_esteem > int(ev.max_esteem):
				continue
			if ev.has("max") and v > int(ev.max):
				continue
			out.append([a, b])
	return out


static func backstage_text(gs: GuildState, bs: Dictionary, text: String) -> String:
	return text.replace("{a}", gs.heroes[bs.a].name).replace("{b}", gs.heroes[bs.b].name)


## Aplica a escolha e devolve as linhas de resultado.
static func resolve_backstage(gs: GuildState, bs: Dictionary, choice: Dictionary) -> Array:
	var a: String = bs.a
	var b: String = bs.b
	var lines := [Backstage.backstage_text(gs, bs, choice.get("result", ""))]
	var aff: Array = choice.get("aff", [0, 0])
	if int(aff[0]) != 0 or int(aff[1]) != 0:
		var before := Relations.pair_value(gs, a, b)
		Relations.change_affinity(gs, a, b, int(aff[0]), int(aff[1]))
		lines.append("%s ↔ %s: %s" % [gs.heroes[a].name, gs.heroes[b].name, Relations.describe_change(gs, before, Relations.pair_value(gs, a, b))])
	for who in choice.get("morale", {}):
		var id: String = a if who == "a" else b
		var d := int(choice.morale[who])
		gs.heroes[id].morale = clampi(gs.heroes[id].morale + d, 0, 10)
		lines.append("%s: moral %+d" % [gs.heroes[id].name, d])
	for who in choice.get("fatigue", {}):
		var id: String = a if who == "a" else b
		gs.heroes[id].fatigue = clampi(gs.heroes[id].fatigue + int(choice.fatigue[who]), 0, 2)
		lines.append("%s ficou %s." % [gs.heroes[id].name, GuildState.FATIGUE_NAMES[gs.heroes[id].fatigue].to_lower()])
	for who in choice.get("fame", {}):
		var l := Town.change_fame(gs, a if who == "a" else b, int(choice.fame[who]))
		if l != "":
			lines.append(l)
	if choice.has("esteem"):
		var l := Town.change_esteem(gs, int(choice.esteem))
		if l != "":
			lines.append(l)
	for who in choice.get("stress", {}):
		var id: String = a if who == "a" else b
		var n := int(choice.stress[who])
		if n > 0:
			lines.append_array(Mind.add_stress(gs, id, n))
		else:
			Mind.relieve(gs, id, -n)
		lines.append("%s: estresse %+d." % [gs.heroes[id].name, n])
	if choice.has("gold"):
		gs.gold = maxi(0, gs.gold + int(choice.gold))
		lines.append("Ouro da guilda %+d." % int(choice.gold))
	if choice.has("reveal_upgrade") and not gs.upgrades_revealed.has(choice.reveal_upgrade):
		gs.upgrades_revealed.append(choice.reveal_upgrade)
		for up in gs.upgrades_data.upgrades:
			if up.id == choice.reveal_upgrade:
				lines.append("✦ Nova melhoria disponível na Guilda: %s (%d ouro)." % [up.name, int(up.cost)])
	bs.done = true
	return lines


## "" se a escolha pode ser feita; senão, o motivo (ex.: custo em ouro).
static func choice_block(gs: GuildState, choice: Dictionary) -> String:
	if int(choice.get("gold", 0)) < 0 and gs.gold < -int(choice.gold):
		return "Precisa de %d de ouro" % -int(choice.gold)
	return ""
