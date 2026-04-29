class_name Battle
extends Node

signal combo_landed

@onready var player = $Player
@onready var enemy = $Enemy
@onready var ui = $CanvasLayer/BattleUI
@onready var combat_log = $CanvasLayer/BattleUI/CombatLog
@onready var body_highlight = $CanvasLayer/BattleUI/BodyHighlight
@onready var body_selector = $CanvasLayer/BattleUI/BodyPartSelector
@onready var player_body_highlight = $CanvasLayer/BattleUI/PlayerBodyHighlight

var selected_body_part: String = "borst"

func _ready():
	var tooltip = BodyTooltip.new()
	$CanvasLayer/BattleUI.add_child(tooltip)
	tooltip.move_to_front()

	setup_starter_deck()
	ui.setup(self)
	body_highlight.setup(enemy, tooltip)
	body_selector.setup(body_highlight)
	body_selector.part_selected.connect(_on_part_selected)
	player_body_highlight.setup(player, tooltip)
	player_body_highlight.part_selected.connect(_on_player_part_selected)
	start_player_turn()

func _on_part_selected(part_name: String):
	selected_body_part = part_name
	if pending_attack != null:
		apply_pending_attack(part_name)
	else:
		combat_log.log_info("Richten op: %s" % part_name)

func setup_starter_deck():
	var kaarten = [
		{"naam": "Koffie Gooien", "cost": 1, "damage": 6,  "block": 0, "type": "attack",  "desc": "Gooi hete koffie!\n6 schade"},
		{"naam": "Karen Mode",    "cost": 2, "damage": 12, "block": 0, "type": "attack",  "desc": "Roep de manager!\n12 schade"},
		{"naam": "Bubblewrap",    "cost": 1, "damage": 0,  "block": 5, "type": "block",   "desc": "Wrap jezelf in!\n5 blok"},
		{"naam": "WiFi Reset",    "cost": 0, "damage": 0,  "block": 3, "type": "special", "desc": "Even resetten.\n3 blok"},
		{"naam": "Selfie Stick",  "cost": 1, "damage": 4,  "block": 0, "type": "attack",  "desc": "Mep ze ermee!\n4 schade"},
	]

	for data in kaarten:
		var card = Card.new()
		card.card_name = data["naam"]
		card.cost = data["cost"]
		card.damage = data["damage"]
		card.block = data["block"]
		card.card_type = data["type"]
		card.description = data["desc"]
		player.deck.append(card)

	player.deck.shuffle()

func _make_card(cname: String, cost: int, dmg: int, blk: int, desc: String, min_r: int = 1, max_r: int = 7) -> Card:
	var c = Card.new()
	c.card_name = cname
	c.cost = cost
	c.damage = dmg
	c.block = blk
	c.description = desc
	c.min_range = min_r
	c.max_range = max_r
	return c

func _make_gun() -> Card:
	var gun = Card.new()
	gun.card_name = "Draw Gun"
	gun.cost = 0
	gun.costs_all_energy = true
	gun.description = "Draw your weapon.\nCan no longer move.\nNext turn: Aim Gun"
	gun.locks_movement = true
	gun.follow_up_card_name = "Aim Gun"
	return gun

func _build_kickbokser_deck():
	pass

func _make_defense(cname: String, part: String) -> Card:
	var c = Card.new()
	c.card_name = cname
	c.cost = 1
	c.defends_part = part
	var part_names = {"hoofd": "Head", "borst": "Chest", "linkerbeen": "Left Leg", "rechterbeen": "Right Leg"}
	c.description = "Guard your %s.\nIf the enemy attacks\nthis part: 0 damage." % part_names.get(part, part)
	return c

func _make_jab() -> Card:
	var c = Card.new()
	c.card_name = "Jab"
	c.cost = 1
	c.min_range = 2
	c.max_range = 2
	c.description = "Quick punch (1 gap).\nHead: 5\nChest: 4\nLegs: 3\nFeet: 3"
	c.body_part_effects = {
		"hoofd":       {"damage": 5},
		"borst":       {"damage": 4},
		"linkerbeen":  {"damage": 3},
		"rechterbeen": {"damage": 3},
	}
	c.combo_names = {
		"hoofd":       "Head Jab",
		"borst":       "Body Jab",
		"linkerbeen":  "Low Jab",
		"rechterbeen": "Low Jab",
	}
	return c

func _make_hook() -> Card:
	var c = Card.new()
	c.card_name = "Hook"
	c.cost = 2
	c.min_range = 1
	c.max_range = 1
	c.description = "Powerful hook (adjacent).\nHead: 12 + stun\nChest: 10"
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
	c.cost = 2
	c.min_range = 1
	c.max_range = 1
	c.description = "Rising punch.\nHead: 14 + stun\nChest: 8"
	c.body_part_effects = {
		"hoofd": {"damage": 14, "effect": "stun"},
		"borst": {"damage": 8},
	}
	c.combo_names = {
		"hoofd": "KO Uppercut",
		"borst": "Body Uppercut",
	}
	return c

func _make_knee() -> Card:
	var c = Card.new()
	c.card_name = "Knee"
	c.cost = 1
	c.min_range = 1
	c.max_range = 1
	c.description = "Knee strike.\nChest: 9\nLegs: 7 + weaken"
	c.body_part_effects = {
		"borst":       {"damage": 9},
		"linkerbeen":  {"damage": 7, "effect": "weaken", "value": 3},
		"rechterbeen": {"damage": 7, "effect": "weaken", "value": 3},
	}
	c.combo_names = {
		"borst":       "Body Knee",
		"linkerbeen":  "Leg Knee",
		"rechterbeen": "Leg Knee",
	}
	return c

func _make_body_part_card(part: String) -> Card:
	var c = Card.new()
	var names = {"hoofd": "Head", "borst": "Chest", "linkerbeen": "Left Leg", "rechterbeen": "Right Leg"}
	c.card_name = names.get(part, part)
	c.cost = 0
	c.is_body_part_target = true
	c.target_part = part
	c.description = "Target\n%s" % names.get(part, part)
	return c

func _make_kick() -> Card:
	var c = Card.new()
	c.card_name = "Kick"
	c.cost = 1
	c.min_range = 2
	c.max_range = 2
	c.description = "Kick (1 gap).\nHead: 10 + stun\nChest: 8\nLegs: 6 + weaken\nFeet: 4 + stun"
	c.body_part_effects = {
		"hoofd":       {"damage": 10, "effect": "stun"},
		"borst":       {"damage": 8},
		"linkerbeen":  {"damage": 6,  "effect": "weaken", "value": 3},
		"rechterbeen": {"damage": 4,  "effect": "stun"},
	}
	c.combo_names = {
		"hoofd":       "Head Kick",
		"borst":       "Middle Kick",
		"linkerbeen":  "Low Kick",
		"rechterbeen": "Sweep Kick",
	}
	return c

func _build_streamer_deck():
	for i in 4: player.deck.append(_make_card("Arrow", 1, 8, 0, "Deal 8 damage\n(ranged only)", 3, 5))
	for i in 2: player.deck.append(_make_card("Attack", 1, 6, 0, "Deal 6 damage"))
	for i in 2: player.deck.append(_make_card("Defend", 1, 0, 5, "Gain 5 block"))
	player.deck.append(_make_card("Shield", 2, 0, 12, "Gain 12 block"))
	for i in 2: player.deck.append(_make_gun())

var turn_phase: int = 1  # 1=move 2=attack 3=defense
var pending_attack: Card = null
var pending_guard: Card = null

const ATTACK_LIMB_MAP: Dictionary = {
	"Jab":      "linkerarm",
	"Hook":     "rechterarm",
	"Uppercut": "rechterarm",
	"Knee":     "linkerbeen",
	"Kick":     "rechterbeen",
}

const GUARD_LIMB_REQ: Dictionary = {
	"hoofd":       ["linkerarm", "rechterarm"],
	"borst":       ["linkerarm"],
	"linkerbeen":  ["linkerbeen"],
	"rechterbeen": ["rechterbeen"],
}

func start_player_turn():
	turn_phase = 1
	pending_guard = null
	player.start_turn()
	body_highlight.set_valid_parts([])
	player_body_highlight.set_valid_parts([])
	_set_movement_hand()
	_warn_fatal_organ_status()
	update_ui()

func _make_move_card(cname: String, direction: int) -> Card:
	var c = Card.new()
	c.card_name = cname
	c.is_movement = true
	c.move_direction = direction
	if direction == 0:
		c.cost = 0
		c.description = "Stay in place.\nNo cost."
	elif direction == 1:
		c.cost = 1
		c.description = "Move one position\nforward."
	else:
		c.cost = 1
		c.description = "Move one position\nbackward."
	return c

func _set_movement_hand():
	player.hand.clear()
	player.hand = [
		_make_move_card("Back", -1),
		_make_move_card("Stance", 0),
		_make_move_card("Forward", 1),
	]

const ENEMY_SLOT = 4

func _do_movement(card: Card):
	if card.move_direction == 0:
		return
	var toward = sign(ENEMY_SLOT - player.position)
	var new_pos = player.position + card.move_direction * toward
	if new_pos < 0 or new_pos >= 6 or new_pos == ENEMY_SLOT:
		return
	player.position = new_pos

func play_card(card: Card):
	if card.is_movement:
		_do_movement(card)
		advance_phase()
		return

	if not card.body_part_effects.is_empty() and pending_attack != null:
		player.energy += pending_attack.cost

	if player.energy < card.cost:
		return
	player.energy -= card.cost

	if not card.body_part_effects.is_empty():
		pending_attack = card
		body_highlight.set_valid_parts(card.body_part_effects.keys())
		update_ui()
		return

	player.play_card(card, enemy)

	if card.damage > 0:
		var messages = enemy.take_damage(card.damage, selected_body_part)
		_log_messages(messages)
		body_highlight.highlight(selected_body_part)
		if _has_fatal_enemy(messages):
			get_tree().change_scene_to_file("res://scenes/win.tscn")
			return

	update_ui()

func advance_phase():
	if turn_phase < 3:
		turn_phase += 1
		if turn_phase == 2:
			if player.kneecap_turns > 0:
				player.kneecap_turns -= 1
			_set_attack_hand()
		elif turn_phase == 3:
			_set_defense_hand()
	update_ui()

func _set_attack_hand():
	pending_attack = null
	player.hand.clear()

	if player.jaw_skip_attack > 0:
		player.jaw_skip_attack -= 1
		combat_log.log_status("Your jaw hurts too much to attack. Skipping.")
		advance_phase()
		return

	match GameState.character_deck_type:
		"kickbokser":
			player.hand = [
				_make_kick(), _make_jab(), _make_hook(), _make_uppercut(), _make_knee(),
			]
			if player.concussion_turns > 0:
				player.concussion_turns -= 1
				var random_card = player.hand[randi() % player.hand.size()]
				pending_attack = random_card
				body_highlight.set_valid_parts(random_card.body_part_effects.keys())
				combat_log.log_status("Seeing stars! A random attack is forced.")
		_:
			player.draw_cards(3)

func apply_pending_attack(part: String):
	if pending_attack == null:
		return
	body_highlight.set_valid_parts([])
	var card = pending_attack
	pending_attack = null
	player.hand.erase(card)
	player.discard.append(card)

	# Wrist miss
	if player.wrist_miss:
		player.wrist_miss = false
		if randf() < 0.5:
			combat_log.log_status("Your wrist gives out! Attack missed.")
			combo_landed.emit()
			advance_phase()
			return

	if card.body_part_effects.has(part):
		var fx = card.body_part_effects[part]
		var dmg = fx.get("damage", 0)

		# Attack limb penalty
		var atk_limb_name = ATTACK_LIMB_MAP.get(card.card_name, "")
		if atk_limb_name != "" and dmg > 0:
			var atk_limb = player.body_parts.get(atk_limb_name)
			if atk_limb != null and atk_limb.status != BodyPart.Status.HEALTHY:
				const MULT_TABLE = {
					BodyPart.Status.BRUISED:  0.85,
					BodyPart.Status.BROKEN:   0.6,
					BodyPart.Status.DISABLED: 0.4,
				}
				const STATUS_TEXT = {
					BodyPart.Status.BRUISED:  "bruised",
					BodyPart.Status.BROKEN:   "broken",
					BodyPart.Status.DISABLED: "destroyed",
				}
				var mult = MULT_TABLE.get(atk_limb.status, 1.0)
				var combo_name = card.combo_names.get(part, card.card_name)
				var limb_display = player.LIMB_DISPLAY.get(atk_limb_name, atk_limb_name)
				dmg = int(dmg * mult)
				combat_log.log_info("Your %s is %s — %s deals reduced damage." % [limb_display, STATUS_TEXT.get(atk_limb.status, ""), combo_name])

		# Elbow debuff
		if player.elbow_debuff > 0:
			dmg = max(0, dmg - player.elbow_debuff)
			player.elbow_debuff = 0

		if dmg > 0:
			var messages = enemy.take_damage(dmg, part)
			_log_messages(messages)
			body_highlight.highlight(part)
			if _has_fatal_enemy(messages):
				combo_landed.emit()
				get_tree().change_scene_to_file("res://scenes/win.tscn")
				return
		var effect = fx.get("effect", "")
		var value = fx.get("value", 0)
		if effect == "stun":
			enemy.stun = true
			combat_log.log_status("Vijand gestunt! Overslaat volgende beurt.")
		elif effect == "weaken":
			enemy.intent_damage = max(0, enemy.intent_damage - value)
			combat_log.log_status("Vijand verzwakt! -%d schade" % value)

	# Rib self-damage
	if player.rib_self_damage:
		player.body_parts["borst"].take_damage(1)
		combat_log.log_status("Crack! Your ribs flare up.")

	combo_landed.emit()
	advance_phase()

func select_guard(card: Card):
	pending_guard = card
	player_body_highlight.set_valid_parts([card.defends_part])
	update_ui()

func apply_pending_guard(part: String):
	if pending_guard == null:
		return
	var card = pending_guard
	pending_guard = null
	player_body_highlight.set_valid_parts([])
	player.hand.erase(card)
	player.discard.append(card)

	var required_limbs = GUARD_LIMB_REQ.get(card.defends_part, [])
	var block_fails = false
	var damaged_limbs: Array = []

	for ln in required_limbs:
		var limb = player.body_parts.get(ln)
		if limb == null:
			continue
		if limb.status == BodyPart.Status.DISABLED:
			block_fails = true
			var display = player.LIMB_DISPLAY.get(ln, ln)
			combat_log.log_attack("Your %s is destroyed — %s fails! Full damage goes through." % [display, card.card_name])
			break
		elif limb.status == BodyPart.Status.BRUISED or limb.status == BodyPart.Status.BROKEN:
			damaged_limbs.append(player.LIMB_DISPLAY.get(ln, ln))

	if not block_fails:
		player.defending_part = card.defends_part
		var names = {"hoofd": "Head", "borst": "Chest", "linkerbeen": "Left Leg", "rechterbeen": "Right Leg"}
		combat_log.log_info("Guarding %s." % names.get(card.defends_part, part))
		if not damaged_limbs.is_empty():
			player.double_chip_damage = true
			combat_log.log_status("Blocking with your damaged %s — chip damage doubled." % " / ".join(damaged_limbs))

	end_turn()

func _on_player_part_selected(part_name: String):
	if turn_phase == 3 and pending_guard != null:
		apply_pending_guard(part_name)

func _set_defense_hand():
	pending_guard = null
	player_body_highlight.set_valid_parts([])
	player.hand.clear()
	match GameState.character_deck_type:
		"kickbokser":
			player.hand = [
				_make_defense("Guard Head",      "hoofd"),
				_make_defense("Guard Chest",     "borst"),
				_make_defense("Guard Left Leg",  "linkerbeen"),
				_make_defense("Guard Right Leg", "rechterbeen"),
			]
		_:
			player.draw_cards(3)

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

func end_turn():
	pending_guard = null
	player_body_highlight.set_valid_parts([])
	var targeted_part = enemy.attack_target_part
	var messages = enemy.take_turn(player)
	var blocked = messages.any(func(m): return m is Dictionary and (m["type"] == "chip" or m["type"] == "chip_warn"))
	var did_attack = messages.any(func(m): return m is String and "slaat" in m)
	if blocked:
		var limb_name = player.GUARD_LIMB_MAP.get(targeted_part, "")
		if limb_name != "":
			player_body_highlight.highlight(limb_name)
	elif did_attack:
		player_body_highlight.highlight(targeted_part)
	for msg in messages:
		if msg is Dictionary:
			match msg.get("type", ""):
				"chip":         combat_log.log_info(msg["text"])
				"fatal_player": combat_log.log_attack(msg["text"])
				"sub":          combat_log.log_status(msg["text"])
				_:              combat_log.log_status(msg["text"])
		elif "gekneusd" in msg or "gebroken" in msg or "uitgeschakeld" in msg:
			combat_log.log_status(msg)
		else:
			combat_log.log_enemy(msg)
	if _has_fatal_player(messages):
		get_tree().change_scene_to_file("res://scenes/game_over.tscn")
		return
	start_player_turn()

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
