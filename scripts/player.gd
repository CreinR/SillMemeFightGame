class_name Player
extends Node

var position: int = 2
var movement_locked: bool = false
var pending_cards: Array = []
var energy: int = 3
var max_energy: int = 3
var max_hand_size: int = 3
var deck: Array = []
var hand: Array = []
var discard: Array = []
var defending_part: String = ""
var has_defended: bool = false
var has_attacked: bool = false
var double_chip_damage: bool = false

# Sub-part effect state
var jaw_skip_attack: int = 0      # skip attack phase for N turns
var concussion_turns: int = 0     # random attack card selected for N turns
var rib_self_damage: bool = false  # 1 self-damage each time an attack card is played
var lung_draw_penalty: int = 0    # draw 1 fewer card for N draws
var elbow_debuff: int = 0         # reduce own attack damage on next attack
var wrist_miss: bool = false      # 50% miss on next attack
var kneecap_turns: int = 0        # can't use Forward/Back for N turns

# Which limb absorbs chip damage when guarding each body part
const GUARD_LIMB_MAP = {
	"hoofd":       "linkerarm",
	"borst":       "rechterarm",
	"linkerbeen":  "linkerbeen",
	"rechterbeen": "rechterbeen",
}

const LIMB_DISPLAY = {
	"linkerarm":   "left arm",
	"rechterarm":  "right arm",
	"linkerbeen":  "left leg",
	"rechterbeen": "right leg",
}

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
		{"name": "Jaw",   "base_chance": 0.40, "effect": "jaw",
		 "log_msg": "Your jaw snaps sideways. Talking is overrated anyway."},
		{"name": "Brain", "base_chance": 0.15, "effect": "brain",
		 "hp": 3, "max_hp": 3,
		 "stage_msgs": [
			 "Lights out. The brain can't take any more.",
			 "Brain critically damaged — one more hit = death!",
			 "Brain rattled! 2 HP remaining.",
		 ]},
	])
	_add_subs("borst", [
		{"name": "Ribs",  "base_chance": 0.50, "effect": "ribs",
		 "log_msg": "Crack! Your ribs file a formal complaint."},
		{"name": "Lung",  "base_chance": 0.25, "effect": "lung",
		 "log_msg": "You wheeze like a broken accordion."},
		{"name": "Heart", "base_chance": 0.08, "effect": "heart",
		 "log_msg": "The heart gives out. It's over."},
		{"name": "Spine", "base_chance": 0.12, "effect": "spine",
		 "hp": 2, "max_hp": 2,
		 "stage_msgs": [
			 "The spine collapses. Nobody's walking away from that.",
			 "Spine compressed! 1 HP remaining.",
		 ]},
	])
	for leg in ["linkerbeen", "rechterbeen"]:
		_add_subs(leg, [
			{"name": "Kneecap", "base_chance": 0.35, "effect": "kneecap",
			 "log_msg": "Your kneecap relocates. Staying put it is."},
			{"name": "Thigh",   "base_chance": 0.30, "effect": "thigh",
			 "log_msg": "Your thigh jiggles like jelly. Moving is complicated."},
		])
	for arm in ["linkerarm", "rechterarm"]:
		_add_subs(arm, [
			{"name": "Elbow", "base_chance": 0.30, "effect": "elbow",
			 "log_msg": "Your elbow pops. Punching feels like a bad idea."},
			{"name": "Wrist", "base_chance": 0.25, "effect": "wrist",
			 "log_msg": "Your wrist wobbles dangerously. Aiming is a suggestion."},
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

func start_turn():
	energy = max_energy
	movement_locked = false
	has_defended = false
	has_attacked = false
	defending_part = ""
	double_chip_damage = false
	hand.clear()
	for c in pending_cards:
		hand.append(c)
	pending_cards.clear()

func draw_cards(amount: int):
	var actual = max(0, amount - (1 if lung_draw_penalty > 0 else 0))
	if lung_draw_penalty > 0:
		lung_draw_penalty -= 1
	for i in actual:
		if hand.size() >= max_hand_size:
			break
		if deck.is_empty():
			shuffle_discard_into_deck()
		if not deck.is_empty():
			hand.append(deck.pop_back())

func shuffle_discard_into_deck():
	deck = discard.duplicate()
	deck.shuffle()
	discard.clear()

func take_damage(amount: int, target_part: String = "borst") -> Array:
	var messages = []
	var blocked = defending_part != "" and target_part == defending_part

	if blocked:
		var limb_name = GUARD_LIMB_MAP.get(target_part, "")
		if limb_name != "" and amount > 0:
			var chip = ceili(amount * 0.2)
			if double_chip_damage:
				chip *= 2
				double_chip_damage = false
			var limb = body_parts.get(limb_name)
			if limb != null and limb.status != BodyPart.Status.DISABLED:
				var display = LIMB_DISPLAY.get(limb_name, limb_name)
				var status_msg = limb.take_damage(chip)
				messages.append({"text": "Blocked with your %s! Took %d chip damage." % [display, chip], "type": "chip"})
				if status_msg != "":
					messages.append(status_msg)
				for hit in limb.roll_sub_parts():
					_apply_sub_effect(hit["effect"])
					if hit.get("fatal", false) and hit["effect"] in ["heart", "brain", "spine"]:
						messages.append({"text": hit["log_msg"], "type": "fatal_player", "organ": hit["effect"]})
					else:
						messages.append({"text": hit["log_msg"], "type": "sub"})
		return messages

	if amount <= 0:
		return messages

	if movement_locked:
		movement_locked = false
		pending_cards.clear()

	var part = body_parts.get(target_part)
	if part == null:
		return messages

	var status_msg = part.take_damage(amount)
	if status_msg != "":
		messages.append(status_msg)

	for hit in part.roll_sub_parts():
		_apply_sub_effect(hit["effect"])
		if hit.get("fatal", false) and hit["effect"] in ["heart", "brain", "spine"]:
			messages.append({"text": hit["log_msg"], "type": "fatal_player", "organ": hit["effect"]})
		else:
			messages.append({"text": hit["log_msg"], "type": "sub"})

	return messages

func _apply_sub_effect(effect: String):
	match effect:
		"jaw":
			jaw_skip_attack += 1
		"brain":
			concussion_turns = max(concussion_turns, 2)
		"ribs":
			rib_self_damage = true
		"lung":
			lung_draw_penalty = 2
		"heart":
			pass  # fatal — battle.gd handles game over
		"spine":
			pass  # fatal — battle.gd handles game over
		"kneecap":
			kneecap_turns = 2
		"thigh":
			pass
		"elbow":
			elbow_debuff += 2
		"wrist":
			wrist_miss = true

func play_card(card: Card, enemy):
	if card.is_attack() and has_attacked:
		return
	if card.is_defense() and has_defended:
		return
	if card.is_attack():
		has_attacked = true
	if card.is_defense():
		has_defended = true
	card.play(self, enemy)
	hand.erase(card)
	discard.append(card)
