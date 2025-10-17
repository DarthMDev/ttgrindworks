extends CanvasLayer
class_name LoseMenu

const SFX_LOSE := preload("res://audio/sfx/misc/MG_lose.ogg")

enum MenuChoice { PLAY_AGAIN, BACK_TO_MENU }

signal s_choice_made(menu_choice: MenuChoice)

@onready var root: Control = %Root
@onready var node_viewer: TextureRect = %NodeViewer
@onready var seed_label: Label = %SeedLabel
@onready var seed_button: Button = %SeedButton

var toon: Toon

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if is_instance_valid(Util.get_player()):
		%DefeatedBy.text = "Defeated by %s" % Util.get_player().last_damage_source
	Engine.time_scale = 1.0
	get_tree().paused = true
	root.modulate.a = 0.0

	seed_label.set_text("Seed: %s" % [RNG._str_seed if RNG._str_seed else str(RNG.base_seed)])
	seed_button.mouse_entered.connect(_hover_seed_label)
	seed_button.mouse_exited.connect(_stop_hover_seed_label)
	seed_button.pressed.connect(_seed_label_clicked)

	toon = load("res://objects/toon/toon.tscn").instantiate()
	node_viewer.add_child(toon)
	toon.drop_shadow.queue_free()
	var dna: ToonDNA
	if not is_instance_valid(Util.get_player()):
		dna = ToonDNA.new()
		dna.randomize_dna()
	else:
		dna = Util.get_player().toon.toon_dna
		Util.get_player().hide()

	toon.construct_toon(dna)
	toon.set_animation('lose')
	toon.rotation_degrees.y = 210.0
	toon.anim_seek(3.68, true)
	get_tree().create_timer(0.05).timeout.connect(toon.anim_pause)
	toon.set_eyes(Toon.Emotion.SAD)

	Sequence.new([
		LerpProperty.new(root, ^"modulate:a", 1.0, 1.0).interp(Tween.EASE_IN, Tween.TRANS_QUAD)
	]).as_tween(self)
	# Pitch scale doesn't work on interactives for some reason!!! Improvised replacement!!!
	if AudioManager.current_music is AudioStreamInteractive:
		AudioManager.stop_music()
		AudioManager.play_sound(load("res://audio/music/boss_lost.ogg"))
	else:
		AudioManager.tween_music_pitch(2.0, 0.4)
		AudioManager.play_sound(SFX_LOSE)

	await get_tree().process_frame
	node_viewer.remove_child(toon)
	await get_tree().process_frame
	node_viewer.node = toon

func play_again() -> void:
	s_choice_made.emit(MenuChoice.PLAY_AGAIN)

func exit() -> void:
	s_choice_made.emit(MenuChoice.BACK_TO_MENU)

func _exit_tree() -> void:
	get_tree().paused = false
	AudioManager.reset_music_pitch()

var _seed_ival: ActiveInterval

func _hover_seed_label() -> void:
	HoverManager.hover("Click to copy seed")
	_seed_ival = LerpProperty.setup(seed_label, ^"self_modulate", 0.15, Color(0.4, 1, 1, 1)).interp(Tween.EASE_OUT, Tween.TRANS_QUAD).start(self)

func _stop_hover_seed_label() -> void:
	HoverManager.stop_hover()
	_seed_ival = LerpProperty.setup(seed_label, ^"self_modulate", 0.15, Color.WHITE).interp(Tween.EASE_OUT, Tween.TRANS_QUAD).start(self)

func _seed_label_clicked() -> void:
	DisplayServer.clipboard_set(RNG._str_seed)
	HoverManager.hover("Seed copied!")
	AudioManager.play_sound(load("res://audio/sfx/ui/GUI_balloon_popup.ogg"), 10.0)
	seed_label.self_modulate = Color.ORANGE
	_seed_ival = LerpProperty.setup(seed_label, ^"self_modulate", 0.6, Color(0.4, 1, 1, 1)).start(self)
