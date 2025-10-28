extends Resource
class_name BattleAction

enum ActionTarget {
	ENEMY,
	ALLY,
	ENEMIES,
	ALLIES,
	SELF,
	NONE,
	ALLY_SPLASH,
	ENEMY_SPLASH,
}
@export var target_type := ActionTarget.ENEMY
@export var action_name: String = "Attack"
@export var one_time_use := false
@export var crit_chance_mod := 1.0
@export var action_tags: Array[ActionTag] = []

var user: Node3D
var targets := []
## Used for splash attacks
var main_target
static var camera_angles = {
	SIDE_RIGHT = Transform3D(Basis(Vector3(-0, 0, -1), Vector3(0, 1, 0), Vector3(1, 0, -0)), Vector3(6, 2, 1)),
	SIDE_LEFT = Transform3D(Basis(Vector3(-0, 0, 1), Vector3(0, 1, 0), Vector3(-1, 0, 0)), Vector3(-6, 2, 1)),
	TOON_FOCUS = Transform3D(Basis(Vector3(-0.906308, 0, -0.422618), Vector3(-0.185264, 0.898794, 0.397299), Vector3(0.379847, 0.438371, -0.814584)), Vector3(2, 2.5, -0.5)),
	AERIAL_COGS = Transform3D(Basis(Vector3(1,0,0), Vector3(0, 0.939693, -0.34202), Vector3(0, 0.34202, 0.939693)), Vector3(0,4,5))
}

## Allow to mark actions as ignored for special action checks, i.e. retaliates from bosses.
var special_action_exclude := false
## Allow moves to set a custom message for when a player gets merc'ed by it
var custom_player_death_source := ""
## Does no damage + Battle text will say "Nullified"
var nullified := false:
	set(x):
		if not ActionTag.NULLIFY_DISABLED in action_tags:
			nullified = x
		else:
			nullified = false

## Some actions will store boost text to be activated once manager.affect_target is called.
var stored_boost_text := []
var all_boost_text := []

# Given to the action by the battle manager
# Allows referencing the manager within action scripts
var manager: BattleManager

# Reference to battle node
var battle_node: BattleNode

# Returns whether or not the actor is animating
func actor_is_animating(actor: Node3D) -> bool:
	if not actor or not 'animator' not in actor or not actor.animator:
		return false
	return not actor.animator.current_animation == 'neutral'

# Sets the camera angle in battle
func set_camera_angle(angle: String) -> void:
	## Reparent if necessary to
	if manager.battle_node.battle_cam.get_parent() != manager.battle_node:
		manager.battle_node.battle_cam.reparent(manager.battle_node)
	var new_angle: Transform3D
	if battle_node.override_camera_angles.keys().has(angle):
		new_angle = battle_node.override_camera_angles[angle]
	else:
		new_angle = camera_angles[angle]
	manager.battle_node.battle_cam.transform = new_angle

func reassess_splash_targets(selection: int, _manager: BattleManager) -> void:
	if target_type != ActionTarget.ENEMY_SPLASH:
		return
	var new_targets: Array = [_manager.cogs[selection]]
	main_target = _manager.cogs[selection]
	var indices: Array = []
	if selection == 0:
		# Far left selection, extend our range to the right
		indices = [1, 2]
	elif selection == _manager.cogs.size() - 1:
		indices = [-1, -2]
		# Far right selection, extend our range to the left
	else:
		# Regular selection, range to the left and right
		indices = [-1, 1]

	# Now apply the indices
	for idx: int in indices:
		var adjust_idx: int = selection + idx
		if adjust_idx < 0 or adjust_idx >= _manager.cogs.size():
			continue
		new_targets.append(_manager.cogs[adjust_idx])
	# Now set the targets!
	targets = new_targets

func store_boost_text(text: String, color: Color) -> void:
	stored_boost_text.append([text, color])
	all_boost_text.append([text, color])

func contains_boost_text(text: String) -> bool:
	for boost_text_arr: Array in all_boost_text:
		if boost_text_arr[0] == text:
			return true

	return false


#region Tags

enum ActionTag {
	NULLIFY_DISABLED, # Added to actions that cannot be nullified
	IS_DEFLECT_ATTACK,
	DOUBLE_REVIVE_DAMAGE,  # Does two revive-damage to characters who only have revives
	OLDMAN_NULLIFY,
	PRIORITY_ACTION, # Marks an action as being high priority for a few scripts that need it
}

func has_tag(tag: ActionTag) -> bool:
	return tag in action_tags

func add_tag(tag: ActionTag) -> void:
	action_tags.append(tag)

func remove_tag(tag: ActionTag) -> void:
	if tag in action_tags:
		action_tags.erase(tag)

#endregion
