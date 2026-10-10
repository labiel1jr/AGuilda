class_name Endings
## Epílogo: final por condições, desfecho por herói e linha por vínculo (data/endings.json).
## Funções estáticas sobre o estado (gs: GuildState, o autoload GameState).


static func _ending_matches(gs: GuildState, c: Dictionary, hero_id: String = "") -> bool:
	for f in c.get("all_flags", []):
		if not gs.flags.has(f):
			return false
	if c.has("any_flags") and not c.any_flags.any(func(f): return gs.flags.has(f)):
		return false
	for f in c.get("no_flags", []):
		if gs.flags.has(f):
			return false
	if c.has("min_reputation") and gs.reputation < int(c.min_reputation):
		return false
	if c.has("max_departed") and gs.departed.size() > int(c.max_departed):
		return false
	if hero_id != "":
		if c.has("departed") and bool(c.departed) != gs.departed.has(hero_id):
			return false
		if c.has("min_morale") and gs.heroes[hero_id].morale < int(c.min_morale):
			return false
		if c.has("bond"):
			var found := false
			for other in gs.heroes:
				if other != hero_id and Relations.bond_label(gs, hero_id, other) == c.bond:
					found = true
			if not found:
				return false
	return true


## {title, text, heroes: [{id, text}], bonds: [texto]}
static func epilogue(gs: GuildState) -> Dictionary:
	var ed: Dictionary = gs._load_json("res://data/endings.json")
	var out := {"title": "", "text": "", "heroes": [], "bonds": []}
	for e in ed.endings:
		if Endings._ending_matches(gs, e):
			out.title = e.title
			out.text = e.text
			break
	var everyone: Array = gs.hero_order + gs.departed
	for id in everyone:
		for c in ed.heroes.get(id, []):
			if Endings._ending_matches(gs, c, id):
				out.heroes.append({"id": id, "text": c.text})
				break
	for key in gs.bond_labels:
		var t: String = ed.bonds.get(gs.bond_labels[key], "")
		if t != "":
			var ids: PackedStringArray = key.split("|")
			out.bonds.append(t.replace("{a}", gs.heroes[ids[0]].name).replace("{b}", gs.heroes[ids[1]].name))
	return out
