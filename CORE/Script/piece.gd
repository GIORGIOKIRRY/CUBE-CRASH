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
		if int(mooves) <= 2:
			_apply_arrow_skin()   # FRECCE (V/O): nuova grafica animata dedicata (se presente per il colore)
		elif settings.game_mode == "test" and Sprite:
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


# FRECCE (mooves 1/2): grafica dedicata a 6 frame per colore (a riposo = frame 1, rottura = 1..6).
# Se i frame per il colore non ci sono ancora, resta la grafica SVG originale.
func _apply_arrow_skin() -> void:
	if Sprite == null:
		return
	var cap := String(color).capitalize()   # "red" -> "Red"
	var dir := "res://CORE/Assets/Art/Game/Cubes/_PLUS/%s/" % cap
	if not ResourceLoader.exists(dir + "ab_1.png"):
		return
	Sprite.texture = load(dir + "ab_1.png")
	Sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# freccia ORIZZONTALE (mooves 2): grafica ruotata di 90° (il frame è "verticale")
	Sprite.rotation = deg_to_rad(90.0) if int(mooves) == 2 else 0.0
	var frames: Array = []
	for i in range(1, 7):
		var p := dir + "ab_%d.png" % i
		if ResourceLoader.exists(p):
			frames.append(load(p))
	if frames.size() < 2 or Player == null:
		return
	var anim := Animation.new()
	var tr := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(tr, "Sprite2D:texture")
	anim.value_track_set_update_mode(tr, Animation.UPDATE_DISCRETE)
	var dt := 0.05
	for i in frames.size():
		anim.track_insert_key(tr, float(i) * dt, frames[i])
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
	# piazzato — mostrano chiaramente l'animazione prima di distruggersi.
	# RELATIVO alla scala attuale del cubo: in storia (griglie 3×3/5×5) i cubi sono più
	# grandi (scale > 1); NON resettare a 1, altrimenti l'animazione li rimpicciolisce.
	var base_scale := scale
	if base_scale.x <= 0.01:
		base_scale = Vector2.ONE
	var tw := create_tween()
	tw.tween_property(self, "scale", base_scale * 1.18, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "scale", base_scale, 0.16).set_trans(Tween.TRANS_SINE)
