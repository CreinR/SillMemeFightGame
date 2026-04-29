class_name BodyPartSelector
extends Node2D

signal part_selected(part_name: String)

var selected_part: String = "romp"
var highlight_ref: BodyHighlight = null

func setup(highlight: BodyHighlight):
	highlight_ref = highlight

func _input(event: InputEvent):
	if not (event is InputEventMouseButton and event.pressed):
		return
	var local_pos = to_local(event.position)
	var clicked = _get_part_at(local_pos)
	if clicked == "":
		return
	if highlight_ref != null and not highlight_ref.valid_parts.is_empty() and clicked not in highlight_ref.valid_parts:
		return
	selected_part = clicked
	part_selected.emit(clicked)
	if highlight_ref != null:
		highlight_ref.queue_redraw()

func _get_part_at(pos: Vector2) -> String:
	if highlight_ref == null:
		return ""
	for part_name in highlight_ref.parts:
		if highlight_ref.parts[part_name]["rect"].has_point(pos):
			return part_name
	return ""
