extends SceneTree
## Screenshots dos momentos de game juice em user://shots/juice_*.png (precisa de janela).

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://shots"))
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var gs = root.get_node("GameState")
	gs.new_game(5)
	gs.begin_chapter()
	main.moments_enabled = false
	main.show_hub()
	var m: Dictionary = gs.board()[0]
	main.show_party(m)
	main._toggle_hero(m, "vera")
	main._toggle_hero(m, "bram")
	main._on_dispatch(m)
	await create_timer(0.22).timeout
	await _shot("juice_selo")
	await create_timer(1.2).timeout
	main._roll_dice({"hero": "vera", "attr": "forca", "roll": 20, "mod": 4, "dc": 9, "ok": true}, func(): pass)
	await create_timer(0.95).timeout
	await _shot("juice_dado")
	await create_timer(1.5).timeout
	while not Expedition.at_boss(gs):
		if gs.expedition.pending != "":
			var nd: Dictionary = Expedition.node_at(gs, gs.expedition.cur)
			Expedition.choose(gs, Expedition.event_by_id(gs, nd.type, nd.event).options[0])
		Expedition.enter(gs, Expedition.choices(gs)[0])
	main._on_face_boss()
	await create_timer(0.5).timeout
	await _shot("juice_resultado_contando")
	await create_timer(1.5).timeout
	await _shot("juice_resultado")
	main.moments_enabled = true
	gs.pending_moments.append({"type": "ruptura", "id": "bram", "kind": "aflicao", "name": "Paranoico", "text": "Bram começa a desconfiar de todos. \"Quem de vocês contou a eles?\""})
	main._play_moments()
	await create_timer(1.5).timeout
	await _shot("juice_ruptura")
	quit()


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("user://shots/%s.png" % name)
