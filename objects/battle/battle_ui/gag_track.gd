extends TextureRect
class_name TrackElement

const WARNING_COLOR := Color.RED

@onready var gag_buttons: = $Gags.get_children()
@onready var ui_root: BattleUI = NodeGlobals.get_ancestor_of_type(self, BattleUI)
@onready var point_label := %Points
@onready var track_label := %TrackName

## Locals
var unlocked: int 
var track: Track
var gags: Array[ToonAttack]
var free := false

## Signals
signal s_refreshing(element: TrackElement)
signal s_refreshed(element: TrackElement)


func _ready():
	var loadout: GagLoadout = Util.get_player().stats.character.gag_loadout
	var track_index : int = get_parent().get_children().find(self)
	if track_index >= loadout.loadout.size():
		grey_out()
		return
	
	track = loadout.loadout[track_index]
	unlocked = Util.get_player().stats.gags_unlocked[track.track_name]
	
	# Set the track color and name
	if unlocked > 0:
		show_track()
	else:
		grey_out()
	
	# Always check the refunds
	if ui_root:
		ui_root.s_gag_canceled.connect(refund_gag)
	
	# Add track to the bar
	refresh()

func emit_gag(gag: ToonAttack, price: int):
	var newgag := gag.duplicate()
	Util.get_player().stats.gag_balance[track.track_name] -= price
	refresh()
	ui_root.s_gag_pressed.emit(newgag)
	newgag.price = price

func refresh():
	if not track:
		return
	
	unlocked = Util.get_player().stats.gags_unlocked[track.track_name]
	if unlocked > 0:
		show_track()
	
	# Allow scripts to alter the gag track by signaling out
	# Duplicate the base track so that the effects are not permanent
	gags = track.gags.duplicate()
	s_refreshing.emit(self)
	
	for i in gag_buttons.size():
		if gags.size() >= i + 1 and i < unlocked:
			var gag := gags[i]
			var button: GagButton = gag_buttons[i]
			button.image = gag.icon
			button.show()
			
			if button.pressed.is_connected(emit_gag):
				button.pressed.disconnect(emit_gag)
				button.mouse_entered.disconnect(ui_root.gag_hovered)
				button.mouse_exited.disconnect(ui_root.gag_unhovered)
			
			var price := 0
			var stats : PlayerStats
			if is_instance_valid(BattleService.ongoing_battle):
				stats = BattleService.ongoing_battle.battle_stats[Util.get_player()]
			else:
				stats = Util.get_player().stats
			if not button.pressed.is_connected(emit_gag):
				if not is_gag_free(gag):
					price = i
					price -= stats.gag_discount
					price = maxi(price, 0)
				button.set_count(price)
				if ui_root:
					button.mouse_entered.connect(ui_root.gag_hovered.bind(gag))
					button.mouse_exited.connect(ui_root.gag_unhovered)
					button.pressed.connect(emit_gag.bind(gag,price))
			
			if should_disable(gag, price):
				button.disable()
			else:
				button.enable()
		else:
			gag_buttons[i].hide()
	
	point_label.text = "Points: " + str(roundi(Util.get_player().stats.gag_balance[track.track_name])) + '/' + str(roundi(Util.get_player().stats.gag_cap))
	if Util.get_player().stats.gag_balance[track.track_name] > Util.get_player().stats.gag_cap:
		point_label.self_modulate = WARNING_COLOR
	else:
		point_label.self_modulate = Color.WHITE
	
	s_refreshed.emit(self)

func refund_gag(gag: ToonAttack):
	var player := Util.get_player()
	for i in track.gags.size():
		if track.gags[i].action_name == gag.action_name:
			var new_balance: int = player.stats.gag_balance[track.track_name]
			new_balance = clamp(new_balance + gag.price, 0, player.stats.gag_cap)
			player.stats.gag_balance[track.track_name] = new_balance
			refresh()
			return

# Gag checks
func all_cogs_lured() -> bool:
	if not ui_root:
		return false
	var battle_manager: BattleManager = ui_root.get_parent()
	var all_lured := true
	for cog in battle_manager.cogs:
		if not cog.lured:
			all_lured = false
			break
	return all_lured

func all_cogs_trapped() -> bool:
	if not ui_root:
		return false
	var battle_manager: BattleManager = ui_root.get_parent()
	var all_trapped := true
	for cog in battle_manager.cogs:
		if not cog.trap:
			all_trapped = false
			break
	return all_trapped

func grey_out() -> void:
	point_label.hide()
	track_label.set_text("???")
	self_modulate = Color.GRAY
	for button in gag_buttons:
		button.hide()

func set_disabled(disabled : bool) -> void:
	for button : GagButton in gag_buttons:
		if disabled:
			button.disable()
		else:
			refresh()

func show_track() -> void:
	track_label.set_text(track.track_name.to_upper())
	self_modulate = track.track_color

func should_disable(gag : ToonAttack, price : int) -> bool:
	if Util.get_player().stats.gag_balance[track.track_name] < price:
		return true
	
	if (gag is GagLure) and all_cogs_lured():
		return true
	elif (gag is GagTrap) and ((all_cogs_lured() and Util.get_player().trap_needs_lure) or all_cogs_trapped()):
		return true
	return false

func is_gag_free(gag : ToonAttack) -> bool:
	for free_gag in Util.get_player().free_gags:
		if free_gag.action_name == gag.action_name:
			return true
	if gag in Util.get_player().free_gags:
		return true
	return free
