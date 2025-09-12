extends FloorModifier

const gag_status = preload("res://objects/battle/battle_resources/status_effects/resources/status_effect_gag_immunity.tres")

func modify_floor() -> void:
	game_floor.s_cog_spawned.connect(
		func(cog: Cog):
			await cog.s_dna_set
			var loadout: Array[Track] = Util.get_player().stats.character.gag_loadout.loadout
			var gag_immunity = gag_status.duplicate()
			gag_immunity.rounds = -1
			gag_immunity.target = cog
			gag_immunity.set_track(loadout[RandomService.randi_channel('true_random') % loadout.size()])
			cog.dna.status_effects.append(gag_immunity)
	)


func get_mod_quality() -> ModType:
	return ModType.NEGATIVE

func get_mod_name() -> String:
	return "Gag immunities"

func get_mod_icon() -> Texture2D:
	return load("res://ui_assets/battle/statuses/track_immunity.png")

func get_description() -> String:
	return "All cogs gain an immunity to a gag track"
