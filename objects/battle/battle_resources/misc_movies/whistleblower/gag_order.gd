extends CogAttack

const STATUS_EFFECT := preload("res://objects/battle/battle_resources/status_effects/resources/status_effect_gag_order.tres")

var gags : Array[ToonAttack] = []


func action() -> void:
	var cog : Cog = user
	
	var movie := manager.create_tween()
	movie.tween_callback(battle_node.focus_character.bind(cog))
	movie.tween_interval(2.0)
	movie.tween_callback(apply_status)
	
	await movie.finished
	movie.kill()

func apply_status() -> void:
	var new_effect := STATUS_EFFECT.duplicate(true)
	new_effect.target = targets[0]
	new_effect.gags = gags
	manager.add_status_effect(new_effect)
