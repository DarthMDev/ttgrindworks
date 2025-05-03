@tool
extends StatusEffect
class_name StatusEffectDiminishingReturns


@export var bean_count := 1
@export var diminish_factor := 0.8

var just_applied := true

func renew() -> void:
	if just_applied:
		just_applied = false
		return
	bean_count = floori(bean_count * diminish_factor)
	if bean_count <= 0:
		manager.expire_status_effect(self)

func cleanup() -> void:
	Util.get_player().stats.add_money(bean_count)
	bean_count = 0

func get_description() -> String:
	if bean_count == 1:
		return "Defeat this Cog to get 1 jellybean back"
	return "Defeat this Cog to get %d jellybeans back" % bean_count

func combine(effect : StatusEffect) -> bool:
	if 'bean_count' in effect:
		bean_count += effect.bean_count
		return true
	return false
