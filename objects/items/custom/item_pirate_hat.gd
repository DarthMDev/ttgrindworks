extends ItemScript

const BEAN_AWARD := 2
const EARN_SFX := preload("res://audio/sfx/ui/tick_counter.ogg")

func on_collect(_item: Item, _model: Node3D) -> void:
	setup()
 
func on_load(_item: Item) -> void:
	setup()

func setup() -> void:
	BattleService.s_battle_participant_died.connect(_participant_died)

func _participant_died(participant: Node3D) -> void:
	if participant is Cog and participant.dna and (participant.dna.is_mod_cog or participant.foreman):
		Util.get_player().stats.add_money(BEAN_AWARD)
		AudioManager.play_sound(EARN_SFX)
