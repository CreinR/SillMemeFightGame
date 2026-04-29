extends Control

@onready var title = $Title
@onready var play_button = $PlayButton
@onready var quit_button = $QuitButton

func _ready():
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", Color(0.9, 0.8, 0.2))

	_style_button(play_button, Color(0.2, 0.5, 0.2), Color(0.4, 0.9, 0.4))
	_style_button(quit_button, Color(0.4, 0.1, 0.1), Color(0.8, 0.2, 0.2))

	play_button.pressed.connect(_on_play)
	quit_button.pressed.connect(_on_quit)

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
	btn.add_theme_font_size_override("font_size", 20)

func _on_play():
	get_tree().change_scene_to_file("res://scenes/character_select.tscn")

func _on_quit():
	get_tree().quit()
