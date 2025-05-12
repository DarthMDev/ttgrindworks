extends Control

@onready var gag_icon : Control = %GagIcon
@onready var gag_name : Control = %GagName
@onready var gag_stats : Control  = %GagStats

func _ready() -> void:
	for track : TrackElement in %Tracks.get_children():
		if not track.track:
			continue
		for button : GagButton in track.gag_buttons:
			button.mouse_entered.connect(display_gag.bind(track.track.gags[track.gag_buttons.find(button)]))
			button.mouse_exited.connect(display_gag)
	display_gag()
	sync_player_info() 

func display_gag(gag: ToonAttack = null) -> void:
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

func show_player_info(show : bool) -> void:
	%PlayerInfo.visible = show
	%GagInfo.visible = not show

func sync_player_info() -> void:
	%PlayerInfoLabel.set_text(
		"Pink Slips: %d\n\nPoint Regen: %d" % [Util.get_player().stats.pink_slips, Util.get_player().stats.gag_regeneration['Throw']]
	)

func refresh() -> void:
	for track : TrackElement in %Tracks.get_children():
		track.refresh()
