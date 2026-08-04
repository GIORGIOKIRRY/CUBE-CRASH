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
var _play_base_scale := Vector2.ONE          # scala base del tasto play (per il rimbalzo)
var _play_bounce_tween: Tween                 # rimbalzo periodico "invito a giocare"
var _deck_base_pos := Vector2.ZERO

# Barra in alto a destra: coin count + classifica + impostazioni
var _coin_bar: TextureRect
var _record_bar: TextureRect
var _coin_count_label: Label
var _leader_btn: TextureButton
var _news_btn: TextureButton
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
const PROFILE_ICONS := [   # icone profilo selezionabili
	"res://CORE/Assets/Art/Home/Profile/profile_blue.png",
	"res://CORE/Assets/Art/Home/Profile/profile_red.png",
	"res://CORE/Assets/Art/Home/Profile/profile_green.png",
	"res://CORE/Assets/Art/Home/Profile/profile_fire.png",
	"res://CORE/Assets/Art/Home/Profile/profile_trophy.png",
	"res://CORE/Assets/Art/Home/Profile/profile_cupgold.png",
	"res://CORE/Assets/Art/Home/Profile/profile_cupgreen.png",
	"res://CORE/Assets/Art/Home/Profile/profile_creator.png",
	"res://CORE/Assets/Art/Home/Profile/profile_beta.png",
]
# icone SBLOCCABILI dalle missioni mensili: indice in PROFILE_ICONS -> id sblocco.
# Se non sbloccata: mostrata in bianco/nero e NON selezionabile.
# "creator" NON viene dalle missioni: si sblocca da remoto quando l'admin
# approva la richiesta Creator (vedi _fetch_creator_approval).
const PROFILE_ICON_LOCK := {3: "fire", 4: "trophy", 5: "cupgold", 6: "cupgreen", 7: "creator", 8: "beta"}
const CREATOR_BIN_URL := "https://api.npoint.io/d307da3a533b2dd1bafa"
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
var _screen_fx: AnimatedSprite2D            # overlay effetti schermo (TV on / cambio modalità)
var _modesel_frames: SpriteFrames = null    # frame flash cambio modalità (cache)
const SCREEN_FX_TEX_W := 512.0              # larghezza texture degli overlay fx
var _mode_titles := {}                      # mode -> Texture2D (scritta a schermo)

# Missioni (tastino TEMPORANEO + pannello, design provvisorio)
var _missions_button: Button
var _coin_label: Label
var _missions_menu: Control
var _missions_list: VBoxContainer
var _missions_scroll: ScrollContainer
var _missions_coins_label: Label
var _missions_coin_bar: TextureRect
var _missions_record_label: Label
var _missions_record_bar: TextureRect
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
var _shop_coins_label: Label

var _art_pos := CAMERA_CENTER


var _intro_pending_music := false   # true finché l'intro TV-on non fa partire la musica

func _ready() -> void:
	# alla PRIMA apertura la musica parte a fine intro TV-on; al ritorno in home subito
	if settings.home_intro_played:
		settings.play_music(music_player.stream)
	# Android 13+: chiede il permesso notifiche (iOS lo gestisce il file nativo CCNotify)
	if OS.get_name() == "Android":
		OS.request_permission("android.permission.POST_NOTIFICATIONS")
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
	_apply_press_fx_all(self)    # affondamento + vibrazione su tutti i tasti restanti
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
	# contatori missioni allineati 1:1 alla HOME. I contatori della home sono nel canvas della
	# Camera2D (traslati), i missioni su CanvasLayer: applico la STESSA traslazione camera (x e y),
	# così combaciano su ogni schermo (iPhone alti e iPad larghi). Zoom camera = 1.
	var cam_dx := view_size.x * 0.5 - CAMERA_CENTER.x
	var cam_dy := view_size.y * 0.5 - CAMERA_CENTER.y
	if _missions_coin_bar:
		_missions_coin_bar.position = Vector2(COIN_X + cam_dx, COUNTER_Y + cam_dy)
	if _missions_coins_label:
		_missions_coins_label.position = Vector2(COIN_X + COIN_W * COIN_ICON_FRAC + cam_dx, COUNTER_Y + cam_dy)
	if _missions_record_bar:
		# la label è figlia della barra: si sposta insieme, basta muovere la barra
		_missions_record_bar.position = Vector2(RECORD_X + cam_dx, COUNTER_Y + cam_dy)

	# zona missioni: tab full-width -> pannello scuro -> timer -> lista clippata
	if _missions_tabs:
		# frame missioni SEMPRE subito sotto i contatori (record/monete): segue la stessa
		# traslazione camera dei contatori -> non si sovrappone su nessun dispositivo.
		var tabs_y := COUNTER_Y + (view_size.y * 0.5 - CAMERA_CENTER.y) + 82.0
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
	# nuovo sfondo home a schermo pieno: nascondi i riempimenti blu della scena
	var sky := get_node_or_null("SkyBG")
	if sky:
		sky.visible = false
	var floor_bg := get_node_or_null("FloorBG")
	if floor_bg:
		floor_bg.visible = false

	# Sfondo home (vignetta) su CanvasLayer DIETRO al contenuto (layer -2 < 0), riempie lo schermo
	var bg_layer := CanvasLayer.new()
	bg_layer.layer = -2
	add_child(bg_layer)
	var bg_rect := TextureRect.new()
	bg_rect.texture = load("res://CORE/Assets/Art/Home/home_bg.png")
	bg_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	bg_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg_layer.add_child(bg_rect)

	_background = Sprite2D.new()
	_background.texture = load("res://CORE/Assets/Art/Home/background.png")
	_background.z_index = -4
	_background.visible = false   # backdrop art nascosto (usiamo lo sfondo su CanvasLayer)
	add_child(_background)

	# Cabinato STATICO (immagine unica, niente animazione)
	_cabinet = Sprite2D.new()
	_cabinet.texture = load("res://CORE/Assets/Art/Home/cabinet_static.png")
	_cabinet.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_cabinet.z_index = -2
	add_child(_cabinet)

	# Ombra AGGANCIATA al cabinato: figlia del cabinato, DIETRO di esso (show_behind_parent),
	# centrata e in scala col canvas art (stessa cornice, texture a risoluzione maggiore).
	_home_shadow = Sprite2D.new()
	_home_shadow.texture = load("res://CORE/Assets/Art/Home/cabinet_shadow.png")
	_home_shadow.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_home_shadow.show_behind_parent = true
	var shsc := ART_SIZE.x / _home_shadow.texture.get_size().x   # texture -> canvas art (locale al cabinato)
	_home_shadow.scale = Vector2(shsc, shsc)
	_cabinet.add_child(_home_shadow)


# --- Tasto PLAY + scintille ----------------------------------------------------
func _build_play_button() -> void:
	# Scintille bianche "sbrilluccicose" dietro il tasto.
	_sparkles = _make_sparkles(26.0, 46, 45.0, 105.0, 2.5, 4.5)

	# Tasto PLAY (nuova grafica), centrato. Input a mano in _input().
	_play_base = Sprite2D.new()
	_play_base.texture = load("res://CORE/Assets/Art/Home/tasto_play_r.png")
	_play_base.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_play_base.z_index = 0
	add_child(_play_base)
	# (Cube Deck rimosso)

	# rimbalzo periodico del tasto PLAY per invitare a giocare
	var bt := Timer.new()
	bt.wait_time = 5.0
	bt.one_shot = false
	bt.autostart = true
	add_child(bt)
	bt.timeout.connect(_play_bounce)


# Fa "rimbalzare" il tasto PLAY (solo in home, quando non è premuto): piccolo hop + atterraggio molleggiato.
func _play_bounce() -> void:
	if _play_base == null or not _play_base.visible or _play_pressing:
		return
	if _play_bounce_tween != null and _play_bounce_tween.is_valid():
		return
	var bp := _play_base_pos
	var bs := _play_base_scale
	_play_bounce_tween = create_tween()
	_play_bounce_tween.tween_property(_play_base, "position:y", bp.y - 22.0, 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_play_bounce_tween.parallel().tween_property(_play_base, "scale", bs * 1.06, 0.16)
	_play_bounce_tween.tween_property(_play_base, "position:y", bp.y, 0.45).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	_play_bounce_tween.parallel().tween_property(_play_base, "scale", bs, 0.30)


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
	# PLAY da solo, centrato (alzato un po': non troppo vicino alla nav bar)
	var s := (DECK_BTN_H_ART / PLAY_NEW_TEX.y) * ART_SCALE
	var y := DECK_ROW_CENTER_ART.y - 32.0

	_deck_world_size = Vector2.ZERO   # deck rimosso: nessuna hit-area

	_play_base.position = _art_to_world(Vector2(DECK_ROW_CENTER_ART.x, y))
	_play_base.scale = Vector2(s, s)
	_play_base_pos = _play_base.position
	_play_base_scale = Vector2(s, s)
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
	settings.button_feedback()   # suono UI
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

	# overlay effetti schermo (TV on all'avvio, flash al cambio modalità): SOPRA tutto lo schermo
	_screen_fx = AnimatedSprite2D.new()
	_screen_fx.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_screen_fx.z_index = -3
	_screen_fx.centered = true
	_screen_fx.visible = false
	add_child(_screen_fx)

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
	# aggiorna il contatore RECORD in alto alla modalità selezionata
	_refresh_record_counters()
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
	settings.play_tvon()   # cambio modalità: suono TV (oltre al suono UI della freccia)
	# flash "cambio modalità" sullo schermo del cabinato (copre lo stacco); il contenuto
	# viene aggiornato al picco del flash da _play_mode_select_fx().
	_play_mode_select_fx()


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
	# EDIT PROFILE aperto: il tap su "cancella" non deve raggiungere il PLAY dietro
	if _profile_menu and _profile_menu.visible:
		return
	if _missions_menu and _missions_menu.visible:
		return
	if _shop_menu and _shop_menu.visible:
		return
	# blocca PLAY/frecce/deck quando le impostazioni o una sotto-pagina (thanks, ecc.) sono aperte
	var sm := get_node_or_null("%SettingsMenu")
	if sm and sm.visible:
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
	# ferma un eventuale rimbalzo in corso e ripristina la scala base
	if _play_bounce_tween != null and _play_bounce_tween.is_valid():
		_play_bounce_tween.kill()
	_play_base.scale = _play_base_scale
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


# --- DEBUG: 3 tasti TEST per le schermate di fine partita (rimuovere prima release) --
# Ognuno lancia direttamente la relativa schermata: Game Over CLASSIC, Game Over
# SPEEDRUN, NUOVO RECORD (con coriandoli). Da rimuovere prima della release.
func _build_test_gameover_button() -> void:
	var specs := [
		{"t": "GO CLASSIC", "mode": "mode_c", "kind": "classic", "col": Color(0.2, 0.6, 1.0)},
		{"t": "GO SPEED", "mode": "speedrun", "kind": "speedrun", "col": Color(1.0, 0.35, 0.2)},
		{"t": "NEW RECORD", "mode": "speedrun", "kind": "record", "col": Color(0.7, 0.3, 1.0)},
	]
	# riga orizzontale in basso (spazio design, non copre nome/griglia)
	var x := 8.0
	for s in specs:
		var b := Button.new()
		b.text = s["t"]
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_font_override("font", MODE_FONT)
		b.add_theme_font_size_override("font_size", 17)
		b.add_theme_color_override("font_color", Color(1, 1, 1))
		var sb := StyleBoxFlat.new()
		sb.bg_color = s["col"]
		sb.set_corner_radius_all(6)
		b.add_theme_stylebox_override("normal", sb)
		b.add_theme_stylebox_override("hover", sb)
		b.add_theme_stylebox_override("pressed", sb)
		b.position = Vector2(x, 172.0)   # riga sotto al frame nome (zona vuota), cliccabile
		b.size = Vector2(180.0, 40.0)
		b.z_index = 500
		b.modulate = Color(1, 1, 1, 0.94)
		b.pressed.connect(_on_test_gameover_pressed.bind(str(s["mode"]), str(s["kind"])))
		add_child(b)
		x += 184.0

func _on_test_gameover_pressed(mode: String, kind: String) -> void:
	settings.button_feedback()
	# istanzia DIRETTAMENTE la schermata di fine partita con i parametri giusti,
	# così ogni tasto mostra in modo affidabile la sua grafica (classic/speedrun/record).
	var scene: PackedScene = load("res://CORE/Scene/game_over_screen.tscn")
	var go: Control = scene.instantiate()
	var lay := CanvasLayer.new()
	lay.layer = 300
	add_child(lay)
	lay.add_child(go)
	go.set_anchors_preset(Control.PRESET_FULL_RECT)
	var is_rec := kind == "record"
	var sc := go.get_node_or_null("Items/L_ScoreNumber") as Label
	if sc:
		sc.text = "215420" if is_rec else "32030"
	var bs := go.get_node_or_null("Items/L_BestScoreNumber") as Label
	if bs:
		bs.text = "180000"
	if go.has_method("set_end_bonus"):
		go.set_end_bonus(215420 if is_rec else 32030, 0, 100)
	if go.has_method("set_session_stats"):
		go.set_session_stats("5:43  ·  26 pose  ·  32030 pt")
	if go.has_method("show_result"):
		go.show_result(is_rec)
	if mode == "speedrun" and not is_rec and go.has_method("set_speedrun_mode"):
		go.set_speedrun_mode(180000, false)
	if go.has_method("set_mode_tag"):
		go.set_mode_tag(mode)
	if is_rec and go.has_method("play_confetti"):
		go.play_confetti()


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
# ---- Contatori in alto: MONETE a destra (coin_count) + RECORD a sinistra (record_count) ----
const COUNTER_H := 44.0
const COIN_W := 161.0            # 44 * 704/192
const RECORD_W := 272.0          # 44 * 1188/192
const COIN_X := 391.0            # destra (552 - 161)
const RECORD_X := 20.0           # sinistra
const COUNTER_Y := 4.0
const COIN_ICON_FRAC := 0.28
const RECORD_ICON_FRAC := 0.17
const COIN_TEX := "res://CORE/Assets/Art/UI/Menu/coin_count.png"
const RECORD_TEX := "res://CORE/Assets/Art/UI/Menu/record_count.png"
var _record_labels: Array = []

# UN SOLO contatore RECORD alla volta: mostra il record della MODALITÀ SELEZIONATA
# (Classic = trofeo, Speedrun = trofeo+fiamma), a dimensione piena (non stracciato).
const REC_CLASSIC_TEX := "res://CORE/Assets/Art/Home/counter_record_classic.png"
const REC_SR_TEX := "res://CORE/Assets/Art/Home/counter_record_speedrun.png"
const REC_CLASSIC_ICON_FRAC := 0.20
const REC_SR_ICON_FRAC := 0.22
const REC_CLASSIC_W := 44.0 * 1156.0 / 192.0    # aspetto naturale a h=44
const REC_SR_W := 44.0 * 1156.0 / 192.0
var _record_bars: Array = []     # tutte le barre record (home/missioni/shop)

# Crea un contatore (frame + numero centrato nella zona scura). Ritorna [bar, label].
func _make_counter(parent: Node, tex_path: String, x: float, y: float, w: float, icon_frac: float, font_size: int = 26) -> Array:
	var bar := TextureRect.new()
	bar.texture = load(tex_path)
	bar.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	bar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bar.stretch_mode = TextureRect.STRETCH_SCALE
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.position = Vector2(x, y)
	bar.size = Vector2(w, COUNTER_H)
	parent.add_child(bar)
	var lbl := Label.new()
	lbl.add_theme_font_override("font", MODE_FONT)
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", Color(1, 1, 1))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.position = Vector2(x + w * icon_frac, y)
	lbl.size = Vector2(w * (1.0 - icon_frac), COUNTER_H)
	parent.add_child(lbl)
	return [bar, lbl]

# Contatore record (label FIGLIA della barra, così segue la barra quando si sposta).
# La texture/valore vengono impostati da _refresh_record_counters() in base alla modalità.
func _make_record_counter(parent: Node, x: float) -> Array:
	var bar := TextureRect.new()
	bar.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	bar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bar.stretch_mode = TextureRect.STRETCH_SCALE
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.position = Vector2(x, COUNTER_Y)
	bar.size = Vector2(REC_CLASSIC_W, COUNTER_H)
	parent.add_child(bar)
	var lbl := Label.new()
	lbl.add_theme_font_override("font", MODE_FONT)
	lbl.add_theme_font_size_override("font_size", 26)   # come le monete
	lbl.add_theme_color_override("font_color", Color(1, 1, 1))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(lbl)   # figlia della barra
	_record_bars.append(bar)
	_record_labels.append(lbl)
	_refresh_record_counters()
	return [bar, lbl]

# Aggiorna TUTTI i contatori record alla modalità attualmente selezionata.
func _refresh_record_counters() -> void:
	var is_sr: bool = MODES[_mode_index]["mode"] == "speedrun"
	var tex := load(REC_SR_TEX if is_sr else REC_CLASSIC_TEX)
	var w: float = REC_SR_W if is_sr else REC_CLASSIC_W
	var frac: float = REC_SR_ICON_FRAC if is_sr else REC_CLASSIC_ICON_FRAC
	var val := _fmt_score(_player_score("speedrun" if is_sr else "classic"))
	for i in _record_bars.size():
		var bar: TextureRect = _record_bars[i]
		if not is_instance_valid(bar):
			continue
		bar.texture = tex
		bar.size = Vector2(w, COUNTER_H)
		var lbl: Label = _record_labels[i]
		if is_instance_valid(lbl):
			lbl.position = Vector2(w * frac, 0.0)
			lbl.size = Vector2(w * (1.0 - frac), COUNTER_H)
			lbl.text = val

# compat: aggiornamento valori record -> ora è un refresh completo
func _update_record_labels() -> void:
	_refresh_record_counters()

func _build_top_right() -> void:
	# MONETE a destra
	var cc := _make_counter(self, COIN_TEX, COIN_X, COUNTER_Y, COIN_W, COIN_ICON_FRAC)
	_coin_bar = cc[0] as TextureRect
	_coin_count_label = cc[1] as Label
	# RECORD a sinistra: UN solo contatore, in base alla modalità selezionata
	var rc := _make_record_counter(self, RECORD_X)
	_record_bar = rc[0] as TextureRect
	_update_coin_count()
	_refresh_record_counters()

	# CLASSIFICA (trofeo) — spostata a sinistra per far posto al tasto NEWS
	_leader_btn = _make_icon_button("res://CORE/Assets/Art/UI/Menu/leaderboard.png", Vector2(302.0, 74.0), 78.0)
	_leader_btn.pressed.connect(_on_leaderboard_pressed)
	# NEWS/RINGRAZIAMENTI (tra classifica e impostazioni) -> apre la schermata thanks
	_news_btn = _make_icon_button("res://CORE/Assets/Art/UI/Menu/news_icon.png", Vector2(388.0, 74.0), 78.0)
	_news_btn.pressed.connect(_on_news_pressed)
	# IMPOSTAZIONI (nuova icona)
	_settings_btn2 = _make_icon_button("res://CORE/Assets/Art/UI/Menu/settings_new.png", Vector2(474.0, 74.0), 78.0)
	_settings_btn2.pressed.connect(_on_settings_button_pressed)

	_build_test_gameover_button()

	# PROFILE PICTURE a SINISTRA (mostra l'icona scelta; tap -> schermata EDIT PROFILE)
	_load_player_name()
	# controlla da remoto se questo giocatore è stato approvato come Creator
	_fetch_creator_approval()
	# scarica la lista OG supporters (per il tag dorato [OG] accanto al nome)
	_fetch_og_supporters()
	# invia SUBITO all'avvio i propri migliori punteggi (classic + speedrun) online:
	# così la classifica speedrun si popola anche per chi non apre quella scheda o
	# gioca da build vecchie che inviavano il punteggio solo a fine partita.
	leaderboard.submit_best("classic", _player_score("classic"))
	leaderboard.submit_best("speedrun", _player_score("speedrun"))
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
	pbtn.set_meta("pfx", true)
	pbtn.pressed.connect(_open_profile)
	_profile_pic_base = _profile_pic.position
	pbtn.button_down.connect(func() -> void:
		_profile_pic.position = _profile_pic_base + Vector2(0, PRESS_SINK)
		_profile_pic.modulate = Color(0.85, 0.85, 0.85)
		settings.vibrate(15)
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

	# anche il FRAME NOME apre il profilo (stesso affondamento di pic+frame).
	# Bottone-overlay figlio diretto del menu, sopra frame e nome (z_index alto), così
	# riceve sempre il tocco (il frame ha mouse_filter IGNORE).
	var nbtn := Button.new()
	nbtn.focus_mode = Control.FOCUS_NONE
	var nbe := StyleBoxEmpty.new()
	nbtn.add_theme_stylebox_override("normal", nbe)
	nbtn.add_theme_stylebox_override("hover", nbe)
	nbtn.add_theme_stylebox_override("pressed", nbe)
	nbtn.add_theme_stylebox_override("focus", nbe)
	nbtn.position = _name_frame.position
	nbtn.size = _name_frame.size
	nbtn.z_index = 5
	nbtn.set_meta("pfx", true)
	nbtn.pressed.connect(_open_profile)
	nbtn.button_down.connect(func() -> void:
		_profile_pic.position = _profile_pic_base + Vector2(0, PRESS_SINK)
		_profile_pic.modulate = Color(0.85, 0.85, 0.85)
		settings.vibrate(15)
		_name_frame.position = _name_frame_base + Vector2(0, PRESS_SINK)
		if _name_edit:
			_name_edit.position = _name_edit_base + Vector2(0, PRESS_SINK))
	nbtn.button_up.connect(func() -> void:
		_profile_pic.position = _profile_pic_base
		_profile_pic.modulate = Color(1, 1, 1)
		_name_frame.position = _name_frame_base
		if _name_edit:
			_name_edit.position = _name_edit_base)
	add_child(nbtn)

	# nome in SOLA LETTURA (si modifica solo in EDIT PROFILE), allineato a sinistra, più grande
	_name_edit = LineEdit.new()
	_name_edit.text = _player_name
	_name_edit.max_length = 12
	_name_edit.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_name_edit.editable = false
	_name_edit.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_name_edit.add_theme_font_override("font", MODE_FONT)
	_name_edit.add_theme_font_size_override("font_size", 30)
	_name_edit.add_theme_color_override("font_color", Color(1, 1, 1))
	_name_edit.add_theme_color_override("font_uneditable_color", Color(1, 1, 1))
	var empty := StyleBoxEmpty.new()
	_name_edit.add_theme_stylebox_override("normal", empty)
	_name_edit.add_theme_stylebox_override("read_only", empty)
	# nome in ALTO (dopo l'icona), allineato a sinistra; i tag vanno SOTTO (vicini)
	_name_edit.position = _name_frame.position + Vector2(nf_w * 0.14, nf_h * 0.01)
	_name_edit.size = Vector2(nf_w * 0.84, nf_h * 0.52)
	_name_edit_base = _name_edit.position
	add_child(_name_edit)
	# se il fetch Creator è già arrivato, applica subito il nome verde brillante
	_apply_creator_name_style()
	# se il fetch OG è già arrivato, applica subito il tag [OG] dorato
	_apply_name_tags()


func _current_profile_icon_path() -> String:
	var i := clampi(_profile_icon_index, 0, PROFILE_ICONS.size() - 1)
	return PROFILE_ICONS[i]

# Nome di default "PLAYER"+cifre casuali, generato una volta e salvato:
# evita che in classifica online ci siano tanti "PLAYER" identici.
func _default_player_name() -> String:
	var cfg := ConfigFile.new()
	cfg.load(PROFILE_CFG)
	var d := str(cfg.get_value("profile", "default_name", ""))
	if d.is_empty():
		randomize()
		d = "PLAYER%04d" % randi_range(0, 9999)
		cfg.set_value("profile", "default_name", d)
		cfg.save(PROFILE_CFG)
	return d

func _load_player_name() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PROFILE_CFG) == OK:
		_player_name = str(cfg.get_value("profile", "name", ""))
		_profile_icon_index = int(cfg.get_value("profile", "icon", 0))
	if _player_name.strip_edges().is_empty() or _player_name == "PLAYER":
		_player_name = _default_player_name()
	_profile_icon_index = clampi(_profile_icon_index, 0, PROFILE_ICONS.size() - 1)
	_profile_sel_index = _profile_icon_index

func _save_player_name() -> void:
	if _name_edit:
		var n := _name_edit.text.strip_edges()
		if n == "":
			n = _default_player_name()
			_name_edit.text = n
		_player_name = n
	_write_profile_cfg()

func _write_profile_cfg() -> void:
	var cfg := ConfigFile.new()
	# non sovrascrivere le altre chiavi (es. lb_id della classifica online)
	cfg.load(PROFILE_CFG)
	cfg.set_value("profile", "name", _player_name)
	cfg.set_value("profile", "icon", _profile_icon_index)
	cfg.save(PROFILE_CFG)
	# aggiorna nome/icona anche sulla classifica online
	leaderboard.submit_best("classic", _player_score("classic"))
	leaderboard.submit_best("speedrun", _player_score("speedrun"))


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
	b.set_meta("pfx", true)
	b.button_down.connect(func() -> void:
		b.position.y += PRESS_SINK
		b.modulate = Color(0.85, 0.85, 0.85)
		settings.vibrate(15))
	b.button_up.connect(func() -> void:
		b.position.y -= PRESS_SINK
		b.modulate = Color(1, 1, 1))


# Applica affondamento + vibrazione a TUTTI i BaseButton discendenti che non hanno già
# un feedback dedicato (meta "pfx"). Usato per coprire nav bar, menu modi, shop, ecc.
func _apply_press_fx_all(node: Node) -> void:
	for c in node.get_children():
		if c is BaseButton and not c.has_meta("pfx"):
			var b := c as BaseButton
			b.set_meta("pfx", true)
			b.button_down.connect(func() -> void:
				b.position.y += PRESS_SINK
				settings.vibrate(15))
			b.button_up.connect(func() -> void:
				b.position.y -= PRESS_SINK)
		_apply_press_fx_all(c)

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
	# tap nella zona nera attorno al frame -> esci dall'edit profile (come CANCELLA)
	dim.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed:
			_close_profile())
	_profile_menu.add_child(dim)
	_profile_frame = Control.new()
	_profile_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_profile_menu.add_child(_profile_frame)
	_profile_bg = _ptex(PROFILE_DIR + "frame_bg.png")
	_profile_bg.mouse_filter = Control.MOUSE_FILTER_STOP   # i tap sul frame NON chiudono
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
		# icone bloccate: mostra la versione B/N finché non sono sbloccate
		var locked := _is_profile_icon_locked(i)
		var tex_path: String = _profile_icon_bw(i) if locked else PROFILE_ICONS[i]
		var b := _ptbtn(tex_path, _select_profile_icon.bind(i))
		b.disabled = locked   # bloccata: non cliccabile
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
	_profile_edit_btn.position = Vector2(nb_x + nb_w - eb_s * 0.30, row_cy - eb_s * 0.5)   # un po' più a destra
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
	var bw := fw * 0.42
	var bh := bw * 576.0 / 1472.0   # aspect nuovi tasti (1472x576)
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

# icona profilo bloccata? (missione mensile non ancora riscossa)
# --- Sblocco icona Creator (approvazione remota via admin) ---------------------
var _creator_http: HTTPRequest = null
var _creator_names: Dictionary = {}   # nome (minuscolo) -> true per i Creator approvati

func _fetch_creator_approval() -> void:
	if _creator_http == null:
		_creator_http = HTTPRequest.new()
		add_child(_creator_http)
		_creator_http.request_completed.connect(_on_creator_approval)
	if _creator_http.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		return
	_creator_http.request(CREATOR_BIN_URL)

func _on_creator_approval(_result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if code != 200:
		return
	var data: Variant = JSON.parse_string(body.get_string_from_utf8())
	if typeof(data) != TYPE_DICTIONARY or not data.has("creator_approved"):
		return
	var approved: Array = data["creator_approved"]
	_creator_names.clear()
	for n in approved:
		var s := str(n).strip_edges().to_lower()
		if s != "":
			_creator_names[s] = true
	# se questo giocatore è approvato: sblocca l'icona + nome verde brillante + tag [CC]
	if _is_creator(_player_name):
		if missions.unlock_icon("creator") and _profile_icon_btns.size() > 0:
			_update_profile_selection()
		_apply_creator_name_style()
	_apply_name_tags()

func _is_creator(name: String) -> bool:
	return bool(_creator_names.get(name.strip_edges().to_lower(), false))

# --- OG Supporters: tag dorato [OG] accanto al nome -----------------------------
const OG_BIN_URL := "https://api.npoint.io/c0e50f85707a48094b11"
var _og_http: HTTPRequest = null
var _og_names: Dictionary = {}   # nome (minuscolo) -> true per gli OG supporters

func _fetch_og_supporters() -> void:
	if _og_http == null:
		_og_http = HTTPRequest.new()
		add_child(_og_http)
		_og_http.request_completed.connect(_on_og_fetched)
	if _og_http.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		return
	_og_http.request(OG_BIN_URL)

func _on_og_fetched(_result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if code != 200:
		return
	var data: Variant = JSON.parse_string(body.get_string_from_utf8())
	if typeof(data) != TYPE_DICTIONARY or not data.has("og_supporters"):
		return
	var arr: Array = data["og_supporters"]
	_og_names.clear()
	for n in arr:
		var s := str(n).strip_edges().to_lower()
		if s != "":
			_og_names[s] = true
	# aggiorna il tag [OG] sul nome in home (se questo giocatore è un OG)
	_apply_name_tags()

func _is_og(name: String) -> bool:
	return bool(_og_names.get(name.strip_edges().to_lower(), false))

# Etichetta dorata "[OG]" (stile oro con contorno scuro)
func _make_tag(txt: String, col: Color, size: int) -> Label:
	var l := Label.new()
	l.text = txt
	l.add_theme_font_override("font", MODE_FONT)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("outline_size", 5)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

# Tag del profilo in HOME, come piccoli badge in ALTO A DESTRA del frame nome
# (uno dopo l'altro). [CC] = Creator (verde), [OG] = OG supporter (oro).
# Il nome resta CENTRATO a dimensione piena.
var _name_tags: Array = []
func _apply_name_tags() -> void:
	for t in _name_tags:
		if is_instance_valid(t):
			t.queue_free()
	_name_tags.clear()
	if not is_instance_valid(_name_edit) or not is_instance_valid(_name_frame):
		return
	_name_edit.add_theme_font_size_override("font_size", 30)   # nome pieno, centrato
	var specs: Array = []
	if _is_og(_player_name):
		specs.append({"t": "[OG]", "c": Color(1.0, 0.82, 0.15)})   # oro
	if _is_creator(_player_name):
		specs.append({"t": "[CC]", "c": Color(0.30, 1.0, 0.38)})   # verde
	if specs.is_empty():
		return
	# tag SOTTO il nome, in fila partendo da SINISTRA (allineati col nome)
	var tag_font := 18
	var gap := 4.0
	var x := _name_frame.size.x * 0.15
	var y := _name_frame.size.y * 0.46
	for s in specs:
		var w: float = MODE_FONT.get_string_size(s["t"], HORIZONTAL_ALIGNMENT_LEFT, -1, tag_font).x + 4.0
		var lbl := _make_tag(s["t"], s["c"], tag_font)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		lbl.position = Vector2(x, y)
		lbl.size = Vector2(w, _name_frame.size.y * 0.40)
		_name_frame.add_child(lbl)   # figlio del frame: segue l'affondamento alla pressione
		_name_tags.append(lbl)
		x += w + gap

# Applica al nome nella home l'effetto verde "sbrilluccicato" (se sei un Creator)
func _apply_creator_name_style() -> void:
	if is_instance_valid(_name_edit) and _is_creator(_player_name):
		_shimmer_name(_name_edit, ["font_color", "font_uneditable_color"])

# Colore verde con luccichio animato su una Label / LineEdit
func _shimmer_name(item: Control, keys: Array) -> void:
	if item == null:
		return
	if item.is_inside_tree():
		_run_shimmer(item, keys)
	else:
		item.tree_entered.connect(_run_shimmer.bind(item, keys), CONNECT_ONE_SHOT)

func _run_shimmer(item: Control, keys: Array) -> void:
	if not is_instance_valid(item):
		return
	var green := Color(0.28, 1.0, 0.36)
	var pale := Color(0.80, 1.0, 0.85)
	for k in keys:
		item.add_theme_color_override(k, green)
	item.add_theme_color_override("font_outline_color", Color(0.0, 0.22, 0.05))
	item.add_theme_constant_override("outline_size", 5)
	var setc := func(c: Color) -> void:
		if is_instance_valid(item):
			for k in keys:
				item.add_theme_color_override(k, c)
	var tw := item.create_tween().set_loops()
	tw.tween_method(setc, green, pale, 0.75).set_trans(Tween.TRANS_SINE)
	tw.tween_method(setc, pale, green, 0.75).set_trans(Tween.TRANS_SINE)

func _is_profile_icon_locked(i: int) -> bool:
	if not PROFILE_ICON_LOCK.has(i):
		return false
	return not missions.is_icon_unlocked(str(PROFILE_ICON_LOCK[i]))

func _profile_icon_bw(i: int) -> String:
	return PROFILE_ICONS[i].replace(".png", "_bw.png")

func _select_profile_icon(i: int) -> void:
	if _is_profile_icon_locked(i):
		# bloccata: non selezionabile finché non completi la missione mensile
		settings.vibrate(20)
		return
	settings.button_feedback()
	_profile_sel_index = i
	_update_profile_selection()

func _update_profile_selection() -> void:
	for k in _profile_icon_btns.size():
		var b: TextureButton = _profile_icon_btns[k]
		var locked := _is_profile_icon_locked(k)
		# aggiorna la texture: B/N se bloccata, a colori se (nel frattempo) sbloccata
		b.texture_normal = load(_profile_icon_bw(k) if locked else PROFILE_ICONS[k])
		b.disabled = locked   # bloccata: non cliccabile
		if locked:
			b.modulate = Color(0.6, 0.6, 0.6)   # bloccata: spenta
		else:
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
		n = _default_player_name()
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
	# animazione pressione: si abbassa leggermente + scurisce + vibra
	b.set_meta("pfx", true)
	var base := pos
	b.button_down.connect(func() -> void:
		b.position = base + Vector2(0, PRESS_SINK)
		b.modulate = Color(0.85, 0.85, 0.85)
		settings.vibrate(15))
	b.button_up.connect(func() -> void:
		b.position = base
		b.modulate = Color(1, 1, 1))
	return b


func _update_coin_count() -> void:
	var c := str(missions.coins)
	if _coin_count_label:
		_coin_count_label.text = c
	if _missions_coins_label:
		_missions_coins_label.text = c
	if _shop_coins_label:
		_shop_coins_label.text = c

# Forza i contatori a un valore preciso (usato per tenere il vecchio totale
# finché le monete volanti non arrivano nel contatore).
func _set_coin_display(v: int) -> void:
	var c := str(v)
	if _coin_count_label:
		_coin_count_label.text = c
	if _missions_coins_label:
		_missions_coins_label.text = c
	if _shop_coins_label:
		_shop_coins_label.text = c
	if _coin_label:
		_coin_label.text = "%d monete" % v


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

var _leader_req := 0   # scarta le risposte in ritardo (cambio tab durante il fetch)

func _populate_leader() -> void:
	if not _leader_list:
		return
	if _leader_tabs:
		_leader_tabs.texture = load(LB_DIR + ("tabs_classic.png" if _leader_tab == "classic" else "tabs_speedrun.png"))
	_leader_timer.text = _leader_refresh_text()
	_leader_req += 1
	var req := _leader_req
	var mode := _leader_tab
	# invia SEMPRE il proprio miglior punteggio online prima di leggere la classifica,
	# così la posizione è aggiornata (prima si inviava solo al salvataggio profilo).
	leaderboard.submit_best(mode, _player_score(mode))
	# Classifica reale da Firebase (solo giocatori veri, niente bot).
	var entries: Array = await leaderboard.fetch_top(mode)
	if req != _leader_req or not is_instance_valid(_leader_list):
		return   # nel frattempo l'utente ha cambiato tab / riaperto
	if entries.is_empty():
		# offline o settimana appena iniziata: almeno la propria riga
		var pscore := _player_score(mode)
		if pscore > 0:
			entries = [{"name": _player_name, "score": pscore, "icon": _profile_icon_index, "is_player": true, "rank": 1}]
	else:
		entries = _rank_real_entries(entries, mode)
	for c in _leader_list.get_children():
		c.queue_free()
	# padding in alto
	var head := Control.new()
	head.custom_minimum_size = Vector2(0, 20)
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_leader_list.add_child(head)
	for e in entries:
		_leader_list.add_child(_make_leader_row(e))
	var tail := Control.new()
	tail.custom_minimum_size = Vector2(0, 180)
	tail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_leader_list.add_child(tail)

# Rank alle voci reali + riga "100+" se il giocatore è fuori dalla top 100
func _rank_real_entries(entries: Array, mode: String) -> Array:
	var pscore := _player_score(mode)
	var has_player := false
	for e in entries:
		if e.get("is_player", false):
			has_player = true
			break
	if not has_player and pscore > 0:
		# se il punteggio del giocatore rientrerebbe nella top 100 (o la lista non è piena),
		# lo INSERISCO alla posizione GIUSTA per punteggio; solo se è davvero fuori mostro "100+".
		var lowest: int = int(entries[-1]["score"]) if entries.size() > 0 else 0
		if entries.size() < 100 or pscore > lowest:
			entries.append({"name": _player_name, "score": pscore, "icon": _profile_icon_index, "is_player": true})
			entries.sort_custom(func(a, b): return int(a["score"]) > int(b["score"]))
		else:
			for i in entries.size():
				entries[i]["rank"] = i + 1
			entries.append({"name": _player_name, "score": pscore, "icon": _profile_icon_index, "is_player": true, "rank": 0, "rank_text": "100+"})
			return entries
	for i in entries.size():
		entries[i]["rank"] = i + 1
	return entries

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
	# nome (i Creator approvati hanno il nome verde "sbrilluccicato")
	var nm_x := LB_ROW_W * 0.30
	var name_lbl := _lb_label(str(e["name"]), 24, txt_col, Vector2(nm_x, 0), Vector2(LB_ROW_W * 0.34, LB_ROW_H), HORIZONTAL_ALIGNMENT_LEFT)
	row.add_child(name_lbl)
	if _is_creator(str(e["name"])):
		_shimmer_name(name_lbl, ["font_color"])
	# tag [CC]/[OG] ATTACCATI al nome in classifica (uno dopo l'altro)
	var nw := MODE_FONT.get_string_size(str(e["name"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x
	var tx := nm_x + nw + 3.0
	var lb_specs: Array = []
	if _is_creator(str(e["name"])):
		lb_specs.append({"t": "[CC]", "c": Color(0.30, 1.0, 0.38)})
	if _is_og(str(e["name"])):
		lb_specs.append({"t": "[OG]", "c": Color(1.0, 0.82, 0.15)})
	for s in lb_specs:
		var tw := MODE_FONT.get_string_size(s["t"], HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x + 2.0
		var tg := _make_tag(s["t"], s["c"], 18)
		tg.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		tg.position = Vector2(tx, 0)
		tg.size = Vector2(tw, LB_ROW_H)
		row.add_child(tg)
		tx += tw + 2.0
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


# Tasto NEWS (tra classifica e impostazioni): apre la schermata dei ringraziamenti
func _on_news_pressed() -> void:
	settings.button_feedback()
	%SettingsMenu.open_thanks_from_home()


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

	# contatori in alto: MONETE a destra + RECORD a sinistra (posizioni finali in _layout)
	var mcc := _make_counter(_missions_menu, COIN_TEX, COIN_X, COUNTER_Y, COIN_W, COIN_ICON_FRAC)
	_missions_coin_bar = mcc[0] as TextureRect
	_missions_coin_bar.pivot_offset = _missions_coin_bar.size * 0.5
	_missions_coins_label = mcc[1] as Label
	var mrc := _make_record_counter(_missions_menu, RECORD_X)
	_missions_record_bar = mrc[0] as TextureRect
	_missions_record_label = mrc[1] as Label

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
	# nel tab SETTIMANALE: ENTRAMBE le missioni MENSILI (icone) IN ALTO.
	# Restano finché non vengono completate/riscosse (non scadono).
	if is_weekly:
		for j in missions.monthly.size():
			if not missions.monthly[j]["claimed"]:
				_missions_list.add_child(_make_mission_row(j, missions.monthly[j], "monthly"))
	var arr: Array = missions.weekly if is_weekly else missions.missions
	var kind := "weekly" if is_weekly else "daily"
	for i in arr.size():
		if arr[i]["claimed"]:
			continue   # riscosse: spariscono
		_missions_list.add_child(_make_mission_row(i, arr[i], kind))
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
	# icone dedicate per tipo; break_color usa il cubo del colore richiesto
	match m["type"]:
		"score":
			return "res://CORE/Assets/Art/UI/Missions/icon_score.png"
		"break_total":
			return "res://CORE/Assets/Art/UI/Missions/icon_break_total.png"
		"combo":
			return "res://CORE/Assets/Art/UI/Missions/icon_combo.png"
		"play":
			return "res://CORE/Assets/Art/UI/Missions/icon_play.png"
		"break_color":
			return "res://CORE/Assets/Art/UI/Missions/icon_cube_%s.png" % str(m["param"])
		"streak":
			return "res://CORE/Assets/Art/UI/Missions/icon_play.png"   # controller
		"score_classic":
			return "res://CORE/Assets/Art/UI/Missions/icon_score.png"
		"beta":
			return "res://CORE/Assets/Art/Home/Profile/profile_beta.png"
	return "res://CORE/Assets/Art/UI/Missions/icon_cube_red.png"

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

func _make_mission_row(index: int, m: Dictionary, kind: String = "daily") -> Control:
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
	if str(m.get("reward_type", "coins")) == "icon":
		# ricompensa = ICONA profilo sbloccabile
		var ric := rh * 0.58
		var icp := "res://CORE/Assets/Art/Home/Profile/profile_%s.png" % str(m["reward_icon"])
		content.add_child(_miss_tex(icp, Vector2(rx + (rw - ric) * 0.5, ry + rh * 0.34), Vector2(ric, ric), true))
	else:
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
		var prog := _miss_label("%s/%s" % [_fmt_score(int(m["progress"])), _fmt_score(int(m["target"]))], 18, Color(1, 1, 1), Vector2(bx, by), Vector2(bw, bh), HORIZONTAL_ALIGNMENT_CENTER)
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
		btn.pressed.connect(_claim_mission.bind(index, kind, row))
	row.add_child(btn)
	return row


# Animazione ricompensa ICONA: l'icona sbloccata compare grande, rimbalza e si
# ingrandisce (con "È TUA!"), per far capire che ora è del giocatore.
func _play_icon_reward_anim(icon_id: String) -> void:
	var path := "res://CORE/Assets/Art/Home/Profile/profile_%s.png" % icon_id
	if not ResourceLoader.exists(path):
		return
	var lay := CanvasLayer.new()
	lay.layer = 250
	add_child(lay)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	lay.add_child(dim)
	var vp := get_viewport().get_visible_rect().size
	var sz := 280.0
	var icon := TextureRect.new()
	icon.texture = load(path)
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.size = Vector2(sz, sz)
	icon.pivot_offset = Vector2(sz, sz) * 0.5
	var base_pos := Vector2((vp.x - sz) * 0.5, (vp.y - sz) * 0.5 - 30.0)
	icon.position = base_pos
	icon.scale = Vector2(0.1, 0.1)
	lay.add_child(icon)
	var lbl := Label.new()
	lbl.text = "È TUA!"
	lbl.add_theme_font_override("font", MODE_FONT)
	lbl.add_theme_font_size_override("font_size", 56)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.86, 0.15))
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	lbl.add_theme_constant_override("outline_size", 8)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.position = Vector2((vp.x - 400.0) * 0.5, base_pos.y + sz + 6.0)
	lbl.size = Vector2(400.0, 70.0)
	lbl.modulate.a = 0.0
	lay.add_child(lbl)
	var tw := icon.create_tween()
	tw.parallel().tween_property(dim, "color", Color(0, 0, 0, 0.72), 0.2)
	# pop in con rimbalzo
	tw.tween_property(icon, "scale", Vector2(1.2, 1.2), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(icon, "scale", Vector2(1.0, 1.0), 0.14).set_trans(Tween.TRANS_SINE)
	tw.parallel().tween_property(lbl, "modulate:a", 1.0, 0.2)
	# due rimbalzi verticali
	tw.tween_property(icon, "position:y", base_pos.y - 34.0, 0.22).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(icon, "position:y", base_pos.y, 0.30).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tw.tween_property(icon, "position:y", base_pos.y - 16.0, 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(icon, "position:y", base_pos.y, 0.20).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.7)
	tw.parallel().tween_property(icon, "modulate:a", 0.0, 0.4)
	tw.parallel().tween_property(lbl, "modulate:a", 0.0, 0.4)
	tw.parallel().tween_property(dim, "color", Color(0, 0, 0, 0), 0.4)
	tw.tween_callback(lay.queue_free)
	settings.vibrate(40)
	# tap per chiudere subito
	dim.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventScreenTouch and e.pressed and is_instance_valid(lay):
			lay.queue_free())

func _claim_mission(index: int, kind: String = "daily", src: Control = null) -> void:
	# MENSILE: ricompensa = icona profilo sbloccata (niente monete volanti)
	if kind == "monthly":
		var icon_id := missions.claim_monthly(index)
		if icon_id != "":
			settings.play_mission()   # missione completata riscossa
			_populate_missions()
			_update_mission_badges()
			_play_icon_reward_anim(icon_id)   # icona che rimbalza: "ora è tua!"
		return
	var before := missions.coins
	# posizione di partenza delle monete (riga riscattata), prima che _populate_missions la rimuova
	var src_pos := Vector2(288.0, 520.0)
	if is_instance_valid(src):
		src_pos = src.global_position + Vector2(src.size.x * 0.82, src.size.y * 0.5)  # zona ricompensa (destra)
	var got := missions.claim_weekly(index) if kind == "weekly" else missions.claim(index)
	if got > 0:
		settings.play_mission()   # missione completata riscossa
		_populate_missions()   # ricostruisce la lista (rimuove la riga riscattata)
		# NON aggiornare ancora i contatori: il valore cambia SOLO quando le
		# monete volanti arrivano nel contatore (più naturale). Tieni il vecchio valore.
		_set_coin_display(before)
		_fly_coins_to_counter(src_pos, before, missions.coins)


# Monete che volano dalla riga riscattata dentro il contatore in alto a destra.
func _fly_coins_to_counter(src_pos: Vector2, from_v: int, to_v: int) -> void:
	if _missions_coin_bar == null:
		_animate_coin_gain(from_v, to_v)
		return
	var target := _missions_coin_bar.global_position + Vector2(_missions_coin_bar.size.x * 0.13, _missions_coin_bar.size.y * 0.5)
	var layer := CanvasLayer.new()
	layer.layer = 30   # sopra il menu missioni (5) e la nav bar (10)
	add_child(layer)
	var tex: Texture2D = load(MISS + "coin_icon.png")
	var n := 12
	var cs := Vector2(36.0, 36.0)
	for i in n:
		var c := TextureRect.new()
		c.texture = tex
		c.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		c.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		c.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		c.size = cs
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var jitter := Vector2(randf_range(-34.0, 34.0), randf_range(-26.0, 26.0))
		c.position = src_pos + jitter - cs * 0.5
		layer.add_child(c)
		var delay := float(i) * 0.045
		var tw := create_tween()
		tw.tween_interval(delay)
		# piccola "presa d'aria" prima di partire
		tw.tween_property(c, "position", c.position - Vector2(0, 18.0), 0.14).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tw.tween_property(c, "position", target - cs * 0.5, 0.42).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		tw.parallel().tween_property(c, "scale", Vector2(0.6, 0.6), 0.42)
		tw.tween_callback(c.queue_free)
	# conteggio + rimbalzo SOLO quando le monete arrivano nel contatore.
	# A quel punto aggiorna tutti i contatori (top/shop) e anima la barra missioni.
	var t := create_tween()
	t.tween_interval(float(n) * 0.045 + 0.35)
	t.tween_callback(func() -> void:
		_update_coin_count()   # top + shop + missioni al nuovo valore
		_update_coin_label()
		_animate_coin_gain(from_v, to_v))
	var cl := create_tween()
	cl.tween_interval(float(n) * 0.045 + 1.0)
	cl.tween_callback(layer.queue_free)


# Monete che salgono (conteggio) + rimbalzo quando si riscatta una missione.
func _animate_coin_gain(from_v: int, to_v: int) -> void:
	if _missions_coins_label == null:
		return
	settings.play_coin()   # suono delle monete che salgono
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
	for arr in [missions.missions, missions.weekly, missions.monthly]:
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
	_update_record_labels()
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
		# alla prima apertura del gioco: intro "TV on" sullo schermo del cabinato + suono
		if not settings.home_intro_played:
			_play_home_intro()
		else:
			_update_mode_screen()


# Intro "accensione TV" sullo schermo del cabinato (una volta per sessione).
# Intro "TV on": la mode classica/selezionata è GIÀ sotto, l'overlay TV-on (opaco->trasparente)
# la rivela accendendo lo schermo. Una volta per sessione.
func _play_home_intro() -> void:
	settings.home_intro_played = true
	_update_mode_screen()   # animazione modalità (classica) SOTTO
	# 1) schermo del cabinato NERO per ~1.5s
	_set_screen_dark(true)
	await get_tree().create_timer(1.5).timeout
	if not is_inside_tree():
		return
	# 2) animazione "accensione TV" (rivela lo schermo)
	var tf := _load_fx_frames("tvon", 17, 22.0)
	_set_screen_dark(false)   # ripristina i colori (coperti dal frame opaco del TV-on)
	if tf == null:
		_start_intro_music()
		return
	settings.play_tvon()
	_intro_pending_music = true
	_start_screen_fx(tf)

# Oscura/ripristina lo schermo del cabinato (animazione modalità + eventuale titolo).
func _set_screen_dark(dark: bool) -> void:
	var c := Color(0, 0, 0) if dark else Color(1, 1, 1)
	if _screen_anim:
		_screen_anim.modulate = c
	if _screen_title:
		_screen_title.modulate = c

# Musica della home con dissolvenza molto rapida (parte a fine intro TV-on).
func _start_intro_music() -> void:
	settings.play_music(music_player.stream, 0.25)

# Flash "cambio modalità": copre lo schermo mentre cambia la modalità sotto.
func _play_mode_select_fx() -> void:
	if _modesel_frames == null:
		_modesel_frames = _load_fx_frames("modesel", 19, 26.0)
	if _modesel_frames == null:
		_update_mode_screen()
		return
	_start_screen_fx(_modesel_frames)
	# scambia il contenuto al PICCO del flash (schermo coperto) così non si vede lo stacco
	var tw := create_tween()
	tw.tween_interval(0.28)
	tw.tween_callback(_update_mode_screen)

func _start_screen_fx(frames: SpriteFrames) -> void:
	if _screen_fx == null:
		return
	_screen_fx.sprite_frames = frames
	_position_screen_fx()
	_screen_fx.visible = true
	if not _screen_fx.animation_finished.is_connected(_on_screen_fx_done):
		_screen_fx.animation_finished.connect(_on_screen_fx_done, CONNECT_ONE_SHOT)
	_screen_fx.play("a")

func _position_screen_fx() -> void:
	if _screen_fx == null:
		return
	_screen_fx.position = _art_to_world(SCREEN_ANIM_CENTER_ART)
	var sc := (SCREEN_ANIM_WIDTH_ART / SCREEN_FX_TEX_W) * ART_SCALE
	_screen_fx.scale = Vector2(sc, sc)

func _on_screen_fx_done() -> void:
	if _screen_fx:
		_screen_fx.visible = false
	# fine intro TV-on: parte la musica (dissolvenza rapida)
	if _intro_pending_music:
		_intro_pending_music = false
		_start_intro_music()

func _load_fx_frames(prefix: String, count: int, fps: float) -> SpriteFrames:
	var sf := SpriteFrames.new()
	sf.add_animation("a")
	sf.set_animation_loop("a", false)
	sf.set_animation_speed("a", fps)
	for i in count:
		var t: Texture2D = load("res://CORE/Assets/Art/Home/Screen/%s_%02d.png" % [prefix, i])
		if t:
			sf.add_frame("a", t)
	return sf if sf.get_frame_count("a") > 0 else null


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
	# contatori in alto: MONETE a destra + RECORD a sinistra (come home/missioni)
	var scc := _make_counter(_shop_menu, COIN_TEX, COIN_X, COUNTER_Y, COIN_W, COIN_ICON_FRAC)
	_shop_coins_label = scc[1] as Label
	_make_record_counter(_shop_menu, RECORD_X)
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

