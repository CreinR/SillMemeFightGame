class_name CardTabs
extends Control

var battle = null
var active_tab: String = "move"
var card_area: Control

var _tab_buttons: Dictionary = {}
var _prev_move_done:   bool = false
var _prev_attack_done: bool = false
var _prev_guard_done:  bool = false

const TAB_COLORS = {
	"move":   Color(0.18, 0.32, 0.75),
	"attack": Color(0.72, 0.14, 0.14),
	"guard":  Color(0.14, 0.52, 0.18),
}
const TAB_ORDER  = ["move", "attack", "guard"]
const TAB_LABELS = {"move": "Movement", "attack": "Attack", "guard": "Guard"}

func setup(battle_ref) -> void:
	battle = battle_ref
	_build_ui()

func _build_ui() -> void:
	var tab_bar = HBoxContainer.new()
	tab_bar.position = Vector2(0, 0)
	tab_bar.size = Vector2(size.x, 34)
	tab_bar.add_theme_constant_override("separation", 6)
	add_child(tab_bar)

	for tab_name in TAB_ORDER:
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(112, 30)
		btn.pressed.connect(_on_tab_clicked.bind(tab_name))
		tab_bar.add_child(btn)
		_tab_buttons[tab_name] = btn

	card_area = Control.new()
	card_area.position = Vector2(0, 38)
	card_area.size = Vector2(size.x, size.y - 38)
	add_child(card_area)

	_update_tab_visuals()

func _on_tab_clicked(tab_name: String) -> void:
	if tab_name != active_tab:
		active_tab = tab_name
		_update_tab_visuals()

func refresh_tab_state() -> void:
	if battle == null:
		return

	var move_just_done   = battle.move_done   and not _prev_move_done
	var attack_just_done = battle.attack_done and not _prev_attack_done

	if move_just_done and not battle.attack_done:
		active_tab = "attack"
	elif attack_just_done and not battle.guard_done:
		active_tab = "guard"

	# Reset to move at the start of a fresh turn
	if not battle.move_done and not battle.attack_done and not battle.guard_done:
		active_tab = "move"

	_prev_move_done   = battle.move_done
	_prev_attack_done = battle.attack_done
	_prev_guard_done  = battle.guard_done

	_update_tab_visuals()

func _is_done(tab_name: String) -> bool:
	if battle == null:
		return false
	match tab_name:
		"move":   return battle.move_done
		"attack": return battle.attack_done
		"guard":  return battle.guard_done
	return false

func _update_tab_visuals() -> void:
	for tab_name in TAB_ORDER:
		var btn: Button = _tab_buttons.get(tab_name)
		if btn == null:
			continue
		var is_active = (tab_name == active_tab)
		var is_done   = _is_done(tab_name)

		btn.text = (TAB_LABELS[tab_name] + " ✓") if is_done else TAB_LABELS[tab_name]

		var style_n = StyleBoxFlat.new()
		var style_h = StyleBoxFlat.new()
		var base    = TAB_COLORS[tab_name]

		if is_done:
			style_n.bg_color     = Color(0.22, 0.22, 0.25, 0.9)
			style_n.border_color = Color(0.42, 0.42, 0.48)
			style_h.bg_color     = Color(0.28, 0.28, 0.32, 0.9)
			style_h.border_color = Color(0.5,  0.5,  0.55)
		elif is_active:
			style_n.bg_color     = base.lightened(0.06)
			style_n.border_color = base.lightened(0.5)
			style_h.bg_color     = base.lightened(0.18)
			style_h.border_color = base.lightened(0.6)
		else:
			style_n.bg_color     = base.darkened(0.55)
			style_n.border_color = base.darkened(0.2)
			style_h.bg_color     = base.darkened(0.4)
			style_h.border_color = base.darkened(0.05)

		for s in [style_n, style_h]:
			s.border_width_top    = 3 if is_active else 1
			s.border_width_bottom = 0 if is_active else 2
			s.border_width_left   = 2
			s.border_width_right  = 2
			s.corner_radius_top_left  = 5
			s.corner_radius_top_right = 5

		btn.add_theme_stylebox_override("normal", style_n)
		btn.add_theme_stylebox_override("hover",  style_h)
		btn.add_theme_color_override("font_color", Color.WHITE)
		btn.add_theme_font_size_override("font_size", 13)
		btn.modulate.a = 1.0 if (is_active or is_done) else 0.55
