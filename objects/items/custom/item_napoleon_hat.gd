extends ItemScript


const BOOST_RANGE := Vector2(0.9, 1.3)
const HEIGHT_RANGE := Vector2(2.5, 8.0)


func on_collect(_item: Item, _model: Node3D) -> void:
	setup()
 
func on_load(_item: Item) -> void:
	setup()

func setup() -> void:
	BattleService.s_action_started.connect(on_action_start)

func on_action_start(action: BattleAction) -> void:
	if action is ToonAttack:
		for target in action.targets:
			if target is Cog:
				boost_gag(action)

func boost_gag(action: ToonAttack) -> void:
	var scale_average := 0.0
	var cog_count := 0
	for target in action.targets:
		if target is Cog:
			scale_average += target.dna.scale
			cog_count += 1
	scale_average /= maxf(cog_count, 1.0)
	var height_from_zero := HEIGHT_RANGE.y - HEIGHT_RANGE.x
	var adjusted_height := clampf(scale_average - HEIGHT_RANGE.x, 0.1, height_from_zero)
	var ratio := adjusted_height / height_from_zero
	var boost := BOOST_RANGE.x + ((BOOST_RANGE.y - BOOST_RANGE.x) * ratio)
	action.damage = roundi(float(action.damage) * boost)
