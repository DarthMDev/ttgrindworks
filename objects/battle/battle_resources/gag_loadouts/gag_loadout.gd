extends Resource
class_name GagLoadout


@export var loadout: Array[Track]

func get_track_of_name(track_name: String) -> Track:
	for track: Track in loadout:
		if track.track_name == track_name:
			return track

	return null

func has_track_of_name(track_name: String) -> bool:
	return get_track_of_name(track_name) != null

func get_action_track(action: ToonAttack) -> Track:
	if action.track: return action.track
	for track in loadout:
		for gag in track.gags:
			if action.action_name == gag.action_name:
				return track
	return
