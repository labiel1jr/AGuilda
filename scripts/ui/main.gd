extends Control
class_name GuildUI
## Cena principal (GDD §8): guarda o estado da interface (party em montagem, mapa aberto, momentos)
## e as cores. As telas ficam em scripts/ui/screens/ (HubScreen, PartyScreen, ExpeditionScreen,
## ResultScreen, GuildScreens, ItemScreens, StoryScreens, TitleScreen) e as peças em
## scripts/ui/components/ (UIKit, Widgets, Moments). Os repasses no fim mantêm a API usada por
## botões, sinais e testes (main.show_hub(), main._on_dispatch(m)...). A regra fica no GameState.

const C_BG := Color("#2b2118")
const C_PANEL := Color("#3d2f22")
const C_PARCHMENT := Color("#e8d9b5")
const C_INK := Color("#2a1f14")
const C_GOLD := Color("#d4a94a")
const C_TEXT := Color("#f1e6cc")
const C_MUTED := Color("#b5a283")
const C_GOOD := Color("#7fb069")
const C_BAD := Color("#d1603d")
const RISK_COLORS := {"baixo": Color("#7fb069"), "medio": Color("#d4a94a"), "alto": Color("#d1603d"), "lendario": Color("#a26ad1")}
const OUTCOME_COLORS := {"limpo": Color("#7fb069"), "custo": Color("#d4a94a"), "falha": Color("#d1603d")}

const MagicMap := preload("res://scripts/ui/magic_map.gd")
const GuildBook := preload("res://scripts/ui/guild_book.gd")
const Portrait := preload("res://scripts/ui/portrait.gd")
const WaxSeal := preload("res://scripts/ui/wax_seal.gd")

var gs  # GameState
var root: VBoxContainer
var title_bg: TextureRect   # arte da tela de título (só visível no título)

const TITLE_ART := "res://art/geralimagem/titulo.png"
var selected: Array = []
var prepared: Dictionary = {}   # magia preparada por conjurador na montagem de party
var last_result := {}
var moments_enabled := true     # encenar ruptura/saída (os testes de screenshot desligam)
var _moment_open := false
var _moment_layer: Control = null
var _fresh_day := false
var _last_toggle := ""
var _map_prev := {}
var _dice_box: Control = null


func _ready() -> void:
	gs = get_node("/root/GameState")
	Juice.load_settings()
	var bg := ColorRect.new()
	bg.color = C_BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	title_bg = TextureRect.new()
	title_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	title_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	title_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	title_bg.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	title_bg.visible = false
	if ResourceLoader.exists(TITLE_ART):
		title_bg.texture = load(TITLE_ART)
	add_child(title_bg)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	add_child(margin)
	root = VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	margin.add_child(root)
	TitleScreen.show_title(self)


# Estado do Mapa Mágico aberto (ExpeditionScreen)
var _map
var _map_party: VBoxContainer
var _map_status: Label
var _map_log: VBoxContainer
var _map_scroll: ScrollContainer
var _map_action: VBoxContainer

# Dupla escolhida no Salão de Treinamento (GuildScreens)
var _train_pick: Array = []


## Limpa a tela atual (cada tela chama antes de se montar).
func _clear() -> void:
	title_bg.visible = false
	title_bg.modulate = Color.WHITE
	if is_instance_valid(_dice_box):
		_dice_box.queue_free()   # a rolagem é só da tela do mapa
	if ResourceLoader.exists(TITLE_ART):
		title_bg.texture = load(TITLE_ART)
	root.modulate = Color.WHITE
	for c in root.get_children():
		c.queue_free()


# ================= Repasses para as telas (API usada por botões, sinais e testes) =================

func _play_moments() -> void:
	Moments.play_moments(self)


func show_hub() -> void:
	HubScreen.show_hub(self)


func _on_end_day() -> void:
	HubScreen.on_end_day(self)


func show_party(m: Dictionary) -> void:
	PartyScreen.show_party(self, m)


func _render_party(m: Dictionary) -> void:
	PartyScreen.render_party(self, m)


func _toggle_hero(m: Dictionary, id: String) -> void:
	PartyScreen.toggle_hero(self, m, id)


func _on_dispatch(m: Dictionary) -> void:
	PartyScreen.on_dispatch(self, m)


func show_map(m: Dictionary) -> void:
	ExpeditionScreen.show_map(self, m)


func _map_refresh() -> void:
	ExpeditionScreen.map_refresh(self)


func _on_node_chosen(pos: Array) -> void:
	ExpeditionScreen.on_node_chosen(self, pos)


func _on_node_arrived(pos: Array) -> void:
	ExpeditionScreen.on_node_arrived(self, pos)


func _show_call(ev: Dictionary, caller: String) -> void:
	ExpeditionScreen.show_call(self, ev, caller)


func _on_call_choice(opt: Dictionary) -> void:
	ExpeditionScreen.on_call_choice(self, opt)


func _roll_dice(d: Dictionary, done: Callable) -> void:
	ExpeditionScreen.roll_dice(self, d, done)


func _show_shop(stock: Array) -> void:
	ExpeditionScreen.show_shop(self, stock)


func _on_face_boss() -> void:
	ExpeditionScreen.on_face_boss(self)


func show_result(res: Dictionary) -> void:
	ResultScreen.show_result(self, res)


func _after_result() -> void:
	ResultScreen.after_result(self)


func show_bond_event(ev: Dictionary) -> void:
	ResultScreen.show_bond_event(self, ev)


func _on_label_chosen(ev: Dictionary, lbl: String) -> void:
	ResultScreen.on_label_chosen(self, ev, lbl)


func show_levelup(entry: Dictionary) -> void:
	ResultScreen.show_levelup(self, entry)


func show_backstage(bs: Dictionary) -> void:
	GuildScreens.show_backstage(self, bs)


func _on_backstage_choice(bs: Dictionary, choice: Dictionary) -> void:
	GuildScreens.on_backstage_choice(self, bs, choice)


func show_relations() -> void:
	GuildScreens.show_relations(self)


func show_book(index: int) -> void:
	GuildScreens.show_book(self, index)


func show_upgrades() -> void:
	GuildScreens.show_upgrades(self)


func show_training() -> void:
	GuildScreens.show_training(self)


func show_ultimatum(u: Dictionary) -> void:
	GuildScreens.show_ultimatum(self, u)


func show_market() -> void:
	ItemScreens.show_market(self)


func show_equip(index: int) -> void:
	ItemScreens.show_equip(self, index)


func show_cast(caster: String, sid: String, back_index: int) -> void:
	ItemScreens.show_cast(self, caster, sid, back_index)


func show_chapter_intro() -> void:
	StoryScreens.show_chapter_intro(self)


func show_chapter_end() -> void:
	StoryScreens.show_chapter_end(self)


func show_ending() -> void:
	StoryScreens.show_ending(self)


func show_epilogue() -> void:
	StoryScreens.show_epilogue(self)


func show_title() -> void:
	TitleScreen.show_title(self)


func show_menu() -> void:
	TitleScreen.show_menu(self)


func show_load(from_title: bool) -> void:
	TitleScreen.show_load(self, from_title)


func _on_new_game() -> void:
	TitleScreen.on_new_game(self)
