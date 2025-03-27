extends Control
@onready var Buttons = %Buttons
var general_button = load("res://objects/general_ui/general_button/general_button.tscn")

# we will add general buttons for each effect in effects/effects.tres
func _ready():
	get_tree().paused = true
	# unlock the mouse
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	var effects = load("res://effects/effects.tres")
	for effect in effects.effects:
		var new_button = general_button.instantiate()
		new_button.text = effect.display_name
		# make the button's custom minimum size 230 x 100 px
		new_button.custom_minimum_size = Vector2(230, 100)
		new_button.pressed.connect(_on_button_pressed.bind(effect)) 
		Buttons.add_child(new_button)

func _on_button_pressed(effect: CCEffect) -> void:
	CrowdControl.test_effect(effect)

func _physics_process(_delta : float) -> void:
	if Input.is_action_just_pressed("test_effects"):
		resume()    

func resume() -> void:
	get_tree().paused = false
	queue_free()
