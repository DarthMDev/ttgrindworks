extends Resource

enum CogDept {
	SELL,
	CASH,
	LAW,
	BOSS,
	NULL,
}
@export var department := CogDept.SELL

enum SuitType {
	SUIT_A,
	SUIT_B,
	SUIT_C
}
@export var suit := SuitType.SUIT_A

@export var custom_blazer_tex: Texture2D
@export var custom_arm_tex: Texture2D
@export var custom_leg_tex: Texture2D
@export var custom_wrist_tex: Texture2D
@export var custom_hand_tex: Texture2D
@export var custom_shoe_tex: Texture2D

@export var cog_name: String = "Cog"
@export var name_plural: String = ""
@export var name_prefix := ""
@export var name_suffix := ""
@export var head: PackedScene
@export var head_scale: Vector3 = Vector3.ONE
@export var head_pos: Vector3 = Vector3.ZERO
@export var scale: float = 1.0
@export var head_textures: Array[Texture2D]
@export var head_shader: CogShader
@export var hand_color: Color = Color.WHITE
@export var head_color: Color = Color.WHITE
@export var custom_nametag_height := 0.0
@export var custom_nametag_suffix := ""
@export var can_speak := true

@export var attacks: Array[CogAttack]
@export var level_low := 1
@export var level_high := 12
@export var status_effects: Array[StatusEffect]
@export var is_mod_cog := false
@export var is_admin := false
@export var health_mod := 1.0

@export_multiline var battle_phrases: Array[String] = ["We are gonna fight now."]
@export var battle_start_movie: BattleStartMovie

@export var external_assets := {
	head_model = "",
	head_textures = [],
	attacks = [],
	custom_blazer_tex = "",
	custom_arm_tex = "",
	custom_wrist_tex = "",
	custom_hand_tex = "",
	custom_shoe_tex = ""
}
