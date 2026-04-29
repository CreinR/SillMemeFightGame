class_name BattleUI
extends Control

@onready var player_hp_label      = $PlayerPanel/HP
@onready var player_hp_bar        = $PlayerPanel/HPBar
@onready var player_block_label   = $PlayerPanel/Block
@onready var player_energy_label = $PlayerPanel/Energy
@onready var player_defending_label = $PlayerPanel/Verdediging
@onready var enemy_hp_label       = $EnemyPanel/HP
@onready var enemy_hp_bar         = $EnemyPanel/HPBar
@onready var enemy_intent_label   = $EnemyPanel/Intent
@onready var card_tabs_node        = $CardTabs
@onready var hand_label           = $HandLabel
@onready var end_turn_button      = $EndTurnButton
@onready var phase_label          = $PhaseLabel
@onready var battlefield_container = $BattlefieldContainer
@onready var distance_label       = $DistanceLabel
@onready var target_label         = $TargetLabel

var battle: Battle
var card_scene = preload("res://scenes/card.tscn")
var character_scene = preload("res://scenes/player_character.tscn")
var enemy_character_scene = preload("res://scenes/enemy_character.tscn")

var slot_panels: Array = []
var player_character: Control = null
var enemy_character: Control = null
var player_status_label: Label = null
var enemy_status_label: Label = null
var action_tracker_label: Label = null

const SLOT_COUNT = 6
const SLOT_WIDTH = 185.0
const SLOT_GAP   = 2.0

func setup(battle_node: Battle):
	battle = battle_node
	end_turn_button.pressed.connect(_on_end_turn)
	battle.combo_landed.connect(_animate_player_attack)
	_style_panels()
	_style_button()
	_style_bars()
	_create_battlefield()
	_create_action_tracker()
	card_tabs_node.setup(battle)
	update(battle.player, battle.enemy)

func _style_bars():
	var player_fill = StyleBoxFlat.new()
	player_fill.bg_color = Color(0.2, 0.8, 0.2)
	player_fill.corner_radius_top_left = 4
	player_fill.corner_radius_top_right = 4
	player_fill.corner_radius_bottom_left = 4
	player_fill.corner_radius_bottom_right = 4

	var enemy_fill = StyleBoxFlat.new()
	enemy_fill.bg_color = Color(0.8, 0.15, 0.15)
	enemy_fill.corner_radius_top_left = 4
	enemy_fill.corner_radius_top_right = 4
	enemy_fill.corner_radius_bottom_left = 4
	enemy_fill.corner_radius_bottom_right = 4

	var bg = StyleBoxFlat.new()
	bg.bg_color = Color(0.1, 0.05, 0.05)
	bg.corner_radius_top_left = 4
	bg.corner_radius_top_right = 4
	bg.corner_radius_bottom_left = 4
	bg.corner_radius_bottom_right = 4

	player_hp_bar.add_theme_stylebox_override("background", bg.duplicate())
	player_hp_bar.add_theme_stylebox_override("fill", player_fill)
	enemy_hp_bar.add_theme_stylebox_override("background", bg.duplicate())
	enemy_hp_bar.add_theme_stylebox_override("fill", enemy_fill)

func _style_panels():
	for panel_node in [$PlayerPanel, $EnemyPanel]:
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.1, 0.1, 0.18)
		style.border_color = Color(0.4, 0.4, 0.6)
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_width_top = 2
		style.border_width_bottom = 2
		style.corner_radius_top_left = 6
		style.corner_radius_top_right = 6
		style.corner_radius_bottom_left = 6
		style.corner_radius_bottom_right = 6
		panel_node.add_theme_stylebox_override("panel", style)

	for label in [$PlayerPanel/HP, $PlayerPanel/Block, $PlayerPanel/Energy,
				  $EnemyPanel/HP, $EnemyPanel/Intent]:
		label.add_theme_color_override("font_color", Color.WHITE)
		label.add_theme_font_size_override("font_size", 13)

func _style_button():
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.5, 0.2)
	style.border_color = Color(0.4, 0.9, 0.4)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	end_turn_button.add_theme_stylebox_override("normal", style)
	end_turn_button.add_theme_color_override("font_color", Color.WHITE)
	end_turn_button.add_theme_font_size_override("font_size", 16)

func _create_battlefield():
	for i in SLOT_COUNT:
		var panel = Panel.new()
		panel.position = Vector2(i * (SLOT_WIDTH + SLOT_GAP), 0)
		panel.size = Vector2(SLOT_WIDTH, 100)

		var num_label = Label.new()
		num_label.text = str(i + 1)
		num_label.position = Vector2(0, 82)
		num_label.size = Vector2(SLOT_WIDTH, 18)
		num_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		num_label.add_theme_font_size_override("font_size", 11)
		num_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		panel.add_child(num_label)

		panel.gui_input.connect(_on_slot_clicked.bind(i))
		battlefield_container.add_child(panel)
		slot_panels.append(panel)

	player_character = character_scene.instantiate()
	player_character.size = Vector2(80, 80)
	player_character.z_index = 2
	battlefield_container.add_child(player_character)

	enemy_character = enemy_character_scene.instantiate()
	enemy_character.size = Vector2(80, 80)
	enemy_character.z_index = 2
	battlefield_container.add_child(enemy_character)

	player_status_label = Label.new()
	player_status_label.z_index = 5
	player_status_label.add_theme_font_size_override("font_size", 11)
	player_status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	player_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	player_status_label.size = Vector2(80, 30)
	battlefield_container.add_child(player_status_label)

	enemy_status_label = Label.new()
	enemy_status_label.z_index = 5
	enemy_status_label.add_theme_font_size_override("font_size", 11)
	enemy_status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	enemy_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	enemy_status_label.size = Vector2(80, 30)
	battlefield_container.add_child(enemy_status_label)

	_update_battlefield()

func _create_action_tracker():
	action_tracker_label = Label.new()
	action_tracker_label.add_theme_font_size_override("font_size", 14)
	action_tracker_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	action_tracker_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	action_tracker_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# Position above the hand container — phase_label node is repurposed as anchor
	phase_label.visible = false
	add_child(action_tracker_label)
	# Will be positioned in update()

func _update_battlefield():
	for i in slot_panels.size():
		var is_player = (i == battle.player.position)
		var is_enemy  = (i == battle.enemy.position)
		var style = StyleBoxFlat.new()
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_width_top = 2
		style.border_width_bottom = 2
		style.corner_radius_top_left = 4
		style.corner_radius_top_right = 4
		style.corner_radius_bottom_left = 4
		style.corner_radius_bottom_right = 4

		if is_player:
			style.bg_color = Color(0.1, 0.22, 0.1)
			style.border_color = Color(0.3, 0.9, 0.3)
		elif is_enemy:
			style.bg_color = Color(0.22, 0.08, 0.08)
			style.border_color = Color(0.9, 0.2, 0.2)
		else:
			style.bg_color = Color(0.08, 0.08, 0.12)
			style.border_color = Color(0.18, 0.18, 0.25)

		slot_panels[i].add_theme_stylebox_override("panel", style)

	var px = battle.player.position * (SLOT_WIDTH + SLOT_GAP) + (SLOT_WIDTH - 80) / 2
	var ex = battle.enemy.position * (SLOT_WIDTH + SLOT_GAP) + (SLOT_WIDTH - 80) / 2

	var tp = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	tp.tween_property(player_character, "position", Vector2(px, 8), 0.2)

	var te = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	te.tween_property(enemy_character, "position", Vector2(ex, 8), 0.3)

	distance_label.visible = false

	if player_status_label != null:
		player_status_label.position = Vector2(px, -32)

func _on_slot_clicked(_event: InputEvent, _slot_index: int):
	pass

func update(player: Player, enemy: Enemy):
	player_hp_label.visible = false
	player_hp_bar.visible = false
	enemy_hp_label.visible = false
	enemy_hp_bar.visible = false
	player_energy_label.visible = false
	player_block_label.visible = false

	var part_labels = {
		"hoofd": "Head", "borst": "Chest",
		"linkerarm": "Left Arm", "rechterarm": "Right Arm",
		"bovenbenen": "Upper Legs", "voeten": "Feet",
	}
	enemy_intent_label.text = "Attack: %d → %s" % [
		enemy.intent_damage,
		part_labels.get(enemy.attack_target_part, enemy.attack_target_part)
	]
	enemy_intent_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35))

	if enemy_character != null:
		enemy_character.queue_redraw()
	hand_label.visible = false
	player_defending_label.visible = false

	if player_character != null:
		player_character.selected_part = player.defending_part
		player_character.update_body_parts(player.body_parts)
		player_character.queue_redraw()

	if not slot_panels.is_empty():
		_update_battlefield()

	if player_status_label != null:
		var effects: Array = []
		if player.jaw_skip_attack > 0:   effects.append("JAW")
		if player.concussion_turns > 0:  effects.append("DIZZY")
		if player.rib_self_damage:       effects.append("RIBS")
		if player.lung_draw_penalty > 0: effects.append("LUNG")
		if player.elbow_debuff > 0:      effects.append("ELBOW")
		if player.wrist_miss:            effects.append("WRIST")
		if player.kneecap_turns > 0:     effects.append("KNEE")
		if player.stagger_turns > 0:     effects.append("STAGGER")
		player_status_label.text = " ".join(effects)
		var label_color = Color(1.0, 0.5, 0.1) if not effects.is_empty() else Color(0, 0, 0, 0)
		player_status_label.add_theme_color_override("font_color", label_color)

	card_tabs_node.refresh_tab_state()
	_update_action_tracker()
	refresh_hand(player)

	# End Turn button always visible
	end_turn_button.visible = true
	end_turn_button.text = "End Turn"

func _update_action_tracker():
	if action_tracker_label == null or battle == null:
		return

	var move_text  = "Move: —"
	var atk_text   = "Attack: —"
	var guard_text = "Guard: —"

	if battle.move_done:
		var mc = battle.player_move_card
		if mc != null:
			move_text = "Move: %s ✓" % mc.card_name
		else:
			move_text = "Move: Skip ✓"

	if battle.attack_done:
		var ac = battle.player_attack_card
		if ac != null:
			var part_labels = {"hoofd": "Head", "borst": "Chest", "bovenbenen": "Legs", "voeten": "Feet"}
			var tgt = part_labels.get(battle.player_attack_target, battle.player_attack_target)
			atk_text = "Attack: %s→%s ✓" % [ac.card_name, tgt]
		else:
			atk_text = "Attack: Skip ✓"
	elif battle.pending_attack != null:
		atk_text = "Attack: %s (pick target)" % battle.pending_attack.card_name

	if battle.guard_done:
		var gc = battle.player_guard_card
		if gc != null:
			guard_text = "Guard: %s ✓" % gc.card_name
		else:
			guard_text = "Guard: Skip ✓"

	action_tracker_label.text = "[ %s ]  [ %s ]  [ %s ]" % [move_text, atk_text, guard_text]
	# Position above tab bar
	var tabs_pos = card_tabs_node.position
	action_tracker_label.position = Vector2(tabs_pos.x, tabs_pos.y - 28)
	action_tracker_label.size = Vector2(card_tabs_node.size.x, 24)

func refresh_hand(player: Player):
	var card_area = card_tabs_node.card_area
	for child in card_area.get_children():
		child.queue_free()

	if player.hand.size() == 0 or battle == null:
		return

	# Show only cards belonging to the active tab
	var active_tab = card_tabs_node.active_tab
	var tab_cards: Array = []
	for c in player.hand:
		if _card_section(c) == active_tab:
			tab_cards.append(c)

	var section_done = (active_tab == "move"   and battle.move_done)   or \
					   (active_tab == "attack" and battle.attack_done) or \
					   (active_tab == "guard"  and battle.guard_done)

	var overlap    = 65.0
	var card_width = 120.0
	var area_width = card_area.size.x if card_area.size.x > 0 else 680.0
	var total_width = overlap * max(tab_cards.size() - 1, 0) + card_width
	var start_x     = max(0.0, (area_width - total_width) / 2.0)

	var running_x = start_x
	for i in tab_cards.size():
		var card = tab_cards[i]
		var is_attack_selected = battle.pending_attack != null and card.card_name == battle.pending_attack.card_name

		var card_node = card_scene.instantiate() as Card
		_copy_card_data(card, card_node)
		card_node.card_clicked.connect(_on_card_clicked.bind(card))
		card_area.add_child(card_node)

		var float_offset = Vector2(0, -38) if is_attack_selected else Vector2.ZERO
		var final_pos = Vector2(running_x, 0) + float_offset
		card_node.base_position = final_pos
		card_node.position = Vector2(running_x, 120)
		card_node.modulate.a = 0.0

		if is_attack_selected:
			card_node.z_index = 200
			card_node.modulate = Color(1.3, 1.1, 0.2, 0.0)
		else:
			card_node.z_index = i

		var delay = i * 0.025
		var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tween.set_parallel(true)
		tween.tween_property(card_node, "position", final_pos, 0.15).set_delay(delay)
		tween.tween_property(card_node, "modulate:a", 1.0, 0.12).set_delay(delay)

		running_x += overlap

		# Section done → show but unclickable
		var playable = (not section_done) and _is_card_playable(card, player)
		card_node.set_playable(playable)

		# Checkmark on the confirmed card
		if (active_tab == "move"   and battle.player_move_card   != null and card.card_name == battle.player_move_card.card_name) or \
		   (active_tab == "guard"  and battle.player_guard_card  != null and card.card_name == battle.player_guard_card.card_name) or \
		   (active_tab == "attack" and battle.player_attack_card != null and card.card_name == battle.player_attack_card.card_name):
			card_node.show_checkmark()

		# Limb warning indicators
		var warn_level = 0
		if not card.body_part_effects.is_empty() and battle.ATTACK_LIMB_MAP.has(card.card_name):
			var ln = battle.ATTACK_LIMB_MAP[card.card_name]
			var atk_limb = player.body_parts.get(ln)
			if atk_limb != null:
				match atk_limb.status:
					BodyPart.Status.DISABLED:                        warn_level = 2
					BodyPart.Status.BRUISED, BodyPart.Status.BROKEN: warn_level = 1
		elif card.defends_part != "":
			var required = battle.GUARD_LIMB_REQ.get(card.defends_part, [])
			for ln in required:
				var g_limb = player.body_parts.get(ln)
				if g_limb == null:
					continue
				if g_limb.status == BodyPart.Status.DISABLED:
					warn_level = 3
					break
				elif g_limb.status in [BodyPart.Status.BRUISED, BodyPart.Status.BROKEN]:
					warn_level = max(warn_level, 1)
		if warn_level > 0:
			card_node.set_limb_warning(warn_level)

func _card_section(card: Card) -> String:
	if card.is_movement or card.card_type == "move_disabled":
		return "move"
	elif card.is_defense():
		return "guard"
	return "attack"

func _is_card_playable(card: Card, player: Player) -> bool:
	var section = _card_section(card)
	# If section already done, not playable
	if section == "move"   and battle.move_done:   return false
	if section == "attack" and battle.attack_done: return false
	if section == "guard"  and battle.guard_done:  return false

	if section == "move":
		if card.card_type == "move_disabled":
			return false
		if card.move_direction == 0:
			return true
		if player.kneecap_turns > 0:
			return false
		var toward = sign(battle.enemy.position - player.position)
		var new_pos = player.position + card.move_direction * toward
		return new_pos >= 0 and new_pos < SLOT_COUNT and new_pos != battle.enemy.position

	if section == "attack":
		var distance = abs(player.position - battle.enemy.position)
		return distance >= card.min_range and distance <= card.max_range

	# guard cards always playable if section not done
	return true

func _copy_card_data(src: Card, dst: Card):
	dst.card_name           = src.card_name
	dst.cost                = src.cost
	dst.description         = src.description
	dst.damage              = src.damage
	dst.block               = src.block
	dst.card_type           = src.card_type
	dst.min_range           = src.min_range
	dst.max_range           = src.max_range
	dst.locks_movement      = src.locks_movement
	dst.follow_up_card_name = src.follow_up_card_name
	dst.costs_all_energy    = src.costs_all_energy
	dst.body_part_effects   = src.body_part_effects
	dst.defends_part        = src.defends_part
	dst.combo_names         = src.combo_names
	dst.is_movement         = src.is_movement
	dst.move_direction      = src.move_direction
	dst.is_body_part_target = src.is_body_part_target
	dst.target_part         = src.target_part

func _on_card_clicked(card: Card):
	if card.card_type == "move_disabled":
		return
	if card.is_movement:
		battle.choose_movement(card)
	elif card.is_attack() and not card.body_part_effects.is_empty():
		battle.choose_attack(card)
	elif card.is_defense():
		battle.choose_guard(card)

func _animate_player_attack():
	if player_character == null:
		return
	var lunge_dir = sign(battle.enemy.position - battle.player.position)
	var original_pos = player_character.position
	var lunge_pos = original_pos + Vector2(lunge_dir * 22, -8)
	var t1 = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	t1.tween_property(player_character, "position", lunge_pos, 0.07)
	await get_tree().create_timer(0.1).timeout
	var t2 = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	t2.tween_property(player_character, "position", original_pos, 0.25)

func _on_end_turn():
	# Skip any unfinished actions and resolve
	if not battle.move_done:
		battle.move_done = true
	if not battle.attack_done:
		battle.pending_attack = null
		battle.body_highlight.set_valid_parts([])
		battle.attack_done = true
	if not battle.guard_done:
		battle.guard_done = true
	battle.resolve_turn()
