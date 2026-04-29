class_name BodyPart
extends Resource

enum Status { HEALTHY, BRUISED, BROKEN, DISABLED }

@export var part_name: String = ""
@export var hp: int = 20
@export var max_hp: int = 20
@export var status: Status = Status.HEALTHY
@export var damage_modifier: float = 1.0

# Each entry: {name, hp, base_chance, effect, log_msg}
var sub_parts: Array = []

func take_damage(amount: int) -> String:
	hp -= amount
	return _update_status()

func _update_status() -> String:
	var old_status = status
	if hp <= 0:
		status = Status.DISABLED
	elif hp <= max_hp * 0.25:
		status = Status.BROKEN
	elif hp <= max_hp * 0.5:
		status = Status.BRUISED

	if status != old_status:
		return _status_change_message()
	return ""

func _status_change_message() -> String:
	match status:
		Status.BRUISED:  return "%s is gekneusd!" % part_name
		Status.BROKEN:   return "%s is gebroken!" % part_name
		Status.DISABLED: return "%s is uitgeschakeld!" % part_name
	return ""

func get_damage_penalty() -> float:
	match status:
		Status.BRUISED:  return 0.8
		Status.BROKEN:   return 0.5
		Status.DISABLED: return 0.0
	return 1.0

# Rolls sub-parts. Returns array of {effect, log_msg, hp_remaining, fatal}.
# Binary sub-parts (max_hp=1) set hp=0 on hit and return fatal=true.
# Degrading organs (max_hp>1) reduce hp by 1; fatal=true when hp reaches 0.
func roll_sub_parts() -> Array:
	const MULTIPLIERS = [1.0, 1.5, 2.5, 0.0]  # HEALTHY / BRUISED / BROKEN / DISABLED
	var hits = []
	var multiplier = MULTIPLIERS[status]
	if multiplier == 0.0:
		return hits
	for sub in sub_parts:
		if sub["hp"] <= 0:
			continue
		if randf() < sub["base_chance"] * multiplier:
			sub["hp"] -= 1
			var is_fatal = sub["hp"] <= 0
			var stage_msgs = sub.get("stage_msgs", [])
			var msg: String
			if not stage_msgs.is_empty() and sub["hp"] < stage_msgs.size():
				msg = stage_msgs[sub["hp"]]
			else:
				msg = sub.get("log_msg", "")
			hits.append({
				"effect":       sub["effect"],
				"log_msg":      msg,
				"hp_remaining": sub["hp"],
				"fatal":        is_fatal,
			})
	return hits
