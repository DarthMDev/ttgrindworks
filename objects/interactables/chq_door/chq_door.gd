extends Node3D
class_name CogDoor

## Config
@export var monitoring := true

## Child References
@onready var door_top := $Doorway1/doortop
@onready var door_bottom := $Doorway1/doorbottom
@onready var door_left := $Doorway1/doorLeft
@onready var door_right := $Doorway1/doorRight
@onready var sfx_slide := $SlideSFX
@onready var sfx_latch := $LatchSFX
@onready var sfx_unlock := $UnlockSFX

## Locals
var locks := 0
var max_locks := 3
var can_open := true
var open_tween : Tween

## Signals
signal s_unlocked


func body_entered(body : Node3D) -> void:
	if body is Player:
		player_entered()

func player_entered() -> void:
	if locks == 0 and can_open and monitoring:
		open()

func add_lock() -> void:
	$Doorway1/Locks.get_child(locks).show()
	locks+=1

func unlock() -> void:
	locks-=1
	if locks == 0: s_unlocked.emit()
	sfx_unlock.play()
	var lock := $Doorway1/Locks.get_child(locks)
	var unlock_tween := create_tween()
	unlock_tween.set_parallel(true)
	unlock_tween.set_trans(Tween.TRANS_QUAD)
	for side in ['Front','Back']:
		# Show Open Hands
		lock.get_node(side+'/HandShake').hide()
		lock.get_node(side+'/ArmLeft/OpenHand').show()
		lock.get_node(side+'/ArmRight/OpenHand').show()
		
		# Slide arms off to side
		unlock_tween.tween_property(lock.get_node(side+'/ArmLeft'),'position:x',-85,2.0)
		unlock_tween.tween_property(lock.get_node(side+'/ArmRight'),'position:x',85,2.0)
	
	# Hide lock after finish
	await unlock_tween.finished
	lock.hide()

## Opens the door
func open() -> void:
	# Stop any currently running open tween
	if open_tween and open_tween.is_valid():
		open_tween.kill()
	
	# Disallow door opening at beginning
	can_open = false
	
	
	# Create opening tween
	open_tween = create_tween()
	open_tween.set_trans(Tween.TRANS_QUAD)
	
	# Open Top/Bottom
	open_tween.tween_property(door_bottom,'position:y',-70,2.0)
	open_tween.set_parallel(true)
	open_tween.tween_property(door_top,'position:y',70,2.0)
	
	# Open Left/Right
	open_tween.tween_property(door_left,'position:x',-70,2.0)
	open_tween.tween_property(door_right,'position:x',70,2.0)
	open_tween.set_parallel(false)
	
	# Wait 4 sec
	open_tween.tween_interval(4.0)
	
	# Close Left/Right
	open_tween.tween_property(door_left,'position:x',0,2.0)
	open_tween.set_parallel(true)
	open_tween.tween_property(door_right,'position:x',0,2.0)
	
	# Close Top/Bottom
	open_tween.tween_property(door_bottom,'position:y',0,2.0)
	open_tween.set_parallel(true)
	open_tween.tween_property(door_top,'position:y',0,2.0)
	
	# Run audio track
	open_audio(-1)
	open_tween.step_finished.connect(open_audio)

## Audio timing for door open
func open_audio(step : int) -> void:
	if step%2==0:
		sfx_slide.stop()
		sfx_latch.play()
		if step == 2: can_open = true
	else:
		sfx_slide.play()

func connect_button(button : CogButton) -> void:
	add_lock()
	button.s_pressed.connect(unlock.unbind(1))

func skip_tween() -> void:
	if open_tween and open_tween.is_running():
		open_tween.custom_step(1000.0)
