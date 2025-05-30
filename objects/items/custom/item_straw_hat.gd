extends ItemScript

const PROXY_BOOST := 1.3


func on_collect(_item: Item, _model: Node3D) -> void:
	setup()

func on_load(_item: Item) -> void:
	setup()

func setup() -> void:
	BattleService.s_round_started.connect(on_round_started)

func on_round_started(actions: Array[BattleAction]) -> void:
	for action in actions:
		if action is GagTrap:
			on_trap_used(action)

func on_trap_used(gag: GagTrap) -> void:
	for target in gag.targets:
		if target is Cog:
			if is_boost_cog(target):
				boost_gag(gag)

func is_boost_cog(cog: Cog) -> bool:
	var dna := cog.dna
	if dna.is_mod_cog or dna.is_admin or not dna.custom_nametag_suffix == "":
		return true
	return false

func boost_gag(gag: GagTrap) -> void:
	gag.damage *= PROXY_BOOST
