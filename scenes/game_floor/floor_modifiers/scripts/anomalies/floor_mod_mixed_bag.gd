extends FloorModifier

const RANDOM_EFFECTS : Array[StatusEffect] =[
	preload("res://objects/battle/battle_resources/status_effects/resources/status_effect_stat_boost.tres"),
	preload("res://objects/battle/battle_resources/status_effects/resources/status_effect_poison.tres"),
	preload("res://objects/battle/battle_resources/status_effects/resources/status_effect_aftershock.tres"),
	preload("res://objects/battle/battle_resources/status_effects/resources/status_effect_drenched.tres"),
	preload("res://objects/battle/battle_resources/status_effects/resources/status_effect_regeneration.tres"),
	preload("res://objects/battle/battle_resources/status_effects/resources/status_effect_gag_immunity.tres"),
]

var cog_hps : Dictionary[Cog, int] = {}

func modify_floor() -> void:
	BattleService.s_battle_started.connect(on_battle_start)

func on_battle_start(battle : BattleManager) -> void:
	for cog in battle.cogs:
		hookup_cog(cog)
	battle.s_participant_joined.connect(func(participant): if participant is Cog: hookup_cog(participant))
	battle.s_status_effect_added.connect(on_status_effect_added)

func hookup_cog(cog : Cog) -> void:
	cog_hps[cog] = cog.stats.hp
	cog.stats.hp_changed.connect(cog_hp_changed.bind(cog))

func cog_hp_changed(hp : int, cog : Cog) -> void:
	if cog in cog_hps.keys() and is_instance_valid(BattleService.ongoing_battle):
		if cog_hps[cog] > hp and cog in BattleService.ongoing_battle.cogs:
			if BattleService.ongoing_battle.current_action is ToonAttack:
				apply_random_effect(cog)

func apply_random_effect(cog : Cog) -> void:
	var effect : StatusEffect = RandomService.array_pick_random('true_random', RANDOM_EFFECTS).duplicate()
	effect.target = cog
	effect.randomize_effect()
	if effect is StatBoost:
		tweak_stat_boost(effect)
	if effect is StatEffectRegeneration:
		effect.instant_effect = false
	await Util.s_process_frame
	BattleService.ongoing_battle.add_status_effect(effect)

func tweak_stat_boost(effect : StatBoost) -> void:
	var valid_effects := ["defense", "damage"]
	if effect.stat not in valid_effects:
		effect.stat = RandomService.array_pick_random('true_random', valid_effects)

func on_status_effect_added(effect : StatusEffect) -> void:
	if effect is StatusLured:
		apply_random_effect(effect.target)

func get_mod_name() -> String:
	return "Mixed Bag"

func get_mod_icon() -> Texture2D:
	return load("res://ui_assets/player_ui/pause/mixed_bag.png")

func get_description() -> String:
	return "Gags apply random status effects to Cogs"

func get_mod_quality() -> ModType:
	return ModType.NEUTRAL
