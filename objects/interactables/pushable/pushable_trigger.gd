@tool
extends Area3D

@export var pushable: PushableComponent
@export_custom(PROPERTY_HINT_LINK, '') var trigger_size: Vector3 = Vector3(0.1, 3, 0.1):
	set(new):
		trigger_size = new
		await NodeGlobals.until_ready(self)
		var collision: CollisionShape3D = $CollisionShape3D
		collision.shape.size = trigger_size
		collision.position.y = trigger_size.y / 2.0
		$DebugLabel.position.y = trigger_size.y + 0.5
		
signal pushable_entered

func _ready():
	if not Engine.is_editor_hint():
		$DebugLabel.hide()
		area_entered.connect(_on_area_entered)
		
func _on_area_entered(area: Area3D):
	print('area entered %s' % area)
	if area == pushable:
		pushable_entered.emit()
