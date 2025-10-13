@tool
extends "res://models/props/stranger/stranger_model.gd"

## im so sorry im so sorry im so sorry im so sorry im so sorry im so sorry
## (this model was a nightmare)

func set_animation(anim: String) -> void:
	if animator.has_animation(anim):
		animator.play(anim)
		%JustForScopesSmile.get_node('AnimationPlayer').play(anim)
	else:
		printerr("ERR: No animation: %s in Stranger's AnimationPlayer" % anim)

func scopes_recede() -> void:
	animator.play_backwards('intro')
	%JustForScopesSmile.get_node('AnimationPlayer').play_backwards('intro')
	animator.animation_finished.connect(on_recede_finish, CONNECT_ONE_SHOT)
