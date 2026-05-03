extends CanvasLayer

@onready var console_line: RichTextLabel = %ConsoleLine
@onready var line_container: VBoxContainer = %LineContainer
@onready var autofill: Label = %AutofillLabel
@onready var input: LineEdit = %Input


var unpause_tree := false


func _ready() -> void:
	console_print("Toontown: The Grindworks %s" % Globals.VERSION_NUMBER)
	input.grab_focus()

func on_input_sent(text: String) -> void:
	input.set_text("")
	parse_command(text)
	reset_autofill()
	get_tree().process_frame.connect(input.grab_focus, CONNECT_ONE_SHOT)

func on_input_changed(_txt: String) -> void:
	while input.text.ends_with("  "):
		input.text = input.text.trim_suffix(" ")
	input.caret_column = input.text.length()
	search_autofill()

func reset_autofill() -> void:
	autofill.set_text("")

func _process(_delta) -> void:
	if Input.is_action_just_pressed('dev_console'):
		if unpause_tree:
			get_tree().paused = false
		queue_free()
		return
	if Input.is_action_just_pressed('ui_focus_next'):
		do_autofill()

#region Autofiller
func do_autofill() -> void:
	if not autofill.text == "":
		input.set_text(autofill.text)
	input.caret_column = input.text.length()

func search_autofill() -> void:
	autofill.text = input.text
	if input.text == "":
		return
	
	for cmd in command_types:
		var fill := get_autofill(cmd)
		if not fill == "":
			autofill.set_text(fill)
			return

func get_autofill(command: Command) -> String:
	var fill := ""
	if command.get_prefix().begins_with(input.text):
		fill = command.get_prefix()
	elif input.text.begins_with(command.get_prefix() + " "):
		var argument_fills := command.get_autofills()
		var final_arg: String = input.text.split(" ")[-1]
		if not argument_fills.keys().has(command.get_arg_index(input.text)):
			return ""
		for arg: String in argument_fills[command.get_arg_index(input.text)]:
			if arg.begins_with(final_arg):
				
				fill = input.text.trim_suffix(input.text.split(" ")[-1]) + arg
				break
	return fill

#endregion

#region Console Printing

func add_console_line(line: String) -> void:
	var newline: RichTextLabel = %ConsoleLine.duplicate(true)
	newline.set_text(line)
	line_container.add_child(newline)
	newline.show()

func console_print(txt: String) -> void:
	add_console_line(txt)

#endregion

#region Command Parsing
var command_types: Array[Command] = [
	PlayerSetterCommand.new(),
	PlayerStatsSetterCommand.new(),
	GiveItemCommand.new(),
	SpawnItemCommand.new(),
	NukeCommand.new(),
	SetGagsUnlockedCommand.new(),
	ChargePrankCommand.new(),
	GhostCommand.new(),
	SetStatMinCommand.new(),
	SetStatMaxCommand.new(),
	SpeakCommand.new(),
	NextFloorCommand.new(),
	TimeScaleCommand.new(),
	OverrideNextChestItemCommand.new(),
	UnlockAchievementsCommand.new(),
	ForceSaveCommand.new(),
]

func parse_command(text: String) -> void:
	var command := find_command(text)
	text = text.trim_prefix(command.get_prefix())
	var args := text.split(" ")
	for i in range(args.size() -1, -1, -1):
		if args[i] == " " or args[i] == "":
			args.remove_at(i)
	run_command(command, args)

# Return the most matching match of the bunch
func find_command(command: String) -> Command:
	for cmd in command_types:
		if compare_prefixes(command, cmd): return cmd
	return InvalidCommand.new()

func compare_prefixes(txt: String, command: Command) -> bool:
	var true_prefix := command.get_prefix()
	if txt.begins_with(true_prefix):
		return true
	return false

func run_command(cmd: Command, args: Array) -> void:
	cmd.s_print.connect(console_print)
	cmd._attempt_run(args)
	cmd.s_print.disconnect(console_print)

#endregion

#region Command Types

class Command:
	# Overrides
	func get_prefix() -> String:
		return ""
	
	func get_args() -> Dictionary[String, String]:
		return {}
	
	func needs_subject() -> bool:
		return false
	
	func get_subject() -> Object:
		return null
	
	func get_subject_title() -> String:
		return ""
	
	func run(_args: Array):
		error_custom("Nop")
	
	func get_command_name() -> String:
		return "command"
	
	func get_autofills() -> Dictionary[int, Array]:
		return {}
	
	func get_arg_index(cmd: String) -> int:
		cmd = cmd.trim_prefix(get_prefix())
		return cmd.split(" ").size() - 1
	
	# DO NOT OVERRIDE
	func _attempt_run(args: Array) -> void:
		args = _parameter_split(args)
		if not args.size() == get_args().keys().size():
			error(ConsoleError.INSUFFICIENT_PARAMETER_COUNT)
			return
		elif not _parameter_check(args) == -1:
			error_custom(format_error(ERROR_FORMAT[ConsoleError.INVALID_TYPE] % _parameter_check(args)))
			return
		elif needs_subject() and get_subject() == null:
			error(ConsoleError.SUBJECT_DOESNT_EXIST)
			return
		run(args)
	
	func _parameter_split(args: Array) -> Array:
		if args.is_empty(): return []
		# This line is awesome
		if get_args()[get_args().keys()[get_args().size() - 1]] == STRING_TYPE:
			var pre_final_arg_count := get_args().size() - 2
			var final_arg := ""
			for arg in args.duplicate(true):
				if args.find(arg) < pre_final_arg_count:
					continue
				final_arg += " " + arg
				args.erase(arg)
			args.append(final_arg.trim_prefix(" "))
		return args
	
	func _parameter_check(args: Array) -> int:
		for param in args:
			var argnum := args.find(param)
			var intended_type := get_args()[get_args().keys()[argnum]]
			var typed_param = cast_value(param, intended_type)
			if not _validate_parameter(param, typed_param, intended_type):
				return args.find(param)
		return -1
	
	func _validate_parameter(string, casted, type) -> bool:
		match type:
			INT_TYPE: return int(string) == casted
			FLOAT_TYPE: return is_equal_approx(float(string), casted)
			VARIANT_TYPE:
				return true
		
		return str(casted) == string
	
	# Error/Print Signaling
	signal s_print(string: String)
	
	func submit_print(string: String) -> void:
		s_print.emit(string)
	
	func error(err: ConsoleError) -> void:
		submit_print(format_error(ERROR_FORMAT[err]))
	
	func error_custom(err_string: String) -> void:
		submit_print(format_error(err_string))
	
	func format_error(err_string: String) -> String:
		err_string = err_string.replace("~~cn", get_command_name())
		err_string = err_string.replace("~~s", get_subject_title())
		err_string = "[color=red]ERROR: " + err_string
		return err_string
	
	# Common Errors
	enum ConsoleError {
		INVALID_SYNTAX,
		INSUFFICIENT_PARAMETER_COUNT,
		INVALID_TYPE,
		SUBJECT_DOESNT_EXIST,
	}
	
	const ERROR_FORMAT: Dictionary[ConsoleError, String] = {
		ConsoleError.INVALID_SYNTAX: "Invalid Syntax for ~~cn",
		ConsoleError.INSUFFICIENT_PARAMETER_COUNT: "Insufficient parameter count for ~~cn",
		ConsoleError.INVALID_TYPE: "Invalid type of argument%d for ~~cn",
		ConsoleError.SUBJECT_DOESNT_EXIST: "Cannot run ~~cn because ~~s does not exist."
	}
	
	# Typing
	func cast_value(value, type: String) -> Variant:
		match type:
			STRING_TYPE: return str(value)
			FLOAT_TYPE: return float(value)
			INT_TYPE: return int(value)
			_: return value
	
	func convert_type(value: String, type: int):
		if type == TYPE_BOOL:
			return value.to_lower() == "true"
		else:
			return type_convert(value, type)
	
	const STRING_TYPE := "_s"
	const FLOAT_TYPE := "_f"
	const INT_TYPE := "_i"
	const VARIANT_TYPE := "_v"
	const BOOL_TYPE := "_b"
	

class InvalidCommand extends Command:
	func _attempt_run(args: Array) -> void:
		var all_args := ""
		for arg in args: all_args += arg + " "
		error_custom("Invalid Command: %s." % all_args)

class SetterCommand extends Command:
	func get_prefix() -> String:
		return "set %s" % get_subject_title()
	
	func needs_subject() -> bool:
		return true
	
	func get_args() -> Dictionary[String, String]:
		return {
			"property" : STRING_TYPE,
			"value" : VARIANT_TYPE,
		}
	
	func get_autofills() -> Dictionary[int, Array]:
		return {1: get_trimmed_property_list()}
	
	func run(args: Array) -> Array:
		var arg: String = args[1]
		var property_name = args[0]
		if not args[0] in get_subject():
			error_custom("~~cn: No property %s in %s." % [args[0], get_subject_title()])
			return []
		var property = get_subject().get(args[0])
		var casted_arg = convert_type(arg, typeof(property))
		var invalid_type := false
		match typeof(property):
			TYPE_FLOAT: invalid_type = not arg.is_valid_float()
			TYPE_INT: invalid_type = not arg.is_valid_float()
		if invalid_type:
			error_custom("~~cn: Invalid typing of argument 1.")
			return []
		get_subject().set(property_name, casted_arg)
		submit_print("%s set to %s on %s." % [property_name, str(casted_arg), get_subject_title()])
		return [property_name, casted_arg]
	
	func get_trimmed_property_list() -> Array[String]:
		if not get_subject(): return []
		var arr: Array[String] = []
		for dict in get_subject().get_property_list():
			var prop = get_subject().get(dict['name'])
			if prop is GDScript or prop is Resource:
				continue
			arr.append(dict['name'])
		return arr

class PlayerSetterCommand extends SetterCommand:
	func get_subject() -> Object:
		return Util.get_player()
	func get_subject_title() -> String:
		return "player"
	func get_trimmed_property_list() -> Array[String]:
		return [
			"see_descriptions",
			"see_anomalies",
			"random_cog_heals",
			"custom_gag_order",
			"less_shop_items",
			"better_battle_rewards",
			"no_negative_anomalies",
			"throw_heals",
			"trap_needs_lure",
			"inverted_sound_damage",
			"obscured_anomalies",
			"immune_to_light_damage",
			"immune_to_crush_damage",
			"gags_cost_beans",
			"revives_are_hp",
			"use_accuracy",
			"ignore_battles",
			"alt_gag_hotswap",
		]

class PlayerStatsSetterCommand extends SetterCommand:
	func get_subject() -> Object:
		if not is_instance_valid(Util.get_player()):
			return null
		return Util.get_player().stats
	func get_subject_title() -> String:
		return "stats"
	func run(args) -> Array:
		var results = super(args)
		if results.is_empty():
			return []
		if is_instance_valid(BattleService.ongoing_battle):
			var stats: PlayerStats = BattleService.ongoing_battle.battle_stats[Util.get_player()]
			stats.set(results[0], results[1])
		
		return []
	func get_trimmed_property_list() -> Array[String]:
		return [
			"hp",
			"max_hp",
			"damage",
			"defense",
			"evasiveness",
			"luck",
			"speed",
			"accuracy",
			"stranger_chance",
			"pink_slips",
			"quest_rerolls",
			"gag_cap",
			"crit_mult",
			"mod_cog_dmg_mult",
			"shop_discount",
			"healing_effectiveness",
			"throw_heal_boost",
			"squirt_defense_boost",
			"drop_aftershock_round_bonus",
			"trap_knockback_percent",
			"lure_fish_round_boost",
			"anomaly_boost",
			"laff_boost_boost",
			"extra_lives",
			"money",
			"active_reserve_size",
		]

class GiveItemCommand extends Command:
	func get_prefix() -> String:
		return "give item"
	func get_args() -> Dictionary[String, String]:
		return {"item_name": STRING_TYPE}
	func needs_subject() -> bool:
		return true
	func get_subject() -> Object:
		return Util.get_player()
	func get_subject_title() -> String:
		return "player"
	func run(args: Array) -> void:
		var item_name: String = args[0]
		if item_name == 'doodle':
			error_custom("Cannot give the Doodle item, as it requires the model be spawned in. Try using the 'spawn item' command.")
			return
		var item_list: PackedStringArray = ItemService.pool_from_path("res://objects/items/pools/everything.tres").items
		for path in item_list:
			if load(path).item_name.to_lower() == item_name.to_lower():
				var item: Item = load(path)
				if item.evergreen or item is ItemActive: item = item.duplicate(true)
				item.apply_item(get_subject())
				submit_print("%s applied to the player." % item_name)
				return
		error_custom("%s does not exist" % item_name)
	func get_autofills() -> Dictionary[int, Array]:
		return {1: get_item_names()}
	func get_item_names() -> Array[String]:
		var names: Array[String] = []
		var item_list: PackedStringArray = ItemService.pool_from_path("res://objects/items/pools/everything.tres").items
		for path in item_list:
			names.append(load(path).item_name.to_lower())
		return names

class SpawnItemCommand extends Command:
	func get_prefix() -> String:
		return "spawn item"
	func get_args() -> Dictionary[String, String]:
		return {"item_name": STRING_TYPE}
	func get_autofills() -> Dictionary[int, Array]:
		return {1: get_item_names()}
	func get_item_names() -> Array[String]:
		var names: Array[String] = []
		var item_list: PackedStringArray = ItemService.pool_from_path("res://objects/items/pools/everything.tres").items
		for path in item_list:
			names.append(load(path).item_name.to_lower())
		return names
	func run(args: Array) -> void:
		if not is_instance_valid(Util.get_player()):
			error_custom("Cannot spawn an item when there is no Player present!")
			return
		var item_name: String = args[0]
		var item_list: PackedStringArray = ItemService.pool_from_path("res://objects/items/pools/everything.tres").items
		for path in item_list:
			if load(path).item_name.to_lower() == item_name.to_lower():
				var world_item: WorldItem = load('res://objects/items/world_item/world_item.tscn').instantiate()
				world_item.item = load(path)
				SceneLoader.current_scene.add_child(world_item)
				world_item.global_position = Util.get_player().toon.to_global(Vector3(0, 0.6, 3.0))
				submit_print("World item of %s spawned." % load(path).item_name)
				return
		error_custom("%s does not exist." % item_name)

class OverrideNextChestItemCommand extends Command:
	func get_prefix() -> String:
		return "override_next_chest_item"
	func get_args() -> Dictionary[String, String]:
		return {"item_name": STRING_TYPE}
	func get_autofills() -> Dictionary[int, Array]:
		return {1: get_item_names()}
	func get_item_names() -> Array[String]:
		var names: Array[String] = []
		var item_list: PackedStringArray = ItemService.pool_from_path("res://objects/items/pools/everything.tres").items
		for path in item_list:
			names.append(load(path).item_name.to_lower())
		return names
	func run(args: Array) -> void:
		if not is_instance_valid(Util.get_player()):
			error_custom("Cannot spawn an item when there is no Player present!")
			return
		var item_name: String = args[0]
		var item_list: PackedStringArray = ItemService.pool_from_path("res://objects/items/pools/everything.tres").items
		for path in item_list:
			if load(path).item_name.to_lower() == item_name.to_lower():
				TreasureChest.CommandOverrideItem = load(path)
				submit_print("Next regular chest roll will be forced to %s." % load(path).item_name)
				return
		error_custom("%s does not exist." % item_name)

class NukeCommand extends Command:
	func get_prefix() -> String:
		return "nuke"
	func run(_args: Array) -> void:
		var all_fights := NodeGlobals.get_children_of_type(SceneLoader, BattleNode, true)
		for battle: BattleNode in all_fights:
			if battle.boss_battle or not battle.is_visible_in_tree() or not NodeGlobals.get_children_of_type(battle, Player).is_empty():
				continue
			for cog in battle.cogs:
				cog.lose()
			battle.call_deferred(&'set_monitoring', false)
			Task.delay(15.0).connect(battle.queue_free)
		submit_print("Destroyed all (safe) battles in the area.")

class NextFloorCommand extends Command:
	func get_prefix() -> String:
		return "next_floor"
	func get_subject() -> Object:
		return Util.floor_manager
	func needs_subject() -> bool:
		return true
	func get_subject_title() -> String:
		return "Floor Manager"
	func run(_args: Array) -> void:
		if Util.get_player().state != Player.PlayerState.WALK:
			error_custom("Cannot go to next floor while not in walk state")
			return

		if Util.get_player().stats.run_stranger_roll():
			SceneLoader.load_into_scene("res://scenes/stranger_shop/stranger_shop.tscn")
		else:
			SceneLoader.load_into_scene("res://scenes/elevator_scene/elevator_scene.tscn")

class SetGagsUnlockedCommand extends Command:
	func get_prefix() -> String:
		return "set gag level"
	func get_args() -> Dictionary[String, String]:
		return {
			"track" : STRING_TYPE,
			"level" : INT_TYPE,
		}
	func get_autofills() -> Dictionary[int, Array]:
		return {1: get_gag_tracks()}
	func run(args: Array) -> void:
		if not is_instance_valid(Util.get_player()):
			error_custom("Cannot set Gag level when there is no Player present!")
			return
		var player: Player = Util.get_player()
		var track: String = args[0].to_lower()
		if track.is_empty():
			error_custom("How did you even do that?")
		track[0] = track[0].to_upper()
		if track in player.stats.gags_unlocked.keys():
			player.stats.gags_unlocked[track] = int(args[1])
		else:
			error_custom("Player has no Gag Track: %s." % track)
			return
		submit_print("Set %s Gags unlocked to %s." % [track, args[1]])
	func get_gag_tracks() -> Array:
		if not is_instance_valid(Util.get_player()):
			return []
		return Util.get_player().stats.gags_unlocked.keys()

class ChargePrankCommand extends Command:
	func get_prefix() -> String:
		return "charge prank"
	func run(_args) -> void:
		var player := Util.get_player()
		if not is_instance_valid(player):
			error_custom("Cannot charge prank when there is no Player present!")
			return
		elif not player.stats.current_active_item:
			error_custom("Player has not prank to charge!")
			return
		player.stats.current_active_item.current_charge = player.stats.current_active_item.charge_count
		submit_print("Successfully charged the Player's current pocket prank.")

class GhostCommand extends Command:
	func get_prefix() -> String:
		return "ghost"
	func run(_args) -> void:
		if not is_instance_valid(Util.get_player()):
			error_custom("Cannot toggle ghost mode when there is no Player present!")
			return
		var player := Util.get_player()
		if player.is_invincible():
			error_custom("Cannot toggle ghost mode while Player is invincible!")
			return
		var ghosting := true
		if not player.get_collision_layer_value(2):
			ghosting = false
		player.set_collision_layer_value(2, not ghosting)
		player.set_collision_layer_value(3, not ghosting)
		submit_print("Ghost mode set to %s" % str(ghosting))

class SetStatMinCommand extends Command:
	func get_prefix() -> String:
		return "set stat min"
	func get_args() -> Dictionary[String, String]:
		return {
			"property" : STRING_TYPE,
			"minimum" : FLOAT_TYPE,
		}
	func get_subject() -> Object:
		return Util.get_player()
	func needs_subject() -> bool:
		return true
	func get_autofills() -> Dictionary[int, Array]:
		return {1: get_stats()}
	func get_stats() -> Array:
		if not is_instance_valid(Util.get_player()): return []
		return Util.get_player().stats.STAT_CLAMPS.keys()
	func run(args: Array) -> void:
		var stat: String = args[0].to_lower()
		var minimum: String = args[1]
		if not stat in get_stats():
			error_custom("%s is not clamped!" % stat)
			return
		elif not minimum.is_valid_float():
			error_custom("~~cn: Invalid typing of argument 1.")
			return
		PlayerStats.STAT_CLAMPS[stat].x = float(minimum)
		submit_print("Minimum %s set to %s." % [stat, minimum])

class SetStatMaxCommand extends Command:
	func get_prefix() -> String:
		return "set stat max"
	func get_args() -> Dictionary[String, String]:
		return {
			"property" : STRING_TYPE,
			"maximum" : FLOAT_TYPE,
		}
	func get_subject() -> Object:
		return Util.get_player()
	func needs_subject() -> bool:
		return true
	func get_autofills() -> Dictionary[int, Array]:
		return {1: get_stats()}
	func get_stats() -> Array:
		if not is_instance_valid(Util.get_player()): return []
		return Util.get_player().stats.STAT_CLAMPS.keys()
	func run(args: Array) -> void:
		var stat: String = args[0].to_lower()
		var maximum: String = args[1]
		if not stat in get_stats():
			error_custom("%s is not clamped!" % stat)
			return
		elif not maximum.is_valid_float():
			error_custom("~~cn: Invalid typing of argument 1.")
			return
		PlayerStats.STAT_CLAMPS[stat].y = float(maximum)
		submit_print("Maximum %s set to %s." % [stat, maximum])

class SpeakCommand extends Command:
	func get_prefix() -> String:
		return "speak"
	func get_args() -> Dictionary[String, String]:
		return {
			"phrase" : STRING_TYPE,
		}
	func get_subject() -> Object:
		return Util.get_player()
	func needs_subject() -> bool:
		return true
	func run(args: Array) -> void:
		var player: Player = get_subject()
		if is_instance_valid(player):
			player.speak(args[0])
			submit_print("Phrase submitted.")

class TimeScaleCommand extends Command:
	func get_prefix() -> String:
		return "timescale"
	func get_args() -> Dictionary[String, String]:
		return {"value": FLOAT_TYPE}
	func run(args: Array) -> void:
		var _time_scale: float = float(args[0])
		Engine.time_scale = _time_scale if _time_scale > 0.0 else 1.0

class UnlockAchievementsCommand extends Command:
	func get_prefix() -> String:
		return "unlock all achievements"
	func run(_args) -> void:
		for achievement in SaveFileService.progress_file.active_achievements:
			achievement.unlock()

class ForceSaveCommand extends Command:
	func get_prefix() -> String:
		return "force save"
	func run(_args) -> void:
		SaveFileService.save()

#endregion
