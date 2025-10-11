@tool
extends Actor
class_name Stranger

const TRASH_MODEL := "res://models/props/stranger/trashcan/stranger_trashcan.tscn"
const MAIL_MODEL := "res://models/props/stranger/mailbox/stranger_mailbox.tscn"

const MAILBOX_CHANCE := 0.03

const ITEM_COUNT_RANGE := Vector2i(3, 6)
const INTERACTION_TRANSITION_TIME := 1.5

var stranger_model: Node3D

var player: Player
var player_spotted := false
var can_spy := true
var spying := false
var first_interaction := true
var override_spy_mode := false

signal s_interacted
signal s_interaction_finished


func _ready() -> void:
	stranger_model = roll_stranger_model()
	add_child(stranger_model)
	stranger_model.set_scopes_visible(false)
	stranger_model.animator.animation_finished.connect(on_stranger_anim_finished)

func roll_stranger_model() -> Node3D:
	if Engine.is_editor_hint():
		return load([MAIL_MODEL, TRASH_MODEL].pick_random()).instantiate()
	if SaveFileService.progress_file.stranger_met and randf() < MAILBOX_CHANCE:
		return load(MAIL_MODEL).instantiate()
	else:
		return load(TRASH_MODEL).instantiate()

func body_entered(body: Node3D) -> void:
	if body is Player:
		if body.state == Player.PlayerState.WALK:
			on_interact()

func on_interact() -> void:
	s_interacted.emit()

func set_stranger_active(stranger_out: bool) -> void:
	match stranger_out:
		true: stranger_model.scopes_emerge()
		false: stranger_model.scopes_recede()

func body_detected(body: Node3D) -> void:
	if body is Player:
		player_detected(body)

func body_undetected(body: Node3D) -> void:
	if body is Player:
		player_undetected()

func player_detected(plyer: Player) -> void:
	if not is_instance_valid(player):
		player = plyer
	player_spotted = true

func player_undetected() -> void:
	player_spotted = false
	if spying:
		stop_spying()
	else:
		can_spy = false
		%SpyTimer.start()

func _process(_delta) -> void:
	spy_check()

func spy_check() -> void:
	if not player or not player_spotted or override_spy_mode: return
	if can_spy and not spying:
		if not player_facing_stranger() and not stranger_model.animator.is_playing():
			start_spying()
	if spying and player_facing_stranger():
		stop_spying() 

func start_spying() -> void:
	spying = true
	set_stranger_active(true)

func stop_spying() -> void:
	spying = false
	can_spy = false
	set_stranger_active(false)
	%SpyTimer.start()

func on_spy_timeout() -> void:
	can_spy = true

func player_facing_stranger() -> bool:
	var dot_limit := 1.8
	var dot := player.toon.global_transform.basis.z.dot(global_position - player.toon.global_position)
	
	return dot > dot_limit

func on_stranger_anim_finished(anim: StringName) -> void:
	if anim.begins_with('out-idle'):
		if not anim == 'out-idle1':
			set_animation('out-idle1')
		else:
			var new_anim = ['out-idle1', 'out-idle2', 'out-idle3'].pick_random()
			stranger_model.set_animation(new_anim)
	elif anim == 'intro' and spying:
		set_animation('out-idle1')

func speak(phrase: String):
	if not %SpeechBubbleNode:
		print('ERR: No speech bubble node found!')
		return
	
	# Remove existing speech bubble(s) if they exist
	for child in %SpeechBubbleNode.get_children():
		if child is SpeechBubble:
			child.finished.emit()
	
	if phrase == ".":
		return
	
	# Create a new speech bubble
	var bubble: SpeechBubble = load('res://objects/misc/speech_bubble/speech_bubble.tscn').instantiate()
	bubble.target = %SpeechBubbleNode
	bubble.set_font(load('res://fonts/made_mirage_bold.OTF'))
	%SpeechBubbleNode.add_child(bubble)
	bubble.set_text(phrase)
	%SFXDial.play()

## Unused behavior porbably
func mutter_timer_expired() -> void:
	if not stranger_model.show_scopes:
		speak("lemme practice my singing: MI MI MI MIIIIIIIIIIIIIIIIIIIIII")

func set_animation(anim: String) -> void:
	stranger_model.set_animation(anim)
