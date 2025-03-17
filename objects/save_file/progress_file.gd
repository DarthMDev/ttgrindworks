extends Resource
class_name ProgressFile


## Actual Progress
@export var characters_unlocked := 1
@export var needs_custom_cog_help := true
@export var cog_creator_unlocked := false

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
@export var boss_cogs_defeated := 0
@export var floors_cleared := 0
@export var deaths := 0
@export var gags_used := 0
@export var total_playtime := 0.0
@export var jellybeans_collected := 0
@export var win_streak := 0
@export var best_time := 0.0


var proxies_unlocked: bool:
	get: return characters_unlocked >= 2

func save_to(file_name: String):
	ResourceSaver.save(self,SaveFileService.SAVE_FILE_PATH + file_name)

## Keep track of player statistics
func start_listening() -> void:
	BattleService.s_battle_started.connect(on_battle_start)
	BattleService.s_boss_died.connect(func(_cog): boss_cogs_defeated += 1)
	Util.s_floor_ended.connect(on_floor_end)
	initialize_achievements()

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
	elif participant is Player:
		deaths += 1
		win_streak = 0

func add_cog_defeat(cog: String) -> void:
	if cogs_defeated.has(cog):
		cogs_defeated[cog] += 1
	else:
		cogs_defeated[cog] = 1

func on_floor_end() -> void:
	floors_cleared += 1

#region ACHIEVEMENTS

var active_achievements: Array[Achievement] = []

func initialize_achievements() -> void:
	for key in ACHIEVEMENT_RESOURCES.keys():
		var achievement: Achievement = load(ACHIEVEMENT_RESOURCES[key])
		active_achievements.append(achievement)
		achievement._setup()

enum GameAchievement {
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
	ONE_HUNDRED_PERCENT
}

const ACHIEVEMENT_RESOURCES := {
	GameAchievement.DEFEAT_COGS_1: "res://objects/save_file/achievements/resources/achievement_one_cog.tres",
	GameAchievement.DEFEAT_COGS_10: "res://objects/save_file/achievements/resources/achievement_ten_cog.tres",
	GameAchievement.DEFEAT_COGS_100: "res://objects/save_file/achievements/resources/achievement_hundred_cog.tres",
	GameAchievement.DEFEAT_COGS_1000: "res://objects/save_file/achievements/resources/achievement_thousand_cog.tres",
	GameAchievement.DEFEAT_COGS_10000: "res://objects/save_file/achievements/resources/achievement_ten_thousand_cog.tres",
	GameAchievement.DEFEAT_BOSSES_1: "res://objects/save_file/achievements/resources/achievement_boss_1.tres",
	GameAchievement.DEFEAT_BOSSES_5: "res://objects/save_file/achievements/resources/achievement_boss_5.tres",
	GameAchievement.DEFEAT_BOSSES_25: "res://objects/save_file/achievements/resources/achievement_boss_25.tres",
	GameAchievement.DEFEAT_BOSSES_100: "res://objects/save_file/achievements/resources/achievement_boss_100.tres",
	GameAchievement.DEFEAT_BOSSES_200: "res://objects/save_file/achievements/resources/achievement_boss_200.tres",
	GameAchievement.DEFEAT_CLOWNS: "res://objects/save_file/achievements/resources/achievement_special_boss_clowns.tres",
	GameAchievement.DEFEAT_SLENDER: "res://objects/save_file/achievements/resources/achievement_special_boss_slendercog.tres",
	GameAchievement.UNLOCK_PROXY_COGS: "res://objects/save_file/achievements/resources/achievement_special_proxy_cogs.tres",
	GameAchievement.UNLOCK_CLARA: "res://objects/save_file/achievements/resources/achievement_unlock_clara.tres",
	GameAchievement.UNLOCK_JULIUS: "res://objects/save_file/achievements/resources/achievement_unlock_wheezer.tres",
	GameAchievement.UNLOCK_BESSIE: "res://objects/save_file/achievements/resources/achievement_unlock_bessie.tres",
	GameAchievement.UNLOCK_MOE: "res://objects/save_file/achievements/resources/achievement_unlock_moe.tres",
	GameAchievement.UNLOCK_RANDOM: "res://objects/save_file/achievements/resources/achievement_unlock_random.tres",
	GameAchievement.DOODLE: "res://objects/save_file/achievements/resources/achievement_doodle.tres",
	GameAchievement.GO_SAD_1: "res://objects/save_file/achievements/resources/achievement_sad_1.tres",
	GameAchievement.GO_SAD_5: "res://objects/save_file/achievements/resources/achievement_sad_5.tres",
	GameAchievement.GO_SAD_10: "res://objects/save_file/achievements/resources/achievement_sad_10.tres",
	GameAchievement.EASTER_EGG_EXPLORER: "res://objects/save_file/achievements/resources/achievement_easteregg_secret_floor.tres",
	GameAchievement.EASTER_EGG_GEAR: "res://objects/save_file/achievements/resources/achievement_easteregg_gears.tres",
	GameAchievement.ONE_HUNDRED_PERCENT: "res://objects/save_file/achievements/resources/achievement_100p.tres"
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
	GameAchievement.ONE_HUNDRED_PERCENT: false
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

#endregion
