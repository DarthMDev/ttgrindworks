extends FloorModifier

var multiplier := StatMultiplier.new()

func modify_floor() -> void:
	var player := Util.get_player()
	
	multiplier.stat = "damage"
	multiplier.additive = true
	multiplier.amount = 0.0
	
	player.stats.multipliers.append(multiplier)
	BattleService.s_round_ended.connect(on_round_ended)
	BattleService.s_battle_ended.connect(on_battle_ended)
	BattleService.s_battle_started.connect(on_round_ended)
	on_round_ended()

func on_round_ended(_manager: BattleManager = null) -> void:
	var random_multiplier := randf_range(-0.25, 0.25)
	multiplier.amount = random_multiplier

func on_battle_ended() -> void:
	multiplier.amount = 0.0

func clean_up() -> void:
	var player := Util.get_player()
	if player and multiplier in player.stats.multipliers:
		player.stats.multipliers.erase(multiplier)

func get_mod_name() -> String:
	return "Silly Waves"

func get_mod_quality() -> ModType:
	return ModType.NEUTRAL

func get_mod_icon() -> Texture2D:
	return load("res://ui_assets/player_ui/pause/silly_waves.png")

func get_description() -> String:
	return "Your gag damage varies every round"
