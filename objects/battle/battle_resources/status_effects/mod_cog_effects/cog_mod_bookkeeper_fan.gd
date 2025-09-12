@tool
extends StatusEffect

var player: Player
var last_player_hp
var debuff_stat = 'damage'
var debuff_stat_index = 0
var cook_cooldown = 0
var mental_math_cooldown = 0
const STAT_BOOST := preload("res://objects/battle/battle_resources/status_effects/resources/status_effect_stat_boost.tres")
var unstable = false

const BoostNums := {
	'damage': 0.75,
	'defense': 0.8,
	'luck': 0.7,
}
func apply() -> void:
	var cog: Cog = target
	player  = Util.get_player()
	player.stats.hp_changed.connect(on_toon_heal)
	manager.s_action_started.connect(on_action_started)
	last_player_hp = player.stats.hp

func on_toon_heal(health : int) -> void:
	if(health < last_player_hp and health != last_player_hp):
		if player.last_damage_source == "Bookkeeper Fan":
			await manager.sleep(0.26)
			manager.battle_text(player, "%s Down!" % (debuff_stat), BattleText.colors.orange[0], BattleText.colors.orange[1])
		var hp_ratio = float(health - last_player_hp) / player.stats.max_hp
		
	last_player_hp = health
	
func on_action_started(action: BattleAction) -> void:
	if action is CogAttack and action.target_type != BattleAction.ActionTarget.SELF:
		if action.user == target and action.action_name != "" and action.action_name != "Mental Math" and action.action_name != "Snipe":
			#action.custom_player_death_source = "Whistleblower Fan"
			player.last_damage_source = "Bookkeeper Fan"
			apply_status_effect()
func renew() -> void:
	if target.stats.hp > target.stats.max_hp * 1.5:
		cook_the_books()
	if target.stats.hp < target.stats.max_hp * 0.7:
		mental_math()
	cook_cooldown -= 1
	mental_math_cooldown -= 1

func cleanup() -> void:
	player.stats.hp_changed.disconnect(on_toon_heal)
	if manager.s_action_started.is_connected(on_action_started):
		manager.s_action_started.disconnect(on_action_started)

func get_status_name() -> String:
	return "Bookkeeper Fan"

func get_icon() -> Texture2D:
	return load("res://ui_assets/battle/statuses/bookkeeper_fan.png")

func apply_status_effect() -> void:
	var new_debuff := STAT_BOOST.duplicate()
	new_debuff.target = player
	new_debuff.rounds = 1
	new_debuff.quality = StatusEffect.EffectQuality.NEGATIVE
	new_debuff.stat = BoostNums.keys()[debuff_stat_index % 3]
	debuff_stat = new_debuff.stat
	debuff_stat_index += 1
	new_debuff.boost = BoostNums[new_debuff.stat]
	manager.add_status_effect(new_debuff)

func cook_the_books() -> void:
	if cook_cooldown > 0:
		return
	var cooked := load("res://objects/battle/battle_resources/misc_movies/bookkeeper/bk_cook_the_books.tres").duplicate()
	cooked.targets = [Util.get_player()]
	cooked.user = target
	manager.round_end_actions.append(cooked)
	cook_cooldown = 3

func mental_math() -> void:
	if mental_math_cooldown > 0:
		return
	var mm := load("res://objects/battle/battle_resources/misc_movies/bookkeeper/bk_mental_math.tres").duplicate()
	mm.user = target
	manager.round_end_actions.append(mm)
	mental_math_cooldown = 4

func expire() -> void:
	manager.s_action_started.disconnect(on_action_started)
