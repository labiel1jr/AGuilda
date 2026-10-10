class_name Juice
## Game juice sóbrio: pequenos movimentos, contadores, flashes e tremores que dão peso às
## decisões e consequências. Tudo é só visual — nunca muda o estado do jogo.
## "Reduzir movimento" (Opções) desliga escala, tremor e animações longas.

const SETTINGS := "user://settings.cfg"

static var reduce_motion := false
static var _loaded := false


static func load_settings() -> void:
	if _loaded:
		return
	_loaded = true
	var cf := ConfigFile.new()
	if cf.load(SETTINGS) == OK:
		reduce_motion = bool(cf.get_value("acessibilidade", "reduzir_movimento", false))


static func set_reduce_motion(on: bool) -> void:
	reduce_motion = on
	var cf := ConfigFile.new()
	cf.load(SETTINGS)
	cf.set_value("acessibilidade", "reduzir_movimento", on)
	cf.save(SETTINGS)


## Dá um "pulo" de escala no controle (volta ao tamanho normal).
static func pop(n: Control, amount: float = 0.12, dur: float = 0.25, delay: float = 0.0) -> void:
	if n == null or not is_instance_valid(n) or reduce_motion:
		return
	n.pivot_offset = n.size / 2.0
	var tw := n.create_tween()
	if delay > 0.0:
		tw.tween_interval(delay)
	tw.tween_callback(func(): n.pivot_offset = n.size / 2.0; n.scale = Vector2.ONE * (1.0 + amount))
	tw.tween_property(n, "scale", Vector2.ONE, dur).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Aparece suavemente (opcionalmente com atraso, para entrar em sequência).
static func fade_in(n: CanvasItem, delay: float = 0.0, dur: float = 0.35) -> void:
	if n == null or not is_instance_valid(n):
		return
	n.modulate.a = 0.0
	var tw := n.create_tween()
	if delay > 0.0 and not reduce_motion:
		tw.tween_interval(delay)
	tw.tween_property(n, "modulate:a", 1.0, 0.12 if reduce_motion else dur)


## Pisca numa cor (sem mexer na posição — seguro dentro de containers).
static func blink(n: CanvasItem, color: Color, dur: float = 0.45) -> void:
	if n == null or not is_instance_valid(n):
		return
	var tw := n.create_tween()
	n.modulate = color
	tw.tween_property(n, "modulate", Color.WHITE, dur)


## Tremor de tela: só para momentos fortes. Use num nó que não esteja dentro de container.
static func shake(n: Control, strength: float = 5.0, dur: float = 0.28) -> void:
	if n == null or not is_instance_valid(n) or reduce_motion:
		return
	var base := n.position
	var tw := n.create_tween()
	var steps := 6
	for i in steps:
		var k := 1.0 - float(i) / steps
		tw.tween_property(n, "position", base + Vector2(randf_range(-1, 1), randf_range(-1, 1)) * strength * k, dur / steps)
	tw.tween_property(n, "position", base, dur / steps)


## Clarão de cor por cima de tudo.
static func flash(host: Control, color: Color, strength: float = 0.28, dur: float = 0.45) -> void:
	if host == null or not is_instance_valid(host):
		return
	var r := ColorRect.new()
	r.color = Color(color, strength * (0.5 if reduce_motion else 1.0))
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	host.add_child(r)
	var tw := r.create_tween()
	tw.tween_property(r, "color:a", 0.0, dur)
	tw.tween_callback(r.queue_free)


## Conta um número até o valor final num Label.
static func count(l: Label, from: float, to: float, fmt: String, dur: float = 0.6) -> void:
	if l == null or not is_instance_valid(l):
		return
	if reduce_motion:
		l.text = fmt % to
		return
	var tw := l.create_tween()
	tw.tween_method(func(v: float): l.text = fmt % v, from, to, dur).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)


## Texto que sobe e some (ganhos e perdas: "+15 ouro", "−1 provisão").
static func fly_text(host: Control, text: String, at_global: Vector2, color: Color) -> void:
	if host == null or not is_instance_valid(host):
		return
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 16)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color("#1a120c"))
	l.add_theme_constant_override("outline_size", 4)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.top_level = true
	host.add_child(l)
	l.global_position = at_global
	var tw := l.create_tween().set_parallel(true)
	tw.tween_property(l, "global_position:y", at_global.y - (16.0 if reduce_motion else 42.0), 1.0).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "modulate:a", 0.0, 1.0).set_delay(0.35)
	tw.chain().tween_callback(l.queue_free)


## Texto que aparece letra a letra.
static func typewrite(l: Label, chars_per_sec: float = 45.0) -> void:
	if l == null or not is_instance_valid(l) or reduce_motion:
		return
	l.visible_ratio = 0.0
	var tw := l.create_tween()
	tw.tween_property(l, "visible_ratio", 1.0, maxf(0.2, l.text.length() / chars_per_sec))


## Tinge para cinza/sépia (perda, despedida, ultimato).
static func desaturate(n: CanvasItem, color: Color = Color(0.78, 0.72, 0.62), dur: float = 0.8) -> void:
	if n == null or not is_instance_valid(n):
		return
	var tw := n.create_tween()
	tw.tween_property(n, "modulate", color, 0.1 if reduce_motion else dur)
