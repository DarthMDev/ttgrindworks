@tool
extends UIPanel

signal s_confirmed
signal s_canceled

@onready var confirm_button : GeneralButton = %ConfirmButton
@onready var canceled_button : GeneralButton = %CancelButton


func confirm() -> void:
	if active:
		s_confirmed.emit()
		close()

func cancel() -> void:
	if active:
		s_canceled.emit()
		close()
