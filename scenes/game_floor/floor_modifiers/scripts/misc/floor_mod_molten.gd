extends FloorModifier

const THERMOMETER := "res://objects/misc/thermometer/molten_thermometer.tscn"
const BUCKET_RATE := 4

var thermometer: Control
var bucket_chance := 0

func get_mod_name() -> String:
	return "Molten Setup"

func modify_floor() -> void:
	#thermometer = load(THERMOMETER).instantiate()
	#add_child(thermometer)
	
	game_floor.environment.environment = game_floor.environment.environment.duplicate(true)
	game_floor.environment.environment.ambient_light_color = Color('ffd8bf')
	get_tree().node_added.connect(on_node_added)
	BattleService.s_battle_spawned.connect(on_battle_spawned)

func on_node_added(node: Node) -> void:
	if node is MoltenWaterBucket:
		connect_bucket(node)

func connect_bucket(bucket: MoltenWaterBucket) -> void:
	if bucket.is_queued_for_deletion(): return
	
	bucket.queue_free()
	
	#if RNG.channel(RNG.ChannelMoltenBuckets).randi() % BUCKET_RATE > bucket_chance:
		#bucket.queue_free()
		#bucket_chance += 1
		#return
	#
	#if not bucket.s_collected.is_connected(thermometer.cool_down):
		#bucket.s_collected.connect(thermometer.cool_down)
		#bucket_chance = 0

func on_battle_spawned(battle: BattleNode) -> void:
	if battle.override_intro: return
	
	for cog in battle.cogs:
		if cog.dna.is_mod_cog:
			var new_movie := BattleStartMovie.new()
			new_movie.override_music = load('res://audio/music/molten_mint/liquid_metal_proxy.ogg')
			battle.override_intro = new_movie
			return
