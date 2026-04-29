extends Control

@onready var label = $Label
@onready var retry_button = $RetryButton
@onready var menu_button = $MenuButton

func _ready():
	label.add_theme_font_size_override("font_size", 72)
	label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
	_style_button(retry_button, Color(0.5, 0.1, 0.1), Color(0.9, 0.2, 0.2))
	_style_button(menu_button, Color(0.15, 0.15, 0.35), Color(0.4, 0.4, 0.8))
	retry_button.pressed.connect(_on_retry)
	menu_button.pressed.connect(_on_menu)

func _style_button(btn: Button, bg: Color, border: Color):
	var style = StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_font_size_override("font_size", 18)

func _on_retry():
	get_tree().change_scene_to_file("res://scenes/battle.tscn")

func _on_menu():
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
