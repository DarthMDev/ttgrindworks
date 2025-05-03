extends Resource
class_name Achievement

@export var achievement_name := ""
@export_multiline var achievement_summary := ""
@export var achievement_index : ProgressFile.GameAchievement
@export var achievement_icon : Texture2D


## Run at game start
## Override this to hook into progress checks
func _setup() -> void:
	pass

func unlock() -> void:
	if not get_completed():
		SaveFileService.progress_file.achievements_earned[achievement_index] = true
		SaveFileService.achievement_ui.queue_achievement_get(self)
		Globals.s_achievement_unlocked.emit()

func get_completed() -> bool:
	# When new achievements are added in later versions,
	# We need to check if this achievement is in the dict yet
	if SaveFileService.progress_file.achievements_earned.has(achievement_index):
		return SaveFileService.progress_file.achievements_earned[achievement_index]
	else:
		return false
