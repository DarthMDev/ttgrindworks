extends Node
class_name BYCChatterPanel

@onready var label_chatter: Label = $ChatterNamesVBox/ChatterTwitchNameLabel
@onready var label_cog: Label = $ChatterNamesVBox/ChatterCogNameLabel
@onready var display_buff: Control = $BuffListHBox

var name_chatter: String
var name_cog: String

var buffs := []

func _ready():
	if name_chatter is String:
		label_chatter.text = name_chatter
	if name_cog is String:
		label_cog.text = name_cog
	
	var buff_texturerects: Array = display_buff.get_children()
	var i = 0
	for buff: StatusEffect in buffs:
		var tx: Texture2D = buff.get_icon()
		buff_texturerects[i].texture = tx
		var desc: Label = get_node("BuffListHBox/Buff" + str(i + 1) + "/BuffDesciptionLabel" + str(i + 1))
		desc.text = buff.description
		i += 1
