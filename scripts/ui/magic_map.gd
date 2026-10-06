extends Control
## Mapa Mágico de Escrutínio (GDD §13): o jogador assiste, não controla.
## Desenha o bioma, revela a rota em dourado e move um marcador por herói.

signal waypoint_reached(index: int)
signal finished

const DURATION := 10.0
const WAYPOINTS := [0.22, 0.52, 0.82]
const C_GOLD := Color("#e8c060")

const BIOMES := {
	"floresta": {"base": Color("#2f4a2a"), "accent": Color("#1d3320"), "detail": Color("#4f7a43")},
	"pantano":  {"base": Color("#2c4846"), "accent": Color("#1f3a3f"), "detail": Color("#5d8f86")},
	"montanha": {"base": Color("#4a3c30"), "accent": Color("#2f261f"), "detail": Color("#8a7660")},
	"estrada":  {"base": Color("#5a4a32"), "accent": Color("#3e3222"), "detail": Color("#a08a5e")},
	"cidade":   {"base": Color("#38343c"), "accent": Color("#232028"), "detail": Color("#6d6878")},
}

var biome := "estrada"
var tokens: Array = []        # [{name, color}]
var progress := 0.0           # 0..1
var speed := 1.0
var running := false
var _reached := 0
var _time := 0.0
var _route_n: PackedVector2Array = []   # rota em coordenadas normalizadas (0..1)
var _decor: Array = []                  # decoração em coordenadas normalizadas
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


# ---------- geração ----------

func _build_route() -> void:
	var ctrl := [Vector2(0.07, 0.82)]
	for i in WAYPOINTS.size():
		var x := lerpf(0.07, 0.9, WAYPOINTS[i])
		ctrl.append(Vector2(x, _rng.randf_range(0.2, 0.8)))
	ctrl.append(Vector2(0.92, 0.18))
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
	var count: int = {"floresta": 70, "pantano": 28, "montanha": 22, "estrada": 18, "cidade": 26}.get(biome, 20)
	for i in count:
		var p := Vector2(_rng.randf(), _rng.randf())
		if _dist_to_route(p) < 0.05:
			continue
		_decor.append({"p": p, "s": _rng.randf_range(0.6, 1.4)})


func _dist_to_route(p: Vector2) -> float:
	var best := 9.0
	for q in _route_n:
		best = minf(best, p.distance_to(q))
	return best


# ---------- desenho ----------

func _draw() -> void:
	var sz := size
	var pal: Dictionary = BIOMES.get(biome, BIOMES.estrada)
	draw_rect(Rect2(Vector2.ZERO, sz), pal.base)
	_draw_terrain(pal, sz)

	var route := PackedVector2Array()
	for q in _route_n:
		route.append(q * sz)

	# rota completa apagada (pontilhada) e trecho revelado em dourado
	for i in range(0, route.size() - 1, 3):
		draw_circle(route[i], 1.6, Color(1, 1, 1, 0.18))
	var lead := _point_at(progress, route)
	var revealed := _slice(progress, route)
	if revealed.size() >= 2:
		draw_polyline(revealed, Color(C_GOLD, 0.25), 9.0, true)
		draw_polyline(revealed, C_GOLD, 3.0, true)

	# guilda e destino
	var start := route[0]
	draw_rect(Rect2(start - Vector2(12, 14), Vector2(24, 20)), Color("#6b5235"))
	draw_colored_polygon(PackedVector2Array([start + Vector2(-15, -14), start + Vector2(15, -14), start + Vector2(0, -28)]), Color("#8a3b1f"))
	var goal := route[-1]
	draw_line(goal + Vector2(-10, -10), goal + Vector2(10, 10), Color("#d1603d"), 4.0)
	draw_line(goal + Vector2(-10, 10), goal + Vector2(10, -10), Color("#d1603d"), 4.0)

	# waypoints
	for i in WAYPOINTS.size():
		var wp := _point_at(WAYPOINTS[i], route)
		var reached := i < _reached
		draw_circle(wp, 7.0, C_GOLD if reached else Color(1, 1, 1, 0.35))
		draw_circle(wp, 3.0, Color("#2a1f14"))
		if reached:
			var ph := fmod(_time * 0.9 + i * 0.3, 1.0)
			draw_arc(wp, 8.0 + ph * 22.0, 0, TAU, 32, Color(C_GOLD, 1.0 - ph), 2.0, true)

	# marcadores dos heróis (levemente defasados para ler como grupo)
	var font := ThemeDB.fallback_font
	for i in tokens.size():
		var t := maxf(0.0, progress - i * 0.012)
		var pos := _point_at(t, route) + Vector2(0, (i - (tokens.size() - 1) / 2.0) * 9.0)
		var col: Color = tokens[i].color
		var glow := 0.5 + 0.5 * sin(_time * 4.0 + i)
		draw_circle(pos, 14.0 + glow * 3.0, Color(col, 0.25))
		draw_circle(pos, 9.0, col)
		draw_arc(pos, 9.0, 0, TAU, 24, Color.WHITE, 1.5, true)
		draw_string(font, pos + Vector2(-4, 5), String(tokens[i].name).left(1), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.WHITE)
	if progress > 0.0 and progress < 1.0:
		draw_circle(lead, 3.0, Color.WHITE)

	# vinheta mágica
	for k in 6:
		var a := 0.08 * (6 - k) / 6.0
		draw_rect(Rect2(Vector2(k * 4, k * 4), sz - Vector2(k * 8, k * 8)), Color(0.55, 0.4, 0.9, a), false, 4.0)


func _draw_terrain(pal: Dictionary, sz: Vector2) -> void:
	# rio comum a todos os biomas
	var river := PackedVector2Array()
	for k in 21:
		var y := k / 20.0
		river.append(Vector2((0.35 + 0.08 * sin(y * 6.0 + _rng.seed % 7)) * sz.x, y * sz.y))
	draw_polyline(river, Color("#3d6f8f", 0.55), 10.0, true)

	for d in _decor:
		var p: Vector2 = d.p * sz
		var s: float = d.s
		match biome:
			"floresta":
				draw_circle(p + Vector2(3, 4), 11.0 * s, pal.accent)
				draw_circle(p, 10.0 * s, pal.detail)
			"pantano":
				draw_set_transform(p, 0, Vector2(1.8, 0.7))
				draw_circle(Vector2.ZERO, 12.0 * s, Color(pal.detail, 0.55))
				draw_set_transform(Vector2.ZERO)
				draw_circle(p + Vector2(0, -16), 18.0 * s, Color(1, 1, 1, 0.05))
			"montanha":
				var h := 34.0 * s
				draw_colored_polygon(PackedVector2Array([p + Vector2(-h * 0.7, h * 0.5), p + Vector2(h * 0.7, h * 0.5), p + Vector2(0, -h * 0.6)]), pal.detail)
				draw_colored_polygon(PackedVector2Array([p + Vector2(-h * 0.18, -h * 0.35), p + Vector2(h * 0.18, -h * 0.35), p + Vector2(0, -h * 0.6)]), Color("#e8e2d4"))
			"estrada":
				draw_rect(Rect2(p, Vector2(16, 12) * s), pal.detail)
				draw_colored_polygon(PackedVector2Array([p + Vector2(-2, 0), p + Vector2(16 * s + 2, 0), p + Vector2(8 * s, -9 * s)]), Color("#8a3b1f"))
			"cidade":
				var w := 14.0 * s
				var hh := 30.0 * s
				draw_rect(Rect2(p - Vector2(0, hh), Vector2(w, hh)), pal.detail)
				draw_rect(Rect2(p - Vector2(-w * 0.3, hh * 0.7), Vector2(w * 0.3, w * 0.3)), Color("#e8c060", 0.6))


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
