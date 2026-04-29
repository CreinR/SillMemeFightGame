class_name Battle
extends Node

signal combo_landed
signal enemy_attacked

@onready var player = $Player
@onready var enemy = $Enemy
@onready var ui = $CanvasLayer/BattleUI
@onready var combat_log = $CanvasLayer/BattleUI/CombatLog
@onready var body_highlight = $CanvasLayer/BattleUI/BodyHighlight
@onready var body_selector = $CanvasLayer/BattleUI/BodyPartSelector
@onready var player_body_highlight = $CanvasLayer/BattleUI/PlayerBodyHighlight

var selected_body_part: String = "borst"

# --- Simultaneous turn state ---
var player_move_card: Card = null
var player_attack_card: Card = null
var player_attack_target: String = ""
var player_guard_card: Card = null
var pending_attack: Card = null   # attack selected but target not yet chosen

# Derived flags for UI
var move_done: bool = false
var attack_done: bool = false
var guard_done: bool = false

# --- Limb / guard tables ---
const ATTACK_LIMB_MAP: Dictionary = {
	"Jab":                "linkerarm",
	"Hook":               "rechterarm",
	"Uppercut":           "rechterarm",
	"Overhand":           "rechterarm",
	"Backfist":           "linkerarm",
	"Roundhouse Kick":    "voeten",
	"Front Kick":         "bovenbenen",
	"Spinning Heel Kick": "voeten",
}

const GUARD_LIMB_REQ: Dictionary = {
	"hoofd":      ["linkerarm", "rechterarm"],
	"borst":      ["linkerarm"],
	"bovenbenen": ["bovenbenen"],
	"voeten":     ["voeten"],
}

func _ready():
	var tooltip = BodyTooltip.new()
	$CanvasLayer/BattleUI.add_child(tooltip)
	tooltip.move_to_front()

	player.apply_stats(CharacterStats.kickboxer())
	enemy.apply_stats(CharacterStats.enemy_default())

	setup_starter_deck()
	ui.setup(self)
	body_highlight.setup(enemy, tooltip, enemy.stats)
	body_selector.setup(body_highlight)
	body_selector.part_selected.connect(_on_part_selected)
	player_body_highlight.setup(player, tooltip, player.stats)
	player_body_highlight.part_selected.connect(_on_player_part_selected)
	start_player_turn()

func _on_part_selected(part_name: String):
	selected_body_part = part_name
	if pending_attack != null:
		_confirm_attack_target(part_name)

func _on_player_part_selected(_part_name: String):
	pass  # No longer used for guard selection in the new system

# ---------------------------------------------------------------------------
# Deck / card factories
# ---------------------------------------------------------------------------
func setup_starter_deck():
	pass

func _make_move_card(cname: String, direction: int) -> Card:
	var c = Card.new()
	c.card_name = cname
	c.is_movement = true
	c.move_direction = direction
	c.card_type = "move"
	if direction == 0:
		c.cost = 0
		c.description = "Stay in place.\nNo cost."
	elif direction == 1:
		c.cost = 0
		c.description = "Move one position\nforward."
	else:
		c.cost = 0
		c.description = "Move one position\nbackward."
	return c

func _make_defense(cname: String, part: String) -> Card:
	var c = Card.new()
	c.card_name = cname
	c.cost = 0
	c.card_type = "block"
	c.defends_part = part
	var part_names = {"hoofd": "Head", "borst": "Chest", "bovenbenen": "Upper Legs", "voeten": "Feet"}
	c.description = "Guard your %s.\nIf the enemy attacks\nthis part: 0 damage." % part_names.get(part, part)
	return c

func _make_jab() -> Card:
	var c = Card.new()
	c.card_name = "Jab"
	c.cost = 0
	c.card_type = "attack"
	c.min_range = 2
	c.max_range = 3
	c.description = "Quick left punch.\nHead: 6  Chest: 5"
	c.body_part_effects = {
		"hoofd": {"damage": 6},
		"borst": {"damage": 5},
	}
	c.combo_names = {
		"hoofd": "Head Jab",
		"borst": "Body Jab",
	}
	return c

func _make_hook() -> Card:
	var c = Card.new()
	c.card_name = "Hook"
	c.cost = 0
	c.card_type = "attack"
	c.min_range = 1
	c.max_range = 1
	c.description = "Right hook (adjacent).\nHead: 12 + stun\nChest: 10"
	c.body_part_effects = {
		"hoofd": {"damage": 12, "effect": "stun"},
		"borst": {"damage": 10},
	}
	c.combo_names = {
		"hoofd": "Left Hook",
		"borst": "Body Hook",
	}
	return c

func _make_uppercut() -> Card:
	var c = Card.new()
	c.card_name = "Uppercut"
	c.cost = 0
	c.card_type = "attack"
	c.min_range = 1
	c.max_range = 1
	c.description = "Rising right punch.\nHead: 14 + stun\nChest: 8"
	c.body_part_effects = {
		"hoofd": {"damage": 14, "effect": "stun"},
		"borst": {"damage": 8},
	}
	c.combo_names = {
		"hoofd": "KO Uppercut",
		"borst": "Body Uppercut",
	}
	return c

func _make_overhand() -> Card:
	var c = Card.new()
	c.card_name = "Overhand"
	c.cost = 0
	c.card_type = "attack"
	c.min_range = 1
	c.max_range = 2
	c.description = "Right overhand.\nHead: 10\n50% bypasses guard!"
	c.body_part_effects = {
		"hoofd": {"damage": 10, "effect": "overhand_bypass"},
	}
	c.combo_names = {
		"hoofd": "Overhand Right",
	}
	return c

func _make_backfist() -> Card:
	var c = Card.new()
	c.card_name = "Backfist"
	c.cost = 0
	c.card_type = "attack"
	c.min_range = 2
	c.max_range = 3
	c.description = "Left backfist.\nHead: 8\n+15% brain hit chance"
	c.body_part_effects = {
		"hoofd": {"damage": 8, "effect": "backfist_brain"},
	}
	c.combo_names = {
		"hoofd": "Spinning Backfist",
	}
	return c

func _make_roundhouse_kick() -> Card:
	var c = Card.new()
	c.card_name = "Roundhouse Kick"
	c.cost = 0
	c.card_type = "attack"
	c.min_range = 2
	c.max_range = 3
	c.description = "Right roundhouse.\nHead: 10+stun  Chest: 8\nLegs: 6+weak  Feet: 4+stun"
	c.body_part_effects = {
		"hoofd":      {"damage": 10, "effect": "stun"},
		"borst":      {"damage": 8},
		"bovenbenen": {"damage": 6, "effect": "weaken", "value": 3},
		"voeten":     {"damage": 4, "effect": "stun"},
	}
	c.combo_names = {
		"hoofd":      "Head Kick",
		"borst":      "Body Kick",
		"bovenbenen": "Low Kick",
		"voeten":     "Sweep Kick",
	}
	return c

func _make_front_kick() -> Card:
	var c = Card.new()
	c.card_name = "Front Kick"
	c.cost = 0
	c.card_type = "attack"
	c.min_range = 2
	c.max_range = 3
	c.description = "Left front kick.\nChest: 7  Legs: 6\nPushes enemy back!"
	c.body_part_effects = {
		"borst":      {"damage": 7, "effect": "front_kick_push"},
		"bovenbenen": {"damage": 6, "effect": "front_kick_push"},
	}
	c.combo_names = {
		"borst":      "Body Push Kick",
		"bovenbenen": "Leg Push Kick",
	}
	return c

func _make_spinning_heel_kick() -> Card:
	var c = Card.new()
	c.card_name = "Spinning Heel Kick"
	c.cost = 0
	c.card_type = "attack"
	c.min_range = 3
	c.max_range = 4
	c.description = "Right spinning heel.\nHead: 16 + stun\nMiss = stumble next turn!"
	c.body_part_effects = {
		"hoofd": {"damage": 16, "effect": "stun"},
	}
	c.combo_names = {
		"hoofd": "Spinning Heel Kick",
	}
	return c

# ---------------------------------------------------------------------------
# Turn start
# ---------------------------------------------------------------------------
func start_player_turn():
	move_done    = false
	attack_done  = false
	guard_done   = false
	player_move_card    = null
	player_attack_card  = null
	player_attack_target = ""
	player_guard_card   = null
	pending_attack      = null

	player.start_turn()
	body_highlight.set_valid_parts([])
	player_body_highlight.set_valid_parts([])

	# Enemy plans all 3 actions secretly
	enemy.plan_turn(player.position)

	_set_full_hand()
	_warn_fatal_organ_status()
	update_ui()

func _set_full_hand():
	player.hand.clear()

	# --- Movement section ---
	if player.stagger_turns > 0:
		# Staggered: show greyed placeholder so tracker still shows Move slot
		var stub = _make_move_card("Stance", 0)
		stub.card_type = "move_disabled"
		player.hand.append(stub)
	else:
		player.hand.append(_make_move_card("Back",    -1))
		player.hand.append(_make_move_card("Stance",   0))
		player.hand.append(_make_move_card("Forward",  1))

	# --- Attack section ---
	if player.jaw_skip_attack > 0:
		player.jaw_skip_attack -= 1
		combat_log.log_status("Your jaw hurts too much to attack. Skipping attack.")
		attack_done = true
	else:
		var attacks = [
			_make_jab(), _make_hook(), _make_uppercut(), _make_overhand(),
			_make_backfist(), _make_roundhouse_kick(), _make_front_kick(),
			_make_spinning_heel_kick(),
		]
		if player.concussion_turns > 0:
			player.concussion_turns -= 1
			var forced = attacks[randi() % attacks.size()]
			pending_attack = forced
			body_highlight.set_valid_parts(forced.body_part_effects.keys())
			combat_log.log_status("Seeing stars! A random attack is forced.")
		for atk in attacks:
			player.hand.append(atk)

	# --- Guard section ---
	player.hand.append(_make_defense("Guard Head",       "hoofd"))
	player.hand.append(_make_defense("Guard Chest",      "borst"))
	player.hand.append(_make_defense("Guard Upper Legs", "bovenbenen"))
	player.hand.append(_make_defense("Guard Feet",       "voeten"))

# ---------------------------------------------------------------------------
# Player action choices (called by UI when cards are clicked)
# ---------------------------------------------------------------------------
func choose_movement(card: Card):
	if move_done:
		return
	player_move_card = card
	move_done = true
	update_ui()
	_check_turn_complete()

func choose_attack(card: Card):
	if attack_done:
		return
	if pending_attack != null:
		# Swap selection — refund no cost since cost=0
		pass
	pending_attack = card
	body_highlight.set_valid_parts(card.body_part_effects.keys())
	update_ui()

func _confirm_attack_target(part: String):
	if pending_attack == null:
		return
	body_highlight.set_valid_parts([])
	player_attack_card   = pending_attack
	player_attack_target = part
	pending_attack       = null
	attack_done          = true
	update_ui()
	_check_turn_complete()

func choose_guard(card: Card):
	if guard_done:
		return
	player_guard_card = card
	guard_done = true

	# Validate guard limbs immediately so player sees warnings
	var required_limbs = GUARD_LIMB_REQ.get(card.defends_part, [])
	for ln in required_limbs:
		var limb = player.body_parts.get(ln)
		if limb == null:
			continue
		if limb.status == BodyPart.Status.DISABLED:
			var display = player.LIMB_DISPLAY.get(ln, ln)
			combat_log.log_attack("Your %s is destroyed — %s may fail!" % [display, card.card_name])
		elif limb.status in [BodyPart.Status.BRUISED, BodyPart.Status.BROKEN]:
			var display = player.LIMB_DISPLAY.get(ln, ln)
			combat_log.log_status("Blocking with damaged %s — chip damage doubled." % display)

	update_ui()
	_check_turn_complete()

func _check_turn_complete():
	if move_done and attack_done and guard_done:
		resolve_turn()

# ---------------------------------------------------------------------------
# Simultaneous resolution
# ---------------------------------------------------------------------------
func resolve_turn():
	pending_attack = null
	body_highlight.set_valid_parts([])

	combat_log.log_info("--- Turn resolving ---")

	# Apply guard so player.defending_part is set for take_damage checks
	_apply_player_guard()

	# ===== STEP 1: Both movements resolve =====
	var player_moved = false
	var enemy_moved  = false

	if player_move_card != null and player_move_card.move_direction != 0 and player.stagger_turns == 0:
		var toward = sign(enemy.position - player.position)
		var new_pos = player.position + player_move_card.move_direction * toward
		if new_pos >= 0 and new_pos < 6 and new_pos != enemy.position:
			player.position = new_pos
			player_moved = true

	if enemy.planned_movement != 0 and enemy.stagger_turns == 0:
		var toward_player = sign(player.position - enemy.position)
		var new_enemy = enemy.position + enemy.planned_movement * toward_player
		if new_enemy >= 0 and new_enemy < 6 and new_enemy != player.position:
			enemy.position = new_enemy
			enemy_moved = true

	if player_moved or enemy_moved:
		combat_log.log_info("Both fighters move.")

	# ===== STEP 2: Range check after movement =====
	var distance = abs(player.position - enemy.position)

	# ===== STEP 3: Both attack actions resolve =====

	# -- Player attack --
	var player_attack_messages: Array = []
	var player_hit_enemy = false

	if player_attack_card != null:
		var atk_min = player_attack_card.min_range
		var atk_max = player_attack_card.max_range
		if distance < atk_min or distance > atk_max:
			combat_log.log_info("Moved out of range — attack missed!")
			if player_attack_card.card_name == "Spinning Heel Kick":
				player.stagger_turns = 1
				combat_log.log_attack("Missed the spinning heel kick — you stumble!")
		elif player_attack_card.card_name == "Spinning Heel Kick" and _shk_speed_miss():
			player.stagger_turns = 1
			combat_log.log_attack("The spinning heel kick whiffs — you stumble!")
		else:
			player_attack_messages = _build_player_attack()
			player_hit_enemy = true

	# -- Enemy attack --
	var enemy_attack_messages: Array = []
	var enemy_will_attack = false
	var enemy_actual_damage = 0
	var enemy_attack_data: Dictionary = {}

	if enemy.stun:
		enemy.stun = false
		combat_log.log_enemy("Enemy is stunned and skips their attack!")
		enemy.plan_turn(player.position)  # pick next target
	elif enemy.jaw_skip_turns > 0:
		enemy.jaw_skip_turns -= 1
		combat_log.log_enemy("Enemy's jaw is broken — they can't attack!")
		enemy.plan_turn(player.position)
	else:
		enemy_attack_data = enemy.get_planned_attack_data()
		var e_min = enemy.intent_attack_min_range
		var e_max = enemy.intent_attack_max_range
		if distance < e_min or distance > e_max:
			combat_log.log_enemy("Enemy moved out of range — attack missed!")
		else:
			enemy_will_attack = true
			enemy_actual_damage = enemy.intent_damage
			if enemy.wrist_miss:
				enemy.wrist_miss = false
				if randf() < 0.5:
					combat_log.log_enemy("Enemy's wrist gives out — attack missed!")
					enemy_will_attack = false
			if enemy_will_attack and enemy.elbow_debuff > 0:
				enemy_actual_damage = max(0, enemy_actual_damage - enemy.elbow_debuff)
				enemy.elbow_debuff = 0
			if enemy_will_attack and enemy.lung_debuff_turns > 0:
				enemy_actual_damage = max(0, enemy_actual_damage - enemy.lung_debuff_value)
				enemy.lung_debuff_turns -= 1

	# ===== STEP 4: Defense resolves =====

	# -- Apply player attack to enemy (with enemy guard check) --
	if player_hit_enemy and player_attack_card != null:
		var part = player_attack_target
		var fx   = player_attack_card.body_part_effects.get(part, {})
		var dmg  = _apply_player_limb_penalty(player_attack_card, fx.get("damage", 0), part)
		if player.elbow_debuff > 0:
			dmg = max(0, dmg - player.elbow_debuff)
			player.elbow_debuff = 0

		# Backfist brain boost
		var brain_boost_applied = false
		if player_attack_card.card_name == "Backfist" and part == "hoofd":
			var hoofd_bp = enemy.body_parts.get("hoofd")
			if hoofd_bp != null:
				for sub in hoofd_bp.sub_parts:
					if sub["effect"] == "brain":
						sub["base_chance"] += 0.15
						brain_boost_applied = true

		# Overhand bypass roll
		var bypass_guard = false
		var effect_str = fx.get("effect", "")
		if effect_str == "overhand_bypass":
			if randf() < 0.5:
				bypass_guard = true
				combat_log.log_attack("Overhand crashes through the guard!")

		# Enemy guard check
		var enemy_guarded = (not bypass_guard) and (enemy.planned_guard == part)
		if enemy_guarded and dmg > 0:
			var chip = ceili(dmg * 0.2)
			var guard_limb = enemy.GUARD_LIMB_MAP.get(part, "")
			if guard_limb != "" and enemy.body_parts.has(guard_limb):
				var gl = enemy.body_parts[guard_limb]
				if gl.status != BodyPart.Status.DISABLED:
					var sm = gl.take_damage(chip)
					combat_log.log_info("Enemy blocked! Chip damage %d to their %s." % [chip, guard_limb])
					if sm != "":
						combat_log.log_status(sm)
			dmg = 0  # full block

		if dmg > 0:
			var msgs = enemy.take_damage(dmg, part)
			_log_messages(msgs)
			body_highlight.highlight(part)
			combo_landed.emit()
			if _has_fatal_enemy(msgs):
				get_tree().change_scene_to_file("res://scenes/win.tscn")
				return
		elif dmg == 0 and not enemy_guarded:
			pass  # Already logged by limb penalty or miss

		# Restore backfist brain boost
		if brain_boost_applied:
			var hoofd_bp = enemy.body_parts.get("hoofd")
			if hoofd_bp != null:
				for sub in hoofd_bp.sub_parts:
					if sub["effect"] == "brain":
						sub["base_chance"] -= 0.15

		# Attack special effects (only on unblocked hit)
		if dmg > 0 or bypass_guard:
			var effect = fx.get("effect", "")
			var value  = fx.get("value", 0)
			match effect:
				"stun":
					enemy.stun = true
					combat_log.log_status("Enemy stunned! Skips next attack.")
				"weaken":
					enemy.intent_damage = max(0, enemy.intent_damage - value)
					combat_log.log_status("Enemy weakened! -%d damage." % value)
				"front_kick_push":
					# Push enemy 1 slot away from player
					var push_dir = sign(enemy.position - player.position)
					var pushed_to = enemy.position + push_dir
					if pushed_to >= 0 and pushed_to < 6:
						enemy.position = pushed_to
						combat_log.log_info("Enemy stumbles back!")
				"backfist_brain":
					combat_log.log_status("The backfist rattles the skull directly!")

		# Spinning Heel Kick miss: triggered when it didn't connect at all
		if player_attack_card.card_name == "Spinning Heel Kick" and dmg == 0:
			player.stagger_turns = 1
			combat_log.log_attack("Missed the spinning heel kick — you stumble!")

		# Rib self-damage
		if player.rib_self_damage:
			player.body_parts["borst"].take_damage(1)
			combat_log.log_status("Crack! Your ribs flare up.")

	# -- Apply enemy attack to player (with player guard check) --
	if enemy_will_attack:
		var targeted = enemy.attack_target_part
		combat_log.log_enemy("Enemy attacks %s for %d!" % [targeted, enemy_actual_damage])

		var msgs = player.take_damage(enemy_actual_damage, targeted)
		var did_block = msgs.any(func(m): return m is Dictionary and m.get("type", "") == "chip")
		if did_block:
			var limb_name = player.GUARD_LIMB_MAP.get(targeted, "")
			if limb_name != "":
				player_body_highlight.highlight(limb_name)
		else:
			player_body_highlight.highlight(targeted)
		for msg in msgs:
			if msg is Dictionary:
				match msg.get("type", ""):
					"chip":         combat_log.log_info(msg["text"])
					"fatal_player": combat_log.log_attack(msg["text"])
					"sub":          combat_log.log_status(msg["text"])
					_:              combat_log.log_status(msg["text"])
			elif "gekneusd" in msg or "gebroken" in msg or "uitgeschakeld" in msg:
				combat_log.log_status(msg)
			else:
				combat_log.log_info(msg)
		if _has_fatal_player(msgs):
			get_tree().change_scene_to_file("res://scenes/game_over.tscn")
			return

		# Enemy Front Kick push — push player away
		if enemy.intent_attack_name == "Front Kick":
			var push_dir = sign(player.position - enemy.position)
			var pushed_to = player.position + push_dir
			if pushed_to >= 0 and pushed_to < 6 and pushed_to != enemy.position:
				player.position = pushed_to
				combat_log.log_info("You stumble back!")

		# Enemy rib reflect
		if enemy.rib_reflect:
			enemy.rib_reflect = false
			enemy.body_parts["borst"].take_damage(1)
			combat_log.log_enemy("Krak! Enemy's ribs flare up on attack.")

		if enemy.concussion_turns > 0:
			enemy.concussion_turns -= 1

	# ===== Next turn =====
	enemy.plan_turn(player.position)  # pick next intent for display
	start_player_turn()

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
func _build_player_attack() -> Array:
	return []  # messages collected inline in resolve_turn

func _apply_player_limb_penalty(card: Card, dmg: int, part: String) -> int:
	if dmg <= 0:
		return 0
	var limb_name = ATTACK_LIMB_MAP.get(card.card_name, "")
	if limb_name == "":
		return dmg

	var limb = player.body_parts.get(limb_name)
	var status_mult := 1.0
	if limb != null and limb.status != BodyPart.Status.HEALTHY:
		const MULT = {
			BodyPart.Status.BRUISED:  0.85,
			BodyPart.Status.BROKEN:   0.6,
			BodyPart.Status.DISABLED: 0.4,
		}
		const STATUS_TEXT = {
			BodyPart.Status.BRUISED:  "bruised",
			BodyPart.Status.BROKEN:   "broken",
			BodyPart.Status.DISABLED: "destroyed",
		}
		status_mult = MULT.get(limb.status, 1.0)
		var combo = card.combo_names.get(part, card.card_name)
		var display = player.LIMB_DISPLAY.get(limb_name, limb_name)
		combat_log.log_info("Your %s is %s — %s deals reduced damage." % [display, STATUS_TEXT.get(limb.status, ""), combo])

	var power := player.stats.get_power(limb_name) if player.stats != null else 1.0
	return int(dmg * status_mult * power)

const SHK_BASE_MISS := 0.2

func _shk_speed_miss() -> bool:
	var limb_name = ATTACK_LIMB_MAP.get("Spinning Heel Kick", "voeten")
	var speed := player.stats.get_speed(limb_name) if player.stats != null else 1.0
	return randf() < SHK_BASE_MISS / maxf(speed, 0.01)

func _apply_player_guard():
	if player_guard_card == null:
		return
	var required_limbs = GUARD_LIMB_REQ.get(player_guard_card.defends_part, [])
	var block_fails = false
	var damaged_limbs: Array = []
	for ln in required_limbs:
		var limb = player.body_parts.get(ln)
		if limb == null:
			continue
		if limb.status == BodyPart.Status.DISABLED:
			block_fails = true
			break
		elif limb.status in [BodyPart.Status.BRUISED, BodyPart.Status.BROKEN]:
			damaged_limbs.append(ln)
	if not block_fails:
		player.defending_part = player_guard_card.defends_part
		if not damaged_limbs.is_empty():
			player.double_chip_damage = true

func _log_messages(messages: Array):
	for msg in messages:
		if msg is Dictionary:
			match msg.get("type", ""):
				"fatal_enemy": combat_log.log_attack(msg["text"])
				"sub":         combat_log.log_status(msg["text"])
				_:             combat_log.log_status(msg["text"])
		elif "schade" in msg or "Raak" in msg:
			combat_log.log_attack(msg)
		elif "gekneusd" in msg or "gebroken" in msg or "uitgeschakeld" in msg:
			combat_log.log_status(msg)
		else:
			combat_log.log_info(msg)

func _has_fatal_enemy(messages: Array) -> bool:
	return messages.any(func(m): return m is Dictionary and m.get("type", "") == "fatal_enemy")

func _has_fatal_player(messages: Array) -> bool:
	return messages.any(func(m): return m is Dictionary and m.get("type", "") == "fatal_player")

func _warn_fatal_organ_status():
	for bp_name in ["hoofd", "borst"]:
		var bp = player.body_parts.get(bp_name)
		if bp == null:
			continue
		for sub in bp.sub_parts:
			if sub["effect"] == "brain" and sub["hp"] < sub.get("max_hp", 1):
				if sub["hp"] == 1:
					combat_log.log_attack("Brain critically damaged — one more hit = death!")
				elif sub["hp"] == 2:
					combat_log.log_status("Brain taking damage — one more hit could be fatal!")
			elif sub["effect"] == "spine" and sub["hp"] == 1:
				combat_log.log_status("Spine compressed — one more hit could be fatal!")

func update_ui():
	ui.update(player, enemy)
	player_body_highlight.queue_redraw()
