class_name ResultStory
## Resultado contado em frases: olha o que pesou no score no momento do despacho (pares, Ações de
## Vínculo, destaque, cansaço, condições, poderes, rota, sorte) e escolhe os momentos mais fortes.
## Textos e imagens em data/result_story.json. Só leitura: não muda o estado nem usa o rng do jogo.


## Devolve [{type, text, heroes: [ids], image}] em ordem de importância.
static func build(gs: GuildState, mission: Dictionary, party: Array, sc: Dictionary, prepared: Dictionary, route: Dictionary, outcome: String) -> Array:
	var d: Dictionary = gs.result_story_data
	if d.is_empty():
		return []
	var cands := []   # [peso, type, heroes, extra]
	# pares
	for pr in ScoreCalc.pairs_of(party):
		var v := Relations.pair_value(gs, pr[0], pr[1])
		var mod: int = int(Relations.band(gs, v).mod)
		if mod >= 8:
			cands.append([mod * 1.1, "laco_lendario", pr, {}])
		elif mod >= 4:
			cands.append([float(mod), "sinergia", pr, {}])
		elif mod <= -2:
			cands.append([-mod * 1.3, "conflito", pr, {}])
	for act in sc.get("actions", []):
		cands.append([5.0, "acao_vinculo", [act.a, act.b], {"acao": act.action}])
	# destaque: quem tem o atributo principal mais alto (7+)
	var best := ""
	var best_v := 0
	for id in party:
		var v: int = int(HeroRPG.effective_attrs(gs, id)[mission.primary])
		if v > best_v:
			best_v = v
			best = id
	if best != "" and best_v >= 7:
		cands.append([2.0 + (best_v - 7) * 0.5, "destaque", [best], {"atributo": mission.primary}])
	for id in party:
		var h: Dictionary = gs.heroes[id]
		if int(h.fatigue) == 1:
			cands.append([2.2, "cansaco", [id], {}])
		var cond: Dictionary = Mind.condition_info(gs, h)
		if not cond.is_empty():
			var kind := "virtude" if h.condition_kind == "virtude" else "aflicao"
			cands.append([3.0, kind, [id], {"condicao": String(cond.name).to_lower()}])
	var povo := int(sc.get("povo", 0))
	if povo != 0:
		var famous := party.duplicate()
		famous.sort_custom(func(x, y): return int(gs.heroes[x].get("fame", 0)) > int(gs.heroes[y].get("fame", 0)))
		cands.append([2.0 + absi(povo), "povo" if povo > 0 else "povo_contra", [famous[0] if povo > 0 else famous[-1]], {}])
	if int(sc.get("powers", 0)) >= 2:
		cands.append([float(sc.powers), "poderes", [], {}])
	if not route.is_empty():
		if int(route.get("bonus", 0)) >= 1:
			cands.append([1.5 + int(route.bonus), "preparacao", [], {}])
		if int(route.get("hunger", 0)) >= 1:
			cands.append([1.5 + int(route.hunger), "fome", [], {}])
		if int(route.get("wear", 0)) >= 1:
			cands.append([1.5 + int(route.wear), "desgaste", [], {}])
	var luck = sc.get("luck", 0)
	if luck != null and int(luck) >= 2:
		cands.append([1.8, "sorte", [], {}])
	elif luck != null and int(luck) <= -2:
		cands.append([1.8, "azar", [], {}])
	if party.size() == 1 and outcome != "limpo":
		cands.append([1.6, "sozinho", party, {}])

	cands.sort_custom(func(a, b): return a[0] > b[0])
	var out := []
	var used_pairs := {}
	for c in cands:
		if out.size() >= int(d.get("max_beats", 3)):
			break
		var heroes: Array = c[2]
		if heroes.size() == 2:
			var k := GuildState.pair_key(heroes[0], heroes[1])
			if used_pairs.has(k):
				continue   # um momento por par
			used_pairs[k] = true
		var beat := _beat(gs, d, c[1], heroes, c[3], party, mission, outcome)
		if not beat.is_empty():
			out.append(beat)
	return out


static func _beat(gs: GuildState, d: Dictionary, type: String, heroes: Array, extra: Dictionary, party: Array, mission: Dictionary, outcome: String) -> Dictionary:
	var def: Dictionary = d.beats.get(type, {})
	if def.is_empty():
		return {}
	var image: String = def.get("image", "")
	var texts: Array = []
	# texto e imagem próprios do par têm prioridade
	if heroes.size() == 2:
		var pd: Dictionary = d.get("pairs", {}).get(GuildState.pair_key(heroes[0], heroes[1]), {}).get(type, {})
		if not pd.is_empty():
			texts = pd.get("texts_" + outcome, pd.get("texts", []))
			image = pd.get("image", image)
	if texts.is_empty() and type == "acao_vinculo":
		texts = def.get("por_acao", {}).get(extra.get("acao", ""), [])
	if texts.is_empty() and type == "destaque":
		texts = def.get("por_atributo", {}).get(extra.get("atributo", ""), [])
	if texts.is_empty():
		texts = def.get("texts_" + outcome, def.get("texts", []))
	if texts.is_empty():
		return {}
	# variação determinística (o mesmo despacho conta sempre a mesma história)
	var pick: String = texts[absi(hash([mission.id, gs.day, type, heroes])) % texts.size()]
	var names := ", ".join(party.map(func(id): return gs.heroes[id].name))
	var text := pick.replace("{party}", names)
	if heroes.size() >= 1:
		text = text.replace("{heroi}", gs.heroes[heroes[0]].name).replace("{a}", gs.heroes[heroes[0]].name)
	if heroes.size() >= 2:
		text = text.replace("{b}", gs.heroes[heroes[1]].name)
	for k in extra:
		text = text.replace("{%s}" % k, String(extra[k]))
	image = image.replace("{atributo}", String(extra.get("atributo", "")))
	return {"type": type, "text": text, "heroes": heroes.duplicate(), "image": image}
