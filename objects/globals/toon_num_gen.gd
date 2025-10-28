@tool
extends RefCounted
class_name ToonNumGen

var _seed := 0
var state: int:
	get: return _rng.state
	set(x): _rng.state = x

var true_random := false
var lock_state := false:
	set(x):
		lock_state = x
		_initial_state = state if x else 0
var _initial_state := 0

var _rng := RandomNumberGenerator.new()

func _init(p_seed := -1, p_state := 0, p_lock_state := false) -> void:
	if p_seed == -1:
		p_seed = Time.get_ticks_msec()
	_seed = p_seed
	_rng.seed = _seed
	if p_state != 0:
		state = p_state
	lock_state = p_lock_state

func randf() -> float:
	check_state_lock()
	if true_random: return randf()
	return _rng.randf()

func randf_range(a := 0.0, b := 1.0) -> float:
	check_state_lock()
	if true_random: return randf_range(a, b)
	return _rng.randf_range(a, b)

func randi() -> int:
	check_state_lock()
	if true_random: return randi()
	return _rng.randi()

func randi_range(a := 0, b := 1) -> int:
	check_state_lock()
	if true_random: return randi_range(a, b)
	return _rng.randi_range(a, b)
	
func rand_weighted(weights: PackedFloat32Array) -> int:
	check_state_lock()
	if true_random: return RandomNumberGenerator.new().rand_weighted(weights)
	return _rng.rand_weighted(weights)

func pick_random(array: Array) -> Variant:
	check_state_lock()
	if true_random: return array.pick_random()
	return array[self.randi_range(0, array.size() - 1)]

func shuffle(array: Array) -> void:
	check_state_lock()
	if true_random: array.shuffle(); return
	var stored_array := array.duplicate()
	array.clear()
	while stored_array:
		var value = self.pick_random(stored_array)
		stored_array.erase(value)
		array.append(value)

func chance(x: float) -> bool:
	check_state_lock()
	if true_random: return randf() <= x
	return self.randf() <= x

func sign() -> int:
	check_state_lock()
	return 1 if self.chance(0.50) else -1

func check_state_lock() -> void:
	if lock_state:
		state = _initial_state
