extends Control

signal body_part_selected(part: String)

var selected_part: String = "borst"
var hovered_part: String = ""
var _texture: Texture2D = null
var _body_parts: Dictionary = {}

func update_body_parts(bparts: Dictionary):
	_body_parts = bparts
	queue_redraw()

func _ready():
	custom_minimum_size = Vector2(80, 80)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var path = "res://assets/cards/Kickbokser.png"
	if ResourceLoader.exists(path):
		_texture = load(path)

func _get_part_rects() -> Dictionary:
	var cx = size.x / 2.0
	return {
		"hoofd":      Rect2(cx - 13, 0,  26, 26),
		"borst":      Rect2(cx - 10, 26, 20, 26),
		"bovenbenen": Rect2(cx - 12, 52, 24, 11),
		"voeten":     Rect2(cx - 12, 63, 24, 12),
	}

func _get_part_at(pos: Vector2) -> String:
	for part in _get_part_rects():
		if _get_part_rects()[part].has_point(pos):
			return part
	return ""

func _gui_input(event: InputEvent):
	if event is InputEventMouseMotion:
		var part = _get_part_at(event.position)
		if part != hovered_part:
			hovered_part = part
			queue_redraw()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var part = _get_part_at(event.position)
		if part != "":
			selected_part = part
			body_part_selected.emit(part)
			queue_redraw()

func _draw():
	if _texture != null:
		var tex_size = Vector2(_texture.get_width(), _texture.get_height())
		var scale = min(size.x / tex_size.x, size.y / tex_size.y)
		var draw_size = tex_size * scale
		var offset = (size - draw_size) / 2.0
		draw_texture_rect(_texture, Rect2(offset, draw_size), false)

	for part in _get_part_rects():
		var rect = _get_part_rects()[part]
		if _body_parts.has(part):
			var bp = _body_parts[part]
			var col: Color
			match bp.status:
				BodyPart.Status.HEALTHY:  col = Color(0.2, 0.8, 0.2, 0.15)
				BodyPart.Status.BRUISED:  col = Color(0.8, 0.8, 0.2, 0.30)
				BodyPart.Status.BROKEN:   col = Color(0.8, 0.4, 0.2, 0.45)
				BodyPart.Status.DISABLED: col = Color(0.8, 0.2, 0.2, 0.60)
				_:                        col = Color(0.2, 0.8, 0.2, 0.15)
			draw_rect(rect, col, true)

		if part == selected_part:
			draw_rect(rect, Color(0.0, 0.8, 1.0, 0.3))
			draw_rect(rect, Color(0.0, 0.8, 1.0, 0.9), false, 1.5)
		elif part == hovered_part:
			draw_rect(rect, Color(1.0, 1.0, 1.0, 0.2))
			draw_rect(rect, Color(1.0, 1.0, 1.0, 0.5), false, 1.0)
