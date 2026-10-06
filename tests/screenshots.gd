extends SceneTree
## Gera screenshots das telas principais em user://shots (precisa de janela, não roda headless).

func _initialize() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	var gs = root.get_node("GameState")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://shots"))
	await _shot("1_hub")
	var m: Dictionary = gs.board()[2]
	main.show_party(m)
	main._toggle_hero(m, "vera")
	main._toggle_hero(m, "bram")
	main._toggle_hero(m, "theo")
	await _shot("2_party")
	main._on_dispatch(m)
	for i in 160:
		await process_frame
	await _shot("6_mapa")
	main.show_result(main.last_result)
	await _shot("3_resultado")
	main.show_relations()
	await _shot("4_relacoes")
	main.show_book(5)
	await _shot("5_livro")
	main.show_book(2)
	await _shot("7_livro_mira")
	quit()

func _shot(name: String) -> void:
	for i in 3:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("user://shots/%s.png" % name)
