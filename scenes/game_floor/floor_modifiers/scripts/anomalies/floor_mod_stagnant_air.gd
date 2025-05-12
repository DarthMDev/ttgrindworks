extends FloorModifier

const NERF_AMT_PLAYER := -0.25
const NERF_AMT_COGS := 0.75

var status_effect: StatBoost:
	get: return GameLoader.load("res://objects/battle/battle_resources/status_effects/resources/status_effect_stat_boost.tres").duplicate()

func modify_floor() -> void:
	var player := Util.get_player()
	player.stats.defense += NERF_AMT_PLAYER
	game_floor.s_cog_spawned.connect(on_cog_spawned)

func clean_up() -> void:
	var player := Util.get_player()
	player.stats.defense -= NERF_AMT_PLAYER
	game_floor.s_cog_spawned.disconnect(on_cog_spawned)

func on_cog_spawned(cog: Cog) -> void:
	cog.s_dna_set.connect(on_dna_set.bind(cog))

func on_dna_set(cog: Cog) -> void:
	var effect := status_effect
	effect.boost = NERF_AMT_COGS
	effect.rounds = -1
	effect.quality = StatusEffect.EffectQuality.NEGATIVE
	effect.stat = 'defense'
	cog.dna.status_effects.append(effect)
	pass

func get_mod_name() -> String:
	return "Dramaturgy"

func get_mod_icon() -> Texture2D:
	return load("res://ui_assets/player_ui/pause/dramaturgy.png")

func get_description() -> String:
	return "Everyone receives -25% Defense"
