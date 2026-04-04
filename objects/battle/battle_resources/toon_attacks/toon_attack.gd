extends ActionScript
class_name ToonAttack

@export var icon: Texture2D
@export var damage: int
@export_multiline var gag_summary := ""

# Used in the UI to temporarily store the price of a gag
var price: int
# Use to force-associate a Gag with a Track
var track: Track

signal s_hit
signal s_missed


func get_stats() -> String:
	var string := "Damage: " + get_true_damage() + "\n"\
	+ "Affects: "
	match target_type:
		ActionTarget.SELF:
			string += "Self"
		ActionTarget.ENEMIES:
			string += "All Cogs"
		ActionTarget.ENEMY:
			string += "One Cog"
		ActionTarget.ENEMY_SPLASH:
			string += "Three Cogs"
	
	return string

func get_true_damage(dmg_mod := 1.0, base_dmg: int = 0, override_track: Track = null) -> String:
	var true_dmg: float
	if base_dmg == 0:
		true_dmg = float(damage)
	else:
		true_dmg = float(base_dmg)
	if not is_equal_approx(dmg_mod, 1.0):
		true_dmg *= dmg_mod
	var player_stats: PlayerStats
	if is_instance_valid(BattleService.ongoing_battle):
		player_stats = BattleService.ongoing_battle.battle_stats[Util.get_player()]
	else:
		player_stats = Util.get_player().stats
	
	var base_boost: float = player_stats.get_stat('damage')
	true_dmg *= base_boost
	
	var effectiveness := 1.0
	if not override_track: override_track = player_stats.character.gag_loadout.get_action_track(self)
	if override_track:
		effectiveness = player_stats.get_track_effectiveness(override_track.track_name)
	return str(roundi(float(true_dmg) * effectiveness))

#region MOVIE SCRIPTS

const BUTTON_PROP := 'res://models/props/gags/button/toon_button.tscn'
const PRESS_SFX := 'res://audio/sfx/battle/gags/AA_trigger_box.ogg'
func press_button() -> void:
	var button : Node3D = load(BUTTON_PROP).instantiate()
	user.toon.left_hand_bone.add_child(button)
	user.set_animation('press-button')
	Task.delay(2.3).connect(AudioManager.play_sound.bind(load(PRESS_SFX)))
	Task.delay(3.5).connect(button.queue_free)

#endregion

func get_immunity(cog : Cog) -> bool:
	#return true
	
	var effects := manager.get_statuses_for_target(cog)
	
	for effect in effects:
		if effect is StatusEffectGagImmunity:
			if effect.track:
				for gag : ToonAttack in effect.track.gags:
					if gag.action_name == action_name:
						return true
	return false

func do_dizzy_stars(cog: Cog, time := 2.0) -> Node3D:
	var stars: Node3D = load("res://models/props/cog_props/stun_stars/stun_stars.tscn").instantiate()
	stars.delete_time = time
	cog.body.head_bone.add_child(stars)
	stars.rotation_degrees.x = 90.0
	return stars

func get_store_summary() -> String:
	if gag_summary.is_empty():
		return get_stats()
	return gag_summary
