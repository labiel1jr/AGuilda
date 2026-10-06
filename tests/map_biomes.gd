extends SceneTree
## Gera uma screenshot do Mapa Mágico por bioma em user://shots/mapa_<bioma>.png (precisa de janela).

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://shots"))
	var heroes := [{"name": "Vera", "color": Color("#8a6fb0")}, {"name": "Bram", "color": Color("#d9823b")}, {"name": "Theo", "color": Color("#c9a227")}]
	var goal: Texture2D = load("res://art/enemies/lobo_alfa.png")
	for biome in ["floresta", "pantano", "montanha", "estrada", "cidade"]:
		var map = load("res://scripts/ui/magic_map.gd").new()
		map.size = Vector2(1280, 720)
		root.add_child(map)
		map.goal_texture = goal
		map.setup({"biome": biome}, heroes, 7)
		map.running = false
		map.progress = 0.6
		map._reached = 2
		for i in 3:
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("user://shots/mapa_%s.png" % biome)
		map.queue_free()
		await process_frame
	quit()
