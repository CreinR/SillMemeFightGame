extends Control

const CHARACTERS = [
	{
		"name": "Kickboxer",
		"hp": 90,
		"energy": 3,
		"description": "Fights up close\nwith hard hits.\n\nHP: 90  |  Energy: 3\n\nDeck: Attacks,\nHeavy Strikes.",
		"deck_type": "kickbokser",
		"bg_color": Color(0.45, 0.12, 0.02),
		"accent": Color(1.0, 0.45, 0.05),
		"icon": "🥊",
		"image": "res://assets/cards/Kickbokser.png"
	}
]

var selected_index: int = 0
var char_panels: Array = []

func _ready():
	_build_ui()

func _build_ui():
	var title = Label.new()
	title.text = "Selecteer je Karakter"
	title.position = Vector2(0, 55)
	title.size = Vector2(1152, 65)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color(0.9, 0.8, 0.2))
	add_child(title)

	var panel_w = 320.0
	var panel_h = 390.0
	var sx = (1152.0 - panel_w) / 2.0
	var sy = 150.0

	for i in CHARACTERS.size():
		var panel = _make_char_panel(CHARACTERS[i], Vector2(sx, sy), Vector2(panel_w, panel_h))
		panel.gui_input.connect(_on_panel_input.bind(i))
		add_child(panel)
		char_panels.append(panel)

	var start_btn = _make_button("Start Battle", Vector2(426, 572), Vector2(300, 52), Color(0.18, 0.45, 0.18), Color(0.35, 0.85, 0.35))
	start_btn.pressed.connect(_on_start)
	add_child(start_btn)

	var back_btn = _make_button("Back", Vector2(96, 572), Vector2(170, 52), Color(0.28, 0.08, 0.08), Color(0.7, 0.18, 0.18))
	back_btn.pressed.connect(_on_back)
	add_child(back_btn)

	_refresh_selection()

func _make_char_panel(c: Dictionary, pos: Vector2, sz: Vector2) -> Panel:
	var panel = Panel.new()
	panel.position = pos
	panel.size = sz
	panel.mouse_filter = Control.MOUSE_FILTER_STOP

	var art_w = sz.x - 16
	var art_h = 145

	var art_bg = ColorRect.new()
	art_bg.position = Vector2(8, 8)
	art_bg.size = Vector2(art_w, art_h)
	art_bg.color = c["bg_color"]
	art_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(art_bg)

	var img_path = c.get("image", "")
	if img_path != "" and ResourceLoader.exists(img_path):
		var art = load("res://scripts/art_display.gd").new()
		art.texture = load(img_path)
		art.position = Vector2(8, 8)
		art.size = Vector2(art_w, art_h)
		panel.add_child(art)
	else:
		var icon = Label.new()
		icon.text = c["icon"]
		icon.position = Vector2(8, 8)
		icon.size = Vector2(art_w, art_h)
		icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		icon.add_theme_font_size_override("font_size", 72)
		icon.add_theme_color_override("font_color", Color.WHITE)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(icon)

	var name_lbl = Label.new()
	name_lbl.text = c["name"]
	name_lbl.position = Vector2(8, 160)
	name_lbl.size = Vector2(sz.x - 16, 34)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 22)
	name_lbl.add_theme_color_override("font_color", Color.WHITE)
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(name_lbl)

	var stats_lbl = Label.new()
	stats_lbl.text = "HP: %d     Energy: %d" % [c["hp"], c["energy"]]
	stats_lbl.position = Vector2(8, 198)
	stats_lbl.size = Vector2(sz.x - 16, 26)
	stats_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_lbl.add_theme_font_size_override("font_size", 13)
	stats_lbl.add_theme_color_override("font_color", c["accent"])
	stats_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(stats_lbl)

	var sep = ColorRect.new()
	sep.position = Vector2(12, 230)
	sep.size = Vector2(sz.x - 24, 1)
	sep.color = c["accent"].darkened(0.4)
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(sep)

	var desc_lbl = Label.new()
	desc_lbl.text = c["description"]
	desc_lbl.position = Vector2(14, 238)
	desc_lbl.size = Vector2(sz.x - 28, 145)
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_lbl.add_theme_font_size_override("font_size", 13)
	desc_lbl.add_theme_color_override("font_color", Color(0.78, 0.78, 0.78))
	desc_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(desc_lbl)

	if c.get("disabled", false):
		var overlay = ColorRect.new()
		overlay.position = Vector2(0, 0)
		overlay.size = sz
		overlay.color = Color(0.0, 0.0, 0.0, 0.6)
		overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(overlay)

		var soon_lbl = Label.new()
		soon_lbl.text = "Coming\nSoon"
		soon_lbl.position = Vector2(0, 0)
		soon_lbl.size = sz
		soon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		soon_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		soon_lbl.add_theme_font_size_override("font_size", 20)
		soon_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		soon_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(soon_lbl)

	return panel

func _make_button(txt: String, pos: Vector2, sz: Vector2, bg: Color, border: Color) -> Button:
	var btn = Button.new()
	btn.text = txt
	btn.position = pos
	btn.size = sz
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
	return btn

func _on_panel_input(event: InputEvent, index: int):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if CHARACTERS[index].get("disabled", false):
			return
		selected_index = index
		_refresh_selection()

func _refresh_selection():
	for i in char_panels.size():
		var style = StyleBoxFlat.new()
		style.corner_radius_top_left = 8
		style.corner_radius_top_right = 8
		style.corner_radius_bottom_left = 8
		style.corner_radius_bottom_right = 8
		var is_disabled = CHARACTERS[i].get("disabled", false)
		if i == selected_index and not is_disabled:
			style.bg_color = Color(0.11, 0.11, 0.2)
			style.border_color = CHARACTERS[i]["accent"]
			style.border_width_left = 3
			style.border_width_right = 3
			style.border_width_top = 3
			style.border_width_bottom = 3
		else:
			style.bg_color = Color(0.08, 0.08, 0.14)
			style.border_color = Color(0.22, 0.22, 0.32)
			style.border_width_left = 2
			style.border_width_right = 2
			style.border_width_top = 2
			style.border_width_bottom = 2
		char_panels[i].add_theme_stylebox_override("panel", style)

func _on_start():
	var c = CHARACTERS[selected_index]
	GameState.character_name = c["name"]
	GameState.character_max_hp = c["hp"]
	GameState.character_max_energy = c["energy"]
	GameState.character_deck_type = c["deck_type"]
	get_tree().change_scene_to_file("res://scenes/battle.tscn")

func _on_back():
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
