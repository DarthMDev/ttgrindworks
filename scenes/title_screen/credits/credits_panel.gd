@tool
extends UIPanel

@export var credits : Array[GameCredit] = []
@export var special_thanks : Array[GameCredit] = []

@onready var credit_template := $CreditTemplate
@onready var credit_container := $Panel/CreditWindow/ScrollContainer/CreditContainer
@onready var thanks_label := $ThanksLabel
@onready var fakeout := $FakeoutCredit


func _ready() -> void:
	super()
	
	for credit in credits:
		if credit is GameCreditAnimated:
			credit_container.add_child(create_animated_credit(credit))
		else:
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

func create_credit(credit: GameCredit) -> Control:
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
	fakeout.get_node('LabelContainer/GeneralButton').queue_free()
	fakeout.get_node('LabelContainer/Role').show()
	if SaveFileService.is_achievement_unlocked(ProgressFile.GameAchievement.ONE_HUNDRED_PERCENT):
		AudioManager.play_sound(load("res://audio/sfx/misc/MG_sfx_travel_game_bonus.ogg"))
		fakeout.get_node('LabelContainer/Role').set_text("Yes, you!")
	else:
		AudioManager.play_sound(load("res://audio/sfx/misc/MG_neg_buzzer.ogg"))

func create_animated_credit(credit: GameCreditAnimated) -> Control:
	var new_credit := %AnimatedCredit.duplicate()
	
	new_credit.get_node('LabelContainer/Name').set_text(credit.name)
	new_credit.get_node('LabelContainer/Role').set_text(credit.role)
	if credit.label_settings:
		new_credit.get_node('LabelContainer/Name').label_settings = credit.label_settings
	new_credit.get_node('Animation').sprite_frames = credit.sprite_frames
	new_credit.get_node('Animation').play('default')
	new_credit.show()
	return new_credit
