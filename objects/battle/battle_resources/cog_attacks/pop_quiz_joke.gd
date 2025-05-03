extends PopQuizAttack
class_name PopQuizJoke

const JOKE_FILE := "res://objects/battle/battle_resources/toon_attacks/megaphone_jokes.txt"


func get_question() -> Array[String]:
	# Prepare prompt array
	var return_arr : Array[String] = []
	
	# Get joke file as array
	var file := FileAccess.open(JOKE_FILE,FileAccess.READ)
	var jokes := file.get_as_text().split("\n")
	jokes.remove_at(jokes.size() - 1)
	
	# Sort setups and punchlines
	var setups : Array[String] = []
	var punchlines : Array[String] = []
	for i in jokes.size():
		if i % 2 == 0:
			setups.append(jokes[i])
		else:
			punchlines.append(jokes[i])
	
	# Choose a random joke from the setups
	var true_joke_index := RandomService.randi_channel('true_random') % setups.size()
	return_arr.append(setups[true_joke_index])
	return_arr.append(punchlines[true_joke_index])
	
	# Append a random amount of false answers from 2-4
	var false_answers := RandomService.randi_channel('true_random') % 3 + 2
	while return_arr.size() < false_answers + 2:
		var false_answer := punchlines[RandomService.randi_channel('true_random') % punchlines.size()]
		if not false_answer in return_arr:
			return_arr.append(false_answer)
	
	# Return the question
	return return_arr
