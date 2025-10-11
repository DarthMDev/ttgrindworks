extends FloorModifier

const CRIT_CHANCE := 1.0 / 7.0

func modify_floor() -> void:
	BattleService.s_action_started.connect(on_action_started)

func clean_up() -> void:
	BattleService.s_action_started.disconnect(on_action_started)

func on_action_started(action: BattleAction) -> void:
	if action is CogAttack and randf() < CRIT_CHANCE:
		action.crit_chance_mod = Globals.CRIT_MOD_GUARANTEE

func get_mod_name() -> String:
	return "Bad Luck"

func get_mod_icon() -> Texture2D:
	return load("res://ui_assets/player_ui/pause/broken_mirror.png")

func get_description() -> String:
	return "Cogs gain the ability to crit"

func get_mod_quality() -> ModType:
	return ModType.NEGATIVE
