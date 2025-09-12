extends FloorModifier
const COG_OBJECT := preload('res://objects/cog/cog.tscn')

func modify_floor() -> void:
	BattleService.s_battle_spawned.connect(on_battle_spawned)

func on_battle_spawned(battle: BattleNode) -> void:
	for i in range(7):
		var new_cog := COG_OBJECT.instantiate()
		new_cog.position.x += battle.cogs[battle.cogs.size() - 1].position.x + battle.COG_DISTANCE
		battle.cogs.append(new_cog)
		battle.add_child(new_cog)

 
