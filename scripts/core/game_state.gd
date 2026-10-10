extends Node
## Estado da guilda: elenco, afinidades, missões, capítulos, ouro, upgrades, dia e reputação.
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

## Faixas de afinidade (GDD §5.4): [até, rótulo, modificador]
const BANDS := [
	[-3, "Conflito Aberto", -4],
	[-1, "Tensão Velada", -2],
	[0, "Neutros", 0],
	[2, "Camaradas", 2],
	[5, "Companheiros", 4],
	[8, "Laço Forte", 6],
	[10, "Dupla Lendária", 8],
]

## Eventos de limiar (GDD §5.4)
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
var pending_levelups := [] # subidas de nível aguardando escolha do jogador
var pending_moments := []  # momentos de personagem para a UI encenar (ruptura, saída); não é salvo

# RPG (níveis, equipamento, magias) — regras em HeroRPG
var classes_data := {}
var items_data := {}
var inventory := []        # Baú da Guilda: ids de itens
var recruits := []         # heróis que ainda vão entrar (recruit_chapter)

# Atos e saída por moral (GDD §5.7)
var act_index := 0
var ultimatum_data := {}
var ultimatums := []       # [{id, done}] — ultimatos abertos hoje
var promises := {}         # id -> último dia para ser despachado
var departed := []         # ids de quem deixou a guilda
var rng := RandomNumberGenerator.new()
var narration := {}
var book := {}

# Neglect (GDD §5.4) e moral por abandono (§5.7)
const NEGLECT_DAYS := 3        # dias sem missão juntos para perder 1 ponto
const NEGLECT_MIN := 3         # só pares a partir de +3 têm o que perder
const IDLE_MORALE_DAYS := 4    # dias sem ser despachado para perder 1 de moral
var initial_affinity := {}     # "a|b" -> valor inicial do par (piso do neglect)
var last_together := {}        # "a|b" -> último dia em que foram juntos (ou do último neglect)

# Eventos de bastidor
var backstage_data := {}
var backstage_today := []      # [{event, a, b, done}]
var backstage_once := []       # ids de eventos "once" já usados

# Capítulos (GDD §7)
var chapters_data := {}
var act := {}                  # ato atual
var chapter_index := 0         # índice em act.chapters
var chapter_start := 1         # dia global em que o capítulo começou
var chapter_state := "intro"   # intro | jogando | encerrado | fim_do_ato
var chapter_result := {}       # resultado do último capítulo encerrado
var flags := []                # flags narrativas ganhas nos capítulos

# Ouro e upgrades (GDD §5.12)
var upgrades_data := {}
var gold := 0
var upgrades_owned := []
var trained_today := false
var route_data := {}
var traits_data := {}
var expedition := {}         # expedição em andamento (Expedition), vazia fora do mapa
var pair_history := {}         # "a|b" -> [{day, mission, outcome}] (exibido com o Arquivo)

const AFF_PHRASES := {
	"Conflito Aberto": "Mal se olham", "Tensão Velada": "Desconfortáveis juntos",
	"Neutros": "Indiferentes", "Camaradas": "Se dão bem", "Companheiros": "Se cobrem em campo",
	"Laço Forte": "Inseparáveis", "Dupla Lendária": "Uma lenda juntos",
}


func _ready() -> void:
	new_game()


func new_game(seed_value: int = -1) -> void:
	if seed_value >= 0:
		rng.seed = seed_value
	else:
		rng.randomize()
	var hd: Dictionary = _load_json("res://data/heroes.json")
	classes_data = _load_json("res://data/classes.json")
	# JSON devolve números como float; níveis marcantes são comparados com int
	classes_data.xp.milestones = classes_data.xp.milestones.map(func(x): return int(x))
	items_data = _load_json("res://data/items.json")
	traits_data = _load_json("res://data/traits.json")
	inventory.clear()
	pending_levelups.clear()
	pending_moments.clear()
	recruits.clear()
	heroes.clear()
	hero_order.clear()
	for h in hd.heroes:
		var attrs := {}
		for k in ATTRS:
			attrs[k] = int(h.attrs[k])
		heroes[h.id] = {
			"id": h.id, "name": h.name, "archetype": h.archetype, "color": Color(h.color),
			"trait": h.trait, "attrs": attrs,
			# Ficha (GDD §8) — campos opcionais no JSON para permitir expansão
			"title": h.get("title", h.name), "class": h.get("class", ""), "race": h.get("race", ""),
			"level": int(h.get("level", 1)), "hp_max": int(h.get("hp_max", 8)),
			"proficiencies": h.get("proficiencies", []), "personality": h.get("personality", {}),
			"portrait": h.get("portrait", ""),
			"fatigue": 0, "morale": 6, "busy": false, "history": [],
		}
		heroes[h.id].hp = heroes[h.id].hp_max
		heroes[h.id].last_dispatch = 0
		heroes[h.id].joins_text = h.get("joins_text", "")
		HeroRPG.init_hero(self, heroes[h.id], h)
		if h.has("recruit_chapter"):
			recruits.append({"id": h.id, "chapter": h.recruit_chapter})
		else:
			hero_order.append(h.id)
	affinity.clear()
	for a in hd.affinity:
		affinity[a] = {}
		for b in hd.affinity[a]:
			affinity[a][b] = int(hd.affinity[a][b])
	bond_labels.clear()
	fired.clear()
	initial_affinity.clear()
	last_together.clear()
	for pr in ScoreCalc.pairs_of(hero_order):
		var key := pair_key(pr[0], pr[1])
		initial_affinity[key] = pair_value(pr[0], pr[1])
		last_together[key] = 0
	missions.clear()
	for m in _load_json("res://data/missions.json").missions:
		var mm: Dictionary = m.duplicate(true)
		mm.rel_day = int(mm.day)
		mm.day = 0
		mm.deadline = int(mm.deadline)
		mm.status = "futura"   # vira "aberta" quando o capítulo dela começa
		mm.result = {}
		missions.append(mm)
	route_data = _load_json("res://data/route.json")
	expedition = {}
	narration = _load_json("res://data/narration.json")
	book = _load_json("res://data/book.json")
	day = 1
	reputation = 0
	dispatched_today = 0
	pending_events.clear()
	backstage_data = _load_json("res://data/backstage.json")
	backstage_once.clear()
	upgrades_data = _load_json("res://data/upgrades.json")
	gold = int(upgrades_data.get("start_gold", 0))
	upgrades_owned.clear()
	trained_today = false
	pair_history.clear()
	chapters_data = _load_json("res://data/chapters.json")
	act_index = 0
	act = chapters_data.acts[0]
	ultimatum_data = _load_json("res://data/ultimatum.json")
	ultimatums.clear()
	promises.clear()
	departed.clear()
	flags.clear()
	chapter_result = {}
	_start_chapter(0)
	_roll_backstage()


# ---------- afinidade ----------

static func pair_key(a: String, b: String) -> String:
	return a + "|" + b if a < b else b + "|" + a


## Valor mecânico do par: o menor dos dois lados (GDD §5.4).
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
	return chapter_state == "fim_de_jogo"


func has_next_act() -> bool:
	return act_index + 1 < chapters_data.acts.size()


## Depois da tela de fim de ato: próximo ato ou fim de jogo.
func next_act() -> void:
	if has_next_act():
		act_index += 1
		act = chapters_data.acts[act_index]
		_start_chapter(0)
	else:
		chapter_state = "fim_de_jogo"


# ---------- capítulos ----------

func current_chapter() -> Dictionary:
	var id: String = act.chapters[chapter_index]
	for ch in chapters_data.chapters:
		if ch.id == id:
			return ch
	return {}


func chapter_end_day() -> int:
	return chapter_start + int(current_chapter().days) - 1


func chapter_day() -> int:
	return day - chapter_start + 1


func chapter_intro() -> Array:
	var ch := current_chapter()
	var lines: Array = ch.get("intro", []).duplicate()
	var extra: Dictionary = ch.get("intro_flags", {})
	for key in extra:
		var neg := String(key).begins_with("!")
		var flag := String(key).trim_prefix("!")
		if flags.has(flag) != neg:
			lines.append(extra[key])
	return lines


func _start_chapter(i: int) -> void:
	chapter_index = i
	chapter_start = day
	var ch := current_chapter()
	for r in recruits.duplicate():
		if r.chapter == ch.id:
			_recruit(r.id)
			recruits.erase(r)
	for m in missions:
		if ch.missions.has(m.id):
			m.status = "aberta"
			m.day = chapter_start + m.rel_day - 1
	chapter_state = "intro"


## Herói novo entra no elenco: pares novos começam a contar a partir de hoje.
func _recruit(id: String) -> void:
	for other in hero_order:
		var key := pair_key(id, other)
		initial_affinity[key] = pair_value(id, other)
		last_together[key] = day
	hero_order.append(id)
	heroes[id].last_dispatch = day


## Heróis que entraram neste capítulo (para a tela de abertura).
func chapter_recruits() -> Array:
	var out := []
	for id in hero_order:
		if heroes[id].joins_text != "" and heroes[id].last_dispatch == chapter_start and chapter_start > 1:
			out.append(id)
	return out


func begin_chapter() -> void:
	chapter_state = "jogando"


## Avalia o objetivo do capítulo que terminou.
func _close_chapter() -> void:
	var ch := current_chapter()
	var goal: Dictionary = ch.goal
	var ok := false
	match goal.type:
		"reputation":
			ok = reputation >= int(goal.min)
		"mission":
			for m in missions:
				if m.id == goal.mission:
					ok = m.status == "concluida" and m.result.outcome != "falha"
	if ok and ch.has("flag_success"):
		flags.append(ch.flag_success)
	chapter_result = {"chapter": ch, "success": ok, "text": ch.outro["success" if ok else "failure"]}
	chapter_state = "encerrado"


## Depois da tela de encerramento: próximo capítulo ou fim do ato.
func next_chapter() -> void:
	if chapter_index + 1 < act.chapters.size():
		_start_chapter(chapter_index + 1)
	else:
		chapter_state = "fim_do_ato"


# ---------- ouro e upgrades ----------

func has_upgrade(id: String) -> bool:
	return upgrades_owned.has(id)


func upgrade_block_reason(up: Dictionary) -> String:
	if has_upgrade(up.id):
		return "Construído"
	if reputation < int(up.rep):
		return "Requer Reputação %d" % int(up.rep)
	if gold < int(up.cost):
		return "Ouro insuficiente"
	return ""


func buy_upgrade(id: String) -> bool:
	for up in upgrades_data.upgrades:
		if up.id == id and upgrade_block_reason(up) == "":
			gold -= int(up.cost)
			upgrades_owned.append(id)
			return true
	return false


func mission_reward(m: Dictionary) -> int:
	return int(m.get("reward", upgrades_data.rewards.get(m.risk, 0)))


## Sem o Quadro de Relações, a afinidade só aparece como impressão (GDD §5.4).
func affinity_visible() -> bool:
	return has_upgrade("quadro")


func describe_aff(v: int) -> String:
	if affinity_visible():
		return "%+d  [%s]" % [v, band(v).label]
	return AFF_PHRASES[band(v).label]


func describe_change(before: int, after: int) -> String:
	if affinity_visible():
		return "afinidade %+d → %+d" % [before, after]
	if after > before:
		return "parecem mais próximos"
	if after < before:
		return "parecem mais distantes"
	return "nada mudou entre eles"


func can_train() -> bool:
	return has_upgrade("salao") and not trained_today


func train_reason(id: String) -> String:
	var h: Dictionary = heroes[id]
	if h.busy:
		return "Em missão"
	if h.hp <= 0:
		return "Incapacitado"
	if h.fatigue >= 1:
		return "Precisa estar Pronto"
	return ""


## Salão de Treinamento: +1 de afinidade para a dupla, os dois ficam Cansados.
func train_pair(a: String, b: String) -> Array:
	var before := pair_value(a, b)
	change_affinity(a, b, 1, 1)
	heroes[a].fatigue = 1
	heroes[b].fatigue = 1
	trained_today = true
	var xp: int = int(classes_data.xp.training)
	var extra := HeroRPG.gain_xp(self, a, xp) + HeroRPG.gain_xp(self, b, xp)
	return ["%s e %s treinam juntos até o sol se pôr. Os dois estão cansados — e %s." % [heroes[a].name, heroes[b].name, describe_change(before, pair_value(a, b))], "+%d de XP para cada um." % xp] + extra


func pair_missions(a: String, b: String) -> Array:
	return pair_history.get(pair_key(a, b), [])


## Modificador estilo D&D para a escala 1–10 do jogo: 1–2 → −2 · 3–4 → −1 · 5–6 → 0 · 7–8 → +1 · 9–10 → +2
static func attr_mod(v: int) -> int:
	return floori((v - 5) / 2.0)


## Status exibido (Livro e elenco).
func hero_status(id: String) -> String:
	var h: Dictionary = heroes[id]
	if h.busy:
		return "Em missão"
	if h.hp <= 0:
		return "Incapacitado"
	if h.fatigue >= 2:
		return "Exausto"
	if h.hp < h.hp_max:
		return "Ferido"
	if h.get("condition_kind", "") == "aflicao":
		return "Aflito"
	return FATIGUE_NAMES[h.fatigue]


## "" se pode ir; senão, o motivo.
func unavailable_reason(id: String, mission: Dictionary) -> String:
	var h: Dictionary = heroes[id]
	if h.busy:
		return "Em missão"
	if h.resting:
		return "Descansando"
	if h.hp <= 0:
		return "Incapacitado"
	if h.fatigue >= 2:
		return "Exausto"
	if h.morale <= 1 and not promises.has(id):
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
		elif tag.type == "requires_hero" and not party.has(tag.hero):
			out.append(tag.text)
		elif tag.type == "min_party" and party.size() < int(tag.min):
			out.append(tag.text)
	return out


## Descanso (dia inteiro): recupera fadiga, PV, magia e moral no fim do dia.
func set_resting(id: String, on: bool) -> void:
	var h: Dictionary = heroes[id]
	if not h.busy:
		h.resting = on


## prepared: {id_do_herói: id_da_magia} para os conjuradores da party.
## route: resultado do mapa de expedição {mod, gold, items, days} (vazio = despacho direto).
func dispatch(mission: Dictionary, party: Array, prepared: Dictionary = {}, route: Dictionary = {}) -> Dictionary:
	var prep := {}
	for id in prepared:
		if party.has(id) and prepared[id] != "" and heroes[id].slots > 0 and heroes[id].spells_known.has(prepared[id]):
			prep[id] = prepared[id]
	var luck := rng.randi_range(-2, 2)
	var sc := ScoreCalc.compute(self, mission, party, luck, prep, int(route.get("mod", 0)))
	var rpg_lines := HeroRPG.on_dispatch(self, party, prep)
	HeroRPG.consume_on_dispatch(self, party)
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
		var fat := 2 if (mission.risk in ["alto", "lendario"] or h.fatigue >= 1) else 1
		if HeroRPG.member_value(self, id, party, prep, "fatigue_resist") > 0:
			fat -= 1
		h.fatigue = max(h.fatigue, fat)
	for act in actions:
		if act.action == "Esforço Extra":
			heroes[act.a].fatigue = 2
			heroes[act.b].fatigue = 2

	# Dano (PV): custo fere um membro; falha fere todos (exceto o protegido)
	var hurt := []
	if result == "custo":
		hurt.append(party[rng.randi_range(0, party.size() - 1)])
	elif result == "falha":
		hurt = party.filter(func(id): return id != protected)
	var dmg: int = {"baixo": 1, "medio": 2, "alto": 3, "lendario": 4}[mission.risk]
	for id in hurt:
		var taken: int = max(0, dmg - HeroRPG.member_value(self, id, party, prep, "damage_reduction"))
		heroes[id].hp = max(0, heroes[id].hp - taken)
		if taken > 0:
			lines.append("%s voltou ferido (−%d PV)." % [heroes[id].name, taken])
		else:
			lines.append("%s levou um golpe, mas a proteção segurou." % heroes[id].name)

	# Moral e reputação
	var morale_delta: int = {"limpo": 1, "custo": 0, "falha": -1}[result]
	for id in party:
		var h: Dictionary = heroes[id]
		var dm := morale_delta
		if party.size() == 1 and result != "limpo":
			dm -= 1
		h.morale = clampi(h.morale + dm, 0, 10)
		h.history.append({"day": day, "mission": mission.name, "result": result})
		h.last_dispatch = day
	reputation = max(0, reputation + {"limpo": 2, "custo": 1, "falha": -1}[result])
	var earned: int = {"limpo": mission_reward(mission), "custo": mission_reward(mission) / 2, "falha": 0}[result]
	gold += earned
	if earned > 0:
		lines.append("A guilda recebe %d de ouro." % earned)
	# Saque da rota: inteiro no sucesso, metade no custo; na falha fica pelo caminho
	if not route.is_empty():
		var rg: int = {"limpo": int(route.gold), "custo": int(route.gold) / 2, "falha": 0}[result]
		gold += rg
		if rg > 0:
			lines.append("Saque da rota: %d de ouro." % rg)
		if result == "falha":
			if int(route.gold) > 0 or not route.items.is_empty():
				lines.append("Na fuga, o saque da rota ficou para trás.")
		else:
			for it in route.items:
				inventory.append(it)
				lines.append("Saque da rota: %s vai para o Baú." % HeroRPG.item(self, it).name)
		if int(route.days) > 0:
			for id in party:
				heroes[id].away_until = day + int(route.days)
			lines.append("A viagem atrasou: o grupo fica fora da guilda por mais %d dia(s)." % int(route.days))

	for pr in ScoreCalc.pairs_of(party):
		var key := pair_key(pr[0], pr[1])
		last_together[key] = day
		if not pair_history.has(key):
			pair_history[key] = []
		pair_history[key].append({"day": day, "mission": mission.name, "outcome": result})

	# Afinidade (GDD §5.4)
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

	var fx: Dictionary = mission.get("effects", {}).get(result, {})
	for hid in fx.get("morale", {}):
		if heroes.has(hid):
			heroes[hid].morale = clampi(heroes[hid].morale + int(fx.morale[hid]), 0, 10)
	if fx.has("flag") and not flags.has(fx.flag):
		flags.append(fx.flag)
	if fx.has("text"):
		lines.append(fx.text)
	for id in party:
		promises.erase(id)

	mission.status = "concluida"
	mission.result = {"outcome": result, "party": party.duplicate(), "day": day}
	lines = rpg_lines + lines
	lines.append_array(HeroRPG.after_mission(self, mission, party, prep, result))
	lines.append_array(Mind.after_mission(self, mission, party, prep, result))
	dispatched_today += 1
	return {"mission": mission, "party": party, "score": sc, "outcome": result, "lines": lines, "affinity": aff_changes, "prepared": prep}


## Narração do Mapa Mágico: uma linha por waypoint (GDD §5.9).
func map_narration(res: Dictionary) -> Array:
	var m: Dictionary = res.mission
	var party: Array = res.party
	var names := ", ".join(party.map(func(id): return heroes[id].name))
	var lider: String = heroes[party[0]].name
	var lines := []
	lines.append(_pick(narration.start))
	lines.append(_pick(narration.biomes.get(m.get("biome", "estrada"), narration.biomes.estrada)))
	var third: String = _pick(narration.outcome[res.outcome])
	if res.score.hidden != 0:
		third = String(narration.hidden).replace("{heroi}", heroes[m.hidden.hero].name) + " " + third
	lines.append(third)
	return lines.map(func(l): return String(l).replace("{party}", names).replace("{lider}", lider))


func _pick(arr: Array) -> String:
	return arr[rng.randi_range(0, arr.size() - 1)]


func _change_logged(a: String, b: String, dab: int, dba: int, log_out: Array) -> void:
	var before := pair_value(a, b)
	change_affinity(a, b, dab, dba)
	log_out.append({"a": a, "b": b, "before": before, "after": pair_value(a, b)})


## Avança o tempo (GDD §4 passo 9). Devolve as linhas do resumo.
func end_day() -> Array:
	var lines := []
	var infirmary := 1 if has_upgrade("enfermaria") else 0
	for id in hero_order:
		var h: Dictionary = heroes[id]
		if h.rest_request and not h.resting:
			h.morale = max(0, h.morale - 1)
			lines.append("%s pediu descanso e não foi atendido(a) (moral −1)." % h.name)
		lines.append_array(Mind.end_day(self, id, h.resting, not h.busy))
		if h.resting:
			# Descanso de verdade: tudo volta, inclusive a magia
			h.fatigue = 0
			h.hp = min(h.hp_max, h.hp + max(1, h.hp_max / 2) * (1 + infirmary))
			h.slots = HeroRPG.max_slots(self, id)
			h.morale = min(10, h.morale + 1)
			h.resting = false
		elif not h.busy:
			if h.fatigue > 0:
				h.fatigue = max(0, h.fatigue - (2 if h.attrs.resistencia >= 7 else 1) - infirmary)
			h.hp = min(h.hp_max, h.hp + max(1, h.hp_max / 4) * (1 + infirmary))
		h.busy = int(h.get("away_until", 0)) > day   # ainda na estrada
	trained_today = false
	var chapter_over: bool = day >= chapter_end_day() and chapter_state in ["intro", "jogando"]
	for m in missions:
		if m.status == "aberta" and m.day <= day and (day >= expires_on(m) or chapter_over):
			m.status = "expirada"
			reputation = max(0, reputation - 1)
			lines.append("A missão \"%s\" expirou. A reputação da guilda caiu." % m.name)
	lines.append_array(_apply_neglect())
	lines.append_array(_process_departures())
	day += 1
	dispatched_today = 0
	if chapter_over:
		_close_chapter()
	_roll_backstage()
	for id in hero_order:
		var h: Dictionary = heroes[id]
		h.rest_request = not h.busy and (h.fatigue >= 2 or h.hp <= h.hp_max / 3 or h.get("condition_kind", "") == "aflicao")   # na estrada não dá para pedir
		if h.rest_request:
			lines.append("%s pede um dia de descanso." % h.name)
	for id in hero_order:
		if heroes[id].morale <= int(ultimatum_data.threshold) and not promises.has(id):
			ultimatums.append({"id": id, "done": false})
			lines.append("⚠ %s ameaça deixar a guilda!" % heroes[id].name)
	if not backstage_today.is_empty():
		lines.append("Há movimento nos bastidores da guilda (%d cena(s))." % backstage_today.size())
	for m in missions:
		if m.status == "aberta" and m.day == day:
			lines.append("Novo pedido no mural: \"%s\"." % m.name)
	return lines


# ---------- saída por moral baixa (GDD §5.7) ----------

func open_ultimatums() -> Array:
	return ultimatums.filter(func(u): return not u.done)


func ultimatum_text(id: String, text: String) -> String:
	return text.replace("{a}", heroes[id].name)


func ultimatum_block_reason(choice: Dictionary) -> String:
	if gold < int(choice.get("cost", 0)):
		return "Ouro insuficiente"
	return ""


func resolve_ultimatum(u: Dictionary, choice: Dictionary) -> Array:
	var id: String = u.id
	var h: Dictionary = heroes[id]
	var lines := [ultimatum_text(id, choice.result)]
	u.done = true
	if choice.get("leave", false):
		lines.append_array(_depart(id))
		return lines
	gold -= int(choice.get("cost", 0))
	h.morale = clampi(h.morale + int(choice.get("morale", 0)), 0, 10)
	if choice.get("rest", false):
		set_resting(id, true)
	if choice.has("promise"):
		promises[id] = day + int(choice.promise) - 1
	return lines


## Ultimatos ignorados e promessas vencidas viram partida.
func _process_departures() -> Array:
	var lines := []
	for u in ultimatums:
		if not u.done and hero_order.has(u.id):
			lines.append("%s cansou de esperar uma resposta." % heroes[u.id].name)
			lines.append_array(_depart(u.id))
	ultimatums.clear()
	for id in promises.keys():
		if day >= int(promises[id]) and hero_order.has(id):
			lines.append("%s esperou a missão prometida. Ela não veio." % heroes[id].name)
			lines.append_array(_depart(id))
	return lines


func _depart(id: String) -> Array:
	if not hero_order.has(id):
		return []
	var h: Dictionary = heroes[id]
	for slot in HeroRPG.SLOTS:
		HeroRPG.unequip(self, id, slot)
	hero_order.erase(id)
	departed.append(id)
	promises.erase(id)
	h.resting = false
	var lines := ["%s deixou a Guilda do Corvo Cinzento. O equipamento ficou no Baú." % h.name]
	pending_moments.append({"type": "saida", "id": id, "text": lines[0]})
	# Irmandade — "Até o Fim" (GDD §5.5): o irmão de armas parte junto
	for other in hero_order.duplicate():
		if bond_label(id, other) == "Irmandade":
			lines.append("Até o Fim: %s não fica onde %s não está." % [heroes[other].name, h.name])
			lines.append_array(_depart(other))
	return lines


# ---------- neglect ----------

## Aplicado no fim do dia, antes de virar. Devolve linhas para o resumo.
func _apply_neglect() -> Array:
	var lines := []
	for pr in ScoreCalc.pairs_of(hero_order):
		var a: String = pr[0]
		var b: String = pr[1]
		var key := pair_key(a, b)
		var v := pair_value(a, b)
		if day - int(last_together[key]) < NEGLECT_DAYS:
			continue
		last_together[key] = day
		if v < NEGLECT_MIN or v <= int(initial_affinity[key]):
			continue
		var before := v
		change_affinity(a, b, -1 if affinity[a][b] > initial_affinity[key] else 0, -1 if affinity[b][a] > initial_affinity[key] else 0)
		if pair_value(a, b) < before:
			lines.append("%s e %s quase não se falam desde a última missão juntos (%s)." % [heroes[a].name, heroes[b].name, describe_change(before, pair_value(a, b))])
	for id in hero_order:
		var h: Dictionary = heroes[id]
		if day - int(h.last_dispatch) >= IDLE_MORALE_DAYS and h.morale > 0:
			h.morale -= 1
			h.last_dispatch = day
			lines.append("%s se sente esquecido(a) na guilda (moral −1)." % h.name)
	return lines


func days_apart(a: String, b: String) -> int:
	return day - int(last_together[pair_key(a, b)])


# ---------- eventos de bastidor ----------

func _roll_backstage() -> void:
	backstage_today.clear()
	var used := []
	var events: Array = backstage_data.get("events", [])
	for _i in int(backstage_data.get("per_day", 2)):
		var options := []   # [peso, evento, a, b]
		for ev in events:
			if ev.get("once", false) and backstage_once.has(ev.id):
				continue
			for pr in _candidate_pairs(ev):
				if used.has(pr[0]) or used.has(pr[1]):
					continue
				options.append([float(ev.get("weight", 1)), ev, pr[0], pr[1]])
		if options.is_empty():
			break
		var total := 0.0
		for o in options:
			total += o[0]
		var roll := rng.randf() * total
		for o in options:
			roll -= o[0]
			if roll <= 0.0:
				backstage_today.append({"event": o[1], "a": o[2], "b": o[3], "done": false})
				used.append(o[2])
				used.append(o[3])
				if o[1].get("once", false):
					backstage_once.append(o[1].id)
				break


func _candidate_pairs(ev: Dictionary) -> Array:
	var out := []
	var fixed: Array = ev.get("heroes", [null, null])
	for a in hero_order:
		for b in hero_order:
			if a == b:
				continue
			if fixed[0] != null and fixed[0] != a:
				continue
			if fixed[1] != null and fixed[1] != b:
				continue
			if fixed[0] == null and fixed[1] == null and a > b:
				continue   # par sem ordem: considera uma vez só
			if heroes[a].hp <= 0 or heroes[b].hp <= 0:
				continue
			var v := pair_value(a, b)
			if ev.has("min") and v < int(ev.min):
				continue
			if ev.has("chapters") and not ev.chapters.has(current_chapter().id):
				continue
			if ev.has("requires_flag") and not flags.has(ev.requires_flag):
				continue
			if ev.has("max") and v > int(ev.max):
				continue
			out.append([a, b])
	return out


func backstage_text(bs: Dictionary, text: String) -> String:
	return text.replace("{a}", heroes[bs.a].name).replace("{b}", heroes[bs.b].name)


## Aplica a escolha e devolve as linhas de resultado.
func resolve_backstage(bs: Dictionary, choice: Dictionary) -> Array:
	var a: String = bs.a
	var b: String = bs.b
	var lines := [backstage_text(bs, choice.get("result", ""))]
	var aff: Array = choice.get("aff", [0, 0])
	if int(aff[0]) != 0 or int(aff[1]) != 0:
		var before := pair_value(a, b)
		change_affinity(a, b, int(aff[0]), int(aff[1]))
		lines.append("%s ↔ %s: %s" % [heroes[a].name, heroes[b].name, describe_change(before, pair_value(a, b))])
	for who in choice.get("morale", {}):
		var id: String = a if who == "a" else b
		var d := int(choice.morale[who])
		heroes[id].morale = clampi(heroes[id].morale + d, 0, 10)
		lines.append("%s: moral %+d" % [heroes[id].name, d])
	for who in choice.get("fatigue", {}):
		var id: String = a if who == "a" else b
		heroes[id].fatigue = clampi(heroes[id].fatigue + int(choice.fatigue[who]), 0, 2)
		lines.append("%s ficou %s." % [heroes[id].name, FATIGUE_NAMES[heroes[id].fatigue].to_lower()])
	bs.done = true
	return lines


# ---------- salvar / carregar ----------

const SAVE_VERSION := 1
const SAVE_SLOTS := ["auto", "1", "2", "3"]
## Estado mutável. Dados estáticos (JSON de conteúdo) são recarregados por new_game.
const SAVE_KEYS := [
	"heroes", "hero_order", "affinity", "bond_labels", "fired", "missions",
	"day", "reputation", "dispatched_today", "pending_events", "pending_levelups",
	"inventory", "recruits", "act_index", "chapter_index", "chapter_start",
	"chapter_state", "chapter_result", "flags", "gold", "upgrades_owned",
	"trained_today", "pair_history", "initial_affinity", "last_together",
	"backstage_today", "backstage_once", "ultimatums", "promises", "departed",
]


static func save_path(slot: String) -> String:
	return "user://saves/save_%s.sav" % slot


## Salva com var_to_str: preserva int, float e Color (JSON transformaria int em float).
func save_game(slot: String) -> bool:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://saves"))
	var state := {}
	for k in SAVE_KEYS:
		state[k] = get(k)
	var data := {
		"version": SAVE_VERSION,
		"meta": {
			"act": act.title, "chapter": current_chapter().get("title", ""),
			"chapter_day": chapter_day(), "reputation": reputation, "gold": gold,
			"saved_at": Time.get_datetime_string_from_system(false, true),
		},
		"rng_state": rng.state,
		"state": state,
	}
	var f := FileAccess.open(save_path(slot), FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(var_to_str(data))
	return true


func load_game(slot: String) -> bool:
	if not FileAccess.file_exists(save_path(slot)):
		return false
	var data = str_to_var(FileAccess.get_file_as_string(save_path(slot)))
	if not (data is Dictionary) or int(data.get("version", 0)) != SAVE_VERSION:
		return false
	new_game()   # recarrega os dados estáticos
	for k in SAVE_KEYS:
		if data.state.has(k):
			set(k, data.state[k])
	act = chapters_data.acts[act_index]
	rng.state = data.rng_state
	for id in heroes:
		Mind.ensure(heroes[id])   # saves anteriores à v0.9
	return true


func save_meta(slot: String) -> Dictionary:
	if not FileAccess.file_exists(save_path(slot)):
		return {}
	var data = str_to_var(FileAccess.get_file_as_string(save_path(slot)))
	if not (data is Dictionary) or int(data.get("version", 0)) != SAVE_VERSION:
		return {}
	return data.meta


func has_any_save() -> bool:
	for s in SAVE_SLOTS:
		if not save_meta(s).is_empty():
			return true
	return false


## Save mais recente (para "Continuar").
func latest_save() -> String:
	var best := ""
	var best_at := ""
	for s in SAVE_SLOTS:
		var m := save_meta(s)
		if not m.is_empty() and String(m.saved_at) > best_at:
			best = s
			best_at = m.saved_at
	return best


# ---------- epílogo (finais variáveis) ----------

func _ending_matches(c: Dictionary, hero_id: String = "") -> bool:
	for f in c.get("all_flags", []):
		if not flags.has(f):
			return false
	if c.has("any_flags") and not c.any_flags.any(func(f): return flags.has(f)):
		return false
	for f in c.get("no_flags", []):
		if flags.has(f):
			return false
	if c.has("min_reputation") and reputation < int(c.min_reputation):
		return false
	if c.has("max_departed") and departed.size() > int(c.max_departed):
		return false
	if hero_id != "":
		if c.has("departed") and bool(c.departed) != departed.has(hero_id):
			return false
		if c.has("min_morale") and heroes[hero_id].morale < int(c.min_morale):
			return false
		if c.has("bond"):
			var found := false
			for other in heroes:
				if other != hero_id and bond_label(hero_id, other) == c.bond:
					found = true
			if not found:
				return false
	return true


## {title, text, heroes: [{id, text}], bonds: [texto]}
func epilogue() -> Dictionary:
	var ed: Dictionary = _load_json("res://data/endings.json")
	var out := {"title": "", "text": "", "heroes": [], "bonds": []}
	for e in ed.endings:
		if _ending_matches(e):
			out.title = e.title
			out.text = e.text
			break
	var everyone: Array = hero_order + departed
	for id in everyone:
		for c in ed.heroes.get(id, []):
			if _ending_matches(c, id):
				out.heroes.append({"id": id, "text": c.text})
				break
	for key in bond_labels:
		var t: String = ed.bonds.get(bond_labels[key], "")
		if t != "":
			var ids: PackedStringArray = key.split("|")
			out.bonds.append(t.replace("{a}", heroes[ids[0]].name).replace("{b}", heroes[ids[1]].name))
	return out


func _load_json(path: String) -> Dictionary:
	var txt := FileAccess.get_file_as_string(path)
	var data = JSON.parse_string(txt)
	assert(data is Dictionary, "JSON inválido: " + path)
	return data
