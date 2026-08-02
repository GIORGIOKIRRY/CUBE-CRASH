extends Node2D

# Schermata di caricamento (all'apertura del gioco):
# sfondo pixel adattivo (no stretch) + frame in basso con LOADING... / barra gialla / XX%.
# Riproduce la voce "Cube Crash" all'avvio, poi passa alla home.

const MIN_TIME := 2.8   # durata a schermo = durata riempimento barra
const BG := preload("res://CORE/Assets/Art/Loading/loading_bg.png")
const FRAME := preload("res://CORE/Assets/Art/Loading/loading_frame.png")
const FONT := preload("res://CORE/Assets/Font/Jersey10-Regular.ttf")
const VOICE_PATH := "res://CORE/Assets/Music&Sound/cube_crash_voice.mp3"

var _bar_fill: ColorRect
var _bar_shine: ColorRect
var _bar_track_w: float = 0.0
var _pct_label: Label

func _ready() -> void:
	# nascondi i vecchi nodi (logo + animazione cubi): ora usiamo il nuovo layout
	if has_node("Logo"):
		$Logo.visible = false
	if has_node("Anim"):
		$Anim.visible = false

	_build_ui()
	_play_voice()

	# riempimento barra 0 -> 100%, poi vai alla home con la transizione
	# (copre lo stacco: niente schermo nero). La musica parte con la home.
	var t := create_tween()
	t.tween_method(_set_progress, 0.0, 1.0, MIN_TIME)
	await t.finished
	if transition and transition.has_method("change_scene"):
		transition.change_scene("res://CORE/Scene/MainMenu.tscn")
	else:
		get_tree().change_scene_to_file("res://CORE/Scene/MainMenu.tscn")

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)

	# --- sfondo a tutto schermo, adattivo, SENZA stretch (crop-to-fill) ---
	var bg := TextureRect.new()
	bg.texture = BG
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(bg)

	var vp := get_viewport().get_visible_rect().size

	# --- frame in basso (immagine, aspect 1792:672) ---
	var fw := minf(vp.x * 0.9, 520.0)
	var fh := fw * 672.0 / 1792.0
	var frame := TextureRect.new()
	frame.texture = FRAME
	frame.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame.stretch_mode = TextureRect.STRETCH_SCALE
	frame.size = Vector2(fw, fh)
	frame.position = Vector2((vp.x - fw) * 0.5, vp.y - fh - vp.y * 0.07)   # frame più in basso
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(frame)

	# --- contenuto dentro il frame: LOADING... / barra / XX% ---
	var pad_x := fw * 0.11
	var pad_y := fh * 0.15
	var inner_w := fw - pad_x * 2.0
	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = pad_x
	vbox.offset_right = -pad_x
	# contenuto un po' più in ALTO dentro il frame (padding sotto maggiore)
	vbox.offset_top = pad_y * 0.55
	vbox.offset_bottom = -pad_y * 1.7
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", int(fh * 0.012))   # LOADING vicino a barra e %
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(vbox)

	# LOADING...
	var lo := Label.new()
	lo.text = "LOADING..."
	lo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lo.add_theme_font_override("font", FONT)
	lo.add_theme_font_size_override("font_size", int(fh * 0.24))
	lo.add_theme_color_override("font_color", Color(1, 1, 1))
	lo.add_theme_color_override("font_outline_color", Color(0.01, 0.06, 0.2))
	lo.add_theme_constant_override("outline_size", 6)
	vbox.add_child(lo)

	# barra gialla in stile pixel (bordo scuro + fondo + riempimento)
	var border := maxf(3.0, fh * 0.03)
	var bar_h := fh * 0.20
	var bar_wrap := Control.new()
	bar_wrap.custom_minimum_size = Vector2(inner_w, bar_h)
	bar_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var outer := ColorRect.new()
	outer.color = Color(0.01, 0.06, 0.2)   # bordo navy scuro
	outer.set_anchors_preset(Control.PRESET_FULL_RECT)
	outer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar_wrap.add_child(outer)
	var trackbg := ColorRect.new()
	trackbg.color = Color(0.12, 0.17, 0.36)   # fondo barra
	trackbg.set_anchors_preset(Control.PRESET_FULL_RECT)
	trackbg.offset_left = border
	trackbg.offset_top = border
	trackbg.offset_right = -border
	trackbg.offset_bottom = -border
	trackbg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar_wrap.add_child(trackbg)
	var fill := ColorRect.new()
	fill.color = Color(1.0, 0.82, 0.08)   # giallo
	fill.position = Vector2(border, border)
	fill.size = Vector2(0.0, bar_h - border * 2.0)
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar_wrap.add_child(fill)
	# riflesso chiaro in alto (pixel style)
	var shine := ColorRect.new()
	shine.color = Color(1.0, 0.93, 0.5)
	shine.position = Vector2(border, border)
	shine.size = Vector2(0.0, maxf(2.0, (bar_h - border * 2.0) * 0.28))
	shine.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar_wrap.add_child(shine)
	_bar_shine = shine
	_bar_fill = fill
	_bar_track_w = inner_w - border * 2.0
	vbox.add_child(bar_wrap)

	# XX%
	_pct_label = Label.new()
	_pct_label.text = "0%"
	_pct_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pct_label.add_theme_font_override("font", FONT)
	_pct_label.add_theme_font_size_override("font_size", int(fh * 0.20))
	_pct_label.add_theme_color_override("font_color", Color(1, 1, 1))
	_pct_label.add_theme_color_override("font_outline_color", Color(0.01, 0.06, 0.2))
	_pct_label.add_theme_constant_override("outline_size", 5)
	vbox.add_child(_pct_label)

func _set_progress(k: float) -> void:
	var kk := clampf(k, 0.0, 1.0)
	if is_instance_valid(_bar_fill):
		_bar_fill.size.x = _bar_track_w * kk
	if is_instance_valid(_bar_shine):
		_bar_shine.size.x = _bar_track_w * kk
	if is_instance_valid(_pct_label):
		_pct_label.text = "%d%%" % int(round(kk * 100.0))

func _play_voice() -> void:
	var stream := load(VOICE_PATH)
	if stream == null:
		return
	var p := AudioStreamPlayer.new()
	p.stream = stream
	p.bus = "Master"
	add_child(p)
	p.play()
