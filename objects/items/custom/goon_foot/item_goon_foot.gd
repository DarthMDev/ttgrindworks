extends ItemScriptActive

const BOOST_AMT := 0.5
const BOOST_TIME := 8.0

const SFX := preload("res://audio/sfx/misc/KART_turboStart.ogg")

func use() -> void:
	AudioManager.play_sound(SFX)
	Util.get_player().boost_queue.queue_text("Speed Boost!", Color.AQUA)
	var stat_mult := StatMultiplier.new()
	stat_mult.stat = 'speed'
	stat_mult.amount = 0.5
	stat_mult.additive = true
	Util.get_player().stats.multipliers.append(stat_mult)
	Task.delayed_call(TaskContainer, BOOST_TIME, Util.get_player().stats.multipliers.erase.bind(stat_mult))
