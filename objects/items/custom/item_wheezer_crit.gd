extends ItemScript

var no_crit_track_count := 1
var crit_track_count := 1
var crit_tracks: Array[Track] = []
var no_crit_tracks: Array[Track] = []

func on_collect(_item: Item, _object: Node3D) -> void:
	setup()

func on_load(_item: Item) -> void:
	setup()

func setup() -> void:
	BattleService.s_battle_started.connect(battle_start)

func battle_start(battle: BattleManager) -> void:
	await battle.s_ui_initialized
	var ui: BattleUI = battle.battle_ui
	battle.s_round_ended.connect(on_round_ended.bind(ui))
	ui.s_turn_complete.connect(on_turn_finalized)
	on_round_ended(ui)

func on_round_ended(ui: BattleUI) -> void:
	reset_track_colors(ui)
	
	# Pick tracks to use
	crit_tracks = []
	no_crit_tracks = []
	var loadout := Util.get_player().character.gag_loadout.loadout.duplicate(true)

	# Remove lure from the running (it has no crit)
	for i in range(loadout.size() - 1, -1, -1):
		if is_instance_of(loadout[i].gags[0], GagLure):
			loadout.remove_at(i)
	
	while loadout.size() > 0 and crit_tracks.size() < crit_track_count:
		RNG.channel(RNG.ChannelWheezerAbility).shuffle(loadout)
		crit_tracks.append(loadout.pop_back())
	
	while loadout.size() > 0 and no_crit_tracks.size() < no_crit_track_count:
		RNG.channel(RNG.ChannelWheezerAbility).shuffle(loadout)
		no_crit_tracks.append(loadout.pop_back())
	
	var colors := [Color.RED, Color.GREEN]
	
	# Change button colors
	for i in crit_tracks.size():
		var element := ui.get_track_element(crit_tracks[i])
		
		for button in element.gag_buttons:
			button.default_color = colors[1]
	
	# Change button colors
	for i in no_crit_tracks.size():
		var element := ui.get_track_element(no_crit_tracks[i])
		
		for button in element.gag_buttons:
			button.default_color = colors[0]

func on_turn_finalized(actions: Array[ToonAttack]) -> void:
	for action in actions:
		for track in no_crit_tracks:
			for miss_action in track.gags:
				if miss_action.action_name == action.action_name:
					# NEVER CRIT
					action.crit_chance_mod = 0.0
		for track in crit_tracks:
			for hit_action in track.gags:
				if hit_action.action_name == action.action_name:
					# ALWAYS CRIT
					action.crit_chance_mod = Globals.CRIT_MOD_GUARANTEE

func reset_track_colors(ui: BattleUI) -> void:
	for track_element in ui.gag_tracks.get_children():
		for button in track_element.gag_buttons:
			button.default_color = Color("00a1ff")
