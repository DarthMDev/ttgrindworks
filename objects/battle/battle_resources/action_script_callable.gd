extends ActionScript
class_name ActionScriptCallable

var damage := 0

var callable : Callable

func action() -> void:
	await callable.call()
