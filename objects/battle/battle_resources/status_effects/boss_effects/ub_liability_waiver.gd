@tool
extends StatusEffect
class_name UBLiabilityWaiverEffect

@export var damage_redirected: float = 0.3
@export var levels_gained: int = 3

var response_lines: Array[String] = [
	"This won't be good for my health.",
	"I suppose it's worth the promotion."
]

var union_buster: Cog

func apply() -> void:
	var battle_node := manager.battle_node
	var movie := manager.create_tween()
	
	var dialogue_choice: String = response_lines[randi()%response_lines.size()]
	
	BattleService.s_toon_dealt_damage.connect(redirect_damage)
	target.set_new_level(target.level + levels_gained)
	movie.tween_callback(battle_node.focus_character.bind(target))
	movie.tween_callback(target.speak.bind(dialogue_choice))
	movie.tween_callback(manager.battle_text.bind(target, "+%s Levels" % levels_gained, BattleText.colors.green[0], BattleText.colors.green[1]))
	await movie.finished
	movie.kill()

func cleanup() -> void:
	if BattleService.s_toon_dealt_damage.is_connected(redirect_damage):
		BattleService.s_toon_dealt_damage.disconnect(redirect_damage)

func redirect_damage(_action: BattleAction, cog: Node3D, amount: int):
	if amount < 0 or cog != union_buster:
		return
	if (not is_instance_valid(target)) or target.stats.hp <= 0:
		return
	
	manager.affect_target(target, amount * damage_redirected)
	target.set_animation("pie-small")
	await manager.barrier(target.animator.animation_finished, 4.0)
	await manager.check_pulses([target])
