extends SceneTree
## Screenshots do arco "A Marca nas Paredes" em user://shots (precisa de janela).

func _initialize() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	var gs = root.get_node("GameState")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://shots"))
	await process_frame
	main.moments_enabled = false
	gs.new_game(11)
	while gs.current_chapter().id != "c2":
		if gs.chapter_state == "intro":
			gs.begin_chapter()
		gs.end_day()
		if gs.chapter_state == "encerrado":
			gs.next_chapter()
		gs.ultimatums.clear()
		gs.promises.clear()
		for id in gs.hero_order:
			gs.heroes[id].morale = 6
	gs.begin_chapter()
	main.show_hub()
	await _shot("marca_hub")
	var m: Dictionary = gs.missions.filter(func(x): return x.id == "marca")[0]
	main.show_party(m)
	for id in ["vera", "bram", "senna"]:
		main._toggle_hero(m, id)
	main._on_dispatch(m)
	main._map.speed = 200.0
	for i in 20:
		await process_frame
	main._on_node_chosen(Expedition.choices(gs)[0])
	for i in 20:
		await process_frame
	await _shot("marca_negociacao")
	main._on_call_choice(Expedition.event_by_id(gs, "", "mc_negociacao").options[1])
	for i in 20:
		await process_frame
	await _shot("marca_caminhos")
	main._on_node_chosen(Expedition.choices(gs)[1])
	for i in 20:
		await process_frame
	await _shot("marca_figueira")
	main._on_call_choice(Expedition.event_by_id(gs, "", "mc_figueira").options[0])
	Expedition.enter(gs, Expedition.choices(gs)[0])
	main._on_face_boss()
	await _shot("marca_resultado")
	main._after_result()
	await _shot("marca_decisao")
	quit()


func _shot(name: String) -> void:
	for i in 3:
		await process_frame
	await create_timer(1.6).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("user://shots/%s.png" % name)
