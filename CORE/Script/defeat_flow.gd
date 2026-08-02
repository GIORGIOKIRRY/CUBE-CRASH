extends Node2D

# Flusso di sconfitta:
# 1) striscia nera translucida col motivo (NO SPACE / NO MOVES), sopra il gioco reale
# 2) schermata REVIVE: countdown (animazione) + tasto REVIVE (pubblicità)
# 3) allo scadere -> schermata finale (game over). Se REVIVE -> continua.

signal finished          # vai alla schermata finale
signal revive_requested  # l'utente vuole continuare (pubblicità)

const REVIVE_BTN := preload("res://CORE/Assets/Art/GameOver/revive_button.png")
const FONT := preload("res://CORE/Assets/Font/Jersey10-Regular.ttf")

const COUNT_FRAMES := 125
const COUNT_FPS := 25.0
const COUNT_SECONDS := 5
const REASON_TIME := 1.8

var _band: ColorRect
var _reason_label: Label
var _dim: ColorRect
var _count: AnimatedSprite2D
var _revive_btn: TextureButton
var _revived := false

func _ready() -> void:
	z_index = 200
	visible = false
	_build()

func _build() -> void:
	# --- striscia motivo (fase 1) ---
	_band = ColorRect.new()
	_band.color = Color(0, 0, 0, 0.72)
	_band.position = Vector2(-60, 470)
	_band.size = Vector2(696, 170)
	_band.visible = false
	add_child(_band)

	_reason_label = Label.new()
	_reason_label.position = Vector2(-60, 470)
	_reason_label.size = Vector2(696, 170)
	_reason_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_reason_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_reason_label.add_theme_font_override("font", FONT)
	_reason_label.add_theme_font_size_override("font_size", 92)
	_reason_label.add_theme_color_override("font_color", Color(1, 1, 1))
	_reason_label.visible = false
	add_child(_reason_label)

	# --- dim (fase 2): più scuro così il tasto REVIVE risalta ---
	_dim = ColorRect.new()
	_dim.color = Color(0, 0, 0, 0.8)
	_dim.position = Vector2(-900, -900)
	_dim.size = Vector2(2400, 2800)
	_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dim.visible = false
	add_child(_dim)

	# --- countdown (fase 2): un po' più in alto ---
	# NB: i 125 frame (576x1024, ~295 MB) NON si caricano qui: rallentavano/appesantivano
	# OGNI avvio partita mentre il countdown serve solo al revive (raro). Lazy: vedi _ensure_count_frames().
	_count = AnimatedSprite2D.new()
	_count.position = Vector2(288, 462)
	_count.visible = false
	add_child(_count)

	# --- tasto revive (fase 2): più in basso ---
	_revive_btn = TextureButton.new()
	_revive_btn.texture_normal = REVIVE_BTN
	_revive_btn.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_revive_btn.ignore_texture_size = true
	_revive_btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	_revive_btn.size = Vector2(330, 129)   # più piccolo (aspect 1472:576)
	_revive_btn.position = Vector2(288 - 165, 800)   # centrato
	_revive_btn.visible = false
	_revive_btn.pressed.connect(_on_revive)
	# mini animazione di pressione (affonda + vibra)
	_revive_btn.button_down.connect(func() -> void:
		_revive_btn.position.y += 5.0
		settings.vibrate(15))
	_revive_btn.button_up.connect(func() -> void:
		_revive_btn.position.y -= 5.0)
	add_child(_revive_btn)

# Avvia il flusso. allow_revive=false salta la schermata revive (limite 3/partita).
func start(reason: String, allow_revive: bool = true) -> void:
	visible = true
	_revived = false
	_reason_label.text = "NO MOVES" if reason == "no_moves" else "NO SPACE"
	_band.visible = true
	_reason_label.visible = true
	settings.play_error()   # suono che spiega il motivo (no space / no moves)
	settings.vibrate(30)
	await get_tree().create_timer(REASON_TIME).timeout
	_band.visible = false
	_reason_label.visible = false
	if not allow_revive:
		_hide_all()
		finished.emit()
		return
	_start_revive()

func _ensure_count_frames() -> void:
	if _count.sprite_frames != null:
		return   # già costruito (cache)
	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")
	frames.add_animation("count")
	frames.set_animation_loop("count", false)
	frames.set_animation_speed("count", COUNT_FPS)
	for i in COUNT_FRAMES:
		var tex: Texture2D = load("res://CORE/Assets/Art/GameOver/Countdown/Cube Crash 5 sec_%05d.png" % i)
		if tex:
			frames.add_frame("count", tex)
	_count.sprite_frames = frames

func _start_revive() -> void:
	_ensure_count_frames()   # carica i frame countdown solo ora (lazy)
	_dim.visible = true
	_count.visible = true
	_revive_btn.visible = true
	_count.play("count")
	# vibrazione per ogni secondo che passa
	for s in COUNT_SECONDS:
		settings.vibrate(25)
		await get_tree().create_timer(1.0).timeout
		if _revived:
			return
	_hide_all()
	finished.emit()

func _on_revive() -> void:
	if _revived:
		return
	_revived = true
	settings.button_feedback()
	_hide_all()
	# Rewarded: il revive arriva solo a video completato. Se l'annuncio non
	# è pronto (es. niente rete) il revive è gratis: meglio non punire.
	if not ads.show_rewarded():
		revive_requested.emit()
		return
	var earned := [false]   # array: le lambda GDScript catturano per valore
	var on_earned := func(_amount: int, _type: String) -> void: earned[0] = true
	ads.rewarded_earned.connect(on_earned)
	await ads.rewarded_closed
	await get_tree().process_frame   # assorbe l'ordine deferred dei segnali
	ads.rewarded_earned.disconnect(on_earned)
	if earned[0]:
		revive_requested.emit()
	else:
		# video chiuso in anticipo: niente premio, si va al game over
		finished.emit()

func _hide_all() -> void:
	_count.stop()
	_band.visible = false
	_reason_label.visible = false
	_dim.visible = false
	_count.visible = false
	_revive_btn.visible = false
	visible = false
