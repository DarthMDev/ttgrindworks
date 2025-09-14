extends ItemSpirit

@export var mult_stat := 'damage'
@export var mult_factor := 1.0
@export var mult_additive := false

const PROXY_EFFECT := preload('res://objects/battle/battle_resources/status_effects/resources/status_effect_mod_cog.tres')
var multiplier : StatMultiplier

func on_collect(_item: Item, _object: Node3D) -> void:
	setup()

func on_load(_item: Item) -> void:
	setup()

func setup() -> void:
	create_multiplier()
	Util.s_floor_started.connect(floor_started)
	BattleService.s_battle_started.connect(give_proxy_abilities)
	# hardcoded for now, sorgy
	if !spirit_purified:
		Util.get_player().stats.can_get_specific_cog_quests = false
		
func purify() -> void:
	super()
	Util.get_player().stats.can_get_specific_cog_quests = true
	
func floor_started(floor: GameFloor) -> void:
	connect_impure_function(transform_cog, floor.s_cog_spawned)

func transform_cog(cog: Cog) -> void:
	cog.use_floor_pool = false
	cog.use_mod_cogs_pool = true
	print("Spirit of Warriors: Transforming " + cog.name + " to proxy")

func give_proxy_abilities(battle: BattleManager):
	for cog in battle.cogs:
		if cog.dna.is_mod_cog:
			print("Spirit of Warriors: Adding proxy abiliity")
			var ability := PROXY_EFFECT.duplicate()
			ability.target = cog
			battle.add_status_effect(ability)

func create_multiplier() -> void:
	multiplier = StatMultiplier.new()
	multiplier.stat = mult_stat
	multiplier.amount = mult_factor
	multiplier.additive = mult_additive
	Util.get_player().stats.multipliers.append(multiplier)
