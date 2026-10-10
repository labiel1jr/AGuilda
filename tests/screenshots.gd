extends SceneTree
## Gera screenshots das telas principais em user://shots (precisa de janela, não roda headless).

func _initialize() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	var gs = root.get_node("GameState")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://shots"))
	await process_frame
	main.show_title()
	await _shot("18_titulo")
	main.moments_enabled = false
	main.show_hub()
	await _shot("10_capitulo")
	gs.begin_chapter()
	main.show_upgrades()
	await _shot("11_upgrades")
	gs.gold = 300
	HeroRPG.buy(gs, "espada_longa")
	HeroRPG.buy(gs, "cota_malha")
	HeroRPG.buy(gs, "pocao_cura")
	HeroRPG.buy(gs, "amuleto_coragem")
	HeroRPG.equip(gs, "vera", "arma", 0)
	HeroRPG.equip(gs, "vera", "armadura", 0)
	main.show_market()
	await _shot("12_mercado")
	main.show_equip(5)
	await _shot("13_equipamento")
	gs.heroes.bram.xp = 70
	gs.heroes.bram.level = 2
	gs.pending_levelups.append({"id": "bram", "level": 3})
	main.show_levelup(gs.pending_levelups.pop_front())
	await _shot("14_nivel")
	main.show_book(2)
	await _shot("15_livro_mira")
	gs.heroes.senna.rest_request = true
	gs.set_resting("lyssa", true)
	gs.gold = 30
	main.show_hub()
	await _shot("1_hub")
	var m: Dictionary = gs.board()[2]
	main.show_party(m)
	main._toggle_hero(m, "vera")
	main._toggle_hero(m, "bram")
	main._toggle_hero(m, "theo")
	await _shot("2_party")
	gs.heroes.vera.stress = 6
	gs.heroes.theo.stress = 10
	gs.heroes.theo.condition = "paranoico"
	gs.heroes.theo.condition_kind = "aflicao"
	gs.heroes.theo.traits = ["pele_dura", "medo_do_escuro"]
	main._on_dispatch(m)
	main._map.speed = 200.0
	for k in 2:
		if gs.expedition.pending != "":
			var nd: Dictionary = Expedition.node_at(gs, gs.expedition.cur)
			main._on_call_choice(Expedition.event_by_id(gs, nd.type, nd.event).options[0])
		main._on_node_chosen(Expedition.choices(gs)[0])
		for i in 8:
			await process_frame
	main._map.speed = 1.0
	for i in 30:
		await process_frame
	await _shot("6_mapa")
	while not Expedition.at_boss(gs):
		if gs.expedition.pending != "":
			var nd: Dictionary = Expedition.node_at(gs, gs.expedition.cur)
			main._on_call_choice(Expedition.event_by_id(gs, nd.type, nd.event).options[0])
		Expedition.enter(gs, Expedition.choices(gs)[0])
	main._on_face_boss()
	await _shot("3_resultado")
	gs.backstage_today = [{"event": gs.backstage_data.events[6], "a": "theo", "b": "lyssa", "done": false},
		{"event": gs.backstage_data.events[0], "a": "mira", "b": "bram", "done": false}]
	main.show_hub()
	await _shot("8_hub_bastidores")
	main.show_backstage(gs.backstage_today[0])
	await _shot("9_bastidor")
	gs.gold = 200
	gs.buy_upgrade("quadro")
	main.show_relations()
	await _shot("4_relacoes")
	main.show_book(5)
	await _shot("5_livro")
	main.show_book(2)
	await _shot("7_livro_mira")
	gs.heroes.senna.morale = 1
	gs.ultimatums = [{"id": "senna", "done": false}]
	main.show_ultimatum(gs.ultimatums[0])
	await _shot("16_ultimato")
	gs.flags.append("noite_vencida")
	gs.chapter_state = "fim_do_ato"
	gs.next_act()
	main.show_hub()
	await _shot("17_ato2")
	main.show_book(5)
	await _shot("5_livro")
	gs.flags = ["noite_vencida", "conselho_aliado", "corvo_derrotado", "irmao_salvo", "carta_lida"]
	gs.reputation = 18
	gs.departed = ["lyssa"]
	gs.hero_order.erase("lyssa")
	gs.bond_labels[gs.pair_key("vera", "bram")] = "Mentoria"
	gs.chapter_state = "fim_de_jogo"
	main.show_epilogue()
	await _shot("19_epilogo")
	quit()

func _shot(name: String) -> void:
	for i in 3:
		await process_frame
	await create_timer(1.6).timeout   # deixa as animações de entrada (juice) terminarem
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("user://shots/%s.png" % name)
