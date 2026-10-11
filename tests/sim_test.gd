extends SceneTree
## Teste headless das regras. Rodar:
## Godot_console.exe --headless --path . -s res://tests/sim_test.gd

var failures := 0


func _init() -> void:
	var gs = load("res://scripts/core/game_state.gd").new()
	gs.new_game(42)
	_check_calibration(gs)
	_check_rules(gs)
	_check_neglect(gs)
	_check_backstage(gs)
	_check_chapters(gs)
	_check_upgrades(gs)
	_check_rpg(gs)
	_check_act2(gs)
	_check_save(gs)
	_check_endings(gs)
	_check_expedition(gs)
	_check_mind(gs)
	_check_story(gs)
	_check_town(gs)
	_check_arcs(gs)
	_check_marca(gs)
	_random_playthroughs(gs, 150)
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


func _check_neglect(gs) -> void:
	gs.new_game(42)
	# Vera/Bram começam em +4 (piso). Sobe para +6 e fica 3 dias sem missão juntos.
	gs.change_affinity("vera", "bram", 2, 2)
	gs.pending_events.clear()
	for i in 3:
		gs.end_day()
	_expect(gs.pair_value("vera", "bram") == 5, "neglect: −1 após 3 dias separados (obtido %d)" % gs.pair_value("vera", "bram"))
	for i in 12:
		gs.end_day()
	_expect(gs.pair_value("vera", "bram") == 4, "neglect não passa do valor inicial (obtido %d)" % gs.pair_value("vera", "bram"))
	_expect(gs.pair_value("theo", "lyssa") == -3, "neglect não mexe em par negativo")
	_expect(gs.heroes.mira.morale < 6, "moral cai para quem fica sem missão")
	gs.new_game(42)


func _check_backstage(gs) -> void:
	var total := 0
	var ids := {}
	var bad := 0
	for sd in 50:
		gs.new_game(sd)
		for d in 6:
			for bs in gs.backstage_today:
				total += 1
				ids[bs.event.id] = true
				if bs.a == bs.b:
					bad += 1
			gs.end_day()
	_expect(total > 0 and bad == 0, "bastidores gerados com pares válidos (%d em 50 jogos)" % total)
	print("  eventos vistos: ", ids.keys())
	gs.new_game(1)
	var bs := {"event": {}, "a": "theo", "b": "lyssa", "done": false}
	gs.resolve_backstage(bs, {"result": "x", "aff": [0, -1], "morale": {"a": 2, "b": -1}})
	_expect(gs.heroes.theo.morale == 8 and gs.heroes.lyssa.morale == 5 and bs.done, "escolher um lado: +2 / −1 de moral")
	gs.new_game(42)


func _check_chapters(gs) -> void:
	gs.new_game(3)
	_expect(gs.chapter_state == "intro" and gs.current_chapter().id == "c1", "jogo começa na abertura do Capítulo 1")
	_expect(gs.board().size() == 3, "Capítulo 1 abre com 3 missões no dia 1")
	gs.begin_chapter()
	for i in 5:
		gs.end_day()
	_expect(gs.chapter_state == "encerrado" and not gs.chapter_result.success, "Capítulo 1 encerra no dia 5 sem objetivo cumprido")
	gs.end_day()
	_expect(gs.flags.is_empty(), "encerramento não se repete antes de confirmar")
	gs.next_chapter()
	_expect(gs.current_chapter().id == "c2" and gs.chapter_day() == 1, "Capítulo 2 começa no dia 1 dele")
	var intro: Array = gs.chapter_intro()
	_expect(String(intro[-1]).contains("observador"), "texto do Capítulo 2 reflete o fracasso no Capítulo 1")
	var c1_open := 0
	for m in gs.missions:
		if gs.chapters_data.chapters[0].missions.has(m.id) and m.status == "aberta":
			c1_open += 1
	_expect(c1_open == 0, "missões do Capítulo 1 não ficam abertas no Capítulo 2")
	var finale: Dictionary = {}
	for m in gs.missions:
		if m.id == "noite_corvo":
			finale = m
	_expect(gs.unmet_tags(finale, ["vera", "bram"]).size() == 1, "missão final exige 3 aventureiros")
	gs.begin_chapter()
	for i in 5:
		gs.end_day()
	gs.next_chapter()
	_expect(gs.chapter_state == "fim_do_ato" and gs.has_next_act() and not gs.is_over(), "fim do Ato 1 leva ao Ato 2")
	gs.next_act()
	_expect(gs.act.id == "ato2" and gs.current_chapter().id == "c3" and gs.chapter_state == "intro", "Ato 2 abre no Capítulo 3")
	gs.begin_chapter()
	for i in 6:
		gs.end_day()
	gs.next_chapter()
	gs.begin_chapter()
	for i in 6:
		gs.end_day()
	gs.next_chapter()
	_expect(gs.chapter_state == "fim_do_ato" and not gs.has_next_act(), "Capítulo 4 encerra o Ato 2")
	gs.next_act()
	_expect(gs.is_over(), "fim de jogo após o último ato")
	gs.new_game(42)


func _check_upgrades(gs) -> void:
	gs.new_game(42)
	_expect(not gs.affinity_visible() and gs.describe_aff(4) == "Se cobrem em campo", "sem Quadro, afinidade é só impressão")
	_expect(not gs.buy_upgrade("quadro"), "Quadro custa mais que o ouro inicial")
	gs.gold = 500
	gs.reputation = 10
	_expect(gs.buy_upgrade("quadro") and gs.affinity_visible(), "comprar o Quadro revela a afinidade")
	_expect(not gs.buy_upgrade("quadro"), "upgrade não é comprado duas vezes")
	gs.buy_upgrade("enfermaria")
	gs.heroes.mira.fatigue = 2
	gs.heroes.mira.hp = 1
	gs.end_day()
	_expect(gs.heroes.mira.fatigue == 0 and gs.heroes.mira.hp == 3, "Enfermaria acelera a recuperação (fadiga %d, PV %d)" % [gs.heroes.mira.fatigue, gs.heroes.mira.hp])
	gs.buy_upgrade("salao")
	_expect(gs.can_train(), "Salão permite treinar")
	gs.train_pair("vera", "bram")
	_expect(gs.pair_value("vera", "bram") == 5 and gs.heroes.vera.fatigue == 1 and not gs.can_train(), "treino: +1 afinidade, Cansados, 1 vez por dia")
	gs.end_day()
	_expect(gs.can_train(), "treino volta no dia seguinte")
	gs.new_game(42)


func _mission(gs, id: String) -> Dictionary:
	for m in gs.missions:
		if m.id == id:
			return m
	return {}


func _check_rpg(gs) -> void:
	gs.new_game(42)
	# XP e nível
	gs.pending_levelups.clear()
	HeroRPG.gain_xp(gs, "bram", 50)
	_expect(gs.heroes.bram.level == 2 and gs.heroes.bram.hp_max == 9 and gs.pending_levelups.size() == 1, "Bram sobe para o nível 2 com 50 XP (+2 PV máx.)")
	HeroRPG.apply_levelup(gs, gs.pending_levelups.pop_front(), "carisma", {})
	_expect(gs.heroes.bram.attrs.carisma == 8, "ponto de atributo aplicado")
	HeroRPG.gain_xp(gs, "bram", 75)
	var e3: Dictionary = gs.pending_levelups.pop_front()
	var o3: Dictionary = HeroRPG.levelup_options(gs, e3)
	_expect(e3.level == 3 and o3.choices.size() == 2 and o3.choices[0].kind == "spell", "nível 3 do Bardo oferece 2 magias")
	HeroRPG.apply_levelup(gs, e3, "carisma", o3.choices[0])
	_expect(gs.heroes.bram.spells_known.size() == 2 and HeroRPG.max_slots(gs, "bram") == 2, "magia aprendida e espaço extra no nível 3")
	gs.heroes.vera.xp = 0
	HeroRPG.gain_xp(gs, "vera", HeroRPG.xp_to_next(gs, 6))
	var o7: Dictionary = HeroRPG.levelup_options(gs, gs.pending_levelups.pop_front())
	_expect(o7.choices.size() == 2 and o7.choices[0].kind == "talent", "nível 7 da Guerreira oferece 2 talentos")

	# Equipamento
	gs.new_game(42)
	gs.gold = 500
	HeroRPG.buy(gs, "espada_longa")
	HeroRPG.buy(gs, "gibao_couro")
	_expect(gs.inventory.size() == 2 and gs.gold == 430, "mercado: compra vai para o Baú e desconta o ouro")
	HeroRPG.equip(gs, "theo", "arma", 0)
	_expect(HeroRPG.effective_attrs(gs, "theo").forca == 9 and gs.heroes.theo.attrs.forca == 8, "Espada Longa: +1 Força efetiva, base intacta")
	_expect(HeroRPG.equip_block_reason(gs, "mira", "armadura", "gibao_couro") != "", "Maga não usa armadura")
	_expect(HeroRPG.equip_block_reason(gs, "lyssa", "armadura", "gibao_couro") == "", "Ladina usa armadura leve")
	HeroRPG.unequip(gs, "theo", "arma")
	_expect(gs.inventory.has("espada_longa") and gs.heroes.theo.equip.arma == "", "remover devolve ao Baú")

	# Poderes com teto +3
	gs.new_game(42)
	gs.inventory = ["pergaminho_forca", "pergaminho_forca", "insignia_corvo"]
	HeroRPG.equip(gs, "theo", "consumivel1", 0)
	HeroRPG.equip(gs, "theo", "consumivel2", 0)
	HeroRPG.equip(gs, "theo", "acessorio", 0)
	var cv := _mission(gs, "caravana")
	_expect(HeroRPG.power_bonus(gs, cv, ["theo"], {}) == 3, "Poderes limitados a +3")

	# Magia preparada: revela o oculto e gasta espaço
	gs.new_game(42)
	_expect(not HeroRPG.reveals_hidden(gs, ["vera"], {}) and HeroRPG.reveals_hidden(gs, ["vera", "mira"], {"mira": "detectar_magia"}), "Detectar Magia revela o requisito oculto")
	var sc_with: Dictionary = ScoreCalc.compute(gs, _mission(gs, "febre"), ["mira"], null, {"mira": "detectar_magia"})
	var sc_without: Dictionary = ScoreCalc.compute(gs, _mission(gs, "febre"), ["mira"])
	_expect(sc_with.total - sc_without.total == 1.0, "magia de exploração soma +1 em Poderes")
	gs.dispatch(_mission(gs, "febre"), ["mira"], {"mira": "detectar_magia"})
	var mira_max := HeroRPG.max_slots(gs, "mira")
	_expect(mira_max == 2 and gs.heroes.mira.slots == 1, "conjurar gasta 1 dos 2 espaços (Maga nível 3)")

	# Descanso
	gs.heroes.bram.fatigue = 2
	gs.heroes.bram.hp = 2
	gs.set_resting("bram", true)
	_expect(gs.unavailable_reason("bram", cv) == "Descansando", "quem descansa não vai em missão")
	gs.end_day()
	_expect(gs.heroes.mira.slots == 1, "sem descanso, a magia não volta")
	_expect(gs.heroes.bram.fatigue == 0 and gs.heroes.bram.hp == 5 and not gs.heroes.bram.resting, "descanso: fadiga zerada e metade do PV")
	gs.set_resting("mira", true)
	gs.end_day()
	_expect(gs.heroes.mira.slots == mira_max, "descanso recupera os espaços de magia")

	# Pedido de descanso ignorado custa moral
	gs.new_game(42)
	gs.heroes.senna.fatigue = 2
	gs.end_day()
	gs.heroes.senna.fatigue = 2
	gs.heroes.senna.rest_request = true
	var m0: int = gs.heroes.senna.morale
	gs.end_day()
	_expect(gs.heroes.senna.morale == m0 - 1, "ignorar pedido de descanso: moral −1")

	# Redução de dano
	gs.new_game(42)
	gs.inventory = ["placas"]
	HeroRPG.equip(gs, "vera", "armadura", 0)
	_expect(HeroRPG.member_value(gs, "vera", ["vera", "bram"], {}, "damage_reduction") == 2 and HeroRPG.member_value(gs, "bram", ["vera", "bram"], {}, "damage_reduction") == 0, "armadura protege só quem veste")
	var rp: Dictionary = gs.dispatch(_mission(gs, "lobos"), ["bram", "mira"], {"mira": "escudo_arcano"})
	_expect(rp.prepared.is_empty(), "despacho ignora magia que a Maga não conhece")

	# Clérigo entra no Capítulo 2
	gs.new_game(42)
	_expect(not gs.hero_order.has("corin"), "Corin não está no Capítulo 1")
	gs.begin_chapter()
	for i in 5:
		gs.end_day()
	gs.next_chapter()
	_expect(gs.hero_order.has("corin") and gs.chapter_recruits() == ["corin"] and gs.days_apart("corin", "vera") == 0, "Corin entra no Capítulo 2 com pares novos")
	_expect(HeroRPG.hub_spells(gs, "corin") == ["cura"], "Corin cura na guilda")
	gs.heroes.vera.hp = 5
	HeroRPG.cast_hub(gs, "corin", "cura", "vera")
	_expect(gs.heroes.vera.hp == 9 and gs.heroes.corin.slots == HeroRPG.max_slots(gs, "corin") - 1, "Curar Ferimentos: +4 PV e gasta espaço")
	gs.new_game(42)


func _to_chapter(gs, cid: String) -> void:
	while gs.current_chapter().id != cid:
		if gs.chapter_state == "intro":
			gs.begin_chapter()
		gs.end_day()
		if gs.chapter_state == "encerrado":
			gs.next_chapter()
		if gs.chapter_state == "fim_do_ato":
			gs.next_act()
		gs.ultimatums.clear()
		gs.promises.clear()
		for id in gs.hero_order:
			gs.heroes[id].morale = 6


func _check_act2(gs) -> void:
	# Missão pessoal
	gs.new_game(42)
	_to_chapter(gs, "c3")
	gs.begin_chapter()
	var irmao := _mission(gs, "irmao_senna")
	_expect(gs.unmet_tags(irmao, ["vera"]).size() == 1 and gs.unmet_tags(irmao, ["senna"]).is_empty(), "missão pessoal exige o herói dela")
	# Senna "treinada" para a missão de Carisma: o teste é sobre o efeito, não sobre a sorte
	gs.heroes.senna.attrs.carisma = 10
	gs.heroes.senna.attrs.destreza = 10
	var res: Dictionary = {}
	for tries in 30:
		irmao.status = "aberta"
		gs.heroes.senna.busy = false
		gs.heroes.senna.morale = 5
		gs.flags.erase("irmao_salvo")
		res = gs.dispatch(irmao, ["senna"])
		if res.outcome == "limpo":
			break
	_expect(res.outcome == "limpo" and gs.flags.has("irmao_salvo") and gs.heroes.senna.morale >= 8, "sucesso na missão pessoal dá flag e moral")
	# Bastidores ligados à história
	var ids := {}
	for sd in 40:
		gs.new_game(sd)
		_to_chapter(gs, "c3")
		for bs in gs.backstage_today:
			ids[bs.event.id] = true
	_expect(not ids.has("primeira_noite") and not ids.has("vespera"), "bastidores de outros capítulos não aparecem no Capítulo 3")
	gs.new_game(1)
	var seen_c1 := false
	for sd in 40:
		gs.new_game(sd)
		for bs in gs.backstage_today:
			if bs.event.id == "primeira_noite":
				seen_c1 = true
	_expect(seen_c1, "bastidor do Capítulo 1 aparece no início")

	# Ultimato ignorado: o herói parte e o equipamento volta ao Baú
	gs.new_game(42)
	gs.inventory = ["espada_longa"]
	HeroRPG.equip(gs, "senna", "arma", 0)
	gs.heroes.senna.morale = 1
	gs.end_day()
	_expect(gs.open_ultimatums().size() == 1 and gs.open_ultimatums()[0].id == "senna", "moral baixa gera ultimato")
	gs.end_day()
	_expect(not gs.hero_order.has("senna") and gs.departed.has("senna") and gs.inventory.has("espada_longa"), "ultimato ignorado: herói parte e o item volta ao Baú")

	# Ultimato atendido com bônus
	gs.new_game(42)
	gs.gold = 100
	gs.heroes.mira.morale = 0
	gs.end_day()
	var u: Dictionary = gs.open_ultimatums()[0]
	gs.resolve_ultimatum(u, gs.ultimatum_data.choices[0])
	gs.end_day()
	_expect(gs.hero_order.has("mira") and gs.heroes.mira.morale >= 3 and gs.gold == 60, "bônus de 40 ouro segura o herói")

	# Promessa: precisa ir em missão em 2 dias; aceita missão mesmo com moral baixa
	gs.new_game(42)
	gs.heroes.lyssa.morale = 0
	gs.end_day()
	gs.resolve_ultimatum(gs.open_ultimatums()[0], gs.ultimatum_data.choices[2])
	_expect(gs.unavailable_reason("lyssa", _mission(gs, "febre")) == "", "promessa: herói aceita a missão prometida")
	gs.end_day()
	gs.end_day()
	_expect(not gs.hero_order.has("lyssa"), "promessa quebrada: o herói parte")

	# Irmandade: parte junto
	gs.new_game(42)
	gs.bond_labels[gs.pair_key("vera", "bram")] = "Irmandade"
	gs.resolve_ultimatum({"id": "vera", "done": false}, gs.ultimatum_data.choices[3])
	_expect(not gs.hero_order.has("vera") and not gs.hero_order.has("bram"), "Irmandade: o irmão de armas parte junto")
	gs.new_game(42)


func _snapshot(gs) -> String:
	var st := {}
	for k in gs.SAVE_KEYS:
		st[k] = gs.get(k)
	return var_to_str(st)


func _check_save(gs) -> void:
	gs.new_game(42)
	gs.begin_chapter()
	gs.gold = 200
	HeroRPG.buy(gs, "espada_longa")
	HeroRPG.equip(gs, "vera", "arma", 0)
	gs.buy_upgrade("quadro")
	gs.dispatch(_mission(gs, "lobos"), ["vera", "bram"])
	gs.change_affinity("lyssa", "mira", 2, 1)
	gs.end_day()
	gs.end_day()
	var snap := _snapshot(gs)
	_expect(gs.save_game("teste"), "salvar em arquivo")
	var next_roll: int = gs.rng.randi()
	gs.new_game(7)
	gs.end_day()
	_expect(_snapshot(gs) != snap, "estado mudou depois do novo jogo")
	_expect(gs.load_game("teste"), "carregar o arquivo")
	_expect(_snapshot(gs) == snap, "estado carregado é idêntico ao salvo")
	_expect(gs.rng.randi() == next_roll, "sorte continua de onde parou")
	_expect(typeof(gs.missions[0].day) == TYPE_INT and typeof(gs.heroes.vera.level) == TYPE_INT, "inteiros continuam inteiros depois de carregar")
	_expect(gs.heroes.vera.color is Color, "cores preservadas")
	_expect(gs.act.id == "ato1" and gs.current_chapter().id == "c1", "ato e capítulo restaurados")
	var meta: Dictionary = gs.save_meta("teste")
	_expect(meta.chapter == "Herança de Cinzas" and meta.chapter_day == 3, "metadados do save (capítulo e dia)")
	# Continua jogável depois de carregar
	gs.end_day()
	_expect(gs.chapter_day() == 4, "jogo segue normalmente depois de carregar")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(gs.save_path("teste")))
	_expect(not gs.load_game("teste"), "carregar espaço vazio falha sem quebrar")
	gs.new_game(42)


func _check_endings(gs) -> void:
	gs.new_game(42)
	gs.flags = ["noite_vencida", "conselho_aliado", "corvo_derrotado", "irmao_salvo"]
	gs.reputation = 25
	var ep: Dictionary = gs.epilogue()
	_expect(ep.title == "A Lenda do Corvo Cinzento", "final Lenda: tudo cumprido, ninguém saiu")
	var senna: Array = ep.heroes.filter(func(e): return e.id == "senna")
	_expect(senna.size() == 1 and String(senna[0].text).contains("Dario"), "epílogo de Senna reflete o irmão salvo")
	gs.departed = ["lyssa"]
	gs.hero_order.erase("lyssa")
	ep = gs.epilogue()
	_expect(ep.title == "A Guilda Reconstruída", "alguém saiu: final Reconstrução")
	var ly: Array = ep.heroes.filter(func(e): return e.id == "lyssa")
	_expect(ly.size() == 1 and String(ly[0].text).contains("sumiu"), "epílogo de quem saiu da guilda")
	gs.flags = []
	_expect(gs.epilogue().title == "Cinzas e Recomeço", "nada cumprido: final Cinzas")
	gs.bond_labels[gs.pair_key("vera", "bram")] = "Mentoria"
	ep = gs.epilogue()
	var bram: Array = ep.heroes.filter(func(e): return e.id == "bram")
	_expect(ep.bonds.size() == 1 and String(bram[0].text).contains("aprendeu"), "vínculos aparecem no epílogo")
	gs.new_game(42)


func _random_playthroughs(gs, n: int) -> void:
	var outcomes := {"limpo": 0, "custo": 0, "falha": 0}
	var route_mods := {}
	var departures := 0
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for run in n:
		gs.new_game(run)
		var guard := 0
		while not gs.is_over() and guard < 300:
			guard += 1
			if gs.chapter_state == "fim_do_ato":
				gs.next_act()
				continue
			for u in gs.open_ultimatums():
				var chs: Array = gs.ultimatum_data.choices.filter(func(c): return gs.ultimatum_block_reason(c) == "")
				gs.resolve_ultimatum(u, chs[rng.randi_range(0, chs.size() - 1)])
			if gs.chapter_state == "intro":
				gs.begin_chapter()
			if gs.chapter_state == "encerrado":
				gs.next_chapter()
				continue
			for up in gs.upgrades_data.upgrades:
				gs.buy_upgrade(up.id)
			for m in gs.board():
				if gs.free_slots() <= 0:
					break
				var avail: Array = gs.hero_order.filter(func(id): return gs.unavailable_reason(id, m) == "")
				avail.shuffle()
				var party: Array = avail.slice(0, rng.randi_range(1, mini(4, avail.size())))
				if party.is_empty() or not gs.unmet_tags(m, party).is_empty():
					continue
				var prep := {}
				for id in party:
					if HeroRPG.is_caster(gs, id) and gs.heroes[id].slots > 0:
						prep[id] = gs.heroes[id].spells_known[rng.randi_range(0, gs.heroes[id].spells_known.size() - 1)]
				var res: Dictionary = _run_expedition(gs, m, party, prep, rng)
				outcomes[res.outcome] += 1
				route_mods[res.route.mod] = route_mods.get(res.route.mod, 0) + 1
				for bs in gs.backstage_today:
					if not bs.done:
						var chs: Array = bs.event.choices
						gs.resolve_backstage(bs, chs[rng.randi_range(0, chs.size() - 1)])
				while not gs.pending_levelups.is_empty():
					var lv: Dictionary = gs.pending_levelups.pop_front()
					var op: Dictionary = HeroRPG.levelup_options(gs, lv)
					HeroRPG.apply_levelup(gs, lv, op.attrs[0] if not op.attrs.is_empty() else "", op.choices[0] if not op.choices.is_empty() else {})
				while not gs.inventory.is_empty():
					var who: String = gs.hero_order[rng.randi_range(0, gs.hero_order.size() - 1)]
					var it: Dictionary = HeroRPG.item(gs, gs.inventory[0])
					var slot: String = "consumivel1" if it.slot == "consumivel" else it.slot
					if gs.heroes[who].equip[slot] != "" or not HeroRPG.equip(gs, who, slot, 0):
						HeroRPG.sell(gs, 0)
				for id in gs.hero_order:
					gs.set_resting(id, gs.heroes[id].rest_request)
				while not gs.pending_events.is_empty():
					var ev: Dictionary = gs.pending_events.pop_front()
					var labels: Array = gs.THRESHOLD_EVENTS[ev.threshold].labels
					gs.choose_bond_label(ev, labels[rng.randi_range(0, labels.size() - 1)])
			gs.end_day()
		_expect(guard < 300, "partida %d terminou" % run)
		departures += gs.departed.size()
	print("Partidas aleatórias: ", outcomes, "  ·  saídas de heróis: ", departures)
	print("  modificador da rota (valor: vezes): ", route_mods)
	var lv := {}
	for id in gs.hero_order:
		lv[id] = gs.heroes[id].level
	print("  níveis ao fim da última partida: ", lv)


## Percorre a expedição escolhendo caminhos e opções ao acaso.
func _run_expedition(gs, m: Dictionary, party: Array, prep: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	Expedition.start(gs, m, party, prep)
	var steps := 0
	while not Expedition.at_boss(gs) and steps < 20:
		var ch: Array = Expedition.choices(gs)
		var out: Dictionary = Expedition.enter(gs, ch[rng.randi_range(0, ch.size() - 1)])
		if out.has("event"):
			var ops: Array = out.event.options
			Expedition.choose(gs, ops[rng.randi_range(0, ops.size() - 1)])
		elif out.has("shop") and not out.shop.is_empty() and rng.randf() < 0.5:
			HeroRPG.buy(gs, out.shop[0])
		steps += 1
	return Expedition.finish(gs)


func _check_expedition(gs) -> void:
	gs.new_game(7)
	var bad := 0
	var types := {}
	for m in gs.missions:
		for d in 6:
			gs.day = d + 1
			var exp: Dictionary = Expedition.start(gs, m, ["vera", "bram"], {})
			var layers: Array = exp.layers
			# todo nó intermediário tem entrada e saída válida; todo caminho chega ao alvo
			var reach := {}
			for i in layers[0].size():
				reach["0:%d" % i] = true
			for l in layers.size() - 1:
				for i in layers[l].size():
					var node: Dictionary = layers[l][i]
					types[node.type] = types.get(node.type, 0) + 1
					if not reach.has("%d:%d" % [l, i]):
						bad += 1
					var tl := l + (2 if node.type == "atalho" else 1)
					if node.next.is_empty() or tl >= layers.size():
						bad += 1
					for j in node.next:
						if j >= layers[tl].size():
							bad += 1
						reach["%d:%d" % [tl, j]] = true
			if not reach.has("%d:0" % (layers.size() - 1)):
				bad += 1
	_expect(bad == 0, "mapas de expedição: grafo conexo, sem nós órfãos (%d problema(s))" % bad)
	_expect(types.size() >= 6, "mapas usam todos os tipos de nó: %s" % [types])
	gs.expedition = {}
	# efeitos e teste de dado
	var m := _mission(gs, "lobos")
	Expedition.start(gs, m, ["vera", "bram"], {})
	var hp_before: int = gs.heroes.bram.hp
	Expedition.apply(gs, {"gold": 20, "provisions": 1, "bonus": 2, "hp_one": -3, "item": "loot", "days": 1}, "bram")
	_expect(gs.expedition.gold == 20 and gs.expedition.bonus == 2 and gs.expedition.items.size() == 1, "efeitos da rota somam na bolsa, preparação e itens")
	_expect(gs.heroes.bram.hp == maxi(1, hp_before - 3), "dano da rota fere sem derrubar")
	var opt := {"label": "x", "test": {"attr": "forca"}, "ok": {"fx": {"gold": 5}}, "fail": {"fx": {}}}
	var r: Dictionary = Expedition.choose(gs, opt)
	_expect(r.dice.hero == "vera" and r.dice.mod == int(HeroRPG.effective_attrs(gs, "vera").forca) - 5, "teste usa o herói mais apto e mod = atributo − 5")
	gs.expedition.provisions = 0
	gs.expedition.cur = [0, 0]
	gs.expedition.hunger = 0
	var tgt: Array = Expedition.choices(gs)[0]
	Expedition.enter(gs, tgt)
	_expect(gs.expedition.hunger == 1, "sem provisões, o passo é com fome")
	var mod_expected: int = mini(2, 3) - Expedition.wear(gs) - 1
	_expect(Expedition.route_mod(gs) == mod_expected, "modificador da rota = preparação − desgaste − fome")
	var gold0: int = gs.gold
	var inv0: int = gs.inventory.size()
	var res: Dictionary = Expedition.finish(gs)
	_expect(res.score.route == mod_expected, "rota entra no score")
	if res.outcome == "falha":
		_expect(gs.inventory.size() == inv0, "na falha, saque da rota se perde")
	else:
		_expect(gs.inventory.size() >= inv0 + 1, "no sucesso, itens da rota vão para o Baú")
	_expect(gs.gold > gold0 or res.outcome == "falha", "ouro da rota e recompensa entram na guilda")
	_expect(gs.heroes.vera.away_until == gs.day + 1, "atraso deixa o grupo fora por mais um dia")
	gs.end_day()
	_expect(gs.heroes.vera.busy, "no dia seguinte, o grupo ainda está na estrada")
	gs.end_day()
	_expect(not gs.heroes.vera.busy, "depois volta à guilda")
	_expect(gs.expedition.is_empty(), "expedição encerrada")


func _check_mind(gs) -> void:
	gs.new_game(11)
	var h: Dictionary = gs.heroes.bram
	_expect(h.stress == 0 and h.traits.is_empty() and h.condition == "", "herói começa sem estresse, traços ou condição")
	Mind.add_stress(gs, "bram", 4)
	_expect(h.stress == 4, "estresse soma")
	gs.rng.seed = 1
	var lines: Array = Mind.add_stress(gs, "bram", 20)
	_expect(h.condition != "" and h.condition_kind in ["aflicao", "virtude"], "no máximo, vira aflição ou virtude (%s)" % h.condition)
	_expect(not lines.is_empty(), "ponto de ruptura é narrado")
	# força uma aflição e confere o score
	h.condition = "desesperado"
	h.condition_kind = "aflicao"
	h.stress = 10
	var m := _mission(gs, "lobos")
	var sc: Dictionary = ScoreCalc.compute(gs, m, ["bram"], 0)
	_expect(sc.mind == -2, "aflição Desesperado dá −2 em Mente")
	var hp0: int = h.hp
	Mind.add_stress(gs, "bram", 1)
	_expect(h.hp == maxi(1, hp0 - 1), "estresse no limite causa colapso (−1 PV)")
	gs.heroes.bram.busy = false
	gs.set_resting("bram", true)
	gs.end_day()
	_expect(h.condition == "" and h.stress <= 5, "descanso na guilda cura a aflição e alivia o estresse")
	# virtude dura virtue_missions missões
	h.condition = "corajoso"
	h.condition_kind = "virtude"
	h.condition_left = 1
	_expect(ScoreCalc.compute(gs, m, ["bram"], 0).mind == 2, "virtude Corajoso dá +2 em Mente")
	Mind.after_mission(gs, m, ["bram"], {}, "limpo")
	_expect(h.condition == "", "virtude passa depois das missões")
	# traços
	Mind.gain_trait(gs, "bram", false, "claustrofobico")
	var mont := _mission(gs, "torre")
	_expect(ScoreCalc.compute(gs, mont, ["bram"], 0).mind == -1, "traço de bioma pesa só no bioma (montanha −1)")
	_expect(ScoreCalc.compute(gs, m, ["bram"], 0).mind == 0, "e não pesa em outro bioma")
	Mind.gain_trait(gs, "bram", true, "sangue_frio")
	h.stress = 0
	Mind.add_stress(gs, "bram", 2)
	_expect(h.stress == 1, "Sangue-Frio reduz o estresse ganho")
	for i in 10:
		Mind.gain_trait(gs, "bram", gs.rng.randf() < 0.5)
	_expect(h.traits.size() <= int(gs.traits_data.max_traits), "limite de traços")
	# rota: estresse, perda de item, requisito e miniboss
	gs.heroes.vera.equip.arma = "espada_longa"
	Expedition.start(gs, _mission(gs, "caravana"), ["vera", "theo"], {})
	var lines2: Array = Expedition.apply(gs, {"lose_item": "arma", "stress": 2}, "vera")
	_expect(gs.heroes.vera.equip.arma == "", "evento de perda tira a arma equipada")
	_expect(gs.heroes.theo.stress >= 1, "estresse da rota vale para o grupo")
	gs.gold = 0
	_expect(Expedition.option_block(gs, {"requires": {"guild_gold": 25}}) != "", "opção com custo fica bloqueada sem ouro")
	var has_mini := true
	for mm in gs.missions:
		if mm.risk != "baixo" and not mm.has("route"):   # rota fixa é desenhada à mão
			var e: Dictionary = Expedition.start(gs, mm, ["vera"], {})
			var layer: Array = e.layers[e.layers.size() - 2]
			if not layer.any(func(n): return n.type == "miniboss"):
				has_mini = false
	_expect(has_mini, "missões de risco médio+ têm guarda do alvo antes do chefe")
	for t in ["npc", "santuario", "miniboss"]:
		_expect(not gs.route_data.events.get(t, []).is_empty(), "eventos de %s existem" % t)
	gs.expedition = {}
	# save antigo sem os campos novos
	for id in gs.heroes:
		gs.heroes[id].erase("stress")
		gs.heroes[id].erase("traits")
	gs.save_game("teste_mind")
	gs.load_game("teste_mind")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(gs.save_path("teste_mind")))
	_expect(gs.heroes.vera.has("stress") and gs.heroes.vera.has("traits"), "save antigo ganha estresse e traços ao carregar")


func _check_story(gs) -> void:
	gs.new_game(21)
	var res: Dictionary = gs.dispatch(_mission(gs, "lobos"), ["vera", "bram"])
	var st: Array = res.story
	_expect(not st.is_empty() and st.size() <= int(gs.result_story_data.max_beats), "resultado contado em até %d momentos" % int(gs.result_story_data.max_beats))
	var pair_lines: Array = gs.result_story_data.pairs["bram|vera"].sinergia.texts + gs.result_story_data.pairs["bram|vera"].sinergia.texts_falha
	_expect(st.any(func(b): return b.type == "sinergia" and pair_lines.has(b.text)), "Vera e Bram ganham a frase própria do par (%s)" % [st.map(func(b): return b.text)])
	_expect(st.any(func(b): return b.type == "sinergia" and b.image.ends_with("par_bram_vera_sinergia.png")), "e a imagem própria do par")
	gs.new_game(21)
	var r2: Dictionary = gs.dispatch(_mission(gs, "lobos"), ["theo", "lyssa"])
	_expect(r2.story.any(func(b): return b.type == "conflito"), "Theo e Lyssa geram um momento de conflito")
	var again: Dictionary = gs.dispatch(_mission(gs, "ratos"), ["vera"])
	_expect(not again.story.any(func(b): return b.text.contains("{")), "sem marcadores sobrando no texto")


func _check_town(gs) -> void:
	gs.new_game(33)
	_expect(gs.town_esteem == 3 and int(gs.heroes.bram.fame) == 0, "cidade começa indiferente e heróis desconhecidos")
	# melhoria oculta: não aparece nem pode ser comprada antes do bastidor
	gs.gold = 500
	gs.reputation = 10
	_expect(not Economy.visible_upgrades(gs).any(func(u): return u.id == "forja"), "Forja começa oculta")
	_expect(not gs.buy_upgrade("forja"), "oculta não pode ser construída")
	var ev: Dictionary = gs.backstage_data.events.filter(func(e): return e.id == "ferreiro_dorin")[0]
	var bs := {"event": ev, "a": "vera", "b": "bram", "done": false}
	var lines: Array = gs.resolve_backstage(bs, ev.choices[0])
	_expect(gs.upgrades_revealed.has("forja") and lines.any(func(l): return l.contains("Nova melhoria")), "bastidor revela a Forja")
	_expect(Backstage._candidate_pairs(gs, ev).is_empty(), "cena que revela não volta depois de revelada")
	var m := _mission(gs, "lobos")
	var before: int = ScoreCalc.compute(gs, m, ["vera", "bram"], 0).powers
	_expect(gs.buy_upgrade("forja"), "Forja construída com ouro")
	_expect(ScoreCalc.compute(gs, m, ["vera", "bram"], 0).powers == before + 1, "Forja dá +1 em combate uma vez só (não por herói)")
	# capela: efeito por herói
	gs.upgrades_revealed.append("capela")
	gs.buy_upgrade("capela")
	gs.heroes.mira.stress = 0
	Mind.add_stress(gs, "mira", 2)
	_expect(gs.heroes.mira.stress == 1, "Capela: cada herói ganha 1 a menos de estresse")
	# fama, estima e escolhas com custo
	var ev2: Dictionary = gs.backstage_data.events.filter(func(e): return e.id == "telhado_viuva")[0]
	gs.resolve_backstage({"event": ev2, "a": "theo", "b": "senna", "done": false}, ev2.choices[0])
	_expect(int(gs.heroes.theo.fame) == 1 and gs.town_esteem == 5, "ajudar a viúva: fama +1 e estima +2")
	gs.gold = 0
	_expect(Backstage.choice_block(gs, ev2.choices[1]) != "", "escolha com custo bloqueada sem ouro")
	gs.town_esteem = 17
	_expect(HeroRPG.buy_price(gs, "espada_longa") < int(HeroRPG.item(gs, "espada_longa").price), "cidade devota baixa os preços")
	gs.town_esteem = 0
	_expect(HeroRPG.buy_price(gs, "espada_longa") > int(HeroRPG.item(gs, "espada_longa").price), "cidade desconfiada encarece")
	# termo Povo só em diplomacia
	var dip := _mission(gs, "caravana")
	gs.heroes.bram.fame = 9
	gs.heroes.mira.fame = 9
	_expect(ScoreCalc.compute(gs, dip, ["bram", "mira"], 0).povo == 2, "fama alta dá +2 em diplomacia")
	_expect(ScoreCalc.compute(gs, m, ["bram", "mira"], 0).povo == 0, "e nada em combate")
	# save
	gs.save_game("teste_town")
	gs.load_game("teste_town")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(gs.save_path("teste_town")))
	_expect(gs.upgrades_revealed.has("forja") and int(gs.heroes.bram.fame) == 9, "save guarda melhorias reveladas e fama")


func _check_arcs(gs) -> void:
	gs.new_game(55)
	var ids: Array = Chapters.current_chapter(gs).missions
	var a := _mission(gs, ids[0])
	var b := _mission(gs, ids[1])
	a.requires_flag = "teste_pista"
	a.arc_delay = 1
	b.forbids_flag = "teste_pista"
	Arcs.on_chapter_start(gs)
	_expect(a.status == "bloqueada", "missão de arco começa bloqueada")
	Arcs.add_flag(gs, "teste_pista")
	_expect(a.status == "aberta" and a.day == gs.day + 1, "flag abre a missão de arco com atraso")
	_expect(b.status == "cancelada", "flag proibida cancela o outro ramo")
	# decisão
	gs.decisions_data = {"decisions": [{"id": "dt", "title": "T", "text": "x",
		"voices": {"vera": {"text": "sim", "leans": "c1"}, "bram": {"text": "não", "leans": "c2"}},
		"choices": [{"id": "c1", "label": "A", "text": "feito", "flags": ["dt_c1"], "gold": 5},
			{"id": "c2", "label": "B", "text": "outro", "requires_flags": ["nunca"]}]}]}
	Arcs.after_mission(gs, a, ["vera", "bram"], {"decision": "dt"})
	_expect(gs.pending_decisions.size() == 1, "missão agenda decisão")
	var pend: Dictionary = gs.pending_decisions.pop_front()
	var d := Arcs.decision(gs, "dt")
	_expect(Arcs.choices(gs, d).size() == 1, "escolha com flag faltando fica escondida")
	gs.heroes.vera.morale = 5
	var st: int = gs.heroes.bram.stress
	var g: int = gs.gold
	Arcs.resolve(gs, pend, d.choices[0])
	_expect(gs.heroes.vera.morale == 6 and gs.heroes.bram.stress == st + 1, "quem concorda ganha moral, quem discorda ganha estresse")
	_expect(gs.flags.has("dt_c1") and gs.gold == g + 5, "escolha aplica flag e ouro")
	# rota fixa
	var groups: Dictionary = Expedition.data(gs).events
	var ev_id: String = groups[groups.keys()[0]][0].id
	a.route = {"fixed": [[{"type": "evento", "event": ev_id}], [{"type": "evento", "event": ev_id}, {"type": "descanso"}]], "provisions": 4}
	var exp: Dictionary = Expedition.start(gs, a, ["vera", "bram"], {})
	_expect(exp.layers.size() == 3 and exp.layers[1].size() == 2 and exp.layers[2][0].type == "chefe", "rota fixa segue o desenho e termina no alvo")
	_expect(exp.provisions == 4 and exp.layers[0][0].next == [0, 1], "rota fixa: provisões e ligações padrão")
	_expect(not Expedition.event_by_id(gs, "inexistente", ev_id).is_empty(), "evento de rota fixa achado em qualquer grupo")
	var r: Dictionary = _run_expedition(gs, a, ["vera", "bram"], {}, RandomNumberGenerator.new())
	_expect(not r.is_empty(), "rota fixa chega ao fim")
	a.erase("route")


## Arco "A Marca nas Paredes" (Cap. 2): completável com e sem contrato, e encerrável na decisão.
func _marca_run(gs, seed: int, party: Array, negotiation: int, decision: String) -> Dictionary:
	gs.new_game(seed)
	_to_chapter(gs, "c2")
	var marca := _mission(gs, "marca")
	var dep := _mission(gs, "deposito")
	var out := {"dep_locked": dep.status == "bloqueada", "marca_open": marca.status == "aberta"}
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	Expedition.start(gs, marca, party, {})
	var first: Dictionary = Expedition.enter(gs, Expedition.choices(gs)[0])
	Expedition.choose(gs, first.event.options[negotiation])
	out.paths = Expedition.choices(gs).size()
	var mid: Dictionary = Expedition.enter(gs, Expedition.choices(gs)[0])
	Expedition.choose(gs, mid.event.options[0])
	Expedition.enter(gs, Expedition.choices(gs)[0])
	Expedition.finish(gs)
	out.knows = gs.flags.has("mc_deposito")
	out.pending = gs.pending_decisions.size()
	var pend: Dictionary = gs.pending_decisions.pop_front()
	var d := Arcs.decision(gs, "mc_decisao")
	var ch: Array = Arcs.choices(gs, d).filter(func(c): return c.id == decision)
	if ch.is_empty():
		ch = Arcs.choices(gs, d).filter(func(c): return c.id == "ir")
	Arcs.resolve(gs, pend, ch[0])
	out.dep_status = dep.status
	out.reward = Economy.mission_reward(gs, dep)
	if dep.status == "aberta":
		var r: Dictionary = _run_expedition(gs, dep, party, {}, rng)
		out.result = r.outcome
		out.recibo = gs.flags.has("mc_recibo")
		out.lamina = gs.inventory.has("lamina_runica")
	return out


func _check_marca(gs) -> void:
	var a := _marca_run(gs, 101, ["vera", "bram", "lyssa"], 0, "ir")
	_expect(a.marca_open and a.dep_locked, "Marca: etapa 1 no quadro, depósito bloqueado")
	_expect(a.paths == 2, "Marca: com contrato, a escolta não aparece (2 caminhos)")
	_expect(a.knows and a.pending == 1, "Marca: etapa 1 dá o endereço e agenda a decisão")
	_expect(a.dep_status == "aberta", "Marca: 'Ir ao depósito' abre a etapa 2")
	_expect(a.has("result"), "Marca: etapa 2 completável com contrato")
	if a.get("result", "") != "falha":
		_expect(a.recibo and a.lamina, "Marca: vitória dá o recibo e a Lâmina Rúnica")
	var b := _marca_run(gs, 202, ["theo", "mira"], 2, "ir")
	_expect(b.paths == 3, "Marca: sem contrato, a escolta aparece (3 caminhos)")
	_expect(b.has("result"), "Marca: etapa 2 completável sem contrato")
	var base := _marca_run(gs, 303, ["theo", "mira"], 0, "guarda")
	_expect(base.dep_status == "cancelada", "Marca: 'Avisar a guarda' encerra o arco")
	# recompensa negociada
	gs.new_game(5)
	var dep := _mission(gs, "deposito")
	var normal: int = Economy.mission_reward(gs, dep)
	gs.flags.append("mc_bom_preco")
	_expect(Economy.mission_reward(gs, dep) > normal, "Marca: pedir mais aumenta a recompensa")
	gs.flags.erase("mc_bom_preco")
	gs.flags.append("mc_sem_contrato")
	_expect(Economy.mission_reward(gs, dep) < normal, "Marca: sem contrato, só metade (cobrada com a prova)")
	# teste dispensado e ajuda
	gs.new_game(6)
	Expedition.start(gs, _mission(gs, "marca"), ["senna", "theo"], {})
	var fig: Dictionary = Expedition.event_by_id(gs, "", "mc_figueira")
	_expect(Expedition.auto_pass(gs, fig.options[0]) != "", "Marca: Senna fala com Lisandre sem teste")
	var neg: Dictionary = Expedition.event_by_id(gs, "", "mc_negociacao")
	_expect(Expedition.help_bonus(gs, neg.options[1]) == 0, "Marca: sem Bram, sem ajuda na pechincha")
	gs.expedition.party = ["bram", "theo"]
	_expect(Expedition.help_bonus(gs, neg.options[1]) == 2, "Marca: Bram dá +2 na pechincha")
	gs.expedition = {}


func _expect(ok: bool, msg: String) -> void:
	if ok:
		print("  ok  ", msg)
	else:
		failures += 1
		print("  FALHA  ", msg)
