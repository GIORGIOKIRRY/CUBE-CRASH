extends Control

@onready var music_player := %AudioStreamPlayer2D



func _ready() -> void:
	settings.play_music(music_player.stream)


func _on_play_button_pressed() -> void:
	settings.play_playbutton()
	settings.vibrate(15)
	transition.change_scene("res://CORE/Scene/game.tscn")


func _on_settings_button_pressed() -> void:
	settings.button_feedback()
	%SettingsMenu.visible = true


# Link in alto a sinistra: condividi il gioco (App Store)
func _on_link_button_pressed() -> void:
	settings.button_feedback()
	OS.shell_open(settings.APPSTORE_URL)


# Pergamena in alto a destra: apre la sezione ringraziamenti
func _on_terms_button_pressed() -> void:
	settings.button_feedback()
	%SettingsMenu.open_thanks_from_home()
