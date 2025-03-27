extends PanelContainer


@export var initial_focus: Control


func _on_twitch_pressed() -> void:
	CrowdControl.login(CrowdControl.TWITCH)
	# save to settings the platform that was selected if crowd_control_startup is enabled
	if SaveFileService.settings_file.get("crowd_control_startup") == true:
		SaveFileService.settings_file.set("crowd_control_platform", CrowdControl.TWITCH)
		SaveFileService.save_settings()
	


func _on_youtube_pressed() -> void:
	CrowdControl.login(CrowdControl.YOUTUBE)
	if SaveFileService.settings_file.get("crowd_control_startup") == true:
		SaveFileService.settings_file.set("crowd_control_platform", CrowdControl.YOUTUBE)
		SaveFileService.save_settings()


func _on_discord_pressed() -> void:
	CrowdControl.login(CrowdControl.DISCORD)
	if SaveFileService.settings_file.get("crowd_control_startup") == true:
		SaveFileService.settings_file.set("crowd_control_platform", CrowdControl.DISCORD)
		SaveFileService.save_settings()


func _on_back_pressed() -> void:
	get_parent().hide()
	CrowdControl.close()
