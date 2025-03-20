extends CCEffect

class_name CCTreasureChest

const TREASURE_POOL := preload("res://objects/items/pools/doodle_treasure.tres")
const SFX_TREASURE := preload('res://audio/sfx/doodle/treasure_digup.ogg')
const TREASURE_CHEST := "res://objects/interactables/treasure_chest/treasure_chest.tscn"
var player = Util.get_player() 
# spawns a treasure chest that the player can interact with, similar to doodle


func _trigger(_instance: CCEffectInstance) -> EffectResult:
    if player == null:
        return FAILURE
    # similar to doodle treasure, we spawn a treasure chest
    var chest = load(TREASURE_CHEST).instantiate()
    if is_instance_valid(Util.floor_manager):
        Util.floor_manager.get_current_room().add_child(chest)
    elif is_instance_valid(SceneLoader.current_scene):
        SceneLoader.current_scene.add_child(chest)
    else:
        return FAILURE
    chest.global_rotation_degrees.y = player.global_rotation_degrees.y - 180.0
    chest.global_transform.origin = player.global_transform.origin + player.global_transform.basis.z * 5
    # play the treasure sound
    SFX_TREASURE.play()
    chest.item_pool = TREASURE_POOL
    
    return SUCCESS

func _can_run() -> bool:
    if player != null and player.stats.hp > 0:
        return true
    # check the scene is valid 
    if is_instance_valid(Util.floor_manager):
        return is_instance_valid(Util.floor_manager.get_current_room())
    elif is_instance_valid(SceneLoader.current_scene):
        return true
    return false
    