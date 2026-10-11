class_name Arcs
## Arcos de missões e decisões de arco (missões grandes, ex.: Alvorada Rubra).
##
## Missão de arco (data/missions.json):
##   "requires_flag": "x"  → fica "bloqueada" até a flag existir; quando aparece, abre no quadro
##   "forbids_flag": "y"   → é cancelada se a flag existir (ramo que não foi escolhido)
##   "arc": "id", "stage": n, "arc_delay": dias até abrir depois da flag (padrão 0)
## Efeitos de missão por resultado (effects.<resultado>): "flag", "flags": [...], "decision": "id"
## Decisões (data/decisions.json): cena de escolha com falas dos heróis que foram; cada escolha
##   tem requires_flags/forbids_flags (aparece ou não), flags, gold, esteem, morale, stress, text.
##   Herói que "leans" para a escolha feita ganha moral; quem queria outra ganha estresse.


## Ganha uma flag e atualiza os arcos (abre/cancela missões).
static func add_flag(gs: GuildState, flag: String) -> void:
	if flag == "" or gs.flags.has(flag):
		return
	gs.flags.append(flag)
	refresh(gs)


## Recalcula o estado das missões de arco do capítulo atual.
static func refresh(gs: GuildState) -> void:
	var ch_missions: Array = Chapters.current_chapter(gs).get("missions", [])
	for m in gs.missions:
		if not ch_missions.has(m.id):
			continue
		if m.has("forbids_flag") and gs.flags.has(m.forbids_flag) and m.status in ["bloqueada", "aberta"]:
			m.status = "cancelada"
			continue
		if m.status == "bloqueada" and gs.flags.has(String(m.get("requires_flag", ""))):
			m.status = "aberta"
			m.day = gs.day + int(m.get("arc_delay", 0))


## Ao abrir o capítulo: missões que dependem de flag começam bloqueadas.
static func on_chapter_start(gs: GuildState) -> void:
	var ch_missions: Array = Chapters.current_chapter(gs).get("missions", [])
	for m in gs.missions:
		if ch_missions.has(m.id) and m.has("requires_flag") and not gs.flags.has(m.requires_flag):
			m.status = "bloqueada"
	refresh(gs)


## Efeitos de arco ao fim de uma missão (chamado pelo despacho).
static func after_mission(gs: GuildState, mission: Dictionary, party: Array, fx: Dictionary) -> void:
	for f in fx.get("flags", []):
		add_flag(gs, f)
	if fx.has("decision"):
		gs.pending_decisions.append({"id": fx.decision, "party": party.duplicate(), "mission": mission.id})


static func decision(gs: GuildState, id: String) -> Dictionary:
	for d in gs.decisions_data.get("decisions", []):
		if d.id == id:
			return d
	return {}


## Escolhas disponíveis (pelas flags que o grupo descobriu).
static func choices(gs: GuildState, d: Dictionary) -> Array:
	return d.get("choices", []).filter(func(c):
		for f in c.get("requires_flags", []):
			if not gs.flags.has(f):
				return false
		for f in c.get("forbids_flags", []):
			if gs.flags.has(f):
				return false
		return true)


## Falas dos heróis que estavam na missão: [{id, text, leans}]
static func voices(gs: GuildState, d: Dictionary, party: Array) -> Array:
	var out := []
	for id in party:
		var v: Dictionary = d.get("voices", {}).get(id, {})
		if not v.is_empty() and gs.heroes.has(id):
			out.append({"id": id, "text": v.text, "leans": v.get("leans", "")})
	return out


## Aplica a escolha e devolve as linhas do resultado.
static func resolve(gs: GuildState, pending: Dictionary, choice: Dictionary) -> Array:
	var d := decision(gs, pending.id)
	var lines := [String(choice.get("text", ""))]
	for v in voices(gs, d, pending.party):
		if v.leans == "":
			continue
		var h: Dictionary = gs.heroes[v.id]
		if v.leans == choice.id:
			h.morale = mini(10, h.morale + 1)
			lines.append("%s concorda com a decisão (moral +1)." % h.name)
		else:
			lines.append_array(Mind.add_stress(gs, v.id, 1))
			lines.append("%s queria outro caminho (estresse +1)." % h.name)
	for hid in choice.get("morale", {}):
		if gs.heroes.has(hid):
			gs.heroes[hid].morale = clampi(gs.heroes[hid].morale + int(choice.morale[hid]), 0, 10)
	for hid in choice.get("stress", {}):
		if gs.heroes.has(hid):
			var n := int(choice.stress[hid])
			if n > 0:
				lines.append_array(Mind.add_stress(gs, hid, n))
			else:
				Mind.relieve(gs, hid, -n)
	if choice.has("gold"):
		gs.gold = maxi(0, gs.gold + int(choice.gold))
		lines.append("Ouro da guilda %+d." % int(choice.gold))
	if choice.has("esteem"):
		var l := Town.change_esteem(gs, int(choice.esteem))
		if l != "":
			lines.append(l)
	for f in choice.get("flags", []):
		add_flag(gs, f)
	return lines.filter(func(l): return String(l) != "")
