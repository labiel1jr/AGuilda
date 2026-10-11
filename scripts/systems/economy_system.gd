class_name Economy
## Ouro e melhorias da guilda (GDD §5.12).
## Funções estáticas sobre o estado (gs: GuildState, o autoload GameState).


static func has_upgrade(gs: GuildState, id: String) -> bool:
	return gs.upgrades_owned.has(id)


## Melhorias que o jogador enxerga: as comuns e as ocultas já reveladas por bastidores.
static func visible_upgrades(gs: GuildState) -> Array:
	return gs.upgrades_data.upgrades.filter(func(up): return not up.get("hidden", false) or gs.upgrades_revealed.has(up.id) or gs.upgrades_owned.has(up.id))


static func upgrade_block_reason(gs: GuildState, up: Dictionary) -> String:
	if Economy.has_upgrade(gs, up.id):
		return "Construído"
	if up.get("hidden", false) and not gs.upgrades_revealed.has(up.id):
		return "Ainda não descoberta"
	if gs.reputation < int(up.rep):
		return "Requer Reputação %d" % int(up.rep)
	if gs.gold < int(up.cost):
		return "Ouro insuficiente"
	return ""


static func buy_upgrade(gs: GuildState, id: String) -> bool:
	for up in gs.upgrades_data.upgrades:
		if up.id == id and Economy.upgrade_block_reason(gs, up) == "":
			gs.gold -= int(up.cost)
			gs.upgrades_owned.append(id)
			return true
	return false


static func mission_reward(gs: GuildState, m: Dictionary) -> int:
	var mult := Town.reward_mult(gs)
	for f in m.get("reward_flags", {}):   # recompensa negociada no arco (ex.: mc_bom_preco)
		if gs.flags.has(f):
			mult *= float(m.reward_flags[f])
	return int(round(int(m.get("reward", gs.upgrades_data.rewards.get(m.risk, 0))) * mult))
