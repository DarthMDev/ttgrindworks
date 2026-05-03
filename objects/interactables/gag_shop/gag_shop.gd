extends Node3D
class_name GagShop

var alt_gags: Dictionary[ToonAttack, ToonAttack] = {}
var SHOP_UI: PackedScene:
	get:
		if not SHOP_UI: return GameLoader.load("res://objects/interactables/gag_shop/gag_shop_ui.tscn")
		return SHOP_UI
var ui: Control


func _init() -> void:
	GameLoader.queue_into(GameLoader.Phase.GAMEPLAY, self, {
		'SHOP_UI' : "res://objects/interactables/gag_shop/gag_shop_ui.tscn",
	})

func _ready() -> void:
	%ShopKeeper.set_animation('neutral')
	if not is_instance_valid(Util.get_player()):
		await Util.s_player_assigned
	var player := Util.get_player()
	roll_for_gags(player.stats.character.gag_loadout)

func body_entered(body: Node3D) -> void:
	if body is Player:
		player_interacted(body)

func roll_for_gags(loadout: GagLoadout) -> void:
	var gag_goal := 3
	var tracks: Array[Track] = loadout.loadout.duplicate()
	while alt_gags.keys().size() < gag_goal:
		# Check if any tracks remaining
		if tracks.is_empty():
			print("Failed to meet Gag goal. Not enough alt Gags in loadout.")
			return
		
		# Pick a random track from the list
		# And get our available Gags
		var track: Track = RandomService.array_pick_random('alt_gags', tracks)
		var available_gags: Array[ToonAttack] = track.mod_gags.keys()
		
		# Remove any Gags already in the player's loadout from the array
		for gag: ToonAttack in track.gags:
			available_gags.erase(gag)
		
		# Do the same for the Gags we've already taken
		for gag: ToonAttack in alt_gags.keys():
			available_gags.erase(gag)
		
		# If no alt Gags available
		# Remove the track from the array
		if available_gags.is_empty():
			tracks.erase(track)
			continue
		
		# Add a random alt Gag to our array
		var new_alt: ToonAttack = RandomService.array_pick_random('alt_gags', available_gags)
		alt_gags[new_alt] = track.gags[track.mod_gags[new_alt]]

func player_interacted(player: Player) -> void:
	if alt_gags.is_empty():
		brush_off()
		return
	
	player.state = Player.PlayerState.STOPPED
	player.global_position.y = global_position.y
	player.set_animation('neutral')
	player.face_position(%ShopKeeper.global_position)
	%ShopKeeper.speak("Choose what you want to buy.")
	CameraTransition.from_current(self, %ShopCam, 1.0)
	await Task.delay(1.0)
	create_ui()

func create_ui() -> void:
	ui = SHOP_UI.instantiate()
	ui.shop = self
	ui.s_gag_purchased.connect(on_gag_purchased)
	ui.s_exit.connect(exit)
	add_child(ui)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func on_gag_purchased(old_gag: ToonAttack, new_gag: ToonAttack) -> void:
	var loadout: GagLoadout = Util.get_player().stats.character.gag_loadout
	for track: Track in loadout.loadout:
		for gag in track.gags:
			if gag == old_gag:
				var index := track.gags.find(gag)
				track.gags.remove_at(index)
				track.gags.insert(index, new_gag)
	for gag in alt_gags.keys():
		if alt_gags[gag] == old_gag:
			if gag == new_gag:
				alt_gags.erase(gag)
			else:
				alt_gags[gag] = new_gag

func exit() -> void:
	ui.queue_free()
	CameraTransition.from_current(self, Util.get_player().camera.camera, 1.0)
	await Task.delay(1.0)
	Util.get_player().state = Player.PlayerState.WALK
	%ShopKeeper.speak("Thanks for stopping by!")

func brush_off() -> void:
	%ShopKeeper.speak("Sorry, pal. Inventory's wiped.")
