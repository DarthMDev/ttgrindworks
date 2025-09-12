@tool
extends StatusEffect

var player: Player
var last_player_hp
var heal_multiplier = 2.5
var max_hp_boosted = 0
func apply() -> void:
	var cog: Cog = target
	player  = Util.get_player()
	player.stats.hp_changed.connect(on_toon_heal)
	last_player_hp = player.stats.hp
	target.stats.is_foreman = true

func on_toon_heal(health : int) -> void:
	if(health > last_player_hp):
		var hp_ratio = float(health - last_player_hp) / player.stats.max_hp
		if target.stats.hp > 0:
			if Util.final_boss: boss_rebalance()
			target.stats.hp = target.stats.hp + (max(target.stats.max_hp, target.stats.hp) * (hp_ratio * heal_multiplier))

	last_player_hp = health
	

func cleanup() -> void:
	player.stats.hp_changed.disconnect(on_toon_heal)

func get_status_name() -> String:
	return "Beneficiary"

func get_icon() -> Texture2D:
	return load("res://ui_assets/battle/statuses/green_plus.png")

func boss_rebalance() -> void:
	if target.stats.max_hp * 2.5 < target.stats.hp:
		if max_hp_boosted < 4:
			target.stats.max_hp = ceili(target.stats.max_hp * 1.33)
			max_hp_boosted+= 1
