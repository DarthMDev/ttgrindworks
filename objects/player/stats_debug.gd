extends Label

# AUGHHH make a dict later

var healed_from_winter_hat = 0
var healed_from_faded_tiara = 0
var healed_from_treasure = 0
var healed_from_throw = 0
var healed = 0
var damage_taken = 0
var battles_done = 0
var last_round_number = 0
var loadout = GagLoadout

func _ready() -> void:
	if SaveFileService.settings_file.show_timer:
		show()

func _process(delta: float) -> void:
	var fps = str(Engine.get_frames_per_second())
	if not Util.get_player():
		print("couldn't find player")
		return
	else:
		var player = Util.get_player()
		if BattleService.ongoing_battle != null:
			last_round_number = BattleService.ongoing_battle.current_round
			
		healed_from_winter_hat = Globals.healed_from_winter_hat
		healed_from_faded_tiara = Globals.healed_from_faded_tiara
		healed_from_treasure = Globals.healed_from_treasure
		healed_from_throw = Globals.healed_from_throw
		#healed = Globals.healed
		damage_taken = Globals.damage_taken
		battles_done = Util.battles_encountered
		healed = healed_from_faded_tiara + healed_from_winter_hat + healed_from_throw + healed_from_treasure
		
	text = "winter hat: %.2f 
	faded tiara: %.2f
	treasure: %.2f
	throw: %.2f
	overall_heal: %.2f
	dmg tkn: %.2f
	battles: %.0f
	round: lv.%.0f
	rnd_dmg:.%.0f
	prv_dmg:.%.0f
	holder: lv.%.0f" % [
		healed_from_winter_hat,
		healed_from_faded_tiara,
		healed_from_treasure,
		healed_from_throw,
		healed,
		damage_taken,
		battles_done,
		last_round_number,
		0,
		0,
		0]
