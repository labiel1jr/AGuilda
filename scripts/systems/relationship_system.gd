class_name Relations
## Relações entre aventureiros: afinidade (vale o menor lado), faixas, vínculos e Ações de Vínculo,
## descrição para a UI (com ou sem Quadro), treino de duplas e neglect (GDD §5.4, §5.5).
## Funções estáticas sobre o estado (gs: GuildState, o autoload GameState).


## Valor mecânico do par: o menor dos dois lados (GDD §5.4).
static func pair_value(gs: GuildState, a: String, b: String) -> int:
	return min(gs.affinity[a][b], gs.affinity[b][a])


static func band(gs: GuildState, v: int) -> Dictionary:
	for bd in GuildState.BANDS:
		if v <= bd[0]:
			return {"label": bd[1], "mod": bd[2]}
	return {"label": GuildState.BANDS[-1][1], "mod": GuildState.BANDS[-1][2]}


static func bond_label(gs: GuildState, a: String, b: String) -> String:
	return gs.bond_labels.get(GuildState.pair_key(a, b), "")


static func active_bond_actions(gs: GuildState, party: Array) -> Array:
	var out := []
	for pr in ScoreCalc.pairs_of(party):
		var label := Relations.bond_label(gs, pr[0], pr[1])
		if GuildState.BOND_ACTIONS.has(label) and Relations.pair_value(gs, pr[0], pr[1]) >= GuildState.BOND_MIN:
			out.append({"a": pr[0], "b": pr[1], "label": label, "action": GuildState.BOND_ACTIONS[label]})
	return out


## Altera a afinidade nos dois sentidos e enfileira eventos de limiar.
static func change_affinity(gs: GuildState, a: String, b: String, delta_ab: int, delta_ba: int) -> void:
	var before := Relations.pair_value(gs, a, b)
	gs.affinity[a][b] = clampi(gs.affinity[a][b] + delta_ab, GuildState.AFF_MIN, GuildState.AFF_MAX)
	gs.affinity[b][a] = clampi(gs.affinity[b][a] + delta_ba, GuildState.AFF_MIN, GuildState.AFF_MAX)
	var after := Relations.pair_value(gs, a, b)
	var key := GuildState.pair_key(a, b)
	var done: Array = gs.fired.get(key, [])
	for t in GuildState.THRESHOLD_EVENTS:
		if done.has(t):
			continue
		var crossed: bool = (t > 0 and before < t and after >= t) or (t < 0 and before > t and after <= t)
		if crossed:
			done.append(t)
			gs.pending_events.append({"a": a, "b": b, "threshold": t})
	gs.fired[key] = done


static func choose_bond_label(gs: GuildState, event: Dictionary, label: String) -> void:
	gs.bond_labels[GuildState.pair_key(event.a, event.b)] = label


## Sem o Quadro de Relações, a afinidade só aparece como impressão (GDD §5.4).
static func affinity_visible(gs: GuildState) -> bool:
	return Economy.has_upgrade(gs, "quadro")


static func describe_aff(gs: GuildState, v: int) -> String:
	if Relations.affinity_visible(gs):
		return "%+d  [%s]" % [v, Relations.band(gs, v).label]
	return GuildState.AFF_PHRASES[Relations.band(gs, v).label]


static func describe_change(gs: GuildState, before: int, after: int) -> String:
	if Relations.affinity_visible(gs):
		return "afinidade %+d → %+d" % [before, after]
	if after > before:
		return "parecem mais próximos"
	if after < before:
		return "parecem mais distantes"
	return "nada mudou entre eles"


static func can_train(gs: GuildState) -> bool:
	return Economy.has_upgrade(gs, "salao") and not gs.trained_today


static func train_reason(gs: GuildState, id: String) -> String:
	var h: Dictionary = gs.heroes[id]
	if h.busy:
		return "Em missão"
	if h.hp <= 0:
		return "Incapacitado"
	if h.fatigue >= 1:
		return "Precisa estar Pronto"
	return ""


## Salão de Treinamento: +1 de afinidade para a dupla, os dois ficam Cansados.
static func train_pair(gs: GuildState, a: String, b: String) -> Array:
	var before := Relations.pair_value(gs, a, b)
	Relations.change_affinity(gs, a, b, 1, 1)
	gs.heroes[a].fatigue = 1
	gs.heroes[b].fatigue = 1
	gs.trained_today = true
	var xp: int = int(gs.classes_data.xp.training)
	var extra := HeroRPG.gain_xp(gs, a, xp) + HeroRPG.gain_xp(gs, b, xp)
	return ["%s e %s treinam juntos até o sol se pôr. Os dois estão cansados — e %s." % [gs.heroes[a].name, gs.heroes[b].name, Relations.describe_change(gs, before, Relations.pair_value(gs, a, b))], "+%d de XP para cada um." % xp] + extra


static func pair_missions(gs: GuildState, a: String, b: String) -> Array:
	return gs.pair_history.get(GuildState.pair_key(a, b), [])


static func change_logged(gs: GuildState, a: String, b: String, dab: int, dba: int, log_out: Array) -> void:
	var before := Relations.pair_value(gs, a, b)
	Relations.change_affinity(gs, a, b, dab, dba)
	log_out.append({"a": a, "b": b, "before": before, "after": Relations.pair_value(gs, a, b)})


## Aplicado no fim do dia, antes de virar. Devolve linhas para o resumo.
static func apply_neglect(gs: GuildState) -> Array:
	var lines := []
	for pr in ScoreCalc.pairs_of(gs.hero_order):
		var a: String = pr[0]
		var b: String = pr[1]
		var key := GuildState.pair_key(a, b)
		var v := Relations.pair_value(gs, a, b)
		if gs.day - int(gs.last_together[key]) < GuildState.NEGLECT_DAYS:
			continue
		gs.last_together[key] = gs.day
		if v < GuildState.NEGLECT_MIN or v <= int(gs.initial_affinity[key]):
			continue
		var before := v
		Relations.change_affinity(gs, a, b, -1 if gs.affinity[a][b] > gs.initial_affinity[key] else 0, -1 if gs.affinity[b][a] > gs.initial_affinity[key] else 0)
		if Relations.pair_value(gs, a, b) < before:
			lines.append("%s e %s quase não se falam desde a última missão juntos (%s)." % [gs.heroes[a].name, gs.heroes[b].name, Relations.describe_change(gs, before, Relations.pair_value(gs, a, b))])
	for id in gs.hero_order:
		var h: Dictionary = gs.heroes[id]
		if gs.day - int(h.last_dispatch) >= GuildState.IDLE_MORALE_DAYS and h.morale > 0:
			h.morale -= 1
			h.last_dispatch = gs.day
			lines.append("%s se sente esquecido(a) na guilda (moral −1)." % h.name)
	return lines


static func days_apart(gs: GuildState, a: String, b: String) -> int:
	return gs.day - int(gs.last_together[GuildState.pair_key(a, b)])
