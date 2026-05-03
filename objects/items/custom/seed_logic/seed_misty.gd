extends 'res://objects/items/custom/seed_logic/custom_seed_base.gd'


const GOOSE_DNA := "res://objects/cog/presets/cashbot/golden_goose.tres"


func setup() -> void:
	Globals.add_standard_cog(load(GOOSE_DNA))

func _exit_tree() -> void:
	Globals.remove_standard_cog(load(GOOSE_DNA))
