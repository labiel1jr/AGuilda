class_name DiceThrow
extends Control
## d20 arremessado sobre o Mapa Mágico nos testes: voa girando, quica duas vezes, para na face do
## resultado e destaca sucesso/falha (20 natural dourado, 1 natural rachado). Só visual.
## Usa os sprites de res://art/dice/ (art/specs/cenario/dado.json) quando existirem; senão desenha
## um d20 provisório por código.

signal landed
signal finished

const DIR := "res://art/dice/"
const FLIGHT := 1.15          # segundos até parar
const HOLD := 0.9             # tempo mostrando o resultado
const C_BONE := Color("#f1e6cc")
const C_BONE_MID := Color("#d9c9a3")
const C_BONE_DARK := Color("#b39d72")
const C_INK := Color("#2a1f14")
const C_OUT := Color("#1a120c")
const C_OK := Color("#3f6b2f")
const C_FAIL := Color("#8a2f1f")
const C_GOLD := Color("#f2d27a")

var result := 20
var ok := true
var radius := 34.0
var _start := Vector2.ZERO
var _land := Vector2.ZERO
var _arc := 120.0
var _t := 0.0                 # 0..1 do voo; >1 = parado
var _hold := 0.0
var _face := 20
var _face_timer := 0.0
var _done := false
var _faces := {}              # número -> Texture2D (sprites, se houver)
var _rolling: Texture2D = null


## area: retângulo (global) onde o dado cai — normalmente o mapa.
func throw(p_result: int, p_ok: bool, area: Rect2) -> void:
	result = p_result
	ok = p_ok
	top_level = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	global_position = area.position
	size = area.size
	radius = clampf(area.size.y * 0.075, 26.0, 46.0)
	_start = Vector2(size.x * 0.12, size.y * 0.95)
	_land = Vector2(size.x * 0.5, size.y * 0.62)
	_arc = size.y * 0.42
	_face = randi_range(1, 20)
	for n in range(1, 21):
		var p := DIR + "d20_face_%02d.png" % n
		if ResourceLoader.exists(p):
			_faces[n] = load(p)
	if ResourceLoader.exists(DIR + "d20_rolando.png"):
		_rolling = load(DIR + "d20_rolando.png")
	if Juice.reduce_motion:
		_t = 1.0
		_land_now()
	set_process(true)


func _process(delta: float) -> void:
	if _t < 1.0:
		var before := _t
		_t = minf(1.0, _t + delta / FLIGHT)
		for hit: float in [0.55, 0.8, 0.92]:
			if before < hit and _t >= hit:
				_impact()
		_face_timer -= delta
		if _face_timer <= 0.0:
			_face = randi_range(1, 20)
			_face_timer = lerpf(0.04, 0.16, _t)
		if _t >= 1.0:
			_land_now()
	elif not _done:
		_hold += delta
		if _hold >= (0.4 if Juice.reduce_motion else HOLD):
			_done = true
			var tw := create_tween()
			tw.tween_property(self, "modulate:a", 0.0, 0.25)
			tw.tween_callback(func():
				finished.emit()
				queue_free())
	queue_redraw()


func _land_now() -> void:
	_face = result
	landed.emit()


func _impact() -> void:
	pass   # o quique já é desenhado (achatamento + poeira); som entra aqui no Juice v3


## Altura acima do chão: arco do arremesso e dois quiques menores.
func _height() -> float:
	var t := _t
	if t < 0.55:
		var k := t / 0.55
		return _arc * 4.0 * k * (1.0 - k) + (1.0 - k) * 0.0
	if t < 0.8:
		var k := (t - 0.55) / 0.25
		return _arc * 0.22 * 4.0 * k * (1.0 - k)
	if t < 0.92:
		var k := (t - 0.8) / 0.12
		return _arc * 0.07 * 4.0 * k * (1.0 - k)
	return 0.0


## Achatamento perto de cada toque no chão.
func _squash() -> float:
	var best := 1.0
	for hit: float in [0.55, 0.8, 0.92]:
		var d := absf(_t - hit)
		if d < 0.035:
			best = minf(best, 1.0 - 0.22 * (1.0 - d / 0.035))
	return best


func _draw() -> void:
	var ease_t := 1.0 - pow(1.0 - _t, 2.0)
	var ground := _start.lerp(_land, ease_t)
	var h := _height()
	var pos := ground - Vector2(0, h)
	var ang := TAU * 3.0 * (1.0 - pow(1.0 - _t, 3.0))   # 3 voltas, termina de pé
	var sq := _squash()
	# sombra no chão (menor quanto mais alto)
	var sh := clampf(1.0 - h / maxf(1.0, _arc), 0.35, 1.0)
	draw_set_transform(ground + Vector2(0, radius * 0.9), 0.0, Vector2(1.0, 0.32))
	draw_circle(Vector2.ZERO, radius * 1.05 * sh, Color(0.1, 0.06, 0.03, 0.35 * sh))
	draw_set_transform(Vector2.ZERO)
	# poeira nos toques
	for hit: float in [0.55, 0.8, 0.92]:
		var since := _t - hit
		if since > 0.0 and since < 0.12:
			var k := since / 0.12
			var at := _start.lerp(_land, 1.0 - pow(1.0 - hit, 2.0)) + Vector2(0, radius * 0.9)
			for s: float in [-1.0, 1.0]:
				draw_circle(at + Vector2(s * radius * (0.6 + k * 0.9), -k * 6.0), radius * 0.22 * (1.0 - k), Color(0.55, 0.45, 0.3, 0.45 * (1.0 - k)))
	# destaque do resultado (atrás do dado)
	if _t >= 1.0:
		var pulse := 0.5 + 0.5 * sin(_hold * 8.0)
		var c := C_OK if ok else C_FAIL
		if result == 20:
			c = C_GOLD
			for i in 12:
				var a := TAU * i / 12.0 + _hold
				draw_line(pos + Vector2(cos(a), sin(a)) * radius * 1.2, pos + Vector2(cos(a), sin(a)) * radius * (1.7 + 0.3 * pulse), Color(C_GOLD, 0.8), 3.0, true)
		draw_circle(pos, radius * (1.35 + 0.08 * pulse), Color(c, 0.22))
		draw_arc(pos, radius * 1.3, 0, TAU, 40, Color(c, 0.85), 3.0, true)
	# o dado
	draw_set_transform(pos, ang, Vector2(1.0 / sqrt(sq), sq))
	var tex: Texture2D = _faces.get(_face)   # no voo, a face sorteada troca enquanto gira
	if _t < 1.0 and _rolling != null:
		var frames := 8
		var fw := _rolling.get_width() / float(frames)
		var fi := int(_t * 40.0) % frames
		draw_texture_rect_region(_rolling, Rect2(-Vector2.ONE * radius * 1.25, Vector2.ONE * radius * 2.5), Rect2(fi * fw, 0, fw, _rolling.get_height()))
	elif tex != null:
		draw_texture_rect(tex, Rect2(-Vector2.ONE * radius * 1.25, Vector2.ONE * radius * 2.5), false)
	else:
		_draw_d20(_face)
	if _t >= 1.0 and result == 1:
		# rachadura da falha crítica
		var crack := PackedVector2Array([Vector2(-0.7, -0.5), Vector2(-0.2, -0.1), Vector2(-0.35, 0.2), Vector2(0.15, 0.35), Vector2(0.55, 0.75)])
		for i in crack.size():
			crack[i] *= radius
		draw_polyline(crack, C_OUT, 3.0, true)
		draw_polyline(crack, C_FAIL, 1.5, true)
	draw_set_transform(Vector2.ZERO)


## d20 provisório: hexágono com a face de cima (triângulo) e as faces vizinhas sombreadas.
func _draw_d20(n: int) -> void:
	var r := radius
	var hexa := PackedVector2Array()
	for i in 6:
		var a := -PI / 2.0 + TAU * i / 6.0
		hexa.append(Vector2(cos(a), sin(a)) * r)
	var tri := PackedVector2Array()
	for i in 3:
		var a := -PI / 2.0 + TAU * i / 3.0
		tri.append(Vector2(cos(a), sin(a)) * r * 0.62)
	draw_colored_polygon(hexa, C_BONE_MID)
	# faces vizinhas: 3 claras (luz da esquerda/cima) e 3 escuras
	for i in 6:
		var a: Vector2 = hexa[i]
		var b: Vector2 = hexa[(i + 1) % 6]
		var t: Vector2 = tri[int(((i + 1) % 6) / 2.0) % 3]
		var shade := C_BONE_DARK if i in [1, 2, 3] else C_BONE_MID.lightened(0.08)
		draw_colored_polygon(PackedVector2Array([a, b, t]), shade)
	draw_colored_polygon(tri, C_BONE)
	# arestas
	for i in 6:
		draw_line(hexa[i], hexa[(i + 1) % 6], C_OUT, 2.0, true)
		draw_line(hexa[i], tri[int(i / 2.0) % 3] if i % 2 == 0 else tri[int((i + 1) / 2.0) % 3], Color(C_OUT, 0.55), 1.2, true)
	for i in 3:
		draw_line(tri[i], tri[(i + 1) % 3], Color(C_OUT, 0.7), 1.5, true)
	draw_line(hexa[5] * 0.85 + Vector2(2, 2), hexa[5] * 0.6 + Vector2(2, 2), Color(1, 1, 1, 0.6), 2.0, true)
	# número da face de cima
	var font := ThemeDB.fallback_font
	var fs := int(r * 0.5)
	var txt := str(n) + ("." if n in [6, 9] else "")
	var w := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_CENTER, -1, fs).x
	var col := C_INK if _t < 1.0 else (Color("#8a6a1f") if n == 20 else C_INK)
	draw_string(font, Vector2(-w / 2.0, r * 0.18), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
