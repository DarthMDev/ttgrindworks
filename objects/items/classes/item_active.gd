extends Item
class_name ItemActive

@export var sfx : Array[AudioStream]
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

@export_range(0, 12) var charge_count := 0
@export_range(0, 12) var current_charge := 0:
	set(x):
		current_charge = clampi(x, 0, charge_count)
		s_current_charge_changed.emit(x)

## Not sure how to best implement this yet
#@export var one_time_use := false
@export var custom_discharge_time := 1.0


var node : ItemScriptActive

signal s_current_charge_changed(new_charges : int)


func apply_item(player : Player, apply_visuals := true, object : Node3D = null) -> void:
	super(player, apply_visuals, object)
	player.stats.current_active_item = self

func apply_item_script(player : Player, object : Node3D = null) -> void:
	if item_script:
		var item_node := ItemScript.add_item_script(player,item_script)
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
