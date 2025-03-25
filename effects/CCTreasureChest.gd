extends CCEffect

class_name CCTreasureChest

const TREASURE_POOL := preload("res://objects/items/pools/doodle_treasure.tres")
const SFX_TREASURE := preload('res://audio/sfx/doodle/treasure_digup.ogg')
# spawns a treasure chest that the player can interact with, similar to doodle


func _trigger(_instance: CCEffectInstance) -> EffectResult:
	# similar to doodle treasure, we spawn a treasure chest
	var player = Util.get_player() 
	var treasure_chest := load("res://objects/interactables/treasure_chest/treasure_chest.tscn")
	var chest = treasure_chest.instantiate()
	if is_instance_valid(Util.floor_manager):
		Util.floor_manager.get_current_room().add_child(chest)
	elif is_instance_valid(SceneLoader.current_scene):
		SceneLoader.current_scene.add_child(chest)
	chest.global_position = player.global_position - Vector3(0, 0, 2)
	# play the treasure sound
	AudioManager.play_sound(SFX_TREASURE)
	chest.item_pool = TREASURE_POOL
	
	return SUCCESS

func _can_run() -> bool:
	var player = Util.get_player() 
	if player != null and player.stats.hp > 0:
		return true
	# check the scene is valid 
	if is_instance_valid(Util.floor_manager):
		return is_instance_valid(Util.floor_manager.get_current_room())
	elif is_instance_valid(SceneLoader.current_scene):
		return true
	return false
	
