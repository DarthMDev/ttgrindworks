extends FloorModifier

## Phrases the Cogs in the HCGC will say.
const STARTER_PHRASES : Array[String] = [
	"This place gives me the creeps...",
	"You should run while you have the chance, Toon.",
	"They said that thing came from the Factory.",
	"Why did I have to get the graveyard shift?",
	"Did you hear something...?",
	"Trust me, going sad is preferable to finding out what lies ahead.",
	"Run back to the playground before it's too late.",
	"It already knows you're here.",
	"The last Toon who came through here never made it out.",
	"It's not too late to turn back, you know.",
	"It's not safe here, Toon.",
]

const V2_CHANCE := 0.05
const PHRASE_CHANCE := 1.0 / 3.0

## 5% for cogs to be v2.0
func modify_floor() -> void:
	game_floor.s_cog_spawned.connect(
		func(cog: Cog): 
			if cog.dna or cog.skelecog:
				return
			if RandomService.randf_channel('true_random') < V2_CHANCE:
				cog.v2 = true
				cog.skelecog_chance = 0
			cog.s_dna_set.connect(cog_dna_set.bind(cog))
	)

func cog_dna_set(cog : Cog) -> void:
	if RandomService.randf_channel('true_random'):
		cog.dna.battle_phrases = STARTER_PHRASES.duplicate()

func get_mod_name() -> String:
	return "SpookyStuff"
