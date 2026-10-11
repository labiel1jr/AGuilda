extends SceneTree
## Percorre todas as telas sem interação para pegar erros de execução da UI.
## Godot_console.exe --headless --path . -s res://tests/ui_smoke.gd

func _initialize() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var gs = root.get_node("GameState")
	main.show_hub()   # abertura do capítulo
	await process_frame
	gs.begin_chapter()
	gs.gold = 999
	gs.reputation = 10
	main.show_upgrades()
	await process_frame
	for up in gs.upgrades_data.upgrades:
		gs.buy_upgrade(up.id)
	main.show_hub()
	await process_frame
	main.show_training()
	await process_frame
	main._train_pick = ["mira", "lyssa"]
	main.show_training()
	await process_frame
	# RPG: mercado, equipamento, magia na guilda, subida de nível
	main.show_market()
	await process_frame
	HeroRPG.buy(gs, "espada_longa")
	HeroRPG.buy(gs, "pocao_cura")
	main.show_equip(0)
	await process_frame
	gs.heroes.theo.hp = 3
	gs.pending_levelups.append({"id": "bram", "level": 3})
	main.show_levelup(gs.pending_levelups.pop_front())
	await process_frame
	gs.heroes.bram.spells_known.append("palavra_cura")
	main.show_cast("bram", "palavra_cura", 4)
	await process_frame
	gs.set_resting("lyssa", true)
	main.show_hub()
	await process_frame
	var m: Dictionary = gs.board()[0]
	main.show_party(m)
	main._toggle_hero(m, "vera")
	main._toggle_hero(m, "bram")
	main._toggle_hero(m, "mira")
	main.prepared = {"mira": "detectar_magia"}
	main._render_party(m)
	await process_frame
	main._on_dispatch(m)
	await process_frame
	# Mapa de expedição: escolhe caminhos, responde chamadas e enfrenta o alvo
	var map = main._map
	assert(map != null, "mapa não criado")
	map.speed = 200.0
	main._show_shop(["espada_longa", "pocao_cura"])
	await process_frame
	gs.heroes.vera.stress = 10
	gs.heroes.vera.condition = "paranoico"
	gs.heroes.vera.condition_kind = "aflicao"
	gs.heroes.vera.traits = ["sangue_frio", "medo_do_escuro"]
	main._show_call(gs.route_data.events.npc[0], "vera")
	await process_frame
	main._map_refresh()
	await process_frame
	var steps := 0
	while not Expedition.at_boss(gs) and steps < 12:
		if gs.expedition.pending != "":
			var node: Dictionary = Expedition.node_at(gs, gs.expedition.cur)
			main._on_call_choice(Expedition.event_by_id(gs, node.type, node.event).options[0])
		var ch: Array = Expedition.choices(gs)
		main._on_node_chosen(ch[0])
		for i in 6:
			await process_frame
		assert(not map.moving, "grupo não chegou ao nó")
		steps += 1
	assert(Expedition.at_boss(gs), "expedição não chegou ao alvo")
	# juice: dado e momentos de personagem
	var rolled := [false]
	main._roll_dice({"hero": "vera", "attr": "forca", "roll": 20, "mod": 3, "dc": 11, "ok": true}, func(): rolled[0] = true)
	await create_timer(4.0).timeout
	assert(rolled[0], "dado não terminou")
	main._on_face_boss()
	await process_frame
	await create_timer(1.6).timeout
	assert(main.last_result.has("route"))
	gs.pending_events.append({"a": "vera", "b": "bram", "threshold": 6})
	main._after_result()
	await process_frame
	main._on_label_chosen({"a": "vera", "b": "bram", "threshold": 6}, "Mentoria")
	gs.backstage_today = [{"event": gs.backstage_data.events[0], "a": "theo", "b": "bram", "done": false}]
	main.show_hub()
	await process_frame
	main.show_backstage(gs.backstage_today[0])
	await process_frame
	main._on_backstage_choice(gs.backstage_today[0], gs.backstage_data.events[0].choices[0])
	await process_frame
	assert(gs.backstage_today[0].done)
	gs.pending_moments.append({"type": "ruptura", "id": "bram", "kind": "aflicao", "name": "Paranoico", "text": "Quem de vocês contou a eles?"})
	gs.pending_moments.append({"type": "saida", "id": "lyssa", "text": "Lyssa deixou a guilda."})
	main._play_moments()
	await process_frame
	assert(main._moment_open, "momento não abriu")
	for k in 2:
		var btn: Button = main._moment_layer.find_children("*", "Button", true, false)[0]
		btn.pressed.emit()
		await process_frame
	assert(not main._moment_open and gs.pending_moments.is_empty(), "momentos não fecharam")
	Juice.set_reduce_motion(true)
	main.show_menu()
	await process_frame
	Juice.set_reduce_motion(false)
	main.show_relations()
	await process_frame
	gs.heroes.theo.condition = "corajoso"
	gs.heroes.theo.condition_kind = "virtude"
	gs.heroes.theo.traits = ["pele_dura"]
	for i in 6:
		main.show_book(i)
		await process_frame
	main._on_end_day()
	await process_frame
	gs.chapter_result = {"chapter": gs.current_chapter(), "success": true, "text": "x"}
	gs.chapter_state = "encerrado"
	main.show_hub()
	await process_frame
	gs.next_chapter()
	main.show_hub()
	await process_frame
	gs.chapter_state = "fim_do_ato"
	main.show_hub()
	await process_frame
	gs.next_act()
	main.show_hub()
	await process_frame
	gs.begin_chapter()
	gs.heroes.senna.morale = 0
	gs.ultimatums = [{"id": "senna", "done": false}]
	main.show_hub()
	await process_frame
	main.show_ultimatum(gs.ultimatums[0])
	await process_frame
	gs.chapter_state = "fim_de_jogo"
	main.show_hub()
	await process_frame
	main.show_epilogue()
	await process_frame
	# Título, menu, salvar e carregar
	main.show_title()
	await process_frame
	main.show_menu()
	await process_frame
	gs.save_game("3")
	main.show_load(false)
	await process_frame
	assert(gs.load_game("3"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(gs.save_path("3")))
	# PV e incapacitado
	gs.heroes.mira.hp = 0
	assert(gs.unavailable_reason("mira", m) == "Incapacitado")
	# decisão de arco
	gs.decisions_data = {"decisions": [{"id": "dt", "title": "Teste", "text": "Escolha.", "voices": {"vera": {"text": "Vamos.", "leans": "c1"}}, "choices": [{"id": "c1", "label": "Seguir", "text": "Seguimos."}]}]}
	var dpend := {"id": "dt", "party": ["vera", "bram"], "mission": ""}
	DecisionScreen.show_decision(main, dpend)
	await process_frame
	DecisionScreen.choose(main, dpend, gs.decisions_data.decisions[0].choices[0])
	await process_frame
	print("UI SMOKE OK")
	quit()


func _find(n: Node, script_name: String) -> Node:
	for c in n.get_children():
		if c.get_script() != null and String(c.get_script().resource_path).get_file().get_basename() == script_name.to_snake_case():
			return c
		var r := _find(c, script_name)
		if r != null:
			return r
	return null
