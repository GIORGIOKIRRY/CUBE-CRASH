extends Node2D

@onready var Sprite: Sprite2D = $Sprite2D
@onready var Player: AnimationPlayer = $AnimationPlayer

@export var color: String
@export var mooves: int = 0
var matched = false

func _ready() -> void:
	_apply_skin()

# Applica la skin selezionata per questo colore (texture + animazione "match").
func _apply_skin() -> void:
	# I pezzi ABILITÀ (mooves>0) NON prendono skin: mantengono la loro grafica.
	# In TEST solo le BOMBE (mooves>=3) diventano GRIGIE (senza colore); le frecce (1/2)
	# restano colorate (si attivano col match di colore).
	if int(mooves) > 0:
		if settings.game_mode == "test" and int(mooves) >= 3 and Sprite:
			var ap := "res://CORE/Assets/Art/Game/Cubes/_ABILITY/ability_%d.png" % int(mooves)
			if ResourceLoader.exists(ap):
				Sprite.texture = load(ap)
		return
	var sk: Dictionary = settings.get_skin(color)
	if sk.is_empty():
		return
	if Sprite:
		Sprite.texture = load(sk["static"])
	var frames: Array = sk.get("frames", [])
	if frames.size() >= 2 and Player:
		var anim := Animation.new()
		var tr := anim.add_track(Animation.TYPE_VALUE)
		anim.track_set_path(tr, "Sprite2D:texture")
		anim.value_track_set_update_mode(tr, Animation.UPDATE_DISCRETE)
		var dt := 0.05
		for i in frames.size():
			anim.track_insert_key(tr, float(i) * dt, load(frames[i]))
		anim.length = float(frames.size()) * dt
		var lib := Player.get_animation_library("")
		if lib:
			if lib.has_animation("match"):
				lib.remove_animation("match")
			lib.add_animation("match", anim)


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
