extends 'res://objects/items/custom/seed_logic/custom_seed_base.gd'


const NEONOTE_COOLDOWN := Vector2(1.0, 120.0)


func setup() -> void:
	BattleService.s_battle_started.connect(on_battle_started)
	while true:
		await Task.delay(randf_range(NEONOTE_COOLDOWN.x, NEONOTE_COOLDOWN.y))
		random_anomalous_and_obscure_and_strange_neonote_event()

func on_battle_started(battle: BattleManager) -> void:
	var node := battle.battle_node
	for cog in node.cogs:
		cog.speak("I'm neoNote")

func random_anomalous_and_obscure_and_strange_neonote_event() -> void:
	var event_type := randi() % 3
	match event_type:
		0:
			boost_text()
		1:
			toon_speaks()
		2:
			random_cog_speaks()

func boost_text() -> void:
	Util.get_player().boost_queue.queue_text("I'm neoNote.", Color(randf(), randf(), randf()))

func toon_speaks() -> void:
	Util.get_player().speak("I'm neoNote.")

func random_cog_speaks() -> void:
	var cogs: Array = NodeGlobals.get_children_of_type(SceneLoader.current_scene, Cog, true)
	if cogs.is_empty():
		boost_text()
		return
	var random_cog: Cog = cogs.pick_random()
	random_cog.speak("I'm neoNote.")
