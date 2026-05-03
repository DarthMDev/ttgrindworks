extends Resource
class_name ProgressFile


## Actual Progress
@export var characters_unlocked := 1
@export var needs_custom_cog_help := true
@export var cog_creator_unlocked := false
@export var mystery_toon_win := false
@export var stranger_met := false

## Fun statistics
## Accounted for v
@export var new_games := 0
@export var cogs_defeated := {}
var total_cogs_defeated : int:
	get: 
		var total_cogs := 0
		for cog in cogs_defeated.keys():
			total_cogs += cogs_defeated[cog]
		return total_cogs
@export var proxy_cogs_defeated := 0
@export var boss_cogs_defeated := 0
@export var floors_cleared := 0
@export var deaths := 0
@export var gags_used := 0
@export var total_playtime := 0.0:
	set(x):
		if is_nan(x):
			return
		total_playtime = maxf(0.0, x)
@export var jellybeans_collected := 0
@export var win_streak := 0
@export var wins := 0
@export var best_time := 0.0
@export var high_score := 0
@export var pocket_pranks_used := 0

## Item Specific stat tracking
@export_storage var special_chests_opened: int = 0
@export_storage var times_jumped: int = 0
@export_storage var times_stranger_seen: int = 0
@export_storage var paint_silo_victories: int = 0


var proxies_unlocked: bool:
	get: return characters_unlocked >= 2
	
func save_to(file_name: String):
	ResourceSaver.save(self,SaveFileService.SAVE_FILE_PATH + file_name)

## Keep track of player statistics
func start_listening() -> void:
	BattleService.s_battle_started.connect(on_battle_start)
	BattleService.s_boss_died.connect(func(_cog): boss_cogs_defeated += 1)
	Util.s_floor_ended.connect(on_floor_end)
	Globals.s_game_win.connect(on_game_win)
	initialize_achievements()
	run_infer_checks()

func on_battle_start(manager: BattleManager) -> void:
	manager.s_round_started.connect(on_round_start)
	manager.s_participant_died.connect(battle_participant_died)

func on_round_start(actions: Array[BattleAction]) -> void:
	for action in actions:
		if action is ToonAttack and not action.action_name == "Attack":
			gags_used += 1

func battle_participant_died(participant: Node3D) -> void:
	if participant is Cog:
		if participant.fusion:
			add_cog_defeat('other')
		else:
			add_cog_defeat(participant.dna.cog_name)
			if participant.dna.is_mod_cog:
				proxy_cogs_defeated += 1
	## The Player object will report its death to us, so we don't need this
	elif participant is Player:
		pass

func on_player_died() -> void:
	if win_streak > 0: win_streak = 0
	else: win_streak -= 1

func add_cog_defeat(cog: String) -> void:
	if cogs_defeated.has(cog):
		cogs_defeated[cog] += 1
	else:
		cogs_defeated[cog] = 1

func on_floor_end() -> void:
	floors_cleared += 1

func on_game_win() -> void:
	wins += 1
	if win_streak <= 0:
		win_streak = 1
	else:
		win_streak += 1

#region ACHIEVEMENTS

var active_achievements: Array[Achievement] = []

func initialize_achievements() -> void:
	for key in ACHIEVEMENT_RESOURCES.keys():
		var achievement: Achievement = load(ACHIEVEMENT_RESOURCES[key])
		active_achievements.append(achievement)
		achievement._setup()

enum GameAchievement {
	# 1.0 Achievements
	DEFEAT_COGS_1,
	DEFEAT_COGS_10,
	DEFEAT_COGS_100,
	DEFEAT_COGS_1000,
	DEFEAT_COGS_10000,
	DEFEAT_BOSSES_1,
	DEFEAT_BOSSES_5,
	DEFEAT_BOSSES_25,
	DEFEAT_BOSSES_100,
	DEFEAT_BOSSES_200,
	DEFEAT_CLOWNS,
	DEFEAT_SLENDER,
	UNLOCK_PROXY_COGS,
	UNLOCK_JULIUS,
	UNLOCK_CLARA,
	UNLOCK_BESSIE,
	UNLOCK_MOE,
	UNLOCK_RANDOM,
	DOODLE,
	GO_SAD_1,
	GO_SAD_5,
	GO_SAD_10,
	EASTER_EGG_EXPLORER,
	EASTER_EGG_GEAR,
	ONE_HUNDRED_PERCENT,
	
	# 1.1 Achievements
	WIN_GAME_HOUR,
	FLIPPY_GETS_BUCKET,

	# 1.2 Achievements
	UNLOCK_PETE,
	UNLOCK_OLDMAN,
	DEFEAT_LIQUIDATOR,
	MEET_STRANGER,
	UNLOCK_LAW_BOOK,
	UNLOCK_DAGGER,
	UNLOCK_DILLY_DIAL,
	UNLOCK_PHILOSOPHERS_STONE,
	UNLOCK_BIRD_WINGS,
	UNLOCK_WEIRD_GLASSES,
	UNLOCK_ROLODEX,
	UNLOCK_WINGTIPS,
	UNLOCK_RAINBOW_JELLYBEAN,
}

const PATH := "res://objects/save_file/achievements/resources/"
const ACHIEVEMENT_RESOURCES := {
	GameAchievement.DEFEAT_COGS_1: PATH + "achievement_one_cog.tres",
	GameAchievement.DEFEAT_COGS_10: PATH + "achievement_ten_cog.tres",
	GameAchievement.DEFEAT_COGS_100: PATH + "achievement_hundred_cog.tres",
	GameAchievement.DEFEAT_COGS_1000: PATH + "achievement_thousand_cog.tres",
	GameAchievement.DEFEAT_COGS_10000: PATH + "achievement_ten_thousand_cog.tres",
	GameAchievement.DEFEAT_BOSSES_1: PATH + "achievement_boss_1.tres",
	GameAchievement.DEFEAT_BOSSES_5: PATH + "achievement_boss_5.tres",
	GameAchievement.DEFEAT_BOSSES_25: PATH + "achievement_boss_25.tres",
	GameAchievement.DEFEAT_BOSSES_100: PATH + "achievement_boss_100.tres",
	GameAchievement.DEFEAT_BOSSES_200: PATH + "achievement_boss_200.tres",
	GameAchievement.DEFEAT_CLOWNS: PATH + "achievement_special_boss_clowns.tres",
	GameAchievement.DEFEAT_SLENDER: PATH + "achievement_special_boss_slendercog.tres",
	GameAchievement.UNLOCK_PROXY_COGS: PATH + "achievement_special_proxy_cogs.tres",
	GameAchievement.UNLOCK_CLARA: PATH + "achievement_unlock_clara.tres",
	GameAchievement.UNLOCK_JULIUS: PATH + "achievement_unlock_wheezer.tres",
	GameAchievement.UNLOCK_BESSIE: PATH + "achievement_unlock_bessie.tres",
	GameAchievement.UNLOCK_MOE: PATH + "achievement_unlock_moe.tres",
	GameAchievement.UNLOCK_RANDOM: PATH + "achievement_unlock_random.tres",
	GameAchievement.DOODLE: PATH + "achievement_doodle.tres",
	GameAchievement.GO_SAD_1: PATH + "achievement_sad_1.tres",
	GameAchievement.GO_SAD_5: PATH + "achievement_sad_5.tres",
	GameAchievement.GO_SAD_10: PATH + "achievement_sad_10.tres",
	GameAchievement.EASTER_EGG_EXPLORER: PATH + "achievement_easteregg_secret_floor.tres",
	GameAchievement.EASTER_EGG_GEAR: PATH + "achievement_easteregg_gears.tres",
	GameAchievement.ONE_HUNDRED_PERCENT: PATH + "achievement_100p.tres",
	GameAchievement.WIN_GAME_HOUR: PATH + "achievement_one_hour.tres",
	GameAchievement.FLIPPY_GETS_BUCKET: PATH + "achievement_bucket.tres",
	GameAchievement.UNLOCK_PETE: PATH + "achievement_unlock_pete.tres",
	GameAchievement.UNLOCK_OLDMAN: PATH + "achievement_unlock_oldman.tres",
	GameAchievement.DEFEAT_LIQUIDATOR: PATH + "achievement_special_boss_liquidator.tres",
	GameAchievement.MEET_STRANGER: PATH + "achievement_meet_stranger.tres",
	GameAchievement.UNLOCK_LAW_BOOK: PATH + "achievement_item_law_book.tres",
	GameAchievement.UNLOCK_DAGGER: PATH + "achievement_item_dagger.tres",
	GameAchievement.UNLOCK_DILLY_DIAL: PATH + "achievement_item_dilly_dial.tres",
	GameAchievement.UNLOCK_PHILOSOPHERS_STONE: PATH + "achievement_item_philosophers_stone.tres",
	GameAchievement.UNLOCK_BIRD_WINGS: PATH + "achievement_item_bird_wings.tres",
	GameAchievement.UNLOCK_WEIRD_GLASSES: PATH + "achievement_item_weird_glasses.tres",
	GameAchievement.UNLOCK_ROLODEX: PATH + "achievement_item_rolodex.tres",
	GameAchievement.UNLOCK_WINGTIPS: PATH + "achievement_item_wingtips.tres",
	GameAchievement.UNLOCK_RAINBOW_JELLYBEAN: PATH + "achievement_item_rainbow_jellybean.tres",
}

@export var achievements_earned := {
	GameAchievement.DEFEAT_COGS_1: false,
	GameAchievement.DEFEAT_COGS_10: false,
	GameAchievement.DEFEAT_COGS_100: false,
	GameAchievement.DEFEAT_COGS_1000: false,
	GameAchievement.DEFEAT_COGS_10000: false,
	GameAchievement.DEFEAT_BOSSES_1: false,
	GameAchievement.DEFEAT_BOSSES_5: false,
	GameAchievement.DEFEAT_BOSSES_25: false,
	GameAchievement.DEFEAT_BOSSES_100: false,
	GameAchievement.DEFEAT_BOSSES_200: false,
	GameAchievement.DEFEAT_CLOWNS: false,
	GameAchievement.DEFEAT_SLENDER: false,
	GameAchievement.UNLOCK_PROXY_COGS: false,
	GameAchievement.UNLOCK_JULIUS: false,
	GameAchievement.UNLOCK_CLARA: false,
	GameAchievement.UNLOCK_BESSIE: false,
	GameAchievement.UNLOCK_MOE: false,
	GameAchievement.UNLOCK_RANDOM: false,
	GameAchievement.DOODLE: false,
	GameAchievement.GO_SAD_1: false,
	GameAchievement.GO_SAD_5: false,
	GameAchievement.GO_SAD_10: false,
	GameAchievement.EASTER_EGG_EXPLORER: false,
	GameAchievement.EASTER_EGG_GEAR: false,
	GameAchievement.ONE_HUNDRED_PERCENT: false,
	GameAchievement.WIN_GAME_HOUR: false,
	GameAchievement.FLIPPY_GETS_BUCKET: false,
	GameAchievement.UNLOCK_PETE: false,
	GameAchievement.UNLOCK_OLDMAN: false,
	GameAchievement.DEFEAT_LIQUIDATOR: false,
	GameAchievement.MEET_STRANGER: false,
	GameAchievement.UNLOCK_LAW_BOOK: false,
	GameAchievement.UNLOCK_DAGGER: false,
	GameAchievement.UNLOCK_DILLY_DIAL: false,
	GameAchievement.UNLOCK_PHILOSOPHERS_STONE: false,
	GameAchievement.UNLOCK_BIRD_WINGS: false,
	GameAchievement.UNLOCK_WEIRD_GLASSES: false,
	GameAchievement.UNLOCK_ROLODEX: false,
	GameAchievement.UNLOCK_WINGTIPS: false,
	GameAchievement.UNLOCK_RAINBOW_JELLYBEAN: false,
}

var achievement_count: int:
	get:
		var counter := 0
		for achievement in achievements_earned.keys():
			if achievements_earned[achievement] == true:
				counter += 1
		return counter

func unlock_achievement(id: GameAchievement) -> void:
	if ACHIEVEMENT_RESOURCES.has(id):
		var new_unlock: Achievement = load(ACHIEVEMENT_RESOURCES[id])
		new_unlock.unlock()

func get_achievement_unlocked(achievement : GameAchievement) -> bool:
	if not achievement in achievements_earned.keys():
		return false
	return achievements_earned[achievement]

#endregion

func run_infer_checks() -> void:
	# Check for initial wins
	if wins == 0:
		wins = characters_unlocked - 1
	
