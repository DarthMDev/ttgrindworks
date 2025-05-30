extends Cog

const PHRASES := [
	"Buzz off, Toon. Can't you see I'm busy?",
	"I have a lot of work to get done.",
	"I don't have time for you, gnat.",
	"You can't even begin to comprehend what I'm capable of.",
	"I haven't had a day off in five years.",
	"I've spent my entire life behind bars.",
	"If I wasn't so busy with my work, you'd be sad in an instant.",
	"I tried to leave once, but this place is like a labyrinth...",
	"Go away.",
	"I'm busy.",
	"You're in no position to meet with me.",
	"Knock it off.",
	"Leave.",
	"Leave me be.",
	"This is a bad time.",
	"I've stepped up the corporate ladder.",
	"I'm the boss.",
	"Corporate doesn't let me out on the green.",
	"You're really teeing me off.",
	"Nope. Not getting out of my chair.",
]
const COOLDOWN := 5.0

var last_phrase_idx := -1
var can_interact := true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()
	set_animation("sit")

func _on_brush_off_body_entered(_body: Node3D) -> void:
	if not can_interact:
		return
	if _body is Player:
		can_interact = false
		speak(pick_phrase())
		await Task.delay(COOLDOWN)
		can_interact = true

func pick_phrase() -> String:
	var phrases := PHRASES.duplicate()
	if last_phrase_idx != -1:
		phrases.erase(PHRASES[last_phrase_idx])
	var new_phrase: String = phrases[RandomService.randi_channel('true_random') % phrases.size()]
	last_phrase_idx = PHRASES.find(new_phrase)
	return new_phrase

func _on_mole_stomp_game_failed() -> void:
	speak("I wouldn't have gotten hit by that.")
