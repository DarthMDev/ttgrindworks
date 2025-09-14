extends ItemScript
class_name ItemSpirit

@export var spirit_purified := false:
	set(x):
		if x and !spirit_purified:
			purify()
		spirit_purified = x

@export var impure_functions: Dictionary[Callable, Signal]

func purify() -> void:
	for callable in impure_functions.keys():
		impure_functions[callable].disconnect(callable)

func connect_impure_function(c: Callable, s: Signal) -> void:
	if spirit_purified: return
	impure_functions.set(c, s)
	s.connect(c)
