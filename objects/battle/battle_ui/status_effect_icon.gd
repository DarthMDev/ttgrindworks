extends Control
class_name StatusEffectIcon

const POSITIVE_ICON := preload("res://ui_assets/battle/positive_icon.png")
const NEGATIVE_ICON := preload("res://ui_assets/battle/negative_icon.png")
const NEUTRAL_ICON := preload("res://ui_assets/battle/neutral_icon.png")

const HOVER_SFX := preload("res://audio/sfx/ui/GUI_rollover.ogg")

@export var effect: StatusEffect:
	set(x):
		effect = x
		refresh()

var is_hovered := false

var hover_seq: Tween:
	set(x):
		if hover_seq and hover_seq.is_valid():
			hover_seq.kill()
		hover_seq = x

static func create() -> StatusEffectIcon:
	return GameLoader.load("res://objects/battle/battle_ui/status_effect_icon.tscn").instantiate()

func _ready() -> void:
	refresh()
	%Icon.mouse_entered.connect(hovered)
	%Icon.mouse_exited.connect(stopped_hover)

func refresh() -> void:
	if get_effect_rounds() == 0 and not effect.rounds == -1:
		queue_free()
	
	# Change background image
	if effect.quality == StatusEffect.EffectQuality.POSITIVE:
		%Background.texture = POSITIVE_ICON
	elif effect.quality == StatusEffect.EffectQuality.NEGATIVE:
		%Background.texture = NEGATIVE_ICON
	elif effect.quality == StatusEffect.EffectQuality.NEUTRAL:
		%Background.texture = NEUTRAL_ICON
	else:
		# Fallback for neutral or whatever
		%Background.texture = NEUTRAL_ICON

	%Icon.texture = effect.get_icon()
	%Icon.self_modulate = effect.get_icon_color()
	%Icon.scale = Vector2.ONE * effect.get_icon_scale()
	%MiniIcon.texture = effect.get_mini_icon()
	%MiniIcon.self_modulate = effect.get_mini_icon_color()
	%MiniIcon.scale = Vector2.ONE * effect.get_mini_icon_scale()
	if effect.rounds == -1:
		%RoundLabel.hide()
	else:
		%RoundLabel.text = str(get_effect_rounds())
		%RoundLabel.show()

func get_effect_rounds() -> int:
	return effect.rounds + 1 + effect.rounds_offset

func _exit_tree() -> void:
	if is_hovered:
		stopped_hover()

func hovered() -> void:
	is_hovered = true
	HoverManager.hover(effect.get_description(), 18, 0.025, effect.get_status_name(), effect.get_title_color())
	hover_seq = Sequence.new([
		LerpProperty.new(self, ^"scale", 0.1, Vector2.ONE * 1.15).interp(Tween.EASE_IN_OUT, Tween.TRANS_QUAD),
	]).as_tween(self)
	AudioManager.play_sound(HOVER_SFX, 6.0)

func stopped_hover() -> void:
	if is_hovered:
		HoverManager.stop_hover()
		is_hovered = false

	hover_seq = Parallel.new([
		LerpProperty.new(self, ^"scale", 0.1, Vector2.ONE).interp(Tween.EASE_IN_OUT, Tween.TRANS_QUAD),
	]).as_tween(self)
