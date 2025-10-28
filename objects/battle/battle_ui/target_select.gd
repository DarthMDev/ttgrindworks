extends TextureRect

const ARROW_NORM := preload("res://ui_assets/battle/target_select/PckMn_Arrow_Up.png")
const ARROW_RED := preload("res://ui_assets/battle/target_select/PckMn_Arrow_Up_RED.png")

# Child references
@onready var arrow := $Buttons/Arrows/ArrowButton

# Signals
signal s_arrow_pressed(index: int)

# Locals
var gag: ToonAttack

func reposition_buttons(cogs: int):
	for i in cogs:
		var newbutton: GeneralButton
		if i == 0:
			newbutton = arrow
		else:
			newbutton = arrow.duplicate()
			$Buttons/Arrows.add_child(newbutton)
		newbutton.pressed.connect(arrow_pressed.bind(i))
		newbutton.mouse_entered.connect(on_arrow_hovered.bind(i))
		newbutton.mouse_exited.connect(on_arrow_unhovered.bind(i))
		newbutton.disabled = false
		
		var cog: Cog = get_parent().get_parent().cogs[i]
		if gag.target_type == BattleAction.ActionTarget.ENEMY_SPLASH:
			%TargetCenterLabel.text = "Which Cogs?"
		else:
			%TargetCenterLabel.text = "Which Cog?"
		if gag is LureFish and cog.lured:
			newbutton.disabled = true
		elif gag is GagTrap:
			if (Util.get_player().trap_needs_lure and cog.lured) or cog.trap:
				newbutton.disabled = true
			else:
				newbutton.disabled = false
	
	$GagPanel/GagImage.set_texture(gag.icon)
	$GagPanel.self_modulate = Globals.get_gag_color(gag)

func reset_buttons():
	for i in range($Buttons/Arrows.get_child_count()-1,0,-1):
		$Buttons/Arrows.get_child(i).queue_free()
	arrow.disconnect('pressed',arrow_pressed)
	arrow.mouse_entered.disconnect(on_arrow_hovered)
	arrow.mouse_exited.disconnect(on_arrow_unhovered)

func arrow_pressed(index : int):
	s_arrow_pressed.emit(index)
	reset_buttons()

func on_arrow_hovered(index : int) -> void:
	if not gag.target_type == BattleAction.ActionTarget.ENEMY_SPLASH:
		return
	
	for button in get_neighbors(index):
		button.texture_normal = ARROW_RED

## Returns splash neighbors
func get_neighbors(index : int) -> Array[GeneralButton]:
	var neighbors : Array[GeneralButton] = []
	var button_container : HBoxContainer = $Buttons/Arrows
	
	if index == 0:
		var i := 1
		while i < button_container.get_child_count() and i < 3:
			neighbors.append(button_container.get_child(i))
			i += 1
	elif index == button_container.get_child_count() - 1:
		var i := button_container.get_child_count() - 2
		while i >= 0 and i > button_container.get_child_count() - 4:
			neighbors.append(button_container.get_child(i))
			i -= 1
	else:
		neighbors.append(button_container.get_child(index - 1))
		neighbors.append(button_container.get_child(index + 1))
	
	return neighbors

func on_arrow_unhovered(_index : int) -> void:
	for button : GeneralButton in $Buttons/Arrows.get_children():
		button.texture_normal = ARROW_NORM
