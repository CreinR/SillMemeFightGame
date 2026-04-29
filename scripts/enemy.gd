class_name Enemy
extends Node

var intent_damage: int = 10
var stun: bool = false
var attack_target_part: String = "borst"

# Sub-part effect state
var jaw_skip_turns: int = 0      # jaw: can't attack for N turns
var concussion_turns: int = 0    # brain: tracks confusion (targeting already random)
var rib_reflect: bool = false    # ribs: every attack deals 1 self-damage
var lung_debuff_turns: int = 0   # lung: reduced damage for N turns
var lung_debuff_value: int = 0   # lung: amount of reduction
var wrist_miss: bool = false     # wrist: 50% miss on next attack
var elbow_debuff: int = 0        # elbow: damage reduction on next attack

var body_parts: Dictionary = {
	"hoofd":       BodyPart.new(),
	"borst":       BodyPart.new(),
	"linkerarm":   BodyPart.new(),
	"rechterarm":  BodyPart.new(),
	"linkerbeen":  BodyPart.new(),
	"rechterbeen": BodyPart.new(),
}

func _ready():
	_setup_body_parts()
	_setup_sub_parts()
	_pick_target_part()

func _setup_body_parts():
	var configs = {
		"hoofd":      {"hp": 15, "max_hp": 15},
		"borst":      {"hp": 30, "max_hp": 30},
		"linkerarm":  {"hp": 20, "max_hp": 20},
		"rechterarm": {"hp": 20, "max_hp": 20},
		"linkerbeen":  {"hp": 20, "max_hp": 20},
		"rechterbeen": {"hp": 20, "max_hp": 20},
	}
	for pname in configs:
		body_parts[pname].part_name = pname
		body_parts[pname].hp = configs[pname]["hp"]
		body_parts[pname].max_hp = configs[pname]["max_hp"]

func _setup_sub_parts():
	_add_subs("hoofd", [
		{"name": "Kaak",     "base_chance": 0.40, "effect": "jaw",
		 "log_msg": "Zijn kaak klapt scheef! Hij kan even niet schreeuwen."},
		{"name": "Hersenen", "base_chance": 0.15, "effect": "brain",
		 "hp": 3, "max_hp": 3,
		 "stage_msgs": [
			 "De hersenen begeven het. Einde verhaal.",
			 "Hersenen kritiek! Nog één klap is fataal.",
			 "Hersenschudding niveau 1! 2 HP over.",
		 ]},
	])
	_add_subs("borst", [
		{"name": "Ribben", "base_chance": 0.50, "effect": "ribs",
		 "log_msg": "Krak! Zijn ribben protesteren bij elke beweging."},
		{"name": "Long",   "base_chance": 0.25, "effect": "lung",
		 "log_msg": "Hij hijgt als een astmatische labrador."},
		{"name": "Hart",   "base_chance": 0.08, "effect": "heart",
		 "log_msg": "Het hart stopt met kloppen. Het is voorbij."},
		{"name": "Wervelkolom", "base_chance": 0.12, "effect": "spine",
		 "hp": 2, "max_hp": 2,
		 "stage_msgs": [
			 "De wervelkolom bezwijkt. Game over.",
			 "Ruggenmerg samengeperst! 1 HP over.",
		 ]},
	])
	for leg in ["linkerbeen", "rechterbeen"]:
		_add_subs(leg, [
			{"name": "Knieschijf", "base_chance": 0.35, "effect": "kneecap",
			 "log_msg": "Zijn knie geeft het op. Hij staat als een standbeeld."},
			{"name": "Dijbeen",    "base_chance": 0.30, "effect": "thigh",
			 "log_msg": "Zijn bovenbeen trilt als een pudding."},
		])
	for arm in ["linkerarm", "rechterarm"]:
		_add_subs(arm, [
			{"name": "Elleboog", "base_chance": 0.30, "effect": "elbow",
			 "log_msg": "Zijn elleboog knalt. Dat voelt hij morgen nog."},
			{"name": "Pols",     "base_chance": 0.25, "effect": "wrist",
			 "log_msg": "Zijn pols wiebelt gevaarlijk. Mikken wordt lastig."},
		])

func _add_subs(part_name: String, subs: Array):
	var part = body_parts.get(part_name)
	if part == null:
		return
	for s in subs:
		part.sub_parts.append({
			"name":        s["name"],
			"hp":          s.get("hp", 1),
			"max_hp":      s.get("max_hp", 1),
			"base_chance": s["base_chance"],
			"effect":      s["effect"],
			"log_msg":     s.get("log_msg", ""),
			"stage_msgs":  s.get("stage_msgs", []),
		})

func _pick_target_part():
	var targets = ["hoofd", "borst", "linkerarm", "rechterarm", "linkerbeen", "rechterbeen"]
	attack_target_part = targets[randi() % targets.size()]

func take_damage(amount: int, target_part: String) -> Array:
	var messages = []
	var part = body_parts.get(target_part)
	if part == null:
		return messages

	var old_penalty = part.get_damage_penalty()
	var status_msg = part.take_damage(amount)
	messages.append("Raak! Vijand krijgt %d schade op %s." % [amount, target_part])
	if status_msg != "":
		messages.append(status_msg)

	if target_part in ["rechterarm", "linkerarm"]:
		var new_penalty = part.get_damage_penalty()
		if new_penalty != old_penalty:
			intent_damage = int(intent_damage * new_penalty) if new_penalty > 0.0 else 0
			messages.append("Door de verwonding doet de vijand nu %d schade." % intent_damage)

	for hit in part.roll_sub_parts():
		_apply_sub_effect(hit["effect"])
		if hit.get("fatal", false) and hit["effect"] in ["heart", "brain", "spine"]:
			messages.append({"text": hit["log_msg"], "type": "fatal_enemy", "organ": hit["effect"]})
		else:
			messages.append({"text": hit["log_msg"], "type": "sub"})

	return messages

func _apply_sub_effect(effect: String):
	match effect:
		"jaw":
			jaw_skip_turns += 1
		"brain":
			concussion_turns = min(concussion_turns + 1, 3)
			_pick_target_part()
		"ribs":
			rib_reflect = true
		"lung":
			lung_debuff_turns = 2
			lung_debuff_value = 3
		"heart":
			pass  # fatal — battle.gd handles game over
		"spine":
			pass  # fatal — battle.gd handles game over
		"kneecap":
			pass
		"thigh":
			intent_damage = max(0, intent_damage - 2)
		"elbow":
			elbow_debuff += 2
		"wrist":
			wrist_miss = true

func take_turn(player) -> Array:
	var messages = []

	if stun:
		stun = false
		messages.append("Vijand is verdoofd en slaat over!")
		_pick_target_part()
		return messages

	if jaw_skip_turns > 0:
		jaw_skip_turns -= 1
		messages.append("Vijand kan zijn kaak niet bewegen. Hij slaat over!")
		_pick_target_part()
		return messages

	if wrist_miss:
		wrist_miss = false
		if randf() < 0.5:
			messages.append("De vijand mist! Zijn pols laat hem in de steek.")
			_pick_target_part()
			return messages

	var actual_damage = intent_damage
	if lung_debuff_turns > 0:
		actual_damage = max(0, actual_damage - lung_debuff_value)
		lung_debuff_turns -= 1
	if elbow_debuff > 0:
		actual_damage = max(0, actual_damage - elbow_debuff)
		elbow_debuff = 0

	messages.append("Vijand slaat voor %d schade op %s!" % [actual_damage, attack_target_part])
	var dmg_messages = player.take_damage(actual_damage, attack_target_part)
	messages.append_array(dmg_messages)

	if rib_reflect:
		body_parts["borst"].take_damage(1)
		messages.append("Krak! Zijn ribben vlammen op bij de aanval.")

	if concussion_turns > 0:
		concussion_turns -= 1

	_pick_target_part()
	return messages
