extends Node3D
class_name MoltenWaterBucket

signal s_collected

var used := false

func body_entered(body: Node3D) -> void:
	if body is Player and not used:
		player_entered()

func player_entered() -> void:
	used = true
	s_collected.emit()
	%Bucket.hide()
	var splat: Sprite3D = load("res://objects/battle/effects/splat/splat.tscn").instantiate()
	add_child(splat)
	#splat.position.y = %SplashPos.position.y
	splat.set_text("SPLASH!")
	splat.modulate = Globals.SQUIRT_COLOR
	AudioManager.play_sound(load("res://audio/sfx/battle/gags/squirt/AA_squirt_seltzer.ogg"))
	await Task.delay(2.0)
	queue_free()

func _ready() -> void:
	var spinny_tween := create_tween().set_loops()
	spinny_tween.tween_property(%Bucket, 'rotation_degrees:y', 359.9, 2.0)
	spinny_tween.tween_property(%Bucket, 'rotation_degrees:y', 0.0, 0.0)
