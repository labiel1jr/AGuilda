extends Node
class_name GuildState
## Estado da guilda: elenco, afinidades, missões, capítulos, ouro, melhorias, dia e reputação.
## Autoload "GameState" (classe GuildState). Guarda o estado e orquestra o jogo (new_game, end_day);
## as regras ficam nos sistemas estáticos de scripts/systems/ (Relations, Missions, Chapters, Economy,
## Departures, Backstage, SaveSystem, Endings) e em scripts/core/ (ScoreCalc, HeroRPG, Expedition, Mind).
## A seção "API pública" no fim repassa para os sistemas, para a UI e os testes chamarem gs.<função>.

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
var result_story_data := {}
var town_esteem := 3           # Estima da cidade pela guilda (Town)
var upgrades_revealed := []     # melhorias ocultas já reveladas por bastidores   # textos do resultado contado (data/result_story.json)
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
	result_story_data = _load_json("res://data/result_story.json")
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
		initial_affinity[key] = Relations.pair_value(self, pr[0], pr[1])
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
	town_esteem = int(upgrades_data.get("town", {}).get("start_esteem", 3))
	upgrades_revealed = []
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
	Chapters.start_chapter(self, 0)
	Backstage.roll_backstage(self)


# ---------- afinidade ----------

static func pair_key(a: String, b: String) -> String:
	return a + "|" + b if a < b else b + "|" + a


# ---------- missões ----------


# ---------- capítulos ----------


# ---------- ouro e upgrades ----------


## Modificador estilo D&D para a escala 1–10 do jogo: 1–2 → −2 · 3–4 → −1 · 5–6 → 0 · 7–8 → +1 · 9–10 → +2
static func attr_mod(v: int) -> int:
	return floori((v - 5) / 2.0)


## Avança o tempo (GDD §4 passo 9). Devolve as linhas do resumo.
func end_day() -> Array:
	var lines := []
	var infirmary := 1 if Economy.has_upgrade(self, "enfermaria") else 0
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
	var chapter_over: bool = day >= Chapters.chapter_end_day(self) and chapter_state in ["intro", "jogando"]
	for m in missions:
		if m.status == "aberta" and m.day <= day and (day >= Missions.expires_on(self, m) or chapter_over):
			m.status = "expirada"
			reputation = max(0, reputation - 1)
			Town.change_esteem(self, -1)   # quem pediu ajuda e não foi atendido conta para os vizinhos
			lines.append("A missão \"%s\" expirou. A reputação da guilda caiu." % m.name)
	lines.append_array(Relations.apply_neglect(self))
	lines.append_array(Departures.process_departures(self))
	day += 1
	dispatched_today = 0
	if chapter_over:
		Chapters.close_chapter(self)
	Backstage.roll_backstage(self)
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


# ---------- neglect ----------


# ---------- eventos de bastidor ----------


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
	"town_esteem", "upgrades_revealed",
]


static func save_path(slot: String) -> String:
	return "user://saves/save_%s.sav" % slot


# ---------- epílogo (finais variáveis) ----------


# =========== API pública: repasses para os sistemas ===========

# ---------- Relations (scripts/systems/relationship_system.gd) ----------

## Valor mecânico do par: o menor dos dois lados (GDD §5.4).
func pair_value(a: String, b: String) -> int:
	return Relations.pair_value(self, a, b)


func band(v: int) -> Dictionary:
	return Relations.band(self, v)


func bond_label(a: String, b: String) -> String:
	return Relations.bond_label(self, a, b)


func active_bond_actions(party: Array) -> Array:
	return Relations.active_bond_actions(self, party)


## Altera a afinidade nos dois sentidos e enfileira eventos de limiar.
func change_affinity(a: String, b: String, delta_ab: int, delta_ba: int) -> void:
	Relations.change_affinity(self, a, b, delta_ab, delta_ba)


func choose_bond_label(event: Dictionary, label: String) -> void:
	Relations.choose_bond_label(self, event, label)


## Sem o Quadro de Relações, a afinidade só aparece como impressão (GDD §5.4).
func affinity_visible() -> bool:
	return Relations.affinity_visible(self)


func describe_aff(v: int) -> String:
	return Relations.describe_aff(self, v)


func describe_change(before: int, after: int) -> String:
	return Relations.describe_change(self, before, after)


func can_train() -> bool:
	return Relations.can_train(self)


func train_reason(id: String) -> String:
	return Relations.train_reason(self, id)


## Salão de Treinamento: +1 de afinidade para a dupla, os dois ficam Cansados.
func train_pair(a: String, b: String) -> Array:
	return Relations.train_pair(self, a, b)


func pair_missions(a: String, b: String) -> Array:
	return Relations.pair_missions(self, a, b)


func days_apart(a: String, b: String) -> int:
	return Relations.days_apart(self, a, b)


# ---------- Missions (scripts/systems/mission_system.gd) ----------

func slots() -> int:
	return Missions.slots(self)


func free_slots() -> int:
	return Missions.free_slots(self)


func expires_on(m: Dictionary) -> int:
	return Missions.expires_on(self, m)


func board() -> Array:
	return Missions.board(self)


## Status exibido (Livro e elenco).
func hero_status(id: String) -> String:
	return Missions.hero_status(self, id)


## "" se pode ir; senão, o motivo.
func unavailable_reason(id: String, mission: Dictionary) -> String:
	return Missions.unavailable_reason(self, id, mission)


## Requisitos de composição não atendidos.
func unmet_tags(mission: Dictionary, party: Array) -> Array:
	return Missions.unmet_tags(self, mission, party)


## Descanso (dia inteiro): recupera fadiga, PV, magia e moral no fim do dia.
func set_resting(id: String, on: bool) -> void:
	Missions.set_resting(self, id, on)


## prepared: {id_do_herói: id_da_magia} para os conjuradores da party.
## route: resultado do mapa de expedição {mod, gold, items, days} (vazio = despacho direto).
func dispatch(mission: Dictionary, party: Array, prepared: Dictionary = {}, route: Dictionary = {}) -> Dictionary:
	return Missions.dispatch(self, mission, party, prepared, route)


## Narração do Mapa Mágico: uma linha por waypoint (GDD §5.9).
func map_narration(res: Dictionary) -> Array:
	return Missions.map_narration(self, res)


# ---------- Chapters (scripts/systems/chapter_system.gd) ----------

func is_over() -> bool:
	return Chapters.is_over(self)


func has_next_act() -> bool:
	return Chapters.has_next_act(self)


## Depois da tela de fim de ato: próximo ato ou fim de jogo.
func next_act() -> void:
	Chapters.next_act(self)


func current_chapter() -> Dictionary:
	return Chapters.current_chapter(self)


func chapter_end_day() -> int:
	return Chapters.chapter_end_day(self)


func chapter_day() -> int:
	return Chapters.chapter_day(self)


func chapter_intro() -> Array:
	return Chapters.chapter_intro(self)


## Heróis que entraram neste capítulo (para a tela de abertura).
func chapter_recruits() -> Array:
	return Chapters.chapter_recruits(self)


func begin_chapter() -> void:
	Chapters.begin_chapter(self)


## Depois da tela de encerramento: próximo capítulo ou fim do ato.
func next_chapter() -> void:
	Chapters.next_chapter(self)


# ---------- Economy (scripts/systems/economy_system.gd) ----------

func has_upgrade(id: String) -> bool:
	return Economy.has_upgrade(self, id)


func upgrade_block_reason(up: Dictionary) -> String:
	return Economy.upgrade_block_reason(self, up)


func buy_upgrade(id: String) -> bool:
	return Economy.buy_upgrade(self, id)


func mission_reward(m: Dictionary) -> int:
	return Economy.mission_reward(self, m)


# ---------- Departures (scripts/systems/departure_system.gd) ----------

func open_ultimatums() -> Array:
	return Departures.open_ultimatums(self)


func ultimatum_text(id: String, text: String) -> String:
	return Departures.ultimatum_text(self, id, text)


func ultimatum_block_reason(choice: Dictionary) -> String:
	return Departures.ultimatum_block_reason(self, choice)


func resolve_ultimatum(u: Dictionary, choice: Dictionary) -> Array:
	return Departures.resolve_ultimatum(self, u, choice)


# ---------- Backstage (scripts/systems/backstage_system.gd) ----------

func backstage_text(bs: Dictionary, text: String) -> String:
	return Backstage.backstage_text(self, bs, text)


## Aplica a escolha e devolve as linhas de resultado.
func resolve_backstage(bs: Dictionary, choice: Dictionary) -> Array:
	return Backstage.resolve_backstage(self, bs, choice)


# ---------- SaveSystem (scripts/systems/save_system.gd) ----------

## Salva com var_to_str: preserva int, float e Color (JSON transformaria int em float).
func save_game(slot: String) -> bool:
	return SaveSystem.save_game(self, slot)


func load_game(slot: String) -> bool:
	return SaveSystem.load_game(self, slot)


func save_meta(slot: String) -> Dictionary:
	return SaveSystem.save_meta(self, slot)


func has_any_save() -> bool:
	return SaveSystem.has_any_save(self)


## Save mais recente (para "Continuar").
func latest_save() -> String:
	return SaveSystem.latest_save(self)


# ---------- Endings (scripts/systems/ending_system.gd) ----------

## {title, text, heroes: [{id, text}], bonds: [texto]}
func epilogue() -> Dictionary:
	return Endings.epilogue(self)


func _load_json(path: String) -> Dictionary:
	var txt := FileAccess.get_file_as_string(path)
	var data = JSON.parse_string(txt)
	assert(data is Dictionary, "JSON inválido: " + path)
	return data
