extends Node
## A singleton responsible for phased loading of game resources.
##
## Objects should queue resources from the [code]GameLoader[/code] in their
## [method Object._init] method, which can avoid long game launch times caused
## by an overreliance on [code]preload()[/code].
##
## You have the option to either let the [code]GameLoader[/code] populate a
## property for you when it's loaded, or you can simply have it load a resource
## and come back for it later. As an example:
##
## [codeblock]
## var MyScene: PackedScene
##
## func _init():
##     GameLoader.queue_into(GameLoader.Phase.GAMEPLAY, self, {
##         'MyScene': 'res://my_scene.tscn',
##     })
##     GameLoader.queue(GameLoader.Phase.GAMEPLAY, [
##         'res://my_other_scene.tscn'
##     ])
##
## func _ready():
##     # If we call queue_into(), the GameLoader will ensure the
##     # resource is loaded and the property is populated by the
##     # time _ready() is called.
##     add_child(MyScene.instantiate())
##
## func _on_signal():
##     # If you want to wait for a phase to be finished loading
##     # before handlinga signal, scene switch, etc., you can do
##     # the following:
##     await GameLoader.wait_for_phase(GameLoader.Phase.GAMEPLAY)
##
##     # An alternative is to call GameLoader.load(path) at some
##     # point to eitherfetch the cached result, if it was
##     # already picked up from the queue, or to have it loaded
##     # (as a blocking call) right then.
##     #
##     # When combined with the above, GameLoader.load() will never
##     # block, because this resource path was queued to the
##     # GAMEPLAY phase in _init().
##     add_child(GameLoader.load('res://my_other_scene.tscn'))
## [/codeblock]

const HINT_PREFIX := '!GL!'
const FILE_ARRAY_HINT_PREFIX := '4/44:'
const FILE := PROPERTY_HINT_FILE_PATH
const FILE_ARRAY := PROPERTY_HINT_TYPE_STRING

const SCENE := '*.tscn,*.glb,*.gltf'
const SCENE_ARRAY := FILE_ARRAY_HINT_PREFIX + '*.tscn,*.glb,*.gltf'

const RESOURCE := '*.tres'
const RESOURCE_ARRAY := FILE_ARRAY_HINT_PREFIX + '*.tres'

const AUDIO_STREAM := '*.ogg'
const AUDIO_STREAM_ARRAY := FILE_ARRAY_HINT_PREFIX + '*.ogg'

const TEXTURE := '*.png,*.jpg,*.jpeg'
const TEXTURE_ARRAY := FILE_ARRAY_HINT_PREFIX + '*.png,*.jpg,*.jpeg'

const NO_LOADER_ASSURANCE := 'no_loader_assurance'
enum Phase {
	## Game Start Phase: Anything that is worth waiting on the initial game
	## load for. Resources needed by singletons or the TitleScreen use this.
	GAME_START,
	## Avatars Phase: For loading Toons and Cogs, which can be quite bulky
	## due to their node count.
	AVATARS,
	## Player Phase: Only loads the Player scene.
	PLAYER,
	## Cog Building Floor Phase: Only loads the Cog Building Scene.
	COG_BLDG_FLOOR,
	## Falling Sequence Phase: Only loads the Falling Scene.
	FALLING_SEQ,
	## Gameplay Phase: Anything else that would occur during regular gameplay,
	## i.e. after the falling sequence or after clicking "Continue [Run]".
	GAMEPLAY,
	## End Phase: An indicator that all (queued) game resources have been loaded.
	END,
}

var current_phase: Phase = Phase.GAME_START
var current_phase_loaded := true
var load_thread := Thread.new()

var queue_dict: Dictionary[Phase, PackedStringArray]
var properties_to_update: Dictionary[String, Array]
var objects_to_path: Dictionary[int, PackedStringArray]
var cache: Dictionary[String, Variant]

signal phase_complete(phase: Phase)

## Returns [true] if the [param phase] is [b]completely[/b] loaded.
func is_phase_loaded(phase: Phase) -> bool:
	return current_phase > phase or (
		current_phase == phase and current_phase_loaded
	)

## Returns a value between [code]0.0[/code] and [code]1.0[/code], representing
## the load progress of the [param phase].
func get_load_progress(phase: Phase) -> float:
	if is_phase_loaded(phase):
		return 1.0
	elif current_phase == phase:
		var phase_paths: PackedStringArray = queue_dict.get(phase, [])
		if not phase_paths:
			return 1.0
		var complete_paths: Array[String]
		for path in phase_paths:
			if path in cache:
				complete_paths.append(path)
		return complete_paths.size() / float(phase_paths.size())
	else:
		return 0.0
	
## A coroutine that awaits until the [param phase] has completely loaded.[br][br]
## Returns immediately if the phase is already completely loaded.
func wait_for_phase(phase: Phase):
	while not is_phase_loaded(phase):
		await phase_complete

## Starts a threaded load of all phases one-by-one, starting at the first phase.
func load_all():
	if current_phase != Phase.GAME_START:
		return
	phase_complete.connect(_load_next_phase)
	load_phase((Phase.GAME_START + 1) as Phase)
	
func _load_next_phase(last_phase: Phase):
	if last_phase + 1 < Phase.END:
		load_phase((last_phase + 1) as Phase)

## Starts loading the [param phase]. If [param blocking] is [code]false[/code],
## this load happens on a thread.
func load_phase(phase: Phase, blocking := false):
	assert(phase > current_phase)
	assert(current_phase_loaded)
	current_phase = phase
	current_phase_loaded = false
	if blocking:
		_load_phase_threaded()
	else:
		load_thread = Thread.new()
		load_thread.start(_load_phase_threaded)

func _load_phase_threaded():
	var value: Variant
	for path in queue_dict.get(current_phase, []):
		value = self.load(path)
		for prop_info in properties_to_update.get(path, []):
			var obj: Object
			var obj_ref: WeakRef = prop_info[0]
			if obj_ref.get_ref():
				obj = obj_ref.get_ref()
			else:
				continue
			var property: String = prop_info[1]
			obj.set(property, value)
		properties_to_update.erase(path)
	current_phase_loaded = true
	phase_complete.emit.bind(current_phase).call_deferred()
	
func _finish_threaded_load(_phase):
	if load_thread.is_started():
		load_thread.wait_to_finish()

## Queues the resource [param paths] to be loaded once the load for the
## [param phase] begins.
func queue(phase: Phase, paths: Array):
	for path: String in paths:
		if path in cache or path in queue_dict.get(phase, []):
			continue
			
		if current_phase >= phase:
			cache[path] = ResourceLoader.load(path)
		elif phase in queue_dict:
			queue_dict[phase].append(path)
		else:
			queue_dict[phase] = PackedStringArray([path])

## Queues resources to be loaded once the load for the [param phase] begins.
## [param prop_to_path] is a [Dictionary] with the values being resource paths,
## and the keys being property names belonging to the given [Object] ([param obj]).
## [br][br]
## When a resource path is loaded, the given properties are automatically set
## to the return value of the load.
## [br][br]
## Additionally, if the [code]Object[/code] is a [Node], this method will also
## connect to its [signal Node.tree_entered] signal to ensure that all its queued
## resources are loaded before its [method Node._ready] method is called.
func queue_into(phase: Phase, obj: Object, prop_to_path: Dictionary[String, String]):
	var path: String
	for prop in prop_to_path.keys():
		path = prop_to_path[prop]
		if path in cache:
			obj.set(prop, cache[path])
			continue
		elif path in queue_dict.get(phase, []):
			properties_to_update[path].append([weakref(obj), prop])
			if obj.get_instance_id() in objects_to_path:
				objects_to_path[obj.get_instance_id()].append(path)
			else:
				objects_to_path[obj.get_instance_id()] = PackedStringArray([path])
			continue
			
		if current_phase >= phase:
			cache[path] = ResourceLoader.load(path)
			obj.set(prop, cache[path])
		else:
			if phase in queue_dict:
				queue_dict[phase].append(path)
			else:
				queue_dict[phase] = PackedStringArray([path])

			if obj.get_instance_id() in objects_to_path:
				objects_to_path[obj.get_instance_id()].append(path)
			else:
				objects_to_path[obj.get_instance_id()] = PackedStringArray([path])
			if path in properties_to_update:
				properties_to_update[path].append([weakref(obj), prop])
			else:
				properties_to_update[path] = [[weakref(obj), prop]]
	
	if (obj is Node and not obj.has_meta(NO_LOADER_ASSURANCE) and
			not obj.tree_entered.is_connected(_obj_ensure_loaded)):
		obj.tree_entered.connect(_obj_ensure_loaded.bind(obj))

## Returns the contents of the [param path] from the GameLoader cache. If the
## resource has not been loaded yet, it is loaded immediately and added to the
## cache before returning.
func load(path: String) -> Variant:
	if path not in cache:
		cache[path] = ResourceLoader.load(path)
	return cache[path]

func _obj_ensure_loaded(obj: Object):
	var value: Variant
	for path in objects_to_path.get(obj.get_instance_id(), []):
		value = self.load(path)
		for prop_info in properties_to_update.get(path, []):
			var other_obj: Object
			var obj_ref: WeakRef = prop_info[0]
			if obj_ref.get_ref():
				other_obj = obj_ref.get_ref()
			else:
				continue
			var property: String = prop_info[1]
			other_obj.set(property, value)
		properties_to_update.erase(path)
