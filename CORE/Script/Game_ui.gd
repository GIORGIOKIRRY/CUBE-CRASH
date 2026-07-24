extends Control

@onready var SettingsMenu = %SettingsMenu
signal MenuOpen

func _ready() -> void:
	SettingsMenu.visible = false

func _on_back_button_pressed() -> void:
	settings.button_feedback()
	get_tree().change_scene_to_file("res://CORE/Scene/MainMenu.tscn")

func _on_settings_button_pressed() -> void:
	settings.button_feedback()
	SettingsMenu.visible = true
	MenuOpen.emit()
