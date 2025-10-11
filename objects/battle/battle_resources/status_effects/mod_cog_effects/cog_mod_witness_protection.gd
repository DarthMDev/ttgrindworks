@tool
extends StatusEffect


func apply() -> void:
	manager.battle_ui.get_node('CogPanels').child_entered_tree.connect(hide_hps)

func get_cog_panels() -> Array[Node]:
	return manager.battle_ui.get_node('CogPanels').get_children()

func hide_hps(_child) -> void:
	for panel in get_cog_panels():
		panel.hp_hidden = true

func cleanup() -> void:
	manager.battle_ui.get_node('CogPanels').child_entered_tree.disconnect(hide_hps)
