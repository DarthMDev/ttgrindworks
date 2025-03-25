# add a random negative anomaly to the floor
# if we dont already have it

extends CCEffect

class_name CCNegativeAnomaly

const ANOMALIES_NEGATIVE: Array[String] = [
	"res://scenes/game_floor/floor_modifiers/scripts/anomalies/floor_mod_level_up.gd",
	"res://scenes/game_floor/floor_modifiers/scripts/anomalies/floor_mod_out_of_touch.gd",
]


func _trigger(_instance: CCEffectInstance) -> EffectResult:
    randomize()
    # add the anomaly to the floor
    # if we dont already have it 
    # make a new list out of the ones we dont have
    var anomalies = new_anomalies()
    var anomaly = anomalies[randi() % anomalies.size()]
    Util.floor_manager.add_anomaly(anomaly)
    return SUCCESS

func new_anomalies() -> Array[String]:
    var anomalies = ANOMALIES_NEGATIVE
    if Util.floor_manager.anomalies:
        for anomaly in Util.floor_manager.anomalies:
            if anomalies.has(anomaly):
                anomalies.erase(anomaly)
    return anomalies

func _can_run() -> bool:
    var player = Util.get_player()
    if player != null and player.stats.hp > 0:
        return true
    if new_anomalies().size() > 0:
        return true
    return false