@tool
extends Item
class_name ItemActive

@export var sfx: Array[AudioStream]
enum SoundType {
	USE,
	COOLDOWN,
	FAILED
}

enum ActiveType {
	ANY,
	BATTLE,
	REALTIME,
	WHENEVER,
}
@export var active_type := ActiveType.ANY
## Will not be used if the color is set to black
@export var custom_charge_color := Color.BLACK

@export_range(0, 12) var charge_count := 0
@export_range(0, 12) var current_charge := 0:
	set(x):
		current_charge = clampi(x, 0, charge_count)
		s_current_charge_changed.emit(x)
@export var needs_full_charge := true
@export var one_time_use := false

## Not sure how to best implement this yet
#@export var one_time_use := false
@export var custom_discharge_time := 1.0


var node: ItemScriptActive

signal s_current_charge_changed(new_charges : int)


func apply_item(player: Player, apply_visuals := true, object: Node3D = null, load_into_reserve := false) -> void:
	super(player, apply_visuals, object)
	if not load_into_reserve:
		player.stats.current_active_item = self

func apply_item_script(player: Player, object: Node3D = null) -> void:
	if item_script:
		var item_node := ItemScript.add_item_script(player, item_script)
		if item_node is ItemScript:
			item_node.on_collect(self, object)
			if item_node is ItemScriptActive:
				item_node.item = self
				node = item_node


func play_sound_key(key: SoundType) -> void:
	if sfx.size() < key:
		return
	
	var stream = sfx[key]
	if stream is AudioStream:
		AudioManager.play_sound(stream)

func remove_item(player: Player) -> void:
	super(player)
	node.attempt_disconnect()
	Util.get_player().stats.current_active_item = null
	Util.get_player().stats.current_active_item = null
