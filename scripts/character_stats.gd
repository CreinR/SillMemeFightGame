class_name CharacterStats
extends Resource

# Per-body-part stats. Head/Chest have Durability + Toughness only.
# Arms/Legs also have Power (outgoing damage) and Speed (SHK miss).
# All values on a 0.5–1.5 scale; default 1.0.
var stats: Dictionary = {}

# ---------------------------------------------------------------------------
# Kickboxer profile
# ---------------------------------------------------------------------------
static func kickboxer() -> CharacterStats:
	var cs = CharacterStats.new()
	cs.stats = {
		"hoofd":      {"durability": 0.8, "toughness": 0.7},
		"borst":      {"durability": 1.2, "toughness": 1.3},
		"linkerarm":  {"durability": 1.0, "toughness": 1.0, "power": 1.0, "speed": 1.3},
		"rechterarm": {"durability": 1.0, "toughness": 1.0, "power": 1.2, "speed": 1.0},
		"bovenbenen": {"durability": 1.2, "toughness": 1.0, "power": 1.0, "speed": 1.1},
		"voeten":     {"durability": 1.2, "toughness": 1.0, "power": 1.3, "speed": 0.8},
	}
	return cs

# ---------------------------------------------------------------------------
# Default enemy profile
# ---------------------------------------------------------------------------
static func enemy_default() -> CharacterStats:
	var cs = CharacterStats.new()
	cs.stats = {
		"hoofd":      {"durability": 1.2, "toughness": 1.1},
		"borst":      {"durability": 0.8, "toughness": 0.7},
		"linkerarm":  {"durability": 1.0, "toughness": 1.0, "power": 0.8, "speed": 0.8},
		"rechterarm": {"durability": 1.0, "toughness": 1.0, "power": 1.3, "speed": 1.1},
		"bovenbenen": {"durability": 0.8, "toughness": 0.8, "power": 1.0, "speed": 1.2},
		"voeten":     {"durability": 0.8, "toughness": 0.8, "power": 1.1, "speed": 1.0},
	}
	return cs

# ---------------------------------------------------------------------------
# Accessors — return 1.0 if stat not defined for this part
# ---------------------------------------------------------------------------
func get_durability(part: String) -> float:
	return stats.get(part, {}).get("durability", 1.0)

func get_toughness(part: String) -> float:
	return stats.get(part, {}).get("toughness", 1.0)

func get_power(part: String) -> float:
	return stats.get(part, {}).get("power", 1.0)

func get_speed(part: String) -> float:
	return stats.get(part, {}).get("speed", 1.0)

func has_power(part: String) -> bool:
	return stats.get(part, {}).has("power")

func has_speed(part: String) -> bool:
	return stats.get(part, {}).has("speed")
