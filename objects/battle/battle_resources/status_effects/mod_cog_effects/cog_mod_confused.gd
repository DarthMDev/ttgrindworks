
@tool
extends StatusEffect

var life_insurance = preload("res://objects/battle/battle_resources/status_effects/mod_cog_effects/mog_cog_life_insurance.tres")
var reorganization = preload("res://objects/battle/battle_resources/status_effects/resources/status_effect_reorganized.tres")
var loadout : GagLoadout
var cog: Cog
var unstable = false

func apply() -> void:
	cog = target
	var insurance_effect = life_insurance.duplicate()
	insurance_effect.target = target
	if unstable:
		insurance_effect.rounds = 0
	var reorg_effect = reorganization.duplicate()
	reorg_effect.target = Util.get_player()
	manager.add_status_effect(insurance_effect)
	manager.add_status_effect(reorg_effect)
	
func renew() -> void:
	var player := Util.get_player()
	
	if not player:
		return
	RandomService.array_shuffle_channel('anomaly_reorg',player.stats.character.gag_loadout.loadout)

	

func get_icon() -> Texture2D:
	return load("res://ui_assets/misc/PetEmoteConfused2.png") #change the icon color red

func get_status_name() -> String:
	return "Confused"
