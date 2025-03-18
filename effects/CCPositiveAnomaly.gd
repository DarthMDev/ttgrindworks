extends CCEffect

class_name CCPositiveAnomaly
const ANOMALIES_POSITIVE: Array[String] = [
	"res://scenes/game_floor/floor_modifiers/scripts/anomalies/floor_mod_overheal.gd",
	"res://scenes/game_floor/floor_modifiers/scripts/anomalies/floor_mod_record_profits.gd",
	"res://scenes/game_floor/floor_modifiers/scripts/anomalies/floor_mod_organic_gags.gd",
]
const ANOMALIES_NEUTRAL: Array[String] = [
	"res://scenes/game_floor/floor_modifiers/scripts/anomalies/floor_mod_marathon.gd",
	"res://scenes/game_floor/floor_modifiers/scripts/anomalies/floor_mod_reorganization.gd",
	"res://scenes/game_floor/floor_modifiers/scripts/anomalies/floor_mod_volatile_market.gd",
]
const ANOMALIES_NEGATIVE: Array[String] = [
	"res://scenes/game_floor/floor_modifiers/scripts/anomalies/floor_mod_level_up.gd",
	"res://scenes/game_floor/floor_modifiers/scripts/anomalies/floor_mod_out_of_touch.gd",
]

func _trigger(_instance: CCEffectInstance) -> EffectResult:
	randomize()
	# add the anomaly to the floor
	
	return SUCCESS

func _can_run() -> bool:
	return Util.get_player() != null
