@tool
extends IDResource
class_name StatusEffect

signal s_expire

# General specifiers
enum EffectQuality {
	POSITIVE,
	NEGATIVE,
	NEUTRAL
}

# Effect Specific
@export var quality := EffectQuality.NEUTRAL
@export var rounds := 1
@export var rounds_offset := 0
@export var icon: Texture2D = null
@export var icon_color := Color.WHITE
@export var icon_scale := 1.0
@export var mini_icon: Texture2D = null
@export var mini_icon_color := Color.WHITE
@export var mini_icon_scale := 1.0
@export var visible := true
@export var description := "This is a Status Effect"
@export var status_name := "Status Effect"
@export var is_foreman_effect := false
var target: Actor
var manager: BattleManager

## Called by battle manager on initial application
func apply():
	pass

## Called by battle manager when effect renews at the end of rounds
func renew():
	pass

## Called by battle manager when effect's rounds expire
func expire():
	pass

## Called by the battle manager when the effect is cleaning up from the battle.
func cleanup() -> void:
	pass

func on_death() -> void:
	pass

func get_description() -> String:
	return description

func get_icon() -> Texture2D:
	return icon

func get_mini_icon() -> Texture2D:
	return mini_icon

func get_icon_color() -> Color:
	return icon_color

func get_mini_icon_color() -> Color:
	return mini_icon_color

func get_icon_scale() -> float:
	return icon_scale

func get_mini_icon_scale() -> float:
	return mini_icon_scale

func get_status_name() -> String:
	return status_name

func get_title_color() -> Color:
	match quality:
		EffectQuality.POSITIVE: return Color(0.0, 0.602, 0.186)
		EffectQuality.NEGATIVE: return Color(0.937, 0.278, 0.278)
		_: return Color(0.353, 0.443, 0.898)

## Override this to use custom combine logic for status effects
func combine(_effect: StatusEffect) -> bool:
	return false

## Override this to change how an effect randomizes itself
func randomize_effect() -> void:
	rounds = randi_range(1, 3)


static var registry: DynamicRegistry = null

static func load_registry() -> void:
	if Engine.is_editor_hint():
		return
	if not registry:
		registry = get_fresh_registry(StatusEffect)

static func get_registry_path() -> String:
	return "res://objects/battle/battle_resources/status_effects/resources"
