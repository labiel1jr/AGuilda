class_name Expedition
## Mapa de expedição (v0.8): a missão vira camadas de nós com bifurcações.
## O estado vive em gs.expedition; o líder escolhe o próximo nó, o nó se resolve
## (eventos com teste d20 + modificador do herói mais apto) e, no chefe, o
## despacho é calculado com o modificador da rota (preparação − desgaste − fome).

const START := [-1, 0]


static func data(gs) -> Dictionary:
	return gs.route_data


## Cria a expedição e o grafo. Não mexe nos heróis ainda.
static func start(gs, mission: Dictionary, party: Array, prepared: Dictionary) -> Dictionary:
	var rd := data(gs)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([gs.day, mission.id, party])
	var n_layers: int = int(rd.layers.get(mission.risk, 3))
	var weights: Dictionary = rd.weights.get(mission.get("biome", ""), rd.weights.default).duplicate()
	weights.merge(mission.get("route", {}).get("weights", {}), true)

	var layers := []
	for l in n_layers:
		var count := rng.randi_range(2, 3)
		var pool := weights.duplicate()
		if l >= n_layers - 1:
			pool.erase("atalho")   # atalho na última camada não pularia nada
		var layer := []
		for i in count:
			var t := _weighted_pick(rng, pool)
			pool.erase(t)          # tipos diferentes na mesma camada
			if t == "atalho" or pool.is_empty():
				pool.erase("atalho")
			layer.append({"type": t, "next": [], "event": "", "done": false})
		layers.append(layer)
	# guarda do alvo: missões de risco médio para cima têm um miniboss na última camada
	if mission.risk != "baixo" and not layers[n_layers - 1].any(func(n): return n.type == "miniboss"):
		layers[n_layers - 1][rng.randi_range(0, layers[n_layers - 1].size() - 1)].type = "miniboss"
	layers.append([{"type": "chefe", "next": [], "event": "", "done": false}])

	# ligações: cada nó aponta para 1–2 nós da camada seguinte (atalho: duas adiante)
	for l in n_layers:
		var layer: Array = layers[l]
		for i in layer.size():
			var node: Dictionary = layer[i]
			var tl := l + (2 if node.type == "atalho" else 1)
			var nt: int = layers[tl].size()
			var j := 0 if layer.size() == 1 else int(round(float(i) * (nt - 1) / (layer.size() - 1)))
			node.next = [j]
			if nt > 1 and rng.randf() < 0.5:
				var k := clampi(j + (1 if rng.randf() < 0.5 else -1), 0, nt - 1)
				if k != j:
					node.next.append(k)
		# todo nó da camada seguinte precisa de uma entrada
		if l + 1 < layers.size():
			for j in layers[l + 1].size():
				var has_in := false
				for node in layer:
					if node.type != "atalho" and node.next.has(j):
						has_in = true
				if not has_in:
					var best := -1
					for i in layer.size():
						if layer[i].type != "atalho" and (best < 0 or absi(i - j) < absi(best - j)):
							best = i
					layer[best].next.append(j)
	# eventos sorteados por nó
	for layer in layers:
		for node in layer:
			var evs: Array = rd.events.get(node.type, [])
			if not evs.is_empty():
				node.event = evs[rng.randi_range(0, evs.size() - 1)].id

	var exp := {
		"mission": mission.id, "party": party.duplicate(), "prepared": prepared.duplicate(),
		"layers": layers, "cur": START.duplicate(), "path": [START.duplicate()],
		"provisions": int(rd.provisions_start.get(mission.risk, 3)),
		"gold": 0, "items": [], "bonus": 0, "hunger": 0, "days": 0,
		"pending": "", "log": [],
	}
	gs.expedition = exp
	return exp


static func mission(gs) -> Dictionary:
	for m in gs.missions:
		if m.id == gs.expedition.mission:
			return m
	return {}


static func node_at(gs, pos: Array) -> Dictionary:
	if pos[0] < 0:
		return {}
	return gs.expedition.layers[pos[0]][pos[1]]


## Nós para onde o grupo pode ir agora: [[camada, índice], ...]
static func choices(gs) -> Array:
	var exp: Dictionary = gs.expedition
	if exp.pending != "":
		return []
	var cur: Array = exp.cur
	if cur[0] < 0:
		var out := []
		for i in exp.layers[0].size():
			out.append([0, i])
		return out
	var node := node_at(gs, cur)
	if node.type == "chefe":
		return []
	var tl: int = cur[0] + (2 if node.type == "atalho" else 1)
	return node.next.map(func(j): return [tl, j])


static func at_boss(gs) -> bool:
	return node_at(gs, gs.expedition.cur).get("type", "") == "chefe"


## Anda até o nó: gasta comida e prepara o que acontece ali.
## Devolve {lines, event?, shop?, boss?}
static func enter(gs, pos: Array) -> Dictionary:
	var exp: Dictionary = gs.expedition
	var rd := data(gs)
	exp.cur = pos.duplicate()
	exp.path.append(pos.duplicate())
	var node := node_at(gs, pos)
	node.done = true
	var out := {"lines": []}
	if exp.provisions > 0:
		exp.provisions -= 1
	else:
		exp.hunger += 1
		out.lines.append("Sem comida, o grupo segue com fome (−1 no score do alvo, +1 de estresse).")
		for id in exp.party:
			out.lines.append_array(Mind.add_stress(gs, id, 1, exp.party, exp.prepared))
	match node.type:
		"chefe":
			out.boss = true
			out.lines.append("O alvo está à vista.")
		"loja":
			out.shop = shop_stock(gs, pos)
			out.lines.append("Um mercador de estrada abre a carroça.")
		_:
			var ev := event_by_id(gs, node.type, node.event)
			if not ev.is_empty():
				exp.pending = ev.id
				out.event = ev
				out.caller = caller(gs, ev)
	exp.log.append_array(out.lines)
	return out


static func event_by_id(gs, type: String, id: String) -> Dictionary:
	for ev in data(gs).events.get(type, []):
		if ev.id == id:
			return ev
	return {}


## Quem chama pelo Mapa Mágico: o membro mais apto no primeiro teste do evento.
static func caller(gs, ev: Dictionary) -> String:
	for opt in ev.options:
		if opt.has("test"):
			return best_for(gs, opt.test.attr)
	var party: Array = gs.expedition.party
	return party[gs.rng.randi_range(0, party.size() - 1)]


static func best_for(gs, attr: String) -> String:
	var best := ""
	var val := -99
	for id in gs.expedition.party:
		var v: int = int(HeroRPG.effective_attrs(gs, id)[attr])
		if v > val:
			val = v
			best = id
	return best


static func modifier(gs, id: String, attr: String) -> int:
	return int(HeroRPG.effective_attrs(gs, id)[attr]) - 5


static func dc(gs, opt: Dictionary) -> int:
	var m := mission(gs)
	return int(data(gs).dc.get(m.risk, 11)) + int(opt.test.get("dc", 0))


## Texto curto do teste para o botão: "Destreza CD 11 · Lyssa +4".
static func test_hint(gs, opt: Dictionary) -> String:
	if not opt.has("test"):
		return ""
	var attr: String = opt.test.attr
	var id := best_for(gs, attr)
	return "%s CD %d · %s %+d" % [attr.capitalize(), dc(gs, opt), gs.heroes[id].name, modifier(gs, id, attr)]


## "" se a opção pode ser escolhida; senão, o motivo.
static func option_block(gs, opt: Dictionary) -> String:
	var req: Dictionary = opt.get("requires", {})
	if req.has("guild_gold") and gs.gold < int(req.guild_gold):
		return "Precisa de %d de ouro da guilda" % int(req.guild_gold)
	if req.has("gold") and gs.expedition.gold < int(req.gold):
		return "Precisa de %d de ouro na bolsa da rota" % int(req.gold)
	if req.has("provisions") and gs.expedition.provisions < int(req.provisions):
		return "Precisa de %d provisão(ões)" % int(req.provisions)
	return ""


## Resolve a opção do evento pendente. Devolve {lines, dice?}
static func choose(gs, opt: Dictionary) -> Dictionary:
	var exp: Dictionary = gs.expedition
	exp.pending = ""
	var out := {"lines": []}
	var hero := ""
	var branch: Dictionary = opt
	if opt.has("test"):
		var attr: String = opt.test.attr
		hero = best_for(gs, attr)
		var mod := modifier(gs, hero, attr)
		var roll: int = gs.rng.randi_range(1, 20)
		var target := dc(gs, opt)
		var ok: bool = roll == 20 or (roll != 1 and roll + mod >= target)
		out.dice = {"hero": hero, "attr": attr, "roll": roll, "mod": mod, "dc": target, "ok": ok}
		out.lines.append("🎲 %s rola %d %+d = %d contra CD %d — %s" % [gs.heroes[hero].name, roll, mod, roll + mod, target, "sucesso!" if ok else "falhou."])
		branch = opt.ok if ok else opt.fail
	else:
		var party: Array = exp.party
		hero = party[gs.rng.randi_range(0, party.size() - 1)]
	if branch.has("text"):
		out.lines.append(_fill(gs, branch.text, hero))
	out.lines.append_array(apply(gs, branch.get("fx", {}), hero))
	exp.log.append_array(out.lines)
	return out


## Aplica efeitos e devolve as linhas do que mudou.
static func apply(gs, fx: Dictionary, hero: String = "") -> Array:
	var exp: Dictionary = gs.expedition
	var lines := []
	var party: Array = exp.party
	if fx.has("gold"):
		var before: int = exp.gold
		exp.gold = maxi(0, exp.gold + int(fx.gold))
		if exp.gold != before:
			lines.append("Bolsa da rota: %+d de ouro." % (exp.gold - before))
	if fx.has("provisions"):
		var before: int = exp.provisions
		exp.provisions = maxi(0, exp.provisions + int(fx.provisions))
		if exp.provisions != before:
			lines.append("Provisões: %+d." % (exp.provisions - before))
	if fx.has("hp"):
		var v := int(fx.hp)
		for id in party:
			if v < 0:
				_hurt(gs, id, -v)
			else:
				_heal(gs, id, v)
		lines.append(("Todos recuperam %d PV." if v > 0 else "Todos perdem %d PV.") % absi(v))
	if fx.has("hp_one"):
		var id: String = hero if hero != "" else party[gs.rng.randi_range(0, party.size() - 1)]
		var v := int(fx.hp_one)
		if v < 0:
			_hurt(gs, id, -v)
		else:
			_heal(gs, id, v)
		lines.append("%s %s %d PV." % [gs.heroes[id].name, "recupera" if v > 0 else "perde", absi(v)])
	if fx.has("bonus"):
		exp.bonus += int(fx.bonus)
		lines.append("Preparação contra o alvo: %+d." % int(fx.bonus))
	if fx.has("item"):
		var it := String(fx.item)
		if it == "loot":
			var table: Array = gs.items_data.loot.get(mission(gs).risk, [])
			it = "" if table.is_empty() else table[gs.rng.randi_range(0, table.size() - 1)]
		if it != "":
			exp.items.append(it)
			lines.append("Encontrado: %s." % HeroRPG.item(gs, it).name)
	if fx.has("days"):
		exp.days = mini(2, exp.days + int(fx.days))
		lines.append("A volta vai atrasar (+%d dia)." % int(fx.days))
	if fx.has("guild_gold"):
		gs.gold = maxi(0, gs.gold + int(fx.guild_gold))
		lines.append("Ouro da guilda: %+d." % int(fx.guild_gold))
	if fx.has("stress"):
		var v := int(fx.stress)
		for id in party:
			if v > 0:
				lines.append_array(Mind.add_stress(gs, id, v, party, exp.prepared))
			else:
				Mind.relieve(gs, id, -v)
		lines.append(("Todos ganham %d de estresse." if v > 0 else "O estresse de todos cai %d.") % absi(v))
	if fx.has("stress_one"):
		var id: String = hero if hero != "" else party[gs.rng.randi_range(0, party.size() - 1)]
		var v := int(fx.stress_one)
		if v > 0:
			lines.append("%s ganha %d de estresse." % [gs.heroes[id].name, v])
			lines.append_array(Mind.add_stress(gs, id, v, party, exp.prepared))
		else:
			Mind.relieve(gs, id, -v)
			lines.append("O estresse de %s cai %d." % [gs.heroes[id].name, -v])
	if fx.has("lose_item"):
		lines.append_array(_lose_item(gs, String(fx.lose_item), hero))
	if fx.has("trait"):
		var id: String = hero if hero != "" else party[gs.rng.randi_range(0, party.size() - 1)]
		var t := String(fx.trait)
		lines.append_array(Mind.gain_trait(gs, id, t == "pos", "" if t in ["pos", "neg"] else t))
	if fx.has("affinity") and party.size() >= 2:
		var pairs := ScoreCalc.pairs_of(party)
		var pr: Array = pairs[gs.rng.randi_range(0, pairs.size() - 1)]
		gs.change_affinity(pr[0], pr[1], int(fx.affinity), int(fx.affinity))
		lines.append("%s e %s se aproximam." % [gs.heroes[pr[0]].name, gs.heroes[pr[1]].name])
	return lines


## Perde um item equipado no slot (preferindo o herói do evento). Item some de vez.
static func _lose_item(gs, slot: String, hero: String) -> Array:
	var party: Array = gs.expedition.party
	var order := party.duplicate()
	if hero != "":
		order.erase(hero)
		order.push_front(hero)
	for id in order:
		var h: Dictionary = gs.heroes[id]
		if h.equip.get(slot, "") != "":
			var it := HeroRPG.item(gs, h.equip[slot])
			h.equip[slot] = ""
			return ["%s perdeu %s." % [h.name, it.name]]
	return ["Por sorte, ninguém tinha nada a perder ali."]


## Estoque do mercador de estrada (fixo por nó).
static func shop_stock(gs, pos: Array) -> Array:
	var pool: Array = HeroRPG.shop_items(gs)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([gs.day, gs.expedition.mission, pos])
	var out := []
	while out.size() < 3 and out.size() < pool.size():
		var it = pool[rng.randi_range(0, pool.size() - 1)]
		if not out.has(it):
			out.append(it)
	return out


static func buy_provisions(gs) -> bool:
	var sp: Dictionary = data(gs).shop_provisions
	if gs.gold < int(sp.price):
		return false
	gs.gold -= int(sp.price)
	gs.expedition.provisions += int(sp.amount)
	return true


## Desgaste: membros com 1/3 do PV ou menos (até 2).
static func wear(gs) -> int:
	var n := 0
	for id in gs.expedition.party:
		var h: Dictionary = gs.heroes[id]
		if h.hp <= h.hp_max / 3:
			n += 1
	return mini(n, 2)


## Modificador que entra no score: preparação (até o teto) − desgaste − fome, nunca abaixo de −2.
static func route_mod(gs) -> int:
	var exp: Dictionary = gs.expedition
	return maxi(-2, clampi(exp.bonus, -1, int(data(gs).bonus_cap)) - wear(gs) - mini(exp.hunger, 2))


## Enfrenta o alvo: chama o despacho com o resultado da rota.
static func finish(gs) -> Dictionary:
	var exp: Dictionary = gs.expedition
	var route := {"mod": route_mod(gs), "bonus": exp.bonus, "wear": wear(gs), "hunger": exp.hunger,
		"gold": exp.gold, "items": exp.items.duplicate(), "days": exp.days}
	var res: Dictionary = gs.dispatch(mission(gs), exp.party, exp.prepared, route)
	res.route = route
	gs.expedition = {}
	return res


static func _hurt(gs, id: String, n: int) -> void:
	var h: Dictionary = gs.heroes[id]
	h.hp = maxi(1, h.hp - n)   # a rota fere, mas não derruba: quem cai é no alvo


static func _heal(gs, id: String, n: int) -> void:
	var h: Dictionary = gs.heroes[id]
	h.hp = mini(h.hp_max, h.hp + n)


static func _fill(gs, text: String, hero: String) -> String:
	var names := ", ".join(gs.expedition.party.map(func(id): return gs.heroes[id].name))
	return text.replace("{heroi}", gs.heroes[hero].name if hero != "" else "").replace("{party}", names)


static func _weighted_pick(rng: RandomNumberGenerator, w: Dictionary) -> String:
	var total := 0
	for k in w:
		total += int(w[k])
	var r := rng.randi_range(1, max(1, total))
	for k in w:
		r -= int(w[k])
		if r <= 0:
			return k
	return w.keys()[0]
