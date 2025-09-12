@tool
extends UIPanel

@export var credits : Array[GameCredit] = []
@export var special_thanks : Array[GameCredit] = []
@export var mod_credits : Array[GameCredit] = []
@export var mod_thanks : Array[GameCredit] = []

@onready var credit_template := $CreditTemplate
@onready var credit_container := $Panel/CreditWindow/ScrollContainer/CreditContainer
@onready var thanks_label := $ThanksLabel
@onready var thanks_label2 := $ThanksLabel2
@onready var fakeout := $FakeoutCredit


func _ready() -> void:
	super()
	
	for credit in credits:
		credit_container.add_child(create_credit(credit))
	var new_thanks_label := thanks_label.duplicate()
	new_thanks_label.show()
	credit_container.add_child(new_thanks_label)
	for credit in special_thanks:
		credit_container.add_child(create_credit(credit))
	
	# Set up devious prank
	var new_fakeout := fakeout.duplicate()
	credit_container.add_child(new_fakeout)
	new_fakeout.show()
	fakeout = new_fakeout
	
#	var new_thanks_label2 := thanks_label2.duplicate()
#	new_thanks_label2.show()
#	for credit in mod_credits:
#		credit_container.add_child(create_credit(credit))

func create_credit(credit : GameCredit) -> Control:
	var new_credit := credit_template.duplicate()
	if credit.icon:
		new_credit.get_node('Icon').set_texture(credit.icon)
	new_credit.get_node('LabelContainer/Name').set_text(credit.name)
	new_credit.get_node('LabelContainer/Role').set_text(credit.role)
	if credit.label_settings:
		new_credit.get_node('LabelContainer/Name').label_settings = credit.label_settings
	new_credit.show()
	return new_credit

func do_fakeout() -> void:
	AudioManager.play_sound(load("res://audio/sfx/misc/MG_neg_buzzer.ogg"))
	fakeout.get_node('LabelContainer/GeneralButton').queue_free()
	fakeout.get_node('LabelContainer/Role').show()
