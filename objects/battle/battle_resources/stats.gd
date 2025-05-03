extends Resource
class_name BattleStats


# Multiplicative
@export var damage := 1.0:
	set(x):
		damage = x
		if self is PlayerStats:
			print('damage set to ' +str(x))
		s_damage_changed.emit(x)
@export var defense := 1.0:
	set(x):
		defense = x
		if self is PlayerStats:
			print('defense set to ' + str(x))
		s_defense_changed.emit(x)
@export var evasiveness := 1.0:
	set(x):
		evasiveness = x
		if self is PlayerStats:
			print('evasiveness set to ' + str(x))
		s_evasiveness_changed.emit(x)
@export var accuracy := 1.0:
	set(x):
		accuracy = x
		if self is PlayerStats:
			print('accuracy set to ' + str(x))
		s_accuracy_changed.emit(x)

## STAT CLAMPS
var STAT_CLAMPS: Dictionary[String, Vector2] = {
	'speed' : Vector2(0.7, 2.0),
	'damage' : Vector2(0.1, UNCAPPED_STAT_VAL),
	'defense' : Vector2(0.1, UNCAPPED_STAT_VAL),
	'evasiveness' : Vector2(0.1, UNCAPPED_STAT_VAL),
	'luck' : Vector2(0.1, UNCAPPED_STAT_VAL),
}
const UNCAPPED_STAT_VAL := -999.0

@export var speed := 1.0:
	set(x):
		speed = x
		if self is PlayerStats:
			print('speed set to ' + str(x))
		s_speed_changed.emit(x)
@export var max_turns := 3


# Additive
@export var max_hp := 25:
	set(x):
		max_hp = x
		max_hp_changed.emit(x)
@export var hp := 25:
	set(x):
		if debug_invulnerable:
			hp = max_hp
		else:
			hp = clamp(x, 0, max_hp)
		hp_changed.emit(hp)
@export var turns := 1
var debug_invulnerable := false

var multipliers: Array[StatMultiplier] = []

# Signals for objects listening
signal hp_changed(health: int)
signal max_hp_changed(health: int)
signal s_damage_changed(new_damaage: float)
signal s_accuracy_changed(new_accuracy: float)
signal s_defense_changed(new_defense: float)
signal s_evasiveness_changed(new_evasiveness: float)
signal s_speed_changed(new_speed: float)



func _to_string():
	var return_string := "Stats: \n"
	var active = false 
	for property in get_property_list():
		if not active and property.name != 'damage':
			continue
		elif property.name == 'damage': 
			active = true
		return_string += property.name + ': ' + str(get(property.name)) + '\n'
	return return_string

func get_stat(stat: String) -> float:
	if stat in self:
		var base_stat = get(stat)
		var additive_total := 0.0
		var multiplier_total := 1.0
		for multiplier in multipliers:
			if multiplier.stat == stat:
				if multiplier.additive:
					additive_total += multiplier.amount
				else:
					multiplier_total += multiplier.amount
		return clamp_stat(stat, (base_stat + additive_total) * multiplier_total)
	else:
		return 1.0

## Can be added to over time if stats need to be hard capped
func clamp_stat(stat : String, amount : float) -> float:
	if stat in STAT_CLAMPS.keys():
		var stat_min := STAT_CLAMPS[stat].x
		var stat_max := STAT_CLAMPS[stat].y
		if is_equal_approx(stat_min, UNCAPPED_STAT_VAL):
			return minf(amount, stat_max)
		elif is_equal_approx(stat_max, UNCAPPED_STAT_VAL):
			return maxf(amount, stat_min)
		return clamp(amount, stat_min, stat_max)
	return amount

func get_stat_as_percent(stat : String) -> int:
	var stat_as_float := get_stat(stat)
	var stat_as_int : int = roundi(stat_as_float * 100.0)
	return stat_as_int
