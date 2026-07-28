extends Node2D

@onready var music_player := %AudioStreamPlayer2D

func _ready() -> void:
	settings.play_music(music_player.stream)
	_center_content()
	# Banner AdMob ancorato in basso, visibile solo durante il gameplay
	# (tutte le modalità: classic, A/B/C e speedrun usano questa scena).
	ads.show_banner()

func _exit_tree() -> void:
	ads.hide_banner()

# Centra il design 576x1024 nel viewport (stretch "expand") spostando la camera.
func _center_content() -> void:
	var cam := Camera2D.new()
	cam.position = Vector2(288, 512)
	cam.ignore_rotation = true
	add_child(cam)
	cam.make_current()
