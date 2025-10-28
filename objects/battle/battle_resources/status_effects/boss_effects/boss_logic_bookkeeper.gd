@tool
extends StatusEffect
class_name BookkeeperLogic

var bookkeeper: Cog:
	get: return target

# Called by battle manager on initial application
func apply():
	rounds = -1
	manager.s_round_started.connect(round_started)

func cleanup() -> void:
	if manager.s_round_started.is_connected(round_started):
		manager.s_round_started.disconnect(round_started)

func round_started(_actions: Array[BattleAction]) -> void:
	# Cook the books: Every 5 rounds, starting on round 2
	if manager.current_round % 5 == 2:
		cook_the_books()
	# Financial report: Every 2 rounds, starting on round 1
	if manager.current_round % 2 == 1:
		financial_report()
	# Mental Math: Every 4 rounds, starting on round 2
	if manager.current_round % 4 == 2:
		mental_math()
	# Ponzi Scheme: Every 4 rounds, starting on round 4
	if manager.current_round % 4 == 0:
		ponzi_scheme()

func cook_the_books() -> void:
	var cooked := load("res://objects/battle/battle_resources/misc_movies/bookkeeper/bk_cook_the_books.tres").duplicate(true)
	cooked.targets = [Util.get_player()]
	cooked.user = bookkeeper
	manager.round_end_actions.append(cooked)

func financial_report() -> void:
	var report := load("res://objects/battle/battle_resources/misc_movies/bookkeeper/bk_financial_report.tres").duplicate(true)
	report.targets = [Util.get_player()]
	report.user = bookkeeper
	manager.round_end_actions.append(report)

func mental_math() -> void:
	var mm := load("res://objects/battle/battle_resources/misc_movies/bookkeeper/bk_mental_math.tres").duplicate(true)
	mm.user = bookkeeper
	manager.round_end_actions.append(mm)

func ponzi_scheme() -> void:
	var ps := load("res://objects/battle/battle_resources/misc_movies/bookkeeper/bk_ponzi_scheme.tres").duplicate(true)
	ps.user = bookkeeper
	manager.round_end_actions.append(ps)
