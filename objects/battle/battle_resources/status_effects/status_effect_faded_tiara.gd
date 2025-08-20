@tool
extends StatusEffect
class_name TiaraRegeneration

var charges = 1
var max_charges = 2
signal s_gag_modified(indexes: Dictionary)  # New signal
var player: Player
var total_healed = 0
var heal_amounts: Dictionary = {
	5: 0.25,
	4: 0.16,
	3: 0.12,
	2: 0.09,
	1: 0.05
	}

func apply() -> void:
	manager.s_gags_chosen.connect(on_gags_chosen)
	manager.s_participant_died.connect(participant_died)
	var cog_amount = manager.cogs.size()
	var heal_percent = heal_amounts.get(cog_amount, 0.0) * 100
	if heal_percent == int(heal_percent):
		description = "Heal %d%% of laff for every idle turn" % heal_percent
	else:
		description = "Heal %.1f%% of laff for every idle turn" % heal_percent
	player = target


func on_gags_chosen(actions: Array[ToonAttack]) -> void:
	if target.stats.hp >= target.stats.max_hp:
		return
	var skipped_turns = player.stats.turns - actions.size() 
	if charges > 0 and skipped_turns > 0:
		var cogs = manager.cogs.size()
		var heal_amount = heal_amounts.get(cogs, 0.16) * skipped_turns * target.stats.max_hp
		print("tiara heal: ", roundi(heal_amount), ",  ",  heal_amounts.get(cogs, 0.16))
		manager.affect_target(target, heal_amount * -1)
		total_healed += roundi(heal_amount * target.stats.get_stat("healing_effectiveness"))
		Globals.healed_from_faded_tiara += (heal_amount *  target.stats.get_stat("healing_effectiveness"))
		print("what we addeding to tiara heal: ", roundi(heal_amount * target.stats.get_stat("healing_effectiveness")))
		print(Globals.healed_from_faded_tiara)
		print("using charge")
		charges-= 1
func participant_died(who: Node3D) -> void:
	if who is Cog:
		if charges < max_charges:
			charges+= 1	
func renew() -> void:
	if charges < 1:
		description = "0 charges! Defeat a cog to recharge the faded tiara!"
		icon_color = Color.CHOCOLATE
	else: 
		var cog_amount = manager.cogs.size()
		icon_color = Color(1, 1, 1, 1)
		var heal_percent = heal_amounts.get(cog_amount, 0.0) * 100
		# Format to show as integer percentage if it's a whole number, otherwise show 1 decimal
		if heal_percent == int(heal_percent):
			description = "Heal %d%% of laff for every idle turn" % heal_percent
		else:
			description = "Heal %.1f%% of laff for every idle turn" % heal_percent
	
	
func cleanup() -> void:
	manager.s_gags_chosen.disconnect(on_gags_chosen)

func get_status_name() -> String:
	return "Faded Tiara"

func get_icon() -> Texture2D:
	return load("res://models/accessories/hats/faded_tiara/faded_tiara_view.png")
