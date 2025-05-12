@tool
extends UIPanel

const COG_CREATOR := "res://scenes/cog_creator/cog_creator.tscn"
var STATISTICS: PackedScene
var CREDITS: PackedScene
var ACHIEVEMENTS: PackedScene

@onready var statistics_button: GeneralButton = $Panel/Buttons/StatisticsButton
@onready var cog_creator_button: GeneralButton = $Panel/Buttons/CogCreatorButton

var hint_tracking := false

func _init():
	GameLoader.queue_into(GameLoader.Phase.GAME_START, self, {
		'STATISTICS': 'res://scenes/title_screen/stats/statistics_panel.tscn',
		'CREDITS': 'res://scenes/title_screen/credits/credits_panel.tscn',
		'ACHIEVEMENTS': 'res://scenes/title_screen/achievement_panel/achievement_panel.tscn',
	})

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	if not SaveFileService.progress_file.cog_creator_unlocked:
		cog_creator_button.text = "???"
		cog_creator_button.set_disabled(true)
		cog_creator_button.pressed.disconnect(open_cog_creator)
		# cog_creator_button.modulate = Color(0.8, 0.8, 0.8, 0.5)
		cog_creator_button.material.set_shader_parameter(&"alpha", 0.5)
		cog_creator_button.mouse_entered.connect(HoverManager.hover.bind("You must defeat ??? ?????? before you can use this feature."))
		cog_creator_button.mouse_exited.connect(HoverManager.stop_hover)
	super()

func open_cog_creator() -> void:
	if not active:
		return
	SceneLoader.load_into_scene(COG_CREATOR)
	hide()
	close()

func open_statistics() -> void:
	get_tree().get_root().add_child(STATISTICS.instantiate())

func open_credits() -> void:
	get_tree().get_root().add_child(CREDITS.instantiate())

func open_achievements() -> void:
	get_tree().get_root().add_child(ACHIEVEMENTS.instantiate())
