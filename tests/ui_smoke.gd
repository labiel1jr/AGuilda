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
	var m: Dictionary = gs.board()[0]
	main.show_party(m)
	main._toggle_hero(m, "vera")
	main._toggle_hero(m, "bram")
	await process_frame
	main._on_dispatch(m)
	await process_frame
	# Mapa Mágico: acelera até o fim e abre o resultado
	var map = _find(main, "MagicMap")
	assert(map != null, "mapa não criado")
	map.speed = 200.0
	for i in 10:
		await process_frame
	assert(not map.running, "mapa não terminou")
	main.show_result(main.last_result)
	await process_frame
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
	main.show_relations()
	await process_frame
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
	# PV e incapacitado
	gs.heroes.mira.hp = 0
	assert(gs.unavailable_reason("mira", m) == "Incapacitado")
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
