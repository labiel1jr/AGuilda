class_name SaveSystem
## Salvar e carregar com var_to_str (preserva int e Color); só o estado mutável (GuildState.SAVE_KEYS).
## Funções estáticas sobre o estado (gs: GuildState, o autoload GameState).


## Salva com var_to_str: preserva int, float e Color (JSON transformaria int em float).
static func save_game(gs: GuildState, slot: String) -> bool:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://saves"))
	var state := {}
	for k in GuildState.SAVE_KEYS:
		state[k] = gs.get(k)
	var data := {
		"version": GuildState.SAVE_VERSION,
		"meta": {
			"act": gs.act.title, "chapter": Chapters.current_chapter(gs).get("title", ""),
			"chapter_day": Chapters.chapter_day(gs), "reputation": gs.reputation, "gold": gs.gold,
			"saved_at": Time.get_datetime_string_from_system(false, true),
		},
		"rng_state": gs.rng.state,
		"state": state,
	}
	var f := FileAccess.open(GuildState.save_path(slot), FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(var_to_str(data))
	return true


static func load_game(gs: GuildState, slot: String) -> bool:
	if not FileAccess.file_exists(GuildState.save_path(slot)):
		return false
	var data = str_to_var(FileAccess.get_file_as_string(GuildState.save_path(slot)))
	if not (data is Dictionary) or int(data.get("version", 0)) != GuildState.SAVE_VERSION:
		return false
	gs.new_game()   # recarrega os dados estáticos
	for k in GuildState.SAVE_KEYS:
		if data.state.has(k):
			gs.set(k, data.state[k])
	gs.act = gs.chapters_data.acts[gs.act_index]
	gs.rng.state = data.rng_state
	for id in gs.heroes:
		Mind.ensure(gs.heroes[id])   # saves anteriores à v0.9
	return true


static func save_meta(gs: GuildState, slot: String) -> Dictionary:
	if not FileAccess.file_exists(GuildState.save_path(slot)):
		return {}
	var data = str_to_var(FileAccess.get_file_as_string(GuildState.save_path(slot)))
	if not (data is Dictionary) or int(data.get("version", 0)) != GuildState.SAVE_VERSION:
		return {}
	return data.meta


static func has_any_save(gs: GuildState) -> bool:
	for s in GuildState.SAVE_SLOTS:
		if not SaveSystem.save_meta(gs, s).is_empty():
			return true
	return false


## Save mais recente (para "Continuar").
static func latest_save(gs: GuildState) -> String:
	var best := ""
	var best_at := ""
	for s in GuildState.SAVE_SLOTS:
		var m := SaveSystem.save_meta(gs, s)
		if not m.is_empty() and String(m.saved_at) > best_at:
			best = s
			best_at = m.saved_at
	return best
