@tool
extends UIPanel

const CHAR_LIMIT := 30

static var stats: Dictionary[String, Dictionary] = {
	"Gameplay": {
		"Floors Cleared": "floors_cleared",
		"Games Played": "new_games",
		"Jellybeans Collected": "jellybeans_collected",
		"Pocket Pranks Used": "pocket_pranks_used",
		"Times Gone Sad": "deaths",
		"Win Streak": "win_streak",
		"High Score": "high_score",
	}
}

@onready var stat_template: HBoxContainer = $StatTemplate
@onready var stat_container: VBoxContainer = %StatContainer
@onready var section_template: VBoxContainer = $SectionTemplate


func _ready() -> void:
	super()
	
	if not Engine.is_editor_hint():
		set_up()

func set_up() -> void:
	create_stat_section("Gameplay")
	append_playtime()
	
	for category in stats.keys():
		create_stat_section(category)
		for stat in stats[category].keys():
			if stats[category][stat] in SaveFileService.progress_file:
				append_stat(category, stat, SaveFileService.progress_file.get(stats[category][stat]))
	append_best_time()
	append_cogs()

func append_stat(section: String, stat: String, value: Variant) -> void:
	var parent_section: VBoxContainer
	for stat_section in stat_container.get_children():
		if stat_section.name == section:
			parent_section = stat_container
	
	if parent_section:
		var stat_object := stat_template.duplicate()
		parent_section.add_child(stat_object)
		if stat.length() > CHAR_LIMIT:
			stat = stat.substr(0, CHAR_LIMIT) + "..."
		stat_object.get_node('Label').set_text(stat + ":")
		stat_object.get_node('Value').set_text(str(value))
		stat_object.show()

func append_cogs() -> void:
	create_stat_section("Cogs")
	
	var total := 0
	for cog in SaveFileService.progress_file.cogs_defeated.keys():
		total += SaveFileService.progress_file.cogs_defeated[cog]
	
	append_stat("Cogs", "Total Defeated", total)
	append_stat("Cogs", "Total Proxies Defeated", SaveFileService.progress_file.proxy_cogs_defeated)
	
	for cog in SaveFileService.progress_file.cogs_defeated.keys():
		append_stat("Cogs", cog.capitalize(), SaveFileService.progress_file.cogs_defeated[cog])

func append_playtime() -> void:
	var time_string := "%d hours, %d minutes"
	
	var seconds: int = int(round(SaveFileService.progress_file.total_playtime))
	
	var hours := floori(seconds / 3600)
	var minutes := floori((seconds - (hours * 3600)) / 60)
	
	time_string = time_string % [hours, minutes]
	
	append_stat("Gameplay", "Total Playtime", time_string)

func append_best_time() -> void:
	var time := SaveFileService.progress_file.best_time
	var time_str := ""
	if is_equal_approx(time, 0.0):
		time_str = "N/A"
	else:
		time_str = RunTimer.get_time_string(time)
	append_stat("Gameplay", "Best Time", time_str)

func create_stat_section(section_title: String) -> VBoxContainer:
	if find_stat_section(section_title):
		return
	
	var new_template := section_template.duplicate()
	new_template.get_node('Label').set_text(section_title)
	stat_container.add_child(new_template)
	new_template.set_name(section_title)
	new_template.show()
	return new_template

func find_stat_section(section_title: String) -> VBoxContainer:
	for section in stat_container.get_children():
		if section.name == section_title:
			return section
	return
