class_name CombatPopup
extends Control

const DISPLAY_TIME  = 3.0
const FADE_IN_TIME  = 0.15
const FADE_OUT_TIME = 0.3
const SLIDE_AMOUNT  = 20.0
const FONT_SIZE     = 36
const PILL_WIDTH    = 760.0
const PILL_HEIGHT   = 60.0

var _queue: Array = []
var _state: String = "idle"  # idle | fade_in | showing | fade_out
var _timer: float = 0.0

var _bg: Panel
var _label: Label

# Resting position of the pill relative to this node's origin (centered)
const _REST_Y: float = -PILL_HEIGHT / 2.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_to_group("combat_popup")
	_build_ui()
	modulate.a = 0.0

func _build_ui() -> void:
	_bg = Panel.new()
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bg.size = Vector2(PILL_WIDTH, PILL_HEIGHT)
	_bg.position = Vector2(-PILL_WIDTH / 2.0, _REST_Y)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.7)
	style.corner_radius_top_left  = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left  = 14
	style.corner_radius_bottom_right = 14
	_bg.add_theme_stylebox_override("panel", style)
	add_child(_bg)

	_label = Label.new()
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.size = Vector2(PILL_WIDTH, PILL_HEIGHT)
	_label.position = Vector2(0, 0)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", FONT_SIZE)
	_bg.add_child(_label)

func show_message(text: String, color: Color) -> void:
	_queue.push_back({"text": text, "color": color})
	if _state == "idle":
		_start_next()

func _start_next() -> void:
	if _queue.is_empty():
		_state = "idle"
		modulate.a = 0.0
		return

	var msg = _queue.pop_front()
	_label.text = msg["text"]
	_label.add_theme_color_override("font_color", msg["color"])

	# Start below resting position, invisible
	_bg.position.y = _REST_Y + SLIDE_AMOUNT
	modulate.a = 0.0
	visible = true
	_state = "fade_in"
	_timer = 0.0

func _process(delta: float) -> void:
	if _state == "idle":
		return
	_timer += delta

	match _state:
		"fade_in":
			var t = minf(_timer / FADE_IN_TIME, 1.0)
			modulate.a = t
			_bg.position.y = _REST_Y + SLIDE_AMOUNT * (1.0 - t)
			if _timer >= FADE_IN_TIME:
				modulate.a = 1.0
				_bg.position.y = _REST_Y
				_state = "showing"
				_timer = 0.0

		"showing":
			if _timer >= DISPLAY_TIME:
				_state = "fade_out"
				_timer = 0.0

		"fade_out":
			var t = minf(_timer / FADE_OUT_TIME, 1.0)
			modulate.a = 1.0 - t
			if _timer >= FADE_OUT_TIME:
				_start_next()
