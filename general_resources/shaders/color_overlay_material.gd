@tool
extends ShaderMaterial
class_name ColorOverlayMaterial

const SHADER = preload("res://general_resources/shaders/color_overlay.gdshader")

@export var test_color: Color = Color.WHITE
@export var test_time: float = 0.15
@export var test_strength: float = 0.75

@warning_ignore("unused_private_class_variable")
@export var _test_flash: bool:
	set(x):
		if Engine.is_editor_hint() and x:
			# Prevent annoying compilation issue
			var editor_interface = Engine.get_singleton("EditorInterface")
			flash(editor_interface.get_edited_scene_root(), test_color, test_time, test_strength)

var _flash_tween: Tween:
	set(x):
		if _flash_tween and _flash_tween.is_valid():
			_flash_tween.kill()
		_flash_tween = x

var strength: float:
	get: return get_shader_parameter(&"strength")
	set(x): set_shader_parameter(&"strength", x)
var color: Color:
	get: return get_shader_parameter(&"color") as Color
	set(x): set_shader_parameter(&"color", x)

func _init() -> void:
	shader = SHADER
	strength = 0.0

func flash(owner: Node, _color := Color.RED, time := 0.15, _strength := 0.6) -> void:
	_flash_tween = Sequence.new([
		Func.new(set_color.bind(_color)),
		Func.new(set_strength.bind(0.0)),
		LerpFunc.new(set_strength, time * 0.5, 0.0, _strength).interp(Tween.EASE_IN, Tween.TRANS_LINEAR),
		LerpFunc.new(set_strength, time * 0.5, _strength, 0.0).interp(Tween.EASE_OUT, Tween.TRANS_LINEAR),
	]).as_tween(owner)

func flash_instant(owner: Node, _color := Color.RED, time := 0.15, _strength := 0.6) -> void:
	_flash_tween = Sequence.new([
		Func.new(set_color.bind(_color)),
		Func.new(set_strength.bind(_strength)),
		Wait.new(time),
		Func.new(set_strength.bind(0.0)),
	]).as_tween(owner)

func flash_instant_fade(owner: Node, _color := Color.RED, time := 0.15, _strength := 0.6) -> void:
	_flash_tween = Sequence.new([
		Func.new(set_color.bind(_color)),
		Func.new(set_strength.bind(_strength)),
		LerpFunc.new(set_strength, time, _strength, 0.0).interp(Tween.EASE_IN, Tween.TRANS_CUBIC),
	]).as_tween(owner)

func fade_in(owner: Node, _color := Color.RED, time := 0.15, _strength := 0.6) -> void:
	_flash_tween = Sequence.new([
		Func.new(set_color.bind(_color)),
		LerpFunc.new(set_strength, time, 0.0, _strength).interp(Tween.EASE_IN, Tween.TRANS_CUBIC),
	]).as_tween(owner)

func fade_out(owner: Node, _color := Color.RED, time := 0.15) -> void:
	_flash_tween = Sequence.new([
		Func.new(set_color.bind(_color)),
		LerpFunc.new(set_strength, time, strength, 0.0).interp(Tween.EASE_IN, Tween.TRANS_CUBIC),
	]).as_tween(owner)

func clear_strength() -> void:
	_flash_tween = null
	set_strength(0.0)

func set_strength(_strength: float) -> void:
	strength = _strength

func set_color(_color: Color) -> void:
	color = _color

func apply_to_node(node: Node) -> void:
	for mesh: MeshInstance3D in NodeGlobals.get_children_of_type(node, MeshInstance3D, true):
		if not mesh.material_overlay: mesh.material_overlay = self
