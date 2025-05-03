extends Sprite3D

## Amount of Gags a voucher restores
const VALUE := 5

## Don't mind the fact that it don't look right in the preview
## It looks correct in game for some reason?!?!

# Child references
@onready var ticket := $SubViewport/Ticket
@onready var gag := $SubViewport/Ticket/Gag

# Locals
var resource: Item
var gag_track: String

func setup(item: Item):
	resource = item
	
	
	if not resource.arbitrary_data.has('gag_track'):
		# Find the gag tracks that the player has access to
		var tracks := []
		var player := Util.get_player()
		
		if not player:
			player = await Util.s_player_assigned
		
		for track in player.stats.gags_unlocked.keys():
			tracks.append(track)
		
		if tracks.is_empty():
			gag_track = player.stats.gags_unlocked.keys()[RandomService.randi_channel('gag_vouchers')%player.stats.gags_unlocked.keys().size()]
		else:
			gag_track = tracks[RandomService.randi_channel('gag_vouchers') % tracks.size()]
		resource.arbitrary_data['gag_track'] = gag_track
		resource.item_description = "+%d %s points!" %[VALUE, gag_track]
		resource.big_description = resource.item_description
	else:
		gag_track = resource.arbitrary_data['gag_track']
	
	gag.texture = get_icon()

func collect() -> void:
	Util.get_player().stats.gag_vouchers[gag_track] += 1

func modify(model: Sprite3D):
	model.gag.texture = gag.texture
	model.ticket.modulate = ticket.modulate

func get_icon() -> Texture2D:
	var player := Util.get_player()
	var loadout: Array[Track] = player.stats.character.gag_loadout.loadout

	var track: Track
	for entry in loadout:
		if entry.track_name == gag_track:
			track = entry
			break
	return track.gags[0].icon
