extends CCEffect

class_name CCRandomVoucher

var voucher: Item
# Gives the toon a random voucher
func _trigger(_instance: CCEffectInstance) -> EffectResult:
	var player = Util.get_player()
	voucher = ItemService.get_random_voucher()
	voucher.apply_item(player)        
	voucher.play_collection_sound()
	return SUCCESS

func _can_run() -> bool:
	var player = Util.get_player()    
	return player != null and player.stats.hp > 0
