extends "old_stomper.gd"

var troll_stomps := 0
var looping = false
var total_stomps := 0
var telegraphing = false

func initiate_kill(body: Node3D) -> void:
	if looping == false:
		looping = true
		print(total_stomps)
		delay_timer.wait_time = 0.3
		while troll_stomps < total_stomps:
			do_stomp()
			troll_stomps = troll_stomps + 1
			delay_timer.start()
			await delay_timer.timeout
		if troll_stomps == total_stomps:
			troll_stomps = troll_stomps + 1
			raise_position = 2.5
			raise_time = 8
			do_stomp()

func stop_stomper(body: Node3D) -> void:
	pass
	


func telegraph(body: Node3D) -> void:
	if not telegraphing:
		telegraphing = true
		var stomp_tween := create_tween()
		stomp_tween.tween_property(model, 'position:y', 1.5, 0.4)
		stomp_tween.tween_callback(play_sfx.bind(stomp_sfx))
