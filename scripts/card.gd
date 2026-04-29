class_name Card
extends Control

signal card_clicked

var base_position: Vector2 = Vector2.ZERO

@export var card_name: String = "Onbekend"
@export var cost: int = 1
@export var description: String = ""
@export var damage: int = 0
@export var block: int = 0
@export var card_type: String = "attack" # "attack", "block", "special"

# Combat properties (used by battle system)
@export var min_range: int = 1
@export var max_range: int = 7
@export var locks_movement: bool = false
@export var follow_up_card_name: String = ""
@export var costs_all_energy: bool = false
@export var defends_part: String = ""
@export var is_movement: bool = false
@export var move_direction: int = 0
@export var is_body_part_target: bool = false
@export var target_part: String = ""

var body_part_effects: Dictionary = {}
var combo_names: Dictionary = {}
var is_playable: bool = true
var limb_warning_level: int = 0

var _warning_dot: Label = null
var _disabled_label: Label = null
var _warning_overlay: ColorRect = null
var _checkmark_overlay: ColorRect = null
var _checkmark_label: Label = null

@onready var name_label = $Panel/VBox/Naam
@onready var desc_label = $Panel/VBox/Beschrijving
@onready var panel = $Panel
@onready var illustration = $Panel/VBox/Illustration

const TYPE_COLORS = {
	"attack":  Color(0.85, 0.25, 0.25),
	"block":   Color(0.25, 0.55, 0.85),
	"special": Color(0.6,  0.25, 0.85),
}

func _ready():
	name_label.text = card_name
	desc_label.text = description
	name_label.add_theme_font_size_override("font_size", 14)
	desc_label.add_theme_font_size_override("font_size", 11)
	desc_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	name_label.add_theme_color_override("font_color", Color.WHITE)
	_apply_style()
	_create_limb_warning_nodes()
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func is_attack() -> bool:
	if card_type in ["move", "move_disabled", "block"]:
		return false
	return card_type == "attack" or damage > 0 or not body_part_effects.is_empty()

func is_defense() -> bool:
	return card_type == "block" or defends_part != ""

func _apply_style():
	var style = StyleBoxFlat.new()
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8

	if is_body_part_target:
		style.bg_color = Color(0.08, 0.18, 0.35)
		style.border_color = Color(0.2, 0.6, 1.0)
	elif is_defense():
		style.bg_color = Color(0.1, 0.2, 0.5)
		style.border_color = Color(0.2, 0.5, 0.9)
	else:
		style.bg_color = TYPE_COLORS.get(card_type, Color(0.2, 0.2, 0.2))
		style.border_color = Color(0.1, 0.1, 0.1)

	panel.add_theme_stylebox_override("panel", style)

func set_illustration(texture: Texture2D):
	illustration.texture = texture

func _create_limb_warning_nodes():
	_warning_overlay = ColorRect.new()
	_warning_overlay.z_index = 8
	_warning_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_warning_overlay.color = Color(0.0, 0.0, 0.0, 0.42)
	_warning_overlay.anchor_right = 1.0
	_warning_overlay.anchor_bottom = 1.0
	_warning_overlay.visible = false
	add_child(_warning_overlay)

	_warning_dot = Label.new()
	_warning_dot.z_index = 10
	_warning_dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_warning_dot.text = "!"
	_warning_dot.add_theme_font_size_override("font_size", 13)
	_warning_dot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_warning_dot.position = Vector2(100, 3)
	_warning_dot.size = Vector2(16, 16)
	_warning_dot.visible = false
	add_child(_warning_dot)

	_disabled_label = Label.new()
	_disabled_label.z_index = 10
	_disabled_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_disabled_label.text = "DISABLED"
	_disabled_label.add_theme_font_size_override("font_size", 11)
	_disabled_label.add_theme_color_override("font_color", Color(1.0, 0.25, 0.25))
	_disabled_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_disabled_label.position = Vector2(5, 78)
	_disabled_label.size = Vector2(110, 18)
	_disabled_label.visible = false
	add_child(_disabled_label)

	_checkmark_overlay = ColorRect.new()
	_checkmark_overlay.z_index = 9
	_checkmark_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_checkmark_overlay.color = Color(0.0, 0.55, 0.15, 0.45)
	_checkmark_overlay.anchor_right = 1.0
	_checkmark_overlay.anchor_bottom = 1.0
	_checkmark_overlay.visible = false
	add_child(_checkmark_overlay)

	_checkmark_label = Label.new()
	_checkmark_label.z_index = 11
	_checkmark_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_checkmark_label.text = "✓"
	_checkmark_label.add_theme_font_size_override("font_size", 28)
	_checkmark_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4))
	_checkmark_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_checkmark_label.position = Vector2(0, 35)
	_checkmark_label.size = Vector2(120, 40)
	_checkmark_label.visible = false
	add_child(_checkmark_label)

func set_limb_warning(level: int):
	limb_warning_level = level
	if _warning_dot == null:
		return
	match level:
		0:
			_warning_dot.visible = false
			_warning_overlay.visible = false
			_disabled_label.visible = false
		1:
			_warning_dot.add_theme_color_override("font_color", Color(1.0, 0.55, 0.0))
			_warning_dot.visible = true
			_warning_overlay.visible = false
			_disabled_label.visible = false
		2:
			_warning_dot.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
			_warning_dot.visible = true
			_warning_overlay.visible = false
			_disabled_label.visible = false
		3:
			_warning_dot.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
			_warning_dot.visible = true
			_warning_overlay.visible = true
			_disabled_label.visible = true

func show_checkmark():
	if _checkmark_overlay != null:
		_checkmark_overlay.visible = true
	if _checkmark_label != null:
		_checkmark_label.visible = true

func set_playable(playable: bool):
	is_playable = playable
	modulate = Color.WHITE if playable else Color(0.45, 0.45, 0.45, 0.75)

func show_as_combo(part: String):
	name_label.text = combo_names.get(part, card_name)
	desc_label.text = _combo_description(part)
	var style = StyleBoxFlat.new()
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.bg_color = Color(0.55, 0.08, 0.08)
	style.border_color = Color(1.0, 0.55, 0.0)
	panel.add_theme_stylebox_override("panel", style)
	name_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.1))

func _combo_description(part: String) -> String:
	if not body_part_effects.has(part):
		return description
	var fx = body_part_effects[part]
	var lines: Array = []
	if fx.has("damage"):
		lines.append("%d damage" % fx["damage"])
	if fx.has("effect"):
		match fx["effect"]:
			"stun":   lines.append("+ Stun!")
			"weaken": lines.append("+ -%d enemy attack" % fx.get("value", 3))
			"heal":   lines.append("+ %d heal" % fx.get("value", 5))
	return "\n".join(lines)

func play(player, enemy):
	# damage and body_part_effects are applied by battle.gd
	if defends_part != "":
		player.defending_part = defends_part
	if locks_movement:
		player.movement_locked = true
	if follow_up_card_name != "":
		var follow_up = _create_follow_up(follow_up_card_name)
		player.pending_cards.append(follow_up)

func _create_follow_up(fname: String) -> Card:
	var c = Card.new()
	match fname:
		"Aim Gun":
			c.card_name = "Aim Gun"
			c.cost = 0
			c.costs_all_energy = true
			c.description = "Aim your weapon.\nCan no longer move.\nNext turn: Fire Gun"
			c.locks_movement = true
			c.follow_up_card_name = "Fire Gun"
		"Fire Gun":
			c.card_name = "Fire Gun"
			c.cost = 0
			c.costs_all_energy = true
			c.description = "Fire! 200 damage"
			c.damage = 200
			c.min_range = 1
			c.max_range = 5
	return c

func _on_mouse_entered():
	if not is_playable:
		return
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	tween.tween_property(self, "position", base_position + Vector2(0, -50), 0.15)
	z_index = 100

func _on_mouse_exited():
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	tween.tween_property(self, "position", base_position, 0.15)
	z_index = 0

func _gui_input(event: InputEvent):
	if not is_playable:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		card_clicked.emit()
