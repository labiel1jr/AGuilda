extends Control
## Mapa Mágico de Escrutínio (GDD §13) — mapa de expedição (v0.8).
## Pergaminho com peças de nanquim (art/MapParts/<tipo>/*.png) escolhidas pelo bioma.
## A rota é um grafo em camadas (Expedition): o líder clica no próximo nó quando
## o grupo chama; o marcador anda até lá e o nó se resolve.

signal node_chosen(pos: Array)
signal arrived(pos: Array)

const MOVE_TIME := 1.4
const C_GOLD := Color("#e8c060")
const C_INK := Color("#3a2a1c")
const C_RED := Color("#a8443c")
const PARTS_DIR := "res://art/MapParts/"
const REF_SIZE := Vector2(860, 660)   # tamanho de referência para espaçar as peças
const START_P := Vector2(0.07, 0.56)
const BOSS_P := Vector2(0.91, 0.44)
const NODE_R := 15.0

## Tinta do pergaminho por bioma
const PAPER := {
	"floresta": Color("#e2dcb4"),
	"pantano":  Color("#d9dcc4"),
	"montanha": Color("#e6dac0"),
	"estrada":  Color("#ead9b2"),
	"cidade":   Color("#e6d9c2"),
}

## Composição por bioma: [tipo, quantidade, escala mínima, escala máxima, agrupado?]
const BIOME_PARTS := {
	"floresta": [["trees", 150, 1.2, 1.6, true], ["hills", 8, 1.0, 1.3, false], ["towns", 2, 1.0, 1.2, false]],
	"pantano":  [["trees", 40, 1.0, 1.3, true], ["hills", 12, 0.9, 1.2, false], ["towns", 2, 1.0, 1.1, false]],
	"montanha": [["mountains", 30, 1.0, 1.5, false], ["hills", 18, 1.0, 1.3, false], ["trees", 24, 1.1, 1.4, true]],
	"estrada":  [["hills", 26, 1.0, 1.3, false], ["trees", 45, 1.1, 1.5, true], ["towns", 8, 1.1, 1.3, false]],
	"cidade":   [["cities", 6, 1.0, 1.3, false], ["towns", 16, 1.1, 1.4, false], ["hills", 10, 1.0, 1.2, false], ["trees", 18, 1.1, 1.4, true]],
}

static var _parts := {}   # tipo -> [Texture2D] (carregado uma vez)

var biome := "estrada"
var tokens: Array = []        # [{name, color}]
var goal_texture: Texture2D = null   # cartaz do inimigo no alvo (sem ele, um X)
var mini_texture: Texture2D = null   # cartaz do guarda do alvo (miniboss), se houver
var type_info := {}           # tipo de nó -> {name, desc} (tooltip)
var exp: Dictionary = {}      # gs.expedition (mesmo objeto, atualizado pelo jogo)
var reachable: Array = []     # [[camada, índice]] clicáveis agora
var speed := 1.0
var moving := false
var _from := Vector2.ZERO     # posição normalizada do grupo
var _to := Vector2.ZERO
var _to_pos: Array = []
var _t := 1.0
var _hover := []
var _time := 0.0
var _pos := {}                          # "l:i" -> posição normalizada (partida "-1:0")
var _edges: Array = []                  # [[pts normalizados], chave_a, chave_b]
var _decor: Array = []                  # [{p, tex, s}] em coordenadas normalizadas, ordenado por y
var _stains: Array = []                 # manchas do pergaminho
var _puddles: Array = []                # poças e névoa (pântano)
var _home: Texture2D = null             # peça usada para a guilda (ponto de partida)
var _rng := RandomNumberGenerator.new()


func setup(mission: Dictionary, party: Array, seed_value: int, expedition: Dictionary) -> void:
	biome = mission.get("biome", "estrada")
	tokens = party
	exp = expedition
	_rng.seed = seed_value
	tooltip_text = " "
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_graph()
	_build_decor()
	_from = _pos[_key(exp.cur)]
	_to = _from
	_t = 1.0
	queue_redraw()


## Anda até o nó; emite arrived ao chegar.
func move_to(pos: Array) -> void:
	_from = _group_pos()
	_to = _pos[_key(pos)]
	_to_pos = pos
	_t = 0.0
	moving = true
	reachable = []


func skip() -> void:
	speed = 4.0


func _process(delta: float) -> void:
	_time += delta
	if moving:
		_t = minf(1.0, _t + delta * speed / MOVE_TIME)
		if _t >= 1.0:
			moving = false
			_from = _to
			arrived.emit(_to_pos)
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_hover = _node_under(event.position)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var hit := _node_under(event.position)
		if not hit.is_empty() and _is_reachable(hit) and not moving:
			node_chosen.emit(hit)
			accept_event()


func _get_tooltip(at_position: Vector2) -> String:
	var hit := _node_under(at_position)
	if hit.is_empty():
		return ""
	if not _revealed(hit):
		return "Caminho ainda encoberto pela névoa."
	var t: String = exp.layers[hit[0]][hit[1]].type
	var info: Dictionary = type_info.get(t, {})
	var tip := "%s — %s" % [info.get("name", t), info.get("desc", "")]
	if _is_reachable(hit):
		tip += "\n(clique para seguir por aqui)"
	return tip


func _node_under(p: Vector2) -> Array:
	for k in _pos:
		var pos := _split(k)
		if pos[0] < 0:
			continue
		var r := 34.0 if pos[0] == exp.layers.size() - 1 else NODE_R + 6.0
		if (_pos[k] * size).distance_to(p) <= r:
			return pos
	return []


func _is_reachable(pos: Array) -> bool:
	for r in reachable:
		if r[0] == pos[0] and r[1] == pos[1]:
			return true
	return false


## Névoa: só a camada atual, a seguinte e o que dá para alcançar aparecem. O alvo e o guarda sempre aparecem.
func _revealed(pos: Array) -> bool:
	if pos[0] >= exp.layers.size() - 1 or exp.layers[pos[0]][pos[1]].type == "miniboss":
		return true
	return pos[0] <= int(exp.cur[0]) + 1 or _is_reachable(pos) or _visited(pos)


func _visited(pos: Array) -> bool:
	for v in exp.path:
		if v[0] == pos[0] and v[1] == pos[1]:
			return true
	return false


static func _key(pos: Array) -> String:
	return "%d:%d" % [pos[0], pos[1]]


func _split(k: String) -> Array:
	var p := k.split(":")
	return [int(p[0]), int(p[1])]


func _group_pos() -> Vector2:
	var t := _t * _t * (3.0 - 2.0 * _t)
	return _from.lerp(_to, t)


# ---------- peças de mapa ----------

## Texturas de art/MapParts/<tipo>/. Funciona no editor e no jogo exportado
## (no exportado a pasta só lista os .import).
static func parts(kind: String) -> Array:
	if _parts.has(kind):
		return _parts[kind]
	var out := []
	var dir := DirAccess.open(PARTS_DIR + kind)
	if dir != null:
		var names := {}
		for f in dir.get_files():
			var n := f.trim_suffix(".import")
			if n.ends_with(".png"):
				names[n] = true
		var sorted_names: Array = names.keys()
		sorted_names.sort_custom(func(a, b): return a.naturalnocasecmp_to(b) < 0)
		for n in sorted_names:
			var path: String = PARTS_DIR + kind + "/" + n
			if ResourceLoader.exists(path):
				out.append(load(path))
	_parts[kind] = out
	return out


# ---------- geração ----------

func _build_graph() -> void:
	_pos.clear()
	_edges.clear()
	_pos["-1:0"] = START_P
	var layers: Array = exp.layers
	var last := layers.size() - 1
	for l in layers.size():
		var n: int = layers[l].size()
		for i in n:
			var p := BOSS_P
			if l < last:
				var x := lerpf(0.22, 0.76, float(l) / max(1, last - 1))
				var y := lerpf(0.12, 0.88, (i + 0.5) / n)
				p = Vector2(x + _rng.randf_range(-0.025, 0.025), y + _rng.randf_range(-0.04, 0.04))
			_pos[_key([l, i])] = p
	for i in layers[0].size():
		_add_edge("-1:0", _key([0, i]))
	for l in last:
		for i in layers[l].size():
			var node: Dictionary = layers[l][i]
			var tl := l + (2 if node.type == "atalho" else 1)
			for j in node.next:
				_add_edge(_key([l, i]), _key([tl, j]))


func _add_edge(ka: String, kb: String) -> void:
	var a: Vector2 = _pos[ka]
	var b: Vector2 = _pos[kb]
	var mid := (a + b) / 2.0 + (b - a).orthogonal().normalized() * _rng.randf_range(-0.04, 0.04)
	var pts := PackedVector2Array()
	for k in 21:
		var t := k / 20.0
		pts.append(a.lerp(mid, t).lerp(mid.lerp(b, t), t))
	_edges.append([pts, ka, kb])


func _build_decor() -> void:
	_decor.clear()
	_stains.clear()
	_puddles.clear()
	var taken: Array = []   # retângulos normalizados já ocupados
	var spec: Array = BIOME_PARTS.get(biome, BIOME_PARTS.estrada)
	for entry in spec:
		var kind: String = entry[0]
		var texs := parts(kind)
		if texs.is_empty():
			continue
		var centers := []
		if entry[4]:
			for c in 7:
				centers.append(Vector2(_rng.randf_range(0.05, 0.95), _rng.randf_range(0.08, 0.95)))
		for n in int(entry[1]):
			for attempt in 12:
				var p: Vector2
				if centers.is_empty():
					p = Vector2(_rng.randf_range(0.03, 0.97), _rng.randf_range(0.08, 0.98))
				else:
					var c: Vector2 = centers[_rng.randi_range(0, centers.size() - 1)]
					p = c + Vector2(_rng.randfn(0.0, 0.07), _rng.randfn(0.0, 0.06))
				if p.x < 0.02 or p.x > 0.98 or p.y < 0.06 or p.y > 0.99:
					continue
				var tex: Texture2D = texs[_rng.randi_range(0, texs.size() - 1)]
				var s := _rng.randf_range(entry[2], entry[3])
				var half := Vector2(tex.get_width(), tex.get_height()) * s / REF_SIZE / 2.0
				if _dist_to_route(p - Vector2(0, half.y)) < half.length() * 0.6 + 0.035:
					continue
				if absf(p.x - _river_x(p.y - half.y)) < half.x + 0.02:
					continue
				if p.x > 0.86 and p.y > 0.80:
					continue   # canto da rosa dos ventos
				var r := Rect2(p - Vector2(half.x, half.y * 2.0), half * 2.0).grow(-0.004)
				if taken.any(func(o): return o.intersects(r)):
					continue
				taken.append(r)
				_decor.append({"p": p, "tex": tex, "s": s})
				break
	# desenha de trás para a frente (base da peça mais acima primeiro)
	_decor.sort_custom(func(a, b): return a.p.y < b.p.y)

	var towns := parts("towns")
	_home = towns[0] if not towns.is_empty() else null
	for i in 26:
		_stains.append({"p": Vector2(_rng.randf(), _rng.randf()), "r": _rng.randf_range(0.03, 0.12), "a": _rng.randf_range(0.03, 0.07)})
	if biome == "pantano":
		for i in 16:
			_puddles.append({"p": Vector2(_rng.randf_range(0.05, 0.95), _rng.randf_range(0.1, 0.95)), "s": _rng.randf_range(0.6, 1.5)})


## Rio em coordenadas normalizadas (mesma curva usada no desenho).
func _river_x(y: float) -> float:
	return 0.38 + 0.07 * sin(y * 6.0 + float(_rng.seed % 7))


func _dist_to_route(p: Vector2) -> float:
	var best := 9.0
	for e in _edges:
		for q in e[0]:
			best = minf(best, p.distance_to(q))
	for k in _pos:
		best = minf(best, p.distance_to(_pos[k]) - 0.025)
	return best


# ---------- desenho ----------

func _draw() -> void:
	var sz := size
	var paper: Color = PAPER.get(biome, PAPER.estrada)
	draw_rect(Rect2(Vector2.ZERO, sz), paper)
	# manchas suaves do pergaminho (degradê radial em anéis)
	for st in _stains:
		for k in 6:
			draw_circle(st.p * sz, st.r * sz.x * (1.0 - k * 0.15), Color(0.45, 0.32, 0.18, st.a / 6.0))
	_draw_river(sz)
	for pd in _puddles:
		var p: Vector2 = pd.p * sz
		draw_set_transform(p, 0, Vector2(2.2, 0.8))
		draw_arc(Vector2.ZERO, 9.0 * pd.s, 0, TAU, 24, Color("#5a7a8c", 0.7), 1.2, true)
		draw_arc(Vector2.ZERO, 5.0 * pd.s, 0, TAU, 20, Color("#5a7a8c", 0.45), 1.0, true)
		draw_set_transform(Vector2.ZERO)
		draw_circle(p + Vector2(0, -18), 26.0 * pd.s, Color(1, 1, 1, 0.10))

	var scale_k := minf(sz.x / REF_SIZE.x, sz.y / REF_SIZE.y)
	for d in _decor:
		var tex: Texture2D = d.tex
		var tsz: Vector2 = Vector2(tex.get_width(), tex.get_height()) * float(d.s) * scale_k
		var base: Vector2 = d.p * sz
		draw_texture_rect(tex, Rect2(base - Vector2(tsz.x / 2.0, tsz.y), tsz), false, Color(1, 1, 1, 0.92))

	# caminhos: tracejado de tinta; percorridos em dourado; as saídas atuais brilham
	var walked := {}
	for i in range(1, exp.path.size()):
		walked[_key(exp.path[i - 1]) + ">" + _key(exp.path[i])] = true
	var cur_key := _key(exp.cur)
	for e in _edges:
		var pts := PackedVector2Array()
		for q in e[0]:
			pts.append(q * sz)
		if walked.has(e[1] + ">" + e[2]):
			draw_polyline(pts, Color(C_GOLD, 0.35), 9.0, true)
			draw_polyline(pts, Color("#b8892e"), 3.0, true)
		elif e[1] == cur_key and not moving and _is_reachable(_split(e[2])):
			var glow := 0.5 + 0.5 * sin(_time * 3.0)
			draw_polyline(pts, Color(C_GOLD, 0.25 + glow * 0.3), 7.0, true)
			for i in range(0, pts.size() - 1, 2):
				draw_line(pts[i], pts[i + 1], Color(C_INK, 0.85), 2.0, true)
		else:
			var hidden: bool = not _revealed(_split(e[2]))
			for i in range(0, pts.size() - 1, 2):
				draw_line(pts[i], pts[i + 1], Color(C_INK, 0.18 if hidden else 0.5), 1.4, true)

	# guilda (partida)
	var start: Vector2 = START_P * sz
	if _home != null:
		var hs := Vector2(_home.get_width(), _home.get_height()) * 1.6 * scale_k
		draw_texture_rect(_home, Rect2(start - Vector2(hs.x / 2.0, hs.y - 4), hs), false)
	draw_line(start + Vector2(10, -34 * scale_k), start + Vector2(10, -54 * scale_k), C_INK, 1.5)
	draw_colored_polygon(PackedVector2Array([start + Vector2(10, -54 * scale_k), start + Vector2(24, -50 * scale_k), start + Vector2(10, -46 * scale_k)]), Color("#b8892e"))
	var font := ThemeDB.fallback_font
	draw_string(font, start + Vector2(-26, 18), "a Guilda", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, C_INK)

	for k in _pos:
		var pos := _split(k)
		if pos[0] >= 0:
			_draw_node(pos, _pos[k] * sz, paper)

	# marcadores dos heróis em volta da posição do grupo
	var g := _group_pos() * sz + Vector2(0, -30)
	for i in tokens.size():
		var ang: float = TAU * i / max(1, tokens.size()) - PI / 2.0
		var pos := g + (Vector2(cos(ang), sin(ang)) * 12.0 if tokens.size() > 1 else Vector2.ZERO)
		var col: Color = tokens[i].color
		var glow := 0.5 + 0.5 * sin(_time * 4.0 + i)
		draw_circle(pos, 11.0 + glow * 2.0, Color(col, 0.30))
		draw_circle(pos, 8.0, col)
		draw_arc(pos, 8.0, 0, TAU, 24, C_INK, 1.5, true)
		draw_string(font, pos + Vector2(-4, 5), String(tokens[i].name).left(1), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)

	_draw_compass(Vector2(sz.x - 46, sz.y - 46), 26.0)
	# bordas envelhecidas + brilho mágico
	for k in 10:
		var a := 0.10 * (10 - k) / 10.0
		draw_rect(Rect2(Vector2(k * 3, k * 3), sz - Vector2(k * 6, k * 6)), Color(0.35, 0.22, 0.10, a), false, 3.0)
	draw_rect(Rect2(Vector2(1, 1), sz - Vector2(2, 2)), Color(0.55, 0.4, 0.9, 0.35 + 0.15 * sin(_time * 1.5)), false, 2.0)


func _draw_node(pos: Array, c: Vector2, paper: Color) -> void:
	var node: Dictionary = exp.layers[pos[0]][pos[1]]
	var reach := _is_reachable(pos) and not moving
	if node.type == "chefe":
		var pulse := 0.5 + 0.5 * sin(_time * 2.5)
		draw_circle(c, 30.0 + pulse * 4.0, Color(C_RED, 0.12 + pulse * 0.10))
		if goal_texture != null:
			draw_texture_rect(goal_texture, Rect2(c - Vector2(30, 30), Vector2(60, 60)), false)
		else:
			draw_line(c + Vector2(-10, -10), c + Vector2(10, 10), C_RED, 4.0)
			draw_line(c + Vector2(-10, 10), c + Vector2(10, -10), C_RED, 4.0)
		if reach:
			draw_arc(c, 34.0 + pulse * 3.0, 0, TAU, 40, Color("#b8892e"), 3.0, true)
		return
	var visited := _visited(pos)
	if node.type == "miniboss" and _revealed(pos):
		var pulse2 := 0.5 + 0.5 * sin(_time * 2.0)
		draw_circle(c, 22.0 + pulse2 * 2.0, Color(C_RED, 0.15))
		if reach:
			var ph2 := fmod(_time * 0.9, 1.0)
			draw_arc(c, 24.0 + ph2 * 10.0, 0, TAU, 32, Color("#b8892e", 1.0 - ph2), 2.0, true)
		if mini_texture != null:
			draw_texture_rect(mini_texture, Rect2(c - Vector2(21, 21), Vector2(42, 42)), false, Color(1, 1, 1, 1.0 if (reach or visited) else 0.75))
			return
	var r := NODE_R + (3.0 if reach and _hover == pos else 0.0)
	if reach:
		var ph := fmod(_time * 0.9, 1.0)
		draw_arc(c, r + 3.0 + ph * 12.0, 0, TAU, 32, Color("#b8892e", 1.0 - ph), 2.0, true)
	var fill := C_GOLD if visited else (Color("#f3ead0") if reach else paper.darkened(0.08))
	draw_circle(c, r, fill)
	draw_arc(c, r, 0, TAU, 28, C_INK, 2.0 if reach else 1.3, true)
	if not _revealed(pos):
		draw_string(ThemeDB.fallback_font, c + Vector2(-4, 6), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(C_INK, 0.45))
		return
	_draw_icon(node.type, c, Color(C_INK, 0.95 if (reach or visited) else 0.6))


## Ícones a nanquim para cada tipo de nó.
func _draw_icon(t: String, c: Vector2, ink: Color) -> void:
	var font := ThemeDB.fallback_font
	match t:
		"combate":
			draw_line(c + Vector2(-7, -7), c + Vector2(7, 7), ink, 2.2)
			draw_line(c + Vector2(7, -7), c + Vector2(-7, 7), ink, 2.2)
			draw_line(c + Vector2(-8, -2), c + Vector2(-2, -8), ink, 1.6)
			draw_line(c + Vector2(8, -2), c + Vector2(2, -8), ink, 1.6)
		"tesouro":
			draw_rect(Rect2(c + Vector2(-8, -3), Vector2(16, 10)), ink, false, 1.8)
			draw_arc(c + Vector2(0, -3), 8.0, PI, TAU, 12, ink, 1.8)
			draw_rect(Rect2(c + Vector2(-2, -1), Vector2(4, 4)), ink)
		"loja":
			draw_arc(c, 7.5, 0, TAU, 20, ink, 1.6, true)
			draw_string(font, c + Vector2(-4, 5), "$", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, ink)
		"acampamento":
			draw_colored_polygon(PackedVector2Array([c + Vector2(0, -9), c + Vector2(5, 3), c + Vector2(0, 0), c + Vector2(-5, 3)]), Color(Color("#c0602d"), ink.a))
			draw_line(c + Vector2(-8, 7), c + Vector2(8, 3), ink, 2.0)
			draw_line(c + Vector2(-8, 3), c + Vector2(8, 7), ink, 2.0)
		"evento":
			draw_string(font, c + Vector2(-4, 7), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, ink)
		"npc":
			draw_circle(c + Vector2(0, -4), 3.5, ink)
			draw_arc(c + Vector2(0, 8), 7.0, PI, TAU, 12, ink, 2.0)
		"santuario":
			draw_line(c + Vector2(0, -9), c + Vector2(0, 8), ink, 2.2)
			draw_line(c + Vector2(-6, -3), c + Vector2(6, -3), ink, 2.2)
		"miniboss":
			draw_colored_polygon(PackedVector2Array([c + Vector2(-8, 6), c + Vector2(-8, -4), c + Vector2(-4, 0), c + Vector2(0, -7), c + Vector2(4, 0), c + Vector2(8, -4), c + Vector2(8, 6)]), Color(C_RED, ink.a))
		"atalho":
			draw_line(c + Vector2(-8, 0), c + Vector2(5, 0), ink, 2.0)
			draw_colored_polygon(PackedVector2Array([c + Vector2(9, 0), c + Vector2(3, -5), c + Vector2(3, 5)]), ink)
			draw_line(c + Vector2(-8, -5), c + Vector2(-2, -5), Color(ink, 0.6), 1.2)
			draw_line(c + Vector2(-8, 5), c + Vector2(-2, 5), Color(ink, 0.6), 1.2)


func _draw_river(sz: Vector2) -> void:
	var river := PackedVector2Array()
	for k in 31:
		var y := k / 30.0
		river.append(Vector2(_river_x(y) * sz.x, y * sz.y))
	draw_polyline(river, Color("#8fb0bf", 0.55), 9.0, true)
	draw_polyline(river, Color("#4f6f80", 0.8), 1.4, true)
	var offset := PackedVector2Array()
	for p in river:
		offset.append(p + Vector2(7, 0))
	draw_polyline(offset, Color("#4f6f80", 0.6), 1.0, true)


func _draw_compass(c: Vector2, r: float) -> void:
	draw_arc(c, r * 0.55, 0, TAU, 28, Color(C_INK, 0.7), 1.0, true)
	for i in 4:
		var a := -PI / 2.0 + i * PI / 2.0
		var tip := c + Vector2(cos(a), sin(a)) * r
		var l := c + Vector2(cos(a + 0.5), sin(a + 0.5)) * r * 0.22
		var rr := c + Vector2(cos(a - 0.5), sin(a - 0.5)) * r * 0.22
		draw_colored_polygon(PackedVector2Array([tip, l, c]), Color(C_INK, 0.85))
		draw_colored_polygon(PackedVector2Array([tip, rr, c]), Color(C_INK, 0.35))
	draw_string(ThemeDB.fallback_font, c + Vector2(-4, -r - 4), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, C_INK)


