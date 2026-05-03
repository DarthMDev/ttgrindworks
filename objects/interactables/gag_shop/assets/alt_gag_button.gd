@tool
extends HBoxContainer

@export var gag: ToonAttack:
	set(x):
		gag = x
		refresh()

@export var button_text := "SWAP":
	set(x):
		await NodeGlobals.until_ready(%BuyButton)
		%BuyButton.text = x
	get:
		if not %BuyButton.is_node_ready(): return ""
		return %BuyButton.text

var enabled := true

signal s_pressed


func refresh() -> void:
	if not gag: return
	await NodeGlobals.until_ready(self)
	%Icon.set_texture(gag.icon)
	%GagName.set_text(gag.action_name)
	if not Engine.is_editor_hint():
		%GagSummary.set_text(gag.get_store_summary())

func set_enabled(enable: bool) -> void:
	enabled = enable


func on_press() -> void:
	s_pressed.emit()
