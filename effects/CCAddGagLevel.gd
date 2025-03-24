extends CCEffect

class_name CCAddGagLevel

var player = Util.get_player()

# adds a random gag level to the player (basically like unlocking a new track frame)

func _trigger(_instance: CCEffectInstance) -> EffectResult:
    if player == null:
        return FAILURE
    # reward a track frame
    # check if every gag in our loadout is maxxed
    if check_if_all_gags_maxxed():
        return FAILURE
    ItemService.get_track_frame().apply_item(player)

    return SUCCESS

func check_if_all_gags_maxxed() -> bool:
    var gags_unlocked = player.stats.gags_unlocked
    for gag_track in gags_unlocked:
        if gags_unlocked[gag_track] < 7:
            return false
    return true

func _can_run() -> bool:
    if player != null and player.stats.hp > 0:
        return true
    if not check_if_all_gags_maxxed():
        return true
    return false