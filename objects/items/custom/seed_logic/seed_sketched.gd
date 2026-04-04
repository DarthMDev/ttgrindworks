## DO NOT UNCOMMENT
## DO NOT LET IT BREAK CONTAINMENT
# class_name Sketched
extends 'res://objects/items/custom/seed_logic/custom_seed_base.gd'


const SKETCHED := "res://objects/items/custom/seed_logic/sketched.tscn"

var sketched: Node


# Sketched
func _ready() -> void:
	sketched = load(SKETCHED).instantiate()
	add_child(sketched)
	Util.s_floor_started.connect(on_floor_start)

func on_floor_start(gfloor: GameFloor) -> void:
	var env : Environment = gfloor.environment.environment.duplicate(true)
	env.background_energy_multiplier *= 2.0
	env.glow_bloom *= 4.0
	env.ambient_light_energy *= 2.5
	gfloor.environment.environment = env
	await Task.delay(8.0)
	if Util.floor_number == 0:
		Util.get_player().boost_queue.queue_text("This will be Toon's Town", Color.AQUA)
		await Task.delay(1.5)
		Util.get_player().boost_queue.queue_text("In 2014", Color.CRIMSON)
