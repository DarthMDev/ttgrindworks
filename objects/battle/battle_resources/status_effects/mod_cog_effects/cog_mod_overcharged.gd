@tool
extends StatusEffect


func apply() -> void:
	var cog: Cog = target
	
	#cog.stats.damage *= 1.1
	manager.s_action_started.connect(on_action_start)
	if target.stats.hp >= target.stats.max_hp * 1.49:
		self.visible = true
	else: 
		self.visible = false

func on_action_start(action : BattleAction) -> void:
	if action.user == target:
		self.visible = true
		if target.stats.hp >= target.stats.max_hp * 1.49:
			action.damage = action.damage *1.5
		else:
				self.visible = false
		action.accuracy = Globals.ACCURACY_GUARANTEE_HIT

func cleanup() -> void:
	manager.s_action_started.disconnect(on_action_start)

func get_status_name() -> String:
	return "Overcharged"

func get_icon() -> Texture2D:
	return load("res://ui_assets/battle/statuses/Overcharged.png")
	
func renew() -> void:
		if target.stats.hp >= target.stats.max_hp * 1.49:
			self.visible = true
		else:
			self.visible = false
	
