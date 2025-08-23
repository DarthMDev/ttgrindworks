
@tool
extends StatusEffect


var mark_amount = 1
var player: Player

var cog: Cog

func apply() -> void:
	cog = target
	player = Util.get_player()
	if Util.final_boss2:
		var attack = load('res://objects/battle/battle_resources/cog_attacks/debuff_wag.gd').duplicate()
		attack.damage = Util.get_player().stats.max_hp * (mark_amount * 0.1)
		attack.summary = "Foreman's Mark"
		attack.mark = true
		attack.marks = mark_amount
		attack.user = target
		attack.targets = [Util.get_player()]
		attack.ignore_stats = true
		manager.append_action(attack)
	
	
func renew() -> void:
	print("IS THIS EVEN LOADING?")
	var attack = load('res://objects/battle/battle_resources/cog_attacks/resources/debuff_wag.tres').duplicate()
	attack.damage = Util.get_player().stats.max_hp * (mark_amount * 0.1)
	attack.summary = "Foreman's Mark"
	attack.mark = true
	attack.marks = mark_amount
	attack.user = target
	attack.targets = [Util.get_player()]
	attack.ignore_stats = true
	attack.action_name = "Mark of the Foreman"
	manager.round_end_actions.append(attack)
	mark_amount+= 1
	description = "At the end of round will attack and mark dealing %d%% of max laff in damage" % (mark_amount * 10)
	

func get_icon() -> Texture2D:
	return load("res://ui_assets/battle/statuses/Relentless.png")

func get_status_name() -> String:
	return "Relentless"
