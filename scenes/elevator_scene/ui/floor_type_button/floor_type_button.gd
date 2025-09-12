extends Control

const STAR_EMPTY := preload("res://ui_assets/misc/quality_star_unfilled.png")
const STAR_FILLED := preload("res://ui_assets/misc/quality_star.png")

@export var floor_variant: FloorVariant:
	set(x):
		floor_variant = x
		apply_variant(x)

@onready var floor_label := $FloorTitle
@onready var level_range_label := $LevelRange
@onready var danger_meter := $DangerMeter
@onready var anomaly_label := $Anomalies

var reward_item: Item
var is_hovering := false

signal s_floor_selected(floor: FloorVariant)

func _ready() -> void:
	%NodeViewer.mouse_entered.connect(hover_item)
	%NodeViewer.mouse_exited.connect(func(): HoverManager.stop_hover(); is_hovering = false)

func hover_item() -> void:
	if reward_item:
		Util.do_item_hover(reward_item)
		is_hovering = true

func apply_variant(variant: FloorVariant) -> void:
	floor_label.set_text(variant.floor_name)
	set_danger(variant.floor_difficulty)
	set_anomalies(variant.anomaly_count)
	level_range_label.set_text("Level Range: " + str(variant.level_range.x) + "-" + str(variant.level_range.y))
	if variant.reward:
		set_reward(variant.reward)
	if is_hovering:
		HoverManager.stop_hover()
		hover_item()

func start_floor() -> void:
	s_floor_selected.emit(floor_variant)
	if floor_variant.discard_item:
		ItemService.seen_item(floor_variant.discard_item)
	
	if not floor_variant.reward:
		return
	
	# Mark item as in play
	ItemService.item_created(floor_variant.reward)
	if Util.s_floor_ended.is_connected(ItemService.item_removed):
		Util.s_floor_ended.disconnect(ItemService.item_removed)
	Util.s_floor_ended.connect(ItemService.item_removed.bind(floor_variant.reward))

func set_danger(danger_index: int) -> void:
	# Get the stars:
	var stars := danger_meter.get_children()
	# Remove danger label
	stars.remove_at(0)
	
	# Set the textures of the stars based on the danger level
	for i in stars.size():
		if i < danger_index:
			stars[i].texture = STAR_FILLED
			edit_stars(stars[i])
		
		else:
			stars[i].texture = STAR_EMPTY

func set_anomalies(anomaly_count: int) -> void:
	var color: Color
	if anomaly_count == 0:
		color = Color.GREEN
	else:
		color = Color.RED
	anomaly_label.set_text("Anomalies: " + str(anomaly_count))
	anomaly_label.label_settings.font_color = color

func set_reward(item: Item) -> void:
	# Add new reward to menu
	reward_item = item
	var reward_model = item.model.instantiate()
	%NodeViewer.camera_position_offset = item.ui_cam_offset
	%NodeViewer.node = reward_model
	%NodeViewer.want_spin_tween = item.want_ui_spin
	
	# Let item set itself up
	if reward_model.has_method('setup'):
		reward_model.setup(item)

func edit_stars(star) -> void:
	#if floor_variant.floor_name == "Overclocked Fight The Foremen":
		#star.modulate = Color(0.45, 0.0, 0.45)
	if floor_variant.floor_name == "Survive The Foremen":
		star.modulate = Color.CRIMSON
	else:
		star.modulate = Color.WHITE
		
	
