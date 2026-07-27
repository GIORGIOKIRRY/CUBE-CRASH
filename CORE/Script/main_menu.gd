extends Control

@onready var music_player := %AudioStreamPlayer2D

const MODE_FONT := preload("res://CORE/Assets/Font/Jersey10-Regular.ttf")

# Sfondo + cabinato sono lo STESSO canvas 800x1400 (sovrapposti 1:1).
const ART_SIZE := Vector2(800.0, 1400.0)
const ART_CENTER := Vector2(400.0, 700.0)
const CAMERA_CENTER := Vector2(288.0, 512.0)
const ART_SCALE := 0.9
const BOTTOM_MARGIN := 0.0

# Animazione cabinato (riflesso sul marquee): 12 frame, poi fermo 15s, poi riparte.
const CAB_FPS := 12.0
const CAB_HOLD := 15.0

# Tasto PLAY sul deck (coord canvas 800x1400). Asset BASE 272x96, PREMUTO 272x88.
# Dimensionato per LARGHEZZA (altezza dall'aspect dell'asset), ancorato per il BASSO.
const PLAY_TEX_BASE := Vector2(272.0, 96.0)
const PLAY_TEX_PRESSED := Vector2(272.0, 88.0)
const PLAY_WIDTH_ART := 216.0                # larghezza voluta nel canvas
const PLAY_CENTER_ART := Vector2(399.0, 687.0) # centro dello SCHERMO del cabinato
const SPARKLE_OFFSET_Y := 0.0                # scintille al centro del tasto

# Test A/B/C: 3 modalità (nel sottomenu). Poi ne resterà una.
const MODES := [
	{"mode": "classic", "label": "CLASSIC",  "sub": "mosse attuali",         "color": Color(0.20, 0.55, 0.80)},
	{"mode": "mode_a",  "label": "MOD A",     "sub": "ogni azione = 1 mossa",  "color": Color(0.90, 0.55, 0.15)},
	{"mode": "mode_b",  "label": "MOD B",     "sub": "no mosse (block blast)", "color": Color(0.25, 0.70, 0.35)},
	{"mode": "mode_c",  "label": "MOD C",     "sub": "fusione + combo + bombe", "color": Color(0.70, 0.30, 0.80)},
]

var _background: Sprite2D
var _cabinet: AnimatedSprite2D
var _hold_timer: Timer

# Il tasto è fatto di Sprite2D (Node2D) per stare nello STESSO spazio del cabinato
# col Camera2D (i Control verrebbero renderizzati con un offset). Input gestito a mano.
var _play_base: Sprite2D
var _play_pressed: Sprite2D
var _play_world_center := Vector2.ZERO
var _play_world_size := Vector2.ZERO
var _play_pressing := false
var _sparkles: CPUParticles2D
var _mode_menu: Control

var _art_pos := CAMERA_CENTER


func _ready() -> void:
	settings.play_music(music_player.stream)
	_build_scene()
	_build_play_button()
	_build_mode_menu()
	_layout()
	get_viewport().size_changed.connect(_layout)


func _art_to_world(art: Vector2) -> Vector2:
	return _art_pos + (art - ART_CENTER) * ART_SCALE


# Ancora la scena arcade in basso e la scala; riposiziona anche tasto e scintille.
func _layout() -> void:
	var view_size := get_viewport_rect().size
	var bottom_y := CAMERA_CENTER.y + view_size.y * 0.5 - BOTTOM_MARGIN
	_art_pos = Vector2(CAMERA_CENTER.x, bottom_y - (ART_SIZE.y - ART_CENTER.y) * ART_SCALE)

	for s: Node2D in [_background, _cabinet]:
		if s:
			s.position = _art_pos
			s.scale = Vector2(ART_SCALE, ART_SCALE)

	_position_play_button()


# --- Sfondo + cabinato animato -------------------------------------------------
func _build_scene() -> void:
	_background = Sprite2D.new()
	_background.texture = load("res://CORE/Assets/Art/Home/background.png")
	_background.z_index = -4
	add_child(_background)

	var frames := SpriteFrames.new()
	frames.add_animation("play")
	frames.set_animation_loop("play", false)
	frames.set_animation_speed("play", CAB_FPS)
	for i in range(1, 13):
		frames.add_frame("play", load("res://CORE/Assets/Art/Home/Cabinet/cabinet_%02d.png" % i))

	_cabinet = AnimatedSprite2D.new()
	_cabinet.sprite_frames = frames
	_cabinet.animation = "play"
	_cabinet.z_index = -2
	add_child(_cabinet)

	_hold_timer = Timer.new()
	_hold_timer.one_shot = true
	_hold_timer.wait_time = CAB_HOLD
	_hold_timer.timeout.connect(_replay_cabinet)
	add_child(_hold_timer)

	_cabinet.animation_finished.connect(_on_cabinet_finished)
	_cabinet.frame = 0
	_cabinet.play("play")


func _on_cabinet_finished() -> void:
	_hold_timer.start()


func _replay_cabinet() -> void:
	_cabinet.frame = 0
	_cabinet.play("play")


# --- Tasto PLAY + scintille ----------------------------------------------------
func _build_play_button() -> void:
	# Scintille bianche "sbrilluccicose" dal centro del tasto, dietro di esso.
	_sparkles = CPUParticles2D.new()
	_sparkles.texture = _make_pixel_texture()
	_sparkles.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sparkles.z_index = -1                       # dietro al tasto (z=0), davanti al cabinato (z=-2)
	_sparkles.amount = 46
	_sparkles.lifetime = 1.0
	_sparkles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	_sparkles.emission_sphere_radius = 26.0      # nascono al centro, dietro il tasto
	_sparkles.direction = Vector2(0, -1)
	_sparkles.spread = 180.0                     # in tutte le direzioni -> attorno al tasto
	_sparkles.gravity = Vector2.ZERO
	_sparkles.initial_velocity_min = 45.0
	_sparkles.initial_velocity_max = 105.0
	_sparkles.scale_amount_min = 2.5
	_sparkles.scale_amount_max = 4.5
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.25, 1.0])
	grad.colors = PackedColorArray([Color(1, 1, 1, 0), Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	_sparkles.color_ramp = grad
	add_child(_sparkles)

	# Tasto: due Sprite2D (base + premuto, allineati in basso). Input a mano in _input().
	_play_base = Sprite2D.new()
	_play_base.texture = load("res://CORE/Assets/Art/Home/play_base.png")
	_play_base.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_play_base.z_index = 0
	add_child(_play_base)

	_play_pressed = Sprite2D.new()
	_play_pressed.texture = load("res://CORE/Assets/Art/Home/play_pressed.png")
	_play_pressed.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_play_pressed.z_index = 0
	_play_pressed.visible = false
	add_child(_play_pressed)


func _make_pixel_texture() -> ImageTexture:
	var img := Image.create(2, 2, false, Image.FORMAT_RGBA8)
	img.fill(Color(1, 1, 1, 1))
	return ImageTexture.create_from_image(img)


# Posiziona/scala il tasto (Sprite2D) e le scintille secondo l'ancoraggio corrente.
func _position_play_button() -> void:
	if not _play_base:
		return
	var center := _art_to_world(PLAY_CENTER_ART)
	# scala mondo dello sprite: porta l'asset (272px) alla larghezza voluta nel canvas
	var s := (PLAY_WIDTH_ART / PLAY_TEX_BASE.x) * ART_SCALE
	var base_disp := PLAY_TEX_BASE * s        # dimensioni a schermo (mondo) del base
	var pressed_disp := PLAY_TEX_PRESSED * s

	_play_base.position = center
	_play_base.scale = Vector2(s, s)

	# premuto allineato in basso (stesso bordo inferiore del base) -> sembra affondare
	_play_pressed.scale = Vector2(s, s)
	_play_pressed.position = Vector2(center.x, center.y + (base_disp.y - pressed_disp.y) * 0.5)

	# rettangolo di hit nel mondo (per _input)
	_play_world_center = center
	_play_world_size = base_disp

	_sparkles.position = _art_to_world(Vector2(PLAY_CENTER_ART.x, PLAY_CENTER_ART.y + SPARKLE_OFFSET_Y))
	_sparkles.scale = Vector2(ART_SCALE, ART_SCALE)


# Input a mano: press/release testati sul rettangolo-mondo del tasto (mouse + touch).
func _input(event: InputEvent) -> void:
	if _mode_menu == null or _mode_menu.visible:
		return
	if not (event is InputEventMouseButton or event is InputEventScreenTouch):
		return
	var world: Vector2 = get_viewport().get_canvas_transform().affine_inverse() * event.position
	var rect := Rect2(_play_world_center - _play_world_size * 0.5, _play_world_size)
	var inside := rect.has_point(world)
	if event.pressed:
		if inside:
			_play_pressing = true
			_on_play_down()
	elif _play_pressing:
		_play_pressing = false
		_on_play_up()
		if inside:
			_on_play_pressed()


func _on_play_down() -> void:
	settings.button_feedback()
	_play_base.visible = false
	_play_pressed.visible = true
	_sparkles.emitting = false


func _on_play_up() -> void:
	_play_base.visible = true
	_play_pressed.visible = false
	# se non si apre il menu (rilascio fuori dal tasto), le scintille riprendono
	_sparkles.emitting = not _mode_menu.visible


func _on_play_pressed() -> void:
	_open_mode_menu()


# --- Sottomenu scelta modalità -------------------------------------------------
func _build_mode_menu() -> void:
	_mode_menu = Control.new()
	_mode_menu.set_anchors_preset(Control.PRESET_FULL_RECT)
	_mode_menu.z_index = 900
	_mode_menu.visible = false
	add_child(_mode_menu)

	# fondo scuro: chiude toccando fuori
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.offset_left = -900.0
	dim.offset_top = -900.0
	dim.offset_right = 1500.0
	dim.offset_bottom = 2000.0
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(_on_dim_input)
	_mode_menu.add_child(dim)

	var title := Label.new()
	title.text = "SCEGLI MODALITÀ"
	title.add_theme_font_override("font", MODE_FONT)
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Color(1, 1, 1))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size = Vector2(360, 50)
	title.position = Vector2(CAMERA_CENTER.x - 180, 350)
	_mode_menu.add_child(title)

	var w := 320.0
	var h := 88.0
	var gap := 18.0
	var x := CAMERA_CENTER.x - w * 0.5
	var y0 := 430.0
	for i in MODES.size():
		var m: Dictionary = MODES[i]
		var btn := Button.new()
		btn.position = Vector2(x, y0 + i * (h + gap))
		btn.size = Vector2(w, h)
		btn.focus_mode = Control.FOCUS_NONE

		var sb := StyleBoxFlat.new()
		sb.bg_color = m["color"]
		sb.set_corner_radius_all(18)
		sb.shadow_color = Color(0, 0, 0, 0.35)
		sb.shadow_size = 6
		sb.shadow_offset = Vector2(0, 4)
		var sb_pressed := sb.duplicate()
		sb_pressed.bg_color = m["color"].darkened(0.2)
		btn.add_theme_stylebox_override("normal", sb)
		btn.add_theme_stylebox_override("hover", sb)
		btn.add_theme_stylebox_override("pressed", sb_pressed)
		btn.add_theme_stylebox_override("focus", sb)

		var t := Label.new()
		t.text = m["label"]
		t.add_theme_font_override("font", MODE_FONT)
		t.add_theme_font_size_override("font_size", 42)
		t.add_theme_color_override("font_color", Color(1, 1, 1))
		t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		t.position = Vector2(0, 6)
		t.size = Vector2(w, 50)
		btn.add_child(t)

		var s := Label.new()
		s.text = m["sub"]
		s.add_theme_font_override("font", MODE_FONT)
		s.add_theme_font_size_override("font_size", 20)
		s.add_theme_color_override("font_color", Color(1, 1, 1, 0.85))
		s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		s.position = Vector2(0, 54)
		s.size = Vector2(w, 28)
		btn.add_child(s)

		btn.pressed.connect(_start_mode.bind(m["mode"]))
		_mode_menu.add_child(btn)


func _open_mode_menu() -> void:
	_sparkles.emitting = false
	_mode_menu.visible = true


func _close_mode_menu() -> void:
	_mode_menu.visible = false
	_sparkles.emitting = true


func _on_dim_input(event: InputEvent) -> void:
	var tap: bool = (event is InputEventMouseButton and not event.pressed) \
		or (event is InputEventScreenTouch and not event.pressed)
	if tap:
		settings.button_feedback()
		_close_mode_menu()


func _start_mode(mode: String) -> void:
	settings.game_mode = mode
	settings.play_playbutton()
	settings.vibrate(15)
	transition.change_scene("res://CORE/Scene/game.tscn")


func _on_settings_button_pressed() -> void:
	settings.button_feedback()
	%SettingsMenu.visible = true


# Link in alto a sinistra: condividi il gioco (App Store)
func _on_link_button_pressed() -> void:
	settings.button_feedback()
	OS.shell_open(settings.APPSTORE_URL)


# Pergamena in alto a destra: apre le PATCH NOTES (novità della versione)
func _on_terms_button_pressed() -> void:
	settings.button_feedback()
	%SettingsMenu.open_patchnotes_from_home()
