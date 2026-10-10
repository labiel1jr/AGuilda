class_name Economy
## Ouro e melhorias da guilda (GDD §5.12).
## Funções estáticas sobre o estado (gs: GuildState, o autoload GameState).


static func has_upgrade(gs: GuildState, id: String) -> bool:
	return gs.upgrades_owned.has(id)


static func upgrade_block_reason(gs: GuildState, up: Dictionary) -> String:
	if Economy.has_upgrade(gs, up.id):
		return "Construído"
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
	return int(m.get("reward", gs.upgrades_data.rewards.get(m.risk, 0)))
