extends CCEffect

class_name CCRandomVoucher

var voucher: Item
var player = Util.get_player()

# Gives the toon a random voucher
func _trigger(_instance: CCEffectInstance) -> EffectResult:
    voucher = ItemService.get_random_voucher()
    voucher.apply_item(player)        
        
    return SUCCESS

func _can_run() -> bool:    
    return player != null and player.stats.hp > 0