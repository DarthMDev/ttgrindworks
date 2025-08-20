@tool
extends StatusEffect
class_name GagJob

var color = Color.CORNFLOWER_BLUE
var arrow_indicator: Sprite3D
var _bounce_amplitude := 0.25
var _bounce_speed := 0.3
var _base_y_position := 4.0
var _bounce_tween: Tween = null
var cog: Cog
var track_name = "Squirt"
var job_met = false
var defense_boost = 0.4
@export var track: Track
const GagIcons: Dictionary = {
	"Trap": preload("res://ui_assets/battle/gags/inventory_tnt.png"),
	"Lure": preload("res://ui_assets/battle/gags/inventory_hypno_goggles.png"),
	"Sound": preload("res://ui_assets/battle/gags/inventory_fog_horn.png"),
	"Squirt": preload("res://ui_assets/battle/gags/inventory_storm_cloud.png"),
	"Throw": preload("res://ui_assets/battle/gags/inventory_cake_1.png"),
	"Drop": preload("res://ui_assets/battle/gags/inventory_piano.png"),
}
func apply() -> void:
	cog = target
	manager.append_has_moved(cog)
	if manager.cogs.size() > 1:
		await manager.remove_debuffs(cog)
	else: await manager.remove_debuffs(cog, true)
	var track_list = Util.get_player().stats.character.gag_loadout.loadout.duplicate()
	for i in range(track_list.size() - 1, -1, -1):
		var track = track_list[i]
		if target.lured and (track.track_name == "Lure" or track.track_name == "Trap"):
			track_list.remove_at(i)
			continue
		# Remove if target has a trap AND track is "Trap"
		if target.trap and track.track_name == "Trap":
			track_list.remove_at(i)
	track = RandomService.array_pick_random('true_random', Util.get_player().stats.character.gag_loadout.loadout)
	track_name = track.track_name
	description = "The foreman demands that you use %s on this cog" % track_name
	var stats : BattleStats = manager.battle_stats[cog]
	stats.defense += defense_boost
	manager.s_action_started.connect(on_action_started)
	if cog:
		show_arrow_above_cog(cog, track.track_color)

func remove() -> void:
	if target:
		hide_arrow_above_cog()

func show_arrow_above_cog(cog: Cog, color := Color.MEDIUM_PURPLE) -> void:
	if arrow_indicator and is_instance_valid(arrow_indicator):
		arrow_indicator.show()
		_start_bounce_animation()
		return
	
	# Create new arrow if one doesn't exist
	var arrow_texture = load("res://ui_assets/misc/white_arrow.png")
	arrow_indicator = Sprite3D.new()
	arrow_indicator.texture = arrow_texture
	arrow_indicator.modulate = color
	arrow_indicator.pixel_size = 0.062
	arrow_indicator.billboard = BaseMaterial3D.BILLBOARD_ENABLED

	if is_instance_valid(cog.body) and is_instance_valid(cog.body.head_node):
		cog.body.head_node.add_child(arrow_indicator)
		arrow_indicator.position = Vector3(0, _base_y_position, 0)
		arrow_indicator.show()
		_start_bounce_animation()
	else:
		push_warning("Couldn't show arrow - nametag node not ready")

func hide_arrow_above_cog() -> void:
	if arrow_indicator and is_instance_valid(arrow_indicator):
		arrow_indicator.hide()
		_stop_bounce_animation()
	arrow_indicator = null

func _start_bounce_animation() -> void:
	if _bounce_tween and _bounce_tween.is_running():
		return
	
	_bounce_tween = cog.create_tween().set_loops()
	_bounce_tween.tween_method(_animate_bounce, 0.0, TAU, 1.0/_bounce_speed)

func _stop_bounce_animation() -> void:
	if _bounce_tween:
		_bounce_tween.kill()
		_bounce_tween = null
	if arrow_indicator and is_instance_valid(arrow_indicator):
		arrow_indicator.position.y = _base_y_position

func _animate_bounce(angle: float) -> void:
	if arrow_indicator and is_instance_valid(arrow_indicator):
		var offset = sin(angle) * _bounce_amplitude
		arrow_indicator.position.y = _base_y_position + offset

func expire() -> void:
	if (not is_instance_valid(target)) or target.stats.hp <= 0:
		return
	hide_arrow_above_cog()
	if not job_met:
		print("job not met")
		var attack = load('res://objects/battle/battle_resources/cog_attacks/resources/debuff_wag.tres').duplicate()
		attack.damage = 4
		attack.summary = "The Foreman Retaliates!"
		attack.user = target
		attack.targets = [Util.get_player()]
		attack.damage += target.level
		manager.battle_stats[target].defense -= defense_boost
		manager.round_end_actions.append(attack) 
func get_icon() -> Texture2D:
	return GagIcons[track_name]

func on_action_started(action: BattleAction) -> void:
	if action is ToonAttack:
		if check_for_match(action):
			print("correct gag was used")
			if cog in action.targets:
				if not job_met: manager.battle_stats[target].defense -= defense_boost
				job_met = true
				print("changed job met to true")
				hide_arrow_above_cog()


func check_for_match(action: ToonAttack) -> bool:
	for gag in track.gags:
		print(gag.action_name ,action.action_name)
		if gag.action_name == action.action_name:
			return true
	return false

func cleanup() -> void:
	if manager.s_action_started.is_connected(on_action_started):
		manager.s_action_started.disconnect(on_action_started)
	
	# Assign a random gag immunity to each Cog
