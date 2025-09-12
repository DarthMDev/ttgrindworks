extends FloorModifier

const green_light_effect := preload("res://objects/battle/battle_resources/misc_movies/traffic_manager/toon_green_light.tres")

func modify_floor() -> void:
	BattleService.s_battle_started.connect(on_battle_started)

func on_battle_started(manager: BattleManager):
	var new_boost = green_light_effect.duplicate()
	new_boost.quality = StatusEffect.EffectQuality.NEGATIVE
	new_boost.target = Util.get_player()
	new_boost.rounds = -1
	manager.add_status_effect(new_boost)

func get_mod_quality() -> ModType:
	return ModType.NEGATIVE

func get_mod_name() -> String:
	return "Essence of The Traffic Manager"

func clean_up() -> void:
	BattleService.s_battle_ended.disconnect(on_battle_started)
	pass

func get_mod_icon() -> Texture2D:
	return load("res://ui_assets/battle/statuses/green_light.png")

func get_description() -> String:
	return "Gag mandate every round"
