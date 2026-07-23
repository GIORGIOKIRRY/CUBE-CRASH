extends Node2D

@onready var music_player := %AudioStreamPlayer2D

func _ready() -> void:
	settings.register_music(music_player)
