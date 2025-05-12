extends Resource
class_name CogDNA

enum CogDept {
	SELL,
	CASH,
	LAW,
	BOSS,
	NULL,
}
@export var department := CogDept.SELL

enum SuitType {
	SUIT_A,
	SUIT_B,
	SUIT_C
}
@export var suit := SuitType.SUIT_A

@export var custom_blazer_tex: Texture2D
@export var custom_arm_tex: Texture2D
@export var custom_leg_tex: Texture2D
@export var custom_wrist_tex: Texture2D
@export var custom_hand_tex: Texture2D
@export var custom_shoe_tex: Texture2D

@export var cog_name: String = "Cog"
@export var name_plural: String = ""
@export var name_prefix := ""
@export var name_suffix := ""
@export var head: PackedScene
@export var head_scale: Vector3 = Vector3.ONE
@export var head_pos: Vector3 = Vector3.ZERO
@export var scale: float = 1.0
@export var head_textures: Array[Texture2D]
@export var head_shader: CogShader
@export var hand_color: Color = Color.WHITE
@export var head_color: Color = Color.WHITE
@export var custom_nametag_height := 0.0
@export var custom_nametag_suffix := ""
@export var can_speak := true

@export var attacks: Array[CogAttack]
@export var level_low := 1
@export var level_high := 12
@export var status_effects: Array[StatusEffect]
@export var is_mod_cog := false
@export var is_admin := false
@export var health_mod := 1.0

@export_multiline var battle_phrases: Array[String] = ["We are gonna fight now."]
@export var battle_start_movie: BattleStartMovie

@export var external_assets := {
	head_model = "",
	head_textures = [],
	attacks = [],
	custom_blazer_tex = "",
	custom_arm_tex = "",
	custom_wrist_tex = "",
	custom_hand_tex = "",
	custom_shoe_tex = ""
}

const DEFAULT_HEAD := "res://models/cogs/heads/flunky.glb"


func get_head() -> Node3D:
	var head_mod: Node3D
	if head:
		head_mod = head.instantiate()
	elif not external_assets['head_model'] == "":
		var head_path : String = external_assets['head_model']
		if head_path.begins_with('res://'):
			head_mod = load(head_path).instantiate()
		elif Globals.custom_cog_head_directory.has(head_path):
			head_mod = Globals.custom_cog_head_directory.get(head_path).instantiate()
	else:
		head_mod = load(DEFAULT_HEAD).instantiate()
	
	var head_tex := head_textures.duplicate()
	for path : String in external_assets['head_textures']:
		if path.begins_with('res://'):
			head_tex.append(load(path))
		else:
			head_tex.append(ImageTexture.create_from_image(Image.load_from_file(path)))
	
	var head_mesh: MeshInstance3D
	
	for child in head_mod.get_children():
		if child is MeshInstance3D:
			head_mesh = child
	if head_mesh:
		for i in head_mesh.mesh.get_surface_count():
			if not head_mesh.mesh.surface_get_material(i):
				continue
			var mat: StandardMaterial3D = head_mesh.mesh.surface_get_material(i).duplicate()
			if head_tex.size() > i:
				mat.albedo_texture = head_tex[i]
			mat.albedo_color = head_color
			head_mesh.set_surface_override_material(i,mat)
	
	if head_shader:
		head_shader.apply_shader(head_mesh)
	
	return head_mod

func combine_attributes(second_dna: CogDNA) -> void:
	# Copy certain attributes from the second DNA to self
	head = second_dna.head
	external_assets = second_dna.external_assets
	head_textures = second_dna.head_textures
	hand_color = second_dna.hand_color
	if not second_dna.head_color == Color.WHITE:
		head_color = second_dna.head_color

## Create epic fusion name
func combine_names(second_dna: CogDNA) -> String:
	# Get our prefix and suffix
	var prefix := get_name_prefix()
	var suffix := second_dna.get_name_suffix()
	
	# Test for hyphenated names
	if prefix.ends_with("-"):
		if suffix.begins_with("-") or suffix.begins_with(" "):
			suffix.erase(0)
		# Capitalize suffix in hyphenated names
		if suffix[0] == suffix[0].to_lower():
			suffix[0] = suffix[0].to_upper()
	elif suffix.begins_with("-"):
		if prefix.ends_with(" "):
			prefix.erase(prefix.length() - 1)
	# Add a space to awkward names
	# Only if name not hyphenated
	else:
		# Allow for no spaces if the suffix starts with a lowercase letter
		if not prefix.ends_with(" ") and not suffix.begins_with(" "):
			if suffix[0] == suffix[0].to_upper():
				prefix += " "
	
	# Combine our names
	var new_name := prefix + suffix
	
	# Remove any double spaces
	new_name = new_name.replace("  ", " ")
	
	# Return combined name
	return new_name

func get_name_prefix(force_default := false) -> String:
	if not name_prefix == "" and not force_default: return name_prefix
	
	if cog_name.split(" ").size() > 1:
		return cog_name.split(" ")[0]
	
	return cog_name

func get_name_suffix(force_default := false) -> String:
	if not name_suffix == "" and not force_default: return name_suffix
	
	if not cog_name.split(" ").size() == 1:
		return cog_name.split(" ")[cog_name.split(" ").size() - 1]
	
	return cog_name

func get_plural_name() -> String:
	if not name_plural == "": return name_plural
	return cog_name + "s"


const ATTRIBUTE_LIST : Array[String] = [
	"department",
	"suit",
	"cog_name",
	"name_plural",
	"name_prefix",
	"name_suffix",
	"head_scale",
	"head_pos",
	"scale",
	"hand_color",
	"head_color",
	"custom_nametag_height",
	"custom_nametag_suffix",
	"level_low",
	"level_high",
	"is_mod_cog",
	"is_admin",
	"health_mod",
	"battle_phrases",
	"external_assets"
]
const PATH_ATTRIBUTE_LIST : Array[String] = [
	"custom_blazer_tex",
	"custom_leg_tex",
	"custom_arm_tex",
	"custom_wrist_tex",
	"custom_hand_tex",
	"custom_shoe_tex",
	"head_textures",
	"head",
	"attacks",
	"status_effects"
]
func to_json() -> String:
	var save_data := {}
	for attribute in ATTRIBUTE_LIST:
		if get(attribute) is Color:
			save_data[attribute] = get(attribute).to_html()
		else:
			save_data[attribute] = get(attribute)
	
	for attribute_name : String in PATH_ATTRIBUTE_LIST:
		var attribute : Variant = get(attribute_name)
		if attribute is Resource:
			# bc people already have custom cogs with this misnamed variable :(
			if attribute_name == "head":
				save_data["external_assets"]["head_model"] = attribute.resource_path
			else:
				save_data["external_assets"][attribute_name] = attribute.resource_path
		elif attribute is Array:
			var attribute_arr : Array = []
			for item in attribute:
				if Util.file_exists(item.resource_path) or item.resource_path.begins_with('res://'):
					print("file exists at: %s" % item.resource_path)
					attribute_arr.append(item.resource_path)
				else:
					print("no file exists at: %s" % item.resource_path)
			if not attribute_arr.is_empty():
				save_data["external_assets"][attribute_name] = attribute_arr
	
	return JSON.stringify(save_data, "\t")

static func from_json(string : String) -> CogDNA:
	var dict = JSON.parse_string(string)
	var dna := CogDNA.new()
	for attribute in ATTRIBUTE_LIST:
		if not attribute in dict:
			continue
		if dna.get(attribute) is Vector3:
			dna.set(attribute, string_to_vector3(dict[attribute]))
		if dict[attribute] is Array:
			dna.get(attribute).assign(dict[attribute])
		else:
			dna.set(attribute, dict[attribute])
	
	# Find our internal resources
	if dict.has("external_assets"):
		var externals : Dictionary = dict.get("external_assets")
		for attribute_name in externals.keys():
			var attribute : Variant = externals[attribute_name]
			if attribute is String:
				if is_image_file(attribute) and not attribute.begins_with("res://"):
					pass
				elif Util.file_exists(attribute) or attribute.begins_with('res://'):
					dna.set(attribute_name, load(attribute))
			elif attribute is Array:
				## head textures are a special case bc they hate me
				if not attribute_name == 'head_textures':
					var new_array := []
					for file in attribute:
						new_array.append(load(file))
					dna.get(attribute_name).assign(new_array)
				else:
					var new_array := []
					for file in attribute:
						if Util.file_exists(file) or file.begins_with('res://'):
							new_array.append(file)
					dna.external_assets.set(attribute_name, new_array)
	return dna


static func string_to_vector3(string := "") -> Vector3:
	if string:
		var new_string: String = string
		new_string = new_string.erase(0, 1)
		new_string = new_string.erase(new_string.length() - 1, 1)
		var array: Array = new_string.split(", ")

		return Vector3(float(array[0]), float(array[1]), float(array[2]))

	return Vector3.ONE


const IMAGE_TYPES := [".jpg", ".png"]
static func is_image_file(path : String) -> bool:
	for image_type in IMAGE_TYPES:
		if path.ends_with(image_type):
			return true
	return false
