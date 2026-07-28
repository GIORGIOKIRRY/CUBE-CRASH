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
const CAB_HOLD := 6.0    # 1s di animazione + 6s di pausa = ripete ~ogni 7s

# Tasto PLAY sul deck (coord canvas 800x1400). Asset BASE 272x96, PREMUTO 272x88.
# Dimensionato per LARGHEZZA (altezza dall'aspect dell'asset), ancorato per il BASSO.
const PLAY_TEX_BASE := Vector2(272.0, 96.0)
const PLAY_TEX_PRESSED := Vector2(272.0, 88.0)
const PLAY_WIDTH_ART := 260.0                # larghezza voluta nel canvas
const PLAY_CENTER_ART := Vector2(399.0, 887.0) # centro dello SCHERMO del cabinato (abbassato)
const SPARKLE_OFFSET_Y := 0.0                # scintille al centro del tasto

# Frecce cambia-modalità ai lati dello schermo del cabinato (asset 88x136, punta a DESTRA).
# La sinistra è la stessa freccia specchiata (flip_h).
const ARROW_TEX := Vector2(88.0, 136.0)
const ARROW_WIDTH_ART := 90.0
const ARROW_L_CENTER_ART := Vector2(146.0, 664.0)
const ARROW_R_CENTER_ART := Vector2(652.0, 664.0)
# Centro dello SCHERMO del cabinato: qui compare la modalità selezionata
const SCREEN_CENTER_ART := Vector2(399.0, 690.0)
# Animazione a schermo (dietro il cabinato, incastrata nel buco 367x271 centro (399,688))
const SCREEN_ANIM_TEX := Vector2(768.0, 576.0)
const SCREEN_ANIM_CENTER_ART := Vector2(399.0, 688.0)
const SCREEN_ANIM_WIDTH_ART := 372.0        # copre il buco; il bordo si infila sotto il cabinato
const SCREEN_ANIM_FPS := 10.0

# Test A/B/C: 3 modalità (nel sottomenu). Poi ne resterà una.
const MODES := [
	{"mode": "mode_c",   "label": "CLASSIC",  "sub": "combo + bombe",         "color": Color(0.70, 0.30, 0.80)},
	{"mode": "speedrun", "label": "SPEEDRUN", "sub": "piu punti in 5 minuti", "color": Color(0.95, 0.35, 0.15)},
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

# Frecce laterali + display modalità sullo schermo
var _arrow_l_base: Sprite2D
var _arrow_l_pressed: Sprite2D
var _arrow_r_base: Sprite2D
var _arrow_r_pressed: Sprite2D
var _arrow_l_center := Vector2.ZERO
var _arrow_r_center := Vector2.ZERO
var _arrow_hit_size := Vector2.ZERO
var _arrow_l_pressing := false
var _arrow_r_pressing := false
var _arrow_l_sparkles: CPUParticles2D
var _arrow_r_sparkles: CPUParticles2D
var _mode_index := 0
var _mode_screen: Node2D
var _mode_screen_label: Label
var _mode_screen_sub: Label
var _screen_anim: AnimatedSprite2D
var _mode_anims := {}                       # mode -> SpriteFrames (animazione a schermo)
var _screen_title: Sprite2D                 # scritta (es. CLASSIC) sopra l'animazione
var _mode_titles := {}                      # mode -> Texture2D (scritta a schermo)

# Missioni (tastino TEMPORANEO + pannello, design provvisorio)
var _missions_button: Button
var _coin_label: Label
var _missions_menu: Control
var _missions_list: VBoxContainer
var _missions_coins_label: Label
var _missions_timer_label: Label

# Menu bar in basso (missioni / home / shop)
const NAV_TEX := Vector2(1600.0, 432.0)
var _nav_bar: TextureRect
var _nav_btns: Array = []
var _nav_textures := {}
var _tab := "home"
var _shop_menu: Control

var _art_pos := CAMERA_CENTER


func _ready() -> void:
	settings.play_music(music_player.stream)
	_build_scene()
	_build_play_button()
	_build_screen_anim()
	_build_mode_screen()
	_build_arrows()
	_build_mode_menu()
	_build_missions_menu()
	_build_shop_menu()
	_build_nav_bar()
	_layout()
	get_viewport().size_changed.connect(_layout)
	_select_tab("home", false)


func _art_to_world(art: Vector2) -> Vector2:
	return _art_pos + (art - ART_CENTER) * ART_SCALE


# Ancora la scena arcade in basso e la scala; riposiziona anche tasto e scintille.
func _layout() -> void:
	var view_size := get_viewport_rect().size
	# barra nav in basso, full-width; altezza basata su una larghezza di riferimento
	# limitata (576 = base di design) così su schermi larghi (iPad) non diventa enorme
	var nav_h := minf(view_size.x, 620.0) * (NAV_TEX.y / NAV_TEX.x)
	if _nav_bar:
		_nav_bar.position = Vector2(0, view_size.y - nav_h)
		_nav_bar.size = Vector2(view_size.x, nav_h)
		for i in _nav_btns.size():
			var b: Button = _nav_btns[i]
			b.position = Vector2(view_size.x * i / 3.0, 0.0)
			b.size = Vector2(view_size.x / 3.0, nav_h)
	# cabinato ancorato al LIMITE INFERIORE (la barra ci passa sopra, è su un CanvasLayer)
	var bottom_y := CAMERA_CENTER.y + view_size.y * 0.5
	_art_pos = Vector2(CAMERA_CENTER.x, bottom_y - (ART_SIZE.y - ART_CENTER.y) * ART_SCALE)

	for s: Node2D in [_background, _cabinet]:
		if s:
			s.position = _art_pos
			s.scale = Vector2(ART_SCALE, ART_SCALE)

	_position_play_button()
	_position_arrows()
	if _mode_screen:
		_mode_screen.position = _art_to_world(SCREEN_CENTER_ART)
		_mode_screen.scale = Vector2(ART_SCALE, ART_SCALE)
	if _screen_anim:
		_screen_anim.position = _art_to_world(SCREEN_ANIM_CENTER_ART)
		var sc := (SCREEN_ANIM_WIDTH_ART / SCREEN_ANIM_TEX.x) * ART_SCALE
		_screen_anim.scale = Vector2(sc, sc)
	_position_screen_title()


# --- Sfondo + cabinato animato -------------------------------------------------
func _build_scene() -> void:
	# (lo sfondo di riempimento è già in scena: SkyBG z=-6 + FloorBG z=-5)
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
	# Scintille bianche "sbrilluccicose" dietro il tasto.
	_sparkles = _make_sparkles(26.0, 46, 45.0, 105.0, 2.5, 4.5)

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


# Emettitore di scintille bianche a pixel (nascono al centro, sparano in tutte le direzioni).
func _make_sparkles(radius: float, amount: int, vmin: float, vmax: float, smin: float, smax: float) -> CPUParticles2D:
	var sp := CPUParticles2D.new()
	sp.texture = _make_pixel_texture()
	sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sp.z_index = -1                       # dietro all'elemento (z=0), davanti al cabinato (z=-2)
	sp.amount = amount
	sp.lifetime = 1.0
	sp.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	sp.emission_sphere_radius = radius
	sp.direction = Vector2(0, -1)
	sp.spread = 180.0
	sp.gravity = Vector2.ZERO
	sp.initial_velocity_min = vmin
	sp.initial_velocity_max = vmax
	sp.scale_amount_min = smin
	sp.scale_amount_max = smax
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.25, 1.0])
	grad.colors = PackedColorArray([Color(1, 1, 1, 0), Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	sp.color_ramp = grad
	add_child(sp)
	return sp


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


# --- Frecce laterali cambia-modalità -------------------------------------------
func _make_arrow_sprite(path: String, flip: bool) -> Sprite2D:
	var sp := Sprite2D.new()
	sp.texture = load(path)
	sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sp.flip_h = flip
	sp.z_index = 0
	add_child(sp)
	return sp


func _build_arrows() -> void:
	# scintille dietro ogni freccia (come il tasto PLAY, un filo più piccole)
	_arrow_l_sparkles = _make_sparkles(17.0, 24, 30.0, 72.0, 2.0, 3.6)
	_arrow_r_sparkles = _make_sparkles(17.0, 24, 30.0, 72.0, 2.0, 3.6)
	# destra = asset così com'è (punta a destra); sinistra = specchiata
	_arrow_r_base = _make_arrow_sprite("res://CORE/Assets/Art/Home/arrow_normal.svg", false)
	_arrow_r_pressed = _make_arrow_sprite("res://CORE/Assets/Art/Home/arrow_pressed.svg", false)
	_arrow_r_pressed.visible = false
	_arrow_l_base = _make_arrow_sprite("res://CORE/Assets/Art/Home/arrow_normal.svg", true)
	_arrow_l_pressed = _make_arrow_sprite("res://CORE/Assets/Art/Home/arrow_pressed.svg", true)
	_arrow_l_pressed.visible = false


func _position_arrows() -> void:
	if not _arrow_r_base:
		return
	var s := (ARROW_WIDTH_ART / ARROW_TEX.x) * ART_SCALE
	_arrow_r_center = _art_to_world(ARROW_R_CENTER_ART)
	_arrow_l_center = _art_to_world(ARROW_L_CENTER_ART)
	_arrow_hit_size = ARROW_TEX * s
	for sp: Sprite2D in [_arrow_r_base, _arrow_r_pressed]:
		sp.position = _arrow_r_center
		sp.scale = Vector2(s, s)
	for sp: Sprite2D in [_arrow_l_base, _arrow_l_pressed]:
		sp.position = _arrow_l_center
		sp.scale = Vector2(s, s)
	_arrow_l_sparkles.position = _arrow_l_center
	_arrow_l_sparkles.scale = Vector2(ART_SCALE, ART_SCALE)
	_arrow_r_sparkles.position = _arrow_r_center
	_arrow_r_sparkles.scale = Vector2(ART_SCALE, ART_SCALE)


func _arrow_down(base: Sprite2D, pressed: Sprite2D, spk: CPUParticles2D) -> void:
	settings.button_feedback()
	base.visible = false
	pressed.visible = true
	spk.emitting = false


func _arrow_up(base: Sprite2D, pressed: Sprite2D, spk: CPUParticles2D) -> void:
	base.visible = true
	pressed.visible = false
	spk.emitting = true


# --- Animazione a schermo (dietro il cabinato) ---------------------------------
func _build_screen_anim() -> void:
	_screen_anim = AnimatedSprite2D.new()
	_screen_anim.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_screen_anim.z_index = -3            # dietro il cabinato (z=-2), davanti allo sfondo (z=-4)
	_screen_anim.centered = true
	add_child(_screen_anim)

	# scritta SOPRA l'animazione (stesso z, aggiunta dopo -> disegnata sopra)
	_screen_title = Sprite2D.new()
	_screen_title.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_screen_title.z_index = -3
	_screen_title.centered = true
	add_child(_screen_title)

	# CLASSIC (gameplay mode_c) e SPEEDRUN hanno animazione + scritta a schermo
	_mode_anims["mode_c"] = _load_screen_frames("classic")
	_mode_titles["mode_c"] = load("res://CORE/Assets/Art/Home/screen_title_classic.png")
	_mode_anims["speedrun"] = _load_screen_frames("speedrun")
	_mode_titles["speedrun"] = load("res://CORE/Assets/Art/Home/screen_title_speedrun.png")


func _load_screen_frames(prefix: String) -> SpriteFrames:
	var sf := SpriteFrames.new()
	sf.add_animation("a")
	sf.set_animation_loop("a", true)
	sf.set_animation_speed("a", SCREEN_ANIM_FPS)
	for i in range(1, 11):
		sf.add_frame("a", load("res://CORE/Assets/Art/Home/Screen/%s_%02d.png" % [prefix, i]))
	return sf


# Posiziona la scritta esattamente sopra l'animazione (stesso centro/larghezza).
func _position_screen_title() -> void:
	if _screen_title and _screen_title.texture:
		_screen_title.position = _art_to_world(SCREEN_ANIM_CENTER_ART)
		var st := (SCREEN_ANIM_WIDTH_ART / float(_screen_title.texture.get_width())) * ART_SCALE
		_screen_title.scale = Vector2(st, st)


# --- Display modalità sullo schermo del cabinato -------------------------------
func _build_mode_screen() -> void:
	# Node2D (segue il Camera2D come gli sprite); i Label sono figli in coord "art".
	_mode_screen = Node2D.new()
	_mode_screen.z_index = -1     # sullo schermo, davanti al cabinato (z=-2)
	add_child(_mode_screen)

	_mode_screen_label = Label.new()
	_mode_screen_label.add_theme_font_override("font", MODE_FONT)
	_mode_screen_label.add_theme_font_size_override("font_size", 64)
	_mode_screen_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mode_screen_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_mode_screen_label.size = Vector2(340, 90)
	_mode_screen_label.position = Vector2(-170, -66)
	_mode_screen.add_child(_mode_screen_label)

	_mode_screen_sub = Label.new()
	_mode_screen_sub.add_theme_font_override("font", MODE_FONT)
	_mode_screen_sub.add_theme_font_size_override("font_size", 26)
	_mode_screen_sub.add_theme_color_override("font_color", Color(1, 1, 1, 0.85))
	_mode_screen_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mode_screen_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_mode_screen_sub.size = Vector2(300, 60)
	_mode_screen_sub.position = Vector2(-150, 20)
	_mode_screen.add_child(_mode_screen_sub)

	_update_mode_screen()


func _update_mode_screen() -> void:
	var m: Dictionary = MODES[_mode_index]
	var mode: String = m["mode"]
	# se la modalità ha un'animazione a schermo la mostro (dietro il cabinato) e nascondo il testo
	if _screen_anim and _mode_anims.has(mode):
		_screen_anim.sprite_frames = _mode_anims[mode]
		_screen_anim.play("a")
		_screen_anim.visible = true
		# scritta sopra l'animazione (se presente per questa modalità)
		if _mode_titles.has(mode):
			_screen_title.texture = _mode_titles[mode]
			_screen_title.visible = true
			_position_screen_title()
		else:
			_screen_title.visible = false
		_mode_screen_label.visible = false
		_mode_screen_sub.visible = false
	else:
		if _screen_anim:
			_screen_anim.visible = false
		if _screen_title:
			_screen_title.visible = false
		_mode_screen_label.visible = true
		_mode_screen_sub.visible = true
		_mode_screen_label.text = m["label"]
		_mode_screen_label.add_theme_color_override("font_color", m["color"])
		_mode_screen_sub.text = m["sub"]


func _cycle_mode(dir: int) -> void:
	_mode_index = (_mode_index + dir + MODES.size()) % MODES.size()
	_update_mode_screen()


# Input a mano: press/release testati sul rettangolo-mondo del tasto (mouse + touch).
func _input(event: InputEvent) -> void:
	if _mode_menu == null or _mode_menu.visible:
		return
	if _tab != "home":
		return
	if not (event is InputEventMouseButton or event is InputEventScreenTouch):
		return
	var world: Vector2 = get_viewport().get_canvas_transform().affine_inverse() * event.position
	var play_rect := Rect2(_play_world_center - _play_world_size * 0.5, _play_world_size)
	var l_rect := Rect2(_arrow_l_center - _arrow_hit_size * 0.5, _arrow_hit_size)
	var r_rect := Rect2(_arrow_r_center - _arrow_hit_size * 0.5, _arrow_hit_size)
	if event.pressed:
		if play_rect.has_point(world):
			_play_pressing = true
			_on_play_down()
		elif l_rect.has_point(world):
			_arrow_l_pressing = true
			_arrow_down(_arrow_l_base, _arrow_l_pressed, _arrow_l_sparkles)
		elif r_rect.has_point(world):
			_arrow_r_pressing = true
			_arrow_down(_arrow_r_base, _arrow_r_pressed, _arrow_r_sparkles)
	else:
		if _play_pressing:
			_play_pressing = false
			_on_play_up()
			if play_rect.has_point(world):
				_on_play_pressed()
		if _arrow_l_pressing:
			_arrow_l_pressing = false
			_arrow_up(_arrow_l_base, _arrow_l_pressed, _arrow_l_sparkles)
			if l_rect.has_point(world):
				_cycle_mode(-1)
		if _arrow_r_pressing:
			_arrow_r_pressing = false
			_arrow_up(_arrow_r_base, _arrow_r_pressed, _arrow_r_sparkles)
			if r_rect.has_point(world):
				_cycle_mode(1)


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
	# la modalità si sceglie con le frecce (mostrata sullo schermo): PLAY la avvia
	_start_mode(MODES[_mode_index]["mode"])


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


# --- MISSIONI (tastino TEMPORANEO + pannello) ----------------------------------
func _build_missions_button() -> void:
	_missions_button = Button.new()
	_missions_button.text = "MISSIONI"
	_missions_button.focus_mode = Control.FOCUS_NONE
	_missions_button.position = Vector2(12, 408)
	_missions_button.size = Vector2(150, 60)
	_missions_button.add_theme_font_override("font", MODE_FONT)
	_missions_button.add_theme_font_size_override("font_size", 28)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.13, 0.48, 0.72)
	sb.set_corner_radius_all(14)
	sb.set_border_width_all(3)
	sb.border_color = Color(1, 1, 1, 0.5)
	sb.shadow_color = Color(0, 0, 0, 0.35)
	sb.shadow_size = 5
	sb.shadow_offset = Vector2(0, 3)
	_missions_button.add_theme_stylebox_override("normal", sb)
	_missions_button.add_theme_stylebox_override("hover", sb)
	_missions_button.add_theme_stylebox_override("pressed", sb)
	_missions_button.pressed.connect(_open_missions)
	add_child(_missions_button)

	_coin_label = Label.new()
	_coin_label.add_theme_font_override("font", MODE_FONT)
	_coin_label.add_theme_font_size_override("font_size", 24)
	_coin_label.add_theme_color_override("font_color", Color(1, 0.84, 0.10))
	_coin_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_coin_label.position = Vector2(12, 472)
	_coin_label.size = Vector2(150, 28)
	add_child(_coin_label)
	_update_coin_label()


func _update_coin_label() -> void:
	if _coin_label:
		_coin_label.text = "%d monete" % missions.coins


func _build_missions_menu() -> void:
	_missions_menu = Control.new()
	_missions_menu.set_anchors_preset(Control.PRESET_FULL_RECT)
	_missions_menu.z_index = 940
	_missions_menu.visible = false
	add_child(_missions_menu)

	# schermata PIENA (come lo shop), non un popup
	var bg := ColorRect.new()
	bg.color = Color(0.09, 0.17, 0.27, 1.0)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	bg.offset_left = -600.0
	bg.offset_top = -600.0
	bg.offset_right = 1400.0
	bg.offset_bottom = 2000.0
	_missions_menu.add_child(bg)

	var title := Label.new()
	title.text = "MISSIONI"
	title.add_theme_font_override("font", MODE_FONT)
	title.add_theme_font_size_override("font_size", 44)
	title.add_theme_color_override("font_color", Color(1, 1, 1))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(24, 132)
	title.size = Vector2(528, 52)
	_missions_menu.add_child(title)

	_missions_coins_label = Label.new()
	_missions_coins_label.add_theme_font_override("font", MODE_FONT)
	_missions_coins_label.add_theme_font_size_override("font_size", 28)
	_missions_coins_label.add_theme_color_override("font_color", Color(1, 0.84, 0.10))
	_missions_coins_label.position = Vector2(44, 186)
	_missions_coins_label.size = Vector2(240, 32)
	_missions_menu.add_child(_missions_coins_label)

	_missions_timer_label = Label.new()
	_missions_timer_label.add_theme_font_override("font", MODE_FONT)
	_missions_timer_label.add_theme_font_size_override("font_size", 20)
	_missions_timer_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))
	_missions_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_missions_timer_label.position = Vector2(292, 190)
	_missions_timer_label.size = Vector2(244, 28)
	_missions_menu.add_child(_missions_timer_label)

	_missions_list = VBoxContainer.new()
	_missions_list.position = Vector2(44, 230)
	_missions_list.size = Vector2(488, 620)
	_missions_list.add_theme_constant_override("separation", 10)
	_missions_menu.add_child(_missions_list)


func _refresh_text() -> String:
	var s := missions.seconds_until_refresh()
	return "Nuove tra %dh %02dm" % [s / 3600, (s % 3600) / 60]


func _open_missions() -> void:
	settings.button_feedback()
	missions._maybe_refresh()
	_populate_missions()
	_missions_menu.visible = true


func _close_missions() -> void:
	settings.button_feedback()
	_missions_menu.visible = false
	_update_coin_label()


func _on_missions_dim_input(event: InputEvent) -> void:
	var tap: bool = (event is InputEventMouseButton and not event.pressed) \
		or (event is InputEventScreenTouch and not event.pressed)
	if tap:
		_select_tab("home")


func _populate_missions() -> void:
	for c in _missions_list.get_children():
		c.queue_free()
	_missions_coins_label.text = "Monete: %d" % missions.coins
	_missions_timer_label.text = _refresh_text()
	for i in missions.missions.size():
		_missions_list.add_child(_make_mission_row(i, missions.missions[i]))


func _make_mission_row(index: int, m: Dictionary) -> Control:
	var row := ColorRect.new()
	row.color = Color(1, 1, 1, 0.06)
	row.custom_minimum_size = Vector2(488, 92)

	var desc := Label.new()
	desc.text = missions.describe(m)
	desc.add_theme_font_override("font", MODE_FONT)
	desc.add_theme_font_size_override("font_size", 22)
	desc.add_theme_color_override("font_color", Color(1, 1, 1))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.position = Vector2(14, 8)
	desc.size = Vector2(316, 48)
	row.add_child(desc)

	var prog := Label.new()
	prog.text = "%d / %d" % [m["progress"], m["target"]]
	prog.add_theme_font_override("font", MODE_FONT)
	prog.add_theme_font_size_override("font_size", 20)
	prog.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
	prog.position = Vector2(14, 58)
	prog.size = Vector2(200, 28)
	row.add_child(prog)

	var rew := Label.new()
	rew.text = "+%d" % m["reward"]
	rew.add_theme_font_override("font", MODE_FONT)
	rew.add_theme_font_size_override("font_size", 24)
	rew.add_theme_color_override("font_color", Color(1, 0.84, 0.10))
	rew.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rew.position = Vector2(338, 8)
	rew.size = Vector2(136, 30)
	row.add_child(rew)

	var claim := Button.new()
	claim.focus_mode = Control.FOCUS_NONE
	claim.add_theme_font_override("font", MODE_FONT)
	claim.add_theme_font_size_override("font_size", 20)
	claim.position = Vector2(338, 46)
	claim.size = Vector2(136, 40)
	if m["claimed"]:
		claim.text = "FATTO"
		claim.disabled = true
	elif missions.is_complete(m):
		claim.text = "RISCUOTI"
		claim.pressed.connect(_claim_mission.bind(index))
	else:
		claim.text = "IN CORSO"
		claim.disabled = true
	row.add_child(claim)
	return row


func _claim_mission(index: int) -> void:
	var got := missions.claim(index)
	if got > 0:
		settings.button_feedback()
		_update_coin_label()
		_populate_missions()


# --- Menu bar in basso (missioni / home / shop) --------------------------------
func _build_nav_bar() -> void:
	_nav_textures = {
		"missions": load("res://CORE/Assets/Art/Home/Nav/bar_missions.png"),
		"home": load("res://CORE/Assets/Art/Home/Nav/bar_home.png"),
		"shop": load("res://CORE/Assets/Art/Home/Nav/bar_shop.png"),
	}
	# CanvasLayer dedicato: la barra sta SOPRA tutto il resto (a prescindere dagli z_index)
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	_nav_bar = TextureRect.new()
	_nav_bar.texture = _nav_textures["home"]
	_nav_bar.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_nav_bar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_nav_bar.stretch_mode = TextureRect.STRETCH_SCALE
	_nav_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_nav_bar)
	# 3 tasti invisibili sopra le celle (sinistra=missioni, centro=home, destra=shop)
	var tabs := ["missions", "home", "shop"]
	for i in 3:
		var b := Button.new()
		b.focus_mode = Control.FOCUS_NONE
		b.mouse_filter = Control.MOUSE_FILTER_STOP
		var empty := StyleBoxEmpty.new()
		b.add_theme_stylebox_override("normal", empty)
		b.add_theme_stylebox_override("hover", empty)
		b.add_theme_stylebox_override("pressed", empty)
		b.add_theme_stylebox_override("focus", empty)
		b.pressed.connect(_select_tab.bind(tabs[i]))
		_nav_bar.add_child(b)
		_nav_btns.append(b)


func _select_tab(tab: String, feedback: bool = true) -> void:
	if feedback:
		settings.button_feedback()
	_tab = tab
	if _nav_bar:
		_nav_bar.texture = _nav_textures.get(tab, _nav_textures["home"])
	if _missions_menu:
		_missions_menu.visible = false
	if _shop_menu:
		_shop_menu.visible = false
	_set_home_visible(tab == "home")
	if tab == "missions":
		missions._maybe_refresh()
		_populate_missions()
		_missions_menu.visible = true
	elif tab == "shop":
		_shop_menu.visible = true


func _set_home_visible(v: bool) -> void:
	for n in [_background, _cabinet, _play_base, _sparkles,
			_arrow_l_base, _arrow_l_pressed, _arrow_r_base, _arrow_r_pressed,
			_arrow_l_sparkles, _arrow_r_sparkles, _screen_anim, _screen_title, _mode_screen]:
		if n:
			n.visible = v
	if _play_pressed:
		_play_pressed.visible = false
	if _sparkles:
		_sparkles.emitting = v
	if _arrow_l_sparkles:
		_arrow_l_sparkles.emitting = v
	if _arrow_r_sparkles:
		_arrow_r_sparkles.emitting = v
	if v:
		_update_mode_screen()


func _build_shop_menu() -> void:
	_shop_menu = Control.new()
	_shop_menu.set_anchors_preset(Control.PRESET_FULL_RECT)
	_shop_menu.z_index = 940
	_shop_menu.visible = false
	add_child(_shop_menu)
	var bg := ColorRect.new()
	bg.color = Color(0.09, 0.17, 0.27, 1.0)
	bg.offset_left = -600.0
	bg.offset_top = -600.0
	bg.offset_right = 1400.0
	bg.offset_bottom = 2000.0
	_shop_menu.add_child(bg)
	var t := Label.new()
	t.text = "SHOP"
	t.add_theme_font_override("font", MODE_FONT)
	t.add_theme_font_size_override("font_size", 70)
	t.add_theme_color_override("font_color", Color(1, 1, 1))
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.offset_left = 38.0
	t.offset_right = 538.0
	t.offset_top = 380.0
	t.offset_bottom = 470.0
	_shop_menu.add_child(t)
	var s := Label.new()
	s.text = "PROSSIMAMENTE"
	s.add_theme_font_override("font", MODE_FONT)
	s.add_theme_font_size_override("font_size", 34)
	s.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	s.offset_left = 38.0
	s.offset_right = 538.0
	s.offset_top = 476.0
	s.offset_bottom = 520.0
	_shop_menu.add_child(s)
