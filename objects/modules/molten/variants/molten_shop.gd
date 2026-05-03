extends Node3D


@export_multiline var red_chair_toon_phrases: Array[String] = []
@export_multiline var blue_chair_toon_phrases: Array[String] = []

var red_chair_interact_ready := true
var blue_chair_interact_ready := true
var spoke_to_blue_chair := false

var TOON_NAME_LINES := [
	"How's it going, %s?",
	"What's up, %s?",
]

func _ready() -> void:
	setup_towel_toon()
	setup_chair_toons()

func setup_chair_toons() -> void:
	var toon_to_pos: Dictionary[Toon, Node3D] = {
		%ChairToon1: %Chair1Pos,
		%ChairToon2: %Chair2Pos,
	}
	
	for toon: Toon in toon_to_pos.keys():
		var pos := toon_to_pos[toon]
		toon.reparent(pos)
		
		var pos_diff := pos.global_position - toon.hip_bone.global_position
		toon.global_position += pos_diff

func setup_towel_toon() -> void:
	%TowelToon.set_animation('slip-forward')
	%TowelToon.anim_seek(0.875, true)
	%TowelToon.anim_pause()
	%TowelToon.set_blink_paused(true)
	%TowelToon.close_eyes()
	%TowelToon.speak(". . . . ZZZ . . .")
	var bubble: SpeechBubble = %TowelToon.speech_bubble_node.get_child(0)
	%TowelToon.speech_bubble_node.position.y -= 1.0
	bubble.auto_expire = false

func chair1_toon_interaction(body: Node3D) -> void:
	if not red_chair_interact_ready: return
	if body is Player:
		var phrases := red_chair_toon_phrases.duplicate()
		for phrase in TOON_NAME_LINES: phrases.append(phrase % Util.get_player().character.character_name)
		%ChairToon1.speak(phrases[randi() % phrases.size()])
	red_chair_interact_ready = false
	Task.delay(5.0).connect(func(): red_chair_interact_ready = true)

func chair2_toon_interaction(body: Node3D) -> void:
	if not blue_chair_interact_ready: return
	if body is Player:
		if not spoke_to_blue_chair:
			%ChairToon2.speak(blue_chair_toon_phrases[0])
			spoke_to_blue_chair = true
			return
		%ChairToon2.speak(blue_chair_toon_phrases[randi() % blue_chair_toon_phrases.size()])
	blue_chair_interact_ready = false
	Task.delay(5.0).connect(func(): blue_chair_interact_ready = true)

func on_boss_finished(_pipe) -> void:
	spoke_to_blue_chair = false
	blue_chair_toon_phrases.remove_at(0)
	blue_chair_toon_phrases.insert(0, "Looks like the pipe's working again, huh?")
