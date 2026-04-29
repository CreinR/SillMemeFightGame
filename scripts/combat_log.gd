class_name CombatLog
extends VBoxContainer

const MAX_LINES = 5
var lines = []

func add_entry(message: String, color: Color = Color.WHITE):
	var label = Label.new()
	label.text = "> " + message
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", 11)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	add_child(label)
	lines.append(label)

	if lines.size() > MAX_LINES:
		lines[0].queue_free()
		lines.pop_front()

func log_attack(message: String):
	add_entry(message, Color(1, 0.4, 0.4))

func log_status(message: String):
	add_entry(message, Color(1, 0.8, 0.2))

func log_enemy(message: String):
	add_entry(message, Color(0.4, 0.7, 1))

func log_info(message: String):
	add_entry(message, Color(0.8, 0.8, 0.8))
