extends 'res://objects/items/custom/seed_logic/custom_seed_base.gd'

var def_mult: StatMultiplier
var eva_mult: StatMultiplier

func setup() -> void:
	def_mult =  StatMultiplier.new()
	def_mult.stat = 'defense'
	def_mult.amount = -0.5
	
	eva_mult = StatMultiplier.new()
	eva_mult.stat = 'evasiveness'
	eva_mult.amount = 2.0
	
	Util.get_player().stats.multipliers.append_array([def_mult, eva_mult])
