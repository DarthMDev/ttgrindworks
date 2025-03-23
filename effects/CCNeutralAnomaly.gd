# adds a random neutral anomaly to the floor
# if we dont already have it

extends CCEffect

class_name CCNeutralAnomaly

const ANOMALIES_NEUTRAL: Array[String] = [
	"res://scenes/game_floor/floor_modifiers/scripts/anomalies/floor_mod_marathon.gd",
	"res://scenes/game_floor/floor_modifiers/scripts/anomalies/floor_mod_reorganization.gd",
	"res://scenes/game_floor/floor_modifiers/scripts/anomalies/floor_mod_volatile_market.gd",
]

var player = Util.get_player()

func _trigger(_instance: CCEffectInstance) -> EffectResult:
    randomize()
    # add the anomaly to the floor
    # if we dont already have it 
    # make a new list out of the ones we dont have
    var anomalies = new_anomalies()
    if anomalies.size() == 0:
        return FAILURE
    var anomaly = anomalies[randi() % anomalies.size()]
    Util.floor_manager.add_anomaly(anomaly)
    return SUCCESS

func new_anomalies() -> Array[String]:
    var anomalies = ANOMALIES_NEUTRAL
    if Util.floor_manager.anomalies:
        for anomaly in Util.floor_manager.anomalies:
            if anomalies.has(anomaly):
                anomalies.erase(anomaly)
    return anomalies

func _can_run() -> bool:
    if player != null and player.stats.hp > 0:
        return true
    if new_anomalies().size() > 0:
        return true
    return false