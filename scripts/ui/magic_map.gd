extends Control
## Mapa Mágico de Escrutínio (GDD §13): o jogador assiste, não controla.
## Pergaminho com peças de nanquim (art/MapParts/<tipo>/*.png) escolhidas pelo bioma,
## rota revelada em dourado e um marcador por herói.

signal waypoint_reached(index: int)
signal finished

const DURATION := 10.0
const WAYPOINTS := [0.22, 0.52, 0.82]
const C_GOLD := Color("#e8c060")
const C_INK := Color("#3a2a1c")
const PARTS_DIR := "res://art/MapParts/"
const REF_SIZE := Vector2(860, 660)   # tamanho de referência para espaçar as peças

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
var goal_texture: Texture2D = null   # cartaz do inimigo no destino (sem ele, um X)
var progress := 0.0           # 0..1
var speed := 1.0
var running := false
var _reached := 0
var _time := 0.0
var _route_n: PackedVector2Array = []   # rota em coordenadas normalizadas (0..1)
var _decor: Array = []                  # [{p, tex, s}] em coordenadas normalizadas, ordenado por y
var _stains: Array = []                 # manchas do pergaminho
var _puddles: Array = []                # poças e névoa (pântano)
var _home: Texture2D = null             # peça usada para a guilda (ponto de partida)
var _rng := RandomNumberGenerator.new()


func setup(mission: Dictionary, party: Array, seed_value: int) -> void:
	biome = mission.get("biome", "estrada")
	tokens = party
	_rng.seed = seed_value
	_build_route()
	_build_decor()
	progress = 0.0
	_reached = 0
	running = true
	queue_redraw()


func skip() -> void:
	speed = 4.0


func _process(delta: float) -> void:
	_time += delta
	if running:
		progress = minf(1.0, progress + delta * speed / DURATION)
		while _reached < WAYPOINTS.size() and progress >= WAYPOINTS[_reached]:
			waypoint_reached.emit(_reached)
			_reached += 1
		if progress >= 1.0:
			running = false
			finished.emit()
	queue_redraw()


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

func _build_route() -> void:
	var ctrl := [Vector2(0.08, 0.80)]
	for i in WAYPOINTS.size():
		var x := lerpf(0.08, 0.9, WAYPOINTS[i])
		ctrl.append(Vector2(x, _rng.randf_range(0.22, 0.78)))
	ctrl.append(Vector2(0.90, 0.20))
	# Catmull-Rom para uma estrada sinuosa
	_route_n = PackedVector2Array()
	for i in ctrl.size() - 1:
		var p0: Vector2 = ctrl[max(i - 1, 0)]
		var p1: Vector2 = ctrl[i]
		var p2: Vector2 = ctrl[i + 1]
		var p3: Vector2 = ctrl[min(i + 2, ctrl.size() - 1)]
		for k in 30:
			var t := k / 30.0
			var t2 := t * t
			var t3 := t2 * t
			_route_n.append(0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3))
	_route_n.append(ctrl[-1])


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
				if p.x > 0.88 and p.y > 0.82:
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
	for q in _route_n:
		best = minf(best, p.distance_to(q))
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

	var route := PackedVector2Array()
	for q in _route_n:
		route.append(q * sz)

	# trilha ainda não percorrida (tracejado de tinta) e trecho revelado em dourado
	for i in range(0, route.size() - 2, 4):
		draw_line(route[i], route[i + 1], Color(C_INK, 0.55), 1.6, true)
	var lead := _point_at(progress, route)
	var revealed := _slice(progress, route)
	if revealed.size() >= 2:
		draw_polyline(revealed, Color(C_GOLD, 0.35), 9.0, true)
		draw_polyline(revealed, Color("#b8892e"), 3.0, true)

	# guilda (partida) e destino
	var start := route[0]
	if _home != null:
		var hs := Vector2(_home.get_width(), _home.get_height()) * 1.6 * scale_k
		draw_texture_rect(_home, Rect2(start - Vector2(hs.x / 2.0, hs.y - 4), hs), false)
	draw_line(start + Vector2(10, -34 * scale_k), start + Vector2(10, -54 * scale_k), C_INK, 1.5)
	draw_colored_polygon(PackedVector2Array([start + Vector2(10, -54 * scale_k), start + Vector2(24, -50 * scale_k), start + Vector2(10, -46 * scale_k)]), Color("#b8892e"))
	var font := ThemeDB.fallback_font
	draw_string(font, start + Vector2(-26, 18), "a Guilda", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, C_INK)
	var goal := route[-1]
	if goal_texture != null:
		var pulse := 0.5 + 0.5 * sin(_time * 2.5)
		draw_circle(goal, 30.0 + pulse * 4.0, Color("#a8443c", 0.12 + pulse * 0.10))
		draw_texture_rect(goal_texture, Rect2(goal - Vector2(26, 26), Vector2(52, 52)), false)
	else:
		draw_line(goal + Vector2(-10, -10), goal + Vector2(10, 10), Color("#a8443c"), 4.0)
		draw_line(goal + Vector2(-10, 10), goal + Vector2(10, -10), Color("#a8443c"), 4.0)

	# waypoints
	for i in WAYPOINTS.size():
		var wp := _point_at(WAYPOINTS[i], route)
		var reached := i < _reached
		draw_circle(wp, 7.0, C_GOLD if reached else Color(paper.darkened(0.15)))
		draw_arc(wp, 7.0, 0, TAU, 20, C_INK, 1.2, true)
		draw_circle(wp, 2.5, C_INK)
		if reached:
			var ph := fmod(_time * 0.9 + i * 0.3, 1.0)
			draw_arc(wp, 8.0 + ph * 22.0, 0, TAU, 32, Color("#b8892e", 1.0 - ph), 2.0, true)

	# marcadores dos heróis (levemente defasados para ler como grupo)
	for i in tokens.size():
		var t := maxf(0.0, progress - i * 0.012)
		var pos := _point_at(t, route) + Vector2(0, (i - (tokens.size() - 1) / 2.0) * 9.0)
		var col: Color = tokens[i].color
		var glow := 0.5 + 0.5 * sin(_time * 4.0 + i)
		draw_circle(pos, 14.0 + glow * 3.0, Color(col, 0.30))
		draw_circle(pos, 9.0, col)
		draw_arc(pos, 9.0, 0, TAU, 24, C_INK, 1.5, true)
		draw_string(font, pos + Vector2(-4, 5), String(tokens[i].name).left(1), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.WHITE)
	if progress > 0.0 and progress < 1.0:
		draw_circle(lead, 3.0, C_INK)

	_draw_compass(Vector2(sz.x - 46, sz.y - 46), 26.0)
	# bordas envelhecidas + brilho mágico
	for k in 10:
		var a := 0.10 * (10 - k) / 10.0
		draw_rect(Rect2(Vector2(k * 3, k * 3), sz - Vector2(k * 6, k * 6)), Color(0.35, 0.22, 0.10, a), false, 3.0)
	draw_rect(Rect2(Vector2(1, 1), sz - Vector2(2, 2)), Color(0.55, 0.4, 0.9, 0.35 + 0.15 * sin(_time * 1.5)), false, 2.0)


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


func _point_at(t: float, route: PackedVector2Array) -> Vector2:
	if route.is_empty():
		return Vector2.ZERO
	var f := clampf(t, 0.0, 1.0) * (route.size() - 1)
	var i := int(f)
	if i >= route.size() - 1:
		return route[-1]
	return route[i].lerp(route[i + 1], f - i)


func _slice(t: float, route: PackedVector2Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	var f := clampf(t, 0.0, 1.0) * (route.size() - 1)
	for i in int(f) + 1:
		out.append(route[i])
	out.append(_point_at(t, route))
	return out
