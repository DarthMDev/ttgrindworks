extends Control
class_name ChatterboxChoice

@onready var bubble : SpeechBubble2D = $SpeechBubble
@onready var item_rect : TextureRect = $ItemTexture
@onready var vote_label : Label = $VoteLabel
@onready var extra_vote_label : Label = $ExtraVoteLabel
@onready var node_viewer = $NodeViewer
@onready var command : TwitchCommand = $TwitchCommand
