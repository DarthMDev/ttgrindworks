extends HBoxContainer

## References to the selected gag panels
var panels: Array[TextureRect] = []
var paneleffects = {}
var itemeffects = {}
@onready var item_panel = $"../BattleMenuContainer/BottomRight/SOS"
## The base gag panel
@onready var gag_panel := $SelectedGag
@onready var battle_ui : BattleUI = get_parent()
@onready var manager: BattleManager = NodeGlobals.get_ancestor_of_type(self, BattleManager)

var current_gags: Array[ToonAttack] = []

## Signals the gag index to cancel
signal s_gag_canceled(index : int)


## Find the proper amount of gag panels to have on startup
func _ready():
	# Add the first gag panel to the array
	panels.append(gag_panel)
	configure_panel(gag_panel)
	update_panels()

func configure_panel(panel) -> void:
	panel.get_node('GagIcon').mouse_entered.connect(hover_slot.bind(panels.find(panel)))
	panel.get_node('GagIcon').mouse_exited.connect(stop_hover)
	panel.get_node('GeneralButton').disabled = true
	panel.get_node('GeneralButton').hide()
	panel.get_node('GeneralButton').pressed.connect(cancel_gag.bind(panels.find(panel)))
		
func update_panels() -> void:
	# Amount of panels is based on Player turns (-1)
	#item_panel.disable()
	var panels_to_make: int = manager.battle_stats[Util.get_player()].turns - panels.size()
	if panels_to_make > 0:
		# Append the panels
		for i in panels_to_make:
			var panel = gag_panel.duplicate()
			reset_panel(panel)
			add_child(panel)
			panels.append(panel)
		for i in Util.get_player().stats.turns:
			paneleffects[i] = 1
		battle_ui.s_damage_drifted.connect(reset_panel_effects)
		battle_ui.s_item_effect.connect(reset_item_effects)		
		# X Button configuration
		for i in range(panels.size() - panels_to_make, panels.size()):
			configure_panel(panels[i])
			
	# definitely not complete negative support
	if panels_to_make < 0:
		for i in abs(panels_to_make):
			panels.pop_back().queue_free()
		

func append_gag(gag: ToonAttack) -> void:
	# Add the icon to the gag panels
	for panel in panels:
		var icon: TextureRect = panel.get_node('GagIcon')
		if not icon.texture:
			icon.texture = gag.icon
			break
	
	# Enable/Disable x buttons
	for panel in panels:
		panel.get_node('GeneralButton').disabled = not panel.get_node('GagIcon').texture
		panel.get_node('GeneralButton').visible = not panel.get_node('GeneralButton').disabled

## Reset all panels
func reset_panel(panel) -> void:
		panel.self_modulate = Color(1, 1, 1, 1)
		panel.get_node('GagIcon').texture = null
		panel.get_node('GeneralButton').disabled = true
		panel.get_node('GeneralButton').hide()

func on_round_start(_gag_order: Array[ToonAttack]) -> void:
	for panel in panels:
		reset_panel(panel)

func cancel_gag(index: int):
	s_gag_canceled.emit(index)

func refresh_gags(gags: Array[ToonAttack]):
	current_gags = gags
	for i in panels.size():
		var panel = panels[i]
		if i < gags.size():
			panel.get_node('GagIcon').texture = gags[i].icon
			panel.get_node('GeneralButton').disabled = false
		else:
			panel.get_node('GagIcon').texture = null
			panel.get_node('GeneralButton').disabled = true
		panel.get_node('GeneralButton').visible = not panel.get_node('GeneralButton').disabled

func hover_slot(idx: int) -> void:
	if (not current_gags) or current_gags.size() - 1 < idx:
		if not paneleffects[idx] != 1 and not itemeffects.has(idx):
			return
	
	#manager.s_gag_modified.connect(color_panels) #idk man %5
	var atk_string: String = ""
	if itemeffects.has(idx):
		for effect in itemeffects[idx]:
			atk_string += effect["desc"]
			atk_string += "\n"	
			
	if paneleffects.has(idx) and paneleffects[idx] != 1:
		#if paneleffects[idx] == 1 and not itemeffects.has(idx):
			#return
		if paneleffects[idx] > 1:
			atk_string += "Gag damage on this turn is boosted by " + str(paneleffects[idx] * 100) + "%"
		elif paneleffects[idx] < 1: atk_string += "Gag damage on this turn is reduced to " + str(paneleffects[idx] * 100) + "%"
	if  not ((not current_gags) or current_gags.size() - 1 < idx):
		var gag: ToonAttack = current_gags[idx]
		var has_main_target: bool = gag.main_target != null
		if paneleffects[idx] != 1:
			atk_string += "\n"
		for cog in manager.cogs:
			if cog in gag.targets:
				atk_string += "X" if ((not has_main_target) or (has_main_target and cog == gag.main_target)) else "x"
			else:
				atk_string += "-"
			if manager.cogs.find(cog) < manager.cogs.size() - 1:
				atk_string += " "
	HoverManager.hover(atk_string, 20, 0.0125)
	
func reset_panel_effects(dict: Dictionary) -> void:
	for idx in dict.keys():
		paneleffects[idx] = paneleffects[idx] * dict[idx]
	color_panels()
func reset_item_effects(dict: Dictionary) -> void:
	#lets hope I don't add anymore items that do turn specfic things
	for turn in dict:
		var new_effect = dict[turn]  # Assume format: {"effect": int, "desc": str}
		var effect_type = new_effect["effect"]
		
		# Initialize turn array if it doesn't exist
		if not turn in itemeffects:
			itemeffects[turn] = []
		
		# Handle Damage Reflection stacking (effect == 2)
		if effect_type >= -1: # there will never be an effect type less then 0 im to lazy to change rn
			#PLEASE CHANGE LATER THO
			var found_existing = false
			
			# Check for existing damage reflection on this turn
			for existing_effect in itemeffects[turn]:
				if existing_effect["effect"] == new_effect["effect"]:
					if existing_effect["effect"] >= 2:
						existing_effect["value"] += new_effect["value"]
						existing_effect["desc"] = "You will be dealt %d%% of the unboosted gag damage dealt this turn" % int(existing_effect["value"] * 100)
						found_existing = true
						break
					else: 
						found_existing = true
						break
			# If no existing reflection, add new entry
			if not found_existing:
				itemeffects[turn].append(new_effect)
	
	color_panels()
func color_panels() -> void: # idk man %5
	for panel in panels:
		panel.self_modulate = Color(1, 1, 1, 1)
	for idx in paneleffects.keys():
		if paneleffects[idx] < 1:
			panels[idx].self_modulate = Color(0.5, 0.2, 0.2, 1)
			#var mat = CanvasItemMaterial.new()
			
			#mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
			#panels[idx].material = mat
		elif paneleffects[idx] > 1: panels[idx].self_modulate = Color(0.2, 0.5, 0.2, 1)
	for idx in itemeffects.keys():
		panels[idx].self_modulate *= Color(1.2, 0.6, 1.4) * 1.6
func stop_hover() -> void:
	HoverManager.stop_hover()
	
func clear_panel_effects() -> void:

	itemeffects.clear()
	for i in Util.player.stats.turns:
		paneleffects[i] = 1
