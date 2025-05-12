extends Node

const FILE_PATH = 'res://anim_check_results.txt'

enum CheckType {
	TOON,
	COG
}
@export var check_type : CheckType

func _ready() -> void:
	check_anims(check_type)


func check_anims(mode : CheckType) -> void:
	var body_dict : Dictionary
	if mode == CheckType.TOON:
		for body_type in ToonDNA.BodyType:
			var body_type_str: String = ToonDNA.BodyType.keys()[body_type].to_lower()
			body_dict[body_type_str] = Globals.fetch_toon_body(body_type, false)
			body_dict[body_type_str + '_skirt'] = Globals.fetch_toon_body(body_type, true)
	else:
		for body_type in CogDNA.SuitType:
			var body_type_str: String = CogDNA.SuitType.keys()[body_type].to_lower()
			body_dict[body_type_str] = Globals.fetch_suit(body_type, false)
			body_dict[body_type_str + '_skelecog'] = Globals.fetch_suit(body_type, true)
	var anim_dict := {}
	var anim_master_list : Array[String] = []
	
	# Run through every body in the list
	for body in body_dict.keys():
		var checkbody : Node3D = body_dict[body].instantiate()
		add_child(checkbody)
		
		# This should never run unless you misconfigured a body
		if not 'animator' in checkbody:
			push_error('No Animator present in body. Goodbye :(')
			get_tree().quit()
			return
			
		# Record the body's animation list
		var animator: AnimationPlayer = checkbody.animator
		anim_dict[body] = animator.get_animation_list()
		
		# Keep track of all animation names
		for anim in animator.get_animation_list():
			if not anim in anim_master_list:
				anim_master_list.append(anim)
		
		# Remove the body
		checkbody.queue_free()
	# Announce success
	print("Gathered all animations, comparing...")
	
	
	# Start a string to write to the file
	var write_string := "!!MISSING "+str(CheckType.keys()[check_type])+" ANIMATIONS!!\n\n"
	
	# For every body, determine what animations are missing and record them to the file
	for body in anim_dict.keys():
		write_string+=body+':\n'
		var missing_anims := 0
		for anim in anim_master_list:
			if anim not in anim_dict[body]:
				missing_anims+=1
				write_string+=anim+"\n"
		if missing_anims == 0:
			write_string+="All animations present."
		write_string+="\n\n"
	write_to_file(write_string)


func write_to_file(string : String) -> void:
	var file : FileAccess = FileAccess.open(FILE_PATH,FileAccess.WRITE)
	file.store_string(string)
	file.close()
