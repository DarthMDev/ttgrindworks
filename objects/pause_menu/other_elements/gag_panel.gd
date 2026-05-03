extends Control

@onready var gag_icon: Control = %GagIcon
@onready var gag_name: Control = %GagName
@onready var gag_stats: Control  = %GagStats


func _ready() -> void:
	display_gag()
	sync_player_info()
	refresh()

func display_gag(gag: Resource = null) -> void:
	if not gag:
		gag_icon.set_texture(null)
		gag_name.set_text("")
		gag_stats.set_text("")
		show_player_info(true)
	else:
		gag_icon.set_texture(gag.icon)
		gag_name.set_text(gag.action_name)
		gag_stats.set_text(gag.get_stats())
		show_player_info(false)

func show_player_info(enabled: bool) -> void:
	%PlayerInfo.visible = enabled
	%GagInfo.visible = not enabled

func sync_player_info() -> void:
	%PlayerInfoLabel.set_text(
		"Pink Slips: %d\n\nPoint Regen: %d" % [Util.get_player().stats.pink_slips, Util.get_player().stats.gag_regeneration['Throw']]
	)

func refresh() -> void:
	for track: Control in %Tracks.get_children():
		track.refresh()
		if not track.track:
			continue
		for button: TextureButton in track.gag_buttons:
			if button.mouse_entered.is_connected(display_gag):
				button.mouse_entered.disconnect(display_gag)
				button.mouse_exited.disconnect(display_gag)
				button.pressed.disconnect(gag_pressed)
			button.mouse_entered.connect(display_gag.bind(track.track.gags[track.gag_buttons.find(button)]))
			button.mouse_exited.connect(display_gag)
			button.pressed.connect(gag_pressed.bind(track.track, track.gag_buttons.find(button)))
	

func gag_pressed(track: Resource, idx: int) -> void:
	if not is_instance_valid(Util.get_player()): return
	if not Util.get_player().alt_gag_hotswap: return
	
	var gag_variants: Array = track.get_gag_variants(idx)
	if gag_variants.size() == 1: return
	
	var gag_index := gag_variants.find(track.gags[idx])
	var new_index := gag_index + 1
	if new_index >= gag_variants.size(): new_index = 0
	track.swap_gag(gag_variants[new_index])
	refresh()

func get_buttons() -> Dictionary:
	var buttons: Dictionary = {}
	for track: Control in %Tracks.get_children():
		for button: TextureButton in track.gag_buttons:
			buttons[button] = track.gags[track.gag_buttons.find(button)]
	return buttons
