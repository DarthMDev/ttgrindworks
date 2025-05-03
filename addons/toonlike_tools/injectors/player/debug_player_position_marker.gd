extends Marker3D

const PLAYER_SCENE := preload('res://objects/player/player.tscn')
var player: Player

@export var invulnerable := false
@export var infinite_gag_points := false

func _init():
	if OS.has_feature('editor') and not Util.get_player():
		player = PLAYER_SCENE.instantiate()
		player.state = Player.PlayerState.WALK

func _ready():
	if player:
		add_child(player)
		SceneLoader.add_persistent_node(player)
		player.stats.debug_invulnerable = invulnerable
		if infinite_gag_points:
			player.stats.gag_cap = 100
			player.stats.debug_gag_points = true
			for track in player.stats.gags_unlocked:
				player.stats.gags_unlocked[track] = 7
				player.stats.gag_balance[track] = 100
	queue_free()
