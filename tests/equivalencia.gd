extends SceneTree
## Partida roteirizada e determinística (semente fixa, escolhas fixas). Imprime um hash do estado
## a cada dia e no fim. Serve para provar que uma refatoração não mudou o comportamento:
## rode antes e depois e compare a saída.
## Godot_console.exe --headless --path . -s res://tests/equivalencia.gd

func _init() -> void:
	var gs = load("res://scripts/core/game_state.gd").new()
	for seed_value in [7, 42, 1234]:
		gs.new_game(seed_value)
		var guard := 0
		while not gs.is_over() and guard < 60:
			guard += 1
			if gs.chapter_state == "intro":
				gs.begin_chapter()
			if gs.chapter_state == "encerrado":
				gs.next_chapter()
				continue
			if gs.chapter_state == "fim_do_ato" and gs.has_next_act():
				gs.next_act()
				continue
			for u in gs.open_ultimatums():
				gs.resolve_ultimatum(u, gs.ultimatum_data.choices[2])
			for up in gs.upgrades_data.upgrades:
				gs.buy_upgrade(up.id)
			for bs in gs.backstage_today:
				if not bs.done:
					gs.resolve_backstage(bs, bs.event.choices[0])
			for m in gs.board():
				if gs.free_slots() <= 0:
					break
				var avail: Array = gs.hero_order.filter(func(id): return gs.unavailable_reason(id, m) == "")
				var party: Array = avail.slice(0, mini(3, avail.size()))
				if party.is_empty() or not gs.unmet_tags(m, party).is_empty():
					continue
				Expedition.start(gs, m, party, {})
				var steps := 0
				while not Expedition.at_boss(gs) and steps < 20:
					var out: Dictionary = Expedition.enter(gs, Expedition.choices(gs)[0])
					if out.has("event"):
						var ops: Array = out.event.options.filter(func(o): return Expedition.option_block(gs, o) == "")
						Expedition.choose(gs, ops[0] if not ops.is_empty() else out.event.options[0])
					steps += 1
				Expedition.finish(gs)
				while not gs.pending_events.is_empty():
					var ev: Dictionary = gs.pending_events.pop_front()
					gs.choose_bond_label(ev, gs.THRESHOLD_EVENTS[ev.threshold].labels[0])
				while not gs.pending_levelups.is_empty():
					var lv: Dictionary = gs.pending_levelups.pop_front()
					var op: Dictionary = HeroRPG.levelup_options(gs, lv)
					HeroRPG.apply_levelup(gs, lv, op.attrs[0] if not op.attrs.is_empty() else "", op.choices[0] if not op.choices.is_empty() else {})
			for id in gs.hero_order:
				gs.set_resting(id, gs.heroes[id].rest_request)
			var lines: Array = gs.end_day()
			print("seed %d dia %d  %s  %s" % [seed_value, gs.day, _hash(gs), str(lines.size())])
		print("FIM seed %d  %s  ep=%s" % [seed_value, _hash(gs), str(gs.epilogue().get("title", "")) if gs.is_over() else "-"])
	gs.free()
	quit()


func _hash(gs) -> String:
	var state := {}
	for k in gs.SAVE_KEYS:
		state[k] = gs.get(k)
	state["rng"] = gs.rng.state
	return var_to_str(state).md5_text()
