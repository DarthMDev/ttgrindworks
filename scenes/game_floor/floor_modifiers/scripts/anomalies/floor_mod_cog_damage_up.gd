extends FloorModifier


const BOOST_AMT := 1.2

const STAT_BOOST_REFERENCE := preload("res://objects/battle/battle_resources/status_effects/resources/status_effect_stat_boost.tres")

func modify_floor() -> void:
	game_floor.s_cog_spawned.connect(
		func(cog: Cog):
			await cog.s_dna_set
			var new_boost = STAT_BOOST_REFERENCE.duplicate()
			new_boost.quality = StatusEffect.EffectQuality.POSITIVE
			new_boost.stat = "damage"
			new_boost.boost = BOOST_AMT
			new_boost.target = cog
			new_boost.rounds = -1
			cog.dna.status_effects.append(new_boost)
			
	)


func get_mod_quality() -> ModType:
	return ModType.NEGATIVE

func get_mod_name() -> String:
	return "Cog Damage up"

func get_mod_icon() -> Texture2D:
	return load("res://ui_assets/battle/statuses/damage.png")

func get_description() -> String:
	return "Cog attack damage increased by 20% "
