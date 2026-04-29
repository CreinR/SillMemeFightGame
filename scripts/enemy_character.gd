extends Control

var selected_part: String = "borst"

func _ready():
	custom_minimum_size = Vector2(80, 80)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _get_part_rects() -> Dictionary:
	var cx = size.x / 2.0
	return {
		"hoofd":      Rect2(cx - 14, 0,  28, 26),
		"borst":      Rect2(cx - 13, 25, 26, 27),
		"bovenbenen": Rect2(cx - 12, 52, 24, 11),
		"voeten":     Rect2(cx - 12, 63, 24, 12),
	}

func _draw():
	var cx = size.x / 2.0
	var body_color = Color(0.7, 0.15, 0.15)
	var dark_color = Color(0.45, 0.05, 0.05)
	var skin_color = Color(0.6, 0.85, 0.5)

	# Legs
	draw_line(Vector2(cx - 6, 52), Vector2(cx - 14, 74), dark_color, 6)
	draw_line(Vector2(cx + 6, 52), Vector2(cx + 14, 74), dark_color, 6)

	# Body
	draw_rect(Rect2(cx - 13, 24, 26, 28), dark_color)
	draw_rect(Rect2(cx - 11, 25, 22, 26), body_color)

	# Arms
	draw_line(Vector2(cx - 13, 28), Vector2(cx - 26, 18), body_color, 5)
	draw_line(Vector2(cx + 13, 28), Vector2(cx + 26, 18), body_color, 5)

	# Neck
	draw_rect(Rect2(cx - 4, 17, 8, 8), skin_color)

	# Head
	draw_circle(Vector2(cx, 11), 14, skin_color)

	# Horns
	draw_line(Vector2(cx - 8, 0), Vector2(cx - 14, -10), dark_color, 4)
	draw_line(Vector2(cx + 8, 0), Vector2(cx + 14, -10), dark_color, 4)

	# Eyes
	draw_circle(Vector2(cx - 5, 9), 3.5, Color(0.9, 0.05, 0.05))
	draw_circle(Vector2(cx + 5, 9), 3.5, Color(0.9, 0.05, 0.05))
	draw_circle(Vector2(cx - 5, 9), 1.5, Color.BLACK)
	draw_circle(Vector2(cx + 5, 9), 1.5, Color.BLACK)

	# Mouth
	draw_arc(Vector2(cx, 18), 5, PI + 0.3, 2 * PI - 0.3, 8, Color(0.1, 0.0, 0.0), 2)
	draw_line(Vector2(cx - 4, 16), Vector2(cx - 2, 18), Color(0.8, 0.8, 0.8), 1.5)
	draw_line(Vector2(cx + 4, 16), Vector2(cx + 2, 18), Color(0.8, 0.8, 0.8), 1.5)

	# Highlight the body part the enemy will attack
	for part in _get_part_rects():
		if part == selected_part:
			var rect = _get_part_rects()[part]
			draw_rect(rect, Color(1.0, 0.2, 0.2, 0.35))
			draw_rect(rect, Color(1.0, 0.2, 0.2, 0.9), false, 1.5)
