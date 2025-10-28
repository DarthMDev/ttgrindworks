extends Node
class_name PrankCharger

enum SignalMode {
	ALL,
	ANY,
}
@export var signal_mode := SignalMode.ALL

@export var signals: Dictionary[Node, String] = {}

@export var one_shot := true

@export var charge_amount := 1

var signal_count := 0
var can_charge := true
var signals_emitted := 0


func _ready() -> void:
	for node: Node in signals.keys():
		if node.has_signal(signals[node]):
			if one_shot:
				node.get(signals[node]).connect(signal_passed, CONNECT_ONE_SHOT)
			else:
				node.get(signals[node]).connect(signal_passed)
	signal_count = signals.keys().size()

func charge_prank(charge_count := charge_amount) -> void:
	var player := Util.get_player()
	if not is_instance_valid(player):
		print("Prank Charger: Player not found, can't charge prank.")
		return
	player.stats.charge_active_item(charge_count)

func signal_passed(_arg1 = null, _arg2 = null, _arg3 = null, _arg4 = null) -> void:
	signals_emitted += 1
	if signals_emitted >= signal_count and can_charge:
		charge_prank()
		if one_shot:
			can_charge = false
