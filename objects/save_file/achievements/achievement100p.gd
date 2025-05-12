extends Achievement

var achievement_goal : int:
	get:
		var count := SaveFileService.progress_file.ACHIEVEMENT_RESOURCES.size() - 1
		if get_completed():
			count += 1
		return count

func _setup() -> void:
	if not try_unlock():
		Globals.s_achievement_unlocked.connect(try_unlock)
		SaveFileService.progress_file.achievements_earned[achievement_index] = false

func try_unlock() -> bool:
	if SaveFileService.progress_file.achievement_count >= achievement_goal:
		unlock()
		return true
	return false
