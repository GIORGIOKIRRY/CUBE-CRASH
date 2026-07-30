extends Node2D

@onready var Sprite: Sprite2D = $Sprite2D
@onready var Player: AnimationPlayer = $AnimationPlayer

@export var color: String
@export var mooves: int = 0
var matched = false

#func _ready() -> void:
	#Sprite.texture = 
	

func move(target, dur := 0.3):
	var tween: Tween = create_tween()
	tween.tween_property(self,"position",target, dur).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

func dim():
	Player.active = true
	Player.play("match")
	# pop di scala (ingrandimento) così TUTTI i cubi del match — anche quello appena
	# piazzato — mostrano chiaramente l'animazione prima di distruggersi
	scale = Vector2.ONE
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2(1.18, 1.18), 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_SINE)
