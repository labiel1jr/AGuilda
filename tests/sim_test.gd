extends SceneTree
## Teste headless das regras. Rodar:
## Godot_console.exe --headless --path . -s res://tests/sim_test.gd

var failures := 0


func _init() -> void:
	var gs = load("res://scripts/core/game_state.gd").new()
	gs.new_game(42)
	_check_calibration(gs)
	_check_rules(gs)
	_check_neglect(gs)
	_check_backstage(gs)
	_check_chapters(gs)
	_check_upgrades(gs)
	_check_rpg(gs)
	_random_playthroughs(gs, 200)
	print("RESULTADO: %s (%d falha(s))" % ["OK" if failures == 0 else "FALHOU", failures])
	gs.free()
	quit(1 if failures > 0 else 0)


func _check_calibration(gs) -> void:
	# Tabela de calibragem do GDD §5.6 (Força + Carisma, sem sorte)
	var m := {"primary": "forca", "secondary": "carisma", "risk": "medio"}
	var cases := [
		[["vera"], 7.9], [["theo", "bram"], 9.3], [["vera", "bram"], 11.3],
		[["vera", "bram", "theo"], 11.8], [["theo", "lyssa"], 2.2],
		[["theo", "lyssa", "mira", "senna"], 6.2],
	]
	for c in cases:
		var got: float = ScoreCalc.compute(gs, m, c[0]).total
		_expect(absf(got - c[1]) < 0.06, "calibragem %s: esperado %.1f, obtido %.2f" % [c[0], c[1], got])


func _check_rules(gs) -> void:
	_expect(gs.pair_value("vera", "bram") == 4, "par Vera/Bram inicial = 4")
	# Assimetria: vale o menor
	gs.affinity.theo.vera = 7
	_expect(gs.pair_value("theo", "vera") == 3, "assimetria usa o menor valor")
	gs.affinity.theo.vera = 3
	# Limiar +6 gera evento e Mentoria ativa Impulso do Mentor
	gs.pending_events.clear()
	gs.change_affinity("vera", "bram", 2, 2)
	_expect(gs.pending_events.size() == 1 and gs.pending_events[0].threshold == 6, "evento de limiar +6")
	gs.choose_bond_label(gs.pending_events.pop_front(), "Mentoria")
	var acts: Array = gs.active_bond_actions(["vera", "bram"])
	_expect(acts.size() == 1 and acts[0].action == "Impulso do Mentor", "Impulso do Mentor ativo")
	var m := {"primary": "forca", "secondary": "carisma", "risk": "medio"}
	_expect(ScoreCalc.compute(gs, m, ["vera", "bram"]).total > 11.3 + 2.0, "Mentoria aumenta o score")
	# Cansado vale 60%
	gs.new_game(42)
	var full: float = ScoreCalc.compute(gs, m, ["vera"]).base
	gs.heroes.vera.fatigue = 1
	_expect(absf(ScoreCalc.compute(gs, m, ["vera"]).base - full * 0.6) < 0.01, "Cansado = 60%")
	gs.heroes.vera.fatigue = 2
	_expect(gs.unavailable_reason("vera", m) == "Exausto", "Exausto não pode ser selecionado")
	gs.new_game(42)


func _check_neglect(gs) -> void:
	gs.new_game(42)
	# Vera/Bram começam em +4 (piso). Sobe para +6 e fica 3 dias sem missão juntos.
	gs.change_affinity("vera", "bram", 2, 2)
	gs.pending_events.clear()
	for i in 3:
		gs.end_day()
	_expect(gs.pair_value("vera", "bram") == 5, "neglect: −1 após 3 dias separados (obtido %d)" % gs.pair_value("vera", "bram"))
	for i in 12:
		gs.end_day()
	_expect(gs.pair_value("vera", "bram") == 4, "neglect não passa do valor inicial (obtido %d)" % gs.pair_value("vera", "bram"))
	_expect(gs.pair_value("theo", "lyssa") == -3, "neglect não mexe em par negativo")
	_expect(gs.heroes.mira.morale < 6, "moral cai para quem fica sem missão")
	gs.new_game(42)


func _check_backstage(gs) -> void:
	var total := 0
	var ids := {}
	var bad := 0
	for sd in 50:
		gs.new_game(sd)
		for d in 6:
			for bs in gs.backstage_today:
				total += 1
				ids[bs.event.id] = true
				if bs.a == bs.b:
					bad += 1
			gs.end_day()
	_expect(total > 0 and bad == 0, "bastidores gerados com pares válidos (%d em 50 jogos)" % total)
	print("  eventos vistos: ", ids.keys())
	gs.new_game(1)
	var bs := {"event": {}, "a": "theo", "b": "lyssa", "done": false}
	gs.resolve_backstage(bs, {"result": "x", "aff": [0, -1], "morale": {"a": 2, "b": -1}})
	_expect(gs.heroes.theo.morale == 8 and gs.heroes.lyssa.morale == 5 and bs.done, "escolher um lado: +2 / −1 de moral")
	gs.new_game(42)


func _check_chapters(gs) -> void:
	gs.new_game(3)
	_expect(gs.chapter_state == "intro" and gs.current_chapter().id == "c1", "jogo começa na abertura do Capítulo 1")
	_expect(gs.board().size() == 3, "Capítulo 1 abre com 3 missões no dia 1")
	gs.begin_chapter()
	for i in 5:
		gs.end_day()
	_expect(gs.chapter_state == "encerrado" and not gs.chapter_result.success, "Capítulo 1 encerra no dia 5 sem objetivo cumprido")
	gs.end_day()
	_expect(gs.flags.is_empty(), "encerramento não se repete antes de confirmar")
	gs.next_chapter()
	_expect(gs.current_chapter().id == "c2" and gs.chapter_day() == 1, "Capítulo 2 começa no dia 1 dele")
	var intro: Array = gs.chapter_intro()
	_expect(String(intro[-1]).contains("observador"), "texto do Capítulo 2 reflete o fracasso no Capítulo 1")
	var c1_open := 0
	for m in gs.missions:
		if gs.chapters_data.chapters[0].missions.has(m.id) and m.status == "aberta":
			c1_open += 1
	_expect(c1_open == 0, "missões do Capítulo 1 não ficam abertas no Capítulo 2")
	var finale: Dictionary = {}
	for m in gs.missions:
		if m.id == "noite_corvo":
			finale = m
	_expect(gs.unmet_tags(finale, ["vera", "bram"]).size() == 1, "missão final exige 3 aventureiros")
	gs.begin_chapter()
	for i in 5:
		gs.end_day()
	gs.next_chapter()
	_expect(gs.is_over(), "fim do Ato 1 após o Capítulo 2")
	gs.new_game(42)


func _check_upgrades(gs) -> void:
	gs.new_game(42)
	_expect(not gs.affinity_visible() and gs.describe_aff(4) == "Se cobrem em campo", "sem Quadro, afinidade é só impressão")
	_expect(not gs.buy_upgrade("quadro"), "Quadro custa mais que o ouro inicial")
	gs.gold = 500
	gs.reputation = 10
	_expect(gs.buy_upgrade("quadro") and gs.affinity_visible(), "comprar o Quadro revela a afinidade")
	_expect(not gs.buy_upgrade("quadro"), "upgrade não é comprado duas vezes")
	gs.buy_upgrade("enfermaria")
	gs.heroes.mira.fatigue = 2
	gs.heroes.mira.hp = 1
	gs.end_day()
	_expect(gs.heroes.mira.fatigue == 0 and gs.heroes.mira.hp == 3, "Enfermaria acelera a recuperação (fadiga %d, PV %d)" % [gs.heroes.mira.fatigue, gs.heroes.mira.hp])
	gs.buy_upgrade("salao")
	_expect(gs.can_train(), "Salão permite treinar")
	gs.train_pair("vera", "bram")
	_expect(gs.pair_value("vera", "bram") == 5 and gs.heroes.vera.fatigue == 1 and not gs.can_train(), "treino: +1 afinidade, Cansados, 1 vez por dia")
	gs.end_day()
	_expect(gs.can_train(), "treino volta no dia seguinte")
	gs.new_game(42)


func _mission(gs, id: String) -> Dictionary:
	for m in gs.missions:
		if m.id == id:
			return m
	return {}


func _check_rpg(gs) -> void:
	gs.new_game(42)
	# XP e nível
	gs.pending_levelups.clear()
	HeroRPG.gain_xp(gs, "bram", 50)
	_expect(gs.heroes.bram.level == 2 and gs.heroes.bram.hp_max == 9 and gs.pending_levelups.size() == 1, "Bram sobe para o nível 2 com 50 XP (+2 PV máx.)")
	HeroRPG.apply_levelup(gs, gs.pending_levelups.pop_front(), "carisma", {})
	_expect(gs.heroes.bram.attrs.carisma == 8, "ponto de atributo aplicado")
	HeroRPG.gain_xp(gs, "bram", 75)
	var e3: Dictionary = gs.pending_levelups.pop_front()
	var o3: Dictionary = HeroRPG.levelup_options(gs, e3)
	_expect(e3.level == 3 and o3.choices.size() == 2 and o3.choices[0].kind == "spell", "nível 3 do Bardo oferece 2 magias")
	HeroRPG.apply_levelup(gs, e3, "carisma", o3.choices[0])
	_expect(gs.heroes.bram.spells_known.size() == 2 and HeroRPG.max_slots(gs, "bram") == 2, "magia aprendida e espaço extra no nível 3")
	gs.heroes.vera.xp = 0
	HeroRPG.gain_xp(gs, "vera", HeroRPG.xp_to_next(gs, 6))
	var o7: Dictionary = HeroRPG.levelup_options(gs, gs.pending_levelups.pop_front())
	_expect(o7.choices.size() == 2 and o7.choices[0].kind == "talent", "nível 7 da Guerreira oferece 2 talentos")

	# Equipamento
	gs.new_game(42)
	gs.gold = 500
	HeroRPG.buy(gs, "espada_longa")
	HeroRPG.buy(gs, "gibao_couro")
	_expect(gs.inventory.size() == 2 and gs.gold == 430, "mercado: compra vai para o Baú e desconta o ouro")
	HeroRPG.equip(gs, "theo", "arma", 0)
	_expect(HeroRPG.effective_attrs(gs, "theo").forca == 9 and gs.heroes.theo.attrs.forca == 8, "Espada Longa: +1 Força efetiva, base intacta")
	_expect(HeroRPG.equip_block_reason(gs, "mira", "armadura", "gibao_couro") != "", "Maga não usa armadura")
	_expect(HeroRPG.equip_block_reason(gs, "lyssa", "armadura", "gibao_couro") == "", "Ladina usa armadura leve")
	HeroRPG.unequip(gs, "theo", "arma")
	_expect(gs.inventory.has("espada_longa") and gs.heroes.theo.equip.arma == "", "remover devolve ao Baú")

	# Poderes com teto +3
	gs.new_game(42)
	gs.inventory = ["pergaminho_forca", "pergaminho_forca", "insignia_corvo"]
	HeroRPG.equip(gs, "theo", "consumivel1", 0)
	HeroRPG.equip(gs, "theo", "consumivel2", 0)
	HeroRPG.equip(gs, "theo", "acessorio", 0)
	var cv := _mission(gs, "caravana")
	_expect(HeroRPG.power_bonus(gs, cv, ["theo"], {}) == 3, "Poderes limitados a +3")

	# Magia preparada: revela o oculto e gasta espaço
	gs.new_game(42)
	_expect(not HeroRPG.reveals_hidden(gs, ["vera"], {}) and HeroRPG.reveals_hidden(gs, ["vera", "mira"], {"mira": "detectar_magia"}), "Detectar Magia revela o requisito oculto")
	var sc_with: Dictionary = ScoreCalc.compute(gs, _mission(gs, "febre"), ["mira"], null, {"mira": "detectar_magia"})
	var sc_without: Dictionary = ScoreCalc.compute(gs, _mission(gs, "febre"), ["mira"])
	_expect(sc_with.total - sc_without.total == 1.0, "magia de exploração soma +1 em Poderes")
	gs.dispatch(_mission(gs, "febre"), ["mira"], {"mira": "detectar_magia"})
	var mira_max := HeroRPG.max_slots(gs, "mira")
	_expect(mira_max == 2 and gs.heroes.mira.slots == 1, "conjurar gasta 1 dos 2 espaços (Maga nível 3)")

	# Descanso
	gs.heroes.bram.fatigue = 2
	gs.heroes.bram.hp = 2
	gs.set_resting("bram", true)
	_expect(gs.unavailable_reason("bram", cv) == "Descansando", "quem descansa não vai em missão")
	gs.end_day()
	_expect(gs.heroes.mira.slots == 1, "sem descanso, a magia não volta")
	_expect(gs.heroes.bram.fatigue == 0 and gs.heroes.bram.hp == 5 and not gs.heroes.bram.resting, "descanso: fadiga zerada e metade do PV")
	gs.set_resting("mira", true)
	gs.end_day()
	_expect(gs.heroes.mira.slots == mira_max, "descanso recupera os espaços de magia")

	# Pedido de descanso ignorado custa moral
	gs.new_game(42)
	gs.heroes.senna.fatigue = 2
	gs.end_day()
	gs.heroes.senna.fatigue = 2
	gs.heroes.senna.rest_request = true
	var m0: int = gs.heroes.senna.morale
	gs.end_day()
	_expect(gs.heroes.senna.morale == m0 - 1, "ignorar pedido de descanso: moral −1")

	# Redução de dano
	gs.new_game(42)
	gs.inventory = ["placas"]
	HeroRPG.equip(gs, "vera", "armadura", 0)
	_expect(HeroRPG.member_value(gs, "vera", ["vera", "bram"], {}, "damage_reduction") == 2 and HeroRPG.member_value(gs, "bram", ["vera", "bram"], {}, "damage_reduction") == 0, "armadura protege só quem veste")
	var rp: Dictionary = gs.dispatch(_mission(gs, "lobos"), ["bram", "mira"], {"mira": "escudo_arcano"})
	_expect(rp.prepared.is_empty(), "despacho ignora magia que a Maga não conhece")

	# Clérigo entra no Capítulo 2
	gs.new_game(42)
	_expect(not gs.hero_order.has("corin"), "Corin não está no Capítulo 1")
	gs.begin_chapter()
	for i in 5:
		gs.end_day()
	gs.next_chapter()
	_expect(gs.hero_order.has("corin") and gs.chapter_recruits() == ["corin"] and gs.days_apart("corin", "vera") == 0, "Corin entra no Capítulo 2 com pares novos")
	_expect(HeroRPG.hub_spells(gs, "corin") == ["cura"], "Corin cura na guilda")
	gs.heroes.vera.hp = 5
	HeroRPG.cast_hub(gs, "corin", "cura", "vera")
	_expect(gs.heroes.vera.hp == 9 and gs.heroes.corin.slots == HeroRPG.max_slots(gs, "corin") - 1, "Curar Ferimentos: +4 PV e gasta espaço")
	gs.new_game(42)


func _random_playthroughs(gs, n: int) -> void:
	var outcomes := {"limpo": 0, "custo": 0, "falha": 0}
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for run in n:
		gs.new_game(run)
		var guard := 0
		while not gs.is_over() and guard < 100:
			guard += 1
			if gs.chapter_state == "intro":
				gs.begin_chapter()
			if gs.chapter_state == "encerrado":
				gs.next_chapter()
				continue
			for up in gs.upgrades_data.upgrades:
				gs.buy_upgrade(up.id)
			for m in gs.board():
				if gs.free_slots() <= 0:
					break
				var avail: Array = gs.hero_order.filter(func(id): return gs.unavailable_reason(id, m) == "")
				avail.shuffle()
				var party: Array = avail.slice(0, rng.randi_range(1, mini(4, avail.size())))
				if party.is_empty() or not gs.unmet_tags(m, party).is_empty():
					continue
				var prep := {}
				for id in party:
					if HeroRPG.is_caster(gs, id) and gs.heroes[id].slots > 0:
						prep[id] = gs.heroes[id].spells_known[rng.randi_range(0, gs.heroes[id].spells_known.size() - 1)]
				var res: Dictionary = gs.dispatch(m, party, prep)
				outcomes[res.outcome] += 1
				for bs in gs.backstage_today:
					if not bs.done:
						var chs: Array = bs.event.choices
						gs.resolve_backstage(bs, chs[rng.randi_range(0, chs.size() - 1)])
				while not gs.pending_levelups.is_empty():
					var lv: Dictionary = gs.pending_levelups.pop_front()
					var op: Dictionary = HeroRPG.levelup_options(gs, lv)
					HeroRPG.apply_levelup(gs, lv, op.attrs[0] if not op.attrs.is_empty() else "", op.choices[0] if not op.choices.is_empty() else {})
				while not gs.inventory.is_empty():
					var who: String = gs.hero_order[rng.randi_range(0, gs.hero_order.size() - 1)]
					var it: Dictionary = HeroRPG.item(gs, gs.inventory[0])
					var slot: String = "consumivel1" if it.slot == "consumivel" else it.slot
					if not HeroRPG.equip(gs, who, slot, 0):
						HeroRPG.sell(gs, 0)
				for id in gs.hero_order:
					gs.set_resting(id, gs.heroes[id].rest_request)
				while not gs.pending_events.is_empty():
					var ev: Dictionary = gs.pending_events.pop_front()
					var labels: Array = gs.THRESHOLD_EVENTS[ev.threshold].labels
					gs.choose_bond_label(ev, labels[rng.randi_range(0, labels.size() - 1)])
			gs.end_day()
		_expect(guard < 100, "partida %d terminou" % run)
	print("Partidas aleatórias: ", outcomes)
	var lv := {}
	for id in gs.hero_order:
		lv[id] = gs.heroes[id].level
	print("  níveis ao fim da última partida: ", lv)


func _expect(ok: bool, msg: String) -> void:
	if ok:
		print("  ok  ", msg)
	else:
		failures += 1
		print("  FALHA  ", msg)
