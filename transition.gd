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
	_sprite.visible = false
	# scala/posizione calcolate a runtime in _fit_to_screen() così copre
	# sempre tutto lo schermo su qualsiasi dispositivo (stretch "expand").

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

# Adatta lo sprite al rettangolo visibile reale del viewport, con margine,
# così copre SEMPRE tutto lo schermo (alto, basso e lati) su ogni dispositivo.
func _fit_to_screen() -> void:
	var vr := get_viewport().get_visible_rect()
	var tex := _sprite.sprite_frames.get_frame_texture("cover", 0)
	var ts := tex.get_size()   # 800 x 1400
	# scala per COPRIRE (max sui due assi) + margine di sicurezza
	var sc: float = maxf(vr.size.x / ts.x, vr.size.y / ts.y) * 1.25
	_sprite.scale = Vector2(sc, sc)
	_sprite.position = vr.position + vr.size * 0.5

# Cambia scena con transizione fluida: copri -> cambia -> scopri.
func change_scene(path: String) -> void:
	if _busy:
		return
	_busy = true
	# Avvia il caricamento in BACKGROUND subito, così avviene DURANTE il wipe (niente
	# freeze su device lenti): la scena si carica mentre la copertura si anima.
	ResourceLoader.load_threaded_request(path)
	_fit_to_screen()
	_sprite.visible = true
	_sprite.play("cover")
	await _sprite.animation_finished
	# schermo coperto: attende che il caricamento (in parallelo al wipe) sia pronto
	var packed: PackedScene = null
	while true:
		var st := ResourceLoader.load_threaded_get_status(path)
		if st == ResourceLoader.THREAD_LOAD_LOADED:
			packed = ResourceLoader.load_threaded_get(path)
			break
		elif st == ResourceLoader.THREAD_LOAD_FAILED or st == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			break
		await get_tree().process_frame
	# cambio scena senza che si veda lo stacco
	if packed != null:
		get_tree().change_scene_to_packed(packed)
	else:
		get_tree().change_scene_to_file(path)   # fallback
	await get_tree().process_frame
	await get_tree().process_frame
	_sprite.play("reveal")
	await _sprite.animation_finished
	_sprite.visible = false
	_busy = false
