extends Control

@onready var prog_bar: TextureProgressBar = %ProgBar
@onready var dial: TextureRect = %Dial

@onready var cog_marker_x: float = %CogMarker.position.x
@onready var toon_marker_x: float = %ToonMarker.position.x
@onready var dial_y: float = %Dial.position.y

@onready var red_bulb: ShaderMaterial = %RedBulb/Lit.material
@onready var green_bulb: ShaderMaterial = %GreenBulb/Lit.material

@export var tween_speed: float = 0.25
var max_value: int
var tween: Tween

func setup(total_shapes : int, triangles : int) -> void:
	#prog_bar.max_value = total_shapes
	max_value = total_shapes
	set_value(triangles)

func set_value(value: float) -> void:
	var new_x := remap(value, 0, max_value, cog_marker_x, toon_marker_x)
	var red_bulb_brightness := remap(max_value - value, 0, max_value, 0, 0.5)
	var green_bulb_brightness := remap(value, 0, max_value, 0, 0.5)
	
	if tween:
		tween.kill()
	tween = create_tween().set_parallel(true)
	tween.tween_property(dial, 'position', Vector2(new_x, dial_y), tween_speed)
	tween.tween_method(
		set_bulb_brightness.bind(red_bulb), 
		red_bulb.get_shader_parameter('radius'),
		red_bulb_brightness,
		tween_speed
	)
	tween.tween_method(
		set_bulb_brightness.bind(green_bulb), 
		green_bulb.get_shader_parameter('radius'),
		green_bulb_brightness,
		tween_speed
	)
	
func set_bulb_brightness(brightness: float, bulb: ShaderMaterial):
	bulb.set_shader_parameter('radius', brightness)

func update_labels(value : float) -> void:
	var triangles := roundi(value)
	var squares := roundi(prog_bar.max_value) - triangles
	%TriangleLabel.set_text(str(triangles))
	%SquareLabel.set_text(str(squares))
