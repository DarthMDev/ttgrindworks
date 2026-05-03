@tool
extends UIPanel

const FINAL_ACHIEVEMENT := preload('res://objects/save_file/achievements/resources/achievement_100p.tres')

@onready var achievement_template := $AchievementTemplate
@onready var achievement_container: GridContainer = %AchievementContainer

static var achievement_order: Dictionary[String, Array] = {
	"": [
		## The "Grind" Works
		ProgressFile.GameAchievement.DEFEAT_COGS_1,
		ProgressFile.GameAchievement.DEFEAT_COGS_10,
		ProgressFile.GameAchievement.DEFEAT_COGS_100,
		ProgressFile.GameAchievement.DEFEAT_COGS_1000,
		ProgressFile.GameAchievement.DEFEAT_COGS_10000,
		ProgressFile.GameAchievement.DEFEAT_BOSSES_1,
		ProgressFile.GameAchievement.DEFEAT_BOSSES_5,
		ProgressFile.GameAchievement.DEFEAT_BOSSES_25,
		ProgressFile.GameAchievement.DEFEAT_BOSSES_100,
		ProgressFile.GameAchievement.DEFEAT_BOSSES_200,
		
		## Secret Bosses
		ProgressFile.GameAchievement.DEFEAT_CLOWNS,
		ProgressFile.GameAchievement.DEFEAT_SLENDER,
		ProgressFile.GameAchievement.DEFEAT_LIQUIDATOR,
		
		## Progression
		ProgressFile.GameAchievement.UNLOCK_PROXY_COGS,
		
		## Character Unlocks
		ProgressFile.GameAchievement.UNLOCK_CLARA,
		ProgressFile.GameAchievement.UNLOCK_JULIUS,
		ProgressFile.GameAchievement.UNLOCK_BESSIE,
		ProgressFile.GameAchievement.UNLOCK_MOE,
		ProgressFile.GameAchievement.UNLOCK_PETE,
		ProgressFile.GameAchievement.UNLOCK_OLDMAN,
		ProgressFile.GameAchievement.UNLOCK_RANDOM,
		
		## Deaths
		ProgressFile.GameAchievement.GO_SAD_1,
		ProgressFile.GameAchievement.GO_SAD_5,
		ProgressFile.GameAchievement.GO_SAD_10,
		
		## Easter Eggs
		ProgressFile.GameAchievement.EASTER_EGG_EXPLORER,
		ProgressFile.GameAchievement.EASTER_EGG_GEAR,
		
		## Challenges
		ProgressFile.GameAchievement.WIN_GAME_HOUR,
		
		## Misc.
		ProgressFile.GameAchievement.DOODLE,
		ProgressFile.GameAchievement.FLIPPY_GETS_BUCKET,
		ProgressFile.GameAchievement.MEET_STRANGER,
		
		## Should always be last :)
		ProgressFile.GameAchievement.ONE_HUNDRED_PERCENT,
	],
	"Items": [
		## Accessory Unlocks
		ProgressFile.GameAchievement.UNLOCK_BIRD_WINGS,
		ProgressFile.GameAchievement.UNLOCK_WEIRD_GLASSES,
		ProgressFile.GameAchievement.UNLOCK_WINGTIPS,
		
		## Passive Unlocks
		ProgressFile.GameAchievement.UNLOCK_ROLODEX,
		ProgressFile.GameAchievement.UNLOCK_DILLY_DIAL,
		ProgressFile.GameAchievement.UNLOCK_PHILOSOPHERS_STONE,
		ProgressFile.GameAchievement.UNLOCK_RAINBOW_JELLYBEAN,
		
		## Pocket Prank Unlocks
		ProgressFile.GameAchievement.UNLOCK_LAW_BOOK,
		ProgressFile.GameAchievement.UNLOCK_DAGGER,
	],
	
}

var sections: Dictionary[String, GridContainer] = {}

func _ready() -> void:
	super()
	if not Engine.is_editor_hint():
		populate_achievements()

func populate_achievements() -> void:
	for key in achievement_order.keys():
		var container := create_section(key)
		populate_section(key, container)
	
	# Add modded achievements
	for key in SaveFileService.mod_achievements.keys():
		var container := get_section(key)
		for achievement in SaveFileService.mod_achievements[key]:
			container.add_child(create_element(achievement))

func create_section(section_name: String) -> GridContainer:
	if section_name != "":
		var header_label := %SectionHeader.duplicate()
		header_label.set_text(section_name)
		%SectionContainer.add_child(header_label)
		header_label.show()
	var new_container := achievement_container.duplicate()
	%SectionContainer.add_child(new_container)
	new_container.show()
	sections[section_name] = new_container
	return new_container

func get_section(section_name: String) -> GridContainer:
	if section_name in sections.keys():
		return sections[section_name]
	return create_section(section_name)

func populate_section(section: String, container: GridContainer) -> void:
	for achievement in achievement_order[section]:
		var res := get_achievement_resource(achievement)
		var new_element := create_element(res)
		new_element.show()
		container.add_child(new_element)

func get_achievement_resource(achievement_id: ProgressFile.GameAchievement) -> Achievement:
	return SaveFileService.progress_file.active_achievements[achievement_id]

func create_achievement_template(achievement: Achievement) -> Control:
	var new_achievement := achievement_template.duplicate()
	if not achievement.hint.is_empty():
		new_achievement.get_node('Elements/Summary').set_text(achievement.hint)
	new_achievement.show()
	return new_achievement

func create_achievement(achievement: Achievement) -> Control:
	var new_achievement := create_achievement_template(achievement)
	new_achievement.get_node('Elements/Title').set_text(achievement.achievement_name)
	if achievement.achievement_icon:
		new_achievement.get_node('Elements/Icon').set_texture(achievement.achievement_icon)
	if achievement.use_achievement_background:
		new_achievement.get_node('Elements/Background').show()
		new_achievement.get_node('Elements/Background').self_modulate = achievement.custom_background_color.lerp(Color.WHITE, 0.4)
		new_achievement.get_node('Elements/Icon').scale *= 0.7
	if achievement.custom_material:
		new_achievement.get_node('Elements/Icon').material = achievement.custom_material
	new_achievement.get_node('Elements/Summary').set_text(achievement.achievement_summary)
	return new_achievement

func create_element(achievement: Achievement) -> Control:
	if achievement.get_completed(): return create_achievement(achievement)
	return create_achievement_template(achievement)
