extends Node2D

@onready var Sprite: Sprite2D = $Sprite2D
@onready var Player: AnimationPlayer = $AnimationPlayer

@export var color: String
@export var mooves: int = 0
var matched = false

#func _ready() -> void:
	#Sprite.texture = 
	

func move(target):
	var tween: Tween = create_tween()
	tween.tween_property(self,"position",target, 0.3).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

func dim():
	Player.active = true
	#var sprite = get_node("Sprite2D")
	#sprite.modulate = Color(1,1,1,.5)
	Player.play("match")
