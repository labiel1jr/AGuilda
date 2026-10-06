extends SceneTree
## Teste headless das regras. Rodar:
## Godot_console.exe --headless --path . -s res://tests/sim_test.gd

var failures := 0


func _init() -> void:
	var gs = load("res://scripts/core/game_state.gd").new()
	gs.new_game(42)
	_check_calibration(gs)
	_check_rules(gs)
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


func _random_playthroughs(gs, n: int) -> void:
	var outcomes := {"limpo": 0, "custo": 0, "falha": 0}
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for run in n:
		gs.new_game(run)
		var guard := 0
		while not gs.is_over() and guard < 100:
			guard += 1
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
