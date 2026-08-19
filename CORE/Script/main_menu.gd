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
const DECK_TEX := Vector2(640.0, 576.0)
const DECK_BTN_H_ART := 150.0                # altezza comune dei due tasti (più grandi)
const DECK_GAP_ART := -4.0                    # attaccati (piccolo che chiude il seam, niente sovrapposizione visibile)
const DECK_ROW_CENTER_ART := Vector2(399.0, 970.0)  # posizione tasto play (indipendente dal cabinato)
const PRESS_SINK := 5.0                       # px di "affondamento" alla pressione
const SPARKLE_OFFSET_Y := 0.0
const DECK_GAP_ROW := 12.0                    # spazio tra tasto deck e tasto play

# Tendina CUBE DECK (scorre dal basso). Frame 800x1088, card 704x960.
const DECK_ASPECT := 800.0 / 1088.0
const CARD_ASPECT := 704.0 / 960.0
const DECK_PANEL_W := 548.0                   # larghezza interna fissa (riferimento card)
const DECK_TOP_FRAC := 0.26                   # bordo alto della tendina (sotto il profilo)
const DECK_BOTTOM_FRAC := 1.05                # bordo basso (>1 = sfora sotto lo schermo, riempie tutto)

# Popup info cubo: pannello a dimensione di design (frame 624x976), scalato e centrato.
const CI_PW := 624.0
const CI_PH := 976.0                          # altezza cornice
const CI_DESIGN_H := 1072.0                   # + spazio per il tasto OK che sporge sotto
# Schede del deck (3 per riga, scorrevole). 7 cubi colorati + speciali.
const DECK_CARDS := [
	{"tex": "res://CORE/Assets/Art/Game/Cubes/Red/Red.svg",       "name": "CUBO ROSSO",   "special": false},
	{"tex": "res://CORE/Assets/Art/Game/Cubes/Orange/Orange.svg", "name": "CUBO ARANCIO", "special": false},
	{"tex": "res://CORE/Assets/Art/Game/Cubes/Yellow/Yellow.svg", "name": "CUBO GIALLO",  "special": false},
	{"tex": "res://CORE/Assets/Art/Game/Cubes/Green/Green.svg",   "name": "CUBO VERDE",   "special": false},
	{"tex": "res://CORE/Assets/Art/Game/Cubes/Blue/Blue.svg",     "name": "CUBO BLU",     "special": false},
	{"tex": "res://CORE/Assets/Art/Game/Cubes/Purple/Purple.svg", "name": "CUBO VIOLA",   "special": false},
	{"tex": "res://CORE/Assets/Art/Game/Cubes/Pink/Pink.svg",     "name": "CUBO ROSA",    "special": false},
	{"tex": "res://CORE/Assets/Art/Game/Cubes/_PLUS/Red/ab_1.png", "name": "FRECCIA VERT.", "special": true, "frame": "res://CORE/Assets/Art/Home/Deck/card_frecce.png"},
	{"tex": "res://CORE/Assets/Art/Game/Cubes/_PLUS/Red/ab_1.png", "name": "FRECCIA ORIZ.", "special": true, "frame": "res://CORE/Assets/Art/Home/Deck/card_frecce.png"},
	{"tex": "res://CORE/Assets/Art/Game/Cubes/_PLUS/Bomb/bomb_1.png",   "name": "BOMBA",         "special": true},
	{"tex": "res://CORE/Assets/Art/Game/Cubes/_XBOMB/Anim/xbomb_1.png", "name": "BOMBA X",       "special": true},
	{"tex": "res://CORE/Assets/Art/Game/Cubes/_ANGLES/Anim/angles_1.png", "name": "BOMBA ANGOLI",  "special": true},
]

# Info dettagliata dei cubi (popup stile Clash Royale). Per ora SOLO il cubo rosso.
# Info dei cubi CLASSICI (popup). Gli speciali non hanno il popup/doppia skin.
const CUBE_INFO := {
	"CUBO ROSSO": {
		"cube": "res://CORE/Assets/Art/Game/Cubes/Red/Red.svg", "name": "CUBO ROSSO", "color_key": "red",
		"type": "CLASSICO", "color": Color(0.93, 0.26, 0.26),
		"desc": "Rosso, quadrato e senza fronzoli. Nessun potere speciale: solo una gran voglia di essere abbinato.",
	},
	"CUBO ARANCIO": {
		"cube": "res://CORE/Assets/Art/Game/Cubes/Orange/Orange.svg", "name": "CUBO ARANCIO", "color_key": "orange",
		"type": "CLASSICO", "color": Color(0.96, 0.55, 0.15),
		"desc": "Arancione come un tramonto, utile come... un altro cubo. Fa numero, e lo fa benissimo.",
	},
	"CUBO GIALLO": {
		"cube": "res://CORE/Assets/Art/Game/Cubes/Yellow/Yellow.svg", "name": "CUBO GIALLO", "color_key": "yellow",
		"type": "CLASSICO", "color": Color(0.98, 0.82, 0.20),
		"desc": "Giallo acceso, personalita spenta. Non illumina la stanza, ma riempie la griglia.",
	},
	"CUBO VERDE": {
		"cube": "res://CORE/Assets/Art/Game/Cubes/Green/Green.svg", "name": "CUBO VERDE", "color_key": "green",
		"type": "CLASSICO", "color": Color(0.36, 0.75, 0.30),
		"desc": "Verde speranza: spera sempre che tu lo abbini in tempo. Nessun superpotere, tanta pazienza.",
	},
	"CUBO BLU": {
		"cube": "res://CORE/Assets/Art/Game/Cubes/Blue/Blue.svg", "name": "CUBO BLU", "color_key": "blue",
		"type": "CLASSICO", "color": Color(0.30, 0.68, 0.95),
		"desc": "Blu come il lunedi. Fa il suo dovere senza lamentarsi (troppo).",
	},
	"CUBO VIOLA": {
		"cube": "res://CORE/Assets/Art/Game/Cubes/Purple/Purple.svg", "name": "CUBO VIOLA", "color_key": "purple",
		"type": "CLASSICO", "color": Color(0.66, 0.42, 0.90),
		"desc": "Viola misterioso... ma il mistero e che non fa niente di speciale. Elegante, pero.",
	},
	"CUBO ROSA": {
		"cube": "res://CORE/Assets/Art/Game/Cubes/Pink/Pink.svg", "name": "CUBO ROSA", "color_key": "pink",
		"type": "CLASSICO", "color": Color(0.93, 0.40, 0.80),
		"desc": "Rosa e fiero. Sembra tenero, ma sa il fatto suo quando si tratta di combo.",
	},
	# ABILITÀ (speciali): popup con SOLA skin base (niente doppia skin).
	"FRECCIA VERT.": {
		"cube": "res://CORE/Assets/Art/Game/Cubes/_PLUS/Red/ab_1.png", "name": "FRECCIA VERT.", "color_key": "",
		"type": "ABILITA", "color": Color(0.98, 0.35, 0.55),
		"desc": "Distrugge tutta la COLONNA in cui si trova. Verticale e senza pieta.",
	},
	"FRECCIA ORIZ.": {
		"cube": "res://CORE/Assets/Art/Game/Cubes/_PLUS/Red/ab_1.png", "name": "FRECCIA ORIZ.", "color_key": "",
		"type": "ABILITA", "color": Color(0.98, 0.35, 0.55),
		"desc": "Spazza via l'intera RIGA. Orizzontale e implacabile.",
	},
	"BOMBA": {
		"cube": "res://CORE/Assets/Art/Game/Cubes/_PLUS/Bomb/bomb_1.png", "name": "BOMBA", "color_key": "",
		"type": "ESPLOSIVO", "color": Color(0.98, 0.35, 0.55),
		"desc": "Esplode e distrugge i cubi tutt'intorno (3x3). Boom!",
	},
	"BOMBA X": {
		"cube": "res://CORE/Assets/Art/Game/Cubes/_XBOMB/Anim/xbomb_1.png", "name": "BOMBA X", "color_key": "",
		"type": "ESPLOSIVO", "color": Color(0.98, 0.35, 0.55),
		"desc": "Esplode lungo le due diagonali, a forma di X.",
	},
	"BOMBA ANGOLI": {
		"cube": "res://CORE/Assets/Art/Game/Cubes/_ANGLES/Anim/angles_1.png", "name": "BOMBA ANGOLI", "color_key": "",
		"type": "ESPLOSIVO", "color": Color(0.98, 0.35, 0.55),
		"desc": "Colpisce i quattro angoli dell'area. Sorpresa!",
	},
}

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
	# 3a modalità = CAMPAGNA / STORIA (stile Candy Crush). Il PLAY NON avvia una partita:
	# apre una MAPPA a livelli (schermata dedicata). Nome/grafiche provvisori.
	{"mode": "story",    "label": "STORIA",   "sub": "campagna a livelli",    "color": Color(0.25, 0.70, 0.95)},
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
# indice del DITO che sta premendo ciascun tasto (-99 = nessuno; -1 = mouse). Serve a NON
# far azzerare la pressione dal rilascio di un ALTRO dito (multi-touch / tap rapidi):
# era il motivo per cui la Speedrun a volte "non partiva" toccando altri tasti.
var _play_touch := -99
var _deck_touch := -99
var _arrow_l_touch := -99
var _arrow_r_touch := -99
var _starting := false   # guardia anti doppio-avvio partita
var _deck_sprite: Sprite2D
var _deck_world_center := Vector2.ZERO
var _deck_world_size := Vector2.ZERO
var _deck_pressing := false
var _deck_menu: Control
var _deck_layer: CanvasLayer
var _deck_panel: Control
var _deck_dim: ColorRect
var _deck_frame: TextureRect
var _deck_title: Label
var _deck_scroll: ScrollContainer
var _deck_content: Control
var _deck_anim: Tween
var _deck_rest_pos := Vector2.ZERO
var _deck_hidden_pos := Vector2.ZERO
# Popup info cubo (Clash-Royale-style)
var _ci_layer: CanvasLayer
var _ci_menu: Control
var _ci_dim: ColorRect
var _ci_panel: Control
var _ci_anim: Tween
var _ci_video: TextureRect
var _ci_video_frames: Array = []
var _ci_video_idx := 0
var _ci_video_timer: Timer
var _ci_ok_btn: TextureButton
var _ci_preview: TextureRect          # cubo grande in alto (preview della skin selezionata)
var _ci_check: TextureRect            # spunta verde (spostata sulla skin selezionata)
var _ci_skin_slots: Array = []        # [{btn, cube, data, owned}]
var _ci_cur_info: Dictionary = {}     # info del cubo aperto
# Demo "video" live (gameplay reale) nel riquadro video del Cube Info.
# Dispatcher per tipo di cubo: match (classici) / frecce (beam V-O) / bombe (3x3, X, angoli).
var _ci_demo: Control = null                 # container (riempie tutto il riquadro video)
var _ci_demo_rect := Rect2()                 # area interna per disporre i cubi (con margine)
var _ci_demo_info: Dictionary = {}           # info del cubo in demo
var _ci_demo_kind := ""                       # match|beam_v|beam_h|bomb3x3|bombx|bombangoli
var _ci_demo_tween: Tween = null
var _ci_demo_running := false
var _ci_demo_color_idx := 0                   # ciclo colori (frecce / griglie randomiche)
var _gray_mat: ShaderMaterial = null  # shader b/n per skin non possedute
var _play_base_pos := Vector2.ZERO           # posizione base (non premuta) per il sink idempotente
var _play_base_scale := Vector2.ONE          # scala base del tasto play (per il rimbalzo)
var _play_bounce_tween: Tween                 # rimbalzo periodico "invito a giocare"
var _deck_base_pos := Vector2.ZERO
var _deck_base_scale := Vector2.ONE
var _deck_bounce_tween: Tween

# Barra in alto a destra: coin count + classifica + impostazioni
var _coin_bar: TextureRect
var _record_bar: TextureRect
var _home_star_bar: TextureRect = null   # contatore STELLE (solo quando è selezionata STORY)
var _home_star_label: Label = null
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
	"res://CORE/Assets/Art/Home/Profile/profile_og.png",
	# icone acquistabili nello SHOP (sbloccabili comprandole): bomba, fungo, pinguino
	"res://CORE/Assets/Art/Home/Shop/av_bomb.png",
	"res://CORE/Assets/Art/Home/Shop/av_mushroom.png",
	"res://CORE/Assets/Art/Home/Shop/av_penguin.png",
	"res://CORE/Assets/Art/Home/Shop/av_fish.png",
	"res://CORE/Assets/Art/Home/Shop/av_skull.png",
	"res://CORE/Assets/Art/Home/Shop/av_pig.png",
]
# icone SBLOCCABILI dalle missioni mensili: indice in PROFILE_ICONS -> id sblocco.
# Se non sbloccata: mostrata in bianco/nero e NON selezionabile.
# "creator"/"og" NON vengono dalle missioni: si sbloccano da remoto (approvazione
# Creator / lista OG supporters).
const PROFILE_ICON_LOCK := {3: "fire", 4: "trophy", 5: "cupgold", 6: "cupgreen", 7: "creator", 8: "beta", 9: "og"}
# icone sbloccabili acquistandole nello SHOP: indice in PROFILE_ICONS -> id avatar shop.
const PROFILE_ICON_SHOP := {10: "av_bomb", 11: "av_mushroom", 12: "av_penguin", 13: "av_fish", 14: "av_skull", 15: "av_pig"}
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
var _profile_lock_overlays: Array = []   # lucchetto sopra le icone ancora bloccate
var _lock_tex: ImageTexture = null       # texture pixel-art del lucchetto (generata una volta)
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

# --- MODALITÀ STORIA / CAMPAGNA (mappa a livelli, struttura provvisoria) --------
# Il PLAY con modalità "story" apre questa mappa scorrevole (livello 1 in basso,
# si sale verso l'alto). I livelli NON sono ancora giocabili: il tap apre un popup
# (nome + descrizione + immagine placeholder + missione + tasto GIOCA). I contenuti
# reali dei livelli andranno in STORY_LEVELS_DATA; per ora tutto placeholder.
# La mappa lavora nello spazio LOGICO del gioco: 576 unità = larghezza schermo su ogni
# telefono (stretch canvas_items/expand). L'arte del MONDO 1 è pensata 768×5760 px (1 px = 1
# unità): banda centrale sicura 576 (px 96..672 dell'arte), 96 px per lato = bleed per tablet.
# Altezza 5760 = 30 livelli × 192 di passo + 96 di margine sopra/sotto.
const STORY_LEVELS := 30                     # livelli per stagione (stagione 1)
const STORY_NODE := 96.0                     # diametro del nodo-livello (unità di gioco)
const STORY_V_GAP := 192.0                   # distanza verticale tra due livelli
const STORY_PAD_TOP := 560.0     # spazio sopra il livello 30 (fascia nuvole in cima + testo/timer sovrapposti)
const STORY_PAD_BOTTOM := 360.0  # spazio sotto il livello 1
# Configurazione dei 30 livelli storia (spec utente 2026-08-14).
# grid=lato griglia · colors=n. colori normali · v/h/b=abilità (verticale/orizzontale/bomba)
# goal: "score"(target) · "cubes"(cubes) · "colors"(colors_goal {nome:qta}) · "speedrun"(target+time)
const STORY_LEVELS_DATA: Array = [
	{"grid":3, "colors":3, "v":false, "h":false, "b":false, "goal":"score", "target":1000},
	{"grid":3, "colors":3, "v":true, "h":false, "b":false, "goal":"score", "target":1500},
	{"grid":3, "colors":3, "v":true, "h":true, "b":false, "goal":"score", "target":2000},
	{"grid":3, "colors":3, "v":true, "h":true, "b":true, "goal":"score", "target":2500},
	{"grid":3, "colors":3, "v":false, "h":false, "b":false, "goal":"cubes", "cubes":50},
	{"grid":3, "colors":3, "v":true, "h":true, "b":true, "goal":"score", "target":3000},
	{"grid":3, "colors":3, "v":true, "h":true, "b":true, "goal":"colors", "colors_goal":{"red":20}},
	{"grid":3, "colors":3, "v":true, "h":true, "b":true, "goal":"colors", "colors_goal":{"green":15, "yellow":15}},
	{"grid":3, "colors":3, "v":true, "h":true, "b":true, "goal":"colors", "colors_goal":{"red":12, "green":12, "yellow":12}},
	{"grid":3, "colors":3, "v":true, "h":true, "b":true, "goal":"speedrun", "target":3000, "time":180.0},
	{"grid":5, "colors":5, "v":false, "h":false, "b":false, "goal":"score", "target":4000},
	{"grid":5, "colors":5, "v":true, "h":false, "b":false, "goal":"score", "target":5000},
	{"grid":5, "colors":5, "v":true, "h":true, "b":false, "goal":"score", "target":6000},
	{"grid":5, "colors":5, "v":true, "h":true, "b":true, "goal":"score", "target":7000},
	{"grid":5, "colors":5, "v":false, "h":false, "b":false, "goal":"cubes", "cubes":120},
	{"grid":5, "colors":5, "v":true, "h":true, "b":true, "goal":"score", "target":9000},
	{"grid":5, "colors":5, "v":true, "h":true, "b":true, "goal":"colors", "colors_goal":{"red":40}},
	{"grid":5, "colors":5, "v":true, "h":true, "b":true, "goal":"colors", "colors_goal":{"green":30, "yellow":30}},
	{"grid":5, "colors":5, "v":true, "h":true, "b":true, "goal":"colors", "colors_goal":{"red":25, "green":25, "yellow":25}},
	{"grid":5, "colors":5, "v":true, "h":true, "b":true, "goal":"speedrun", "target":8000, "time":300.0},
	{"grid":7, "colors":7, "v":false, "h":false, "b":false, "goal":"score", "target":6000},
	{"grid":7, "colors":7, "v":true, "h":false, "b":false, "goal":"score", "target":8000},
	{"grid":7, "colors":7, "v":true, "h":true, "b":false, "goal":"score", "target":10000},
	{"grid":7, "colors":7, "v":true, "h":true, "b":true, "goal":"score", "target":12000},
	{"grid":7, "colors":7, "v":false, "h":false, "b":false, "goal":"cubes", "cubes":200},
	{"grid":7, "colors":7, "v":true, "h":true, "b":true, "goal":"score", "target":16000},
	{"grid":7, "colors":7, "v":true, "h":true, "b":true, "goal":"colors", "colors_goal":{"red":60}},
	{"grid":7, "colors":7, "v":true, "h":true, "b":true, "goal":"colors", "colors_goal":{"green":45, "yellow":45}},
	{"grid":7, "colors":7, "v":true, "h":true, "b":true, "goal":"colors", "colors_goal":{"red":35, "green":35, "yellow":35}},
	{"grid":7, "colors":7, "v":true, "h":true, "b":true, "goal":"speedrun", "target":10000, "time":300.0},
]
# --- Grafica MONDO 1: sfondo verde + isole cliccabili ---
const STORY_BG_TEX := preload("res://CORE/Assets/Art/Story/sfondo_story.png")
const STORY_ISLAND_TEX := preload("res://CORE/Assets/Art/Story/level_node.png")
const STORY_CLOUDS_TEX := preload("res://CORE/Assets/Art/Story/clouds_top.png")
# Prossima stagione: parte il 1° settembre 2026 (countdown fino a quel giorno)
const STORY_SEASON_TARGET_ISO := "2026-09-01T00:00:00"
const STORY_ISLAND_W := 156.0                 # larghezza nodo-livello (tile quadrata)
const STORY_ISLAND_H := 173.0                 # altezza (aspetto 1152×1280 ≈ 0.9)
const STORY_ISLAND_GAP := 220.0               # distanza verticale tra due isole
var _story_layer: CanvasLayer
var _story_map_img: TextureRect
var _story_bg_img: ColorRect                   # fondo blu tinta unita (fisso, dietro tutto)
var _story_bg_scroll: TextureRect              # sfondo a strisce blu SCORREVOLE (dentro il contenuto)
var _story_num_labels: Array = []              # label numero su ogni isola
var _story_bounce_tw: Tween = null             # tween di rimbalzo dell'isola del livello corrente
var _story_season_lbl: Label = null            # "NUOVA STAGIONE IN ARRIVO" sopra il livello 30
var _story_clouds: TextureRect = null          # fascia di nuvole in cima alla mappa (sotto il testo stagione)
var _story_countdown_lbl: Label = null         # timer countdown alla prossima stagione (1 set)
var _story_countdown_timer: Timer = null       # aggiorna il countdown ogni secondo
var _story_island_stars: Array = []            # per ogni isola: [3 TextureRect stella]
var _story_star_counter: Label = null          # contatore stelle totali (in alto a destra)
var _story_counter_icon: TextureRect = null    # icona stella accanto al contatore
var _story_map: Control
var _story_scroll: ScrollContainer
var _story_content: Control
var _story_path: Line2D
var _story_level_buttons: Array = []
var _story_level_pos: Array = []             # centro di ogni nodo in coord contenuto
var _story_total_h := 0.0
var _story_popup: Control
var _story_pop_title: Label
var _story_pop_img: TextureRect
var _story_pop_desc: Label
var _story_pop_mission: Label
var _story_pop_star_icons: Array = []          # 3 icone stella nel popup
var _story_pop_star_lbls: Array = []           # 3 missioni (una per stella) nel popup
var _story_pop_reward_icons: Array = []        # 3 icone ricompensa (moneta/cosmetico)
var _story_pop_reward_lbls: Array = []         # 3 label importo ricompensa
var _story_pop_claim_btns: Array = []          # 3 tasti RISCUOTI
var _story_pop_bigstar_icons: Array = []       # 3 stelle grandi in cima (stato livello)
var _story_pop_num: Label                      # "LIVELLO N" grande
# anteprima ANIMATA del livello (stile cube deck): griglia N×N coi colori del livello
var _story_preview_box: Panel = null
var _story_preview_cubes: Array = []
var _story_preview_palette: Array = []
var _story_preview_timer: Timer = null
var _story_pop_stats: VBoxContainer            # caratteristiche: "Dimensioni griglia: N×N" + cubi
# cubi colorati (icone piccole per la sezione caratteristiche); ordine come in grid.gd
const STORY_CUBE_TEX := {
	"red": preload("res://CORE/Assets/Art/Game/Cubes/Red/Red.svg"),
	"green": preload("res://CORE/Assets/Art/Game/Cubes/Green/Green.svg"),
	"yellow": preload("res://CORE/Assets/Art/Game/Cubes/Yellow/Yellow.svg"),
	"blue": preload("res://CORE/Assets/Art/Game/Cubes/Blue/Blue.svg"),
	"purple": preload("res://CORE/Assets/Art/Game/Cubes/Purple/Purple.svg"),
	"orange": preload("res://CORE/Assets/Art/Game/Cubes/Orange/Orange.svg"),
	"pink": preload("res://CORE/Assets/Art/Game/Cubes/Pink/Pink.svg"),
}
const STORY_COLOR_ORDER := ["red", "green", "yellow", "blue", "purple", "orange", "pink"]
const STORY_STAR_FULL_TEX := preload("res://CORE/Assets/Art/Story/star_full.png")
const STORY_STAR_EMPTY_TEX := preload("res://CORE/Assets/Art/Story/star_empty.png")
const STORY_COIN_TEX := preload("res://CORE/Assets/Art/UI/Missions/coin_icon.png")
const STORY_POPUP_PANEL_TEX := preload("res://CORE/Assets/Art/Story/popup_panel.png")
const STORY_PLAY_TEX := preload("res://CORE/Assets/Art/Story/btn_play.png")
const STORY_CLOSE_TEX := preload("res://CORE/Assets/Art/Story/btn_close.png")
var _story_pop_play_idx := 1
var _story_msg: Label
var _story_back: TextureButton
var _story_title: Label
const STORY_BACK_TEX := preload("res://CORE/Assets/Art/UI/Game/exit_arrow.png")

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
var _prev_tab := "home"   # per cambiare musica solo entrando/uscendo dallo shop
var _shop_menu: Control
var _shop_coins_label: Label
var _shop_items: Dictionary = {}   # id -> {kind, box, sb, lbl, price}
var _shop_msg: Label               # messaggio "monete insufficienti"
var _shop_bg: ColorRect
var _shop_curtain: TextureRect     # tenda rossa in alto (adattiva)
var _shop_title: Label             # scritta "SHOP" grande con contorno nero
var _shop_scroll: ScrollContainer  # area scorrevole (barra nascosta)
var _shop_top_pad: Control         # spazio in cima allo scroll (nascosto sotto la tenda)
var _shop_timer_label: Label       # countdown "nuovo shop tra..." sotto la scritta SHOP
var _shop_coin_bar: TextureRect
var _shop_record_bar: TextureRect
const SHOP := "res://CORE/Assets/Art/Home/Shop/"

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
	_build_story_map()
	_build_deck_menu()
	_build_cubeinfo_menu()
	_build_leader_menu()
	_build_top_right()
	_build_profile_menu()
	_build_nav_bar()
	_apply_press_fx_all(self)    # affondamento + vibrazione su tutti i tasti restanti
	_layout()
	get_viewport().size_changed.connect(_layout)
	_select_tab("home", false)
	# ritorno da un livello storia col tasto MAPPA: riapri la mappa invece della home
	if settings.open_story_on_load:
		settings.open_story_on_load = false
		call_deferred("_open_story_map")


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
	_layout_deck()
	_layout_cubeinfo()
	_layout_shop()
	_layout_story()
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

	# Tasto CUBE DECK a fianco del PLAY (apre la tendina). Input a mano in _input().
	_deck_sprite = Sprite2D.new()
	_deck_sprite.texture = load("res://CORE/Assets/Art/Home/cube_deck_icon.png")
	_deck_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_deck_sprite.z_index = 0
	add_child(_deck_sprite)

	# rimbalzo periodico del tasto DECK (come il PLAY, invito a giocare)
	var dbt := Timer.new()
	dbt.wait_time = 5.0
	dbt.one_shot = false
	dbt.autostart = true
	add_child(dbt)
	dbt.timeout.connect(_deck_bounce)

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


# Rimbalzo del tasto CUBE DECK (come il PLAY).
func _deck_bounce() -> void:
	if _deck_sprite == null or not _deck_sprite.visible or _deck_pressing:
		return
	if _deck_bounce_tween != null and _deck_bounce_tween.is_valid():
		return
	var bp := _deck_base_pos
	var bs := _deck_base_scale
	_deck_bounce_tween = create_tween()
	_deck_bounce_tween.tween_property(_deck_sprite, "position:y", bp.y - 22.0, 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_deck_bounce_tween.parallel().tween_property(_deck_sprite, "scale", bs * 1.06, 0.16)
	_deck_bounce_tween.tween_property(_deck_sprite, "position:y", bp.y, 0.45).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	_deck_bounce_tween.parallel().tween_property(_deck_sprite, "scale", bs, 0.30)


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
	# DECK (quadrato) + PLAY affiancati, coppia centrata sotto lo schermo del cabinato.
	var h := DECK_BTN_H_ART
	var play_w := PLAY_NEW_TEX.x / PLAY_NEW_TEX.y * h   # larghezza art del PLAY a quest'altezza
	var deck_w := DECK_TEX.x / DECK_TEX.y * h           # DECK quadrato
	var total := deck_w + DECK_GAP_ROW + play_w
	var left := DECK_ROW_CENTER_ART.x - total * 0.5
	var y := DECK_ROW_CENTER_ART.y - 32.0
	var deck_cx := left + deck_w * 0.5
	var play_cx := left + deck_w + DECK_GAP_ROW + play_w * 0.5

	var s := (h / PLAY_NEW_TEX.y) * ART_SCALE
	_play_base.position = _art_to_world(Vector2(play_cx, y))
	_play_base.scale = Vector2(s, s)
	_play_base_pos = _play_base.position
	_play_base_scale = Vector2(s, s)
	_play_world_center = _play_base.position
	_play_world_size = PLAY_NEW_TEX * s

	if _deck_sprite:
		var ds := (h / DECK_TEX.y) * ART_SCALE
		_deck_sprite.position = _art_to_world(Vector2(deck_cx, y))
		_deck_sprite.scale = Vector2(ds, ds)
		_deck_base_pos = _deck_sprite.position
		_deck_base_scale = Vector2(ds, ds)
		_deck_world_center = _deck_sprite.position
		_deck_world_size = DECK_TEX * ds

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
	# STORIA / CAMPAGNA: animazione (SOTRY.GIF) + scritta STORY a schermo
	_mode_anims["story"] = _load_screen_frames("story")
	_mode_titles["story"] = load("res://CORE/Assets/Art/Home/screen_title_story.png")


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
	# STORY: mostra il contatore STELLE nella STESSA identica posizione del contatore RECORD
	# (punti classic/speedrun) e nascondi il record. Copio pos/size dal record → nessuno sfasamento.
	var is_story := mode == "story"
	if _home_star_bar and is_instance_valid(_record_bar):
		_home_star_bar.position = _record_bar.position
		_home_star_bar.size = Vector2(REC_CLASSIC_W, COUNTER_H)
		_home_star_bar.visible = is_story
		if is_story and _home_star_label:
			_home_star_label.position = Vector2(REC_CLASSIC_W * REC_CLASSIC_ICON_FRAC, 0.0)
			_home_star_label.size = Vector2(REC_CLASSIC_W * (1.0 - REC_CLASSIC_ICON_FRAC), COUNTER_H)
			_home_star_label.text = str(settings.story_total_stars())
	if _record_bar:
		_record_bar.visible = not is_story
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
		_mode_screen_label.text = loc.t(m["label"])
		_mode_screen_label.add_theme_color_override("font_color", m["color"])
		_mode_screen_sub.text = loc.t(m["sub"])


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
	if _story_map and _story_map.visible:
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
	# indice del dito (touch) o -1 per il mouse
	var idx: int = event.index if event is InputEventScreenTouch else -1
	if event.pressed:
		# un solo tasto per dito; se il tasto è già premuto da un altro dito, ignora
		if play_rect.has_point(world) and _play_touch == -99:
			_play_touch = idx
			_play_pressing = true
			_on_play_down()
		elif deck_rect.has_point(world) and _deck_touch == -99:
			_deck_touch = idx
			_deck_pressing = true
			_on_deck_down()
		elif l_rect.has_point(world) and _arrow_l_touch == -99:
			_arrow_l_touch = idx
			_arrow_l_pressing = true
			_arrow_down(_arrow_l_base, _arrow_l_pressed, _arrow_l_sparkles)
		elif r_rect.has_point(world) and _arrow_r_touch == -99:
			_arrow_r_touch = idx
			_arrow_r_pressing = true
			_arrow_down(_arrow_r_base, _arrow_r_pressed, _arrow_r_sparkles)
	else:
		# reagisci SOLO al rilascio dello STESSO dito che aveva premuto il tasto
		if _play_pressing and idx == _play_touch:
			_play_pressing = false
			_play_touch = -99
			_on_play_up()
			if play_rect.has_point(world):
				_on_play_pressed()
		elif _deck_pressing and idx == _deck_touch:
			_deck_pressing = false
			_deck_touch = -99
			_on_deck_up()
			if deck_rect.has_point(world):
				_on_deck_pressed()
		elif _arrow_l_pressing and idx == _arrow_l_touch:
			_arrow_l_pressing = false
			_arrow_l_touch = -99
			_arrow_up(_arrow_l_base, _arrow_l_pressed, _arrow_l_sparkles)
			if l_rect.has_point(world):
				_cycle_mode(-1)
		elif _arrow_r_pressing and idx == _arrow_r_touch:
			_arrow_r_pressing = false
			_arrow_r_touch = -99
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
	var mode: String = MODES[_mode_index]["mode"]
	if mode == "story":
		# la campagna non avvia una partita: apre la MAPPA a livelli CON la stessa
		# transizione (wipe) delle altre modalità: copri -> apri mappa -> scopri.
		settings.play_playbutton()
		settings.vibrate(15)
		transition.wipe(_open_story_map)
		return
	_start_mode(mode)


# --- Tasto CUBE DECK -----------------------------------------------------------
func _on_deck_down() -> void:
	settings.button_feedback()
	if _deck_bounce_tween != null and _deck_bounce_tween.is_valid():
		_deck_bounce_tween.kill()
	_deck_sprite.scale = _deck_base_scale
	_deck_sprite.modulate = Color(0.85, 0.85, 0.85)
	_deck_sprite.position = _deck_base_pos + Vector2(0, PRESS_SINK)


func _on_deck_up() -> void:
	_deck_sprite.modulate = Color(1, 1, 1)
	_deck_sprite.position = _deck_base_pos


func _on_deck_pressed() -> void:
	_open_deck()


func _open_deck() -> void:
	if _deck_menu == null:
		return
	_deck_menu.visible = true
	_layout_deck()
	if _deck_anim and _deck_anim.is_valid():
		_deck_anim.kill()
	_deck_panel.position = _deck_hidden_pos
	_deck_dim.color.a = 0.0
	# animazione CALIBRATA: sale, supera di poco (14px) e si assesta. Niente rimbalzo esagerato.
	var over := _deck_rest_pos.y - 14.0
	_deck_anim = create_tween()
	_deck_anim.tween_property(_deck_panel, "position:y", over, 0.30) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_deck_anim.parallel().tween_property(_deck_dim, "color:a", 0.9, 0.26)
	_deck_anim.tween_property(_deck_panel, "position:y", _deck_rest_pos.y, 0.14) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _close_deck() -> void:
	if _deck_menu == null or not _deck_menu.visible:
		return
	if _deck_anim and _deck_anim.is_valid():
		_deck_anim.kill()
	_deck_anim = create_tween()
	_deck_anim.set_parallel(true)
	_deck_anim.tween_property(_deck_panel, "position:y", _deck_hidden_pos.y, 0.28) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_deck_anim.tween_property(_deck_dim, "color:a", 0.0, 0.24)
	_deck_anim.chain().tween_callback(func() -> void: _deck_menu.visible = false)


# Crea i nodi UNA volta; dimensioni/posizioni e card sono in _layout_deck (responsive).
func _build_deck_menu() -> void:
	# CanvasLayer dedicato SOPRA tutto (nav bar=10, profilo=20, ecc.): il dim copre e
	# blocca i tap ai tasti sottostanti; toccare fuori chiude e basta.
	_deck_layer = CanvasLayer.new()
	_deck_layer.layer = 200
	add_child(_deck_layer)

	_deck_menu = Control.new()
	_deck_menu.set_anchors_preset(Control.PRESET_FULL_RECT)
	_deck_menu.visible = false
	_deck_layer.add_child(_deck_menu)

	# Sfondo scuro a tutto schermo (blocca l'input; tap = chiudi)
	_deck_dim = ColorRect.new()
	_deck_dim.color = Color(0.05, 0.10, 0.18, 0.9)
	_deck_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_deck_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_deck_dim.gui_input.connect(_on_deck_dim_input)
	_deck_menu.add_child(_deck_dim)

	# Pannello tendina (dimensioni calcolate in _layout_deck; niente scale)
	_deck_panel = Control.new()
	_deck_menu.add_child(_deck_panel)

	# Frame (cornice pergamena blu). Riempie il pannello; assorbe i tap.
	_deck_frame = TextureRect.new()
	_deck_frame.texture = load("res://CORE/Assets/Art/Home/Deck/deck_frame.png")
	_deck_frame.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_deck_frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_deck_frame.stretch_mode = TextureRect.STRETCH_SCALE
	_deck_frame.mouse_filter = Control.MOUSE_FILTER_STOP
	_deck_panel.add_child(_deck_frame)

	# Titolo sul header giallo: BIANCO con contorno nero
	_deck_title = Label.new()
	_deck_title.text = loc.t("CUBE DECK")
	_deck_title.add_theme_font_override("font", MODE_FONT)
	_deck_title.add_theme_font_size_override("font_size", 58)
	_deck_title.add_theme_color_override("font_color", Color(1, 1, 1))
	_deck_title.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_deck_title.add_theme_constant_override("outline_size", 14)
	_deck_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_deck_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_deck_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_deck_panel.add_child(_deck_title)

	# Corpo scrollabile (barra nascosta; scroll al tocco)
	_deck_scroll = ScrollContainer.new()
	_deck_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_deck_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_deck_panel.add_child(_deck_scroll)
	var vsb := _deck_scroll.get_v_scroll_bar()
	if vsb:
		vsb.modulate = Color(1, 1, 1, 0)          # invisibile ma ancora scrollabile
		vsb.add_theme_stylebox_override("scroll", StyleBoxEmpty.new())
		vsb.add_theme_stylebox_override("grabber", StyleBoxEmpty.new())
		vsb.add_theme_stylebox_override("grabber_highlight", StyleBoxEmpty.new())
		vsb.add_theme_stylebox_override("grabber_pressed", StyleBoxEmpty.new())

	_deck_content = Control.new()
	_deck_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_deck_scroll.add_child(_deck_content)

	_layout_deck()


# Responsive: larghezza = quasi tutto lo schermo (si adatta ai lati), altezza GRANDE (può
# uscire sopra), ATTACCATO in basso. Le card mantengono le loro proporzioni (non deformate).
func _layout_deck() -> void:
	if _deck_panel == null:
		return
	var view := get_viewport_rect().size
	# larghezza = TUTTO lo schermo (lati flush); riempie tutto ma parte PIÙ IN BASSO e
	# sfora sotto il bordo inferiore (il top non arriva così in alto).
	var pwd := view.x
	var top_y := view.y * DECK_TOP_FRAC           # il bordo alto (con l'header) parte qui (sotto il profilo)
	var phd := view.y * DECK_BOTTOM_FRAC - top_y  # fino a poco sotto il bordo schermo
	_deck_panel.size = Vector2(pwd, phd)
	_deck_frame.position = Vector2.ZERO
	_deck_frame.size = Vector2(pwd, phd)
	_deck_rest_pos = Vector2((view.x - pwd) * 0.5, top_y)
	_deck_hidden_pos = Vector2(_deck_rest_pos.x, view.y + 40.0)

	# titolo nell'header giallo (leggermente più in alto)
	_deck_title.position = Vector2(pwd * 0.10, phd * 0.016)
	_deck_title.size = Vector2(pwd * 0.80, maxf(56.0, phd * 0.062))

	# corpo scrollabile: il CLIP (top dell'area) sta proprio al confine giallo/blu dell'header,
	# così scorrendo i cubi spariscono SOTTO il titolo. Il fondo arriva al bordo basso schermo.
	var gap := 14.0
	var bx := pwd * 0.09
	var by := phd * 0.095                         # clip dello scroll
	var bw := pwd * 0.82
	var bh := view.y - top_y - by                 # il fondo dell'area = fondo schermo
	_deck_scroll.position = Vector2(bx, by)
	_deck_scroll.size = Vector2(bw, bh)

	# ricostruisci le card a dimensione reale (3 per riga)
	for ch in _deck_content.get_children():
		_deck_content.remove_child(ch)
		ch.queue_free()
	var pad_top := phd * 0.045                     # i cubi partono un filo più in basso (ma clippano in alto)
	var pad_bottom := phd * 0.04
	var cols := 3
	var card_w := (bw - float(cols - 1) * gap) / float(cols)
	var card_h := card_w / CARD_ASPECT
	var n := DECK_CARDS.size()
	var rows := int(ceil(float(n) / float(cols)))
	var content_h := pad_top + float(rows) * card_h + float(maxi(rows - 1, 0)) * gap + pad_bottom
	_deck_content.custom_minimum_size = Vector2(bw, content_h)
	_deck_content.size = Vector2(bw, maxf(content_h, bh))
	for i in n:
		var row := i / cols
		var col := i % cols
		var in_row := mini(cols, n - row * cols)   # l'ultima riga può averne meno: la centro
		var row_w := float(in_row) * card_w + float(in_row - 1) * gap
		var start_x := (bw - row_w) * 0.5
		var cx := start_x + float(col) * (card_w + gap)
		var cy := pad_top + float(row) * (card_h + gap)
		var card := _make_deck_card(DECK_CARDS[i], card_w, card_h)
		card.position = Vector2(cx, cy)
		_deck_content.add_child(card)

	if _deck_anim and _deck_anim.is_valid():
		return   # non toccare la posizione durante lo slide
	_deck_panel.position = _deck_rest_pos if (_deck_menu and _deck_menu.visible) else _deck_hidden_pos


# Scheda del deck = Button CLICCABILE (per una sezione futura). Cornice + cubo piccolo + nome.
func _make_deck_card(c: Dictionary, cw: float, ch: float) -> Control:
	var card := Button.new()
	card.custom_minimum_size = Vector2(cw, ch)
	card.size = Vector2(cw, ch)
	card.focus_mode = Control.FOCUS_NONE
	card.flat = true
	# PASS: il tap sulla card funziona, ma il drag passa allo ScrollContainer (scroll fluido)
	card.mouse_filter = Control.MOUSE_FILTER_PASS
	# niente chrome del bottone: la grafica è la cornice
	for st in ["normal", "hover", "pressed", "focus", "disabled"]:
		card.add_theme_stylebox_override(st, StyleBoxEmpty.new())
	card.pressed.connect(_on_deck_card_pressed.bind(c))
	# effetto "vero tasto": alla pressione affonda un filo e si scurisce
	card.button_down.connect(func() -> void:
		card.position += Vector2(0, 4.0)
		card.modulate = Color(0.86, 0.86, 0.86))
	card.button_up.connect(func() -> void:
		card.position -= Vector2(0, 4.0)
		card.modulate = Color(1, 1, 1))
	var special: bool = c.get("special", false)
	var frame := TextureRect.new()
	# frame per-card opzionale (es. le FRECCE hanno una cornice dedicata); altrimenti special/classic
	var frame_path: String = c.get("frame", "res://CORE/Assets/Art/Home/Deck/card_special.png" if special \
		else "res://CORE/Assets/Art/Home/Deck/card_classic.png")
	frame.texture = load(frame_path)
	frame.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame.stretch_mode = TextureRect.STRETCH_SCALE
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.position = Vector2.ZERO
	frame.size = Vector2(cw, ch)
	card.add_child(frame)
	# Cubo PICCOLO, CENTRATO in orizzontale nella parte alta (aspetto conservato, omogeneo).
	# expand_mode IGNORE_SIZE: il TextureRect rispetta la size piccola (altrimenti usa quella
	# nativa della texture e trabocca a destra, enorme).
	var cube := TextureRect.new()
	cube.texture = load(_skin_static_for(c.get("name", ""), c["tex"]))
	cube.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	cube.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cube.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	cube.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cube.position = Vector2(cw * 0.24, ch * 0.16)   # un po' più grande e più basso
	cube.size = Vector2(cw * 0.52, ch * 0.36)
	card.add_child(cube)
	# FRECCE: nella card il cubo alterna tutti i colori (come una gif di preview)
	var cname: String = c.get("name", "")
	# la FRECCIA ORIZZONTALE mostra la grafica ruotata di 90° (il frame è "verticale")
	if cname == "FRECCIA ORIZ.":
		cube.pivot_offset = cube.size * 0.5
		cube.rotation = deg_to_rad(90.0)
	if cname == "FRECCIA VERT." or cname == "FRECCIA ORIZ.":
		var plus_n := 2 if cname == "FRECCIA ORIZ." else 1
		var idx := {"v": 0}
		var tmr := Timer.new()
		tmr.wait_time = 0.5
		tmr.one_shot = false
		tmr.autostart = true   # parte da solo quando entra nell'albero (la card non è ancora in tree qui)
		card.add_child(tmr)
		tmr.timeout.connect(func() -> void:
			if not is_instance_valid(cube):
				return
			idx["v"] = (idx["v"] + 1) % DEMO_COLORS.size()
			var col: String = DEMO_COLORS[idx["v"]]
			var ab := "%s_PLUS/%s/ab_1.png" % [CUBES_DIR, col.capitalize()]
			cube.texture = load(ab) if ResourceLoader.exists(ab) else load("%s_PLUS/%s/%s_plus%d.svg" % [CUBES_DIR, col, col, plus_n]))
	# Nome sotto: PIÙ GRANDE (bianco, contorno nero)
	var nm := Label.new()
	nm.text = loc.t(c["name"])
	nm.add_theme_font_override("font", MODE_FONT)
	nm.add_theme_font_size_override("font_size", 26)
	nm.add_theme_color_override("font_color", Color(1, 1, 1))
	nm.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	nm.add_theme_constant_override("outline_size", 6)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	nm.position = Vector2(cw * 0.03, ch * 0.56)
	nm.size = Vector2(cw * 0.94, ch * 0.40)
	card.add_child(nm)
	return card


# Tap su una scheda del deck: apre il popup info-cubo (per ora solo il cubo rosso).
func _on_deck_card_pressed(c: Dictionary) -> void:
	settings.button_feedback()
	var key: String = c.get("name", "")
	if CUBE_INFO.has(key):
		_open_cubeinfo(CUBE_INFO[key])


# ============ POPUP INFO CUBO (stile Clash Royale) ============
func _build_cubeinfo_menu() -> void:
	_ci_layer = CanvasLayer.new()
	_ci_layer.layer = 210   # sopra il deck (200)
	add_child(_ci_layer)
	_ci_menu = Control.new()
	_ci_menu.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ci_menu.visible = false
	_ci_layer.add_child(_ci_menu)
	# dim scuro: tap fuori = chiudi
	_ci_dim = ColorRect.new()
	_ci_dim.color = Color(0.03, 0.06, 0.12, 0.78)
	_ci_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ci_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_ci_dim.gui_input.connect(_on_ci_dim_input)
	_ci_menu.add_child(_ci_dim)
	# pannello (contenuto ricostruito ad ogni apertura)
	_ci_panel = Control.new()
	_ci_panel.size = Vector2(CI_PW, CI_DESIGN_H)
	_ci_menu.add_child(_ci_panel)
	# timer del "video" in loop (placeholder = animazione schermo gameplay)
	_ci_video_timer = Timer.new()
	_ci_video_timer.wait_time = 0.12
	_ci_video_timer.one_shot = false
	add_child(_ci_video_timer)
	_ci_video_timer.timeout.connect(_ci_advance_video)
	# video demo: cubo rosso che fa match in gameplay (loop)
	for i in range(1, 17):
		var p := "res://CORE/Assets/Art/Home/CubeInfo/RedDemo/demo_%02d.png" % i
		if ResourceLoader.exists(p):
			_ci_video_frames.append(load(p))


func _ci_advance_video() -> void:
	if _ci_video == null or _ci_video_frames.is_empty():
		return
	_ci_video_idx = (_ci_video_idx + 1) % _ci_video_frames.size()
	_ci_video.texture = _ci_video_frames[_ci_video_idx]


func _ci_label(text: String, pos: Vector2, sz: Vector2, fsize: int, halign: int, top: bool = false, col: Color = Color(1, 1, 1)) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", MODE_FONT)
	l.add_theme_font_size_override("font_size", fsize)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	l.add_theme_constant_override("outline_size", 5)
	l.horizontal_alignment = halign
	l.vertical_alignment = VERTICAL_ALIGNMENT_TOP if top else VERTICAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.position = pos
	l.size = sz
	_ci_panel.add_child(l)
	return l


# Piccola pressione (affonda + scurisce) per i tasti del popup.
func _ci_press_fx(btn: BaseButton, sink: float = 5.0) -> void:
	var base := btn.position
	btn.button_down.connect(func() -> void:
		btn.position = base + Vector2(0, sink)
		btn.modulate = Color(0.85, 0.85, 0.85))
	btn.button_up.connect(func() -> void:
		btn.position = base
		btn.modulate = Color(1, 1, 1))


func _ci_texbtn(tex: String, pos: Vector2, sz: Vector2, cb: Callable) -> TextureButton:
	var b := TextureButton.new()
	b.texture_normal = load(tex)
	b.ignore_texture_size = true
	b.stretch_mode = TextureButton.STRETCH_SCALE
	b.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	b.position = pos
	b.size = sz
	b.pressed.connect(cb)
	_ci_panel.add_child(b)
	return b


func _ci_texrect(tex: String, pos: Vector2, sz: Vector2, mode: int) -> TextureRect:
	var t := TextureRect.new()
	t.texture = load(tex)
	t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = mode
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.position = pos
	t.size = sz
	_ci_panel.add_child(t)
	return t


# --- Demo "video" live: usa la grafica REALE del gioco (texture cubo + frame di pop) ---
# Un cubo scende/viene trascinato in mezzo a due cubi uguali -> match -> esplosione, in loop.
const DEMO_COLORS := ["Red", "Orange", "Yellow", "Green", "Blue", "Purple", "Pink"]
const CUBES_DIR := "res://CORE/Assets/Art/Game/Cubes/"
const DELETE_FRAMES := [
	preload("res://CORE/Assets/Art/Game/Delete/delete_01.svg"),
	preload("res://CORE/Assets/Art/Game/Delete/delete_02.svg"),
	preload("res://CORE/Assets/Art/Game/Delete/delete_03.svg"),
	preload("res://CORE/Assets/Art/Game/Delete/delete_04.svg"),
	preload("res://CORE/Assets/Art/Game/Delete/delete_05.svg"),
	preload("res://CORE/Assets/Art/Game/Delete/delete_06.svg"),
]

# Crea il container della demo (riempie TUTTO il riquadro video, come il vecchio rettangolo verde).
func _build_ci_demo(info: Dictionary, slot_pos: Vector2, slot_size: Vector2) -> void:
	_ci_demo = Control.new()
	_ci_demo.position = slot_pos
	_ci_demo.size = slot_size
	_ci_demo.clip_contents = true
	_ci_demo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ci_panel.add_child(_ci_demo)
	# sfondo scuro tipo area di gioco (grande quanto il riquadro)
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.14, 0.20)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ci_demo.add_child(bg)
	# area interna (margine) dove disporre i cubi, così non toccano la cornice
	var m := Vector2(slot_size.x * 0.08, slot_size.y * 0.12)
	_ci_demo_rect = Rect2(m, slot_size - m * 2.0)
	_ci_demo_info = info
	_ci_demo_kind = _ci_demo_kind_for(info)


func _ci_demo_kind_for(info: Dictionary) -> String:
	match info.get("name", ""):
		"FRECCIA VERT.": return "beam_v"
		"FRECCIA ORIZ.": return "beam_h"
		"BOMBA": return "bomb3x3"
		"BOMBA X": return "bombx"
		"BOMBA ANGOLI": return "bombangoli"
	return "match"   # tutti i classici


# ---- helper geometria / texture ----
func _ci_grid(cols: int, rows: int) -> Dictionary:
	var r := _ci_demo_rect
	var cell := minf(r.size.x / (cols + 0.3), r.size.y / (rows + 0.3))
	var gw := cell * cols
	var gh := cell * rows
	var ox := r.position.x + (r.size.x - gw) * 0.5 + cell * 0.5
	var oy := r.position.y + (r.size.y - gh) * 0.5 + cell * 0.5
	return {"cell": cell, "cube": cell * 0.94, "ox": ox, "oy": oy}


func _ci_cell_center(g: Dictionary, col: float, row: float) -> Vector2:
	return Vector2(g["ox"] + col * g["cell"], g["oy"] + row * g["cell"])


func _ci_cube_at(center: Vector2, size: float, tex: Texture2D) -> TextureRect:
	var t := TextureRect.new()
	t.texture = tex
	t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.size = Vector2(size, size)
	t.pivot_offset = t.size * 0.5
	t.position = center - t.size * 0.5
	_ci_demo.add_child(t)
	return t


func _ci_base_tex(color: String) -> Texture2D:
	return load("%s%s/%s.svg" % [CUBES_DIR, color, color]) as Texture2D


func _ci_pop_frames(color: String) -> Array:
	var frames: Array = []
	for i in range(2, 8):
		var p := "%s%s/%s_%d.svg" % [CUBES_DIR, color, color, i]
		if ResourceLoader.exists(p):
			frames.append(load(p))
	return frames


# --- SKIN-AWARE: la demo usa la SKIN SELEZIONATA del colore (texture + rottura) ---
# color = nome capitalizzato ("Red"); la skin è indicizzata per color_key minuscolo ("red").
func _ci_skin_static(color: String) -> Texture2D:
	var sk: Dictionary = settings.get_skin(color.to_lower())
	var path: String = sk.get("static", "%s%s/%s.svg" % [CUBES_DIR, color, color])
	return load(path) as Texture2D


# Frame di rottura della skin selezionata (in gameplay è l'animazione "match" della skin).
# Fallback ai frame base del colore se la skin non li definisce.
func _ci_skin_frames(color: String) -> Array:
	var sk: Dictionary = settings.get_skin(color.to_lower())
	var paths: Array = sk.get("frames", [])
	var out: Array = []
	for p in paths:
		if ResourceLoader.exists(p):
			out.append(load(p))
	if out.is_empty():
		out = _ci_pop_frames(color)
	return out


func _ci_anim_frames(pattern: String, n: int) -> Array:
	var frames: Array = []
	for i in range(1, n + 1):
		var p := pattern % i
		if ResourceLoader.exists(p):
			frames.append(load(p))
	return frames


func _ci_beam_frames(color: String) -> Array:
	# beam per colore: SOLO i frame con contenuto (2..7, il resto è trasparente)
	var frames: Array = []
	for i in range(1, 9):
		var p := "res://CORE/Assets/Art/Game/SpecialBeam/%s_%03d.png" % [color.to_lower(), i]
		if ResourceLoader.exists(p):
			frames.append(load(p))
	return frames


# Aggiunge al tween `t` la distruzione sincronizzata dei cubi: guizzo + ciclo frame (pop/delete) + dissolvenza.
func _ci_destroy(t: Tween, cubes: Array, frames: Array) -> void:
	# piccolo guizzo di scala (l'esplosione "sboccia")
	t.tween_callback(func() -> void:
		for c in cubes:
			if is_instance_valid(c):
				c.scale = Vector2(1.2, 1.2))
	if not frames.is_empty():
		for i in frames.size():
			var idx := i
			t.tween_callback(func() -> void:
				for c in cubes:
					if is_instance_valid(c):
						c.texture = frames[idx])
			t.tween_interval(0.05)
	var first := true
	for c in cubes:
		var cc: TextureRect = c
		var fade := t.tween_property(cc, "modulate:a", 0.0, 0.16) if first \
			else t.parallel().tween_property(cc, "modulate:a", 0.0, 0.16)
		fade.set_ease(Tween.EASE_IN)
		t.parallel().tween_property(cc, "scale", Vector2(0.3, 0.3), 0.16).set_ease(Tween.EASE_IN)
		first = false


# ---- ciclo demo (un ciclo per volta, si riavvia da solo variando il colore) ----
func _ci_demo_start() -> void:
	if _ci_demo == null:
		return
	_ci_demo_stop()
	_ci_demo_running = true
	_ci_demo_color_idx = 0
	_ci_demo_cycle()


func _ci_demo_stop() -> void:
	_ci_demo_running = false
	if _ci_demo_tween and _ci_demo_tween.is_valid():
		_ci_demo_tween.kill()
	_ci_demo_tween = null


func _ci_demo_next() -> void:
	if not _ci_demo_running:
		return
	_ci_demo_color_idx += 1
	_ci_demo_cycle()


func _ci_demo_clear() -> void:
	# rimuove i cubi ma tiene lo sfondo (primo figlio)
	for i in range(_ci_demo.get_child_count() - 1, 0, -1):
		var ch := _ci_demo.get_child(i)
		_ci_demo.remove_child(ch)
		ch.free()


func _ci_demo_cycle() -> void:
	if not _ci_demo_running or _ci_demo == null or not is_instance_valid(_ci_demo):
		return
	_ci_demo_clear()
	var t := create_tween()
	match _ci_demo_kind:
		"beam_v": _ci_cycle_beam(t, false)
		"beam_h": _ci_cycle_beam(t, true)
		"bomb3x3": _ci_cycle_bomb(t, "3x3")
		"bombx": _ci_cycle_bomb(t, "x")
		"bombangoli": _ci_cycle_bomb(t, "angoli")
		_: _ci_cycle_match(t)
	t.tween_interval(0.55)
	t.tween_callback(_ci_demo_next)
	_ci_demo_tween = t


# CLASSICI: cubo trascinato in mezzo a due dello stesso colore -> match -> pop.
func _ci_cycle_match(t: Tween) -> void:
	var color := _ci_color_from_path(_ci_demo_info.get("cube", ""))
	var base := _ci_skin_static(color)
	var pop := _ci_skin_frames(color)
	var g := _ci_grid(3, 1)
	var size: float = g["cube"]
	var left := _ci_cube_at(_ci_cell_center(g, 0, 0), size, base)
	var right := _ci_cube_at(_ci_cell_center(g, 2, 0), size, base)
	var mid_c := _ci_cell_center(g, 1, 0)
	var start_c := Vector2(mid_c.x, _ci_demo.size.y + size)   # sotto, clippato
	var drop := _ci_cube_at(start_c, size, base)
	t.tween_interval(0.4)
	t.tween_property(drop, "position", mid_c - drop.size * 0.5, 0.5) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(drop, "scale", Vector2(1.12, 1.12), 0.1).set_ease(Tween.EASE_OUT)
	t.tween_property(drop, "scale", Vector2.ONE, 0.12)
	t.tween_interval(0.12)
	_ci_destroy(t, [left, right, drop], pop)


# FRECCE: griglia 5x5, freccia al centro (colore ciclato). Il beam LUNGO percorre tutta
# la COLONNA (verticale) o RIGA (orizzontale); i cubi vicini restano.
func _ci_cycle_beam(t: Tween, horizontal: bool) -> void:
	var color: String = DEMO_COLORS[_ci_demo_color_idx % DEMO_COLORS.size()]
	var plus_n := 2 if horizontal else 1
	# freccia = nuovo cubo-abilità (ab_1) col fallback all'SVG se il colore non ha i frame
	var ab_path := "%s_PLUS/%s/ab_1.png" % [CUBES_DIR, color.capitalize()]
	var arrow: Texture2D = load(ab_path) if ResourceLoader.exists(ab_path) else load("%s_PLUS/%s/%s_plus%d.svg" % [CUBES_DIR, color, color, plus_n])
	var N := 5
	var mid := 2
	var g := _ci_grid(N, N)
	var size: float = g["cube"]
	var line: Array = []      # cubi della colonna/riga colpita
	for row in N:
		for col in N:
			var on_line := (row == mid) if horizontal else (col == mid)
			var is_center := col == mid and row == mid
			var tex: Texture2D
			if is_center:
				tex = arrow
			elif on_line:
				tex = _ci_skin_static(color)   # la linea colpita è del colore della freccia (skin selezionata)
			else:
				tex = _ci_skin_static(DEMO_COLORS[(_ci_demo_color_idx + col + row * 2 + 3) % DEMO_COLORS.size()])
			var cube := _ci_cube_at(_ci_cell_center(g, col, row), size, tex)
			# freccia ORIZZONTALE: cubo ruotato di 90° (il frame è "verticale")
			if is_center and horizontal:
				cube.pivot_offset = cube.size * 0.5
				cube.rotation = PI / 2.0
			if on_line:
				line.append(cube)
	# beam colorato lungo TUTTA la linea (N celle), animato a frame
	var beam := TextureRect.new()
	beam.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	beam.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	beam.stretch_mode = TextureRect.STRETCH_SCALE
	beam.mouse_filter = Control.MOUSE_FILTER_IGNORE
	beam.modulate = Color(1, 1, 1, 0)
	var line_center := _ci_cell_center(g, mid, mid)
	beam.size = Vector2(size * 1.35, g["cell"] * N)
	beam.pivot_offset = beam.size * 0.5
	beam.position = line_center - beam.size * 0.5
	if horizontal:
		beam.rotation = PI / 2.0
	var beam_frames := _ci_beam_frames(color)
	if not beam_frames.is_empty():
		beam.texture = beam_frames[0]
	_ci_demo.add_child(beam)
	t.tween_interval(0.45)
	# accendi il beam e scorri i frame (2..7 = quelli con contenuto)
	t.tween_callback(func() -> void:
		if is_instance_valid(beam): beam.modulate.a = 1.0)
	for i in beam_frames.size():
		var idx := i
		t.tween_callback(func() -> void:
			if is_instance_valid(beam): beam.texture = beam_frames[idx])
		t.tween_interval(0.05)
	# i cubi della linea si ROMPONO con l'animazione match della SKIN (non il Delete delle bombe)
	t.parallel().tween_property(beam, "modulate:a", 0.0, 0.22)
	_ci_destroy(t, line, _ci_skin_frames(color))


# BOMBE: griglia 5x5 di cubi + bomba al centro che esplode con la sua animazione.
# 3x3 = area 3x3 attorno; X = diagonali complete; angoli = i 4 angoli estremi dell'area.
func _ci_cycle_bomb(t: Tween, mode: String) -> void:
	var N := 5
	var mid := 2
	var g := _ci_grid(N, N)
	var size: float = g["cube"]
	# cubi di contorno con colori variati (tutti tranne il centro)
	var cells: Dictionary = {}   # "col,row" -> TextureRect
	for row in N:
		for col in N:
			if col == mid and row == mid:
				continue
			var color: String = DEMO_COLORS[(_ci_demo_color_idx + col + row * 3) % DEMO_COLORS.size()]
			cells["%d,%d" % [col, row]] = _ci_cube_at(_ci_cell_center(g, col, row), size, _ci_skin_static(color))
	# bomba al centro (leggermente più grande) + frame di animazione
	var anim: Array = []
	match mode:
		"3x3": anim = _ci_anim_frames("res://CORE/Assets/Art/Game/Cubes/_PLUS/Bomb/bomb_%d.png", 6)
		"x": anim = _ci_anim_frames("res://CORE/Assets/Art/Game/Cubes/_XBOMB/Anim/xbomb_%d.png", 6)
		"angoli": anim = _ci_anim_frames("res://CORE/Assets/Art/Game/Cubes/_ANGLES/Anim/angles_%d.png", 6)
	var bomb := _ci_cube_at(_ci_cell_center(g, mid, mid), size * 1.08, anim[0] if not anim.is_empty() else null)
	# quali celle vengono distrutte
	var hit_keys: Array = []
	match mode:
		"3x3":
			for r in [1, 2, 3]:
				for c in [1, 2, 3]:
					hit_keys.append("%d,%d" % [c, r])
		"x":
			for i in N:
				hit_keys.append("%d,%d" % [i, i])          # diagonale \
				hit_keys.append("%d,%d" % [i, N - 1 - i])  # diagonale /
		"angoli":
			# come nel gameplay: ogni angolo rompe 3 cubi a L
			var w1 := N - 1
			for corner in [
				[Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1)],
				[Vector2i(w1, 0), Vector2i(w1 - 1, 0), Vector2i(w1, 1)],
				[Vector2i(0, w1), Vector2i(1, w1), Vector2i(0, w1 - 1)],
				[Vector2i(w1, w1), Vector2i(w1 - 1, w1), Vector2i(w1, w1 - 1)],
			]:
				for cc in corner:
					hit_keys.append("%d,%d" % [cc.x, cc.y])
	var hit: Array = []
	for k in hit_keys:
		if cells.has(k):
			hit.append(cells[k])
	t.tween_interval(0.45)
	# animazione della bomba
	for i in anim.size():
		var idx := i
		t.tween_callback(func() -> void:
			if is_instance_valid(bomb): bomb.texture = anim[idx])
		t.tween_interval(0.07)
	# esplosione: cubi colpiti + bomba svaniscono con il "delete"
	_ci_destroy(t, hit + [bomb], DELETE_FRAMES)


# Colore ("Red"/"Blue"/...) dal path della texture di un cubo classico.
func _ci_color_from_path(path: String) -> String:
	for col in DEMO_COLORS:
		if String(path).find("/%s/%s" % [col, col]) != -1:
			return col
	return "Red"


const CI_DIR := "res://CORE/Assets/Art/Home/CubeInfo/"

func _build_cubeinfo_content(info: Dictionary) -> void:
	# cornice
	_ci_texrect(CI_DIR + "popup_frame.png", Vector2(0, 0), Vector2(CI_PW, CI_PH), TextureRect.STRETCH_SCALE)
	# titolo CUBE INFO CENTRATO nel frame (più grande), alla stessa altezza della X
	_ci_label(loc.t("CUBE INFO"), Vector2(CI_PW * 0.5 - 180.0, 20.0), Vector2(360.0, 78.0), 46, HORIZONTAL_ALIGNMENT_CENTER)
	# tasto X in alto a destra
	var xbtn := _ci_texbtn(CI_DIR + "close_x.png", Vector2(CI_PW - 92.0, 24.0), Vector2(72.0, 72.0), _close_cubeinfo)
	_ci_press_fx(xbtn, 4.0)

	# --- sezione alta (un po' più in basso): cubo grande a sx, nome/tipo/descrizione a dx ---
	_ci_cur_info = info
	var cur_static := _skin_static_for(info["name"], info["cube"])
	_ci_preview = _ci_texrect(cur_static, Vector2(40.0, 132.0), Vector2(206.0, 206.0), TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
	# FRECCIA ORIZZONTALE: anteprima ruotata di 90° (il frame è "verticale")
	if str(info.get("name", "")) == "FRECCIA ORIZ.":
		_ci_preview.pivot_offset = _ci_preview.size * 0.5
		_ci_preview.rotation = deg_to_rad(90.0)
	var rx := 280.0
	var rw := CI_PW - rx - 38.0
	var name_col: Color = info.get("color", Color(1, 1, 1))
	_ci_label(loc.t(info["name"]), Vector2(rx, 138.0), Vector2(rw, 58.0), 48, HORIZONTAL_ALIGNMENT_LEFT, false, name_col)
	_ci_label(loc.t("TIPO:") + " " + loc.t(info["type"]), Vector2(rx, 202.0), Vector2(rw, 42.0), 32, HORIZONTAL_ALIGNMENT_LEFT)
	_ci_label(loc.t(info["desc"]), Vector2(rx, 250.0), Vector2(rw, 110.0), 22, HORIZONTAL_ALIGNMENT_LEFT, true)

	# --- sezione video: riquadro VERDE pieno + BORDO (interno trasparente) sopra ---
	# (l'animazione la fornirà l'utente; il verde serve solo per allineare)
	var vw := 540.0                    # sezione video un po' più piccola
	var vh := vw * 0.5                 # aspetto del bordo 2:1
	var vx := (CI_PW - vw) * 0.5
	var vy := 376.0
	_ci_video = null
	_ci_demo = null
	# demo live per OGNI cubo: classici = match; frecce = beam V/O (colori ciclati);
	# bombe = 3x3 / X / angoli con le loro animazioni. Riempie tutto il riquadro video.
	_build_ci_demo(info, Vector2(vx, vy), Vector2(vw, vh))
	# bordo navy (interno trasparente) sopra la demo
	_ci_texrect(CI_DIR + "video_border.png", Vector2(vx, vy), Vector2(vw, vh), TextureRect.STRETCH_SCALE)

	# --- sezione skin (spunta verde sulla selezionata; tap = animazione) ---
	var sy := vy + vh + 2.0
	_ci_label(loc.t("SKIN"), Vector2(52.0, sy), Vector2(340.0, 56.0), 46, HORIZONTAL_ALIGNMENT_LEFT)
	var slot := 150.0
	var slot_h := slot * (368.0 / 352.0)
	var slot_y := sy + 60.0
	var ck: String = info.get("color_key", "")
	var skins: Array = settings.CUBE_SKINS.get(ck, [])
	if skins.is_empty():   # abilità: solo skin base (l'immagine del cubo stesso)
		skins = [{"static": info["cube"], "frames": []}]
	_ci_skin_slots.clear()
	for i in skins.size():
		var sd: Dictionary = skins[i]
		var sx := 56.0 + float(i) * (slot + 20.0)
		var owned := _is_skin_owned(ck, i)
		var sb := TextureButton.new()
		sb.texture_normal = load(CI_DIR + "skin_frame.png")
		sb.ignore_texture_size = true
		sb.stretch_mode = TextureButton.STRETCH_SCALE
		sb.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sb.position = Vector2(sx, slot_y)
		sb.size = Vector2(slot, slot_h)
		sb.pivot_offset = Vector2(slot * 0.5, slot_h * 0.5)
		sb.pressed.connect(_ci_select_skin.bind(i))
		_ci_panel.add_child(sb)
		var cu := TextureRect.new()
		cu.texture = load(sd["static"])
		cu.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		cu.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		cu.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		cu.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cu.position = Vector2(slot * 0.2, slot_h * 0.18)
		cu.size = Vector2(slot * 0.6, slot_h * 0.55)
		sb.add_child(cu)
		# skin NON posseduta (comprabile nello shop): b/n + lucchetto, non selezionabile
		if not owned:
			cu.material = _gray_material()
			var lock := _make_lock_overlay()
			sb.add_child(lock)
		_ci_skin_slots.append({"btn": sb, "cube": cu, "data": sd, "owned": owned})
	# spunta verde UNICA, sulla skin selezionata (spostabile)
	_ci_check = TextureRect.new()
	_ci_check.texture = load(CI_DIR + "skin_check.png")
	_ci_check.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_ci_check.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_ci_check.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_ci_check.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ci_check.size = Vector2(58.0, 58.0)
	var sel: int = settings.get_skin_index(ck)
	if not _is_skin_owned(ck, sel):   # skin non più/non posseduta -> torna al default
		sel = 0
		if ck != "":
			settings.set_skin(ck, 0)
	_ci_place_check(clampi(sel, 0, maxi(skins.size() - 1, 0)))

	# --- tasto OK (sporge sotto la cornice, alzato un po') ---
	var okw := 300.0
	var okh := okw * (288.0 / 736.0)
	_ci_ok_btn = _ci_texbtn(CI_DIR + "ok_button.png", Vector2((CI_PW - okw) * 0.5, CI_PH - 72.0), Vector2(okw, okh), _on_ci_ok)
	_ci_ok_btn.pivot_offset = Vector2(okw * 0.5, okh * 0.5)


# Selezione skin: sposta la spunta, riproduce l'animazione di distruzione della skin,
# aggiorna la preview in alto e il cubo nel deck.
# Skin posseduta? La skin di DEFAULT (idx 0) è sempre disponibile; le altre vanno
# comprate nello shop (shop.owns_skin("sk_"+colore)).
func _is_skin_owned(ck: String, idx: int) -> bool:
	if idx <= 0:
		return true
	return shop.owns_skin("sk_" + ck)

# ShaderMaterial grayscale (una volta) per le skin non possedute.
func _gray_material() -> ShaderMaterial:
	if _gray_mat != null:
		return _gray_mat
	var sh := Shader.new()
	sh.code = "shader_type canvas_item;\nvoid fragment() {\n\tvec4 c = texture(TEXTURE, UV);\n\tfloat g = dot(c.rgb, vec3(0.299, 0.587, 0.114));\n\tCOLOR = vec4(vec3(g), c.a);\n}\n"
	_gray_mat = ShaderMaterial.new()
	_gray_mat.shader = sh
	return _gray_mat

func _ci_select_skin(idx: int) -> void:
	if idx < 0 or idx >= _ci_skin_slots.size():
		return
	# skin non posseduta: non selezionabile (va comprata nello shop)
	if not bool(_ci_skin_slots[idx].get("owned", true)):
		settings.vibrate(20)
		return
	settings.button_feedback()
	var ck: String = _ci_cur_info.get("color_key", "")
	if ck != "":
		settings.set_skin(ck, idx)
	_ci_place_check(idx)
	var slot: Dictionary = _ci_skin_slots[idx]
	# l'animazione di distruzione usa i "frames" della skin (classica = Red..Red_7)
	_ci_play_destroy(slot["cube"], slot["data"].get("frames", []), slot["data"]["static"])
	if _ci_preview:
		_ci_preview.texture = load(slot["data"]["static"])
	_layout_deck()   # aggiorna il cubo nel deck dietro
	_ci_demo_start()   # riavvia la demo con la nuova skin (texture + rottura)


# Riproduce l'animazione di distruzione (frame) nel TextureRect, poi torna allo static.
# Se non ci sono frame, fa solo un rimbalzo.
func _ci_play_destroy(rect: TextureRect, frames: Array, static_path: String) -> void:
	if frames.is_empty():
		rect.pivot_offset = rect.size * 0.5
		var b := create_tween()
		b.tween_property(rect, "scale", Vector2(1.18, 1.18), 0.08).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		b.tween_property(rect, "scale", Vector2(1, 1), 0.18).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		return
	var tw := create_tween()
	for f in frames:
		var path: String = f
		tw.tween_callback(func() -> void: rect.texture = load(path))
		tw.tween_interval(0.07)
	tw.tween_callback(func() -> void: rect.texture = load(static_path))


func _ci_place_check(idx: int) -> void:
	if _ci_check == null or idx < 0 or idx >= _ci_skin_slots.size():
		return
	var p := _ci_check.get_parent()
	if p:
		p.remove_child(_ci_check)
	var slot: TextureButton = _ci_skin_slots[idx]["btn"]
	slot.add_child(_ci_check)
	_ci_check.position = Vector2(slot.size.x - 44.0, -16.0)


# Skin selezionata -> percorso immagine statica (per deck/preview). Fallback = default.
func _skin_static_for(name: String, default_tex: String) -> String:
	if CUBE_INFO.has(name):
		var ck: String = CUBE_INFO[name].get("color_key", "")
		if ck != "":
			var sk: Dictionary = settings.get_skin(ck)
			if not sk.is_empty():
				return sk["static"]
	return default_tex


func _open_cubeinfo(info: Dictionary) -> void:
	if _ci_menu == null:
		return
	for ch in _ci_panel.get_children():
		_ci_panel.remove_child(ch)
		ch.queue_free()
	_build_cubeinfo_content(info)
	_ci_menu.visible = true
	_layout_cubeinfo()
	# video loop
	_ci_video_idx = 0
	if _ci_video and not _ci_video_frames.is_empty():
		_ci_video_timer.start()
	# demo live (cubi classici): avvia il loop gameplay
	_ci_demo_start()
	# pop-in dal centro
	if _ci_anim and _ci_anim.is_valid():
		_ci_anim.kill()
	var target := _ci_panel.scale
	_ci_panel.scale = target * 0.85
	_ci_dim.color.a = 0.0
	_ci_anim = create_tween()
	_ci_anim.tween_property(_ci_panel, "scale", target, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_ci_anim.parallel().tween_property(_ci_dim, "color:a", 0.78, 0.20)


func _close_cubeinfo() -> void:
	if _ci_menu == null or not _ci_menu.visible:
		return
	settings.button_feedback()
	_ci_video_timer.stop()
	_ci_demo_stop()
	if _ci_anim and _ci_anim.is_valid():
		_ci_anim.kill()
	var target := _ci_panel.scale
	_ci_anim = create_tween()
	_ci_anim.tween_property(_ci_panel, "scale", target * 0.85, 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_ci_anim.parallel().tween_property(_ci_dim, "color:a", 0.0, 0.16)
	_ci_anim.chain().tween_callback(func() -> void: _ci_menu.visible = false)


func _on_ci_ok() -> void:
	# animazione del tasto OK, poi conferma (per ora chiude)
	if _ci_ok_btn:
		var t := create_tween()
		t.tween_property(_ci_ok_btn, "scale", Vector2(1.12, 1.12), 0.07).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		t.tween_property(_ci_ok_btn, "scale", Vector2(1, 1), 0.10).set_trans(Tween.TRANS_SINE)
		t.tween_callback(_close_cubeinfo)
	else:
		_close_cubeinfo()


func _on_ci_dim_input(event: InputEvent) -> void:
	var tap: bool = (event is InputEventMouseButton and not event.pressed) \
		or (event is InputEventScreenTouch and not event.pressed)
	if tap:
		_close_cubeinfo()


func _layout_cubeinfo() -> void:
	if _ci_panel == null:
		return
	var view := get_viewport_rect().size
	var sc := minf(view.x * 0.92 / CI_PW, view.y * 0.96 / CI_DESIGN_H)
	_ci_panel.pivot_offset = Vector2(CI_PW * 0.5, CI_DESIGN_H * 0.5)
	# centrato ma un filo più in basso
	_ci_panel.position = view * 0.5 - _ci_panel.pivot_offset + Vector2(0, view.y * 0.03)
	if not (_ci_anim and _ci_anim.is_valid()):
		_ci_panel.scale = Vector2(sc, sc)


func _on_deck_dim_input(event: InputEvent) -> void:
	var tap: bool = (event is InputEventMouseButton and not event.pressed) \
		or (event is InputEventScreenTouch and not event.pressed)
	if tap:
		settings.button_feedback()
		_close_deck()


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

	# CONTATORE STELLE: solo in STORY, nella stessa posizione del contatore record
	_home_star_bar = TextureRect.new()
	_home_star_bar.texture = load("res://CORE/Assets/Art/Home/star_counter_home.png")
	_home_star_bar.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_home_star_bar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_home_star_bar.stretch_mode = TextureRect.STRETCH_SCALE
	_home_star_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# stessa posizione del contatore RECORD (punti classic/speedrun), che nascondo in story
	_home_star_bar.size = Vector2(REC_CLASSIC_W, COUNTER_H)
	_home_star_bar.position = Vector2(RECORD_X, COUNTER_Y)
	_home_star_bar.visible = false
	add_child(_home_star_bar)
	_home_star_label = Label.new()
	_home_star_label.add_theme_font_override("font", MODE_FONT)
	_home_star_label.add_theme_font_size_override("font_size", 26)
	_home_star_label.add_theme_color_override("font_color", Color(1, 1, 1))
	_home_star_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_home_star_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_home_star_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_home_star_label.position = Vector2(REC_CLASSIC_W * 0.20, 0.0)
	_home_star_label.size = Vector2(REC_CLASSIC_W * 0.80, COUNTER_H)
	_home_star_bar.add_child(_home_star_label)

	# CLASSIFICA (trofeo) — spostata a sinistra per far posto al tasto NEWS
	_leader_btn = _make_icon_button("res://CORE/Assets/Art/UI/Menu/leaderboard.png", Vector2(302.0, 74.0), 78.0)
	_leader_btn.pressed.connect(_on_leaderboard_pressed)
	# NEWS/RINGRAZIAMENTI (tra classifica e impostazioni) -> apre la schermata thanks
	_news_btn = _make_icon_button("res://CORE/Assets/Art/UI/Menu/news_icon.png", Vector2(388.0, 74.0), 78.0)
	_news_btn.pressed.connect(_on_news_pressed)
	# IMPOSTAZIONI (nuova icona)
	_settings_btn2 = _make_icon_button("res://CORE/Assets/Art/UI/Menu/settings_new.png", Vector2(474.0, 74.0), 78.0)
	_settings_btn2.pressed.connect(_on_settings_button_pressed)

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
	_name_edit.max_length = 14
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
	_name_edit.position = _name_frame.position + Vector2(nf_w * 0.14, nf_h * 0.18)
	_name_edit.size = Vector2(nf_w * 0.84, nf_h * 0.50)
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
	# aggiorna SUBITO nome/icona sulla classifica online (anche con 0 punti, purché
	# il giocatore abbia già una voce): niente più attesa fino a fine partita
	leaderboard.push_profile()


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
	_profile_title.text = loc.t("EDIT PROFILE")
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
	_profile_name_title.text = loc.t("NOME GIOCATORE")
	_profile_name_title.add_theme_font_override("font", MODE_FONT)
	_profile_name_title.add_theme_color_override("font_color", Color(1, 1, 1))
	_profile_name_title.add_theme_color_override("font_outline_color", Color(0.16, 0.07, 0.0))
	_profile_name_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_profile_name_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_profile_frame.add_child(_profile_name_title)
	_profile_name_edit = LineEdit.new()
	_profile_name_edit.max_length = 14
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
	_profile_grid.mouse_filter = Control.MOUSE_FILTER_PASS   # non blocca il drag-scroll
	_profile_scroll.add_child(_profile_grid)
	for i in PROFILE_ICONS.size():
		# icone bloccate: mostra la versione B/N finché non sono sbloccate
		var locked := _is_profile_icon_locked(i)
		var tex_path: String = _profile_icon_bw(i) if locked else PROFILE_ICONS[i]
		var b := _ptbtn(tex_path, _select_profile_icon.bind(i))
		b.disabled = locked   # bloccata: non cliccabile
		b.clip_contents = false
		b.mouse_filter = Control.MOUSE_FILTER_PASS   # il drag scorre, il tap seleziona
		_profile_grid.add_child(b)
		_profile_icon_btns.append(b)
		# lucchetto pixel-art sopra all'icona (visibile solo se bloccata)
		var lock := _make_lock_overlay()
		lock.visible = locked
		b.add_child(lock)
		_profile_lock_overlays.append(lock)
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
	# frame selezione icone (come prima)
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
	_reset_name_title()
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
	# se questo giocatore è un OG: sblocca l'icona OG + tag [OG]
	if _is_og(_player_name):
		if missions.unlock_icon("og") and _profile_icon_btns.size() > 0:
			_update_profile_selection()
	# aggiorna il tag [OG] sul nome in home
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
	# icone SHOP: bloccate finché non le compri nello shop
	if PROFILE_ICON_SHOP.has(i):
		return not shop.owns_avatar(str(PROFILE_ICON_SHOP[i]))
	if not PROFILE_ICON_LOCK.has(i):
		return false
	return not missions.is_icon_unlocked(str(PROFILE_ICON_LOCK[i]))

func _profile_icon_bw(i: int) -> String:
	return PROFILE_ICONS[i].replace(".png", "_bw.png")

# Overlay (velo scuro + lucchetto pixel-art) da mettere sopra un'icona bloccata.
func _make_lock_overlay() -> Control:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# (niente velo scuro: solo il lucchetto sopra l'icona già in B/N)
	var tr := TextureRect.new()
	tr.texture = _make_lock_texture()
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST   # pixel netti
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# riquadro centrato ~58% della cella
	tr.anchor_left = 0.21
	tr.anchor_right = 0.79
	tr.anchor_top = 0.21
	tr.anchor_bottom = 0.79
	root.add_child(tr)
	return root

# Lucchetto pixel-art 16x16 generato in codice (nessun asset da importare).
func _make_lock_texture() -> ImageTexture:
	if _lock_tex != null:
		return _lock_tex
	var rows := [
		"................",
		".....######.....",
		"....##....##....",
		"....##....##....",
		"....##....##....",
		"....##....##....",
		"..############..",
		"..#oooooooooo#..",
		"..#oooooooooo#..",
		"..#oooo##oooo#..",
		"..#oooo##oooo#..",
		"..#oooo##oooo#..",
		"..#oooooooooo#..",
		"..#oooooooooo#..",
		"..############..",
		"................",
	]
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var white := Color(1, 1, 1, 1)
	var dark := Color(0.05, 0.05, 0.09, 1)
	for y in rows.size():
		var line: String = rows[y]
		for x in line.length():
			var ch: String = line[x]
			if ch == "#":
				img.set_pixel(x, y, dark)
			elif ch == "o":
				img.set_pixel(x, y, white)
	_lock_tex = ImageTexture.create_from_image(img)
	return _lock_tex

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
		# lucchetto: visibile solo finché l'icona è bloccata
		if k < _profile_lock_overlays.size():
			_profile_lock_overlays[k].visible = locked
	if _profile_prev:
		_profile_prev.texture = load(PROFILE_ICONS[clampi(_profile_sel_index, 0, PROFILE_ICONS.size() - 1)])

func _profile_edit_name() -> void:
	settings.button_feedback()
	_reset_name_title()
	if _profile_name_edit:
		# SVUOTA il campo: così la tastiera iOS parte da 0 e puoi scrivere un nome pieno
		# (col vecchio testo la tastiera nativa lasciava aggiungere solo pochi caratteri).
		_profile_name_edit.placeholder_text = _player_name   # mostra com'era
		_profile_name_edit.clear()
		_profile_name_edit.grab_focus()

func _reset_name_title() -> void:
	if _profile_name_title:
		_profile_name_title.text = loc.t("NOME GIOCATORE")
		_profile_name_title.add_theme_color_override("font_color", Color(1, 1, 1))

func _confirm_profile() -> void:
	settings.button_feedback()
	# nome (se lasci vuoto tieni quello attuale, non resettare a un nome a caso)
	var n := _profile_name_edit.text.strip_edges()
	if n == "":
		n = _player_name if _player_name.strip_edges() != "" else _default_player_name()
	# nome invariato → nessun controllo unicità, applica e chiudi
	if n == _player_name:
		_apply_profile(n)
		return
	# nome CAMBIATO → controllo unicità sul server (async)
	if _profile_name_title:
		_profile_name_title.text = loc.t("CONTROLLO...")
		_profile_name_title.add_theme_color_override("font_color", Color(1, 1, 1))
	if _profile_confirm:
		_profile_confirm.disabled = true
	leaderboard.check_and_claim_name(n, func(ok: bool) -> void:
		if _profile_confirm:
			_profile_confirm.disabled = false
		if ok:
			_apply_profile(n)
		elif _profile_name_title:
			_profile_name_title.text = loc.t("NOME GIA IN USO!")
			_profile_name_title.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
			settings.vibrate(30))

# Applica nome + icona scelti e chiude la schermata.
func _apply_profile(n: String) -> void:
	_player_name = n
	if _name_edit:
		_name_edit.text = _player_name   # aggiorna la home
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
		_coin_label.text = "%d %s" % [v, loc.t("monete")]


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
	_leader_title.text = loc.t("TOP CRASHER")
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
	# la classifica è MENSILE: si azzera all'inizio del mese successivo (fine 31 agosto, ecc.)
	var left := leaderboard.seconds_until_reset()
	return loc.tf("Nuova classifica tra: %dg %02dh", [left / 86400, (left % 86400) / 3600])

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
	# spingi anche nome+icona (anche con 0 punti): così gli ALTRI vedono il tuo nuovo avatar
	leaderboard.push_profile()
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
	# icona profilo (un po' più piccola). Per la PROPRIA riga uso l'icona LOCALE:
	# così il cambio avatar si vede SUBITO in classifica, senza aspettare il server.
	var ic := LB_ROW_H * 0.62
	var icon_idx: int = _profile_icon_index if is_player else int(e["icon"])
	row.add_child(_miss_tex(PROFILE_ICONS[clampi(icon_idx, 0, PROFILE_ICONS.size() - 1)], Vector2(LB_ROW_W * 0.16, (LB_ROW_H - ic) * 0.5), Vector2(ic, ic), true))
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
	title.text = loc.t("SCEGLI MODALITÀ")
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
		t.text = loc.t(m["label"])
		t.add_theme_font_override("font", MODE_FONT)
		t.add_theme_font_size_override("font_size", 42)
		t.add_theme_color_override("font_color", Color(1, 1, 1))
		t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		t.position = Vector2(0, 6)
		t.size = Vector2(w, 50)
		btn.add_child(t)

		var s := Label.new()
		s.text = loc.t(m["sub"])
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
	if _starting:
		return
	_starting = true
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
	_missions_button.text = loc.t("MISSIONI")
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
		_coin_label.text = "%d %s" % [missions.coins, loc.t("monete")]


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
		return loc.tf("Nuove missioni disponibili tra: %dg %02dh", [w / 86400, (w % 86400) / 3600])
	var s := missions.seconds_until_refresh()
	return loc.tf("Nuove missioni disponibili tra: %dh %02dm", [s / 3600, (s % 3600) / 60])


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
	_play_reward_anim("res://CORE/Assets/Art/Home/Profile/profile_%s.png" % icon_id)

# Animazione "premio ottenuto" (icona che rimbalza + "È TUA!"), riusabile per missioni e shop.
func _play_reward_anim(path: String) -> void:
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
	lbl.text = loc.t("È TUA!")
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
		_populate_shop()
		_layout_shop()
	# MUSICA: lo SHOP ha la sua traccia. Cambia SOLO entrando/uscendo dallo shop, in crossfade;
	# home<->missioni non tocca la musica (niente restart). Le tracce riprendono da dove lasciate.
	if tab == "shop" and _prev_tab != "shop":
		settings.play_music(settings.shop_music, settings.MUSIC_FADE, true)
	elif tab != "shop" and _prev_tab == "shop":
		settings.play_music(music_player.stream, settings.MUSIC_FADE, true)
	_prev_tab = tab


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
	# CanvasLayer (screen-space, come le missioni): si adatta a tutto lo schermo
	var layer := CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	_shop_menu = Control.new()
	_shop_menu.set_anchors_preset(Control.PRESET_FULL_RECT)
	_shop_menu.visible = false
	layer.add_child(_shop_menu)

	# sfondo BLU pieno dello shop (#004F87, da "shop sfondo.svg" = riempimento pieno)
	_shop_bg = ColorRect.new()
	_shop_bg.color = Color(0.0, 79.0 / 255.0, 135.0 / 255.0, 1.0)
	_shop_bg.mouse_filter = Control.MOUSE_FILTER_STOP
	_shop_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_shop_menu.add_child(_shop_bg)

	# area SCORREVOLE (barra nascosta ma scrollabile) — sotto la tenda, fino al fondo
	_shop_scroll = ScrollContainer.new()
	_shop_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_shop_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	_shop_scroll.clip_contents = true
	_shop_menu.add_child(_shop_scroll)
	var vb := VBoxContainer.new()
	vb.name = "VB"
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.mouse_filter = Control.MOUSE_FILTER_PASS   # lascia scorrere il drag allo ScrollContainer
	vb.add_theme_constant_override("separation", 14)
	_shop_scroll.add_child(vb)

	# TENDA rossa in alto, attaccata al bordo alto, adattiva a tutta la larghezza
	_shop_curtain = TextureRect.new()
	_shop_curtain.texture = load(SHOP + "tenda_shop.png")
	_shop_curtain.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_shop_curtain.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_shop_curtain.stretch_mode = TextureRect.STRETCH_SCALE
	_shop_curtain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shop_menu.add_child(_shop_curtain)

	# contatori in alto: MONETE a destra + RECORD a sinistra (come home/missioni)
	var scc := _make_counter(_shop_menu, COIN_TEX, COIN_X, COUNTER_Y, COIN_W, COIN_ICON_FRAC)
	_shop_coin_bar = scc[0] as TextureRect
	_shop_coins_label = scc[1] as Label
	var src := _make_record_counter(_shop_menu, RECORD_X)
	_shop_record_bar = src[0] as TextureRect

	# (la scritta "SHOP" è ora il PRIMO elemento scorrevole, aggiunta in _populate_shop)

	# messaggio "monete insufficienti" (nascosto)
	_shop_msg = Label.new()
	_shop_msg.add_theme_font_override("font", MODE_FONT)
	_shop_msg.add_theme_font_size_override("font_size", 30)
	_shop_msg.add_theme_color_override("font_color", Color(1, 0.35, 0.35))
	_shop_msg.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_shop_msg.add_theme_constant_override("outline_size", 6)
	_shop_msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_shop_msg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shop_msg.modulate.a = 0.0
	_shop_menu.add_child(_shop_msg)

	# esiti acquisti in-app (pacchetti monete)
	if not iap.purchase_success.is_connected(_on_iap_success):
		iap.purchase_success.connect(_on_iap_success)
	if not iap.purchase_failed.is_connected(_on_iap_failed):
		iap.purchase_failed.connect(_on_iap_failed)

	_populate_shop()
	_layout_shop()

func _on_iap_success(_index: int) -> void:
	settings.vibrate(30)
	_update_coin_count()
	_flash_shop_msg("ACQUISTO COMPLETATO!")

func _on_iap_failed(_index: int, reason: String) -> void:
	settings.vibrate(60)
	_flash_shop_msg("PROSSIMAMENTE" if reason == "unavailable" else "ACQUISTO NON RIUSCITO")

# Layout responsivo dello shop (chiamato da _layout su ogni resize).
func _layout_shop() -> void:
	if _shop_menu == null:
		return
	var view := get_viewport_rect().size
	# TENDA rossa: bordo ALTO attaccato al bordo superiore (y=0), altezza piena (aspetto 3200x1120)
	var curtain_h := view.x * 1120.0 / 3200.0
	if _shop_curtain:
		_shop_curtain.position = Vector2(0, 0)
		_shop_curtain.size = Vector2(view.x, curtain_h)
	# contatori alla STESSA ALTEZZA della home (allineati via traslazione camera)
	var cam_dx := view.x * 0.5 - CAMERA_CENTER.x
	var cam_dy := view.y * 0.5 - CAMERA_CENTER.y
	if _shop_record_bar:
		_shop_record_bar.position = Vector2(RECORD_X + cam_dx, COUNTER_Y + cam_dy)
	if _shop_coin_bar:
		_shop_coin_bar.position = Vector2(COIN_X + cam_dx, COUNTER_Y + cam_dy)
	if _shop_coins_label:
		_shop_coins_label.position = Vector2(COIN_X + COIN_W * COIN_ICON_FRAC + cam_dx, COUNTER_Y + cam_dy)
	var nav_h := minf(view.x, NAV_MAX_W) * (NAV_TEX.y / NAV_TEX.x)
	# messaggio "monete insufficienti" flottante in basso (sopra la nav bar)
	if _shop_msg:
		_shop_msg.position = Vector2(0, view.y - nav_h - 44.0)
		_shop_msg.size = Vector2(view.x, 30.0)
	# area scorrevole: il CLIP parte DENTRO il corpo della tenda (alzato di `overlap`), così
	# il contenuto che scorre sparisce DIETRO la tenda e non sbuca dal bordo smerlato.
	if _shop_scroll:
		var overlap := curtain_h * 0.22
		var top := curtain_h - overlap
		var side := view.x * 0.06
		var bottom := view.y - nav_h * 0.72
		_shop_scroll.position = Vector2(side, top)
		_shop_scroll.size = Vector2(view.x - side * 2.0, maxf(120.0, bottom - top))
		# il padding in cima riporta la scritta SHOP appena SOTTO il bordo visibile della tenda
		if _shop_top_pad:
			_shop_top_pad.custom_minimum_size = Vector2(0, overlap + 10.0)
		var vb := _shop_scroll.get_node_or_null("VB") as VBoxContainer
		if vb:
			vb.custom_minimum_size = Vector2(_shop_scroll.size.x, 0)

# Linea divisoria tra le sezioni dello shop.
func _shop_divider() -> Control:
	var wrap := Control.new()
	wrap.custom_minimum_size = Vector2(0, 40.0)   # più spazio tra Avatar / Skin / Monete
	wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var line := ColorRect.new()
	line.color = Color(1, 1, 1, 0.22)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.anchor_left = 0.06
	line.anchor_right = 0.94
	line.anchor_top = 0.5
	line.anchor_bottom = 0.5
	line.offset_top = -2.0
	line.offset_bottom = 2.0
	wrap.add_child(line)
	return wrap

func _shop_section_label(txt: String) -> Label:
	var l := Label.new()
	l.text = loc.t(txt)
	l.add_theme_font_override("font", MODE_FONT)
	l.add_theme_font_size_override("font_size", 44)
	l.add_theme_color_override("font_color", Color(1, 0.84, 0.10))
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	l.add_theme_constant_override("outline_size", 8)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.custom_minimum_size = Vector2(0, 60)
	return l

func _shop_grid(items: Array, kind: String) -> GridContainer:
	var g := GridContainer.new()
	g.columns = 3
	g.mouse_filter = Control.MOUSE_FILTER_PASS   # non blocca lo scorrimento
	g.add_theme_constant_override("h_separation", 12)
	g.add_theme_constant_override("v_separation", 16)
	# larghezza card = un terzo dell'area scorrevole (view*0.88, come _layout_shop)
	var view := get_viewport_rect().size
	var scroll_w := view.x * 0.88
	var card_w := (scroll_w - 2.0 * 12.0) / 3.0
	for item in items:
		g.add_child(_make_shop_cell(kind, item, card_w))
	return g

# Card acquistabile: cornice shop_frame.png + icona (avatar/skin) + prezzo con icona coin.
func _make_shop_cell(kind: String, item: Dictionary, card_w: float) -> Control:
	var id := str(item["id"])
	var card_h := card_w / (832.0 / 1280.0)
	var cell := Control.new()
	cell.mouse_filter = Control.MOUSE_FILTER_PASS   # non blocca lo scorrimento
	cell.custom_minimum_size = Vector2(card_w, card_h)
	# cornice BLU per avatar/skin
	var frame := TextureRect.new()
	frame.texture = load(SHOP + "item_frame.png")
	frame.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame.stretch_mode = TextureRect.STRETCH_SCALE
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.position = Vector2.ZERO
	frame.size = Vector2(card_w, card_h)
	cell.add_child(frame)
	# icona (avatar o skin), centrata nella parte alta
	var icon := TextureRect.new()
	icon.texture = load(str(item.get("icon", "")))
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ic := card_w * 0.60
	icon.position = Vector2((card_w - ic) * 0.5, card_h * 0.12)
	icon.size = Vector2(ic, ic)
	cell.add_child(icon)
	# riga prezzo: numero + icona coin, più VICINA all'icona (non a fondo card)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 4)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.position = Vector2(0, card_h * 0.58)
	row.size = Vector2(card_w, card_h * 0.22)
	cell.add_child(row)
	var lbl := Label.new()
	lbl.text = str(int(item["price"]))
	lbl.add_theme_font_override("font", MODE_FONT)
	lbl.add_theme_font_size_override("font_size", 38)
	lbl.add_theme_color_override("font_color", Color(1, 0.84, 0.10))
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	lbl.add_theme_constant_override("outline_size", 6)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(lbl)
	var coin := TextureRect.new()
	coin.texture = load("res://CORE/Assets/Art/UI/Missions/coin_icon.png")
	coin.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	coin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var cs := card_w * 0.26
	coin.custom_minimum_size = Vector2(cs, cs)
	row.add_child(coin)
	# bottone trasparente su tutta la card. PASS: il tap compra, ma il drag passa allo
	# ScrollContainer (così lo scorrimento funziona anche partendo su una card).
	var btn := Button.new()
	btn.flat = true
	btn.mouse_filter = Control.MOUSE_FILTER_PASS
	btn.position = Vector2.ZERO
	btn.size = Vector2(card_w, card_h)
	btn.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	btn.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	btn.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	btn.pressed.connect(_on_shop_item.bind(kind, id))
	cell.add_child(btn)
	return cell

# Testo del countdown di rotazione shop ("NUOVO SHOP TRA Xh Ym").
func _shop_timer_text() -> String:
	var s: int = shop.seconds_until_shop_refresh()
	return "%s %dh %02dm" % [loc.t("NUOVO SHOP TRA"), s / 3600, (s % 3600) / 60]

func _process(_delta: float) -> void:
	if _shop_menu and _shop_menu.visible and _shop_timer_label and is_instance_valid(_shop_timer_label):
		_shop_timer_label.text = _shop_timer_text()

# Ricostruisce le sezioni dello shop mostrando SOLO gli oggetti NON posseduti (quelli
# comprati spariscono). Sezioni vuote nascoste.
func _populate_shop() -> void:
	if _shop_scroll == null:
		return
	var vb := _shop_scroll.get_node_or_null("VB") as VBoxContainer
	if vb == null:
		return
	for ch in vb.get_children():
		vb.remove_child(ch)
		ch.queue_free()
	# padding iniziale: tiene la scritta SHOP SOTTO il bordo della tenda; l'altezza vera
	# la imposta _layout_shop (dipende dalla tenda), così il clip cade dietro la tenda.
	_shop_top_pad = Control.new()
	_shop_top_pad.custom_minimum_size = Vector2(0, 40.0)
	_shop_top_pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(_shop_top_pad)
	# scritta SHOP = PRIMO elemento scorrevole (sotto la tenda, prima di AVATAR)
	var title := Label.new()
	title.text = loc.t("SHOP")
	title.add_theme_font_override("font", MODE_FONT)
	title.add_theme_font_size_override("font_size", 66)
	title.add_theme_color_override("font_color", Color(1, 1, 1))
	title.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	title.add_theme_constant_override("outline_size", 12)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.custom_minimum_size = Vector2(0, 74.0)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(title)
	# timer di rotazione: sotto la scritta SHOP (aggiornato in _process)
	_shop_timer_label = Label.new()
	_shop_timer_label.add_theme_font_override("font", MODE_FONT)
	_shop_timer_label.add_theme_font_size_override("font_size", 24)
	_shop_timer_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.9))
	_shop_timer_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_shop_timer_label.add_theme_constant_override("outline_size", 5)
	_shop_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_shop_timer_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_shop_timer_label.custom_minimum_size = Vector2(0, 30.0)
	_shop_timer_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shop_timer_label.text = _shop_timer_text()
	vb.add_child(_shop_timer_label)
	var first_section := true
	# AVATAR: sono solo 3, quindi sempre tutti (tolti quelli già posseduti)
	var avatars: Array = shop.AVATARS.filter(func(it): return not shop.owns_avatar(str(it["id"])))
	if not avatars.is_empty():
		vb.add_child(_shop_section_label("AVATAR"))
		vb.add_child(_shop_grid(avatars, "avatar"))
		first_section = false
	# SKIN CUBI: SEMPRE 3 skin comprabili del giorno (daily_skins esclude già le possedute)
	var skins: Array = shop.daily_skins()
	if not skins.is_empty():
		if not first_section:
			vb.add_child(_shop_divider())
		vb.add_child(_shop_section_label("SKIN CUBI"))
		vb.add_child(_shop_grid(skins, "skin"))
		first_section = false
	# sezione MONETE: pacchetti acquistabili con soldi veri (€)
	if not first_section:
		vb.add_child(_shop_divider())
	vb.add_child(_shop_section_label("MONETE"))
	vb.add_child(_coin_pack_grid())
	# padding in fondo: l'ultima riga può scorrere BEN sopra la nav bar
	var spacer := Control.new()
	var nav_h := minf(get_viewport_rect().size.x, NAV_MAX_W) * (NAV_TEX.y / NAV_TEX.x)
	spacer.custom_minimum_size = Vector2(0, nav_h + 60.0)
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(spacer)

# Griglia dei pacchetti monete (3 per riga).
func _coin_pack_grid() -> GridContainer:
	var g := GridContainer.new()
	g.columns = 3
	g.mouse_filter = Control.MOUSE_FILTER_PASS
	g.add_theme_constant_override("h_separation", 12)
	g.add_theme_constant_override("v_separation", 16)
	var view := get_viewport_rect().size
	var card_w := (view.x * 0.88 - 2.0 * 12.0) / 3.0
	for i in shop.COIN_PACKS.size():
		g.add_child(_make_coin_pack_cell(shop.COIN_PACKS[i], card_w, i))
	return g

# Card pacchetto monete: cornice + icona coin + quantità + prezzo in €.
func _make_coin_pack_cell(pack: Dictionary, card_w: float, index: int) -> Control:
	var card_h := card_w / (832.0 / 1280.0)
	var cell := Control.new()
	cell.mouse_filter = Control.MOUSE_FILTER_PASS
	cell.custom_minimum_size = Vector2(card_w, card_h)
	# cornice ORO per i pacchetti monete
	var frame := TextureRect.new()
	frame.texture = load(SHOP + "coin_frame.png")
	frame.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame.stretch_mode = TextureRect.STRETCH_SCALE
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.size = Vector2(card_w, card_h)
	cell.add_child(frame)
	# icona coin grande
	var coin := TextureRect.new()
	coin.texture = load("res://CORE/Assets/Art/UI/Missions/coin_icon.png")
	coin.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	coin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	coin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ic := card_w * 0.50
	coin.position = Vector2((card_w - ic) * 0.5, card_h * 0.10)
	coin.size = Vector2(ic, ic)
	cell.add_child(coin)
	# quantità monete
	var amt := Label.new()
	amt.text = str(int(pack["coins"]))
	amt.add_theme_font_override("font", MODE_FONT)
	amt.add_theme_font_size_override("font_size", 32)
	amt.add_theme_color_override("font_color", Color(1, 0.84, 0.10))
	amt.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	amt.add_theme_constant_override("outline_size", 6)
	amt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	amt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	amt.position = Vector2(0, card_h * 0.52)
	amt.size = Vector2(card_w, card_h * 0.16)
	cell.add_child(amt)
	# prezzo in €
	var price := Label.new()
	price.text = str(pack["price"])
	price.add_theme_font_override("font", MODE_FONT)
	price.add_theme_font_size_override("font_size", 34)
	price.add_theme_color_override("font_color", Color(1, 1, 1))
	price.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	price.add_theme_constant_override("outline_size", 6)
	price.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	price.mouse_filter = Control.MOUSE_FILTER_IGNORE
	price.position = Vector2(0, card_h * 0.70)
	price.size = Vector2(card_w, card_h * 0.18)
	cell.add_child(price)
	var btn := Button.new()
	btn.flat = true
	btn.mouse_filter = Control.MOUSE_FILTER_PASS
	btn.size = Vector2(card_w, card_h)
	btn.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	btn.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	btn.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	btn.pressed.connect(_on_coin_pack.bind(index))
	cell.add_child(btn)
	return cell

# Acquisto pacchetto monete via IAP (iap.gd). Il risultato arriva sui segnali dell'autoload
# iap (collegati in _build_shop_menu): success -> monete accreditate, unavailable -> PROSSIMAMENTE.
func _on_coin_pack(index: int) -> void:
	settings.button_feedback()
	iap.purchase(index)

# Path dell'icona di un oggetto (per l'animazione premio all'acquisto).
func _shop_icon(kind: String, id: String) -> String:
	var list: Array = shop.AVATARS if kind == "avatar" else shop.SKINS
	for it in list:
		if str(it["id"]) == id:
			return str(it.get("icon", ""))
	return ""

func _on_shop_item(kind: String, id: String) -> void:
	settings.button_feedback()
	var is_av := kind == "avatar"
	var ok: bool = shop.buy_avatar(id) if is_av else shop.buy_skin(id)
	if ok:
		settings.vibrate(30)
		if is_av:
			shop.equip_avatar(id)   # comprato = subito equipaggiato
		else:
			shop.equip_skin(id)
		_update_coin_count()
		_play_reward_anim(_shop_icon(kind, id))   # animazione "premio ottenuto" (come missioni)
		_populate_shop()                            # l'oggetto comprato sparisce dallo shop
	else:
		settings.vibrate(60)
		_flash_shop_msg("MONETE INSUFFICIENTI!")

func _flash_shop_msg(txt: String) -> void:
	if _shop_msg == null:
		return
	_shop_msg.text = loc.t(txt)
	_shop_msg.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_interval(1.1)
	tw.tween_property(_shop_msg, "modulate:a", 0.0, 0.5)


# ================================================================================
# MODALITÀ STORIA / CAMPAGNA — mappa a livelli (struttura, grafiche provvisorie)
# ================================================================================
func _build_story_map() -> void:
	_story_layer = CanvasLayer.new()
	_story_layer.layer = 40   # sopra la nav bar (10) e gli overlay minori
	add_child(_story_layer)
	_story_map = Control.new()
	_story_map.set_anchors_preset(Control.PRESET_FULL_RECT)
	_story_map.visible = false
	_story_layer.add_child(_story_map)

	# fondo blu tinta unita FISSO (dietro tutto): evita bordi/trasparenze quando lo
	# sfondo a strisce scorrevole non copre (colore = base dell'immagine sotry_back).
	_story_bg_img = ColorRect.new()
	_story_bg_img.color = Color(5.0 / 255.0, 120.0 / 255.0, 236.0 / 255.0)
	_story_bg_img.mouse_filter = Control.MOUSE_FILTER_STOP
	_story_bg_img.set_anchors_preset(Control.PRESET_FULL_RECT)
	_story_map.add_child(_story_bg_img)

	# area SCORREVOLE verticale (barra nascosta): livello 1 in basso, si sale verso l'alto
	_story_scroll = ScrollContainer.new()
	_story_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_story_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	_story_scroll.clip_contents = true
	_story_map.add_child(_story_scroll)

	_story_content = Control.new()
	_story_content.mouse_filter = Control.MOUSE_FILTER_PASS   # lascia scorrere il drag
	# dentro un ScrollContainer verticale il contenuto NON deve espandersi in verticale
	# (altrimenti viene schiacciato all'altezza del viewport e lo scroll si rompe): riempie
	# solo in larghezza, l'altezza la dà custom_minimum_size.
	_story_content.size_flags_horizontal = Control.SIZE_FILL
	_story_content.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_story_scroll.add_child(_story_content)

	# sfondo a strisce blu SCORREVOLE: dentro il contenuto (scorre con le isole), dietro tutto.
	_story_bg_scroll = TextureRect.new()
	_story_bg_scroll.texture = STORY_BG_TEX
	_story_bg_scroll.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_story_bg_scroll.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_story_bg_scroll.stretch_mode = TextureRect.STRETCH_SCALE
	_story_bg_scroll.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_story_content.add_child(_story_bg_scroll)

	# ISOLE-livello 1..STORY_LEVELS: ogni livello è un'isola cliccabile col numero pixelato sopra.
	_story_level_buttons.clear()
	_story_num_labels.clear()
	_story_island_stars.clear()
	for i in STORY_LEVELS:
		var n := i + 1
		var isl := TextureButton.new()
		isl.texture_normal = STORY_ISLAND_TEX
		isl.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST   # pixel art nitida
		isl.ignore_texture_size = true
		isl.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		isl.pivot_offset = Vector2(STORY_ISLAND_W * 0.5, STORY_ISLAND_H * 0.5)   # scala dal centro
		# PASS: il TAP apre il livello, ma il DRAG passa allo ScrollContainer (si scorre anche
		# partendo da un'isola; se ci si ferma e si tocca, apre il livello)
		isl.mouse_filter = Control.MOUSE_FILTER_PASS
		isl.pressed.connect(_on_story_level.bind(n))
		# numero del livello sul pianoro erboso (parte alta dell'isola)
		var lbl := Label.new()
		lbl.text = str(n)
		lbl.add_theme_font_override("font", MODE_FONT)
		lbl.add_theme_font_size_override("font_size", 60)
		lbl.add_theme_color_override("font_color", Color(1, 1, 1))
		lbl.add_theme_color_override("font_outline_color", Color(0.12, 0.09, 0.05))
		lbl.add_theme_constant_override("outline_size", 8)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		isl.add_child(lbl)
		# 3 stelline sotto il numero (stato del livello)
		var srow: Array = []
		for s in 3:
			var sm := TextureRect.new()
			sm.texture = STORY_STAR_EMPTY_TEX
			sm.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			sm.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			sm.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			sm.mouse_filter = Control.MOUSE_FILTER_IGNORE
			isl.add_child(sm)
			srow.append(sm)
		# la stella centrale disegnata per ultima → sopra le laterali (senza z_index
		# globale, che la farebbe sbucare sopra il popup del livello)
		isl.move_child(srow[1], -1)
		_story_island_stars.append(srow)
		_story_content.add_child(isl)
		_story_level_buttons.append(isl)
		_story_num_labels.append(lbl)

	# scritta "NUOVA STAGIONE / IN ARRIVO" sopra l'ultima isola (scorre col contenuto)
	_story_season_lbl = Label.new()
	_story_season_lbl.text = "%s\n%s" % [loc.t("NUOVA STAGIONE"), loc.t("IN ARRIVO")]
	_story_season_lbl.add_theme_font_override("font", MODE_FONT)
	_story_season_lbl.add_theme_font_size_override("font_size", 44)
	_story_season_lbl.add_theme_color_override("font_color", Color(1, 0.92, 0.45))
	_story_season_lbl.add_theme_color_override("font_outline_color", Color(0.12, 0.09, 0.05))
	_story_season_lbl.add_theme_constant_override("outline_size", 8)
	_story_season_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_story_season_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_story_season_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_story_content.add_child(_story_season_lbl)

	# TIMER countdown alla prossima stagione (sotto il testo)
	_story_countdown_lbl = Label.new()
	_story_countdown_lbl.add_theme_font_override("font", MODE_FONT)
	_story_countdown_lbl.add_theme_font_size_override("font_size", 40)
	_story_countdown_lbl.add_theme_color_override("font_color", Color(1, 1, 1))
	_story_countdown_lbl.add_theme_color_override("font_outline_color", Color(0.12, 0.09, 0.05))
	_story_countdown_lbl.add_theme_constant_override("outline_size", 7)
	_story_countdown_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_story_countdown_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_story_countdown_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_story_content.add_child(_story_countdown_lbl)

	# NUVOLE decorative in cima alla mappa, sotto il testo/timer
	_story_clouds = TextureRect.new()
	_story_clouds.texture = STORY_CLOUDS_TEX
	_story_clouds.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_story_clouds.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_story_clouds.stretch_mode = TextureRect.STRETCH_SCALE
	_story_clouds.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_story_content.add_child(_story_clouds)

	# aggiornamento del countdown ogni secondo
	_story_countdown_timer = Timer.new()
	_story_countdown_timer.wait_time = 1.0
	_story_countdown_timer.autostart = true
	_story_countdown_timer.timeout.connect(_update_season_countdown)
	_story_map.add_child(_story_countdown_timer)
	_update_season_countdown()

	# CONTATORE STELLE totali in alto a destra (icona stella + numero), header fisso
	_story_counter_icon = TextureRect.new()
	_story_counter_icon.texture = STORY_STAR_FULL_TEX
	_story_counter_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_story_counter_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_story_counter_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_story_counter_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_story_map.add_child(_story_counter_icon)
	_story_star_counter = Label.new()
	_story_star_counter.add_theme_font_override("font", MODE_FONT)
	_story_star_counter.add_theme_font_size_override("font_size", 40)
	_story_star_counter.add_theme_color_override("font_color", Color(1, 0.92, 0.45))
	_story_star_counter.add_theme_color_override("font_outline_color", Color(0.12, 0.09, 0.05))
	_story_star_counter.add_theme_constant_override("outline_size", 6)
	_story_star_counter.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_story_star_counter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_story_map.add_child(_story_star_counter)

	# header: titolo + tasto indietro (fuori dallo scroll, sempre visibili)
	_story_title = Label.new()
	_story_title.text = loc.t("STORIA")
	_story_title.add_theme_font_override("font", MODE_FONT)
	_story_title.add_theme_font_size_override("font_size", 46)
	_story_title.add_theme_color_override("font_color", Color(1, 1, 1))
	_story_title.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_story_title.add_theme_constant_override("outline_size", 6)
	_story_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_story_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_story_map.add_child(_story_title)

	# tasto INDIETRO = stessa grafica della X di gioco (exit_arrow), stessa altezza
	# (posizione calcolata in _layout_story con la traslazione camera, come la X in partita)
	_story_back = TextureButton.new()
	_story_back.texture_normal = STORY_BACK_TEX
	_story_back.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_story_back.ignore_texture_size = true
	_story_back.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	_story_back.pressed.connect(_close_story_map)
	_story_map.add_child(_story_back)


	# toast (es. "PROSSIMAMENTE" sul tasto GIOCA)
	_story_msg = Label.new()
	_story_msg.add_theme_font_override("font", MODE_FONT)
	_story_msg.add_theme_font_size_override("font_size", 34)
	_story_msg.add_theme_color_override("font_color", Color(1, 0.85, 0.35))
	_story_msg.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_story_msg.add_theme_constant_override("outline_size", 6)
	_story_msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_story_msg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_story_msg.modulate.a = 0.0
	_story_map.add_child(_story_msg)

	_build_story_popup()


func _build_story_popup() -> void:
	_story_popup = Control.new()
	_story_popup.set_anchors_preset(Control.PRESET_FULL_RECT)
	_story_popup.visible = false
	_story_map.add_child(_story_popup)

	# dim: tap fuori dal pannello = chiudi
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(func(e: InputEvent) -> void:
		if (e is InputEventMouseButton and e.pressed) or (e is InputEventScreenTouch and e.pressed):
			_close_story_popup())
	_story_popup.add_child(dim)

	# PANNELLO a DIMENSIONE FISSA (sempre uguale, indipendente dal livello), proporzioni
	# dell'immagine così non si deforma. Centrato sullo schermo.
	var pw := 432.0
	var ph := 862.0   # pannello fisso (alto per immagine grande + caratteristiche + missioni)
	var panel := Control.new()
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -pw * 0.5
	panel.offset_right = pw * 0.5
	panel.offset_top = -ph * 0.5
	panel.offset_bottom = ph * 0.5
	_story_popup.add_child(panel)

	# sfondo 9-patch (riempie il pannello, bordi/angoli non deformati)
	var bg := NinePatchRect.new()
	bg.texture = STORY_POPUP_PANEL_TEX
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	bg.patch_margin_left = 40
	bg.patch_margin_right = 40
	bg.patch_margin_top = 40
	bg.patch_margin_bottom = 40
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.add_child(bg)

	# (X rimossa: si chiude toccando fuori dal pannello)
	# contenuto (VBox) ancorato con margini; offset_top per lasciar spazio alle STELLE grandi
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	vb.anchor_left = 0.0
	vb.anchor_right = 1.0
	vb.anchor_top = 0.0
	vb.anchor_bottom = 1.0
	vb.offset_left = 26
	vb.offset_right = -26
	vb.offset_top = 68
	vb.offset_bottom = -58
	panel.add_child(vb)

	# NUMERO livello, grande ("LIVELLO N")
	_story_pop_num = Label.new()
	_story_pop_num.add_theme_font_override("font", MODE_FONT)
	_story_pop_num.add_theme_font_size_override("font_size", 68)
	_story_pop_num.add_theme_color_override("font_color", Color(1, 1, 1))
	_story_pop_num.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_story_pop_num.add_theme_constant_override("outline_size", 6)
	_story_pop_num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(_story_pop_num)

	# ANTEPRIMA ANIMATA del livello (stile cube deck): griglia N×N coi colori del livello,
	# i cubi compaiono e si distruggono in loop. Riempita in _open_story_level_popup.
	var img_wrap := CenterContainer.new()
	_story_preview_box = Panel.new()
	_story_preview_box.custom_minimum_size = Vector2(336, 250)   # grande e squadrato
	_story_preview_box.clip_contents = true
	var ibs := StyleBoxFlat.new()
	ibs.bg_color = Color(0.04, 0.10, 0.16)
	ibs.set_corner_radius_all(10)
	ibs.set_border_width_all(3)
	ibs.border_color = Color(1, 1, 1, 0.35)
	_story_preview_box.add_theme_stylebox_override("panel", ibs)
	img_wrap.add_child(_story_preview_box)
	vb.add_child(img_wrap)
	# timer che anima l'anteprima (pop di cubi casuali)
	_story_preview_timer = Timer.new()
	_story_preview_timer.wait_time = 0.7
	_story_preview_timer.one_shot = false
	_story_preview_timer.timeout.connect(_story_preview_tick)
	_story_preview_box.add_child(_story_preview_timer)

	# breve descrizione simpatica del livello
	_story_pop_desc = Label.new()
	_story_pop_desc.add_theme_font_override("font", MODE_FONT)
	_story_pop_desc.add_theme_font_size_override("font_size", 24)
	_story_pop_desc.add_theme_color_override("font_color", Color(0.85, 0.92, 1.0))
	_story_pop_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_story_pop_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_story_pop_desc.custom_minimum_size = Vector2(360, 0)
	vb.add_child(_story_pop_desc)

	# CARATTERISTICHE: dimensione griglia + cubi colorati (riempita in _open_story_level_popup)
	_story_pop_stats = VBoxContainer.new()
	_story_pop_stats.alignment = BoxContainer.ALIGNMENT_CENTER
	_story_pop_stats.add_theme_constant_override("separation", 6)
	vb.add_child(_story_pop_stats)

	# MISSIONI: 3 colonne, ognuna con la STELLA (B/N) in alto e SOTTO la quantità da ottenere.
	_story_pop_star_icons.clear()
	_story_pop_star_lbls.clear()
	var miss_row := HBoxContainer.new()
	miss_row.alignment = BoxContainer.ALIGNMENT_CENTER
	miss_row.add_theme_constant_override("separation", 18)
	for i in 3:
		var col := VBoxContainer.new()
		col.alignment = BoxContainer.ALIGNMENT_CENTER
		col.add_theme_constant_override("separation", 3)
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.custom_minimum_size = Vector2(118, 0)
		var ic := TextureRect.new()
		ic.texture = STORY_STAR_EMPTY_TEX      # design stella in bianco e nero
		ic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.custom_minimum_size = Vector2(54, 54)
		ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		col.add_child(ic)
		var ml := Label.new()
		ml.add_theme_font_override("font", MODE_FONT)
		ml.add_theme_font_size_override("font_size", 24)
		ml.add_theme_color_override("font_color", Color(1, 1, 1))     # bianco (colore aggiornato in open)
		ml.add_theme_color_override("font_outline_color", Color(0, 0, 0))
		ml.add_theme_constant_override("outline_size", 5)
		ml.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ml.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		ml.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.add_child(ml)
		miss_row.add_child(col)
		_story_pop_star_icons.append(ic)
		_story_pop_star_lbls.append(ml)
	vb.add_child(miss_row)

	# spinge il PLAY in fondo al pannello
	var play_spacer := Control.new()
	play_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(play_spacer)

	# tasto PLAY in BASSO (immagine, "PLAY" già stampato)
	var play_wrap := CenterContainer.new()
	var play := TextureButton.new()
	play.texture_normal = STORY_PLAY_TEX
	play.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	play.ignore_texture_size = true
	play.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	play.custom_minimum_size = Vector2(230, 90)
	play.focus_mode = Control.FOCUS_NONE
	play.pressed.connect(_on_story_play)
	play_wrap.add_child(play)
	vb.add_child(play_wrap)

	# 3 STELLE MOLTO GRANDI a cavallo del bordo superiore (stile match-3): centrale enorme,
	# laterali grandi; colorate se conquistate, altrimenti in bianco e nero.
	var stars_holder := HBoxContainer.new()
	stars_holder.alignment = BoxContainer.ALIGNMENT_CENTER
	stars_holder.add_theme_constant_override("separation", 2)
	stars_holder.anchor_left = 0.0
	stars_holder.anchor_right = 1.0
	stars_holder.anchor_top = 0.0
	stars_holder.anchor_bottom = 0.0
	stars_holder.offset_top = -56.0    # centro delle stelle sul bordo alto (metà fuori)
	stars_holder.offset_bottom = 56.0
	stars_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(stars_holder)
	_story_pop_bigstar_icons.clear()
	var big_sizes := [76, 108, 76]
	for i in 3:
		var st := TextureRect.new()
		st.texture = STORY_STAR_EMPTY_TEX
		st.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		st.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		st.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		st.custom_minimum_size = Vector2(big_sizes[i], big_sizes[i])
		st.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		st.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stars_holder.add_child(st)
		_story_pop_bigstar_icons.append(st)


func _layout_story() -> void:
	if _story_map == null:
		return
	var view := get_viewport_rect().size
	if _story_scroll:
		_story_scroll.position = Vector2.ZERO
		_story_scroll.size = view
	# altezza contenuto: 30 isole a serpentina (livello 1 in basso, si sale) + padding
	_story_total_h = STORY_PAD_TOP + STORY_PAD_BOTTOM + float(STORY_LEVELS - 1) * STORY_ISLAND_GAP
	_story_total_h = maxf(_story_total_h, view.y)
	if _story_content:
		# solo custom_minimum_size: è questa che definisce l'area scorrevole; NON impostare
		# .size a mano (litiga con la gestione del ScrollContainer → scroll a scatti/strano).
		_story_content.custom_minimum_size = Vector2(view.x, _story_total_h)
	# sfondo a strisce scorrevole: copre tutta l'area del contenuto (scorre con le isole)
	if _story_bg_scroll:
		_story_bg_scroll.size = Vector2(view.x, _story_total_h)
		_story_bg_scroll.position = Vector2.ZERO
		_story_content.move_child(_story_bg_scroll, 0)   # dietro tutto
	# posizioni a serpentina: livello 1 (i=0) IN BASSO
	var amp: float = minf(view.x * 0.26, 150.0)
	var cx := view.x * 0.5
	_story_level_pos.clear()
	for i in STORY_LEVELS:
		var y := _story_total_h - STORY_PAD_BOTTOM - float(i) * STORY_ISLAND_GAP
		var x := cx + amp * sin(float(i) * 0.9)
		_story_level_pos.append(Vector2(x, y))
	var hw := STORY_ISLAND_W * 0.5
	var hh := STORY_ISLAND_H * 0.5
	for i in _story_level_buttons.size():
		var b: TextureButton = _story_level_buttons[i]
		if not is_instance_valid(b):
			continue
		b.size = Vector2(STORY_ISLAND_W, STORY_ISLAND_H)
		b.pivot_offset = Vector2(hw, hh)
		b.position = _story_level_pos[i] - Vector2(hw, hh)
		# NUMERO grande CENTRATO nella parte alta della tile
		if i < _story_num_labels.size() and is_instance_valid(_story_num_labels[i]):
			var lbl: Label = _story_num_labels[i]
			lbl.position = Vector2(0, STORY_ISLAND_H * 0.10)
			lbl.size = Vector2(STORY_ISLAND_W, STORY_ISLAND_H * 0.42)
		# 3 STELLE GRANDI sotto il numero: centrale più grande, laterali un po' più piccole.
		if i < _story_island_stars.size():
			var side_sz := 34.0
			var mid_sz := 46.0
			var overlap := 4.0
			var mtot := 2.0 * side_sz + mid_sz - 2.0 * overlap
			var mx := (STORY_ISLAND_W - mtot) * 0.5
			var baseline := STORY_ISLAND_H * 0.80   # bordo basso comune (sopra l'ombra della tile)
			var srow: Array = _story_island_stars[i]
			var szs := [side_sz, mid_sz, side_sz]
			var xoff := 0.0
			for s in srow.size():
				if is_instance_valid(srow[s]):
					var ssz: float = szs[s]
					srow[s].size = Vector2(ssz, ssz)
					srow[s].position = Vector2(mx + xoff, baseline - ssz)
					xoff += ssz - overlap
	# NUVOLE attaccate in cima allo schermo (top del contenuto), col testo "NUOVA STAGIONE
	# IN ARRIVO" + timer SOVRAPPOSTI sopra le nuvole.
	var cloud_h := view.x * (520.0 / 768.0)
	if _story_clouds:
		_story_clouds.size = Vector2(view.x, cloud_h)
		_story_clouds.position = Vector2(0, 0)
		# nuvole sopra lo sfondo scorrevole (idx 0) ma dietro al testo/timer
		_story_content.move_child(_story_clouds, 1)
	# testo + timer più in basso, sotto la notch/dynamic island (offset fisso dal top)
	var season_y := 150.0
	if _story_season_lbl:
		_story_season_lbl.size = Vector2(view.x, 110.0)
		_story_season_lbl.position = Vector2(0, season_y)
	if _story_countdown_lbl:
		_story_countdown_lbl.size = Vector2(view.x, 52.0)
		_story_countdown_lbl.position = Vector2(0, season_y + 104.0)
	# tasto indietro alla STESSA altezza/posizione della X di gioco (game.tscn UI/BackButton:
	# design (36,-6), 74x74) traslata come gli overlay CanvasLayer (cam_dx/cam_dy)
	var cam_dx := view.x * 0.5 - CAMERA_CENTER.x
	var cam_dy := view.y * 0.5 - CAMERA_CENTER.y
	if _story_back:
		_story_back.size = Vector2(74, 74)
		_story_back.position = Vector2(36.0 + cam_dx, -6.0 + cam_dy)
	# freccia "torna al livello" in basso al centro (sopra la nav bar). Ruotata di 90°:
	# il pivot al centro tiene il centro visivo fermo; posiziono il centro a (cx, y_basso).
	if _story_title:
		# titolo "STORIA" in alto RIMOSSO (nascosto) su richiesta
		_story_title.visible = false
	# contatore stelle in alto a DESTRA (icona + numero), alla stessa altezza dell'header
	if _story_counter_icon:
		_story_counter_icon.size = Vector2(44, 44)
		_story_counter_icon.position = Vector2(view.x - 118.0, 16.0 + cam_dy)
	if _story_star_counter:
		_story_star_counter.position = Vector2(view.x - 70.0, 12.0 + cam_dy)
		_story_star_counter.size = Vector2(64, 52)
	if _story_msg:
		_story_msg.position = Vector2(0, view.y * 0.5 - 30.0)
		_story_msg.size = Vector2(view.x, 60)
	if _story_popup:
		_story_popup.set_anchors_preset(Control.PRESET_FULL_RECT)


# config grezza del livello n (dizionario di STORY_LEVELS_DATA) o vuoto se fuori range
func _story_cfg(n: int) -> Dictionary:
	if n >= 1 and n <= STORY_LEVELS_DATA.size():
		return STORY_LEVELS_DATA[n - 1]
	return {}


# TEMP: tutti i livelli sbloccati (per test). Rimettere a false per la progressione reale.
const STORY_UNLOCK_ALL := true
# un livello è sbloccato se è il primo o se il precedente è stato completato
func _story_is_unlocked(n: int) -> bool:
	if STORY_UNLOCK_ALL:
		return true
	return n <= settings.story_completed + 1


# numero con separatore delle migliaia (50000 -> "50.000")
func _story_num(n: int) -> String:
	var s := str(n)
	var out := ""
	var c := 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		c += 1
		if c % 3 == 0 and i > 0:
			out = "." + out
	return out


func _story_color_name(key: String) -> String:
	match key:
		"red": return loc.t("rossi")
		"green": return loc.t("verdi")
		"yellow": return loc.t("gialli")
	return key


# Ricompense cosmetiche (3ª stella dei livelli-traguardo ogni 5): livello -> {tipo, id}.
const STORY_MILESTONE_REWARDS := {
	5:  {"type": "avatar", "id": "av_penguin"},
	10: {"type": "skin",   "id": "sk_blue"},
	15: {"type": "avatar", "id": "av_mushroom"},
	20: {"type": "skin",   "id": "sk_green"},
	25: {"type": "avatar", "id": "av_pig"},
	30: {"type": "skin",   "id": "sk_purple"},
}

# Ricompensa della stella `s` (0/1/2) del livello n. Monete crescenti col livello;
# la 3ª stella dei livelli-traguardo (5,10,…,30) dà un cosmetico (avatar/skin).
func _story_reward(n: int, s: int) -> Dictionary:
	if s == 2 and STORY_MILESTONE_REWARDS.has(n):
		var r: Dictionary = STORY_MILESTONE_REWARDS[n]
		var icon := _shop_cosmetic_icon(r["type"], r["id"])
		return {"type": r["type"], "id": r["id"], "tex": icon, "amount": 0}
	var amount: int = [20 + n * 5, 40 + n * 10, 75 + n * 15][s]
	return {"type": "coins", "id": "", "tex": STORY_COIN_TEX, "amount": amount}


# icona (Texture2D) di un cosmetico dello shop dato tipo+id
func _shop_cosmetic_icon(kind: String, id: String) -> Texture2D:
	var lst: Array = shop.AVATARS if kind == "avatar" else shop.SKINS
	for it in lst:
		if it["id"] == id:
			var p := str(it["icon"])
			return load(p) if ResourceLoader.exists(p) else null
	return null


# missione per la stella `tier` (0/1/2): stesse soglie di grid.gd (×1 / ×1.8 / ×2.8; colori ×1/1.7/2.6)
# Obiettivo COMPATTO della stella `tier`: numero + cosa (es. "3000 punti", "270 cubi rossi").
func _story_star_amount(cfg: Dictionary, tier: int) -> String:
	var goal := str(cfg.get("goal", "score"))
	match goal:
		"cubes":
			var base := int(cfg.get("cubes", 0))
			var vc: int = [base, int(round(base * 1.8)), int(round(base * 2.8))][tier]
			return "%s %s" % [_story_num(vc), loc.t("cubi")]
		"colors":
			var mult: float = [1.0, 1.7, 2.6][tier]
			var cg: Dictionary = cfg.get("colors_goal", {})
			var parts: Array = []
			for k in cg:
				parts.append("%d %s" % [int(ceil(float(int(cg[k])) * mult)), _story_color_name(str(k))])
			return "\n".join(parts)
		_:
			var b := int(cfg.get("target", 0))
			var vv: int = [b, int(round(b * 1.8)), int(round(b * 2.8))][tier]
			return "%s %s" % [_story_num(vv), loc.t("punti")]


func _story_star_mission(cfg: Dictionary, tier: int) -> String:
	var goal := str(cfg.get("goal", "score"))
	match goal:
		"cubes":
			var base := int(cfg.get("cubes", 0))
			var vc: int = [base, int(round(base * 1.8)), int(round(base * 2.8))][tier]
			return "%s %d %s" % [loc.t("Distruggi"), vc, loc.t("cubi")]
		"colors":
			var mult: float = [1.0, 1.7, 2.6][tier]
			var cg: Dictionary = cfg.get("colors_goal", {})
			var parts: Array = []
			for k in cg:
				parts.append("%d %s" % [int(ceil(float(int(cg[k])) * mult)), _story_color_name(str(k))])
			return "%s %s" % [loc.t("Distruggi"), ", ".join(parts)]
		_:
			var b := int(cfg.get("target", 0))
			var vv: int = [b, int(round(b * 1.8)), int(round(b * 2.8))][tier]
			return "%s %s" % [_story_num(vv), loc.t("punti")]


func _story_mission_text(cfg: Dictionary) -> String:
	match str(cfg.get("goal", "score")):
		"cubes":
			return "%s %d %s" % [loc.t("Distruggi"), int(cfg.get("cubes", 0)), loc.t("cubi")]
		"colors":
			var parts: Array = []
			var cg: Dictionary = cfg.get("colors_goal", {})
			for k in cg:
				parts.append("%d %s" % [int(cg[k]), _story_color_name(str(k))])
			return "%s %s" % [loc.t("Distruggi"), ", ".join(parts)]
		"speedrun":
			var t := int(cfg.get("time", 0.0))
			return "%s %s %s %d:%02d" % [_story_num(int(cfg.get("target", 0))), loc.t("punti in"), loc.t("max"), t / 60, t % 60]
		_:
			return "%s %s %s" % [loc.t("Raggiungi"), _story_num(int(cfg.get("target", 0))), loc.t("punti")]


func _story_level_info(n: int) -> Dictionary:
	var cfg := _story_cfg(n)
	if cfg.is_empty():
		return {"name": "%s %d" % [loc.t("LIVELLO"), n], "desc": "", "mission": ""}
	var g := int(cfg.get("grid", 3))
	var col := int(cfg.get("colors", 3))
	return {
		"name": "%s %d" % [loc.t("LIVELLO"), n],
		"desc": "%s %d×%d · %d %s" % [loc.t("Griglia"), g, g, col, loc.t("colori")],
		"mission": _story_mission_text(cfg),
	}


func _on_story_level(n: int) -> void:
	settings.button_feedback()
	if not _story_is_unlocked(n):
		_story_island_pop(n - 1)
		_flash_story_msg("LIVELLO BLOCCATO")
		return
	# animazione "schiaccia isola" prima di aprire il popup
	_story_island_pop(n - 1)
	await get_tree().create_timer(0.22).timeout
	_open_story_level_popup(n)


# animazione TAP dell'isola: squash + pop (dal centro grazie a pivot_offset)
func _story_island_pop(idx: int) -> void:
	if idx < 0 or idx >= _story_level_buttons.size():
		return
	var b = _story_level_buttons[idx]
	if not is_instance_valid(b):
		return
	b.scale = Vector2.ONE
	var tw := create_tween()
	tw.tween_property(b, "scale", Vector2(0.82, 0.82), 0.07).set_trans(Tween.TRANS_SINE)
	tw.tween_property(b, "scale", Vector2(1.16, 1.16), 0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(b, "scale", Vector2.ONE, 0.11).set_trans(Tween.TRANS_SINE)


# rimbalzo CONTINUO dell'isola del livello corrente (il prossimo da fare)
func _story_stop_bounce() -> void:
	if _story_bounce_tw and _story_bounce_tw.is_valid():
		_story_bounce_tw.kill()
	_story_bounce_tw = null

func _story_start_bounce(idx: int) -> void:
	_story_stop_bounce()
	if idx < 0 or idx >= _story_level_buttons.size():
		return
	var b = _story_level_buttons[idx]
	if not is_instance_valid(b):
		return
	var base_y: float = b.position.y
	_story_bounce_tw = create_tween().set_loops()
	_story_bounce_tw.tween_property(b, "position:y", base_y - 14.0, 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_story_bounce_tw.tween_property(b, "position:y", base_y, 0.55).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)


func _open_story_level_popup(n: int) -> void:
	_story_pop_play_idx = n
	var cfg := _story_cfg(n)
	var earned := settings.story_best_stars(n)
	_story_pop_num.text = "%s %d" % [loc.t("LIVELLO"), n]
	_story_pop_desc.text = _story_funny_desc(n, cfg)
	# 3 stelle grandi in cima: colorate se conquistate, altrimenti bianco e nero
	for i in _story_pop_bigstar_icons.size():
		_story_pop_bigstar_icons[i].texture = STORY_STAR_FULL_TEX if i < earned else STORY_STAR_EMPTY_TEX
	# caratteristiche: griglia N×N + cubi dei colori usati
	_fill_story_stats(cfg)
	# anteprima animata del livello (griglia + colori)
	_build_story_preview(int(cfg.get("grid", 3)), int(cfg.get("colors", 3)))
	# missioni: per ogni stella l'obiettivo. Stella conquistata = oro; non conquistata = bianco.
	for i in 3:
		if i < _story_pop_star_lbls.size():
			_story_pop_star_lbls[i].text = _story_star_amount(cfg, i)
			var got := i < earned
			_story_pop_star_icons[i].texture = STORY_STAR_FULL_TEX if got else STORY_STAR_EMPTY_TEX
			_story_pop_star_lbls[i].add_theme_color_override("font_color", Color(1, 0.92, 0.45) if got else Color(1, 1, 1))
	_story_popup.visible = true


# breve descrizione simpatica in base all'obiettivo del livello
func _story_funny_desc(n: int, cfg: Dictionary) -> String:
	if n == 1:
		return loc.t("Il primo passo: rompi qualche cubo e prendici la mano!")
	match str(cfg.get("goal", "score")):
		"cubes":
			return loc.t("Fai a pezzi tutti i cubi che puoi!")
		"colors":
			return loc.t("A caccia dei colori giusti!")
		"speedrun":
			return loc.t("Corri, il tempo scappa via!")
		_:
			return loc.t("Accumula più punti che riesci!")


# riempie CARATTERISTICHE: riga1 "Dimensioni griglia: N×N", riga2 i cubi dei colori usati
func _fill_story_stats(cfg: Dictionary) -> void:
	if _story_pop_stats == null:
		return
	for c in _story_pop_stats.get_children():
		_story_pop_stats.remove_child(c)
		c.queue_free()
	var g := int(cfg.get("grid", 3))
	var ncol := int(cfg.get("colors", 3))
	# riga 1: dimensione griglia
	var gl := Label.new()
	gl.add_theme_font_override("font", MODE_FONT)
	gl.add_theme_font_size_override("font_size", 26)
	gl.add_theme_color_override("font_color", Color(1, 0.92, 0.45))
	gl.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	gl.add_theme_constant_override("outline_size", 4)
	gl.text = "%s %d×%d" % [loc.t("Dimensioni griglia:"), g, g]
	gl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_story_pop_stats.add_child(gl)
	# riga 2: cubi dei colori disponibili
	var cubes := HBoxContainer.new()
	cubes.alignment = BoxContainer.ALIGNMENT_CENTER
	cubes.add_theme_constant_override("separation", 8)
	for i in mini(ncol, STORY_COLOR_ORDER.size()):
		var ck: String = STORY_COLOR_ORDER[i]
		var cube := TextureRect.new()
		cube.texture = STORY_CUBE_TEX.get(ck, null)
		cube.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		cube.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		cube.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		cube.custom_minimum_size = Vector2(36, 36)
		cube.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cubes.add_child(cube)
	_story_pop_stats.add_child(cubes)


func _close_story_popup() -> void:
	if _story_preview_timer:
		_story_preview_timer.stop()   # ferma l'animazione anteprima (perf)
	if _story_popup:
		_story_popup.visible = false


# ---- ANTEPRIMA ANIMATA DEL LIVELLO (stile cube deck) ----
func _story_preview_base(cap: String) -> Texture2D:
	return load("%s%s/%s.svg" % [CUBES_DIR, cap, cap]) as Texture2D

func _story_preview_frames(cap: String) -> Array:
	var out: Array = []
	for i in range(2, 8):
		var p := "%s%s/%s_%d.svg" % [CUBES_DIR, cap, cap, i]
		if ResourceLoader.exists(p):
			out.append(load(p))
	return out

# Costruisce la griglia N×N di cubi (colori del livello) e avvia il loop di animazione.
func _build_story_preview(n: int, ncol: int) -> void:
	if _story_preview_box == null:
		return
	# palette: primi `ncol` colori dello story order, capitalizzati (red -> Red)
	_story_preview_palette.clear()
	for i in mini(ncol, STORY_COLOR_ORDER.size()):
		_story_preview_palette.append(String(STORY_COLOR_ORDER[i]).capitalize())
	if _story_preview_palette.is_empty():
		_story_preview_palette.append("Red")
	# pulisci i cubi precedenti (tieni il Timer)
	for c in _story_preview_cubes:
		if is_instance_valid(c):
			c.queue_free()
	_story_preview_cubes.clear()
	# geometria: N×N centrata nel box (area fissa 336×250)
	var box := Vector2(336.0, 250.0)
	var m := 16.0
	var cell: float = minf((box.x - 2.0 * m) / float(n), (box.y - 2.0 * m) / float(n))
	var cube_sz := cell * 0.92
	var gw := cell * float(n)
	var gh := cell * float(n)
	var ox := (box.x - gw) * 0.5
	var oy := (box.y - gh) * 0.5
	for r in n:
		for cc in n:
			var cap: String = _story_preview_palette[randi() % _story_preview_palette.size()]
			var t := TextureRect.new()
			t.texture = _story_preview_base(cap)
			t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			t.mouse_filter = Control.MOUSE_FILTER_IGNORE
			t.size = Vector2(cube_sz, cube_sz)
			t.pivot_offset = t.size * 0.5
			t.position = Vector2(ox + cc * cell + (cell - cube_sz) * 0.5, oy + r * cell + (cell - cube_sz) * 0.5)
			t.set_meta("cap", cap)
			_story_preview_box.add_child(t)
			_story_preview_cubes.append(t)
	if _story_preview_timer:
		_story_preview_timer.start()

# A ogni tick fa "esplodere" 1-2 cubi casuali e li rigenera con un colore della palette.
func _story_preview_tick() -> void:
	if _story_preview_cubes.is_empty():
		return
	var pops: int = 1 if _story_preview_cubes.size() <= 9 else 2
	for _k in pops:
		var cube = _story_preview_cubes[randi() % _story_preview_cubes.size()]
		_story_preview_pop(cube)

func _story_preview_pop(cube: TextureRect) -> void:
	if not is_instance_valid(cube):
		return
	var cap := str(cube.get_meta("cap", "Red"))
	var frames := _story_preview_frames(cap)
	var tw := create_tween()
	tw.tween_property(cube, "scale", Vector2(1.15, 1.15), 0.06)
	for f in frames:
		var ff: Texture2D = f
		tw.tween_callback(func() -> void:
			if is_instance_valid(cube):
				cube.texture = ff)
		tw.tween_interval(0.04)
	# rigenera con nuovo colore
	var newcap: String = _story_preview_palette[randi() % _story_preview_palette.size()]
	tw.tween_callback(func() -> void:
		if is_instance_valid(cube):
			cube.set_meta("cap", newcap)
			cube.texture = _story_preview_base(newcap)
			cube.scale = Vector2(0.3, 0.3))
	tw.tween_property(cube, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# Aggiorna, per il livello n, le 3 ricompense e lo stato dei tasti RISCUOTI.
func _refresh_story_rewards(n: int) -> void:
	var earned := settings.story_best_stars(n)
	for i in 3:
		if i >= _story_pop_claim_btns.size():
			break
		var rw := _story_reward(n, i)
		var ri: TextureRect = _story_pop_reward_icons[i]
		var rl: Label = _story_pop_reward_lbls[i]
		var btn: Button = _story_pop_claim_btns[i]
		ri.texture = rw.get("tex", null)
		if rw["type"] == "coins":
			rl.text = "+%d" % int(rw["amount"])
		else:
			rl.text = loc.t("SKIN") if rw["type"] == "skin" else loc.t("AVATAR")
		var unlocked := i < earned
		var claimed := settings.story_reward_claimed(n, i)
		ri.modulate = Color(1, 1, 1) if unlocked else Color(1, 1, 1, 0.35)
		rl.modulate = Color(1, 1, 1) if unlocked else Color(1, 1, 1, 0.35)
		if claimed:
			btn.text = loc.t("RISCOSSO")
			btn.disabled = true
			btn.modulate = Color(0.6, 1.0, 0.6)
		elif unlocked:
			btn.text = loc.t("RISCUOTI")
			btn.disabled = false
			btn.modulate = Color(1, 1, 1)
		else:
			btn.text = loc.t("BLOCCATO")
			btn.disabled = true
			btn.modulate = Color(1, 1, 1, 0.5)


# Riscuote la ricompensa della stella `s` del livello aperto nel popup.
func _on_claim_story_reward(s: int) -> void:
	var n: int = _story_pop_play_idx
	if s < 0 or s >= 3:
		return
	if s >= settings.story_best_stars(n):
		return   # stella non ancora conquistata
	if settings.story_reward_claimed(n, s):
		return   # già riscossa
	var rw := _story_reward(n, s)
	match rw["type"]:
		"coins":
			missions.coins += int(rw["amount"])
			missions._save()
			settings.play_coin()
		"avatar":
			shop.owned_avatars[rw["id"]] = true
			shop._save()
			settings.button_feedback()
		"skin":
			shop.owned_skins[rw["id"]] = true
			shop._save()
			settings.button_feedback()
	settings.story_mark_reward_claimed(n, s)
	_refresh_story_rewards(n)


# aggiorna l'aspetto dei nodi-livello: completato=verde, giocabile=normale, bloccato=spento
# Aggiorna il countdown alla prossima stagione (1 settembre 2026). Formato: "TRA 14G 03H 22M 10S".
func _update_season_countdown() -> void:
	if _story_countdown_lbl == null:
		return
	var target := Time.get_unix_time_from_datetime_string(STORY_SEASON_TARGET_ISO)
	var now := Time.get_unix_time_from_system()
	var rem := int(target - now)
	if rem <= 0:
		_story_countdown_lbl.text = loc.t("IN ARRIVO")
		return
	var d := rem / 86400
	var h := (rem % 86400) / 3600
	var m := (rem % 3600) / 60
	var s := rem % 60
	_story_countdown_lbl.text = "%s %dG %02dH %02dM %02dS" % [loc.t("TRA"), d, h, m, s]


func _refresh_story_nodes() -> void:
	for i in _story_level_buttons.size():
		var b: TextureButton = _story_level_buttons[i]
		if not is_instance_valid(b):
			continue
		var n := i + 1
		if not _story_is_unlocked(n):
			b.modulate = Color(0.6, 0.6, 0.66)     # bloccato: spento
		else:
			b.modulate = Color(1, 1, 1)
		# stelline dell'isola in base a quelle guadagnate
		if i < _story_island_stars.size():
			var earned := settings.story_best_stars(n)
			var srow: Array = _story_island_stars[i]
			for s in srow.size():
				if is_instance_valid(srow[s]):
					srow[s].texture = STORY_STAR_FULL_TEX if s < earned else STORY_STAR_EMPTY_TEX
	# contatore stelle totali (in alto a destra)
	if _story_star_counter:
		_story_star_counter.text = str(settings.story_total_stars())
	# rimbalzo continuo sull'isola del prossimo livello da fare
	_story_start_bounce(clampi(settings.story_completed, 0, STORY_LEVELS - 1))


func _on_story_play() -> void:
	settings.button_feedback()
	var n: int = _story_pop_play_idx
	var cfg := _story_cfg(n)
	if cfg.is_empty() or not _story_is_unlocked(n):
		_close_story_popup()
		_flash_story_msg("PROSSIMAMENTE")
		return
	settings.game_mode = "story"
	settings.story_level = n
	settings.story_grid = int(cfg.get("grid", 3))
	settings.story_colors = int(cfg.get("colors", 3))
	settings.story_ab_vert = bool(cfg.get("v", false))
	settings.story_ab_horiz = bool(cfg.get("h", false))
	settings.story_ab_bomb = bool(cfg.get("b", false))
	settings.story_goal = str(cfg.get("goal", "score"))
	settings.story_target = int(cfg.get("target", 0))
	settings.story_goal_cubes = int(cfg.get("cubes", 0))
	settings.story_goal_colors = (cfg.get("colors_goal", {}) as Dictionary).duplicate()
	settings.story_time = float(cfg.get("time", 0.0))
	settings.play_playbutton()
	settings.vibrate(15)
	transition.change_scene("res://CORE/Scene/game.tscn")


func _open_story_map() -> void:
	if _story_map == null:
		return
	_story_map.visible = true
	_close_story_popup()
	_layout_story()
	_refresh_story_nodes()
	# la mappa parte dal BASSO (livello 1)
	await get_tree().process_frame
	if _story_scroll:
		_story_scroll.scroll_vertical = int(_story_total_h)


func _close_story_map() -> void:
	settings.button_feedback()
	_story_stop_bounce()
	_close_story_popup()
	if _story_map:
		_story_map.visible = false


func _flash_story_msg(txt: String) -> void:
	if _story_msg == null:
		return
	_story_msg.text = loc.t(txt)
	_story_msg.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_interval(1.1)
	tw.tween_property(_story_msg, "modulate:a", 0.0, 0.5)

