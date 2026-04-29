class_name BattleUI
extends Control

@onready var player_hp_label = $PlayerPanel/HP
@onready var player_hp_bar = $PlayerPanel/HPBar
@onready var player_block_label = $PlayerPanel/Block
@onready var player_energy_label = $PlayerPanel/Energy
@onready var player_defending_label = $PlayerPanel/Verdediging
@onready var enemy_hp_label = $EnemyPanel/HP
@onready var enemy_hp_bar = $EnemyPanel/HPBar
@onready var enemy_intent_label = $EnemyPanel/Intent
@onready var hand_container = $Hand
@onready var hand_label = $HandLabel
@onready var end_turn_button = $EndTurnButton
@onready var phase_label = $PhaseLabel
@onready var battlefield_container = $BattlefieldContainer
@onready var distance_label = $DistanceLabel
@onready var target_label = $TargetLabel

var battle: Battle
var card_scene = preload("res://scenes/card.tscn")
var character_scene = preload("res://scenes/player_character.tscn")
var enemy_character_scene = preload("res://scenes/enemy_character.tscn")

var slot_panels: Array = []
var player_character: Control = null
var enemy_character: Control = null
var player_status_label: Label = null
var enemy_status_label: Label = null

const SLOT_COUNT = 6
const SLOT_WIDTH = 185.0
const SLOT_GAP = 2.0

func setup(battle_node: Battle):
	battle = battle_node
	end_turn_button.pressed.connect(_on_end_turn)
	battle.combo_landed.connect(_animate_player_attack)
	_style_panels()
	_style_button()
	_style_bars()
	_create_battlefield()
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

func _update_battlefield():
	const ENEMY_SLOT = 4
	for i in slot_panels.size():
		var is_player = (i == battle.player.position)
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
		elif i == ENEMY_SLOT:
			style.bg_color = Color(0.22, 0.08, 0.08)
			style.border_color = Color(0.9, 0.2, 0.2)
		else:
			style.bg_color = Color(0.08, 0.08, 0.12)
			style.border_color = Color(0.18, 0.18, 0.25)

		slot_panels[i].add_theme_stylebox_override("panel", style)

	var px = battle.player.position * (SLOT_WIDTH + SLOT_GAP) + (SLOT_WIDTH - 80) / 2
	var ex = ENEMY_SLOT * (SLOT_WIDTH + SLOT_GAP) + (SLOT_WIDTH - 80) / 2

	var tp = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	tp.tween_property(player_character, "position", Vector2(px, 8), 0.2)

	var te = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	te.tween_property(enemy_character, "position", Vector2(ex, 8), 0.3)

	distance_label.visible = false

	if player_status_label != null:
		player_status_label.position = Vector2(px, -32)

func _on_slot_clicked(_event: InputEvent, _slot_index: int):
	pass

func _update_defending_label(part: String):
	var names = {"hoofd": "Head", "borst": "Chest", "linkerarm": "Left Arm", "rechterarm": "Right Arm", "linkerbeen": "Left Leg", "rechterbeen": "Right Leg"}
	if part == "":
		player_defending_label.text = "Defending: —"
		player_defending_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	else:
		player_defending_label.text = "Defending: " + names.get(part, part)
		player_defending_label.add_theme_color_override("font_color", Color(0.0, 0.8, 1.0))

func update(player: Player, enemy: Enemy):
	player_hp_label.visible = false
	player_hp_bar.visible = false
	enemy_hp_label.visible = false
	enemy_hp_bar.visible = false
	player_energy_label.visible = false
	player_block_label.visible = false
	var part_labels = {"hoofd": "Head", "borst": "Chest", "linkerarm": "Left Arm", "rechterarm": "Right Arm", "linkerbeen": "Left Leg", "rechterbeen": "Right Leg"}
	enemy_intent_label.text = "Attack: %d → %s" % [enemy.intent_damage, part_labels.get(enemy.attack_target_part, enemy.attack_target_part)]
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
		if player.jaw_skip_attack > 0:    effects.append("JAW")
		if player.concussion_turns > 0:   effects.append("DIZZY")
		if player.rib_self_damage:        effects.append("RIBS")
		if player.lung_draw_penalty > 0:  effects.append("LUNG")
		if player.elbow_debuff > 0:       effects.append("ELBOW")
		if player.wrist_miss:             effects.append("WRIST")
		if player.kneecap_turns > 0:      effects.append("KNEE")
		player_status_label.text = " ".join(effects)
		var label_color = Color(1.0, 0.5, 0.1) if not effects.is_empty() else Color(0, 0, 0, 0)
		player_status_label.add_theme_color_override("font_color", label_color)

	_update_phase_ui()
	refresh_hand(player)

func refresh_hand(player: Player):
	for child in hand_container.get_children():
		child.queue_free()

	var card_count = player.hand.size()
	if card_count == 0 or battle == null:
		return

	var GROUP_GAP = 55.0
	var container_width = 780.0
	var overlap = 65.0

	var group_break_idx = -1
	for i in range(1, card_count):
		if player.hand[i].is_body_part_target and not player.hand[i - 1].is_body_part_target:
			group_break_idx = i
			break

	var total_width = overlap * (card_count - 1) + 120.0 + (GROUP_GAP if group_break_idx >= 0 else 0.0)
	var start_x = max(0.0, (container_width - total_width) / 2.0)

	for i in card_count:
		var card = player.hand[i]
		var extra_x = GROUP_GAP if (group_break_idx >= 0 and i >= group_break_idx) else 0.0
		var is_attack_selected = battle.pending_attack != null and card.card_name == battle.pending_attack.card_name
		var is_guard_selected  = battle.pending_guard  != null and card.card_name == battle.pending_guard.card_name
		var is_selected = is_attack_selected or is_guard_selected

		var card_node = card_scene.instantiate() as Card
		card_node.card_name = card.card_name
		card_node.cost = card.cost
		card_node.description = card.description
		card_node.damage = card.damage
		card_node.block = card.block
		card_node.card_type = card.card_type
		card_node.min_range = card.min_range
		card_node.max_range = card.max_range
		card_node.locks_movement = card.locks_movement
		card_node.follow_up_card_name = card.follow_up_card_name
		card_node.costs_all_energy = card.costs_all_energy
		card_node.body_part_effects = card.body_part_effects
		card_node.defends_part = card.defends_part
		card_node.combo_names = card.combo_names
		card_node.is_movement = card.is_movement
		card_node.move_direction = card.move_direction
		card_node.is_body_part_target = card.is_body_part_target
		card_node.target_part = card.target_part
		card_node.card_clicked.connect(_on_card_clicked.bind(card))
		hand_container.add_child(card_node)

		var base_pos = Vector2(start_x + i * overlap + extra_x, 0)
		var float_offset = Vector2(0, -38) if is_selected else Vector2.ZERO
		var final_pos = base_pos + float_offset
		card_node.base_position = final_pos
		card_node.position = base_pos + Vector2(0, 120)

		if is_selected:
			card_node.z_index = 200
			card_node.modulate = Color(0.2, 0.8, 1.3, 0.0) if is_guard_selected else Color(1.3, 1.1, 0.2, 0.0)
		else:
			card_node.z_index = i
			card_node.modulate.a = 0.0

		var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tween.set_parallel(true)
		tween.tween_property(card_node, "position", final_pos, 0.25).set_delay(i * 0.05)
		tween.tween_property(card_node, "modulate:a", 1.0, 0.2).set_delay(i * 0.05)

		if not is_selected:
			var playable = true
			if battle.turn_phase == 1:
				if card.is_movement:
					if card.move_direction == 0:
						playable = true
					elif battle.player.kneecap_turns > 0:
						playable = false
					else:
						var toward = sign(4 - player.position)
						var new_pos = player.position + card.move_direction * toward
						playable = (new_pos >= 0) and (new_pos < SLOT_COUNT) and (new_pos != 4)
				else:
					playable = false
			elif battle.turn_phase == 2:
				if card.is_defense():
					playable = false
				elif card.is_attack():
					var distance = abs(player.position - 4)
					playable = distance >= card.min_range and distance <= card.max_range
			elif battle.turn_phase == 3:
				playable = card.is_defense()
			card_node.set_playable(playable)

			# Limb warning indicators
			var warn_level = 0
			if not card.body_part_effects.is_empty() and battle.ATTACK_LIMB_MAP.has(card.card_name):
				var ln = battle.ATTACK_LIMB_MAP[card.card_name]
				var atk_limb = player.body_parts.get(ln)
				if atk_limb != null:
					match atk_limb.status:
						BodyPart.Status.DISABLED:                         warn_level = 2
						BodyPart.Status.BRUISED, BodyPart.Status.BROKEN:  warn_level = 1
			elif card.defends_part != "":
				var required = battle.GUARD_LIMB_REQ.get(card.defends_part, [])
				for ln in required:
					var g_limb = player.body_parts.get(ln)
					if g_limb == null:
						continue
					if g_limb.status == BodyPart.Status.DISABLED:
						warn_level = 3
						break
					elif g_limb.status == BodyPart.Status.BRUISED or g_limb.status == BodyPart.Status.BROKEN:
						warn_level = max(warn_level, 1)
			if warn_level > 0:
				card_node.set_limb_warning(warn_level)

func _on_card_clicked(card: Card):
	if battle.turn_phase == 2 and card.is_attack() and not card.body_part_effects.is_empty():
		battle.play_card(card)
	elif battle.turn_phase == 3 and card.is_defense():
		battle.select_guard(card)
	else:
		_play_card_animation(card)

func _play_card_animation(card: Card):
	var target_node: Card = null
	for child in hand_container.get_children():
		if child is Card and child.card_name == card.card_name:
			target_node = child
			break
	if target_node == null:
		battle.play_card(card)
		update(battle.player, battle.enemy)
		return

	var container_origin = hand_container.get_global_rect().position
	var center_pos = Vector2(get_viewport_rect().size.x / 2.0 - container_origin.x - 60, -210)

	var t1 = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	t1.set_parallel(true)
	t1.tween_property(target_node, "position", center_pos, 0.25)
	t1.tween_property(target_node, "scale", Vector2(1.4, 1.4), 0.25)
	await get_tree().create_timer(0.35).timeout

	# Fase 2: transformatie naar specifieke move (alleen bij combo-kaarten)
	if not card.body_part_effects.is_empty() and not card.combo_names.is_empty():
		var pulse = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		pulse.tween_property(target_node, "scale", Vector2(1.7, 1.7), 0.12)
		await get_tree().create_timer(0.1).timeout
		target_node.show_as_combo(battle.selected_body_part)
		var shrink = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		shrink.tween_property(target_node, "scale", Vector2(1.4, 1.4), 0.15)
		await get_tree().create_timer(0.6).timeout

	# Fase 3: fade out
	var t2 = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUINT)
	t2.tween_property(target_node, "modulate:a", 0.0, 0.2)
	await t2.finished

	battle.play_card(card)

func _animate_player_attack():
	if player_character == null:
		return
	var lunge_dir = sign(4 - battle.player.position)
	var original_pos = player_character.position
	var lunge_pos = original_pos + Vector2(lunge_dir * 22, -8)
	var t1 = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	t1.tween_property(player_character, "position", lunge_pos, 0.07)
	await get_tree().create_timer(0.1).timeout
	var t2 = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	t2.tween_property(player_character, "position", original_pos, 0.25)

func _update_phase_ui():
	if battle == null:
		return
	match battle.turn_phase:
		1:
			phase_label.text = "Phase 1: Move"
			phase_label.add_theme_color_override("font_color", Color(0.9, 0.75, 0.2))
			end_turn_button.visible = false
		2:
			phase_label.text = "Phase 2: Attack"
			phase_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
			end_turn_button.visible = true
			end_turn_button.text = "Skip →"
		3:
			phase_label.text = "Phase 3: Defense"
			phase_label.add_theme_color_override("font_color", Color(0.3, 0.7, 1.0))
			end_turn_button.visible = true
			end_turn_button.text = "End Turn"
	phase_label.add_theme_font_size_override("font_size", 15)

func _on_end_turn():
	if battle.turn_phase == 3:
		battle.end_turn()
	else:
		battle.advance_phase()
