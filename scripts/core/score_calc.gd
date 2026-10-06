class_name ScoreCalc
## Cálculo de score da missão (GDD §5.6).
## Score = Base + Cobertura + Afinidade + Vínculo + Oculto + Sorte

const W_PRIMARY := 0.65
const W_SECONDARY := 0.35
const TIRED_FACTOR := 0.6
const COVERAGE_MIN := 7
const COVERAGE_MAX := 2

## [falha abaixo de, limpo a partir de]
const THRESHOLDS := {
	"baixo": [6, 9],
	"medio": [8, 11],
	"alto": [10, 13],
	"lendario": [13, 16],
}

const BOND_BONUS := {
	"Esforço Extra": 2,
	"Sincronia Perfeita": 3,
}


## Calcula o score. Se `luck` for null, devolve o estimado (sem sorte).
static func compute(gs, mission: Dictionary, party: Array, luck = null) -> Dictionary:
	var p: String = mission.primary
	var s: String = mission.secondary
	var actions: Array = gs.active_bond_actions(party)

	var attrs := {}
	for id in party:
		attrs[id] = gs.heroes[id].attrs.duplicate()

	# Impulso do Mentor: o mais fraco do par ganha +3 nos atributos da missão
	for act in actions:
		if act.action == "Impulso do Mentor":
			var a: String = act.a
			var b: String = act.b
			var weaker := a if _weighted(attrs[a], p, s) < _weighted(attrs[b], p, s) else b
			attrs[weaker][p] += 3
			attrs[weaker][s] += 3

	var values := {}
	for id in party:
		var v := _weighted(attrs[id], p, s)
		if gs.heroes[id].fatigue == 1:
			v *= TIRED_FACTOR
		values[id] = v

	# Competição: os dois valem o melhor dos dois
	for act in actions:
		if act.action == "Competição":
			var best: float = max(values[act.a], values[act.b])
			values[act.a] = best
			values[act.b] = best

	var base := 0.0
	for id in party:
		base += values[id]
	base /= max(1, party.size())

	var coverage := 0
	for id in party:
		if attrs[id][p] >= COVERAGE_MIN:
			coverage += 1
	coverage = min(coverage, COVERAGE_MAX)

	var affinity := 0.0
	var pairs := pairs_of(party)
	if pairs.size() > 0:
		for pr in pairs:
			affinity += gs.band(gs.pair_value(pr[0], pr[1])).mod
		affinity /= pairs.size()

	var bond := 0
	for act in actions:
		bond += BOND_BONUS.get(act.action, 0)

	var hidden := 0
	if mission.has("hidden") and party.has(mission.hidden.hero):
		hidden = int(mission.hidden.mod)

	var total := base + coverage + affinity + bond + hidden
	if luck != null:
		total += luck
	return {
		"base": base, "coverage": coverage, "affinity": affinity, "bond": bond,
		"hidden": hidden, "luck": luck, "total": total, "actions": actions,
	}


static func outcome(total: float, risk: String) -> String:
	var t: Array = THRESHOLDS[risk]
	if total < t[0]:
		return "falha"
	if total < t[1]:
		return "custo"
	return "limpo"


static func pairs_of(party: Array) -> Array:
	var out := []
	for i in party.size():
		for j in range(i + 1, party.size()):
			out.append([party[i], party[j]])
	return out


static func _weighted(a: Dictionary, p: String, s: String) -> float:
	return W_PRIMARY * a[p] + W_SECONDARY * a[s]
