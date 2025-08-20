
@tool
extends StatusEffect

var above = true
var hp_requirement = 0
var cog: Cog
var turns = 0
var lower_hp = true
var lower_hp_chance = 0.7
var boosts = 0
var max_boosts = 2
var unstable = false

func apply() -> void:
	cog = target
	hp_requirement = cog.stats.max_hp
	above = false
	description = "This foreman's health must be above %d" % hp_requirement
	
	
func renew() -> void:
	if(!(check_requirements())):
		print("bleh")
		print("okay so requirement failed: ")
		if above:
			print("checking requiremint is ", target.stats.hp, "  wasnt greater than: ", hp_requirement )
			print(target.stats.hp > hp_requirement)
		else:
			print("checking requiremint is ", target.stats.hp, " wasnt less than: ", hp_requirement )
			print(target.stats.hp < hp_requirement)
		var attack = load('res://objects/battle/battle_resources/cog_attacks/resources/heckle.tres').duplicate()
		attack.summary = "The Foreman is Disappointed"
		attack.action_name = "Disappointment"
		attack.user = target
		attack.accuracy = 200
		attack.targets = [Util.get_player()]
		manager.round_end_actions.append(attack)
		if boosts <= max_boosts:
			target.stats.max_hp *= 1.33
			target.stats.hp *= 1.33
			boosts+= 1
	get_requirement()
	
func check_requirements() -> bool:
	if above:
		print("checking requiremint is ", target.stats.hp, " greater than: ", hp_requirement )
		print(target.stats.hp > hp_requirement)
		return target.stats.hp > hp_requirement
	else:
		print("checking requiremint is ", target.stats.hp, " less than: ", hp_requirement )
		print(target.stats.hp < hp_requirement)
		return target.stats.hp < hp_requirement
		
func get_icon() -> Texture2D:
	return load("res://models/cogs/misc/hp_light/cog_light.png") #change the icon color red maybe soon

func get_status_name() -> String:
	return "Ohmmeter"

func get_requirement() -> void:
	var mult
	if manager.cogs.size() <= 1:
		above = false
		mult = RandomService.randf_range_channel('true_random', 0.5, 0.8)
		hp_requirement = target.stats.hp * mult
	else:
		var roll: float = RandomService.randf_channel('true_random')
		lower_hp = roll < lower_hp_chance
	if lower_hp:
		above = false
		mult = RandomService.randf_range_channel('true_random', 0.75, 0.92)
		hp_requirement = target.stats.hp * mult
	else:
		above = true
		mult = RandomService.randf_range_channel('true_random', 0.97, 0.99)
		hp_requirement = target.stats.hp * mult
	if above:
		description = "This foreman's health must be above %d" % hp_requirement
	else: description = "This foreman's health must be below %d" % hp_requirement


	
