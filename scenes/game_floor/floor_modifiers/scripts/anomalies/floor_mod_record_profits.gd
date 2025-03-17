extends FloorModifier

const REWARD_AMOUNT := 2
const EARN_SFX := preload("res://audio/sfx/ui/tick_counter.ogg")

## Gives player jellybeans for every Cog defeated
func modify_floor() -> void:
	BattleService.s_battle_started.connect(on_battle_start)

func on_battle_start(battle : BattleManager) -> void:
	battle.s_participant_died.connect(battle_participant_dying)

func battle_participant_dying(participant : Node3D) -> void:
	if participant is Cog and Util.get_player():
		Util.get_player().stats.add_money(RandomService.randi_channel('true_random') % REWARD_AMOUNT)
		AudioManager.play_sound(EARN_SFX)

func get_mod_name() -> String:
	return "Record Profits"

func get_mod_quality() -> ModType:
	return ModType.POSITIVE

func get_mod_icon() -> Texture2D:
	return load("res://ui_assets/player_ui/pause/RecordProfits.png")

func get_description() -> String:
	return "Destroyed Cogs may drop jellybeans"
