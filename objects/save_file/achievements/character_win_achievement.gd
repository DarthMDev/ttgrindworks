extends Achievement
class_name CharacterWinAchievement

## Class of achievements that unlock when the game is won by a specific character

@export var character_id := PlayerCharacter.Character.OTHER


func _setup() -> void:
	if get_completed():
		return
	
	Globals.s_game_win.connect(on_game_win)

func on_game_win() -> void:
	var char_id := Util.get_player().character.character_id
	if character_id == char_id:
		unlock()
