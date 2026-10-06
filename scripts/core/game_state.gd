extends Node
## Estado da guilda: elenco, afinidades, missões, dia e reputação.
## Autoload "GameState". Toda regra de jogo fica aqui ou em ScoreCalc; a UI só lê e chama.

const ATTRS := ["forca", "destreza", "conhecimento", "carisma", "resistencia"]
const ATTR_NAMES := {
	"forca": "Força", "destreza": "Destreza", "conhecimento": "Conhecimento",
	"carisma": "Carisma", "resistencia": "Resistência",
}
const RISK_NAMES := {"baixo": "BAIXO", "medio": "MÉDIO", "alto": "ALTO", "lendario": "LENDÁRIO"}
const FATIGUE_NAMES := ["Pronto", "Cansado", "Exausto"]
const OUTCOME_NAMES := {"limpo": "Sucesso Limpo", "custo": "Sucesso com Custo", "falha": "Falha com Revelação"}

const AFF_MIN := -5
const AFF_MAX := 10
const LAST_DAY := 8

## Faixas de afinidade (GDD §5.4.1): [até, rótulo, modificador]
const BANDS := [
	[-3, "Conflito Aberto", -4],
	[-1, "Tensão Velada", -2],
	[0, "Neutros", 0],
	[2, "Camaradas", 2],
	[5, "Companheiros", 4],
	[8, "Laço Forte", 6],
	[10, "Dupla Lendária", 8],
]

## Eventos de limiar (GDD §5.4.3)
const THRESHOLD_EVENTS := {
	3: {"title": "Algo mudou entre eles", "labels": ["Amizade", "Lealdade", "Rivalidade Saudável"]},
	6: {"title": "Um vínculo se forma", "labels": ["Amizade Profunda", "Mentoria", "Atração", "Rivalidade Saudável"]},
	9: {"title": "Não é mais só trabalho", "labels": ["Parceria Lendária", "Romance", "Irmandade"]},
	-3: {"title": "A tensão explodiu", "labels": ["Rivalidade", "Rancor", "Ruptura"]},
	-5: {"title": "Isso não tem conserto fácil", "labels": ["Inimizade Declarada"]},
}

## Ações de Vínculo (GDD §5.5) — ativas com o par em Laço Forte (+6)
const BOND_ACTIONS := {
	"Amizade Profunda": "Cobertura Mútua",
	"Mentoria": "Impulso do Mentor",
	"Atração": "Esforço Extra",
	"Rivalidade Saudável": "Competição",
	"Parceria Lendária": "Sincronia Perfeita",
	"Irmandade": "Até o Fim",
}
const BOND_MIN := 6

var heroes := {}          # id -> {id, name, archetype, color, attrs, trait, fatigue, morale, busy, history}
var hero_order := []
var affinity := {}        # a -> {b: int} (assimétrica)
var bond_labels := {}     # "a|b" -> rótulo
var fired := {}           # "a|b" -> [limiares já disparados]
var missions := []
var day := 1
var reputation := 0
var dispatched_today := 0
var pending_events := []  # eventos de vínculo aguardando escolha do jogador
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	new_game()


func new_game(seed_value: int = -1) -> void:
	if seed_value >= 0:
		rng.seed = seed_value
	else:
		rng.randomize()
	var hd: Dictionary = _load_json("res://data/heroes.json")
	heroes.clear()
	hero_order.clear()
	for h in hd.heroes:
		var attrs := {}
		for k in ATTRS:
			attrs[k] = int(h.attrs[k])
		heroes[h.id] = {
			"id": h.id, "name": h.name, "archetype": h.archetype, "color": Color(h.color),
			"trait": h.trait, "attrs": attrs,
			"fatigue": 0, "morale": 6, "busy": false, "history": [],
		}
		hero_order.append(h.id)
	affinity.clear()
	for a in hd.affinity:
		affinity[a] = {}
		for b in hd.affinity[a]:
			affinity[a][b] = int(hd.affinity[a][b])
	bond_labels.clear()
	fired.clear()
	missions.clear()
	for m in _load_json("res://data/missions.json").missions:
		var mm: Dictionary = m.duplicate(true)
		mm.day = int(mm.day)
		mm.deadline = int(mm.deadline)
		mm.status = "aberta"
		mm.result = {}
		missions.append(mm)
	day = 1
	reputation = 0
	dispatched_today = 0
	pending_events.clear()


# ---------- afinidade ----------

static func pair_key(a: String, b: String) -> String:
	return a + "|" + b if a < b else b + "|" + a


## Valor mecânico do par: o menor dos dois lados (GDD §5.4.2).
func pair_value(a: String, b: String) -> int:
	return min(affinity[a][b], affinity[b][a])


func band(v: int) -> Dictionary:
	for bd in BANDS:
		if v <= bd[0]:
			return {"label": bd[1], "mod": bd[2]}
	return {"label": BANDS[-1][1], "mod": BANDS[-1][2]}


func bond_label(a: String, b: String) -> String:
	return bond_labels.get(pair_key(a, b), "")


func active_bond_actions(party: Array) -> Array:
	var out := []
	for pr in ScoreCalc.pairs_of(party):
		var label := bond_label(pr[0], pr[1])
		if BOND_ACTIONS.has(label) and pair_value(pr[0], pr[1]) >= BOND_MIN:
			out.append({"a": pr[0], "b": pr[1], "label": label, "action": BOND_ACTIONS[label]})
	return out


## Altera a afinidade nos dois sentidos e enfileira eventos de limiar.
func change_affinity(a: String, b: String, delta_ab: int, delta_ba: int) -> void:
	var before := pair_value(a, b)
	affinity[a][b] = clampi(affinity[a][b] + delta_ab, AFF_MIN, AFF_MAX)
	affinity[b][a] = clampi(affinity[b][a] + delta_ba, AFF_MIN, AFF_MAX)
	var after := pair_value(a, b)
	var key := pair_key(a, b)
	var done: Array = fired.get(key, [])
	for t in THRESHOLD_EVENTS:
		if done.has(t):
			continue
		var crossed: bool = (t > 0 and before < t and after >= t) or (t < 0 and before > t and after <= t)
		if crossed:
			done.append(t)
			pending_events.append({"a": a, "b": b, "threshold": t})
	fired[key] = done


func choose_bond_label(event: Dictionary, label: String) -> void:
	bond_labels[pair_key(event.a, event.b)] = label


# ---------- missões ----------

func slots() -> int:
	if reputation >= 12:
		return 3
	if reputation >= 5:
		return 2
	return 1


func free_slots() -> int:
	return slots() - dispatched_today


func expires_on(m: Dictionary) -> int:
	return m.day + m.deadline - 1


func board() -> Array:
	var out := []
	for m in missions:
		if m.status == "aberta" and m.day <= day:
			out.append(m)
	return out


func is_over() -> bool:
	if day > LAST_DAY:
		return true
	for m in missions:
		if m.status == "aberta":
			return false
	return true


## "" se pode ir; senão, o motivo.
func unavailable_reason(id: String, mission: Dictionary) -> String:
	var h: Dictionary = heroes[id]
	if h.busy:
		return "Em missão"
	if h.fatigue >= 2:
		return "Exausto"
	if h.morale <= 1:
		return "Recusa (moral baixa)"
	for tag in mission.get("tags", []):
		if tag.type == "forbid_hero" and tag.hero == id:
			return "Proibido nesta missão"
	return ""


## Requisitos de composição não atendidos.
func unmet_tags(mission: Dictionary, party: Array) -> Array:
	var out := []
	for tag in mission.get("tags", []):
		if tag.type == "requires_attr":
			var ok := false
			for id in party:
				if heroes[id].attrs[tag.attr] >= int(tag.min):
					ok = true
			if not ok:
				out.append(tag.text)
	return out


func dispatch(mission: Dictionary, party: Array) -> Dictionary:
	var luck := rng.randi_range(-2, 2)
	var sc := ScoreCalc.compute(self, mission, party, luck)
	var result := ScoreCalc.outcome(sc.total, mission.risk)
	var actions: Array = sc.actions
	var action_names := actions.map(func(x): return x.action)
	var lines := []
	var aff_changes := []

	if result == "falha" and action_names.has("Sincronia Perfeita"):
		result = "custo"
		lines.append("Sincronia Perfeita: a dupla transformou o desastre em vitória amarga.")

	var names := ", ".join(party.map(func(id): return heroes[id].name))
	lines.push_front(String(mission.texts[result]).replace("{party}", names))
	if sc.hidden != 0:
		lines.append(mission.hidden.text)
	for act in actions:
		match act.action:
			"Impulso do Mentor":
				lines.append("%s e %s: Impulso do Mentor — o mais novo lutou acima do próprio nível." % [heroes[act.a].name, heroes[act.b].name])
			"Esforço Extra":
				lines.append("%s e %s se esforçaram além da conta um pelo outro." % [heroes[act.a].name, heroes[act.b].name])
			"Competição":
				lines.append("%s e %s disputaram quem resolvia primeiro." % [heroes[act.a].name, heroes[act.b].name])

	# Fadiga
	var protected := ""
	if result == "falha":
		for act in actions:
			if act.action == "Cobertura Mútua":
				protected = act.b
				lines.append("Cobertura Mútua: %s absorveu o pior para que %s voltasse ileso." % [heroes[act.a].name, heroes[act.b].name])
	for id in party:
		var h: Dictionary = heroes[id]
		h.busy = true
		if id == protected:
			continue
		h.fatigue = 2 if (mission.risk in ["alto", "lendario"] or h.fatigue >= 1) else 1
	for act in actions:
		if act.action == "Esforço Extra":
			heroes[act.a].fatigue = 2
			heroes[act.b].fatigue = 2

	# Moral e reputação
	var morale_delta: int = {"limpo": 1, "custo": 0, "falha": -1}[result]
	for id in party:
		var h: Dictionary = heroes[id]
		var dm := morale_delta
		if party.size() == 1 and result != "limpo":
			dm -= 1
		h.morale = clampi(h.morale + dm, 0, 10)
		h.history.append({"day": day, "mission": mission.name, "result": result})
	reputation = max(0, reputation + {"limpo": 2, "custo": 1, "falha": -1}[result])

	# Afinidade (GDD §5.4.2)
	var pair_delta: int = {"limpo": 1, "custo": 0, "falha": -1}[result]
	for pr in ScoreCalc.pairs_of(party):
		if pair_delta != 0:
			_change_logged(pr[0], pr[1], pair_delta, pair_delta, aff_changes)
	if result == "custo" and party.size() >= 2 and rng.randf() < 0.4:
		var pairs := ScoreCalc.pairs_of(party)
		var pr: Array = pairs[rng.randi_range(0, pairs.size() - 1)]
		lines.append("%s protegeu %s no pior momento." % [heroes[pr[0]].name, heroes[pr[1]].name])
		_change_logged(pr[0], pr[1], 2, 2, aff_changes)
	if result == "falha" and party.size() >= 2 and rng.randf() < 0.4:
		var pairs := ScoreCalc.pairs_of(party)
		var pr: Array = pairs[rng.randi_range(0, pairs.size() - 1)]
		lines.append("%s culpa %s pelo fracasso." % [heroes[pr[0]].name, heroes[pr[1]].name])
		_change_logged(pr[0], pr[1], -2, -1, aff_changes)

	mission.status = "concluida"
	mission.result = {"outcome": result, "party": party.duplicate(), "day": day}
	dispatched_today += 1
	return {"mission": mission, "party": party, "score": sc, "outcome": result, "lines": lines, "affinity": aff_changes}


func _change_logged(a: String, b: String, dab: int, dba: int, log_out: Array) -> void:
	var before := pair_value(a, b)
	change_affinity(a, b, dab, dba)
	log_out.append({"a": a, "b": b, "before": before, "after": pair_value(a, b)})


## Avança o tempo (GDD §4 passo 7). Devolve as linhas do resumo.
func end_day() -> Array:
	var lines := []
	for id in hero_order:
		var h: Dictionary = heroes[id]
		if not h.busy and h.fatigue > 0:
			h.fatigue = max(0, h.fatigue - (2 if h.attrs.resistencia >= 7 else 1))
		h.busy = false
	for m in missions:
		if m.status == "aberta" and m.day <= day and day >= expires_on(m):
			m.status = "expirada"
			reputation = max(0, reputation - 1)
			lines.append("A missão \"%s\" expirou. A reputação da guilda caiu." % m.name)
	day += 1
	dispatched_today = 0
	for m in missions:
		if m.status == "aberta" and m.day == day:
			lines.append("Novo pedido no mural: \"%s\"." % m.name)
	return lines


func _load_json(path: String) -> Dictionary:
	var txt := FileAccess.get_file_as_string(path)
	var data = JSON.parse_string(txt)
	assert(data is Dictionary, "JSON inválido: " + path)
	return data
