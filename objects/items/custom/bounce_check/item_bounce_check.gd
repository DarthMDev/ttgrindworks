extends ItemScriptActive

const EARN_SFX := preload("res://audio/sfx/ui/tick_counter.ogg")
const STAT_BOOST := preload('res://objects/battle/battle_resources/status_effects/resources/status_effect_stat_boost.tres')
const BEAN_STAT := preload("res://objects/battle/battle_resources/status_effects/resources/status_effect_payraise.tres")
const SFX := preload("res://audio/sfx/items/cash_register.ogg")

const responses = [
	"Looks like payday came early.",
	"Overtime is finally paying off.",
	"A well deserved raise.",
	"I'm going to purchase a new stapler.",
	"Your hubris will be your downfall, Toon.",
	"Wrong choice, Toon."
]

var targetCogs : Array[Cog]
var beans_per_cog = 7.0

func use() -> void:
	if not is_instance_valid(BattleService.ongoing_battle):
		cancel_use()
		return
	
	AudioManager.play_sound(SFX)
	
	targetCogs = BattleService.ongoing_battle.cogs
	
	var hp_boost = 1.0 / len(targetCogs)
	var damage_boost = 0.5 / len(targetCogs)
	
	for cog in targetCogs:
		@warning_ignore("narrowing_conversion")
		cog.stats.max_hp *= 1.0 + hp_boost
		@warning_ignore("narrowing_conversion")
		cog.stats.hp *= 1.0 + hp_boost
		
		var bean_return := BEAN_STAT.duplicate()
		bean_return.quality = StatusEffect.EffectQuality.POSITIVE
		bean_return.just_applied = false
		bean_return.bean_count = ceili(beans_per_cog * (float(cog.stats.hp) / cog.stats.max_hp))
		bean_return.target = cog
		
		var dmg_boost = STAT_BOOST.duplicate()
		dmg_boost.quality = StatusEffect.EffectQuality.POSITIVE
		dmg_boost.boost = 1.0 + damage_boost
		dmg_boost.stat = 'damage'
		dmg_boost.target = cog
		dmg_boost.rounds = -1
		
		BattleService.ongoing_battle.add_status_effect(bean_return)
		BattleService.ongoing_battle.add_status_effect(dmg_boost)
	
	BattleService.ongoing_battle.battle_ui.cog_panels.reset(0)
	await cutscene()
	
	
	BattleService.ongoing_battle.battle_ui.cog_panels.assign_cogs(targetCogs)

# Avert your eyes don't look at this please
func cutscene() -> void:
	var battle := BattleService.ongoing_battle
	
	if is_instance_valid(battle.battle_ui.timer):
		battle.battle_ui.timer.timer.set_paused(true)
		
	battle.battle_ui.visible = false
	Util.get_player().toon.hide()
	
	battle.battle_node.focus_cogs()
	battle.battle_node.battle_cam.position.z += 3.0
	
	for cog in targetCogs:
		cog.set_animation(RandomService.array_pick_random('true_random', ['clap', 'buffed']))
		cog.speak(RandomService.array_pick_random('true_random', responses))
	
	var txt = Util.do_3d_text(BattleService.ongoing_battle.battle_node, "Damage Up!", BattleText.colors.orange[0], BattleText.colors.orange[1])
	
	await battle.sleep(0.5)
	
	var txt2 = Util.do_3d_text(BattleService.ongoing_battle.battle_node, "Health Up!", BattleText.colors.orange[0], BattleText.colors.orange[1])
	
	await battle.sleep(2.0)
	battle.battle_ui.visible = true
	Util.get_player().toon.show()
	battle.battle_node.focus_character(battle.battle_node)
	
	if is_instance_valid(battle.battle_ui.timer):
		battle.battle_ui.timer.timer.set_paused(false)
