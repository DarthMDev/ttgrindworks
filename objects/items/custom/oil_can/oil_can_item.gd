extends Node3D

## Foundational, load-bearing script that cannot be removed....

func collect() -> void:
	# Toon yell. they are scare
	AudioManager.play_sound(Util.get_player().toon.yelp)
