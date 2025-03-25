extends CCEffect

class_name CCDOTEffect

var player = Util.get_player()
var manager: BattleManager
const CROWD_CONTROL_BURN = preload("res://objects/battle/battle_resources/status_effects/resources/crowd_control_burn.tres")
 
# applies a damage over time effect only if the player is in battle

func _trigger(_instance: CCEffectInstance) -> EffectResult:
    manager.add_status_effect(CROWD_CONTROL_BURN)
    return SUCCESS

func _can_run() -> bool:
    if player != null and player.stats.hp > 0:
        return true
    if BattleService.ongoing_battle:
        return true
    return false