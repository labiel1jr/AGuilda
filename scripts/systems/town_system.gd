class_name Town
## A cidade e o povo: Fama de cada herói no povo e Estima da cidade pela guilda (separada da
## Reputação com o Conselho). Mexem nos preços, na recompensa das missões, nos testes de
## diplomacia (termo Povo do score) e nos bastidores. Dados em data/upgrades.json → town.

const FAME_MIN := -5
const FAME_MAX := 10
const ESTEEM_MAX := 20


static func data(gs: GuildState) -> Dictionary:
	return gs.upgrades_data.get("town", {})


## Garante os campos (heróis novos e saves antigos).
static func ensure(h: Dictionary) -> void:
	if not h.has("fame"):
		h.fame = 0


static func change_fame(gs: GuildState, id: String, n: int) -> String:
	var h: Dictionary = gs.heroes[id]
	ensure(h)
	var before: int = h.fame
	h.fame = clampi(h.fame + n, FAME_MIN, FAME_MAX)
	if h.fame == before:
		return ""
	return "%s: fama no povo %+d (%s)." % [h.name, h.fame - before, fame_label(h.fame)]


static func change_esteem(gs: GuildState, n: int) -> String:
	var before: int = gs.town_esteem
	gs.town_esteem = clampi(gs.town_esteem + n, 0, ESTEEM_MAX)
	if gs.town_esteem == before:
		return ""
	return "Estima da cidade %+d (%s)." % [gs.town_esteem - before, esteem_label(gs.town_esteem)]


static func fame_label(v: int) -> String:
	if v <= -3:
		return "malvisto(a)"
	if v <= 0:
		return "desconhecido(a)"
	if v <= 4:
		return "conhecido(a)"
	if v <= 7:
		return "querido(a)"
	return "lenda do povo"


static func esteem_label(v: int) -> String:
	if v <= 2:
		return "desconfiada"
	if v <= 6:
		return "indiferente"
	if v <= 11:
		return "simpática"
	if v <= 16:
		return "grata"
	return "devota"


## Preço no mercado: a cidade grata cobra menos, a desconfiada cobra mais.
static func price_mult(gs: GuildState) -> float:
	var e: int = gs.town_esteem
	if e <= 2:
		return 1.2
	if e >= 17:
		return 0.8
	if e >= 12:
		return 0.9
	return 1.0


## Recompensa: quem a cidade estima recebe pedidos mais generosos.
static func reward_mult(gs: GuildState) -> float:
	return 1.15 if gs.town_esteem >= 12 else 1.0


## Termo Povo do score: só em missões de diplomacia, pela fama média do grupo.
static func score_bonus(gs: GuildState, mission: Dictionary, party: Array) -> int:
	if mission.get("type", "") != "diplomacia" or party.is_empty():
		return 0
	var total := 0.0
	for id in party:
		total += int(gs.heroes[id].get("fame", 0))
	var avg := total / party.size()
	if avg >= 8:
		return 2
	if avg >= 5:
		return 1
	if avg <= -3:
		return -1
	return 0


## Depois de uma missão vista pelo povo (cidade e estrada): fama e estima seguem o resultado.
static func after_mission(gs: GuildState, mission: Dictionary, party: Array, result: String) -> Array:
	var lines := []
	if not mission.get("biome", "") in ["cidade", "estrada"]:
		return lines
	var d: int = {"limpo": 1, "custo": 0, "falha": -1}[result]
	if d == 0:
		return lines
	var l := change_esteem(gs, d)
	if l != "":
		lines.append(l)
	for id in party:
		var lf := change_fame(gs, id, d)
		if lf != "":
			lines.append(lf)
	return lines
