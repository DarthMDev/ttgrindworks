extends BattleStartMovie

const DEBUG_SKIP := false
const TM := preload('res://objects/cog/presets/sellbot/traffic_manager.tres')
const BK := preload('res://objects/cog/presets/cashbot/bookkeeper.tres')
const WB := preload('res://objects/cog/presets/lawbot/whistleblower.tres')
const UB := preload('res://objects/cog/presets/bossbot/union_buster.tres')


var directory: FinalBossScene:
	get: return battle_node.get_parent()
var boss1: Cog 
var boss2: Cog
var boss_cogs: Array[Cog]:
	get: return [boss1, boss2]

func play() -> Tween:
	boss1 = battle_node.cogs[0]
	boss2 = battle_node.cogs[1]
	for cog in battle_node.cogs:
		cog.set_animation('neutral')
	movie = get_paired_scene()
	return movie

func get_paired_scene() -> Tween:
	if DEBUG_SKIP and OS.is_debug_build():
		return debug_skip()
	
	return find_scene(get_active_pairing()).call()

func set_camera_angle(angle: String) -> void:
	camera.global_transform = get_camera_angle(angle)

func get_camera_angle(angle: String) -> Transform3D:
	return directory.get_node('CameraAngles/' + angle).global_transform

func get_char_position(pos: String) -> Vector3:
	return directory.get_node('CharPositions/'+ pos).global_position

#region CUTSCENE VARIANTS
var pairings := {
	[TM, BK]: bk_tm,
	[TM, WB]: tm_wb,
	[TM, UB]: tm_ub,
	[BK, WB]: bk_wb,
	[BK, UB]: bk_ub,
	[WB, UB]: wb_ub,
}

func find_scene(active_pairing: Array[String]) -> Callable:
	for pairing in pairings.keys():
		if compare_pairing(active_pairing, get_pairing(pairing)):
			return pairings[pairing]
	return debug_skip

func get_active_pairing() -> Array[String]:
	return [boss1.dna.cog_name, boss2.dna.cog_name]

func get_pairing(dna_pair: Array) -> Array[String]:
	return [dna_pair[0].cog_name, dna_pair[1].cog_name]

func compare_pairing(pairing1: Array[String], pairing2: Array[String]) -> bool:
	if pairing1.hash() == pairing2.hash():
		return true
	pairing1.reverse()
	return pairing1.hash() == pairing2.hash()

func get_cog(cog_name: String) -> Cog:
	for cog in boss_cogs:
		if cog.dna.cog_name == cog_name:
			return cog
	return

## USE THIS IF THE BOSS COGS' POSITIONS NEED TO BE SWAPPED BEFORE STARTING
func swap_cog_positions() -> void:
	var prev_pos = boss1.position
	boss1.position = boss2.position
	boss2.position = prev_pos

func bk_ub() -> Tween:
	var bk := get_cog('Bookkeeper')
	var ub := get_cog('Union Buster')
	var player: Player = Util.get_player()
	
	var scene := create_tween()
	
	# Elevator shot
	append_toon_elevator_shot(scene)
	scene.tween_callback(tween_buffer)
	
	# Move to boss focus as Cogs turn
	append_char_move(scene, player, get_char_position('WalkInPos'), 3.0, true)
	scene.parallel().set_trans(Tween.TRANS_QUAD).tween_property(camera, 'global_transform', get_camera_angle('FocusBoss'), 3.0)
	append_char_turn(scene, bk, get_char_position('WalkInPos'), 3.0, true)
	append_char_turn(scene, ub, get_char_position('WalkInPos'), 3.0, true)
	scene.parallel().tween_callback(bk.speak.bind("Surprised? You shouldn't be.")).set_delay(2.0)
	scene.tween_interval(3.0)
	
	# Cogversation :)
	append_cog_speak_shot(scene, ub, "We've been expecting you, Toon.")
	append_cog_speak_shot(scene, ub, "The Chairman prizes us for our forward-thinking and meticulousness.", 4.0, false)
	append_cog_speak_shot(scene, ub, "Did you truly think your destructive tomfoolery would escape our notice?", 4.0, false)
	append_cog_speak_shot(scene, bk, "I've already run the numbers. The amount of damage you have caused this facility is... astronomical.", 4.0)
	append_cog_speak_shot(scene, bk, "How you even found this place is another matter entirely.", 3.0, false)
	append_cog_speak_shot(scene, ub, "I already have my team searching for the employee who dared leak this location.", 4.0)
	append_cog_speak_shot(scene, ub, "Rest assured, they shall be reduced to scrap metal by lunch.", 3.0, false)
	append_cog_speak_shot(scene, ub, "You see, Toon...", false)
	append_cog_speak_shot(scene, ub, "Unlike our loudmouthed contemporaries, the two of us prefer to do things quietly.", 4.0, false)
	append_cog_speak_shot(scene, ub, "There is beauty in the silence that conformity brings.", 3.0, false)
	append_cog_speak_shot(scene, bk, "And soon, despite your wanton destruction, the facility will be back to full capacity.", 4.0)
	append_cog_speak_shot(scene, bk, "Once more in a state of tranquil dominance.", 4.0, false)
	append_cog_speak_shot(scene, ub, "For no matter how many pies you toss, or seltzer bottles you squirt...", 4.0)
	scene.parallel().tween_callback(start_music)
	append_cog_speak_shot(scene, ub, "This company will never fall.", 4.0, false)
	# Play music here ^
	append_cog_speak_shot(scene, bk, "You believe yourself capable of defeating us? Pure fiction.", 4.0)
	append_cog_speak_shot(scene, bk, "You are simply an errant mark on this ledger.", 3.0, false)
	append_cog_speak_shot(scene, bk, "An insignificant speck of ink on an otherwise flawless page.", 3.0, false)
	append_cog_speak_shot(scene, ub, "Now prepare to be expunged.", 4.0)
	
	return scene

func bk_tm() -> Tween:
	var bk := get_cog('Bookkeeper')
	var tm := get_cog('Traffic Manager')
	var player: Player = Util.get_player()
	
	var scene := create_tween()
	
	# Elevator shot
	append_toon_elevator_shot(scene)
	scene.tween_callback(tween_buffer)
	
	# Move to boss focus as Cogs turn
	append_char_move(scene, player, get_char_position('WalkInPos'), 3.0, true)
	scene.parallel().set_trans(Tween.TRANS_QUAD).tween_property(camera, 'global_transform', get_camera_angle('FocusBoss'), 3.0)
	scene.parallel().tween_callback(tm.speak.bind("Your reports are only barely before their deadlines, yet again.")).set_delay(2.0)
	scene.tween_interval(3.0)
	
	append_cog_speak_shot(scene, tm, "Would it rust your servos to be a bit more punctual?")
	append_cog_speak_shot(scene, bk, "My work requires precision and delicateness, Mr. Manager.")
	append_cog_speak_shot(scene, bk, "Qualities that your processors seem unable to read in.", 3.0, false)
	append_cog_speak_shot(scene, tm, "Beg your pardon!?", 2.0)
	append_cog_speak_shot(scene, bk, "Oh please, Mr. Manager. This is the 3897th time we have had this conversation.")
	append_cog_speak_shot(scene, bk, "I am the personal finance manager to the Chairman.", 3.0, false)
	append_cog_speak_shot(scene, bk, "I assure you that I know how to do my job.", 3.0, false)
	append_cog_speak_shot(scene, bk, "Unless you wish to question the Chairman's judgement?", 3.0, false)
	append_cog_speak_shot(scene, tm, "How dare you! I would never!")
	append_cog_speak_shot(scene, tm, "I am simply saying that someone appointed by the Chairman should have a better timetable!", 4.0, false)
	scene.set_trans(Tween.TRANS_QUAD).tween_property(camera, 'global_transform', get_camera_angle('FocusBoss'), 3.0)
	scene.set_trans(Tween.TRANS_LINEAR)
	append_char_turn(scene, bk, get_char_position('WalkInPos'), 2.0, true)
	scene.parallel().tween_callback(tm.speak.bind("You would expect an executive of your caliber to excel in ALL fields, especially-"))
	scene.parallel().tween_callback(bk.speak.bind("Would you please halt your incessant rambling for a moment?")).set_delay(2.5)
	scene.tween_interval(2.5)
	scene.tween_callback(tm.set_animation.bind('halt'))
	append_cog_speak_shot(scene, tm, "I see no stop lights, Ms. Bookkeeper! And therefore-", 2.0)
	append_cog_speak_shot(scene, bk, "Please turn around.")
	scene.tween_callback(battle_node.focus_character.bind(tm))
	scene.set_trans(Tween.TRANS_LINEAR)
	append_char_turn(scene, tm, get_char_position('WalkInPos'), 1.5)
	append_cog_speak_shot(scene, tm, "WHAT!? A TOON? IN THIS FACILITY!?")
	scene.parallel().tween_callback(start_music)
	append_cog_speak_shot(scene, tm, "There was nothing about this in any of your reports, Miss Bookkeeper!", 4.0, false)
	append_cog_speak_shot(scene, bk, "I don't believe you knew they were travelling on your lines, did you? Then pipe down.", 4.0)
	append_cog_speak_shot(scene, bk, "Unexpected, yes. Unplanned for? Hardly.", 3.0, false)
	scene.set_trans(Tween.TRANS_QUAD).tween_property(camera, 'global_transform', get_camera_angle('BattleFocus'), 2.0)
	scene.set_trans(Tween.TRANS_LINEAR)
	append_char_move(scene, bk, battle_node.get_cog_position(bk), 3.5, true)
	scene.tween_interval(1.0)
	append_cog_speak_shot(scene, bk, "I'll scrub this mark from staining your reputation, Mr. Manager.", 3.0, false)
	scene.tween_callback(tm.speak.bind("How outrageous! This Toon is mine to run down!"))
	scene.set_trans(Tween.TRANS_LINEAR)
	append_char_move(scene, tm, battle_node.get_cog_position(tm), 3.5, true)
	scene.tween_callback(battle_node.face_battle_center.bind(tm))
	append_cog_speak_shot(scene, tm, "So stay in your lane!")
	return scene

func tm_wb() -> Tween:
	var wb := get_cog('Whistleblower')
	var tm := get_cog('Traffic Manager')
	var player : Player = Util.get_player()
	
	var scene := create_tween()
	
	append_toon_elevator_shot(scene)
	
	scene.tween_callback(wb.set_global_position.bind(get_char_position('WB_TM_INTRO')))
	scene.tween_callback(tm.set_global_position.bind(get_char_position('TM_WB_INTRO')))
	scene.tween_callback(face_character.bind(wb, tm))
	scene.tween_callback(face_character.bind(tm, wb))
	
	append_char_move(scene, player, get_char_position('WalkInPos'), 3.0, true)
	append_char_move(scene, wb, get_char_position('WB_TM_WALKTO'), 2.0, true)
	scene.parallel().set_trans(Tween.TRANS_QUAD).tween_property(camera, 'global_transform', get_camera_angle('WBFocus'), 3.0)
	scene.parallel().tween_callback(wb.speak.bind("Urg, that takes care of that. Never seen a jam so unruly before.")).set_delay(2.0)
	scene.tween_interval(3.0)
	
	append_cog_speak_shot(scene, wb, "Needing to play traffic cop when there's real work to be done makes my gears grind.", 5.0)
	append_cog_speak_shot(scene, tm, "Your assistance in this matter is greatly appreciated, Madame.")
	append_cog_speak_shot(scene, tm, "I cannot believe this. A DELAY on our production lines.", 3.0, false)
	append_cog_speak_shot(scene, tm, "Not only that, it lasted 14.59 SECONDS! OUTRAGEOUS!!!", 3.0, false)
	append_cog_speak_shot(scene, wb, "The lower floors are in complete disarray.")
	append_cog_speak_shot(scene, wb, "An EMBARRASSMENT to the company!", 3.0, false)
	append_cog_speak_shot(scene, wb, "Something's been gumming up our works. No Suit worth their tie is this sloppy.", 4.0, false)
	append_cog_speak_shot(scene, wb, "Especially not in a facility the Chairman prizes so highly.", 3.0, false)
	append_cog_speak_shot(scene, tm, "What could it be? A virus? Espionage? UNIONIZATION!?")
	append_cog_speak_shot(scene, wb, "No no. Something smells...")
	
	scene.set_trans(Tween.TRANS_LINEAR)
	append_char_turn(scene, wb, get_char_position('WalkInPos'), 1.5)
	scene.tween_interval(0.5)
	scene.tween_callback(battle_node.focus_character.bind(wb, -4.0))
	scene.tween_callback(wb.speak.bind("TOONY."))
	scene.parallel().tween_callback(start_music)
	scene.tween_interval(3.0)
	
	append_cog_speak_shot(scene, tm, "Aha! The proverbial wrench in the works shows its dastardly visage!", 5.0)
	scene.tween_callback(battle_node.focus_character.bind(wb, -4.0))
	scene.tween_callback(tm.speak.bind("."))
	append_cog_speak_shot(scene, wb, "Your antics are responsible for these setbacks, aren't they!?", 5.0, false)
	append_cog_speak_shot(scene, tm, "Never in my tenure have I seen such wanton disrespect to my timetable!", 4.0)
	append_cog_speak_shot(scene, tm, "If word of scheduling delays reached the Chairman-", 3.0, false)
	scene.tween_callback(battle_node.focus_character.bind(wb, -4.0))
	scene.tween_callback(tm.speak.bind("."))
	append_cog_speak_shot(scene, wb, "There won't be any need.", 3.0, false)
	append_cog_speak_shot(scene, wb, "We'll CRUSH this incessant rabble-rouser right here and now!", 3.0, false)
	append_cog_speak_shot(scene, tm, "Ha! Well spoken! It appears this is your final stop, Toon.", 3.0)
	scene.tween_callback(battle_node.focus_character.bind(wb, -4.0))
	scene.tween_callback(tm.speak.bind("."))
	append_cog_speak_shot(scene, wb, "We're going to run you out on a rail!", 3.0, false)
	
	return scene

func tm_ub() -> Tween:
	var ub := get_cog('Union Buster')
	var tm := get_cog('Traffic Manager')
	var player : Player = Util.get_player()
	
	var scene := create_tween()
	
	# Elevator shot
	append_toon_elevator_shot(scene)
	scene.tween_callback(tween_buffer)
	
	# Move to boss focus as Cogs turn
	append_char_move(scene, player, get_char_position('WalkInPos'), 3.0, true)
	scene.parallel().set_trans(Tween.TRANS_QUAD).tween_property(camera, 'global_transform', get_camera_angle('FocusBoss'), 3.0)
	scene.parallel().tween_callback(ub.speak.bind("Well, Mr. Manager, after extensive examination of your department...")).set_delay(2.0)
	scene.tween_interval(3.0)
	
	append_cog_speak_shot(scene, ub, "I can say that I am seeing a remarkably clean record of productivity and work ethic.", 4.0)
	append_cog_speak_shot(scene, tm, "Why thank you sir! If there is one thing I pride myself on, it is productivity!", 4.0)
	append_cog_speak_shot(scene, tm, "I am certain the Chairman will be delighted to hear the results of your routine inspection.", 4.0, false)
	append_cog_speak_shot(scene, ub, "Mmn. Yes. Almost too productive. Almost... too clean.")
	append_cog_speak_shot(scene, tm, "I beg your pardon, sir!?")
	append_cog_speak_shot(scene, ub, "Spotless record after spotless record. Not even Miss Golden Goose is this perfect.", 4.0)
	append_cog_speak_shot(scene, ub, "Even for someone appointed by the Chairman himself, such flawless performance may raise eyebrows.", 5.0)
	append_cog_speak_shot(scene, ub, "Perhaps you’re trying to... cover something up?", 3.0, false)
	append_cog_speak_shot(scene, tm, "How DARE you!? You would question my loyalty to this company!?")
	append_cog_speak_shot(scene, ub, "It is because of my loyalty that I deem it fit to question yours.")
	append_cog_speak_shot(scene, ub, "My job is to ask the difficult questions, Mr. Manager.", 3.0, false)
	append_cog_speak_shot(scene, tm, "Well MY job is to keep this company’s engine running!")
	append_cog_speak_shot(scene, tm, "You can inspect my lines from top to bottom and find them spotless!", 4.0, false)
	append_cog_speak_shot(scene, tm, "Perhaps I should be the one questioning YOU!", 3.0, false)
	append_cog_speak_shot(scene, tm, "Who is it that watches the watcher, hm?", 3.0, false)
	scene.tween_callback(tween_buffer)
	append_char_turn(scene, ub, get_char_position('WalkInPos'), 1.5, true)
	scene.parallel().tween_callback(battle_node.focus_character.bind(ub))
	scene.parallel().tween_callback(ub.speak.bind("Rrg. We’ll continue this discussion later. It appears we have a guest."))
	scene.parallel().tween_interval(3.0)
	scene.tween_callback(tm.speak.bind("What?"))
	scene.tween_callback(battle_node.focus_character.bind(tm))
	append_char_turn(scene, tm, get_char_position('WalkInPos'), 1.5)
	scene.tween_interval(0.1)
	scene.tween_callback(tm.set_animation.bind('pie-small'))
	append_cog_speak_shot(scene, tm, "Ack! Alack! Egad!!! A Toon!?", 3.0, false)
	scene.parallel().tween_callback(start_music)
	append_cog_speak_shot(scene, tm, "Let us put aside this disagreement for now.", 3.0, false)
	append_cog_speak_shot(scene, tm, "I shall prove the veracity of my claims by putting a stop to this runaway disaster.", 5.0, false)
	append_cog_speak_shot(scene, ub, "Then we shall waste no time.")
	append_cog_speak_shot(scene, ub, "The two of us shall scab over this open wound in no time.", 4.0, false)
	scene.tween_callback(battle_node.reposition_cogs)
	scene.set_trans(Tween.TRANS_QUAD).tween_property(camera, 'global_transform', get_camera_angle('BattleFocus'), 2.0)
	
	append_cog_speak_shot(scene, ub, "Your ambitions are about to be broken, pest.")
	append_cog_speak_shot(scene, tm, "All lights read green on Toon elimination protocol!")
	
	return scene

func bk_wb() -> Tween:
	var wb := get_cog('Whistleblower')
	var bk := get_cog('Bookkeeper')
	var player : Player = Util.get_player()
	
	var scene := create_tween()
	append_toon_elevator_shot(scene)
	scene.tween_callback(tween_buffer)
	
	# Move to boss focus as Cogs turn
	append_char_move(scene, player, get_char_position('WalkInPos'), 3.0, true)
	scene.parallel().set_trans(Tween.TRANS_QUAD).tween_property(camera, 'global_transform', get_camera_angle('FocusBoss'), 3.0)
	scene.parallel().tween_callback(bk.speak.bind("...and you want ALL of those reports filed... immediately?")).set_delay(2.0)
	scene.tween_interval(3.0)
	
	append_cog_speak_shot(scene, wb, "Quite so, Miss Bookkeeper! I’m afraid they’re all rather important.")
	append_cog_speak_shot(scene, bk, "Right. And does... each individual charge need to be its own report?")
	append_cog_speak_shot(scene, bk, "This encyclopedia could have been a pamphlet.", 3.0, false)
	append_cog_speak_shot(scene, bk, "I do have other duties to attend to.", 3.0, false)
	append_cog_speak_shot(scene, bk, "The Chairman needs his financial reports, and I cannot be impeded by frivolity.", 4.0, false)
	append_cog_speak_shot(scene, wb, "That would be to diminish the weight of this Toon’s misdeeds!")
	scene.tween_callback(wb.set_animation.bind('speak'))
	append_cog_speak_shot(scene, wb, "They deserve a separate trial for each misdeed!", 3.0, false)
	append_cog_speak_shot(scene, wb, "Breaking and entering! Destruction of company property!! WORKPLACE TOMFOOLERY!!!", 4.0, false)
	scene.tween_callback(wb.set_animation.bind('buffed'))
	append_cog_speak_shot(scene, wb, "I’ll round that pest up and harangue them UNTIL THE END OF TIME!!!", 3.0, false)
	append_cog_speak_shot(scene, bk, "Your enthusiasm is truly infectious.")
	scene.set_trans(Tween.TRANS_LINEAR)
	append_char_turn(scene, bk, get_char_position('WalkInPos'), 1.5, true)
	append_cog_speak_shot(scene, bk, "But... you may also want to add ‘entering an executive office without clearance’ to those charges.", 5.0, false)
	scene.tween_callback(battle_node.focus_character.bind(wb))
	scene.tween_callback(wb.speak.bind("THERE YOU ARE!!"))
	scene.set_trans(Tween.TRANS_LINEAR)
	append_char_turn(scene, wb, get_char_position('WalkInPos'), 1.5, true)
	scene.parallel().tween_callback(start_music)
	append_cog_speak_shot(scene, wb, "How polite of you to spare me the trouble of hunting you down!", 3.0, false)
	append_cog_speak_shot(scene, wb, "But if you thought coming groveling to me would reduce your charges, you’re SORELY mistaken.", 5.0, false)
	append_cog_speak_shot(scene, bk, "Despite my overzealous compatriot’s blustering...")
	append_cog_speak_shot(scene, bk, "Your list of workplace infractions are truly monumental.", 4.0, false)
	append_cog_speak_shot(scene, bk, "And we are well within our jurisdiction to punish you for them. Extensively.", 4.0, false)
	scene.tween_callback(battle_node.reposition_cogs)
	scene.set_trans(Tween.TRANS_QUAD).tween_property(camera, 'global_transform', get_camera_angle('BattleFocus'), 2.0)
	scene.tween_interval(1.0)
	append_cog_speak_shot(scene, wb, "Let’s book ‘em, shall we?")
	append_cog_speak_shot(scene, bk, "I’m afraid that your story ends here.")
	
	return scene

func wb_ub() -> Tween:
	var wb := get_cog('Whistleblower')
	var ub := get_cog('Union Buster')
	var player : Player = Util.get_player()
	
	var scene := create_tween()
	
	append_toon_elevator_shot(scene)
	scene.tween_callback(tween_buffer)
	
	# Move to boss focus as Cogs turn
	append_char_move(scene, player, get_char_position('WalkInPos'), 3.0, true)
	scene.parallel().set_trans(Tween.TRANS_QUAD).tween_property(camera, 'global_transform', get_camera_angle('FocusBoss'), 3.0)
	scene.parallel().tween_callback(wb.speak.bind("Yes sir, I’m sure of it. Suit 311A in Division 7, cubicle 2896.")).set_delay(2.0)
	scene.tween_interval(3.0)
	
	append_cog_speak_shot(scene, ub, "I see. And what was this miscreant doing?")
	append_cog_speak_shot(scene, wb, "Sources say... he stared off into space for a full ten seconds.")
	append_cog_speak_shot(scene, ub, "...Unbelievable. Such flagrant wage theft on company time.")
	append_cog_speak_shot(scene, ub, "Take care of him quietly. I’ll have a Flunky replace him shortly.", 4.0, false)
	scene.tween_callback(battle_node.focus_character.bind(wb))
	scene.set_trans(Tween.TRANS_LINEAR)
	append_char_turn(scene, wb, get_char_position('WalkInPos'), 1.5)
	append_cog_speak_shot(scene, wb, "Oh ho! It appears there are far bigger fish for the frying.", 3.0, false)
	scene.parallel().tween_callback(start_music)
	scene.tween_callback(battle_node.focus_character.bind(ub))
	scene.set_trans(Tween.TRANS_LINEAR)
	append_char_turn(scene, ub, get_char_position('WalkInPos'), 1.5)
	append_cog_speak_shot(scene, ub, "Well well. A Toon. Your timing is quite fortuitous.", false)
	append_cog_speak_shot(scene, ub, "You see, my colleague here and I are tasked with the discipline of this fine facility.", 4.0, false)
	append_cog_speak_shot(scene, wb, "But under our supervision, there’s hardly any lawbreakers to haul off!", 4.0)
	append_cog_speak_shot(scene, ub, "Leaving us with... downtime.")
	append_cog_speak_shot(scene, wb, "Cogs without work? OUTRAGEOUS! What kind of employees have DOWNTIME!?", 4.0)
	append_cog_speak_shot(scene, wb, "But when I hear whispers of a maggot sneaking around making mischief...", 4.0, false)
	append_cog_speak_shot(scene, ub, "It finally gives us a chance to use our full talents.")
	append_cog_speak_shot(scene, ub, "I assure you, the Chairman has rated our abilities to eliminate pests second to none.", 4.0, false)
	append_cog_speak_shot(scene, wb, "Enjoy your last whiffs of air as a free Toon.")
	append_cog_speak_shot(scene, ub, "Because you’re busted.")
	
	return scene

func debug_skip() -> Tween:
	var scene := create_tween()
	scene.tween_interval(2.0)
	battle_node.cogs.append_array(battle_node.get_parent().fill_elevator(2))
	scene.tween_callback(battle_node.reposition_cogs)
	return scene

func append_cog_speak_shot(tween : Tween, cog : Cog, phrase : String, time := 3.0, focus_character := true) -> void:
	if focus_character:
		tween.tween_callback(battle_node.focus_character.bind(cog))
	tween.tween_callback(cog.speak.bind(phrase))
	tween.tween_interval(time)

func append_toon_elevator_shot(tween : Tween, time := 3.0) -> void:
	tween.tween_callback(Util.get_player().set_global_position.bind(get_char_position("StartPos")))
	tween.tween_callback(Util.get_player().face_position.bind(battle_node.global_position))
	tween.tween_callback(camera.set_global_transform.bind(directory.elevator_in.elevator_cam.global_transform))
	tween.tween_callback(directory.elevator_in.open)
	tween.tween_interval(time)

func append_char_move(tween : Tween, character : Actor, pos : Vector3, time : float, parallel := false) -> void:
	if parallel:
		tween.set_parallel(true)
	tween.tween_callback(character.face_position.bind(pos))
	tween.tween_callback(character.set_animation.bind('walk'))
	tween.tween_property(character, 'global_position', pos, time)
	tween.tween_callback(character.set_animation.bind('neutral')).set_delay(time)
	if parallel:
		tween.set_parallel(false)

func append_char_turn(tween : Tween, character : Actor, pos : Vector3, time : float, parallel := false) -> void:
	if parallel:
		tween.set_parallel(true)
	var current_rotation := character.rotation.y
	character.face_position(pos)
	var goal_rotation := character.rotation.y
	character.rotation.y = current_rotation
	
	tween.tween_callback(character.set_animation.bind('walk'))
	tween.tween_property(character, 'rotation:y', goal_rotation, time).set_trans(Tween.TRANS_LINEAR)
	tween.parallel().tween_callback(character.set_animation.bind('neutral')).set_delay(time)
	if parallel:
		tween.set_parallel(false)

# With the appends, they need to be able to be called parallel.
# But to allow the application of multiple appends to run parallel,
# we may need to buffer whatever action came prior
func tween_buffer() -> void:
	print("Tween Buffer")

#endregion
