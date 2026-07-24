extends Node2D

# Schermata di caricamento: logo + animazione cubi (frame PNG),
# poi transizione automatica alla home.

const FRAME_COUNT := 49
const FPS := 24.0
const MIN_TIME := 2.2  # durata minima a schermo

@onready var anim: AnimatedSprite2D = $Anim

func _ready() -> void:
	# camera per centrare il design 576x1024 nel viewport (stretch "expand")
	var cam := Camera2D.new()
	cam.position = Vector2(288, 512)
	add_child(cam)
	cam.make_current()

	_build_frames()

	await get_tree().create_timer(MIN_TIME).timeout
	get_tree().change_scene_to_file("res://CORE/Scene/MainMenu.tscn")

func _build_frames() -> void:
	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")
	frames.add_animation("load")
	frames.set_animation_loop("load", true)
	frames.set_animation_speed("load", FPS)
	for i in FRAME_COUNT:
		var path := "res://CORE/Assets/Art/Loading/CARICAMENTO_%05d.png" % i
		var tex: Texture2D = load(path)
		if tex:
			frames.add_frame("load", tex)
	anim.sprite_frames = frames
	anim.play("load")
