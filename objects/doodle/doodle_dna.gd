extends Resource
class_name DoodleDNA

enum DoodleTail {
	BUNNY,
	CAT,
	BIRD,
	LONG
}
@export var tail := DoodleTail.BUNNY

enum DoodleEar {
	BUNNY,
	CAT,
	DOG,
	ANTENNA,
	HORN
}
@export var ears := DoodleEar.BUNNY

enum DoodleNose {
	CLOWN,
	DOG,
	OVAL,
	PIG
}
@export var nose := DoodleNose.CLOWN

@export var color := Color.WHITE

@export var eye_lashes := false

var textures : Array[String]= [
	"res://models/doodle/Beanbody3stripes6.png",
	"res://models/doodle/BeanbodyDots6.png",
	"res://models/doodle/BeanbodyTummy6.png",
	"res://models/doodle/BeanbodyZebraStripes6.png"
]
@export var tex_num := 0
var texture : Texture2D:
	get:
		return load(textures[tex_num])

@export var hair := false


func randomize_dna():
	tail = RNG.channel(RNG.ChannelDoodleDNA).randi() % DoodleTail.keys().size() as DoodleTail
	ears = RNG.channel(RNG.ChannelDoodleDNA).randi() % DoodleEar.keys().size() as DoodleEar
	nose = RNG.channel(RNG.ChannelDoodleDNA).randi() % DoodleNose.keys().size() as DoodleNose
	color = Globals.random_dna_color
	eye_lashes = RNG.channel(RNG.ChannelDoodleDNA).randi() % 2 == 0
	tex_num = RNG.channel(RNG.ChannelDoodleDNA).randi() % textures.size()
	hair = RNG.channel(RNG.ChannelDoodleDNA).randi() % 2 == 0
