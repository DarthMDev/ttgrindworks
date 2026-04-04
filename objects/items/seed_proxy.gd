extends 'res://objects/items/custom/seed_logic/custom_seed_base.gd'


func setup() -> void:
	get_tree().node_added.connect(on_node_added)

func on_node_added(node: Node) -> void:
	if node is Cog:
		on_cog_spawned(node)

func on_cog_spawned(cog: Cog) -> void:
	cog.use_mod_cogs_pool = true
