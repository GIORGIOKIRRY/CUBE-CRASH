extends CanvasLayer

# ============================================================
# Autoload "transition" — transizione a schermo tra le scene.
# Un wipe blu copre lo schermo; quando è tutto coperto (niente
# più visibile) cambia scena, poi scopre la nuova schermata.
# Persistente: sopravvive al cambio scena (layer alto).
# ============================================================

const FRAME_DIR := "res://CORE/Assets/Art/UI/Transition/"
const COVER_FRAMES := 14      # frame 0..13  -> copertura
const TOTAL_FRAMES := 28      # frame 0..27  -> copertura + scopertura
const FPS := 42.0             # velocità wipe (originale 25 fps, più scattante)

var _sprite: AnimatedSprite2D
var _busy := false

func _ready() -> void:
	layer = 128   # sopra a tutto (game over 99999 usa z_index in-scena, qui è un layer)
	_build()

func _build() -> void:
	_sprite = AnimatedSprite2D.new()
	_sprite.centered = true
	_sprite.position = Vector2(288, 512)   # centro viewport base 576x1024
	_sprite.scale = Vector2(0.75, 0.75)    # 800x1400 * .75 = 600x1050, copre tutto lo schermo
	_sprite.visible = false

	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")

	frames.add_animation("cover")
	frames.set_animation_loop("cover", false)
	frames.set_animation_speed("cover", FPS)
	for i in COVER_FRAMES:
		var t: Texture2D = load(FRAME_DIR + "t_%03d.png" % i)
		if t:
			frames.add_frame("cover", t)

	frames.add_animation("reveal")
	frames.set_animation_loop("reveal", false)
	frames.set_animation_speed("reveal", FPS)
	for i in range(COVER_FRAMES, TOTAL_FRAMES):
		var t: Texture2D = load(FRAME_DIR + "t_%03d.png" % i)
		if t:
			frames.add_frame("reveal", t)

	_sprite.sprite_frames = frames
	add_child(_sprite)

# Cambia scena con transizione fluida: copri -> cambia -> scopri.
func change_scene(path: String) -> void:
	if _busy:
		return
	_busy = true
	_sprite.visible = true
	_sprite.play("cover")
	await _sprite.animation_finished
	# schermo tutto coperto: cambio scena senza che si veda lo stacco
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	await get_tree().process_frame
	_sprite.play("reveal")
	await _sprite.animation_finished
	_sprite.visible = false
	_busy = false
