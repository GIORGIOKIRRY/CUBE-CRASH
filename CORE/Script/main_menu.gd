extends Control

@onready var music_player := %AudioStreamPlayer2D



func _ready() -> void:
	settings.register_music(music_player)


func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file("res://CORE/Scene/game.tscn")


func _on_settings_button_pressed() -> void:
	%SettingsMenu.visible = true
