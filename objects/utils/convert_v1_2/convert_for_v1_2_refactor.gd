@tool
extends EditorScript

func _run():
	# CogPool must come before CogDNA
	convert_cog_pool()
	convert_cog_dnas()
	
	convert_department_floors()
	convert_item_pools()

func _convert_resource(old_resource: Resource, new_script: Variant, resources: Properties, resource_arrays: Properties, other: Properties) -> Variant:
	push_warning('  converting %s' % old_resource.resource_path)
	var converted: Resource = new_script.new()
	for old_property_name in resources.names.keys():
		var new_property_name := resources.names[old_property_name]
		var resource_value = old_resource.get(old_property_name)
		if resource_value != null:
			if resources.fn.is_valid():
				resources.fn.call([old_property_name, new_property_name], resource_value, converted)
			else:
				converted.set(new_property_name, resource_value.resource_path)
	for old_property_name in resource_arrays.names.keys():
		var new_property_name := resource_arrays.names[old_property_name]
		if resource_arrays.fn.is_valid():
			resource_arrays.fn.call([old_property_name, new_property_name], old_resource, converted)
		else:
			converted.set(new_property_name, old_resource.get(old_property_name).map(func(resource): return resource.resource_path))
	for old_property_name in other.names.keys():
		var new_property_name := other.names[old_property_name]
		if other.fn.is_valid():
			other.fn.call([old_property_name, new_property_name], old_resource, converted)
		else:
			converted.set(new_property_name, old_resource.get(old_property_name))
	return converted

func _convert_resources(directories: Array[String], old_script: GDScript, new_script: Variant, resources: Properties, resource_arrays: Properties, other: Properties):
	for dir in directories:
		for file in ResourceLoader.list_directory(dir):
			var old_resource = ResourceLoader.load(dir + file)
			if old_resource.get_script() != old_script:
				continue
				
			push_warning('converting %s' % file)
			var converted = _convert_resource(old_resource, new_script, resources, resource_arrays, other)
			converted.take_over_path(old_resource.resource_path)
			ResourceSaver.save(converted)


class Properties:
	var names: Dictionary[String, String]
	var fn: Callable
	
	func _init(names: Array = [], fn: Callable = Callable(), name_overrides: Dictionary[String, String] = {}):
		for name in names:
			self.names[name] = name
		for name in name_overrides.keys():
			self.names[name] = name_overrides[name]
		self.fn = fn


#region CogDNA
const OLD_COG_DNA := preload('uid://okjbx502s3r5')

var cog_dna_properties := {
	'resources': Properties.new([
		'custom_blazer_tex', 'custom_arm_tex', 'custom_leg_tex', 
		'custom_wrist_tex', 'custom_hand_tex', 'custom_shoe_tex',
		'head', 'battle_start_movie',
	]),
	'resource_arrays': Properties.new(
		['head_textures', 'status_effects'],
		Callable(),
		{'status_effects': 'baked_status_effects'},
	),
	'other': Properties.new([
		'department', 'suit', 'cog_name', 'name_plural', 'name_prefix',
		'name_suffix', 'head_scale', 'head_pos', 'scale', 'head_shader',
		'hand_color', 'head_color', 'custom_nametag_height',
		'custom_nametag_suffix', 'can_speak', 'attacks', 'level_low',
		'level_high', 'is_mod_cog', 'is_admin', 'health_mod',
		'battle_phrases', 'external_assets',
	]),
}

func convert_cog_dnas():
	_convert_resources(
		[
			'res://objects/cog/presets/bossbot/',
			'res://objects/cog/presets/cashbot/',
			'res://objects/cog/presets/lawbot/',
			'res://objects/cog/presets/sellbot/',
			'res://objects/cog/presets/misc/',
		],
		OLD_COG_DNA,
		CogDNA,
		cog_dna_properties['resources'],
		cog_dna_properties['resource_arrays'],
		cog_dna_properties['other'],
	)
	
func _convert_cog_dna(old_cog_dna: OLD_COG_DNA) -> CogDNA:
	return _convert_resource(
		old_cog_dna,
		CogDNA,
		cog_dna_properties['resources'],
		cog_dna_properties['resource_arrays'],
		cog_dna_properties['other'],
	)
#endregion


#region CogPool
func convert_cog_pool():
	var cogs: Dictionary[String, CogDNA]
	var pools: Dictionary[CogPool, Array]
	
	var _convert_inner_cog_dna = func(property_names: Array, old_resource: Variant, converted: CogPool):
		var new_cog_dna_array: PackedStringArray
		var old_cog_dna_array = old_resource.get(property_names[0])
		for old_cog_dna in old_cog_dna_array:
			push_warning('  attempting conversion %s (%s)' % [old_cog_dna.get('cog_name'), old_cog_dna])
			new_cog_dna_array.append(old_cog_dna.resource_path)
			cogs[old_cog_dna.resource_path] = _convert_cog_dna(old_cog_dna)
		#push_warning('  convert inner cog dna %s %s' % [old_cog_dna_array, new_cog_dna_array])
		#converted.set(property_name, new_cog_dna_array)
		pools[converted] = Array(new_cog_dna_array)
		push_warning(pools.keys())
		
	_convert_resources(
		['res://objects/cog/presets/pools/'],
		load('uid://ocitcstc3bru'),
		CogPool,
		# Resources -> Resource Paths
		Properties.new(),
		# Resource Arrays -> Resource Path Arrays
		Properties.new(['cogs'], _convert_inner_cog_dna),
		# Other Exported Properties
		Properties.new(),
	)
	push_warning('-- COGS: %s\n--POOLS: %s' % [cogs, pools])
	for cog_dna_path in cogs.keys():
		var converted = cogs[cog_dna_path]
		converted.take_over_path(cog_dna_path)
		ResourceSaver.save(converted)
	for pool in pools.keys():
		pool.cogs.assign(pools[pool].map(func(path: String): return cogs[path]))
		ResourceSaver.save(pool)
#endregion

#region DepartmentFloor
func convert_department_floors():
	_convert_resources(
		['res://scenes/game_floor/department_floors/'],
		load('uid://bs13ap551050v'),
		DepartmentFloor,
		# Resources -> Resource Paths
		Properties.new(['battle_music']),
		# Resource Arrays -> Resource Path Arrays
		Properties.new(
			['entrances', 'connectors', 'one_time_rooms', 'background_music']
		),
		# Other Exported Properties
		Properties.new(
			[
				'battle_rooms', 'obstacle_rooms', 'pre_final_rooms',
				'final_rooms', 'special_rooms',
			],
			_convert_facility_room_array,
		),
	)
#endregion


#region FacilityRoom
const FACILITY_ROOM = preload('uid://dhyadt7p1gv78')
func _convert_facility_room_array(property_names: Array, old_resource: Variant, converted: Variant):
	var facility_rooms: Array[FacilityRoom] = []
	for old_facility_room: FACILITY_ROOM in old_resource.get(property_names[0]):
		var facility_room: FacilityRoom = FacilityRoom.new()
		facility_room.room = old_facility_room.room.resource_path
		facility_room.rarity_weight = old_facility_room.rarity_weight
		facility_rooms.append(facility_room)
	converted.set(property_names[1], facility_rooms)
#endregion


#region ItemPool
func convert_item_pools():
	_convert_resources(
		['res://objects/items/pools/'],
		load('uid://wiibpvvki8vs'),
		ItemPool,
		# Resources -> Resource Paths
		Properties.new([]),
		# Resource Arrays -> Resource Path Arrays
		Properties.new(['items']),
		# Other Exported Properties
		Properties.new(['low_roll_override']),
	)
#endregion
