extends Control

@onready var music_player := %AudioStreamPlayer2D

const MODE_FONT := preload("res://CORE/Assets/Font/Jersey10-Regular.ttf")

# Sfondo + cabinato sono lo STESSO canvas 800x1400 (sovrapposti 1:1).
const ART_SIZE := Vector2(800.0, 1400.0)
const ART_CENTER := Vector2(400.0, 700.0)
const CAMERA_CENTER := Vector2(288.0, 512.0)
const ART_SCALE := 0.86
const BOTTOM_MARGIN := 0.0
const CABINET_DROP := 115.0                   # abbassa cabinato + tasto play (assieme via _art_to_world)

# Animazione cabinato (riflesso sul marquee): 12 frame, poi fermo 15s, poi riparte.
const CAB_FPS := 12.0
const CAB_HOLD := 6.0    # 1s di animazione + 6s di pausa = ripete ~ogni 7s

# Deck in basso (coord canvas 800x1400): tasto CUBE DECK (576x576) + tasto PLAY (1408x576)
# AFFIANCATI, stessa altezza, centrati. Press = leggero scurimento (modulate).
const PLAY_NEW_TEX := Vector2(1472.0, 576.0)
const DECK_TEX := Vector2(576.0, 576.0)
const DECK_BTN_H_ART := 150.0                # altezza comune dei due tasti (più grandi)
const DECK_GAP_ART := -4.0                    # attaccati (piccolo che chiude il seam, niente sovrapposizione visibile)
const DECK_ROW_CENTER_ART := Vector2(399.0, 970.0)  # posizione tasto play (indipendente dal cabinato)
const PRESS_SINK := 5.0                       # px di "affondamento" alla pressione
const SPARKLE_OFFSET_Y := 0.0

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
var _home_shadow: Sprite2D
var _cabinet: Sprite2D
var _hold_timer: Timer

# Il tasto è fatto di Sprite2D (Node2D) per stare nello STESSO spazio del cabinato
# col Camera2D (i Control verrebbero renderizzati con un offset). Input gestito a mano.
var _play_base: Sprite2D
var _play_pressed: Sprite2D
var _play_world_center := Vector2.ZERO
var _play_world_size := Vector2.ZERO
var _play_pressing := false
var _deck_sprite: Sprite2D
var _deck_world_center := Vector2.ZERO
var _deck_world_size := Vector2.ZERO
var _deck_pressing := false
var _deck_menu: Control
var _play_base_pos := Vector2.ZERO           # posizione base (non premuta) per il sink idempotente
var _deck_base_pos := Vector2.ZERO

# Barra in alto a destra: coin count + classifica + impostazioni
var _coin_bar: TextureRect
var _coin_count_label: Label
var _leader_btn: TextureButton
var _settings_btn2: TextureButton
var _profile_pic: TextureRect
var _name_frame: TextureRect
var _name_edit: LineEdit
var _profile_pic_base: Vector2 = Vector2.ZERO
var _name_frame_base: Vector2 = Vector2.ZERO
var _name_edit_base: Vector2 = Vector2.ZERO
var _player_name: String = "PLAYER"
const PROFILE_CFG := "user://profile.cfg"
# Schermata EDIT PROFILE
const PROFILE_DIR := "res://CORE/Assets/Art/Home/Profile/"
const PROFILE_ICONS := [   # icone profilo selezionabili (se ne aggiungeranno altre)
	"res://CORE/Assets/Art/Home/Profile/icon_king_cube.png",
]
var _profile_icon_index: int = 0     # icona attualmente scelta (salvata)
var _profile_sel_index: int = 0      # icona selezionata nella schermata (prima di CONFERMA)
var _profile_menu: Control
var _profile_frame: Control
var _profile_bg: TextureRect
var _profile_title: Label
var _profile_prev: TextureRect       # anteprima icona scelta (in alto a sx nella schermata)
var _profile_namebox: TextureRect
var _profile_name_title: Label
var _profile_name_edit: LineEdit
var _profile_edit_btn: TextureButton
var _profile_selframe: TextureRect
var _profile_scroll: ScrollContainer
var _profile_grid: GridContainer
var _profile_cancel: TextureButton
var _profile_confirm: TextureButton
var _profile_icon_btns: Array = []
var _leader_menu: Control
var _leader_bg: ColorRect
var _leader_panel: ColorRect
var _leader_tabs: TextureRect
var _leader_timer: Label
var _leader_scroll: ScrollContainer
var _leader_list: VBoxContainer
var _tab_classic_btn: Button
var _tab_speed_btn: Button
var _leader_close: TextureButton
var _leader_title: Label
var _leader_tab: String = "classic"
const LB_DIR := "res://CORE/Assets/Art/UI/Leaderboard/"
const LB_ROW_W := 500.0
const LB_ROW_H := 74.0
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
var _missions_scroll: ScrollContainer
var _missions_coins_label: Label
var _missions_coin_bar: TextureRect
var _missions_timer_label: Label
var _missions_tabs: TextureRect
var _missions_panel: ColorRect
var _tab_weekly_btn: Button
var _tab_daily_btn: Button
var _missions_tab: String = "weekly"   # "weekly" | "daily"

# Menu bar in basso (missioni / home / shop)
const NAV_TEX := Vector2(1600.0, 432.0)
const NAV_FLAT_FRAC := 32.0 / 432.0   # il tab attivo sporge in alto: la barra piatta inizia più giù
const NAV_MAX_W := 820.0              # larghezza max barra (su iPad/tablet non si stira: navy ai lati)
var _nav_bar: TextureRect
var _nav_bg: ColorRect
var _nav_badge: TextureRect   # badge "missioni completate" sul tab missioni
var _nav_badge_base: Vector2 = Vector2.ZERO
var _nav_badge_raise: float = 0.0
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
	_build_deck_menu()
	_build_leader_menu()
	_build_top_right()
	_build_profile_menu()
	_build_nav_bar()
	_layout()
	get_viewport().size_changed.connect(_layout)
	_select_tab("home", false)


func _art_to_world(art: Vector2) -> Vector2:
	return _art_pos + (art - ART_CENTER) * ART_SCALE


# Ancora la scena arcade in basso e la scala; riposiziona anche tasto e scintille.
func _layout() -> void:
	var view_size := get_viewport_rect().size
	# barra nav: larghezza cap (ASPETTO NATIVO, niente stiramento su iPad/tablet), centrata;
	# il navy dei lati lo riempie _nav_bg a tutta larghezza.
	var bar_w := minf(view_size.x, NAV_MAX_W)
	var nav_h := bar_w * (NAV_TEX.y / NAV_TEX.x)
	var nav_top := view_size.y - nav_h
	if _nav_bg:
		# allineato alla barra PIATTA (il tab attivo sporge sopra): niente blocco navy agli angoli
		_nav_bg.position = Vector2(0, nav_top + nav_h * NAV_FLAT_FRAC)
		_nav_bg.size = Vector2(view_size.x, nav_h * (1.0 - NAV_FLAT_FRAC))
	if _nav_bar:
		var bar_left := (view_size.x - bar_w) * 0.5
		_nav_bar.position = Vector2(bar_left, nav_top)
		_nav_bar.size = Vector2(bar_w, nav_h)
		for i in _nav_btns.size():
			var b: Button = _nav_btns[i]
			b.position = Vector2(bar_w * i / 3.0, 0.0)
			b.size = Vector2(bar_w / 3.0, nav_h)
		# badge sopra il tab missioni (leftmost), in alto a destra della cella
		if _nav_badge:
			var bs := nav_h * 0.34
			_nav_badge.size = Vector2(bs, bs)
			_nav_badge_raise = nav_h * 0.14
			_nav_badge_base = Vector2(bar_left + bar_w / 3.0 - bs * 0.35, nav_top - bs * 0.05)
			_apply_nav_badge_pos()
	# zona missioni: tab full-width -> pannello scuro -> timer -> lista clippata
	if _missions_tabs:
		var tabs_y := 200.0
		var th := view_size.x * 94.0 / 576.0
		_missions_tabs.position = Vector2(0, tabs_y)
		_missions_tabs.size = Vector2(view_size.x, th)
		if _tab_weekly_btn:
			_tab_weekly_btn.position = Vector2(0, tabs_y)
			_tab_weekly_btn.size = Vector2(view_size.x * 0.5, th)
		if _tab_daily_btn:
			_tab_daily_btn.position = Vector2(view_size.x * 0.5, tabs_y)
			_tab_daily_btn.size = Vector2(view_size.x * 0.5, th)
		var panel_top := tabs_y + th - 6.0
		if _missions_panel:
			# pannello attaccato fino al FONDO schermo (dietro la nav bar): niente blu residuo
			_missions_panel.position = Vector2(0, panel_top)
			_missions_panel.size = Vector2(view_size.x, maxf(60.0, view_size.y - panel_top))
		if _missions_timer_label:
			_missions_timer_label.position = Vector2(0, panel_top + 12.0)
			_missions_timer_label.size = Vector2(view_size.x, 28.0)
		if _missions_scroll:
			var scroll_top := panel_top + 50.0
			# clipped frame attaccato al FONDO dello schermo (il tail lascia scorrere sopra la nav bar)
			_missions_scroll.position = Vector2(32.0, scroll_top)
			_missions_scroll.size = Vector2(view_size.x - 64.0, maxf(120.0, view_size.y - scroll_top))
	# cabinato ancorato in basso ma ABBASSATO di CABINET_DROP (la barra ci passa sopra, CanvasLayer)
	var bottom_y := CAMERA_CENTER.y + view_size.y * 0.5 + CABINET_DROP
	_art_pos = Vector2(CAMERA_CENTER.x, bottom_y - (ART_SIZE.y - ART_CENTER.y) * ART_SCALE)

	for s: Node2D in [_background, _cabinet]:
		if s:
			s.position = _art_pos
			s.scale = Vector2(ART_SCALE, ART_SCALE)

	# ombra: larga quanto lo schermo, bordo inferiore allineato al fondo schermo
	if _home_shadow and _home_shadow.texture:
		var stex := _home_shadow.texture.get_size()
		var ssc := view_size.x / stex.x
		_home_shadow.scale = Vector2(ssc, ssc)
		var screen_bottom := CAMERA_CENTER.y + view_size.y * 0.5
		_home_shadow.position = Vector2(CAMERA_CENTER.x, screen_bottom - stex.y * ssc * 0.5)

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
	_layout_profile()
	_layout_leader()


# --- Sfondo + cabinato animato -------------------------------------------------
func _build_scene() -> void:
	# (lo sfondo di riempimento è già in scena: SkyBG z=-6 + FloorBG z=-5)
	_background = Sprite2D.new()
	_background.texture = load("res://CORE/Assets/Art/Home/background.png")
	_background.z_index = -4
	_background.visible = false   # sfondo home = blu pieno (SkyBG); backdrop nascosto
	add_child(_background)

	# (ombra home rimossa)

	# Cabinato STATICO (immagine unica, niente animazione)
	_cabinet = Sprite2D.new()
	_cabinet.texture = load("res://CORE/Assets/Art/Home/cabinet_static.png")
	_cabinet.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_cabinet.z_index = -2
	add_child(_cabinet)


# --- Tasto PLAY + scintille ----------------------------------------------------
func _build_play_button() -> void:
	# Scintille bianche "sbrilluccicose" dietro il tasto.
	_sparkles = _make_sparkles(26.0, 46, 45.0, 105.0, 2.5, 4.5)

	# Tasto PLAY (nuova grafica), centrato. Input a mano in _input().
	_play_base = Sprite2D.new()
	_play_base.texture = load("res://CORE/Assets/Art/Home/play_button_new.png")
	_play_base.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_play_base.z_index = 0
	add_child(_play_base)
	# (Cube Deck rimosso)


func _make_pixel_texture() -> ImageTexture:
	var img := Image.create(2, 2, false, Image.FORMAT_RGBA8)
	img.fill(Color(1, 1, 1, 1))
	return ImageTexture.create_from_image(img)


# Emettitore di scintille bianche a pixel (nascono al centro, sparano in tutte le direzioni).
func _make_sparkles(radius: float, amount: int, vmin: float, vmax: float, smin: float, smax: float) -> CPUParticles2D:
	var sp := CPUParticles2D.new()
	sp.self_modulate = Color(1, 1, 1, 0)   # effetto pixel disattivato (invisibile)
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
	# PLAY da solo, centrato
	var s := (DECK_BTN_H_ART / PLAY_NEW_TEX.y) * ART_SCALE
	var y := DECK_ROW_CENTER_ART.y

	_deck_world_size = Vector2.ZERO   # deck rimosso: nessuna hit-area

	_play_base.position = _art_to_world(Vector2(DECK_ROW_CENTER_ART.x, y))
	_play_base.scale = Vector2(s, s)
	_play_base_pos = _play_base.position
	_play_world_center = _play_base.position
	_play_world_size = PLAY_NEW_TEX * s

	if _sparkles:
		_sparkles.position = _play_base.position
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
	pressed.position = base.position + Vector2(0, PRESS_SINK)   # affonda di qualche pixel
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
	if _deck_menu and _deck_menu.visible:
		return
	if _leader_menu and _leader_menu.visible:
		return
	if not (event is InputEventMouseButton or event is InputEventScreenTouch):
		return
	var world: Vector2 = get_viewport().get_canvas_transform().affine_inverse() * event.position
	var play_rect := Rect2(_play_world_center - _play_world_size * 0.5, _play_world_size)
	var deck_rect := Rect2(_deck_world_center - _deck_world_size * 0.5, _deck_world_size)
	var l_rect := Rect2(_arrow_l_center - _arrow_hit_size * 0.5, _arrow_hit_size)
	var r_rect := Rect2(_arrow_r_center - _arrow_hit_size * 0.5, _arrow_hit_size)
	if event.pressed:
		if play_rect.has_point(world):
			_play_pressing = true
			_on_play_down()
		elif deck_rect.has_point(world):
			_deck_pressing = true
			_on_deck_down()
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
		if _deck_pressing:
			_deck_pressing = false
			_on_deck_up()
			if deck_rect.has_point(world):
				_on_deck_pressed()
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
	_play_base.modulate = Color(0.85, 0.85, 0.85)
	_play_base.position = _play_base_pos + Vector2(0, PRESS_SINK)   # affonda un filo
	_sparkles.emitting = false


func _on_play_up() -> void:
	_play_base.modulate = Color(1, 1, 1)
	_play_base.position = _play_base_pos
	# se non si apre il menu (rilascio fuori dal tasto), le scintille riprendono
	_sparkles.emitting = not _mode_menu.visible


func _on_play_pressed() -> void:
	# la modalità si sceglie con le frecce (mostrata sullo schermo): PLAY la avvia
	_start_mode(MODES[_mode_index]["mode"])


# --- Tasto CUBE DECK -----------------------------------------------------------
func _on_deck_down() -> void:
	settings.button_feedback()
	_deck_sprite.modulate = Color(0.85, 0.85, 0.85)
	_deck_sprite.position = _deck_base_pos + Vector2(0, PRESS_SINK)


func _on_deck_up() -> void:
	_deck_sprite.modulate = Color(1, 1, 1)
	_deck_sprite.position = _deck_base_pos


func _on_deck_pressed() -> void:
	if _deck_menu:
		_deck_menu.visible = true


func _build_deck_menu() -> void:
	_deck_menu = Control.new()
	_deck_menu.set_anchors_preset(Control.PRESET_FULL_RECT)
	_deck_menu.z_index = 960
	_deck_menu.visible = false
	add_child(_deck_menu)
	var dim := ColorRect.new()
	dim.color = Color(0.07, 0.13, 0.22, 0.98)
	dim.offset_left = -600.0
	dim.offset_top = -600.0
	dim.offset_right = 1400.0
	dim.offset_bottom = 2000.0
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(_on_deck_dim_input)
	_deck_menu.add_child(dim)
	var t := Label.new()
	t.text = "CUBE DECK"
	t.add_theme_font_override("font", MODE_FONT)
	t.add_theme_font_size_override("font_size", 70)
	t.add_theme_color_override("font_color", Color(1, 1, 1))
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.offset_left = 38.0
	t.offset_right = 538.0
	t.offset_top = 380.0
	t.offset_bottom = 470.0
	_deck_menu.add_child(t)
	var s := Label.new()
	s.text = "PROSSIMAMENTE\n(tocca per chiudere)"
	s.add_theme_font_override("font", MODE_FONT)
	s.add_theme_font_size_override("font_size", 30)
	s.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	s.offset_left = 38.0
	s.offset_right = 538.0
	s.offset_top = 478.0
	s.offset_bottom = 580.0
	_deck_menu.add_child(s)


func _on_deck_dim_input(event: InputEvent) -> void:
	var tap: bool = (event is InputEventMouseButton and not event.pressed) \
		or (event is InputEventScreenTouch and not event.pressed)
	if tap:
		settings.button_feedback()
		_deck_menu.visible = false


# --- Barra in alto a destra (coin count + classifica + impostazioni) -----------
func _build_top_right() -> void:
	# COIN COUNT (barra con moneta a sx + numero) SOPRA le due icone
	_coin_bar = TextureRect.new()
	_coin_bar.texture = load("res://CORE/Assets/Art/UI/Menu/coin_count.png")
	_coin_bar.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_coin_bar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_coin_bar.stretch_mode = TextureRect.STRETCH_SCALE
	_coin_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_coin_bar.position = Vector2(360.0, 4.0)
	_coin_bar.size = Vector2(192.0, 192.0 * 176.0 / 792.0)
	add_child(_coin_bar)

	_coin_count_label = Label.new()
	_coin_count_label.add_theme_font_override("font", MODE_FONT)
	_coin_count_label.add_theme_font_size_override("font_size", 30)
	_coin_count_label.add_theme_color_override("font_color", Color(1, 1, 1))
	_coin_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_coin_count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_coin_count_label.position = Vector2(406.0, 4.0)
	_coin_count_label.size = Vector2(140.0, 43.0)
	add_child(_coin_count_label)
	_update_coin_count()

	# CLASSIFICA (trofeo) a SINISTRA delle impostazioni — più grandi e alzate
	_leader_btn = _make_icon_button("res://CORE/Assets/Art/UI/Menu/leaderboard.png", Vector2(388.0, 74.0), 78.0)
	_leader_btn.pressed.connect(_on_leaderboard_pressed)
	# IMPOSTAZIONI (nuova icona)
	_settings_btn2 = _make_icon_button("res://CORE/Assets/Art/UI/Menu/settings_new.png", Vector2(474.0, 74.0), 78.0)
	_settings_btn2.pressed.connect(_on_settings_button_pressed)

	# PROFILE PICTURE a SINISTRA (mostra l'icona scelta; tap -> schermata EDIT PROFILE)
	_load_player_name()
	_profile_pic = TextureRect.new()
	_profile_pic.texture = load(_current_profile_icon_path())
	_profile_pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_profile_pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_profile_pic.stretch_mode = TextureRect.STRETCH_SCALE
	_profile_pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_profile_pic.position = Vector2(24.0, 74.0)
	_profile_pic.size = Vector2(78.0, 78.0)
	_profile_pic.z_index = 1   # in primo piano rispetto al name frame (attaccato)
	add_child(_profile_pic)
	var pbtn := Button.new()
	pbtn.focus_mode = Control.FOCUS_NONE
	var pe := StyleBoxEmpty.new()
	pbtn.add_theme_stylebox_override("normal", pe)
	pbtn.add_theme_stylebox_override("hover", pe)
	pbtn.add_theme_stylebox_override("pressed", pe)
	pbtn.add_theme_stylebox_override("focus", pe)
	pbtn.set_anchors_preset(Control.PRESET_FULL_RECT)
	pbtn.pressed.connect(_open_profile)
	_profile_pic_base = _profile_pic.position
	pbtn.button_down.connect(func() -> void:
		_profile_pic.position = _profile_pic_base + Vector2(0, PRESS_SINK)
		_profile_pic.modulate = Color(0.85, 0.85, 0.85)
		if _name_frame:
			_name_frame.position = _name_frame_base + Vector2(0, PRESS_SINK)
		if _name_edit:
			_name_edit.position = _name_edit_base + Vector2(0, PRESS_SINK))
	pbtn.button_up.connect(func() -> void:
		_profile_pic.position = _profile_pic_base
		_profile_pic.modulate = Color(1, 1, 1)
		if _name_frame:
			_name_frame.position = _name_frame_base
		if _name_edit:
			_name_edit.position = _name_edit_base)
	_profile_pic.add_child(pbtn)

	# NAME FRAME SOTTO la profile (l'icona sta SOPRA il frame del nome)
	var nf_h := 78.0
	var nf_w := nf_h * 896.0 / 384.0       # mantiene l'aspect del frame
	_name_frame = TextureRect.new()
	_name_frame.texture = load("res://CORE/Assets/Art/Home/name_frame.png")
	_name_frame.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_name_frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_name_frame.stretch_mode = TextureRect.STRETCH_SCALE
	_name_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_name_frame.position = Vector2(24.0 + 78.0 - 18.0, 74.0)
	_name_frame.size = Vector2(nf_w, nf_h)
	_name_frame_base = _name_frame.position
	add_child(_name_frame)

	# nome in SOLA LETTURA (si modifica solo in EDIT PROFILE), allineato a sinistra, più grande
	_name_edit = LineEdit.new()
	_name_edit.text = _player_name
	_name_edit.max_length = 12
	_name_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_edit.editable = false
	_name_edit.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_name_edit.add_theme_font_override("font", MODE_FONT)
	_name_edit.add_theme_font_size_override("font_size", 30)
	_name_edit.add_theme_color_override("font_color", Color(1, 1, 1))
	_name_edit.add_theme_color_override("font_uneditable_color", Color(1, 1, 1))
	var empty := StyleBoxEmpty.new()
	_name_edit.add_theme_stylebox_override("normal", empty)
	_name_edit.add_theme_stylebox_override("read_only", empty)
	# centrato nel frame, leggermente spostato a destra
	_name_edit.position = _name_frame.position + Vector2(nf_w * 0.12, nf_h * 0.12)
	_name_edit.size = Vector2(nf_w * 0.78, nf_h * 0.62)
	_name_edit_base = _name_edit.position
	add_child(_name_edit)


func _current_profile_icon_path() -> String:
	var i := clampi(_profile_icon_index, 0, PROFILE_ICONS.size() - 1)
	return PROFILE_ICONS[i]

func _load_player_name() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PROFILE_CFG) == OK:
		_player_name = str(cfg.get_value("profile", "name", "PLAYER"))
		_profile_icon_index = int(cfg.get_value("profile", "icon", 0))
	_profile_icon_index = clampi(_profile_icon_index, 0, PROFILE_ICONS.size() - 1)
	_profile_sel_index = _profile_icon_index

func _save_player_name() -> void:
	if _name_edit:
		var n := _name_edit.text.strip_edges()
		if n == "":
			n = "PLAYER"
			_name_edit.text = n
		_player_name = n
	_write_profile_cfg()

func _write_profile_cfg() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("profile", "name", _player_name)
	cfg.set_value("profile", "icon", _profile_icon_index)
	cfg.save(PROFILE_CFG)


# ======================= SCHERMATA EDIT PROFILE ================================
func _ptex(path: String) -> TextureRect:
	var t := TextureRect.new()
	t.texture = load(path)
	t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_SCALE
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t

func _ptbtn(path: String, cb: Callable) -> TextureButton:
	var b := TextureButton.new()
	b.texture_normal = load(path)
	b.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	b.ignore_texture_size = true
	b.stretch_mode = TextureButton.STRETCH_SCALE
	b.pressed.connect(cb)
	_add_press_sink(b)
	return b


# animazione pressione riutilizzabile: il tasto si abbassa e scurisce mentre è premuto
func _add_press_sink(b: BaseButton) -> void:
	b.button_down.connect(func() -> void:
		b.position.y += PRESS_SINK
		b.modulate = Color(0.85, 0.85, 0.85))
	b.button_up.connect(func() -> void:
		b.position.y -= PRESS_SINK
		b.modulate = Color(1, 1, 1))

func _build_profile_menu() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 20   # sopra la nav bar (10)
	add_child(layer)
	_profile_menu = Control.new()
	_profile_menu.set_anchors_preset(Control.PRESET_FULL_RECT)
	_profile_menu.visible = false
	layer.add_child(_profile_menu)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_profile_menu.add_child(dim)
	_profile_frame = Control.new()
	_profile_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_profile_menu.add_child(_profile_frame)
	_profile_bg = _ptex(PROFILE_DIR + "frame_bg.png")
	_profile_frame.add_child(_profile_bg)
	# header
	_profile_title = Label.new()
	_profile_title.text = "EDIT PROFILE"
	_profile_title.add_theme_font_override("font", MODE_FONT)
	_profile_title.add_theme_color_override("font_color", Color(1, 1, 1))
	_profile_title.add_theme_color_override("font_outline_color", Color(0.16, 0.07, 0.0))
	_profile_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_profile_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_profile_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_profile_frame.add_child(_profile_title)
	# anteprima icona scelta
	_profile_prev = _ptex(_current_profile_icon_path())
	_profile_frame.add_child(_profile_prev)
	# name box + titolo + campo editabile
	_profile_namebox = _ptex(PROFILE_DIR + "name_box.png")
	_profile_frame.add_child(_profile_namebox)
	_profile_name_title = Label.new()
	_profile_name_title.text = "NOME GIOCATORE"
	_profile_name_title.add_theme_font_override("font", MODE_FONT)
	_profile_name_title.add_theme_color_override("font_color", Color(1, 1, 1))
	_profile_name_title.add_theme_color_override("font_outline_color", Color(0.16, 0.07, 0.0))
	_profile_name_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_profile_name_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_profile_frame.add_child(_profile_name_title)
	_profile_name_edit = LineEdit.new()
	_profile_name_edit.max_length = 12
	_profile_name_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_profile_name_edit.add_theme_font_override("font", MODE_FONT)
	_profile_name_edit.add_theme_color_override("font_color", Color(1, 1, 1))
	var pe := StyleBoxEmpty.new()
	_profile_name_edit.add_theme_stylebox_override("normal", pe)
	_profile_name_edit.add_theme_stylebox_override("focus", pe)
	# il nome si modifica SOLO col tasto giallo edit (non toccando la box): niente click diretti
	_profile_name_edit.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_profile_name_edit.text_submitted.connect(func(_t: String) -> void: _profile_name_edit.release_focus())
	_profile_frame.add_child(_profile_name_edit)
	# tasto modifica nome
	_profile_edit_btn = _ptbtn(PROFILE_DIR + "edit_name.png", _profile_edit_name)
	_profile_frame.add_child(_profile_edit_btn)
	# frame selezione + griglia icone scorribile
	_profile_selframe = _ptex(PROFILE_DIR + "select_frame.png")
	_profile_frame.add_child(_profile_selframe)
	_profile_scroll = ScrollContainer.new()
	_profile_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_profile_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	_profile_scroll.clip_contents = true
	_profile_frame.add_child(_profile_scroll)
	_profile_grid = GridContainer.new()
	_profile_grid.columns = 4
	_profile_scroll.add_child(_profile_grid)
	for i in PROFILE_ICONS.size():
		var b := _ptbtn(PROFILE_ICONS[i], _select_profile_icon.bind(i))
		_profile_grid.add_child(b)
		_profile_icon_btns.append(b)
	# cancel / confirm
	_profile_cancel = _ptbtn(PROFILE_DIR + "cancel.png", _close_profile)
	_profile_frame.add_child(_profile_cancel)
	_profile_confirm = _ptbtn(PROFILE_DIR + "confirm.png", _confirm_profile)
	_profile_frame.add_child(_profile_confirm)


func _layout_profile() -> void:
	if not _profile_frame:
		return
	var view := get_viewport_rect().size
	var fw := minf(view.x * 0.84, 452.0)
	var fh := fw * 2912.0 / 2048.0
	if fh > view.y * 0.88:
		fh = view.y * 0.88
		fw = fh * 2048.0 / 2912.0
	var fx := (view.x - fw) * 0.5
	var fy := (view.y - fh) * 0.5
	_profile_frame.position = Vector2(fx, fy)
	_profile_frame.size = Vector2(fw, fh)
	_profile_bg.position = Vector2.ZERO
	_profile_bg.size = Vector2(fw, fh)
	# titolo GRANDE con STROKE più spesso
	_profile_title.add_theme_font_size_override("font_size", int(fh * 0.072))
	_profile_title.add_theme_constant_override("outline_size", maxi(4, int(fh * 0.015)))
	_profile_title.position = Vector2(0, -fh * 0.006)
	_profile_title.size = Vector2(fw, fh * 0.11)
	# riga ATTACCATA: anteprima | name box (più grande) | edit
	var row_cy := fh * 0.215
	var prev_s := fw * 0.19
	var eb_s := fw * 0.16
	var nb_w := fw * 0.46
	var nb_h := nb_w * 0.26   # name box un po' più alto del nativo (0.2) = più grande
	var glx := (fw - (prev_s + nb_w + eb_s)) * 0.5
	_profile_prev.position = Vector2(glx, row_cy - prev_s * 0.5)
	_profile_prev.size = Vector2(prev_s, prev_s)
	var nb_x := glx + prev_s
	_profile_namebox.position = Vector2(nb_x, row_cy - nb_h * 0.5)
	_profile_namebox.size = Vector2(nb_w, nb_h)
	_profile_name_title.add_theme_font_size_override("font_size", int(fh * 0.034))
	_profile_name_title.add_theme_constant_override("outline_size", maxi(2, int(fh * 0.006)))
	_profile_name_title.position = Vector2(nb_x, row_cy - nb_h * 0.5 - fh * 0.042)
	_profile_name_title.size = Vector2(nb_w, fh * 0.042)
	_profile_name_edit.add_theme_font_size_override("font_size", int(nb_h * 0.56))
	_profile_name_edit.position = Vector2(nb_x + nb_w * 0.05, row_cy - nb_h * 0.34)
	_profile_name_edit.size = Vector2(nb_w * 0.9, nb_h * 0.68)
	_profile_edit_btn.position = Vector2(nb_x + nb_w, row_cy - eb_s * 0.5)
	_profile_edit_btn.size = Vector2(eb_s, eb_s)
	# frame selezione icone: ABBASSATO
	var sf_w := fw * 0.88
	var sf_h := sf_w * 1504.0 / 1856.0
	var sf_x := (fw - sf_w) * 0.5
	var sf_y := fh * 0.31
	_profile_selframe.position = Vector2(sf_x, sf_y)
	_profile_selframe.size = Vector2(sf_w, sf_h)
	var pad := sf_w * 0.07
	_profile_scroll.position = Vector2(sf_x + pad, sf_y + pad)
	_profile_scroll.size = Vector2(sf_w - pad * 2.0, sf_h - pad * 2.0)
	var gap := int(sf_w * 0.03)
	_profile_grid.add_theme_constant_override("h_separation", gap)
	_profile_grid.add_theme_constant_override("v_separation", gap)
	var cell := (sf_w - pad * 2.0 - gap * 3) / 4.0
	for b in _profile_icon_btns:
		b.custom_minimum_size = Vector2(cell, cell)
	# cancel / confirm
	var bw := fw * 0.38
	var bh := bw * 320.0 / 896.0
	var by := fh * 0.895 - bh * 0.5
	_profile_cancel.position = Vector2(fw * 0.265 - bw * 0.5, by)
	_profile_cancel.size = Vector2(bw, bh)
	_profile_confirm.position = Vector2(fw * 0.735 - bw * 0.5, by)
	_profile_confirm.size = Vector2(bw, bh)


func _open_profile() -> void:
	settings.button_feedback()
	_profile_sel_index = _profile_icon_index
	_profile_name_edit.text = _player_name
	_update_profile_selection()
	_layout_profile()
	_profile_menu.visible = true

func _close_profile() -> void:
	settings.button_feedback()
	_profile_menu.visible = false

func _select_profile_icon(i: int) -> void:
	settings.button_feedback()
	_profile_sel_index = i
	_update_profile_selection()

func _update_profile_selection() -> void:
	for k in _profile_icon_btns.size():
		var b: TextureButton = _profile_icon_btns[k]
		b.modulate = Color(1, 1, 1) if k == _profile_sel_index else Color(0.5, 0.5, 0.5)
	if _profile_prev:
		_profile_prev.texture = load(PROFILE_ICONS[clampi(_profile_sel_index, 0, PROFILE_ICONS.size() - 1)])

func _profile_edit_name() -> void:
	settings.button_feedback()
	if _profile_name_edit:
		_profile_name_edit.grab_focus()
		_profile_name_edit.select_all()

func _confirm_profile() -> void:
	settings.button_feedback()
	# nome
	var n := _profile_name_edit.text.strip_edges()
	if n == "":
		n = "PLAYER"
	_player_name = n
	if _name_edit:
		_name_edit.text = _player_name   # aggiorna la home
	# icona
	_profile_icon_index = _profile_sel_index
	if _profile_pic:
		_profile_pic.texture = load(_current_profile_icon_path())
	_write_profile_cfg()
	_profile_menu.visible = false


func _make_icon_button(path: String, pos: Vector2, sz: float) -> TextureButton:
	var b := TextureButton.new()
	b.texture_normal = load(path)
	b.ignore_texture_size = true
	b.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	b.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	b.position = pos
	b.size = Vector2(sz, sz)
	add_child(b)
	# animazione pressione: si abbassa leggermente + scurisce
	var base := pos
	b.button_down.connect(func() -> void:
		b.position = base + Vector2(0, PRESS_SINK)
		b.modulate = Color(0.85, 0.85, 0.85))
	b.button_up.connect(func() -> void:
		b.position = base
		b.modulate = Color(1, 1, 1))
	return b


func _update_coin_count() -> void:
	if _coin_count_label:
		_coin_count_label.text = str(missions.coins)


func _on_leaderboard_pressed() -> void:
	settings.button_feedback()
	if _leader_menu:
		_populate_leader()
		_layout_leader()
		_leader_menu.visible = true


# ============================ CLASSIFICA (leaderboard) =========================
func _build_leader_menu() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 15   # sopra la nav bar (10)
	add_child(layer)
	_leader_menu = Control.new()
	_leader_menu.set_anchors_preset(Control.PRESET_FULL_RECT)
	_leader_menu.visible = false
	layer.add_child(_leader_menu)
	# sfondo blu + pannello scuro (stessa base delle missioni)
	_leader_bg = ColorRect.new()
	_leader_bg.color = Color(5.0 / 255.0, 120.0 / 255.0, 236.0 / 255.0, 1.0)
	_leader_bg.mouse_filter = Control.MOUSE_FILTER_STOP
	_leader_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_leader_menu.add_child(_leader_bg)
	_leader_panel = ColorRect.new()
	_leader_panel.color = Color(0.0, 79.0 / 255.0, 135.0 / 255.0, 1.0)
	_leader_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_leader_menu.add_child(_leader_panel)
	# tasto chiudi (X) in alto a sinistra
	_leader_close = TextureButton.new()
	_leader_close.texture_normal = load("res://CORE/Assets/Art/UI/Game/exit_x.png")
	_leader_close.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_leader_close.ignore_texture_size = true
	_leader_close.stretch_mode = TextureButton.STRETCH_SCALE
	_leader_close.position = Vector2(24, 108)
	_leader_close.size = Vector2(72, 72)
	_leader_close.pressed.connect(_close_leader)
	_add_press_sink(_leader_close)
	_leader_menu.add_child(_leader_close)
	# titolo TOP CRASHER (stesso livello della X, centrato)
	_leader_title = Label.new()
	_leader_title.text = "TOP CRASHER"
	_leader_title.add_theme_font_override("font", MODE_FONT)
	_leader_title.add_theme_font_size_override("font_size", 42)
	_leader_title.add_theme_color_override("font_color", Color(1, 0.93, 0.5))
	_leader_title.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_leader_title.add_theme_constant_override("outline_size", 8)
	_leader_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_leader_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_leader_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_leader_menu.add_child(_leader_title)
	# striscia TAB classic/speedrun
	_leader_tabs = TextureRect.new()
	_leader_tabs.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_leader_tabs.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_leader_tabs.stretch_mode = TextureRect.STRETCH_SCALE
	_leader_tabs.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_leader_tabs.texture = load(LB_DIR + "tabs_classic.png")
	_leader_menu.add_child(_leader_tabs)
	_tab_classic_btn = _make_tab_button(func() -> void: _select_leader_tab("classic"), _leader_menu)
	_tab_speed_btn = _make_tab_button(func() -> void: _select_leader_tab("speedrun"), _leader_menu)
	# timer "Nuova classifica tra:"
	_leader_timer = Label.new()
	_leader_timer.add_theme_font_override("font", MODE_FONT)
	_leader_timer.add_theme_font_size_override("font_size", 20)
	_leader_timer.add_theme_color_override("font_color", Color(1, 1, 1, 0.85))
	_leader_timer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_leader_menu.add_child(_leader_timer)
	# lista scorrevole
	_leader_scroll = ScrollContainer.new()
	_leader_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_leader_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	_leader_scroll.clip_contents = true
	_leader_menu.add_child(_leader_scroll)
	_leader_list = VBoxContainer.new()
	_leader_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_leader_list.add_theme_constant_override("separation", 8)
	_leader_scroll.add_child(_leader_list)


func _close_leader() -> void:
	settings.button_feedback()
	_leader_menu.visible = false

func _select_leader_tab(tab: String) -> void:
	settings.button_feedback()
	_leader_tab = tab
	if _leader_tabs:
		_leader_tabs.texture = load(LB_DIR + ("tabs_classic.png" if tab == "classic" else "tabs_speedrun.png"))
	_populate_leader()

func _leader_refresh_text() -> String:
	# la classifica si rinnova ogni 7 giorni (settimana unix corrente)
	var wk := 604800
	var now := int(Time.get_unix_time_from_system())
	var left := wk - (now % wk)
	return "Nuova classifica tra: %dg %02dh" % [left / 86400, (left % 86400) / 3600]

func _layout_leader() -> void:
	if not _leader_tabs:
		return
	var view := get_viewport_rect().size
	var nav_h := minf(view.x, NAV_MAX_W) * (NAV_TEX.y / NAV_TEX.x)
	if _leader_close:
		_leader_close.position = Vector2(view.x - 96.0, 108.0)
	if _leader_title:
		_leader_title.position = Vector2(0, 116.0)
		_leader_title.size = Vector2(view.x, 56.0)
	var tabs_y := 200.0
	var th := view.x * 94.0 / 576.0
	_leader_tabs.position = Vector2(0, tabs_y)
	_leader_tabs.size = Vector2(view.x, th)
	_tab_classic_btn.position = Vector2(0, tabs_y)
	_tab_classic_btn.size = Vector2(view.x * 0.5, th)
	_tab_speed_btn.position = Vector2(view.x * 0.5, tabs_y)
	_tab_speed_btn.size = Vector2(view.x * 0.5, th)
	var panel_top := tabs_y + th - 6.0
	_leader_panel.position = Vector2(0, panel_top)
	_leader_panel.size = Vector2(view.x, maxf(60.0, view.y - panel_top))
	_leader_timer.position = Vector2(0, panel_top + 12.0)
	_leader_timer.size = Vector2(view.x, 28.0)
	var scroll_top := panel_top + 50.0
	_leader_scroll.position = Vector2(32.0, scroll_top)
	_leader_scroll.size = Vector2(view.x - 64.0, maxf(120.0, view.y - scroll_top))

func _populate_leader() -> void:
	if not _leader_list:
		return
	for c in _leader_list.get_children():
		c.queue_free()
	if _leader_tabs:
		_leader_tabs.texture = load(LB_DIR + ("tabs_classic.png" if _leader_tab == "classic" else "tabs_speedrun.png"))
	_leader_timer.text = _leader_refresh_text()
	# padding in alto
	var head := Control.new()
	head.custom_minimum_size = Vector2(0, 20)
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_leader_list.add_child(head)
	for e in _gen_leaderboard(_leader_tab):
		_leader_list.add_child(_make_leader_row(e))
	var tail := Control.new()
	tail.custom_minimum_size = Vector2(0, 180)
	tail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_leader_list.add_child(tail)

func _player_score(mode: String) -> int:
	var cfg := ConfigFile.new()
	if cfg.load("user://save.cfg") == OK:
		if mode == "speedrun":
			return int(cfg.get_value("scores", "speedrun_best", 0))
		return int(cfg.get_value("scores", "high_score", 0))
	return 0

func _fmt_score(n: int) -> String:
	var s := str(n)
	var out := ""
	var cnt := 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		cnt += 1
		if cnt % 3 == 0 and i > 0:
			out = "." + out
	return out

func _gen_leaderboard(mode: String) -> Array:
	var week := int(Time.get_unix_time_from_system()) / 604800
	var rng := RandomNumberGenerator.new()
	rng.seed = int(hash(mode)) + week * 7919
	var names := ["Kirry", "Marco", "Luna", "Rex", "Nova", "Zed", "Milo", "Ivy", "Ace", "Kai",
		"Bree", "Neo", "Skye", "Jax", "Vera", "Oro", "Pip", "Rux", "Tila", "Enzo",
		"Gwen", "Dax", "Remy", "Suki", "Bolt", "Coco", "Fenn", "Lux", "Mira", "Nix"]
	var top_score: int = 6000000 if mode == "classic" else 45000
	var entries: Array = []
	var s := top_score
	for i in range(120):
		var nm: String = names[rng.randi() % names.size()] + str(rng.randi_range(1, 999))
		entries.append({"name": nm, "score": s, "icon": 0, "is_player": false})
		s = int(float(s) * rng.randf_range(0.90, 0.985)) - rng.randi_range(50, 500)
		if s < 100:
			s = 100
	var pscore := _player_score(mode)
	if pscore > 0:
		entries.append({"name": _player_name, "score": pscore, "icon": _profile_icon_index, "is_player": true})
	entries.sort_custom(func(a, b): return a["score"] > b["score"])
	# rank reale del giocatore (anche oltre la top 100)
	var player_rank := -1
	for i in entries.size():
		if entries[i].get("is_player", false):
			player_rank = i + 1
	var top: Array = entries.slice(0, 100)
	for i in top.size():
		top[i]["rank"] = i + 1
	# se sei fuori dalla top 100, aggiungi la tua riga in fondo con "100+"
	if pscore > 0 and player_rank > 100:
		top.append({"name": _player_name, "score": pscore, "icon": _profile_icon_index, "is_player": true, "rank": 0, "rank_text": "100+"})
	return top

func _make_leader_row(e: Dictionary) -> Control:
	var rank: int = int(e.get("rank", 0))
	var is_player: bool = e.get("is_player", false)
	var rank_txt: String = str(e.get("rank_text", str(rank)))
	# barra verde dedicata per la TUA riga (mostra subito la tua posizione)
	var bar: String = "bar_other.png"
	if is_player:
		bar = "bar_player.png"
	elif rank == 1:
		bar = "bar_1.png"
	elif rank == 2:
		bar = "bar_2.png"
	elif rank == 3:
		bar = "bar_3.png"
	var row := Control.new()
	row.custom_minimum_size = Vector2(LB_ROW_W, LB_ROW_H)
	row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# barra di sfondo
	row.add_child(_miss_tex(LB_DIR + bar, Vector2.ZERO, Vector2(LB_ROW_W, LB_ROW_H)))
	var txt_col := Color(1, 1, 1) if (is_player or rank > 3) else Color(0.10, 0.06, 0.0)
	# posizione (numero, o "100+") a sinistra
	var rank_sz: int = 24 if e.has("rank_text") else 30
	row.add_child(_lb_label(rank_txt, rank_sz, txt_col, Vector2(LB_ROW_W * 0.01, 0), Vector2(LB_ROW_W * 0.15, LB_ROW_H), HORIZONTAL_ALIGNMENT_CENTER))
	# icona profilo (un po' più piccola)
	var ic := LB_ROW_H * 0.62
	row.add_child(_miss_tex(PROFILE_ICONS[clampi(int(e["icon"]), 0, PROFILE_ICONS.size() - 1)], Vector2(LB_ROW_W * 0.16, (LB_ROW_H - ic) * 0.5), Vector2(ic, ic), true))
	# nome
	row.add_child(_lb_label(str(e["name"]), 24, txt_col, Vector2(LB_ROW_W * 0.30, 0), Vector2(LB_ROW_W * 0.34, LB_ROW_H), HORIZONTAL_ALIGNMENT_LEFT))
	# punteggio agganciato a destra: giallo chiaro + stroke nero
	var sc := _lb_label(_fmt_score(int(e["score"])), 24, Color(1, 0.93, 0.5), Vector2(LB_ROW_W * 0.60, 0), Vector2(LB_ROW_W * 0.36, LB_ROW_H), HORIZONTAL_ALIGNMENT_RIGHT)
	sc.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	sc.add_theme_constant_override("outline_size", 5)
	row.add_child(sc)
	return row

func _lb_label(txt: String, size: int, col: Color, pos: Vector2, sz: Vector2, halign: int) -> Label:
	var l := Label.new()
	l.text = txt
	l.add_theme_font_override("font", MODE_FONT)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.horizontal_alignment = halign
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.position = pos
	l.size = sz
	return l


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
	# CanvasLayer (screen-space, come la nav bar): niente shift della camera
	var layer := CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	_missions_menu = Control.new()
	_missions_menu.set_anchors_preset(Control.PRESET_FULL_RECT)
	_missions_menu.visible = false
	layer.add_child(_missions_menu)

	# sfondo blu pieno (adattato a tutto lo schermo)
	var bg := ColorRect.new()
	bg.color = Color(5.0 / 255.0, 120.0 / 255.0, 236.0 / 255.0, 1.0)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_missions_menu.add_child(bg)

	# pannello scuro (contenuto): dietro allo scroll, stirato fino alla nav bar (in _layout)
	_missions_panel = ColorRect.new()
	_missions_panel.color = Color(0.0, 79.0 / 255.0, 135.0 / 255.0, 1.0)
	_missions_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_missions_menu.add_child(_missions_panel)

	# coin counter in ALTO A DESTRA (nella fascia trasparente sopra i tab)
	var coinbar := TextureRect.new()
	coinbar.texture = load("res://CORE/Assets/Art/UI/Menu/coin_count.png")
	coinbar.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	coinbar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coinbar.stretch_mode = TextureRect.STRETCH_SCALE
	coinbar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coinbar.position = Vector2(356, 132)
	coinbar.size = Vector2(196, 196.0 * 176.0 / 792.0)
	coinbar.pivot_offset = coinbar.size * 0.5
	_missions_menu.add_child(coinbar)
	_missions_coin_bar = coinbar
	_missions_coins_label = Label.new()
	_missions_coins_label.add_theme_font_override("font", MODE_FONT)
	_missions_coins_label.add_theme_font_size_override("font_size", 30)
	_missions_coins_label.add_theme_color_override("font_color", Color(1, 1, 1))
	_missions_coins_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_missions_coins_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_missions_coins_label.position = Vector2(406, 132)
	_missions_coins_label.size = Vector2(140, 44)
	_missions_menu.add_child(_missions_coins_label)

	# striscia TAB (weekly / daily): texture full-width, posizionata in _layout
	_missions_tabs = TextureRect.new()
	_missions_tabs.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_missions_tabs.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_missions_tabs.stretch_mode = TextureRect.STRETCH_SCALE
	_missions_tabs.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_missions_tabs.texture = load(MISS + "tabs_weekly.png")
	_missions_menu.add_child(_missions_tabs)
	_tab_weekly_btn = _make_tab_button(func() -> void: _select_mission_tab("weekly"))
	_tab_daily_btn = _make_tab_button(func() -> void: _select_mission_tab("daily"))

	# timer "Nuove missioni disponibili tra:" (dentro il pannello, sopra la lista)
	_missions_timer_label = Label.new()
	_missions_timer_label.add_theme_font_override("font", MODE_FONT)
	_missions_timer_label.add_theme_font_size_override("font_size", 20)
	_missions_timer_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.85))
	_missions_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_missions_menu.add_child(_missions_timer_label)

	# lista SCROLLABILE clippata dentro il pannello (posizione/size in _layout)
	_missions_scroll = ScrollContainer.new()
	_missions_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_missions_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	_missions_scroll.clip_contents = true
	_missions_menu.add_child(_missions_scroll)
	_missions_list = VBoxContainer.new()
	_missions_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_missions_list.custom_minimum_size = Vector2(488, 0)
	_missions_list.add_theme_constant_override("separation", 12)
	_missions_scroll.add_child(_missions_list)


# Tasto trasparente per un tab (posizione/size in _layout).
func _make_tab_button(cb: Callable, parent: Node = null) -> Button:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	var empty := StyleBoxEmpty.new()
	b.add_theme_stylebox_override("normal", empty)
	b.add_theme_stylebox_override("hover", empty)
	b.add_theme_stylebox_override("pressed", empty)
	b.add_theme_stylebox_override("focus", empty)
	b.pressed.connect(cb)
	(parent if parent != null else _missions_menu).add_child(b)
	return b


func _select_mission_tab(tab: String) -> void:
	settings.button_feedback()
	_missions_tab = tab
	if _missions_tabs:
		var p := MISS + ("tabs_weekly.png" if tab == "weekly" else "tabs_daily.png")
		_missions_tabs.texture = load(p)
	_populate_missions()


func _refresh_text() -> String:
	if _missions_tab == "weekly":
		var w := missions.seconds_until_weekly_refresh()
		return "Nuove missioni disponibili tra: %dg %02dh" % [w / 86400, (w % 86400) / 3600]
	var s := missions.seconds_until_refresh()
	return "Nuove missioni disponibili tra: %dh %02dm" % [s / 3600, (s % 3600) / 60]


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
	_missions_coins_label.text = str(missions.coins)
	if _missions_tabs:
		_missions_tabs.texture = load(MISS + ("tabs_weekly.png" if _missions_tab == "weekly" else "tabs_daily.png"))
	_missions_timer_label.text = _refresh_text()
	# padding in alto: spazio così il badge della prima riga non viene tagliato
	var head := Control.new()
	head.custom_minimum_size = Vector2(0, 26)
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_missions_list.add_child(head)
	var is_weekly := _missions_tab == "weekly"
	var arr: Array = missions.weekly if is_weekly else missions.missions
	for i in arr.size():
		if arr[i]["claimed"]:
			continue   # riscosse: spariscono
		_missions_list.add_child(_make_mission_row(i, arr[i], is_weekly))
	# spazio in fondo: abbastanza da far salire l'ultima riga sopra la nav bar
	var tail := Control.new()
	tail.custom_minimum_size = Vector2(0, 180)
	tail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_missions_list.add_child(tail)
	_update_mission_badges()


const ROW_W := 488.0
const ROW_H := 146.0
const MISS := "res://CORE/Assets/Art/UI/Missions/"

func _miss_tex(path: String, pos: Vector2, sz: Vector2, keep: bool = false) -> TextureRect:
	var t := TextureRect.new()
	t.texture = load(path)
	t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED if keep else TextureRect.STRETCH_SCALE
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.position = pos
	t.size = sz
	return t

func _mission_icon_path(m: Dictionary) -> String:
	var color := "red"
	match m["type"]:
		"break_color": color = str(m["param"])
		"score": color = "yellow"
		"break_total": color = "blue"
		"combo": color = "purple"
		"play": color = "green"
	var cap := color.capitalize()
	return "res://CORE/Assets/Art/Game/Cubes/%s/%s.svg" % [cap, cap]

func _miss_label(txt: String, size: int, col: Color, pos: Vector2, sz: Vector2, halign: int) -> Label:
	var l := Label.new()
	l.text = txt
	l.add_theme_font_override("font", MODE_FONT)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.horizontal_alignment = halign
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.position = pos
	l.size = sz
	return l

const MISS_SINK := 4.0

func _make_mission_row(index: int, m: Dictionary, is_weekly: bool = false) -> Control:
	var done: bool = missions.is_complete(m) and not m["claimed"]
	var bg_tex: String = "mission_bg_done.png" if done else "mission_bg.png"
	var icon_tex: String = "icon_frame_done.png" if done else "icon_frame.png"
	var rew_tex: String = "reward_frame_done.png" if done else "reward_frame.png"
	var txt_col := Color(1, 1, 1)   # testo sempre bianco (anche missioni completate)

	var row := Control.new()
	row.custom_minimum_size = Vector2(ROW_W, ROW_H)
	row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER   # riga centrata orizzontalmente
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE   # non blocca lo scroll
	# contenuto: si abbassa alla pressione
	var content := Control.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.position = Vector2.ZERO
	content.size = Vector2(ROW_W, ROW_H)
	row.add_child(content)

	content.add_child(_miss_tex(MISS + bg_tex, Vector2.ZERO, Vector2(ROW_W, ROW_H)))

	# ICONA (sinistra) = frame + cubo del colore della missione
	var ih := ROW_H * 0.72
	var iw := ih * (576.0 / 608.0)
	var ix := ROW_W * 0.045
	var iy := (ROW_H - ih) * 0.5
	content.add_child(_miss_tex(MISS + icon_tex, Vector2(ix, iy), Vector2(iw, ih)))
	var cs := iw * 0.62
	content.add_child(_miss_tex(_mission_icon_path(m), Vector2(ix + (iw - cs) * 0.5, iy + (ih - cs) * 0.5), Vector2(cs, cs), true))

	# REWARD (destra) = frame + "RICOMPENSE" + coin + quantità
	var rw := iw
	var rh := ih
	var rx := ROW_W - ROW_W * 0.045 - rw
	var ry := iy
	content.add_child(_miss_tex(MISS + rew_tex, Vector2(rx, ry), Vector2(rw, rh)))
	content.add_child(_miss_label("RICOMPENSE", 16, txt_col, Vector2(rx, ry + 3), Vector2(rw, 20), HORIZONTAL_ALIGNMENT_CENTER))
	var coinS := rh * 0.40
	var coinX := rx + rw * 0.10
	var coinY := ry + rh * 0.42
	content.add_child(_miss_tex(MISS + "coin_icon.png", Vector2(coinX, coinY), Vector2(coinS, coinS), true))
	var amt_col: Color = Color(1, 1, 1) if done else Color(1, 0.86, 0.12)
	content.add_child(_miss_label(str(m["reward"]), 22, amt_col, Vector2(coinX + coinS + 4, coinY), Vector2(rw * 0.55, coinS), HORIZONTAL_ALIGNMENT_LEFT))

	# CENTRO: testo (ALLINEATO A SINISTRA) + barra progresso
	var cl := ix + iw + ROW_W * 0.03
	var cr := rx - ROW_W * 0.03
	var cw := cr - cl
	content.add_child(_miss_label(missions.describe(m), 20, txt_col, Vector2(cl, ROW_H * 0.08), Vector2(cw, ROW_H * 0.44), HORIZONTAL_ALIGNMENT_LEFT))

	var bw := cw * 0.98
	var bh := bw * (224.0 / 1280.0)
	var bx := cl + (cw - bw) * 0.5
	var by := ROW_H * 0.60
	if done:
		content.add_child(_miss_tex(MISS + "bar_complete.png", Vector2(bx, by), Vector2(bw, bh)))
		content.add_child(_miss_label("RISCATTA LE RICOMPENSE", 13, Color(1, 1, 1), Vector2(bx, by), Vector2(bw, bh), HORIZONTAL_ALIGNMENT_CENTER))
	else:
		content.add_child(_miss_tex(MISS + "bar_back.png", Vector2(bx, by), Vector2(bw, bh)))
		var frac := clampf(float(m["progress"]) / float(maxi(1, int(m["target"]))), 0.0, 1.0)
		var fill := ColorRect.new()
		fill.color = Color(1.0, 0.82, 0.10)
		fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fill.position = Vector2(bx + bw * 0.025, by + bh * 0.143)
		fill.size = Vector2(bw * (0.974 - 0.025) * frac, bh * (0.853 - 0.143))
		content.add_child(fill)
		content.add_child(_miss_tex(MISS + "bar_front.png", Vector2(bx, by), Vector2(bw, bh)))
		var prog := _miss_label("%d/%d" % [m["progress"], m["target"]], 18, Color(1, 1, 1), Vector2(bx, by), Vector2(bw, bh), HORIZONTAL_ALIGNMENT_CENTER)
		prog.add_theme_constant_override("outline_size", 6)
		prog.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
		content.add_child(prog)

	# badge "completata" in alto a destra della riga (solo se completa e non riscossa)
	if done:
		content.add_child(_miss_tex(MISS + "mission_done_badge.png", Vector2(ROW_W - 38.0, -14.0), Vector2(44.0, 44.0), true))
		# stroke verde scuro sui testi delle missioni completate
		for c in content.get_children():
			if c is Label:
				c.add_theme_color_override("font_outline_color", Color(0.0, 0.22, 0.06))
				c.add_theme_constant_override("outline_size", 5)

	# tasto: ogni missione è pressabile (affonda); se completa riscuote
	var btn := Button.new()
	btn.focus_mode = Control.FOCUS_NONE
	var empty := StyleBoxEmpty.new()
	btn.add_theme_stylebox_override("normal", empty)
	btn.add_theme_stylebox_override("hover", empty)
	btn.add_theme_stylebox_override("pressed", empty)
	btn.add_theme_stylebox_override("focus", empty)
	btn.position = Vector2.ZERO
	btn.size = Vector2(ROW_W, ROW_H)
	# PASS: il tap preme la riga, ma il drag arriva alla ScrollContainer (scroll fluido, non si blocca)
	btn.mouse_filter = Control.MOUSE_FILTER_PASS
	btn.button_down.connect(func() -> void: content.position = Vector2(0, MISS_SINK))
	btn.button_up.connect(func() -> void: content.position = Vector2.ZERO)
	if done:
		btn.pressed.connect(_claim_mission.bind(index, is_weekly))
	row.add_child(btn)
	return row


func _claim_mission(index: int, is_weekly: bool = false) -> void:
	var before := missions.coins
	var got := missions.claim_weekly(index) if is_weekly else missions.claim(index)
	if got > 0:
		settings.button_feedback()
		_update_coin_label()
		_update_coin_count()
		_populate_missions()
		_animate_coin_gain(before, missions.coins)


# Monete che salgono (conteggio) + rimbalzo quando si riscatta una missione.
func _animate_coin_gain(from_v: int, to_v: int) -> void:
	if _missions_coins_label == null:
		return
	_missions_coins_label.pivot_offset = _missions_coins_label.size * 0.5
	var t := create_tween()
	t.tween_method(func(v: float) -> void: _missions_coins_label.set_text(str(int(round(v)))), float(from_v), float(to_v), 0.6)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	var tb := create_tween()
	tb.tween_property(_missions_coins_label, "scale", Vector2(1.45, 1.45), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tb.tween_property(_missions_coins_label, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	if _missions_coin_bar:
		_missions_coin_bar.scale = Vector2.ONE
		var tc := create_tween()
		tc.tween_property(_missions_coin_bar, "scale", Vector2(1.12, 1.12), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tc.tween_property(_missions_coin_bar, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)


func _has_completed_missions() -> bool:
	for arr in [missions.missions, missions.weekly]:
		for m in arr:
			if not m["claimed"] and missions.is_complete(m):
				return true
	return false

func _update_mission_badges() -> void:
	if _nav_badge:
		_nav_badge.visible = _has_completed_missions()

func _apply_nav_badge_pos() -> void:
	if _nav_badge:
		# quando la pagina missioni è attiva il tab si alza: il badge lo segue
		var up := _nav_badge_raise if _tab == "missions" else 0.0
		_nav_badge.position = _nav_badge_base - Vector2(0, up)


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
	# sfondo navy a tutta larghezza: riempie i lati su schermi larghi (iPad/tablet)
	_nav_bg = ColorRect.new()
	_nav_bg.color = Color(8.0 / 255.0, 5.0 / 255.0, 56.0 / 255.0, 1.0)
	_nav_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_nav_bg)
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
	# badge "missioni completate" (sopra il tab missioni)
	_nav_badge = TextureRect.new()
	_nav_badge.texture = load("res://CORE/Assets/Art/UI/Missions/mission_done_badge.png")
	_nav_badge.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_nav_badge.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_nav_badge.stretch_mode = TextureRect.STRETCH_SCALE
	_nav_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_nav_badge.visible = false
	layer.add_child(_nav_badge)
	_update_mission_badges()


func _select_tab(tab: String, feedback: bool = true) -> void:
	if feedback:
		settings.button_feedback()
	_tab = tab
	_apply_nav_badge_pos()
	if _leader_menu:
		_leader_menu.visible = false
	if _nav_bar:
		_nav_bar.texture = _nav_textures.get(tab, _nav_textures["home"])
	if _missions_menu:
		_missions_menu.visible = false
	if _shop_menu:
		_shop_menu.visible = false
	if _deck_menu:
		_deck_menu.visible = false
	if _leader_menu:
		_leader_menu.visible = false
	_update_coin_count()
	_set_home_visible(tab == "home")
	if tab == "missions":
		missions._maybe_refresh()
		_populate_missions()
		_missions_menu.visible = true
	elif tab == "shop":
		_shop_menu.visible = true


func _set_home_visible(v: bool) -> void:
	for n in [_cabinet, _play_base, _deck_sprite, _sparkles,
			_arrow_l_base, _arrow_l_pressed, _arrow_r_base, _arrow_r_pressed,
			_arrow_l_sparkles, _arrow_r_sparkles, _screen_anim, _screen_title, _mode_screen]:
		if n:
			n.visible = v
	if _play_pressed:
		_play_pressed.visible = false
	# i frame "schiacciati" delle frecce restano nascosti (mostrati solo durante la pressione)
	if _arrow_l_pressed:
		_arrow_l_pressed.visible = false
	if _arrow_r_pressed:
		_arrow_r_pressed.visible = false
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
