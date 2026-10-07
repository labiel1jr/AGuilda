extends SceneTree
## Gera uma screenshot do Mapa Mágico por bioma em user://shots/mapa_<bioma>.png (precisa de janela).

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://shots"))
	var gs = root.get_node("GameState")
	gs.new_game(3)
	var heroes := [{"name": "Vera", "color": Color("#8a6fb0")}, {"name": "Bram", "color": Color("#d9823b")}, {"name": "Theo", "color": Color("#c9a227")}]
	var goal: Texture2D = load("res://art/enemies/lobo_alfa.png")
	for biome in ["floresta", "pantano", "montanha", "estrada", "cidade"]:
		var m: Dictionary = gs.missions.filter(func(x): return x.get("biome", "") == biome)[0]
		var exp: Dictionary = Expedition.start(gs, m, ["vera", "bram", "theo"], {})
		Expedition.enter(gs, Expedition.choices(gs)[0])
		exp.pending = ""
		var map = load("res://scripts/ui/magic_map.gd").new()
		map.size = Vector2(1280, 720)
		root.add_child(map)
		map.goal_texture = goal
		map.setup(m, heroes, 7, exp)
		map.reachable = Expedition.choices(gs)
		for i in 3:
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("user://shots/mapa_%s.png" % biome)
		map.queue_free()
		await process_frame
	quit()
