extends Control
class_name ChatterboxChoice

@onready var bubble : SpeechBubble2D = $SpeechBubble
@onready var item_rect : TextureRect = $ItemTexture
@onready var vote_label : Label = $VoteLabel
@onready var extra_vote_label : Label = $ExtraVoteLabel
@onready var node_viewer = $NodeViewer
@onready var command : TwitchCommand = $TwitchCommand
@onready var sweetener_labels : Array[Label] = [
	%ChangeStat, %ChangeStat2
]
@onready var sweeteners : Array[Array]:
	set(x):
		for i in x.size():
			if x[i][1] > 0:
				sweetener_labels[i].text = "+"
			elif x[i][1] < 0:
				sweetener_labels[i].text = "-"
			sweetener_labels[i].text += str(abs(x[i][1])) + "% " + x[i][0]
		sweeteners = x
