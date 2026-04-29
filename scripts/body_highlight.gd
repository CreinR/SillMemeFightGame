class_name BodyHighlight
extends Node2D

var parts = {
	"hoofd":      {"rect": Rect2(-20, -150, 40,  55), "flash": false},
	"borst":      {"rect": Rect2(-30,  -92, 60,  75), "flash": false},
	"linkerarm":  {"rect": Rect2(-60,  -92, 26,  65), "flash": false},
	"rechterarm": {"rect": Rect2( 34,  -92, 26,  65), "flash": false},
	"bovenbenen": {"rect": Rect2(-30,  -15, 26,  45), "flash": false},
	"voeten":     {"rect": Rect2(  4,  -15, 26,  45), "flash": false},
}

const HEALTHY_COLOR  = Color(0.2, 0.8, 0.2, 0.3)
const BRUISED_COLOR  = Color(0.8, 0.8, 0.2, 0.4)
const BROKEN_COLOR   = Color(0.8, 0.4, 0.2, 0.5)
const DISABLED_COLOR = Color(0.8, 0.2, 0.2, 0.6)
const FLASH_COLOR    = Color(1.0, 1.0, 1.0, 0.9)
const INACTIVE_COLOR = Color(0.12, 0.12, 0.12, 0.55)
const DANGER_COLOR   = Color(0.95, 0.1, 0.1, 0.5)

var enemy_ref: Enemy = null
var valid_parts: Array = []
var _tooltip = null
var _hovered_part: String = ""

func setup(enemy: Enemy, tooltip = null):
	enemy_ref = enemy
	_tooltip  = tooltip
	queue_redraw()

func _has_damaged_fatal_organ(part_name: String) -> bool:
	if enemy_ref == null:
		return false
	var bp = enemy_ref.body_parts.get(part_name)
	if bp == null:
		return false
	for sub in bp.sub_parts:
		if sub["effect"] in ["brain", "spine", "heart"] and sub["hp"] < sub.get("max_hp", 1):
			return true
	return false

func set_valid_parts(arr: Array):
	valid_parts = arr
	queue_redraw()

func highlight(part_name: String):
	if not parts.has(part_name):
		return
	parts[part_name]["flash"] = true
	queue_redraw()
	var tween = create_tween()
	tween.tween_interval(0.3)
	tween.tween_callback(func():
		parts[part_name]["flash"] = false
		queue_redraw()
	)

func _input(event: InputEvent):
	if _tooltip == null or not (event is InputEventMouseMotion):
		return
	var local = to_local(event.position)
	var hit   = ""
	for pname in parts:
		if parts[pname]["rect"].has_point(local):
			hit = pname
			break
	if hit == _hovered_part:
		return
	_hovered_part = hit
	if hit == "":
		_tooltip.cancel()
	elif enemy_ref != null and enemy_ref.body_parts.has(hit):
		var bp   = enemy_ref.body_parts[hit]
		var rect = parts[hit]["rect"]
		_tooltip.queue_show(hit, bp, Rect2(to_global(rect.position), rect.size), "left")

func _draw():
	if enemy_ref == null:
		return
	for part_name in parts:
		var part_data = parts[part_name]
		var rect = part_data["rect"]

		var is_active = valid_parts.is_empty() or part_name in valid_parts

		var draw_color: Color
		if part_data["flash"]:
			draw_color = FLASH_COLOR
		elif not is_active:
			draw_color = INACTIVE_COLOR
		elif enemy_ref.body_parts.has(part_name):
			var bp = enemy_ref.body_parts[part_name]
			match bp.status:
				BodyPart.Status.HEALTHY:  draw_color = HEALTHY_COLOR
				BodyPart.Status.BRUISED:  draw_color = BRUISED_COLOR
				BodyPart.Status.BROKEN:   draw_color = BROKEN_COLOR
				BodyPart.Status.DISABLED: draw_color = DISABLED_COLOR
				_:                        draw_color = HEALTHY_COLOR
		else:
			draw_color = HEALTHY_COLOR

		draw_rect(rect, draw_color, true)
		if not part_data["flash"] and is_active and _has_damaged_fatal_organ(part_name):
			draw_rect(rect, DANGER_COLOR, true)
		draw_rect(rect, Color(0.5, 0.5, 0.5) if not is_active else Color.BLACK, false)
		draw_string(
			ThemeDB.fallback_font,
			Vector2(rect.position.x, rect.position.y - 4),
			part_name,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1, 10,
			Color(0.4, 0.4, 0.4) if not is_active else Color.WHITE
		)
