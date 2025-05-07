# this effect will generate a random doodle and give it to the player
extends CCEffect
class_name CCDoodle


func _trigger(_instance: CCEffectInstance) -> EffectResult:
	var player = Util.get_player()
	# Load and instantiate the doodle
	var doodle : RoamingDoodle = load('res://objects/doodle/roaming_doodle/roaming_doodle.tscn').instantiate()
	SceneLoader.add_persistent_node(doodle)
	doodle.doodle.hide()
	doodle.shadow.hide()

	# Apply random DNA to the doodle
	var doodle_dna := DoodleDNA.new()
	doodle_dna.randomize_dna()
	doodle.doodle.dna = doodle_dna
	doodle.doodle.apply_dna()

	# Add the doodle to the player's partners
	player.partners.append(doodle)

	# Set the doodle's state after a delay
	await Task.delay(1.0)
	doodle.state = RoamingDoodle.DoodleState.AWAIT
	return SUCCESS

func _can_run() -> bool:
	var player = Util.get_player()
	if player != null and player.stats.hp > 0:
		return true
	return false
