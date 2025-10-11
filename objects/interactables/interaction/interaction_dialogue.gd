extends Interaction
class_name InteractionDialogue


const SPEECH_BUBBLE := preload('res://objects/misc/speech_bubble/speech_bubble_interactive/speech_bubble_interactive.tscn')

@export_multiline var dialogue: Array[String] = []
@export var actor: Node3D
@export var exit_on_finish := true

var actor_rotation: Vector3


func interact() -> void:
	stop_player()
	if actor and actor.has_method('face_position'):
		actor_rotation = actor.rotation
		actor.face_position(player.global_position)
		player.face_position(actor.global_position)
	
	do_camera_transition()
	start_dialogue()

func start_dialogue() -> void:
	var bubble := SPEECH_BUBBLE.instantiate()
	bubble.dialogue = dialogue
	bubble.s_dialogue_finished.connect(on_dialogue_finished)
	bubble.character = actor
	bubble.target = self
	add_child(bubble)

func on_dialogue_finished() -> void:
	s_interaction_finished.emit()
	s_interaction_finished_player.emit(player)
	if exit_on_finish:
		end_interaction()

func end_interaction() -> void:
	_standard_exit()
	if actor_rotation and is_instance_valid(actor):
		actor.rotation = actor_rotation
