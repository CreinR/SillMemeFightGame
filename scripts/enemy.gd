class_name Enemy
extends Node

var position: int = 4
var intent_damage: int = 10
var stun: bool = false
var attack_target_part: String = "borst"

# Planned actions for the simultaneous turn
var planned_movement: int = 0     # -1 = away, 0 = stance, 1 = toward player
var planned_guard: String = ""    # body part being guarded this turn
var intent_attack_name: String = "Jab"
var intent_attack_min_range: int = 2
var intent_attack_max_range: int = 3
var intent_attack_limb: String = "linkerarm"

# Sub-part effect state
var jaw_skip_turns: int = 0      # jaw: can't attack for N turns
var concussion_turns: int = 0    # brain: tracks confusion (targeting already random)
var rib_reflect: bool = false    # ribs: every attack deals 1 self-damage
var lung_debuff_turns: int = 0   # lung: reduced damage for N turns
var lung_debuff_value: int = 0   # lung: amount of reduction
var wrist_miss: bool = false     # wrist: 50% miss on next attack
var elbow_debuff: int = 0        # elbow: damage reduction on next attack
var stagger_turns: int = 0       # can't use movement next turn (Spinning Heel miss)
var stats: CharacterStats = null

# Full new attack roster (used by enemy AI)
const ATTACK_ROSTER = [
	{
		"name": "Jab", "limb": "linkerarm",
		"min_range": 2, "max_range": 3,
		"targets": {
			"hoofd": {"damage": 6},
			"borst": {"damage": 5},
		}
	},
	{
		"name": "Hook", "limb": "rechterarm",
		"min_range": 1, "max_range": 1,
		"targets": {
			"hoofd": {"damage": 12, "effect": "stun"},
			"borst": {"damage": 10},
		}
	},
	{
		"name": "Uppercut", "limb": "rechterarm",
		"min_range": 1, "max_range": 1,
		"targets": {
			"hoofd": {"damage": 14, "effect": "stun"},
			"borst": {"damage": 8},
		}
	},
	{
		"name": "Overhand", "limb": "rechterarm",
		"min_range": 1, "max_range": 2,
		"targets": {
			"hoofd": {"damage": 10, "effect": "overhand_bypass"},
		}
	},
	{
		"name": "Roundhouse Kick", "limb": "voeten",
		"min_range": 2, "max_range": 3,
		"targets": {
			"hoofd":      {"damage": 10, "effect": "stun"},
			"borst":      {"damage": 8},
			"bovenbenen": {"damage": 6, "effect": "weaken", "value": 3},
			"voeten":     {"damage": 4, "effect": "stun"},
		}
	},
	{
		"name": "Front Kick", "limb": "bovenbenen",
		"min_range": 2, "max_range": 3,
		"targets": {
			"borst":      {"damage": 7, "effect": "front_kick_push"},
			"bovenbenen": {"damage": 6, "effect": "front_kick_push"},
		}
	},
	{
		"name": "Spinning Heel Kick", "limb": "voeten",
		"min_range": 3, "max_range": 4,
		"targets": {
			"hoofd": {"damage": 16, "effect": "stun"},
		}
	},
]

var body_parts: Dictionary = {
	"hoofd":      BodyPart.new(),
	"borst":      BodyPart.new(),
	"linkerarm":  BodyPart.new(),
	"rechterarm": BodyPart.new(),
	"bovenbenen": BodyPart.new(),
	"voeten":     BodyPart.new(),
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
		"bovenbenen": {"hp": 20, "max_hp": 20},
		"voeten":     {"hp": 20, "max_hp": 20},
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
	for leg in ["bovenbenen", "voeten"]:
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

const BASE_HP := {
	"hoofd": 15, "borst": 30,
	"linkerarm": 20, "rechterarm": 20,
	"bovenbenen": 20, "voeten": 20,
}

func apply_stats(cs: CharacterStats) -> void:
	stats = cs
	for pname in body_parts:
		var new_hp := maxi(1, roundi(BASE_HP.get(pname, 20) * cs.get_durability(pname)))
		body_parts[pname].hp       = new_hp
		body_parts[pname].max_hp   = new_hp
		body_parts[pname].toughness = cs.get_toughness(pname)

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

func _pick_target_part(attack_data: Dictionary = {}):
	var targets: Array
	if attack_data.has("targets"):
		targets = attack_data["targets"].keys()
	else:
		targets = ["hoofd", "borst", "bovenbenen", "voeten"]
	attack_target_part = targets[randi() % targets.size()]

# Called at the start of the player's planning phase — plans all 3 enemy actions.
func plan_turn(player_pos: int):
	# --- Movement ---
	if stagger_turns > 0:
		stagger_turns -= 1
		planned_movement = 0
	else:
		_plan_movement(player_pos)

	# --- Attack ---
	_plan_attack(player_pos)

	# --- Guard ---
	var guard_options = ["hoofd", "borst", "bovenbenen", "voeten"]
	planned_guard = guard_options[randi() % guard_options.size()]

func _plan_movement(player_pos: int):
	var distance = abs(player_pos - position)
	var r = randf()
	if distance > 3:
		# Too far — always close in
		planned_movement = 1
	elif distance <= 1:
		# Too close — always back up
		planned_movement = -1
	else:
		# Preferred range: weight toward stance/forward
		if r < 0.15:
			planned_movement = -1
		elif r < 0.55:
			planned_movement = 0
		else:
			planned_movement = 1

func _plan_attack(player_pos: int):
	var distance = abs(player_pos - position)
	var valid: Array = []
	for atk in ATTACK_ROSTER:
		if distance >= atk["min_range"] and distance <= atk["max_range"]:
			valid.append(atk)
	if valid.is_empty():
		# Fallback to jab regardless of range
		valid = [ATTACK_ROSTER[0]]
	var chosen = valid[randi() % valid.size()]
	intent_attack_name = chosen["name"]
	intent_attack_min_range = chosen["min_range"]
	intent_attack_max_range = chosen["max_range"]
	intent_attack_limb = chosen.get("limb", "linkerarm")
	_pick_target_part(chosen)

	# Base damage from chosen attack for target
	var dmg = 0
	if chosen["targets"].has(attack_target_part):
		dmg = chosen["targets"][attack_target_part].get("damage", 0)

	# Apply arm damage penalty to intent_damage
	var limb = body_parts.get(intent_attack_limb)
	if limb != null:
		match limb.status:
			BodyPart.Status.BRUISED:  dmg = int(dmg * 0.85)
			BodyPart.Status.BROKEN:   dmg = int(dmg * 0.6)
			BodyPart.Status.DISABLED: dmg = int(dmg * 0.4)

	if lung_debuff_turns > 0:
		dmg = max(0, dmg - lung_debuff_value)

	if stats != null:
		dmg = int(dmg * stats.get_power(intent_attack_limb))

	intent_damage = dmg

# Returns a dictionary with the attack data for the current planned attack.
func get_planned_attack_data() -> Dictionary:
	for atk in ATTACK_ROSTER:
		if atk["name"] == intent_attack_name:
			return atk
	return {}

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
			stagger_turns = 2
		"thigh":
			intent_damage = max(0, intent_damage - 2)
		"elbow":
			elbow_debuff += 2
		"wrist":
			wrist_miss = true

# Guard limb map — which player limb absorbs chip when guarding each part
const GUARD_LIMB_MAP = {
	"hoofd":      "linkerarm",
	"borst":      "rechterarm",
	"bovenbenen": "bovenbenen",
	"voeten":     "voeten",
}
