class_name Chapters
## Atos e capítulos: abertura, dias, recrutas, objetivo, encerramento e próximo ato (GDD §7).
## Funções estáticas sobre o estado (gs: GuildState, o autoload GameState).


static func is_over(gs: GuildState) -> bool:
	return gs.chapter_state == "fim_de_jogo"


static func has_next_act(gs: GuildState) -> bool:
	return gs.act_index + 1 < gs.chapters_data.acts.size()


## Depois da tela de fim de ato: próximo ato ou fim de jogo.
static func next_act(gs: GuildState) -> void:
	if Chapters.has_next_act(gs):
		gs.act_index += 1
		gs.act = gs.chapters_data.acts[gs.act_index]
		Chapters.start_chapter(gs, 0)
	else:
		gs.chapter_state = "fim_de_jogo"


static func current_chapter(gs: GuildState) -> Dictionary:
	var id: String = gs.act.chapters[gs.chapter_index]
	for ch in gs.chapters_data.chapters:
		if ch.id == id:
			return ch
	return {}


static func chapter_end_day(gs: GuildState) -> int:
	return gs.chapter_start + int(Chapters.current_chapter(gs).days) - 1


static func chapter_day(gs: GuildState) -> int:
	return gs.day - gs.chapter_start + 1


static func chapter_intro(gs: GuildState) -> Array:
	var ch := Chapters.current_chapter(gs)
	var lines: Array = ch.get("intro", []).duplicate()
	var extra: Dictionary = ch.get("intro_flags", {})
	for key in extra:
		var neg := String(key).begins_with("!")
		var flag := String(key).trim_prefix("!")
		if gs.flags.has(flag) != neg:
			lines.append(extra[key])
	return lines


static func start_chapter(gs: GuildState, i: int) -> void:
	gs.chapter_index = i
	gs.chapter_start = gs.day
	var ch := Chapters.current_chapter(gs)
	for r in gs.recruits.duplicate():
		if r.chapter == ch.id:
			Chapters.recruit(gs, r.id)
			gs.recruits.erase(r)
	for m in gs.missions:
		if ch.missions.has(m.id):
			m.status = "aberta"
			m.day = gs.chapter_start + m.rel_day - 1
	gs.chapter_state = "intro"


## Herói novo entra no elenco: pares novos começam a contar a partir de hoje.
static func recruit(gs: GuildState, id: String) -> void:
	for other in gs.hero_order:
		var key := GuildState.pair_key(id, other)
		gs.initial_affinity[key] = Relations.pair_value(gs, id, other)
		gs.last_together[key] = gs.day
	gs.hero_order.append(id)
	gs.heroes[id].last_dispatch = gs.day


## Heróis que entraram neste capítulo (para a tela de abertura).
static func chapter_recruits(gs: GuildState) -> Array:
	var out := []
	for id in gs.hero_order:
		if gs.heroes[id].joins_text != "" and gs.heroes[id].last_dispatch == gs.chapter_start and gs.chapter_start > 1:
			out.append(id)
	return out


static func begin_chapter(gs: GuildState) -> void:
	gs.chapter_state = "jogando"


## Avalia o objetivo do capítulo que terminou.
static func close_chapter(gs: GuildState) -> void:
	var ch := Chapters.current_chapter(gs)
	var goal: Dictionary = ch.goal
	var ok := false
	match goal.type:
		"reputation":
			ok = gs.reputation >= int(goal.min)
		"mission":
			for m in gs.missions:
				if m.id == goal.mission:
					ok = m.status == "concluida" and m.result.outcome != "falha"
	if ok and ch.has("flag_success"):
		gs.flags.append(ch.flag_success)
	gs.chapter_result = {"chapter": ch, "success": ok, "text": ch.outro["success" if ok else "failure"]}
	gs.chapter_state = "encerrado"


## Depois da tela de encerramento: próximo capítulo ou fim do ato.
static func next_chapter(gs: GuildState) -> void:
	if gs.chapter_index + 1 < gs.act.chapters.size():
		Chapters.start_chapter(gs, gs.chapter_index + 1)
	else:
		gs.chapter_state = "fim_do_ato"
