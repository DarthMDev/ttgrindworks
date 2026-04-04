extends 'res://objects/items/custom/seed_logic/custom_seed_base.gd'

const POS_OFFSET := Vector3(0.0, 0.0, -0.5)

var omni_light: OmniLight3D
var interval: ActiveInterval

func setup() -> void:
	var color_rect := ColorRect.new()
	color_rect.color = Color.PURPLE
	color_rect.color.a = 0.15
	color_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(color_rect)
	omni_light = OmniLight3D.new()
	omni_light.light_color = Color.PURPLE
	omni_light.omni_range = 10.0
	add_child(omni_light)
	interval = Sequence.new([
		LerpProperty.setup(omni_light, ^'light_energy', 1.0, 5.0).interp(Tween.EASE_IN_OUT, Tween.TRANS_SINE),
		LerpProperty.setup(omni_light, ^'light_energy', 1.0, 1.0).interp(Tween.EASE_IN_OUT, Tween.TRANS_SINE),
	]).start(self).set_loops()
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF

func _process(_delta: float) -> void:
	omni_light.global_position = Util.get_player().toon.body_node.get_global_transform_interpolated().origin
	omni_light.position += POS_OFFSET.rotated(Vector3.UP, Util.get_player().toon.body_node.global_rotation.y)
