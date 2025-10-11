extends Resource
class_name AudioSnippet

@export var stream: AudioStream
@export var start_time := 0.0
@export var end_time := -1.0

func play() -> void:
	AudioManager.play_snippet(stream,start_time,end_time)
