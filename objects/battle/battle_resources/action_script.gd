extends BattleAction
class_name ActionScript

## Override this method to run your battle movie
func action():
	pass

func create_tween() -> Tween:
	return manager.create_tween()
