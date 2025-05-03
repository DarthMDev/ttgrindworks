extends FloorModifier


func modify_floor() -> void:
	BattleService.s_battle_started.connect(on_battle_start)

func on_battle_start(battle : BattleManager) -> void:
	battle.s_status_effect_added.connect(on_status_effect_added)

func on_status_effect_added(effect : StatusEffect) -> void:
	if effect.rounds > 0:
		effect.rounds += 1


func get_mod_name() -> String:
	return "Status Report"

func get_mod_icon() -> Texture2D:
	return load("res://ui_assets/player_ui/pause/status_report_1.png")

func get_description() -> String:
	return "All Status Effects last 1 round longer"

func get_mod_quality() -> ModType:
	return ModType.NEUTRAL
