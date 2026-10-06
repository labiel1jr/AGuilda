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
				var res: Dictionary = gs.dispatch(m, party)
				outcomes[res.outcome] += 1
				for bs in gs.backstage_today:
					if not bs.done:
						var chs: Array = bs.event.choices
						gs.resolve_backstage(bs, chs[rng.randi_range(0, chs.size() - 1)])
				while not gs.pending_events.is_empty():
					var ev: Dictionary = gs.pending_events.pop_front()
					var labels: Array = gs.THRESHOLD_EVENTS[ev.threshold].labels
					gs.choose_bond_label(ev, labels[rng.randi_range(0, labels.size() - 1)])
			gs.end_day()
		_expect(guard < 100, "partida %d terminou" % run)
	print("Partidas aleatórias: ", outcomes)


func _expect(ok: bool, msg: String) -> void:
	if ok:
		print("  ok  ", msg)
	else:
		failures += 1
		print("  FALHA  ", msg)
