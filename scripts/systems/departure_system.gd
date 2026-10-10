class_name Departures
## Ultimato por moral baixa, promessas e saída de aventureiros; Irmandade "Até o Fim" (GDD §5.7).
## Funções estáticas sobre o estado (gs: GuildState, o autoload GameState).


static func open_ultimatums(gs: GuildState) -> Array:
	return gs.ultimatums.filter(func(u): return not u.done)


static func ultimatum_text(gs: GuildState, id: String, text: String) -> String:
	return text.replace("{a}", gs.heroes[id].name)


static func ultimatum_block_reason(gs: GuildState, choice: Dictionary) -> String:
	if gs.gold < int(choice.get("cost", 0)):
		return "Ouro insuficiente"
	return ""


static func resolve_ultimatum(gs: GuildState, u: Dictionary, choice: Dictionary) -> Array:
	var id: String = u.id
	var h: Dictionary = gs.heroes[id]
	var lines := [Departures.ultimatum_text(gs, id, choice.result)]
	u.done = true
	if choice.get("leave", false):
		lines.append_array(Departures.depart(gs, id))
		return lines
	gs.gold -= int(choice.get("cost", 0))
	h.morale = clampi(h.morale + int(choice.get("morale", 0)), 0, 10)
	if choice.get("rest", false):
		Missions.set_resting(gs, id, true)
	if choice.has("promise"):
		gs.promises[id] = gs.day + int(choice.promise) - 1
	return lines


## Ultimatos ignorados e promessas vencidas viram partida.
static func process_departures(gs: GuildState) -> Array:
	var lines := []
	for u in gs.ultimatums:
		if not u.done and gs.hero_order.has(u.id):
			lines.append("%s cansou de esperar uma resposta." % gs.heroes[u.id].name)
			lines.append_array(Departures.depart(gs, u.id))
	gs.ultimatums.clear()
	for id in gs.promises.keys():
		if gs.day >= int(gs.promises[id]) and gs.hero_order.has(id):
			lines.append("%s esperou a missão prometida. Ela não veio." % gs.heroes[id].name)
			lines.append_array(Departures.depart(gs, id))
	return lines


static func depart(gs: GuildState, id: String) -> Array:
	if not gs.hero_order.has(id):
		return []
	var h: Dictionary = gs.heroes[id]
	for slot in HeroRPG.SLOTS:
		HeroRPG.unequip(gs, id, slot)
	gs.hero_order.erase(id)
	gs.departed.append(id)
	gs.promises.erase(id)
	h.resting = false
	var lines := ["%s deixou a Guilda do Corvo Cinzento. O equipamento ficou no Baú." % h.name]
	gs.pending_moments.append({"type": "saida", "id": id, "text": lines[0]})
	# Irmandade — "Até o Fim" (GDD §5.5): o irmão de armas parte junto
	for other in gs.hero_order.duplicate():
		if Relations.bond_label(gs, id, other) == "Irmandade":
			lines.append("Até o Fim: %s não fica onde %s não está." % [gs.heroes[other].name, h.name])
			lines.append_array(Departures.depart(gs, other))
	return lines
