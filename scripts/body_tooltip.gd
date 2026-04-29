class_name BodyTooltip
extends Control

const BG_COLOR     := Color(0.1, 0.1, 0.1, 0.85)
const TEXT_COLOR   := Color(1.0, 1.0, 1.0, 1.0)
const RED_COLOR    := Color(1.0, 0.35, 0.35, 1.0)
const ORANGE_COLOR := Color(1.0, 0.65, 0.1, 1.0)
const DIM_COLOR    := Color(0.55, 0.55, 0.55, 1.0)
const FONT_SIZE    := 11
const HEADER_SIZE  := 12
const MIN_W        := 230.0

const ICONS := {
	"heart": "❤", "brain": "🧠", "spine": "🦴",
	"lung": "🫁", "ribs": "💀", "jaw": "🦷",
	"elbow": "💪", "wrist": "✊", "kneecap": "🦵", "thigh": "🦵",
}
const SUB_NAMES := {
	"heart": "Heart", "brain": "Brain", "spine": "Spine",
	"lung": "Lung",   "ribs": "Ribs",   "jaw": "Jaw",
	"elbow": "Elbow", "wrist": "Wrist", "kneecap": "Kneecap", "thigh": "Thigh",
}
const PART_DISPLAY := {
	"hoofd": "Head",           "borst": "Chest",
	"linkerarm": "Left Arm",   "rechterarm": "Right Arm",
	"bovenbenen": "Upper Legs", "voeten": "Feet",
	"linkerbeen": "Left Leg",  "rechterbeen": "Right Leg",
}
const STATUS_LABELS := ["HEALTHY", "BRUISED", "BROKEN", "DISABLED"]
const FATAL_EFFECTS := ["heart", "brain", "spine"]

var _timer:  Timer         = null
var _panel:  PanelContainer = null
var _vbox:   VBoxContainer  = null

var _pending_part:  String         = ""
var _pending_bp:    BodyPart       = null
var _pending_rect:  Rect2          = Rect2()
var _pending_side:  String         = "left"
var _pending_stats: CharacterStats = null
var _active: bool                  = false

func _ready():
	visible = false
	mouse_filter = MOUSE_FILTER_IGNORE
	z_index = 200

	_timer = Timer.new()
	_timer.one_shot = true
	_timer.wait_time = 0.2
	_timer.timeout.connect(_on_timer)
	add_child(_timer)

	var bg = StyleBoxFlat.new()
	bg.bg_color = BG_COLOR
	bg.border_color = Color(0.4, 0.4, 0.4, 0.9)
	bg.border_width_left   = 1; bg.border_width_right  = 1
	bg.border_width_top    = 1; bg.border_width_bottom = 1
	bg.corner_radius_top_left    = 5; bg.corner_radius_top_right    = 5
	bg.corner_radius_bottom_left = 5; bg.corner_radius_bottom_right = 5
	bg.content_margin_left  = 10; bg.content_margin_right  = 10
	bg.content_margin_top   = 7;  bg.content_margin_bottom = 7

	_panel = PanelContainer.new()
	_panel.mouse_filter = MOUSE_FILTER_IGNORE
	_panel.add_theme_stylebox_override("panel", bg)
	add_child(_panel)

	_vbox = VBoxContainer.new()
	_vbox.mouse_filter = MOUSE_FILTER_IGNORE
	_vbox.add_theme_constant_override("separation", 2)
	_panel.add_child(_vbox)

func queue_show(part_name: String, bp: BodyPart, screen_rect: Rect2, side: String, cs: CharacterStats = null):
	_pending_part  = part_name
	_pending_bp    = bp
	_pending_rect  = screen_rect
	_pending_side  = side
	_pending_stats = cs
	_active = true
	_timer.start()

func cancel():
	_active = false
	_timer.stop()
	visible = false

func _on_timer():
	if not _active:
		return
	_build()
	visible = false
	await get_tree().process_frame
	await get_tree().process_frame
	if not _active:
		return
	_do_position()
	visible = true

func _build():
	while _vbox.get_child_count() > 0:
		_vbox.get_child(0).free()

	_add_label(
		"%s — %s" % [PART_DISPLAY.get(_pending_part, _pending_part),
		             STATUS_LABELS[_pending_bp.status]],
		TEXT_COLOR, HEADER_SIZE
	)
	_add_sep()

	if _pending_bp.sub_parts.is_empty():
		_add_label("No injuries detected", DIM_COLOR, FONT_SIZE)
		_build_stat_bars()
		return

	var any_damaged = false
	for sub in _pending_bp.sub_parts:
		if sub["hp"] < sub.get("max_hp", 1):
			any_damaged = true
			break

	if not any_damaged:
		_add_label("No injuries detected", DIM_COLOR, FONT_SIZE)
		_build_stat_bars()
		return

	var fatal_subs: Array = []
	var other_subs: Array = []
	for sub in _pending_bp.sub_parts:
		if sub["effect"] in FATAL_EFFECTS:
			fatal_subs.append(sub)
		else:
			other_subs.append(sub)

	for sub in (fatal_subs + other_subs):
		var entry = _sub_entry(sub)
		_add_label(entry["text"], entry["color"], FONT_SIZE)

	_build_stat_bars()

func _build_stat_bars() -> void:
	if _pending_stats == null:
		return
	_add_sep()
	_add_stat_row("Durability", _pending_stats.get_durability(_pending_part))
	_add_stat_row("Toughness",  _pending_stats.get_toughness(_pending_part))
	if _pending_stats.has_power(_pending_part):
		_add_stat_row("Power", _pending_stats.get_power(_pending_part))
	if _pending_stats.has_speed(_pending_part):
		_add_stat_row("Speed", _pending_stats.get_speed(_pending_part))

func _sub_entry(sub: Dictionary) -> Dictionary:
	var effect  = sub["effect"]
	var icon    = ICONS.get(effect, "•")
	var dname   = SUB_NAMES.get(effect, effect)
	var hp      = sub["hp"]
	var max_hp  = sub.get("max_hp", 1)
	var is_fat  = effect in FATAL_EFFECTS

	var status_str: String
	var color: Color

	if is_fat:
		if hp <= 0:
			status_str = "DESTROYED"; color = RED_COLOR
		elif hp < max_hp:
			if effect == "brain":
				status_str = ("CONCUSSED (%d/3)" % hp) if hp > 1 else "CRITICAL (1/3)"
			elif effect == "spine":
				status_str = "COMPRESSED (1/2)"
			else:
				status_str = "%d/%d" % [hp, max_hp]
			color = ORANGE_COLOR
		else:
			status_str = "INTACT"; color = DIM_COLOR
	else:
		if hp <= 0:
			status_str = "HIT";    color = RED_COLOR
		else:
			status_str = "INTACT"; color = DIM_COLOR

	return {"text": "%s %s — %s" % [icon, dname, status_str], "color": color}

func _add_label(text: String, color: Color, font_size: int):
	var lbl = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", color)
	lbl.mouse_filter = MOUSE_FILTER_IGNORE
	lbl.custom_minimum_size = Vector2(MIN_W - 20.0, 0)
	_vbox.add_child(lbl)

func _add_sep():
	var sep = HSeparator.new()
	sep.mouse_filter = MOUSE_FILTER_IGNORE
	var style = StyleBoxLine.new()
	style.color = Color(0.38, 0.38, 0.38, 0.85)
	style.thickness = 1
	sep.add_theme_stylebox_override("separator", style)
	_vbox.add_child(sep)

func _add_stat_row(stat_name: String, value: float) -> void:
	const THRESHOLDS := [0.5, 0.7, 0.9, 1.1, 1.3]
	var bar := ""
	for t in THRESHOLDS:
		bar += "■" if value >= t else "□"

	var color: Color
	if value > 1.05:
		color = Color(0.3, 0.9, 0.3)
	elif value < 0.95:
		color = Color(1.0, 0.45, 0.45)
	else:
		color = DIM_COLOR

	var hbox = HBoxContainer.new()
	hbox.mouse_filter = MOUSE_FILTER_IGNORE
	hbox.add_theme_constant_override("separation", 4)
	_vbox.add_child(hbox)

	var name_lbl = Label.new()
	name_lbl.text = stat_name
	name_lbl.add_theme_font_size_override("font_size", FONT_SIZE)
	name_lbl.add_theme_color_override("font_color", DIM_COLOR)
	name_lbl.mouse_filter = MOUSE_FILTER_IGNORE
	name_lbl.custom_minimum_size = Vector2(80, 0)
	hbox.add_child(name_lbl)

	var bar_lbl = Label.new()
	bar_lbl.text = bar
	bar_lbl.add_theme_font_size_override("font_size", FONT_SIZE)
	bar_lbl.add_theme_color_override("font_color", color)
	bar_lbl.mouse_filter = MOUSE_FILTER_IGNORE
	hbox.add_child(bar_lbl)

	var val_lbl = Label.new()
	val_lbl.text = " %.1f" % value
	val_lbl.add_theme_font_size_override("font_size", FONT_SIZE)
	val_lbl.add_theme_color_override("font_color", color)
	val_lbl.mouse_filter = MOUSE_FILTER_IGNORE
	hbox.add_child(val_lbl)

func _do_position():
	var sz  = _panel.size
	if sz.x < 4:
		sz = Vector2(MIN_W, 80)
	var vp  = get_viewport_rect().size
	var r   = _pending_rect
	var pos: Vector2

	if _pending_side == "left":
		pos = Vector2(r.position.x - sz.x - 8, r.position.y - 10)
	else:
		pos = Vector2(r.position.x + r.size.x + 8, r.position.y - 10)

	pos.x = clamp(pos.x, 4.0, vp.x - sz.x - 4.0)
	pos.y = clamp(pos.y, 4.0, vp.y - sz.y - 4.0)
	position = pos
