extends Label


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hide()
	update_text()
	Util.s_floor_number_changed.connect(update_text)
	Util.s_floor_started.connect(func(_x=null): show())
	Util.s_floor_ended.connect(func(_x=null): hide())
	BattleService.s_battle_started.connect(func(_x=null): hide())
	BattleService.s_battle_ended.connect(func(_x=null): if Util.floor_number != -1: show())

func update_text() -> void:
	if Util.floor_number == 0:
		text = 'Ground Floor'
	else:
		if Util.floor_manager:
			text = "Floor " + str(Util.floor_number) + " " + Util.floor_manager.floor_variant.floor_name
		else: text = 'Floor %s' % Util.floor_number 
