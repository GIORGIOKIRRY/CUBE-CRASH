extends Node2D

# ----- Export Variables -----
@export var width: int = 10
@export var height: int = 10
@export var x_start: float = 0.0
@export var y_start: float = 0.0
@export var offset: float = 64.0

# Posizionamento BottomGrid (3 slot)
@export var bottom_y_offset_pixels: int = 148 # quanto sotto alla griglia principale (abbassato: non attaccato al contorno)
@export var bottom_spacing_px: int = 140      # distanza orizzontale tra i 3 slot

# Scala dei 3 cubi trascinabili: in basso sono più grandi, quando li
# prendi per trascinarli si rimpiccioliscono alla dimensione della griglia.
const BOTTOM_PIECE_SCALE := 1.35
var _bottom_scale: float = BOTTOM_PIECE_SCALE   # scala dei cubi nel tray (più grande in storia 3×3)
const GRID_PIECE_SCALE := 1.0
const DRAG_LIFT := 100.0   # il cubo preso col dito si alza sopra il dito (vedi dove lo posizioni)
const CELL_SPRITE_SCALE := 0.734694   # scala sprite dei cubi = dimensione cella
const POP_FONT := preload("res://CORE/Assets/Font/Jersey10-Regular.ttf")

# Animazione esplosione (6 frame) alla distruzione di un cubo.
const EXPLO_FRAMES := [
	preload("res://CORE/Assets/Art/Game/Delete/delete_01.svg"),
	preload("res://CORE/Assets/Art/Game/Delete/delete_02.svg"),
	preload("res://CORE/Assets/Art/Game/Delete/delete_03.svg"),
	preload("res://CORE/Assets/Art/Game/Delete/delete_04.svg"),
	preload("res://CORE/Assets/Art/Game/Delete/delete_05.svg"),
	preload("res://CORE/Assets/Art/Game/Delete/delete_06.svg"),
]
const EXPLO_FPS := 20.0                # 6 frame ≈ 0.3s; il cubo dietro sparisce al 3° frame
const COMBO_EFFECT_SCALE := 0.85       # scala dell'animazione COMBO (frame nativi 500x302)
const COMBO_SPEED := 1.1               # velocità di riproduzione (più lenta = più fluida)

# Bilanciamento tavola (stile Block Blast: scacchiera quasi sempre piena).
# Quando è ≥70% piena, esplode UN cubo casuale (2 se ≥80%, rarissimamente 3),
# UNO ALLA VOLTA, con un cooldown: quanto basta a far proseguire senza svuotare.
const BALANCE_FULLNESS_TRIGGER := 0.90  # rarissimo: solo quando è quasi del tutto piena
const BALANCE_COOLDOWN := 3             # minimo mosse tra due bilanciamenti

# Combo: la sparizione di cubi è RARA e "fortunata", legata alle catene lunghe.
const COMBO_REWARD_MIN_CHAIN := 3      # servono almeno 3 combo di fila per avere spazio
const COMBO_MAX_BONUS := 2             # max cubi bonus rimossi (raro)
const IDLE_HINT_MS := 10000            # suggerimenti dopo 10s di inattività
const HINT_REPEAT_MS := 10000          # intervallo tra suggerimenti ripetuti
@export var spawn_rows_above: int = 1       # quante "righe" sopra la griglia fanno partire la caduta
@export var enable_empty_fall_fx: bool = true

# ----- Difficulty Progression -----
@export var difficulty_step_score: int = 2400  # ogni quanti punti sale la difficoltà (rampa più veloce per i bravi)
@export var max_difficulty_level: int = 10

var difficulty_level: int = 0

@export_range(0.0, 1.0, 0.01)
var max_empty_refill_probability: float = 0.88  # limite massimo vuoti

@export var bonus_moves_penalty_per_level: int = 1

# Probabilità refill (0.0-1.0). Es: 0.2 = 20% spazio vuoto, 80% pezzi
@export_range(0.0, 1.0, 0.01) var empty_refill_probability: float = 0.63

@export_range(0.0, 1.0, 0.01)
var plus_piece_probability: float = 0.18  # base cubi-mossa (poi modulata da _effective_plus_prob)
const INITIAL_PLUS_PROB := 0.10  # seed cubi-mossa sulla scacchiera iniziale (più basso: meno surplus a inizio partita)
const BOTTOM_SPECIAL_PROB := 0.05  # Mode C: prob. che un blocco del tray in basso sia uno speciale (V/O/BOMBA) — molto raro, è il "vantaggio"

@export var max_moves: int = 30  # numero di mosse iniziali
var current_moves: int = 0
var is_game_over: bool = false

# --- Modalità test A/B/C (impostata da settings.game_mode in _ready) ---
var _mode: String = "classic"
var _moves_enabled: bool = true      # false in mode_b e mode_c (niente mosse)
var _swap_costs_move: bool = false   # true in mode_a (swap che fa match costa una mossa)
const MOVE_CUBE_POINTS := 120        # in mode_b i cubi +N danno punti invece di mosse
var is_resolving: bool = false  # nuovo: blocca mosse durante la risoluzione

# --- MODE C (fusione Classic+B): niente mosse, game over solo per spazio, ---
# colori progressivi (parte da 5), combo frequenti, bonus rivisti:
#  +1 = colonna intera (+ gravità/refill)   +2 = riga intera (+ gravità)
#  +3 = bomba 5x5 che lascia un CRATERE vuoto (buchi da riempire, niente refill)
var _is_mode_c: bool = false
# MODALITÀ STORIA (campagna): livello con griglia custom (es. 3×3) e obiettivo punti.
# Gioca con le meccaniche di CLASSIC (mode_c) ma con VITTORIA al raggiungimento del target.
var _is_story: bool = false
var _story_target: int = 0
var _story_won: bool = false
# Regole del livello storia corrente (lette da settings in _ready):
var _story_colors: int = 3                     # n. colori normali ammessi (3/5/7)
var _story_ab_vert: bool = true                # abilità verticale (colonna) attiva
var _story_ab_horiz: bool = true               # abilità orizzontale (riga) attiva
var _story_ab_bomb: bool = true                # abilità bomba 3×3 attiva
var _story_abilities: Array = []               # valori abilità attivi, subset di [1,2,3]
var _story_time: float = 0.0                   # >0 = livello a tempo (speedrun storia)
var _story_goal: String = "score"              # "score" | "cubes" | "colors" | "speedrun"
var _story_goal_cubes: int = 0                 # goal "cubes": cubi normali da distruggere
var _story_goal_colors: Dictionary = {}        # goal "colors": {colore -> quantità}
var _story_destroyed: int = 0                  # cubi distrutti finora (totale)
var _story_color_tally: Dictionary = {}        # colore -> cubi distrutti finora
var _story_level: int = 1                       # numero del livello storia corrente
var _story_wpos: float = 0.0                    # posizione nel mondo (0=primo livello .. 1=ultimo)
var _story_gd: float = 0.0                      # difficoltà globale 0..1 (livello 1 .. 30)
var _story_hud: Label = null                   # etichetta obiettivo in partita
# --- Sistema 3 STELLE (3 fasi/soglie per livello) ---
const STORY_STAR_FULL := preload("res://CORE/Assets/Art/Story/star_full.png")
const STORY_STAR_EMPTY := preload("res://CORE/Assets/Art/Story/star_empty.png")
var _story_score_th: Array = []                # 3 soglie punteggio (score/speedrun)
var _story_cube_th: Array = []                 # 3 soglie cubi
var _story_color_tiers: Array = []             # 3 tier {colore->qta} (goal colors)
var _story_stars_shown: int = 0                # stelle attualmente raggiunte (per il live-save)
var _story_star_icons: Array = []              # 3 TextureRect stella nell'HUD
var _story_bar_fill: ColorRect = null          # barra progresso: riempimento
var _story_bar_hi: ColorRect = null            # barra progresso: highlight (stile pixel)
var _story_bar_max_w: float = 0.0              # larghezza massima del riempimento
var _story_last_score: int = -1                # per aggiornare la barra quando cambia il punteggio
# In storia i 3 colori base sono ROSSO/VERDE/GIALLO (usati dagli obiettivi), poi gli altri.
const STORY_COLOR_ORDER := ["red", "green", "yellow", "blue", "purple", "orange", "pink"]
const BASE_CELL := 82.285714                  # cella del 7×7 di riferimento (per scalare i cubi)
var _grid_piece_scale: float = 1.0            # scala dei cubi SULLA griglia (= GRID_PIECE_SCALE, cresce in story se celle più grandi)
var _cell_sprite_scale: float = CELL_SPRITE_SCALE   # scala di preview/ghost (idem)
var _is_test: bool = false                   # modalità TEST: sperimentale (bombe swap, combo facili, 4 colori)
var _is_test_6: bool = false                  # modalità TEST 6: identica alla CLASSIC ma con 4 colori
var _is_test_7: bool = false                  # modalità TEST 7: identica alla CLASSIC ma bombe swap (in bianco/nero)
var _bomb_swap: bool = false                  # true in CLASSIC/SPEEDRUN: le BOMBE (mooves>=3) si attivano con QUALSIASI swap (senza colore)
var _bomb_anim: Dictionary = {}               # valore bomba (mooves) -> Array di frame dell'animazione di ESPLOSIONE (nero/b-n)
const BOMB_ANIM_STEP := 0.05                  # durata di ogni frame dell'animazione bomba (come i blocchi normali)
const BOMB_EXPLODE_TIME := 0.32               # attesa prima di distruggere/attivare il power-up (lascia scorrere l'animazione)
var _fall_speed_mult: float = 1.0   # caduta leggermente più lenta nella CLASSIC (non speedrun)
var _is_speedrun: bool = false               # gameplay mode_c + timer 5 min + input libero durante le cascate
var _speedrun_time_left: float = 300.0       # 5 minuti
var _timer_label: Label = null
var _speedrun_best: int = 0                   # record dedicato alla modalità speedrun
var _prev_speedrun_best: int = 0             # record speedrun PRIMA di questa partita
var _speedrun_started: bool = false          # il timer parte solo dopo il countdown 3-2-1-GO
# musica speedrun caricata in modo ASINCRONO (mai bloccante): il path è solo una stringa,
# nessuna dipendenza pesante su grid.gd -> non appesantisce il caricamento della scena.
const SR_MUSIC_PATH := "res://CORE/Assets/Music&Sound/speedrun.mp3"
var _sr_music_pending: bool = false
const MODE_C_COLOR_ORDER := ["blue", "red", "yellow", "green", "purple", "orange", "pink"]
const MODE_C_START_COLORS := 5           # colori a inizio partita (facili le combo)
const MODE_C_COLORS_PER_STEP := 2        # +1 colore ogni N livelli (colori più in fretta = match più duri prima)
const SPEEDRUN_START_COLORS := 3         # speedrun: solo 3 colori i primi 3 min (tantissimi match)
const SPEEDRUN_MAX_COLORS := 6           # speedrun: massimo colori dopo la fase iniziale
var _bomb_suppress: float = 0.0          # dopo una bomba (+3) la prossima è meno probabile (decade nel tempo)
# ordine dei cubi-bonus in possible_plus_pieces (3 per colore: +1,+2,+3)
const MODE_C_PLUS_COLOR_ORDER := ["blue", "red", "pink", "purple", "yellow", "orange", "green"]
var _mc_active_count: int = MODE_C_START_COLORS
var _mc_normal_scenes: Array = []             # scene normali ordinate per MODE_C_COLOR_ORDER
var _mc_plus_by_color: Dictionary = {}        # color -> {1:scene, 2:scene, 3:scene}
var _total_combos: int = 0                    # combo totali della partita (contatore in alto a sx)

# Revive: max 3 volte per partita
var revive_count: int = 0
const MAX_REVIVES := 3
var _last_defeat_reason: String = "no_space"

# ----- Scoring -----
@export var points_per_piece: int = 10  # (legacy, non più usato per il punteggio base)
@export var points_per_placement: int = 30   # punti per ogni blocco posizionato
@export var points_per_match: int = 100       # punti base per un match (3 cubi); +30 per cubo extra
const END_MOVE_POINTS := 100                   # ogni mossa rimasta a fine partita vale 100 punti
var _end_moves: int = 0
var _end_bonus: int = 0
const COMBO_END_POINTS := 100                   # mode_c: ogni combo accumulata vale 100 punti a fine partita
var _combo_bonus: int = 0
var score: int = 0                      # punteggio della PARTITA corrente
var high_score: int = 0                 # miglior punteggio di sempre
var lifetime_score: int = 0             # punteggio cumulativo totale
var _prev_high_score: int = 0           # record PRIMA di questa partita (per rilevare nuovo record)
var _is_new_record: bool = false        # true se la partita ha battuto il record precedente

const SAVE_PATH := "user://save.cfg"

var can_move = true

# ---- Mini-tutorial della PRIMA partita (solo primo avvio, solo CLASSIC) ----
# Consigli CONTESTUALI: avanzano quando il giocatore compie l'azione (piazza,
# fa match, scambia, combo) invece di comparire "a caso" ogni N secondi → si
# capisce facendo, e finisce da solo appena hai imparato (cap 10 minuti).
const TUT_CFG := "user://tutorial.cfg"
const TUT_VERSION := 7                 # bumpare per FAR RICOMPARIRE il tutorial a tutti
                                       # (installazioni nuove: ver=0 < TUT_VERSION → lo vedono sempre)
var _tut_active := false
var _tut_layer: Node = null
var _tut_panel: Control = null    # banda nera a tutta larghezza (contenitore del testo)
var _tut_label: Label = null
var _tut_phase := 0               # 0=piazza, 1=scambia, 2=fatto
var _tut_phase_done := false      # match avvenuto nella fase corrente
var _tut_need_color := ""         # colore da tenere nel tray durante il tutorial
var _tut_decor: Array = []        # cubi decorativi (tray B/N non toccabile in fase swap)
var _tut_gray_mat: ShaderMaterial = null   # shader grigio per i cubi decorativi
var _tut_target_cell: Vector2i = Vector2i(-1, -1)   # cella valida per il drop in fase 0
var _tut_advancing := false        # true durante la pausa fra una fase e la successiva
const TUT_PHASE_PAUSE := 1.8       # pausa (s) per far VEDERE l'effetto prima della fase dopo
var _tut_hint_node: Node2D = null  # riquadro pulsante che indica DOVE piazzare il cubo
# DEMO ABILITÀ (dopo la combo): per ogni speciale prima lo MOSTRA, poi lo fa ESPLODERE
# su una mappa piena così si vede l'effetto (colonna/riga/3x3/X/angoli).
const TUT_DEMO := [
	{"type": "show", "paths": ["res://CORE/Scene/PieceScene/blue_plus_1.tscn", "res://CORE/Scene/PieceScene/red_plus_2.tscn"], "text": "FRECCE\nDistruggono una colonna o una riga"},
	{"type": "explode", "path": "res://CORE/Scene/PieceScene/blue_plus_1.tscn", "val": 1, "text": "Freccia VERTICALE\ndistrugge tutta la colonna"},
	{"type": "explode", "path": "res://CORE/Scene/PieceScene/red_plus_2.tscn", "val": 2, "text": "Freccia ORIZZONTALE\ndistrugge tutta la riga"},
	{"type": "show", "paths": ["res://CORE/Scene/PieceScene/green_plus_3.tscn"], "text": "BOMBA\nDistrugge i cubi tutt'intorno"},
	{"type": "explode", "path": "res://CORE/Scene/PieceScene/green_plus_3.tscn", "val": 3, "text": "BOMBA\nesplosione 3x3"},
	{"type": "show", "paths": ["res://CORE/Scene/PieceScene/purple_xbomb.tscn"], "text": "BOMBA X\nDistrugge lungo le diagonali"},
	{"type": "explode", "path": "res://CORE/Scene/PieceScene/purple_xbomb.tscn", "val": 4, "text": "BOMBA X\nesplode a forma di X"},
	{"type": "show", "paths": ["res://CORE/Scene/PieceScene/orange_angles.tscn"], "text": "BOMBA ANGOLI\nColpisce i quattro angoli"},
	{"type": "explode", "path": "res://CORE/Scene/PieceScene/orange_angles.tscn", "val": 5, "text": "BOMBA ANGOLI\ncolpisce i quattro angoli"},
]
# TEST: nei build DEBUG il tutorial parte SEMPRE (per Giorgio). Mettere a false per tornare
# al comportamento normale (una volta sola per utente). Non tocca i build di release.
const TUT_ALWAYS_TEST := true

func _load_scores() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(SAVE_PATH)
	if err == OK:
		high_score     = int(cfg.get_value("scores", "high_score", 0))
		lifetime_score = int(cfg.get_value("scores", "lifetime_score", 0))
		_speedrun_best = int(cfg.get_value("scores", "speedrun_best", 0))
	else:
		high_score = 0
		lifetime_score = 0
		_speedrun_best = 0

func _save_scores() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("scores", "high_score", high_score)
	cfg.set_value("scores", "lifetime_score", lifetime_score)
	cfg.set_value("scores", "speedrun_best", _speedrun_best)
	cfg.save(SAVE_PATH)

# ----- Piece Scenes -----
var possible_pieces = [
	preload("res://CORE/Scene/PieceScene/blue_piece.tscn"),
	preload("res://CORE/Scene/PieceScene/red_piece.tscn"),
	preload("res://CORE/Scene/PieceScene/pink_piece.tscn"),
	preload("res://CORE/Scene/PieceScene/purple_piece.tscn"),
	preload("res://CORE/Scene/PieceScene/yellow_piece.tscn"),
	preload("res://CORE/Scene/PieceScene/orange_piece.tscn"),
	preload("res://CORE/Scene/PieceScene/green_piece.tscn")
]

var possible_plus_pieces = [
	preload("res://CORE/Scene/PieceScene/blue_plus_1.tscn"),
	preload("res://CORE/Scene/PieceScene/blue_plus_2.tscn"),
	preload("res://CORE/Scene/PieceScene/blue_plus_3.tscn"),
	preload("res://CORE/Scene/PieceScene/red_plus_1.tscn"),
	preload("res://CORE/Scene/PieceScene/red_plus_2.tscn"),
	preload("res://CORE/Scene/PieceScene/red_plus_3.tscn"),
	preload("res://CORE/Scene/PieceScene/pink_plus_1.tscn"),
	preload("res://CORE/Scene/PieceScene/pink_plus_2.tscn"),
	preload("res://CORE/Scene/PieceScene/pink_plus_3.tscn"),
	preload("res://CORE/Scene/PieceScene/purple_plus_1.tscn"),
	preload("res://CORE/Scene/PieceScene/purple_plus_2.tscn"),
	preload("res://CORE/Scene/PieceScene/purple_plus_3.tscn"),
	preload("res://CORE/Scene/PieceScene/yellow_plus_1.tscn"),
	preload("res://CORE/Scene/PieceScene/yellow_plus_2.tscn"),
	preload("res://CORE/Scene/PieceScene/yellow_plus_3.tscn"),
	preload("res://CORE/Scene/PieceScene/orange_plus_1.tscn"),
	preload("res://CORE/Scene/PieceScene/orange_plus_2.tscn"),
	preload("res://CORE/Scene/PieceScene/orange_plus_3.tscn"),
	preload("res://CORE/Scene/PieceScene/green_plus_1.tscn"),
	preload("res://CORE/Scene/PieceScene/green_plus_2.tscn"),
	preload("res://CORE/Scene/PieceScene/green_plus_3.tscn")
]

# Modalità TEST: BOMBE senza colore che compaiono sulla board e si attivano con QUALSIASI
# swap (bomba 3x3, bomba X, bomba angoli). Le FRECCE invece restano colorate (match).
const TEST_ABILITY_SCENES := [
	preload("res://CORE/Scene/PieceScene/red_plus_3.tscn"),   # bomba 3x3
	preload("res://CORE/Scene/PieceScene/red_xbomb.tscn"),    # bomba X
	preload("res://CORE/Scene/PieceScene/red_angles.tscn"),   # bomba angoli
]
const TEST_ABILITY_PROB := 0.03   # BOMBE rarissime sulla board

# Scelta pesata della bomba in TEST (3x3 la più comune, X e angoli rarissime).
func _pick_test_ability() -> PackedScene:
	var r := randf()
	if r < 0.70:
		return TEST_ABILITY_SCENES[0]   # bomba 3x3
	elif r < 0.87:
		return TEST_ABILITY_SCENES[1]   # bomba X
	return TEST_ABILITY_SCENES[2]       # bomba angoli

# BOMBA X (mooves = 4): esplode formando una X (due diagonali). Un colore per bomba,
# ordine = MODE_C_PLUS_COLOR_ORDER (blue, red, pink, purple, yellow, orange, green).
var possible_xbomb_pieces = [
	preload("res://CORE/Scene/PieceScene/blue_xbomb.tscn"),
	preload("res://CORE/Scene/PieceScene/red_xbomb.tscn"),
	preload("res://CORE/Scene/PieceScene/pink_xbomb.tscn"),
	preload("res://CORE/Scene/PieceScene/purple_xbomb.tscn"),
	preload("res://CORE/Scene/PieceScene/yellow_xbomb.tscn"),
	preload("res://CORE/Scene/PieceScene/orange_xbomb.tscn"),
	preload("res://CORE/Scene/PieceScene/green_xbomb.tscn"),
]

# BOMBA ANGOLI (mooves = 5): rompe i 3 blocchi in ognuno dei 4 angoli della griglia.
# Ordine = MODE_C_PLUS_COLOR_ORDER (blue, red, pink, purple, yellow, orange, green).
var possible_angles_pieces = [
	preload("res://CORE/Scene/PieceScene/blue_angles.tscn"),
	preload("res://CORE/Scene/PieceScene/red_angles.tscn"),
	preload("res://CORE/Scene/PieceScene/pink_angles.tscn"),
	preload("res://CORE/Scene/PieceScene/purple_angles.tscn"),
	preload("res://CORE/Scene/PieceScene/yellow_angles.tscn"),
	preload("res://CORE/Scene/PieceScene/orange_angles.tscn"),
	preload("res://CORE/Scene/PieceScene/green_angles.tscn"),
]

# Cubi-mossa raggruppati per valore (+1/+2/+3). Costruito da possible_plus_pieces
# in _ready (ordine per colore: +1,+2,+3). Serve a scegliere il VALORE in base
# alle mosse: così i cubi-mossa sono SEMPRE presenti, ma quando ne hai tante escono
# per lo più +1 (poco income), quando sei a corto escono più +2/+3 (aiuto vero).
var _plus_pool := {1: [], 2: [], 3: [], 4: [], 5: []}

# ----- Grid State -----
var all_pieces: Array = []      # 2D [width][height] -> Node or null
var cell_active: Array = []     # 2D bool: true = cella attiva (partecipa alla gravità), false = buco

# ----- Touch/Swap -----
var first_touch = Vector2i(0, 0)
var final_touch = Vector2i(0, 0)
var controlling := false

# ----- BottomGrid (3 pezzi trascinabili) -----
var bottom_pieces: Array = [null, null, null]  # 3 slot
var dragging_piece: Node = null
var dragging_from_slot: int = -1
var drag_start_pos: Vector2 = Vector2.ZERO
var _multi_drags: Dictionary = {}   # speedrun: indice-dito -> pezzo trascinato (multi-touch)
var _placement_preview: Sprite2D = null   # fantasma del blocco dove verrà piazzato (opacità bassa)
var _preview_fade_tween: Tween = null       # dissolvenza della preview
var _drag_scale_tween: Tween = null         # tween di scala del cubo trascinato
var _explo_frames: SpriteFrames = null      # frame dell'animazione di esplosione
var _combo_frames: Dictionary = {}          # livello -> SpriteFrames (COMBO 1..4)
var _combo_fx: Dictionary = {}              # livello -> SpriteFrames effetto a schermo intero (4 lati)
var _active_combo_fx: CanvasLayer = null    # effetto full-screen attualmente in corso
var _active_combo_num: AnimatedSprite2D = null   # numero COMBO attualmente in corso
# --- SCREEN SHAKE (feedback "dopamine" sui match/combo, tutte le modalità) ---
# Scuotiamo DIRETTAMENTE il nodo board (self): i cubi si muovono contro lo sfondo (CanvasLayer
# fisso) → scossa sempre visibile, senza dipendere da una Camera2D "current".
var _shake_base_pos := Vector2.ZERO
var _shake_amount: float = 0.0
const SHAKE_DECAY := 30.0     # px/s di decadimento (più basso = più morbido)
const SHAKE_MAX := 11.0       # ampiezza massima (px) — scossa leggera
var _special_beam_frames: Dictionary = {}        # colore -> SpriteFrames beam V/O per colore
var _beam_clip: Control = null                    # maschera: clippa i beam dentro la griglia
var _moves_since_balance: int = 0           # cooldown mosse per il bilanciamento
var _last_shown_score: int = -1             # per l'animazione pop del punteggio
var _score_pop_tween: Tween = null
var _score_count_tween: Tween = null
# Statistiche partita (per calibrare la durata)
var _game_start_ms: int = 0
var _stat_placements: int = 0
var _stat_moves_earned: int = 0   # mosse guadagnate nella partita (per calibrare l'economia)
var _last_session_stats: String = ""
# Combo + suggerimenti
var _combo_count: int = 0                    # match wave nella catena corrente (ricompensa)
var _find_wave: int = 0                       # ondata di find_matches nella catena
var _combo_matches: int = 0                   # TOTALE gruppi di match nella catena (simultanei + cascata)
var _last_combo_shown: int = 0                # combo mostrate finora nella catena (sequenziale 1,2,3...); reset a fine catena
var _color_to_scene: Dictionary = {}         # colore -> scena pezzo (per il refill combo)
var _last_action_ms: int = 0                 # ultimo input del player (per i suggerimenti)
var _hint_ghost: Node2D = null               # fantasma del suggerimento sulla griglia
var _next_hint_ms: int = 0
var _hint_swap_tweens: Array = []            # tween dell'animazione suggerimento swap
var _hint_swap_pieces: Array = []            # cubi animati dallo swap hint
var _hint_swap_base: Array = []              # posizioni originali da ripristinare
var _last_diff_update_ms: int = 0            # throttle aggiornamento difficoltà (tempo)

# =========================================================
# Helpers: Grid/Pixel
# =========================================================
func grid_to_pixel(column: int, row: int) -> Vector2:
	var new_x = x_start + offset * column
	var new_y = y_start + -offset * row
	return Vector2(new_x, new_y)

func pixel_to_grid(pixel_x: float, pixel_y: float) -> Vector2i:
	var new_x = int(round((pixel_x - x_start) / offset))
	var new_y = int(round((pixel_y - y_start) / -offset))
	return Vector2i(new_x, new_y)

func is_in_grid(g: Vector2i) -> bool:
	return g.x >= 0 && g.x < width && g.y >= 0 && g.y < height

func make_2d_array() -> Array:
	var array := []
	for i in width:
		array.append([])
		for j in height:
			array[i].append(null)
	return array

# =========================================================
# Setup iniziale
# =========================================================
func _ready() -> void:
	can_move = true
	_game_start_ms = Time.get_ticks_msec()
	randomize()
	# Modalità test scelta dal menu
	_mode = settings.game_mode
	_is_speedrun = _mode == "speedrun"
	_is_test = _mode == "test"                        # test = sperimentale (bombe swap, ecc.)
	_is_test_6 = _mode == "test6"                     # test6 = CLASSIC identica ma 4 colori
	_is_test_7 = _mode == "test7"                     # test7 = alias storico (ora è il comportamento della CLASSIC)
	if _is_test_6 or _is_test_7:
		_mode = "mode_c"   # trattata come CLASSIC ovunque (bilanciamento classic)
	# STORIA/campagna: gioca con le meccaniche CLASSIC (mode_c) ma con obiettivo punti.
	_is_story = _mode == "story"
	if _is_story:
		_mode = "mode_c"
		_story_target = settings.story_target
		_story_colors = maxi(3, settings.story_colors)
		_story_ab_vert = settings.story_ab_vert
		_story_ab_horiz = settings.story_ab_horiz
		_story_ab_bomb = settings.story_ab_bomb
		_story_abilities.clear()
		if _story_ab_vert: _story_abilities.append(1)
		if _story_ab_horiz: _story_abilities.append(2)
		if _story_ab_bomb: _story_abilities.append(3)
		_story_time = settings.story_time
		_story_goal = settings.story_goal
		_story_goal_cubes = settings.story_goal_cubes
		_story_goal_colors = settings.story_goal_colors.duplicate()
		_story_destroyed = 0
		_story_color_tally = {}
		# difficoltà graduale: posizione nel mondo (0..1) e difficoltà globale (0..1)
		_story_level = maxi(1, settings.story_level)
		_story_wpos = float((_story_level - 1) % 10) / 9.0
		_story_gd = clampf(float(_story_level - 1) / 29.0, 0.0, 1.0)
		# 3 SOGLIE stelle: ⭐ = obiettivo base, ⭐⭐ ≈ 1.8×, ⭐⭐⭐ ≈ 2.8× (colori: tier ×1/×1.7/×2.6)
		_story_score_th = [_story_target, int(round(_story_target * 1.8)), int(round(_story_target * 2.8))]
		_story_cube_th = [_story_goal_cubes, int(round(_story_goal_cubes * 1.8)), int(round(_story_goal_cubes * 2.8))]
		_story_color_tiers = []
		if not _story_goal_colors.is_empty():
			for m in [1.0, 1.7, 2.6]:
				var tier := {}
				for k in _story_goal_colors:
					tier[k] = int(ceil(float(int(_story_goal_colors[k])) * m))
				_story_color_tiers.append(tier)
		_story_stars_shown = 0
	_is_mode_c = _mode == "mode_c" or _is_speedrun or _is_test
	var _story_sr := _is_story and _story_time > 0.0   # livello STORIA a tempo → tema rosso speedrun
	# BOMBE (mooves>=3): si attivano con QUALSIASI swap (senza colore) e sono mostrate in
	# BIANCO/NERO. È il comportamento DI DEFAULT di CLASSIC e SPEEDRUN (ex TEST 7). Le FRECCE
	# (V/O) restano colorate e si attivano col match.
	_bomb_swap = _is_mode_c
	_fall_speed_mult = 1.4 if _is_test else (1.25 if (_mode == "mode_c" and not _is_speedrun) else (1.5 if _is_speedrun else 1.0))
	# TEST: cascate un filo più veloci (meno attesa tra le combo)
	if _is_test:
		var _dtimer := get_parent().get_node_or_null("DestroyTimer") as Timer
		if _dtimer:
			_dtimer.wait_time = 0.45
	_moves_enabled = _mode != "mode_b" and not _is_mode_c
	_swap_costs_move = _mode == "mode_a"
	# Sfondo gameplay a TUTTO SCHERMO (adattivo su iPad/schermi grandi): CanvasLayer dietro tutto.
	# (il vecchio Sfondo aveva dimensione fissa e non copriva gli schermi larghi.)
	var _bg_path := "res://CORE/Assets/Art/Game/sfondo_speedrun.svg" if (_is_speedrun or _story_sr) else "res://CORE/Assets/Art/Game/sfondo_gameplay.png"
	var _bg_layer := CanvasLayer.new()
	_bg_layer.layer = -10
	add_child(_bg_layer)
	var _bgr := TextureRect.new()
	_bgr.texture = load(_bg_path)
	_bgr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_bgr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_bgr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_bgr.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bgr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bg_layer.add_child(_bgr)
	var _old_sfondo := get_node_or_null("../Sfondo")
	if _old_sfondo:
		_old_sfondo.visible = false   # sostituito dal CanvasLayer full-screen
	var _old_bg := get_node_or_null("../BG")   # ColorRect teal a tutto schermo che copriva il nuovo sfondo
	if _old_bg:
		_old_bg.visible = false
	# SPEEDRUN: griglia e sfondo dedicati
	if _is_speedrun:
		var gnode := get_node_or_null("Grid") as TextureRect
		if gnode:
			gnode.texture = load("res://CORE/Assets/Art/Game/griglia_speedrun.svg")
		var bnode := get_node_or_null("GridBorder") as TextureRect
		if bnode:
			bnode.texture = load("res://CORE/Assets/Art/Game/contorno_griglia_speedrun.svg")
		var sfnode := get_node_or_null("../Sfondo") as TextureRect
		if sfnode:
			sfnode.texture = load("res://CORE/Assets/Art/Game/sfondo_speedrun.svg")
		# musica speedrun: SOLO avvio caricamento in background (non bloccante). La riproduce
		# _process quando è pronta -> _ready finisce subito e la board si genera regolarmente.
		ResourceLoader.load_threaded_request(SR_MUSIC_PATH)
		_sr_music_pending = true
		# se disattivi/riattivi la musica dai settings, ferma/riprende anche quella speedrun
		if not settings.music_toggled.is_connected(_on_music_toggled):
			settings.music_toggled.connect(_on_music_toggled)
	# icona uscita: speedrun = freccia ROSSA, classic = X, altre = freccia
	var back_btn := get_node_or_null("../UI/BackButton") as TextureButton
	if back_btn:
		if _is_speedrun or _story_sr:
			back_btn.texture_normal = load("res://CORE/Assets/Art/UI/Game/exit_arrow_red.png")
		elif _mode == "mode_c":
			back_btn.texture_normal = load("res://CORE/Assets/Art/UI/Game/exit_x.png")
		else:
			back_btn.texture_normal = load("res://CORE/Assets/Art/UI/Game/exit_arrow.png")
	# speedrun (anche storia a tempo): impostazioni ROSSE
	if _is_speedrun or _story_sr:
		var set_btn := get_node_or_null("../UI/SettingsButton") as TextureButton
		if set_btn:
			set_btn.texture_normal = load("res://CORE/Assets/Art/UI/Game/settings_red.png")
	# STORIA: griglia quadrata custom (es. 3×3) centrata nell'area 576×576 della board,
	# cubi scalati alla dimensione della cella, sfondo griglia dedicato.
	if _is_story:
		var side: int = maxi(3, settings.story_grid)
		width = side
		height = side
		offset = 576.0 / float(side)
		x_start = offset * 0.5          # centro colonna 0 (es. 96 per 3×3)
		y_start = 814.0 - offset * 0.5  # 814 = bordo inferiore della Grid TextureRect
		_grid_piece_scale = offset / BASE_CELL
		_cell_sprite_scale = CELL_SPRITE_SCALE * (offset / BASE_CELL)
		var gnode := get_node_or_null("Grid") as TextureRect
		if gnode:
			# livelli a tempo (speedrun) = griglia ROSSA della stessa dimensione
			var suffix := "_red" if _story_sr else ""
			if side == 3:
				gnode.texture = load("res://CORE/Assets/Art/Game/griglia_3x3%s.svg" % suffix)
			elif side == 5:
				gnode.texture = load("res://CORE/Assets/Art/Game/griglia_5x5%s.svg" % suffix)
			else:
				gnode.texture = load("res://CORE/Assets/Art/Game/griglia_new%s.svg" % suffix)
		# STORIA: dimensione/posizione del tray per griglia (più piccoli che in passato)
		if side <= 3:
			_bottom_scale = 1.45
			bottom_spacing_px = 158
			bottom_y_offset_pixels = 198
		elif side == 5:
			_bottom_scale = 1.1
			bottom_spacing_px = 132
			bottom_y_offset_pixels = 150
		# STORIA a tempo (speedrun): bordo griglia + sfondo ROSSI (la griglia resta dimensionata)
		if _story_sr:
			var bnode := get_node_or_null("GridBorder") as TextureRect
			if bnode:
				bnode.texture = load("res://CORE/Assets/Art/Game/contorno_griglia_speedrun.svg")
			var sfnode := get_node_or_null("../Sfondo") as TextureRect
			if sfnode:
				sfnode.texture = load("res://CORE/Assets/Art/Game/sfondo_speedrun.svg")
	_build_plus_pools()
	if _bomb_swap:
		_load_bomb_frames()
	# colori attivi iniziali (speedrun parte da 3 = tanti match; classic da 5)
	if _is_mode_c:
		_mc_active_count = _mode_c_active_count()
	current_moves = max_moves
	# mode_b: niente contatore mosse a schermo.
	# mode_c: riusa quel contatore per le COMBO totali fatte.
	if not _moves_enabled:
		# COMBO e HighScore rimossi dalla zona sopra la griglia (nascosti in gameplay)
		var mv = get_node_or_null("../UI/MOOVES")
		if mv:
			mv.visible = false
		var hs0 = get_node_or_null("../UI/HighScore")
		if hs0:
			hs0.visible = false
	if _is_speedrun:
		_setup_speedrun_ui()
	# STORIA a tempo (livelli speedrun della campagna): riusa l'UI/timer dello speedrun
	if _is_story and _story_time > 0.0:
		_speedrun_time_left = _story_time
		_setup_speedrun_ui()
	# HUD obiettivo + barra (per TUTTI i livelli storia; layout diverso se a tempo)
	if _is_story:
		_setup_story_hud()
	all_pieces = make_2d_array()
	cell_active = make_2d_array()
	# mappa colore -> scena pezzo (serve al refill combo E ai pool Mode C):
	# va costruita PRIMA di generare la scacchiera iniziale.
	for scene in possible_pieces:
		var inst = scene.instantiate()
		var col = inst.get("color")
		if col != null:
			_color_to_scene[str(col)] = scene
		inst.free()
	if _is_mode_c:
		_build_mode_c_pools()
		if _tutorial_should_run() and not _is_story:
			_tut_begin()           # TUTORIAL guidato: board + tray scriptati (niente random)
		else:
			_spawn_mode_c_start()  # griglia iniziale casuale/varia (non scacchiera)
			if _is_story:
				_story_seed_abilities()   # abilità del livello VISIBILI fin dall'inizio
			_spawn_bottom_pieces()
			_animate_board_intro()   # riempimento dall'alto verso il basso
	else:
		_spawn_checkerboard()
		_spawn_bottom_pieces()
		_animate_board_intro()
	update_moves_label()
	_setup_shake_camera()
	_load_scores()
	_prev_high_score = high_score   # record da battere in questa partita
	_prev_speedrun_best = _speedrun_best
	score = 0
	_update_point_label()
	_update_high_score_labels_everywhere()

	# SpriteFrames condiviso per l'animazione di esplosione
	_explo_frames = SpriteFrames.new()
	_explo_frames.add_animation("boom")
	_explo_frames.set_animation_loop("boom", false)
	_explo_frames.set_animation_speed("boom", EXPLO_FPS)
	for tex in EXPLO_FRAMES:
		_explo_frames.add_frame("boom", tex)

	# NB: le animazioni COMBO (numeri + effetti a schermo intero) NON si
	# precaricano tutte qui (erano centinaia di MB -> crash/jetsam). Si caricano LAZY
	# per livello (vedi _get_combo_frames/_get_combo_fx). Per evitare il LAG alla prima
	# combo, i livelli bassi (1..4, i più comuni) si scaldano in BACKGROUND su un thread
	# subito dopo l'avvio: quando servono sono già in cache = niente hitch.
	_preload_common_combos.call_deferred()

	_last_action_ms = Time.get_ticks_msec()

	# DEBUG (tasti TEST home): forza subito una schermata di fine partita da testare
	if settings.debug_gameover != "":
		_debug_go_type = settings.debug_gameover
		settings.debug_gameover = ""
		_run_test_gameover.call_deferred()
		return

	# speedrun: prima di far partire il timer, countdown 3-2-1-GO! (input bloccato)
	if _is_speedrun:
		_speedrun_countdown()

# DEBUG: forza una schermata di fine partita per testarne la grafica (tasti TEST
# nella home). Da rimuovere insieme ai tasti prima della release.
var _debug_test_gameover: bool = false
var _debug_go_type: String = ""            # "classic" | "speedrun" | "record"
var _debug_force_record: int = -1          # -1 nessun override, 0 forza NO record, 1 forza record
func _run_test_gameover() -> void:
	await get_tree().create_timer(0.4).timeout
	if not is_inside_tree():
		return
	_speedrun_started = true
	_debug_test_gameover = true
	if _debug_go_type == "record":
		var base: int = _prev_speedrun_best if _is_speedrun else _prev_high_score
		score = base + 123450   # sopra il record -> NUOVO RECORD
		_debug_force_record = 1
	else:
		score = 5000            # punteggio qualunque, NON record
		_debug_force_record = 0
	_trigger_game_over("time" if _is_speedrun else "no_space")

# --- Speedrun: countdown iniziale 3-2-1-GO! -----------------------------------
func _speedrun_countdown() -> void:
	can_move = false
	_speedrun_started = false
	var dim := _make_countdown_dim()
	for t in ["3", "2", "1", "GO!"]:
		_show_countdown_text(t)
		if t == "GO!":
			settings.play_playbutton()
			settings.vibrate(90)
		else:
			settings.play_tap()
			settings.vibrate(45)
		await get_tree().create_timer(0.7).timeout
		if not is_inside_tree():
			return
	_speedrun_started = true
	can_move = true
	if is_instance_valid(dim):
		var tw := create_tween()
		tw.tween_property(dim, "modulate:a", 0.0, 0.35)
		tw.tween_callback(dim.queue_free)

func _make_countdown_dim() -> ColorRect:
	var ui := get_node_or_null("../UI")
	if ui == null:
		return null
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.offset_left = -400.0
	dim.offset_top = -400.0
	dim.offset_right = 1000.0
	dim.offset_bottom = 1600.0
	dim.z_index = 799   # dietro i numeri (z=800)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	ui.add_child(dim)
	return dim

func _show_countdown_text(txt: String) -> void:
	var ui := get_node_or_null("../UI")
	if ui == null:
		return
	var lbl := Label.new()
	lbl.text = txt
	var pl = ui.get_node_or_null("PointLabel")
	if pl:
		var pf = pl.get_theme_font("font")
		if pf:
			lbl.add_theme_font_override("font", pf)
	lbl.add_theme_font_size_override("font_size", 190)
	lbl.add_theme_color_override("font_color", Color(1, 1, 1))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.offset_left = 38.0
	lbl.offset_right = 538.0
	lbl.offset_top = 380.0
	lbl.offset_bottom = 640.0
	lbl.pivot_offset = Vector2(250.0, 130.0)
	lbl.z_index = 800
	lbl.scale = Vector2(0.4, 0.4)
	lbl.modulate.a = 0.0
	ui.add_child(lbl)
	var tw := create_tween()
	tw.tween_property(lbl, "scale", Vector2(1.15, 1.15), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(lbl, "modulate:a", 1.0, 0.12)
	tw.tween_interval(0.30)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.22)
	tw.parallel().tween_property(lbl, "scale", Vector2(1.5, 1.5), 0.22)
	tw.tween_callback(lbl.queue_free)

# 1) Griglia iniziale a scacchiera: (pezzo, spazio vuoto) alternati
func _spawn_checkerboard() -> void:
	for i in width:
		for j in height:
			if ((i + j) % 2) == 0:
				# celle "piene" iniziali = attive
				cell_active[i][j] = true
				var piece := _random_piece_instance_avoiding_match(i, j)
				add_child(piece)
				_apply_bomb_bw(piece)
				piece.scale = Vector2(_grid_piece_scale, _grid_piece_scale)   # storia: celle grandi (3×3/5×5)
				piece.position = grid_to_pixel(i, j)
				all_pieces[i][j] = piece
			else:
				# buchi: vuoti e saltati dalla gravità finché il player non li riempie
				cell_active[i][j] = false
				all_pieces[i][j] = null

# MODE C: griglia iniziale CASUALE e diversa ogni partita (ammassi/forme varie),
# non la solita scacchiera. Le celle piene = attive con un cubo; le vuote = buchi.
func _spawn_mode_c_start() -> void:
	var filled := _mode_c_fill_pattern()
	for i in width:
		for j in height:
			if filled[i][j]:
				cell_active[i][j] = true
				var piece := _random_piece_instance_avoiding_match(i, j)
				add_child(piece)
				_apply_bomb_bw(piece)
				piece.scale = Vector2(_grid_piece_scale, _grid_piece_scale)   # storia: celle grandi (3×3/5×5)
				piece.position = grid_to_pixel(i, j)
				all_pieces[i][j] = piece
			else:
				cell_active[i][j] = false
				all_pieces[i][j] = null

# Genera un pattern booleano pieno/vuoto. Tavola piena con i BUCHI DISTRIBUITI IN MODO
# OMOGENEO su tutta la griglia (mai spazi vuoti concentrati su un lato/in cima/a bande).
# Varia densità e "texture" così ogni partita è diversa, ma la rottura resta uniforme.
func _mode_c_fill_pattern() -> Array:
	var filled: Array = []
	for i in width:
		filled.append([])
		for j in height:
			filled[i].append(false)

	# STORIA 3×3 (mondo 1): parti con poche celle piene, che AUMENTANO gradualmente col livello
	# (primo livello del mondo = 3, ultimo = 6 su 9): più pieno = più difficile, ma resta giocabile.
	if _is_story and width <= 3:
		var cells: Array = []
		for i in width:
			for j in height:
				cells.append(Vector2i(i, j))
		cells.shuffle()
		var target_fill: int = int(round(lerpf(3.0, 6.0, _story_wpos)))
		for k in range(mini(target_fill, cells.size())):
			var c: Vector2i = cells[k]
			filled[c.x][c.y] = true
		return filled

	# STORIA 5×5/7×7: densità iniziale GRADUALE (primi livelli del mondo più vuoti = più facili,
	# ultimi più pieni = più difficili). Scatter uniforme.
	if _is_story:
		var dens := lerpf(0.42, 0.82, _story_wpos)
		for i in width:
			for j in height:
				filled[i][j] = randf() < dens
		return filled

	var kind := randi() % 3
	if kind == 0:
		# scatter uniforme: buchi sparsi su tutta la tavola
		var p := randf_range(0.76, 0.88)
		for i in width:
			for j in height:
				filled[i][j] = randf() < p
	elif kind == 1:
		# scacchiera + rumore: densità alta e uniforme, texture regolare
		var extra := randf_range(0.55, 0.80)
		for i in width:
			for j in height:
				filled[i][j] = ((i + j) % 2 == 0) or (randf() < extra)
	else:
		# quasi piena, con pochi buchi sparsi in modo omogeneo
		var holes := randf_range(0.12, 0.24)
		for i in width:
			for j in height:
				filled[i][j] = randf() >= holes
	return filled

# Animazione d'ingresso: la griglia si RIEMPIE gradualmente dall'ALTO verso il basso.
# I cubi COMPARIONO sul posto (scala 0→piena + dissolvenza), riga per riga: NON si spostano,
# quindi non "galleggiano" mai né sforano il bordo della griglia.
func _animate_board_intro() -> void:
	var stagger := 0.05
	for i in width:
		for j in height:
			var p = all_pieces[i][j]
			if p == null or not is_instance_valid(p):
				continue
			var base_scale: Vector2 = p.scale
			if base_scale.x <= 0.01:
				base_scale = Vector2(_grid_piece_scale, _grid_piece_scale)
			var d: float = float(height - 1 - j) * stagger   # riga in ALTO per prima
			p.scale = base_scale * 0.3
			p.modulate.a = 0.0
			var tw := create_tween()
			tw.tween_interval(d)
			tw.tween_property(p, "scale", base_scale, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			var tw2 := create_tween()
			tw2.tween_interval(d)
			tw2.tween_property(p, "modulate:a", 1.0, 0.15)

# Evita match immediato sul posizionamento
func _random_piece_instance_avoiding_match(i: int, j: int) -> Node:
	var piece = _spawn_plus_or_normal(INITIAL_PLUS_PROB).instantiate()
	var loops := 0

	while match_at(i, j, piece.color) and loops < 100:
		piece = _spawn_plus_or_normal(INITIAL_PLUS_PROB).instantiate()
		loops += 1

	return piece

# =========================================================
# 2) BottomGrid con 3 pezzi trascinabili
# =========================================================
func _bottom_slot_pixel(slot_idx: int) -> Vector2:
	# centro i 3 slot sotto la griglia
	var grid_pixel_left = grid_to_pixel(0, 0).x
	var grid_pixel_right = grid_to_pixel(width - 1, 0).x
	var grid_center_x = (grid_pixel_left + grid_pixel_right) * 0.5
	var start_x = grid_center_x - bottom_spacing_px
	return Vector2(start_x + slot_idx * bottom_spacing_px, y_start + bottom_y_offset_pixels)

# Sceglie il blocco per uno slot del tray in basso.
func _pick_bottom_piece() -> PackedScene:
	# Il tray in basso è SEMPRE un cubo NORMALE colorato: MAI bombe o abilità (frecce/X/angoli),
	# in NESSUNA modalità. Sceglie direttamente tra i cubi normali (evita del tutto i rami
	# speciali di _pick_normal_piece). Gli speciali compaiono solo sulla board (refill).
	if _is_mode_c and not _mc_normal_scenes.is_empty():
		var n: int = mini(_mc_active_count, _mc_normal_scenes.size())
		return _mc_normal_scenes[randi() % n]
	return possible_pieces.pick_random()

func _spawn_bottom_pieces() -> void:
	for s in range(3):
		if bottom_pieces[s] == null:
			var piece = _pick_bottom_piece().instantiate()
			add_child(piece)
			piece.position = _bottom_slot_pixel(s)
			piece.scale = Vector2(_bottom_scale, _bottom_scale)
			# Etichetta per distinguere logica (non serve modificare lo script del pezzo)
			piece.set_meta("origin", "bottom")
			piece.set_meta("slot_idx", s)
			_apply_select_look(piece)
			bottom_pieces[s] = piece

func _replenish_bottom_slot(slot_idx: int) -> void:
	if bottom_pieces[slot_idx] == null:
		# TUTORIAL: rifornisci col colore richiesto dalla fase (o niente se la fase non usa il tray)
		var _scene: PackedScene
		if _tut_active:
			if _tut_need_color == "" or not _color_to_scene.has(_tut_need_color):
				return
			_scene = _color_to_scene[_tut_need_color]
		else:
			_scene = _pick_bottom_piece()
		var piece = _scene.instantiate()
		add_child(piece)
		piece.position = _bottom_slot_pixel(slot_idx)
		piece.scale = Vector2(_bottom_scale, _bottom_scale)
		piece.set_meta("origin", "bottom")
		piece.set_meta("slot_idx", slot_idx)
		_apply_select_look(piece)
		bottom_pieces[slot_idx] = piece

# I 3 cubi in basso (tray) usano la grafica SELECT del loro colore; sulla griglia tornano normali.
func _select_name(col: String) -> String:
	if col == "blue":
		return "BLU"
	if col == "yellow":
		return "YELLO"
	return col.to_upper()

func _apply_select_look(piece: Node) -> void:
	if _get_piece_mooves(piece) != 0:
		return   # solo cubi NORMALI (gli speciali V/O/bomba hanno la loro grafica)
	var spr := piece.get_node_or_null("Sprite2D") as Sprite2D
	if spr == null:
		return
	if not piece.has_meta("normal_tex"):
		piece.set_meta("normal_tex", spr.texture)
	var path := "res://CORE/Assets/Art/Game/Select/%s.svg" % _select_name(str(piece.get("color")))
	if ResourceLoader.exists(path):
		spr.texture = load(path)

func _restore_normal_look(piece: Node) -> void:
	var spr := piece.get_node_or_null("Sprite2D") as Sprite2D
	if spr and piece.has_meta("normal_tex"):
		spr.texture = piece.get_meta("normal_tex")

# Carica (una volta) i frame delle animazioni delle BOMBE (idle nero/b-n):
# val 3 = normale (3x3), val 4 = X, val 5 = ANGOLI.
func _load_bomb_frames() -> void:
	if not _bomb_anim.is_empty():
		return
	_bomb_anim[3] = _load_frame_seq("res://CORE/Assets/Art/Game/Cubes/_PLUS/Bomb/bomb_%d.png")
	_bomb_anim[4] = _load_frame_seq("res://CORE/Assets/Art/Game/Cubes/_XBOMB/Anim/xbomb_%d.png")
	_bomb_anim[5] = _load_frame_seq("res://CORE/Assets/Art/Game/Cubes/_ANGLES/Anim/angles_%d.png")

func _load_frame_seq(fmt: String) -> Array:
	var frames: Array = []
	for i in range(1, 7):
		var p: String = fmt % i
		if ResourceLoader.exists(p):
			frames.append(load(p))
	return frames

# CLASSIC / SPEEDRUN: le BOMBE (mooves>=3) si attivano indipendentemente dal colore (swap).
# Tutte e 3 (val 3 normale, val 4 X, val 5 ANGOLI) hanno una grafica ANIMATA dedicata
# (nera/b-n) in loop. Fallback shader grigio solo se mancassero i frame.
# Le frecce V/O restano colorate (seguono il match) e non passano di qui.
func _apply_bomb_bw(piece: Node) -> void:
	if piece == null or not _bomb_swap:
		return
	var mv := _get_piece_mooves(piece)
	if mv < 3:
		return
	var spr := piece.get_node_or_null("Sprite2D") as Sprite2D
	if spr == null:
		return
	var frames: Array = _bomb_anim.get(mv, [])
	if frames.is_empty():
		spr.material = _tut_gray_material()   # senza frame: desatura a bianco/nero (fallback)
		return
	# A RIPOSO: solo il PRIMO frame (statico); niente shader (la grafica è già nera).
	# Pixel-art -> filtro NEAREST.
	spr.material = null
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	spr.texture = frames[0]
	# ESPLOSIONE: costruisce l'animazione "match" con TUTTI i frame, esattamente come i cubi
	# normali (piece.gd _apply_skin). Verrà riprodotta da dim() quando la bomba si attiva.
	var player := piece.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if player == null:
		return
	var anim := Animation.new()
	var tr := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(tr, "Sprite2D:texture")
	anim.value_track_set_update_mode(tr, Animation.UPDATE_DISCRETE)
	for i in frames.size():
		anim.track_insert_key(tr, float(i) * BOMB_ANIM_STEP, frames[i])
	anim.length = float(frames.size()) * BOMB_ANIM_STEP
	var lib := player.get_animation_library("")
	if lib:
		if lib.has_animation("match"):
			lib.remove_animation("match")
		lib.add_animation("match", anim)

# =========================================================
# 3) Match detection
# =========================================================
# Colore ai fini del MATCH. In modalità TEST le abilità (mooves>0) sono INERTI:
# non hanno colore, quindi non formano mai match (si attivano solo con lo swap).
func _match_color(p) -> String:
	if p == null:
		return "@none@"
	# TEST / TEST 7: solo le BOMBE (mooves>=3) sono senza colore (inerti al match). Le frecce (1/2)
	# restano colorate e si attivano col match come prima.
	if _bomb_swap and _get_piece_mooves(p) >= 3:
		return "@ability@"
	var c = p.get("color")
	return str(c) if c != null else "@none@"

func match_at(i: int, j: int, color) -> bool:
	if i > 1:
		if all_pieces[i - 1][j] != null and all_pieces[i - 2][j] != null:
			if _match_color(all_pieces[i - 1][j]) == color and _match_color(all_pieces[i - 2][j]) == color:
				return true
	if j > 1:
		if all_pieces[i][j - 1] != null and all_pieces[i][j - 2] != null:
			if _match_color(all_pieces[i][j - 1]) == color and _match_color(all_pieces[i][j - 2]) == color:
				return true
	return false

func find_matches() -> bool:
	var any_match := false
	for i in width:
		for j in height:
			if all_pieces[i][j] != null:
				var current_color = _match_color(all_pieces[i][j])
				if current_color == "@ability@" or current_color == "@none@":
					continue
				# orizzontale
				if i > 0 and i < width - 1:
					if all_pieces[i - 1][j] != null and all_pieces[i + 1][j] != null:
						if _match_color(all_pieces[i - 1][j]) == current_color and _match_color(all_pieces[i + 1][j]) == current_color:
							all_pieces[i - 1][j].matched = true
							all_pieces[i - 1][j].dim()
							all_pieces[i][j].matched = true
							all_pieces[i][j].dim()
							all_pieces[i + 1][j].matched = true
							all_pieces[i + 1][j].dim()
							any_match = true
				# verticale
				if j > 0 and j < height - 1:
					if all_pieces[i][j - 1] != null and all_pieces[i][j + 1] != null:
						if _match_color(all_pieces[i][j - 1]) == current_color and _match_color(all_pieces[i][j + 1]) == current_color:
							all_pieces[i][j - 1].matched = true
							all_pieces[i][j - 1].dim()
							all_pieces[i][j].matched = true
							all_pieces[i][j].dim()
							all_pieces[i][j + 1].matched = true
							all_pieces[i][j + 1].dim()
							any_match = true
	if any_match:
		_find_wave += 1
		# BEAM speciali V/O: parte SUBITO (appena lo speciale entra in un match), cioè
		# prima del DestroyTimer/distruzione dei blocchi. Meta "beam_done" = una volta sola.
		if not _moves_enabled:
			for i in width:
				for j in height:
					var pc = all_pieces[i][j]
					if pc != null and pc.matched and not pc.has_meta("beam_done"):
						var mv := _get_piece_mooves(pc)
						if mv == 1 or mv == 2:
							pc.set_meta("beam_done", true)
							var pcol: String = str(pc.color) if pc.get("color") != null else "red"
							var cc := Vector2i(i, j)
							var hh := mv == 2
							# parte leggermente dopo (ma comunque prima della distruzione)
							get_tree().create_timer(0.12).timeout.connect(func() -> void: _spawn_special_beam(cc, hh, pcol))
		# COMBO = più di un match (simultanei o in cascata). L'animazione è SEQUENZIALE:
		# la prima combo della catena è COMBO 1, poi 2, poi 3... una per wave, MAI a salti
		# (anche se una wave azzera più linee insieme). Reset a fine catena → riparte da 1.
		_combo_matches += _count_new_match_groups()
		if _combo_matches >= 2:
			_last_combo_shown += 1
			var cells: Array = []
			for i in width:
				for j in height:
					if all_pieces[i][j] != null and all_pieces[i][j].matched:
						cells.append(Vector2i(i, j))
			_show_combo_effect(_last_combo_shown, _combo_effect_pos(cells))
		is_resolving = true
		_cancel_drag()
		var dt: Timer = get_parent().get_node("DestroyTimer")
		if _is_speedrun:
			# speedrun: risoluzione RAPIDA e NON riavviata a ogni piazzamento, così più match
			# (anche da mani diverse) si risolvono subito insieme invece di accodarsi/bloccarsi
			if dt.is_stopped():
				dt.start(0.22)
		else:
			dt.start()
	return any_match

func destroy_matched() -> Array:
	var destroyed_positions: Array = []
	var bonus_moves := 0
	var destroyed_count := 0
	var ability_hits: Array = []   # mode_b: cubi +N matchati -> power-up
	var break_tally := {}          # missioni: conteggio cubi rotti per colore

	for i in width:
		for j in height:
			var piece = all_pieces[i][j]
			if piece != null and piece.matched:
				# Somma mooves solo se la proprietà esiste
				var mv := _get_piece_mooves(piece)
				bonus_moves += mv
				# mode_b: registra il power-up del cubo +N (colonna / riga / bomba)
				if not _moves_enabled and mv > 0:
					ability_hits.append({"pos": Vector2i(i, j), "val": mv})

				# Punteggio: conta ogni pezzo distrutto
				destroyed_count += 1

				# missioni: conta il colore del cubo rotto
				var pcol = piece.get("color")
				if pcol != null:
					var cs := str(pcol)
					break_tally[cs] = int(break_tally.get(cs, 0)) + 1

				piece.queue_free()
				all_pieces[i][j] = null
				destroyed_positions.append(Vector2i(i, j))

	# mode_b: attiva i power-up (liberano spazio ed entrano nel conteggio/punteggio)
	if not _moves_enabled:
		for hit in ability_hits:
			destroyed_count += _trigger_powerup(hit["pos"], hit["val"], destroyed_positions)

	# missioni: cubi rotti per colore (dai match)
	for c in break_tally:
		missions.report_break(str(c), int(break_tally[c]))
	# STORIA: conteggio obiettivi (cubi distrutti totali e per colore)
	if _is_story:
		for c in break_tally:
			_story_add_destroyed(str(c), int(break_tally[c]))
		_update_story_hud()

	# 🔹 Bonus mosse (solo classic / mode_a): i cubi +1/+2/+3 danno il loro valore.
	# In mode_b i cubi +N NON danno mosse: sono power-up (gestiti sopra).
	if bonus_moves > 0 and _moves_enabled:
		settings.play_newmove()
		current_moves += bonus_moves
		_stat_moves_earned += bonus_moves
		_show_move_gain_popup(bonus_moves)
		update_moves_label()

	# Applica punteggio
	if destroyed_count > 0:
		if _tut_active:
			_tut_phase_done = true   # tutorial guidato: la fase corrente è completata
		_combo_count += 1   # una wave di match = una combo nella catena (per la ricompensa)
		# SFX + vibrazione: distruzione cubi (più intensa, scala col numero distrutto)
		settings.play_destroy()
		settings.vibrate(45 + min(destroyed_count, 6) * 8)
		# SHAKE dello schermo sul match (scala col numero di cubi distrutti)
		_screen_shake(3.0 + minf(float(destroyed_count), 8.0) * 0.55)

		# Match da 3 cubi = 100 punti base, +30 per ogni cubo oltre i 3,
		# poi MOLTIPLICATORE combo: match normale x1, combo 1 x2, combo 2 x3, ...
		var base_gain := points_per_match + maxi(0, destroyed_count - 3) * 30
		# moltiplicatore = numero di gruppi di match nella catena (match singolo x1, combo1 x2, ...)
		var mult := maxi(1, _combo_matches)
		var gained := base_gain * mult
		score += gained
		lifetime_score += gained
		_show_points_gain_popup(gained)

		# Record live-update: classic -> high_score, speedrun -> _speedrun_best.
		# Aggiornare ANCHE lo speedrun in tempo reale evita che, uscendo dalla
		# partita prima dello scadere del timer, il punteggio venga perso.
		if _is_speedrun:
			if score > _speedrun_best:
				_speedrun_best = score
		elif score > high_score:
			high_score = score

		# UI + Salva
		_update_point_label()
		_update_high_score_labels_everywhere()
		_save_scores()
	_update_difficulty()
	return destroyed_positions

# Power-up del cubo +N matchato (mode_b e mode_c). Libera spazio distruggendo:
#  +1 -> tutta la COLONNA verticale (poi gravità + refill)
#  +2 -> tutta la RIGA orizzontale (poi gravità)
#  +3 -> mode_b: BOMBA 4x4 (si riempie) | mode_c: BOMBA 5x5 che lascia un CRATERE
#        vuoto (le celle diventano buchi: niente refill, li riempie il giocatore).
# I cubi colpiti NON riattivano altri power-up (niente catene infinite).
func _trigger_powerup(center: Vector2i, val: int, destroyed_positions: Array) -> int:
	var cells: Array = []
	var crater := false      # mode_c +3: lascia il vuoto (buchi) senza refill
	if val == 1:
		for y in height:
			cells.append(Vector2i(center.x, y))
	elif val == 2:
		for x in width:
			cells.append(Vector2i(x, center.y))
	elif val == 4:
		# BOMBA X: due diagonali complete passanti per il centro (forma una X).
		# Lascia SPAZI VUOTI (cratere) da riempire con nuovi blocchi, come le altre bombe mode_c.
		if _is_mode_c:
			crater = true
		var m := maxi(width, height)
		for d in range(-m, m + 1):
			cells.append(Vector2i(center.x + d, center.y + d))   # diagonale \
			cells.append(Vector2i(center.x + d, center.y - d))   # diagonale /
	elif val == 5:
		# BOMBA ANGOLI: rompe i 3 blocchi (a L) in ognuno dei 4 angoli della griglia.
		if _is_mode_c:
			crater = true
		var w1 := width - 1
		var h1 := height - 1
		for corner in [
			[Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1)],
			[Vector2i(w1, 0), Vector2i(w1 - 1, 0), Vector2i(w1, 1)],
			[Vector2i(0, h1), Vector2i(1, h1), Vector2i(0, h1 - 1)],
			[Vector2i(w1, h1), Vector2i(w1 - 1, h1), Vector2i(w1, h1 - 1)],
		]:
			for c in corner:
				cells.append(c)
	elif _is_mode_c:
		# mode_c +3: bomba 3x3 (da -1 a +1), lascia un cratere vuoto e duraturo
		crater = true
		for dx in range(-1, 2):
			for dy in range(-1, 2):
				cells.append(Vector2i(center.x + dx, center.y + dy))
	else:
		# mode_b +3: area 4x4 (da -1 a +2 su entrambi gli assi)
		for dx in range(-1, 3):
			for dy in range(-1, 3):
				cells.append(Vector2i(center.x + dx, center.y + dy))

	# NB: il beam V/O parte già in find_matches (prima del DestroyTimer). Qui i blocchi
	# si distruggono normalmente: essendo dopo il DestroyTimer, il beam è già in corso.
	var is_beam := (val == 1 or val == 2)
	var cleared := 0
	for c in cells:
		if not is_in_grid(c):
			continue
		var p = all_pieces[c.x][c.y]
		if p != null:
			# STORIA: conta i cubi distrutti dalle abilità (colonna/riga/bomba) per gli obiettivi
			if _is_story:
				var _pc = p.get("color")
				if _pc != null:
					_story_add_destroyed(str(_pc), 1)
			all_pieces[c.x][c.y] = null
			# V/O: pop del match (l'esplosione bianca resta SOLO per bomba val 3 / mode_b)
			if is_beam or (_is_mode_c and val != 3 and val != 4 and val != 5):
				_destroy_piece_single(p)
			else:
				_spawn_explosion(grid_to_pixel(c.x, c.y), p)
			cleared += 1
			# cratere: NON entra nella gravità/refill -> il vuoto resta
			if not crater:
				destroyed_positions.append(c)
		if crater:
			cell_active[c.x][c.y] = false   # buco: spazio vuoto e duraturo da riempire
	if cleared > 0:
		if val == 3 or val == 4 or val == 5:
			settings.play_bomb()       # tutte e 3 le bombe: suono dedicato
		elif is_beam:
			settings.play_arrow()      # blocchi V (colonna) / O (riga)
		else:
			settings.play_explosion()  # mode_b
		if val == 3 or val == 4 or val == 5:
			settings.vibrate(500)      # BOMBA: vibrazione fortissima
		elif is_beam:
			# V/O: due vibrazioni di intensità crescente, un po' più lunghe
			settings.vibrate(130)
			get_tree().create_timer(0.16).timeout.connect(func() -> void: settings.vibrate(260))
		else:
			settings.vibrate(60)
	return cleared

# Animazione BEAM dei cubi speciali: verticale per V (colonna), ruotata 90° per O (riga).
# Sempre CENTRATA sul cubo speciale.
func _get_special_beam_frames(color: String) -> SpriteFrames:
	if not _special_beam_frames.has(color):
		var sf := SpriteFrames.new()
		sf.add_animation("b")
		sf.set_animation_loop("b", false)
		sf.set_animation_speed("b", 30.0)
		var i := 1
		while true:
			var p := "res://CORE/Assets/Art/Game/SpecialBeam/%s_%03d.png" % [color, i]
			if not ResourceLoader.exists(p):
				break
			sf.add_frame("b", load(p))
			i += 1
		if sf.get_frame_count("b") == 0 and color != "red":
			sf = _get_special_beam_frames("red")   # fallback
		_special_beam_frames[color] = sf
	return _special_beam_frames[color]

# Maschera che clippa i beam DENTRO l'area della griglia (l'effetto non esce fuori).
func _ensure_beam_clip() -> void:
	if _beam_clip != null and is_instance_valid(_beam_clip):
		return
	_beam_clip = Control.new()
	_beam_clip.clip_contents = true
	_beam_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_beam_clip.z_index = 150   # sopra i cubi, sotto le combo (numero z=200)
	_beam_clip.position = Vector2(x_start - offset * 0.5, y_start - offset * (float(height) - 0.5))
	_beam_clip.size = Vector2(offset * float(width), offset * float(height))
	add_child(_beam_clip)

func _spawn_special_beam(center: Vector2i, horizontal: bool, color: String = "red") -> void:
	var frames := _get_special_beam_frames(color)
	if frames == null or frames.get_frame_count("b") == 0:
		return
	_ensure_beam_clip()
	var asp := AnimatedSprite2D.new()
	asp.sprite_frames = frames
	asp.animation = "b"
	asp.centered = true
	# posizione RELATIVA alla maschera (il beam viene clippato all'area griglia)
	asp.position = grid_to_pixel(center.x, center.y) - _beam_clip.position
	var tex0 := frames.get_frame_texture("b", 0)
	asp.scale = Vector2.ONE * (offset / float(tex0.get_width()))   # larghezza beam = una cella
	if horizontal:
		asp.rotation = PI / 2.0   # O: beam orizzontale (ruotato di 90°)
	asp.speed_scale = 1.5
	_beam_clip.add_child(asp)
	asp.animation_finished.connect(asp.queue_free)
	asp.play("b")

# Distrugge un blocco con l'animazione SINGOLA del match (pop), non l'esplosione bianca.
func _destroy_piece_single(p: Node) -> void:
	if p.has_method("dim"):
		p.dim()
	get_tree().create_timer(0.32).timeout.connect(func() -> void:
		if is_instance_valid(p):
			p.queue_free()
	)

func _apply_local_gravity(destroyed_positions: Array) -> void:
	# collassa solo le colonne toccate dal match
	var affected_columns: Array = []
	for pos in destroyed_positions:
		if not affected_columns.has(pos.x):
			affected_columns.append(pos.x)

	for x in affected_columns:
		_collapse_column(x)
		_refill_column_active(x)

func _collapse_column(x: int) -> void:
	# Compatta verso il basso SOLO le celle attive. I buchi (celle non attive)
	# vengono saltati: un cubo che cade non si ferma nel buco, ci passa oltre.
	var cubes: Array = []
	var active_rows: Array = []
	for y in range(0, height):        # y=0 è la riga più in basso
		if cell_active[x][y]:
			active_rows.append(y)
			if all_pieces[x][y] != null:
				cubes.append(all_pieces[x][y])
			all_pieces[x][y] = null

	# rimetti i cubi nelle celle attive più in basso, mantenendo l'ordine
	for k in range(cubes.size()):
		var ry: int = active_rows[k]
		all_pieces[x][ry] = cubes[k]
		var target_px := grid_to_pixel(x, ry)
		if cubes[k].has_method("move"):
			cubes[k].move(target_px, 0.3 * _fall_speed_mult)
		else:
			_tween_to(cubes[k], target_px, 0.15)

# Riempie dall'alto le celle ATTIVE ancora vuote della colonna (dopo il collasso),
# facendo scendere nuovi cubi che saltano i buchi. I buchi restano vuoti.
func _refill_column_active(x: int) -> void:
	var count := 0
	for y in range(0, height):           # dal basso verso l'alto: le celle attive vuote sono in alto
		if cell_active[x][y] and all_pieces[x][y] == null:
			# con una certa probabilità (più alta all'inizio) scegli un colore che forma una combo
			var piece
			var combo_color := ""
			if randf() < _combo_refill_bias():
				combo_color = _match_color_at(x, y)
			if combo_color != "" and _color_to_scene.has(combo_color):
				piece = _color_to_scene[combo_color].instantiate()
			else:
				piece = _spawn_plus_or_normal(_effective_plus_prob()).instantiate()
			add_child(piece)
			_apply_bomb_bw(piece)
			piece.scale = Vector2(_grid_piece_scale, _grid_piece_scale)   # storia: celle grandi
			var spawn_row := height + spawn_rows_above + count
			piece.position = grid_to_pixel(x, spawn_row)
			all_pieces[x][y] = piece
			var target_px := grid_to_pixel(x, y)
			if piece.has_method("move"):
				piece.move(target_px, 0.3 * _fall_speed_mult)
			else:
				_tween_to(piece, target_px, 0.2)
			count += 1

func _spawn_empty_drop(x: int, from_row: int, to_row: int) -> void:
	if not enable_empty_fall_fx:
		return
	var ghost := Node2D.new()
	add_child(ghost)

	# rettangolino trasparente
	var poly := Polygon2D.new()
	poly.color = Color(1, 1, 1, 0.10)  # leggermente visibile
	var s := float(offset) * 0.7
	poly.polygon = PackedVector2Array([
		Vector2(-s * 0.5, -s * 0.5),
		Vector2( s * 0.5, -s * 0.5),
		Vector2( s * 0.5,  s * 0.5),
		Vector2(-s * 0.5,  s * 0.5),
	])
	ghost.add_child(poly)

	var start_px := grid_to_pixel(x, from_row)
	var end_px := grid_to_pixel(x, to_row)
	ghost.position = start_px

	var dist := float(abs(from_row - to_row))
	var dur := 0.12 + 0.03 * dist
	var tw := create_tween()
	tw.tween_property(ghost, "position", end_px, dur)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_callback(Callable(ghost, "queue_free"))


func _on_destroy_timer_timeout() -> void:
	var destroyed_cells = destroy_matched()

	# TUTORIAL guidato: niente gravità/refill/cascate — la board resta controllata.
	# La distruzione è avvenuta (_tut_phase_done), _tut_scripted_tick farà avanzare la fase.
	if _tut_active:
		is_resolving = false
		var _dtt = get_parent().get_node_or_null("DestroyTimer")
		if _dtt:
			_dtt.stop()
		_combo_matches = 0
		_find_wave = 0
		_last_combo_shown = 0
		return

	# 1) collassa e riempie SOLO le colonne coinvolte:
	#    i cubi cadono e nuovi cubi scendono dall'alto nelle celle ATTIVE, saltando i buchi
	_apply_local_gravity(destroyed_cells)

	# 2) cascata
	if find_matches():
		return

	# 4) fine cascata → sblocca input
	is_resolving = false

	# Il DestroyTimer NON è one-shot: a fine catena va fermato, altrimenti continua a
	# scattare ogni 0.4s (ri-conterebbe la combo all'infinito). Riparte al match dopo.
	var _dt = get_parent().get_node_or_null("DestroyTimer")
	if _dt:
		_dt.stop()

	# mode_c: conta la combo (catena con 2+ gruppi di match) nel contatore in alto a sx.
	# Conta UNA volta per catena, poi azzera così i tick residui non ri-contano.
	if _is_mode_c and _last_combo_shown >= 1:
		# accumula la combo PIÙ ALTA mostrata nella catena: COMBO 1 = +1 ... COMBO 4 = +4
		_total_combos += _last_combo_shown
		_update_combo_counter()
	_combo_matches = 0
	_find_wave = 0
	_last_combo_shown = 0

	# ricompensa combo: RARA e legata alle catene lunghe (3+). Poco spazio, "fortuna".
	# mode_c: NIENTE blocchi che esplodono a caso (lo spazio lo creano solo match e bombe).
	if not _is_mode_c and _combo_count >= COMBO_REWARD_MIN_CHAIN:
		var bonus := 1
		if _combo_count >= 5:
			bonus = 2   # solo catene molto lunghe danno 2
		_remove_random_blocks_staggered(mini(bonus, COMBO_MAX_BONUS))
	_combo_count = 0

	_maybe_balance_board()
	check_game_over()

func _tween_to(node: Node2D, to_pos: Vector2, dur: float = 0.15) -> void:
	var tw := create_tween()
	tw.tween_property(node, "position", to_pos, dur * _fall_speed_mult)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_OUT)

func _refill_destroyed_cells_random(destroyed_cells: Array) -> void:
	# Refill solo sulle colonne coinvolte
	var affected_columns: Array = []
	for pos in destroyed_cells:
		if not affected_columns.has(pos.x):
			affected_columns.append(pos.x)

	for x in affected_columns:
		# per ogni null dall'alto verso il basso, decidi cosa "cade": pezzo o vuoto
		for y in range(height - 1, -1, -1):  # dall'alto verso il basso
			if all_pieces[x][y] == null:
				# spawn position "sopra" la griglia
				var spawn_row := height + spawn_rows_above
				# random: pezzo o vuoto
				if randf() > empty_refill_probability:
					var piece = _spawn_plus_or_normal(_effective_plus_prob()).instantiate()
					add_child(piece)
					_apply_bomb_bw(piece)
					piece.scale = Vector2(_grid_piece_scale, _grid_piece_scale)   # storia: celle grandi

					var spawn_px := grid_to_pixel(x, spawn_row)
					var target_px := grid_to_pixel(x, y)
					piece.position = spawn_px

					if piece.has_method("move"):
						piece.move(target_px, 0.3 * _fall_speed_mult)
					else:
						var dist := float(spawn_row - y)
						_tween_to(piece, target_px, 0.15 + 0.03 * dist)

					all_pieces[x][y] = piece
				else:
					all_pieces[x][y] = null
					_spawn_empty_drop(x, spawn_row, y)

# =========================================================
# 4) Swap e annulla se non c'è match
# =========================================================
func swap_pieces(column: int, row: int, direction: Vector2i) -> void:
	if is_game_over or is_resolving:
		return
	var nx = column + direction.x
	var ny = row + direction.y
	if not is_in_grid(Vector2i(nx, ny)):
		return

	var first_piece = all_pieces[column][row]
	var other_piece = all_pieces[nx][ny]
	if first_piece == null or other_piece == null:
		return

	# Esegui swap
	all_pieces[column][row] = other_piece
	all_pieces[nx][ny] = first_piece
	first_piece.move(grid_to_pixel(nx, ny))
	other_piece.move(grid_to_pixel(column, row))

	# MODALITÀ TEST / TEST 7: se lo swap coinvolge un'ABILITÀ, si attiva SUBITO (senza match di colore)
	# nella sua nuova posizione — stile Candy Crush. first_piece è ora a (nx,ny), other a (column,row).
	if _bomb_swap:
		# solo le BOMBE (mooves>=3) esplodono con lo swap; le frecce seguono il match normale
		var mv1 := _get_piece_mooves(first_piece)
		var mv2 := _get_piece_mooves(other_piece)
		if mv1 >= 3 or mv2 >= 3:
			_combo_count = 0
			_find_wave = 0
			_combo_matches = 0
			_last_combo_shown = 0
			if mv1 >= 3:
				first_piece.matched = true
				first_piece.dim()        # esplode con la SUA animazione (come i blocchi)
			if mv2 >= 3:
				other_piece.matched = true
				other_piece.dim()
			is_resolving = true
			# lascia scorrere l'animazione di esplosione, poi distrugge + attiva il power-up
			get_tree().create_timer(BOMB_EXPLODE_TIME).timeout.connect(_on_destroy_timer_timeout)
			return

	# Verifica match
	_combo_count = 0
	_find_wave = 0
	_combo_matches = 0
	_last_combo_shown = 0
	if not find_matches():
		# nessun match -> annulla (revert): non costa nulla
		all_pieces[column][row] = first_piece
		all_pieces[nx][ny] = other_piece
		first_piece.move(grid_to_pixel(column, row))
		other_piece.move(grid_to_pixel(nx, ny))
	elif _swap_costs_move and _moves_enabled and current_moves > 0:
		# mode_a: lo swap che fa match è un'azione -> costa una mossa
		current_moves -= 1
		update_moves_label()
		_show_move_cost_popup()

func _cancel_drag() -> void:
	_hide_placement_preview()
	if dragging_piece != null:
		# torna allo slot
		if dragging_from_slot >= 0:
			dragging_piece.global_position = _bottom_slot_pixel(dragging_from_slot)
			# SNAP diretto alla scala del tray (niente tween: in 3×3 la scala-griglia è molto
			# più grande e l'animazione di ritorno faceva un effetto strano sotto il cubo)
			_kill_piece_scale_tween(dragging_piece)
			dragging_piece.scale = Vector2(_bottom_scale, _bottom_scale)
			_apply_select_look(dragging_piece)   # tornato nel tray: grafica SELECT
		if dragging_piece is CanvasItem:
			dragging_piece.z_index = 0
		dragging_piece = null
		dragging_from_slot = -1

# =========================================================
# Input: swipe per swap nella griglia + drag&drop dei pezzi dal BottomGrid
# =========================================================
func _process(_delta: float) -> void:
	# SCREEN SHAKE: jitter decrescente sulla posizione del nodo board (sui match/combo)
	if _shake_amount > 0.0:
		position = _shake_base_pos + Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _shake_amount
		_shake_amount = maxf(0.0, _shake_amount - _delta * SHAKE_DECAY)
		if _shake_amount <= 0.05:
			_shake_amount = 0.0
			position = _shake_base_pos
	# musica speedrun pronta? riproducila DIRETTAMENTE sull'AudioStreamPlayer della scena
	# (spegnendo la musica dei settings), caricata in background = mai bloccante.
	if _sr_music_pending:
		var st := ResourceLoader.load_threaded_get_status(SR_MUSIC_PATH)
		if st == ResourceLoader.THREAD_LOAD_LOADED:
			_sr_music_pending = false
			var srm := ResourceLoader.load_threaded_get(SR_MUSIC_PATH)
			if srm is AudioStreamMP3:
				(srm as AudioStreamMP3).loop = false   # niente loop: una volta a partita
			var sfp := get_node_or_null("../AudioStreamPlayer2D") as AudioStreamPlayer
			if sfp:
				settings.fade_out_music()      # spegni la musica dei settings (gameplay/home)
				sfp.stream = srm
				# SEMPRE in play: la musica è a TEMPO col timer 5 min (non loop). Se OFF parte
				# comunque, solo MUTATA, e avanza col timer; il toggle la muta/smuta senza
				# riavviarla. Riparte da zero solo con "play again".
				sfp.volume_db = -8.0 if settings.music_enabled else -80.0
				sfp.play()
		elif st == ResourceLoader.THREAD_LOAD_FAILED or st == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			_sr_music_pending = false
	if is_game_over:
		return
	# STORIA: barra di progresso live quando cambia il punteggio (obiettivi a punti)
	if _is_story and _story_hud != null and score != _story_last_score:
		_story_last_score = score
		_update_story_hud()
	# STORIA: 3 STELLE (3 fasi). Appena superi una soglia la stella è SALVATA (best per livello);
	# al raggiungimento della 3ª stella → celebrazione di vittoria.
	if _is_story and not _story_won:
		var st := _story_stars_now()
		if st > _story_stars_shown:
			_story_stars_shown = st
			settings.story_set_stars(_story_level, st)
			_update_story_hud()
			if st >= 3:
				_story_win()
				return
	# STORIA a tempo (livelli campagna speedrun): countdown; a 0 senza obiettivo = sconfitta
	if _is_story and _story_time > 0.0 and not is_game_over:
		_speedrun_time_left -= _delta
		if _speedrun_time_left <= 0.0:
			_speedrun_time_left = 0.0
			_update_timer_label()
			_trigger_game_over("time")
			return
		_update_timer_label()
	if _tut_active:
		_tut_scripted_tick()
	# recupero della soppressione bombe (dopo una bomba la prossima è meno probabile)
	if _bomb_suppress > 0.0:
		_bomb_suppress = maxf(0.0, _bomb_suppress - _delta * 0.05)   # ~20s per tornare normale
	# speedrun: il timer 5 min parte solo dopo il countdown 3-2-1-GO; a 0 finisce la partita
	if _is_speedrun:
		if _speedrun_started:
			_speedrun_time_left -= _delta
			if _speedrun_time_left <= 0.0:
				_speedrun_time_left = 0.0
				_update_timer_label()
				_trigger_game_over("time")
				return
			# colori progressivi basati sul tempo (pochi all'inizio = tanti match)
			_mc_active_count = _mode_c_active_count()
			# rete di sicurezza anti-blocco: se la board è piena, libera spazio
			if not is_resolving and _is_board_full():
				_remove_random_cells(10)
		_update_timer_label()
		# la musica speedrun segue il toggle "Musica" (muta/smuta, non si ferma)
		var _srp := get_node_or_null("../AudioStreamPlayer2D") as AudioStreamPlayer
		if _srp and _srp.playing:
			var _tv := -8.0 if settings.music_enabled else -80.0
			if _srp.volume_db != _tv:
				_srp.volume_db = _tv
	# difficoltà basata sul tempo: aggiorna ~1 volta al secondo anche mentre si risolve
	if Time.get_ticks_msec() - _last_diff_update_ms > 1000:
		_last_diff_update_ms = Time.get_ticks_msec()
		_update_difficulty()
	if is_resolving:
		return
	_handle_grid_touch_swap()
	if not _tut_active:
		_check_idle_hint()

# Suggerimenti se il player resta fermo troppo a lungo
func _check_idle_hint() -> void:
	if dragging_piece != null:
		return
	var now := Time.get_ticks_msec()
	var interval := _hint_interval_ms()
	if now - _last_action_ms < interval:
		return
	if now < _next_hint_ms:
		return
	_next_hint_ms = now + interval
	_show_hint()

# Ritmo dei consigli idle: ~5s all'INIZIO (primi 90s, per capire), poi ~12s più avanti.
func _hint_interval_ms() -> int:
	return 5000 if (Time.get_ticks_msec() - _game_start_ms) < 90000 else 12000

# Swipe per scambiare due pezzi adiacenti nella griglia
func _handle_grid_touch_swap() -> void:
	if can_move == true:
		if Input.is_action_just_pressed("ui_touch"):
			var g = pixel_to_grid(get_global_mouse_position().x, get_global_mouse_position().y)
			if is_in_grid(g):
				first_touch = g
				controlling = true

	if Input.is_action_just_released("ui_touch"):
		if controlling:
			controlling = false
			# NB: la cella di rilascio può finire FUORI dalla griglia quando si "spinge"
			# un cubo verso il bordo alto/basso (lo swipe esce dall'area di gioco). Non serve
			# che sia dentro: basta la DIREZIONE dello swipe — swap_pieces verifica poi che la
			# cella vicina esista davvero. Così gli scambi sui bordi (prima ignorati) funzionano.
			var g = pixel_to_grid(get_global_mouse_position().x, get_global_mouse_position().y)
			final_touch = g
			_touch_difference(first_touch, final_touch)

func _touch_difference(grid_1: Vector2i, grid_2: Vector2i) -> void:
	var difference = grid_2 - grid_1
	if abs(difference.x) > abs(difference.y):
		if difference.x > 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2i(1, 0))
		elif difference.x < 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2i(-1, 0))
	elif abs(difference.y) > abs(difference.x):
		if difference.y > 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2i(0, 1))
		elif difference.y < 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2i(0, -1))

func _input(event: InputEvent) -> void:
	# qualsiasi input del player azzera il timer di inattività e toglie il suggerimento
	if event is InputEventMouseButton or event is InputEventMouseMotion or event is InputEventScreenTouch or event is InputEventScreenDrag:
		_last_action_ms = Time.get_ticks_msec()
		_clear_hint()
	if can_move == true:
		# speedrun: input consentito anche durante le cascate (più mosse in contemporanea)
		if is_game_over or (is_resolving and not _is_speedrun):
			return
		# speedrun: MULTI-TOUCH (un drag indipendente per ogni DITO)
		if _is_speedrun:
			_handle_multitouch(event)
			return
		# Inizio drag: mouse down su un pezzo della BottomGrid
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var clicked := _get_bottom_piece_under_mouse()
			if clicked != null:
				dragging_piece = clicked
				_restore_normal_look(clicked)   # preso col dito: grafica cubo normale
				dragging_from_slot = int(clicked.get_meta("slot_idx"))
				drag_start_pos = clicked.global_position
				# porta sopra gli altri mentre trascini
				if dragging_piece is CanvasItem:
					dragging_piece.z_index = 999
				# animazione fluida: rimpicciolisce alla dimensione della griglia
				_tween_piece_scale(dragging_piece, _grid_piece_scale)
				settings.play_pickup()
		
		# Durante drag
		if dragging_piece != null and event is InputEventMouseMotion:
			dragging_piece.global_position = get_global_mouse_position() + Vector2(0, -DRAG_LIFT)
			_update_placement_preview()

		# Fine drag
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed and dragging_piece != null:
			var target_grid := pixel_to_grid(get_global_mouse_position().x, get_global_mouse_position().y - DRAG_LIFT)

			if is_in_grid(target_grid) \
			and all_pieces[target_grid.x][target_grid.y] == null \
			and (not _moves_enabled or current_moves > 0) \
			and _tut_drop_allowed(dragging_piece, target_grid):
				# Inserimento dalla BottomGrid: se spot vuoto, rimane anche senza match
				dragging_piece.set_meta("origin", "grid")
				_restore_normal_look(dragging_piece)   # sulla griglia: grafica cubo normale
				# ferma OGNI tween di scala di questo pezzo: altrimenti un tween orfano
				# (es. verso 1.35) continua e lascia il cubo piazzato ingrandito/sballato
				_kill_piece_scale_tween(dragging_piece)
				dragging_piece.scale = Vector2(_grid_piece_scale, _grid_piece_scale)
				dragging_piece.global_position = grid_to_pixel(target_grid.x, target_grid.y)
				all_pieces[target_grid.x][target_grid.y] = dragging_piece
				# la cella (anche se era un buco) diventa attiva: da ora partecipa alla gravità
				cell_active[target_grid.x][target_grid.y] = true
				settings.play_place()

				bottom_pieces[dragging_from_slot] = null
				_replenish_bottom_slot(dragging_from_slot)

				# Decrementa una mossa (non in mode_b, dove le mosse non esistono)
				if _moves_enabled:
					current_moves -= 1
					if current_moves < 0:
						current_moves = 0
					update_moves_label() # 👈 aggiorna il testo del label
					_show_move_cost_popup()   # piccola animazione rossa "-1"
				_moves_since_balance += 1
				_stat_placements += 1

				# Punteggio: posizionare un blocco dà 30 punti
				score += points_per_placement
				lifetime_score += points_per_placement
				if _is_speedrun:
					if score > _speedrun_best:
						_speedrun_best = score
				elif score > high_score:
					high_score = score
				_show_points_gain_popup(points_per_placement)
				_update_point_label()
				_update_high_score_labels_everywhere()
				_save_scores()

				check_game_over()

				# Verifica match dopo l’inserimento; se nessun match, valuta il bilanciamento
				_combo_count = 0
				_find_wave = 0
				_combo_matches = 0
				_last_combo_shown = 0
				if not find_matches():
					_maybe_balance_board()

				# Controlla il game over
				check_game_over()
			else:
				# Ritorna allo slot originale se non valido — SNAP diretto alla scala tray
				dragging_piece.global_position = _bottom_slot_pixel(dragging_from_slot)
				_kill_piece_scale_tween(dragging_piece)
				dragging_piece.scale = Vector2(_bottom_scale, _bottom_scale)
				_apply_select_look(dragging_piece)   # tornato nel tray: grafica SELECT
				# TUTORIAL: colore/posto sbagliato → il cubo TRABALLA e torna nel tray
				if _tut_active:
					settings.vibrate(25)
					var _bx: float = dragging_piece.global_position.x
					var _shk := dragging_piece.create_tween()
					_shk.tween_property(dragging_piece, "global_position:x", _bx - 18.0, 0.05)
					_shk.tween_property(dragging_piece, "global_position:x", _bx + 18.0, 0.05)
					_shk.tween_property(dragging_piece, "global_position:x", _bx - 12.0, 0.05)
					_shk.tween_property(dragging_piece, "global_position:x", _bx, 0.05)
				# posto valido ma niente mosse -> scuoti "MOOVES" per farlo capire
				elif current_moves <= 0 and is_in_grid(target_grid) and all_pieces[target_grid.x][target_grid.y] == null:
					_shake_moves_label()

			# Reset parametri di drag
			_hide_placement_preview()
			if dragging_piece is CanvasItem:
				dragging_piece.z_index = 0

			dragging_piece = null
			dragging_from_slot = -1
			get_viewport().set_input_as_handled()

func check_game_over() -> void:
	if _tut_active:
		return   # nel tutorial guidato non si perde mai
	# STORIA — rischio "spazio" GRADUALE per mondo:
	#  • livelli a tempo: mai per spazio (valvola forte).
	#  • Mondo 1 (3×3): non si perde per spazio (valvola 3).
	#  • Mondo 2 (5×5): valvola leggera (1) → si perde molto di rado.
	#  • Mondo 3 (7×7): NESSUNA valvola → si può perdere per spazio (sfida vera).
	if _is_story and _story_time > 0.0:
		if not is_game_over and not is_resolving and _is_board_full():
			_remove_random_cells(10)
		return
	if _is_story and width <= 5:
		if not is_game_over and not is_resolving and _is_board_full():
			_remove_random_cells(3 if width <= 3 else 1)
		return
	if _is_speedrun:
		# speedrun: si perde SOLO a tempo, mai per spazio. Se la board si riempie del tutto
		# libera automaticamente qualche cella (valvola), così non si resta MAI bloccati.
		if not is_game_over and not is_resolving and _is_board_full():
			_remove_random_cells(10)
		return
	if is_game_over or is_resolving:
		return

	var deadlock_swaps_only := _is_deadlocked(true, false)
	var deadlock_all := _is_deadlocked(true, true)
	var full := _is_board_full()

	# 1) mosse finite + nessuna mossa possibile
	if current_moves <= 0 and deadlock_swaps_only:
		update_moves_label()
		_trigger_game_over("no_moves")
		return

	# 2) griglia piena + nessuna mossa possibile
	if full and deadlock_all:
		update_moves_label()
		_trigger_game_over("no_space")


func _get_bottom_piece_under_mouse() -> Node:
	return _bottom_piece_at(get_global_mouse_position())

func _bottom_piece_at(mouse_pos: Vector2) -> Node:
	# Area di tocco FISSA e generosa ancorata al CENTRO DELLO SLOT (non alla texture/scala
	# corrente del pezzo). Così il tap "prende" sempre — anche subito dopo un piazzamento o
	# mentre il pezzo rientra/anima — e copre tutta la cella del tray senza zone morte.
	# Vale sia per il drag normale sia per il multitouch della speedrun.
	var hw := bottom_spacing_px * 0.5
	var hh := bottom_spacing_px * 0.62
	for s in range(3):
		var p: Node = bottom_pieces[s]
		if p == null:
			continue
		var center: Vector2 = to_global(_bottom_slot_pixel(s))
		if absf(mouse_pos.x - center.x) <= hw and absf(mouse_pos.y - center.y) <= hh:
			return p
	return null


# Piazza un pezzo trascinato nella cella sotto world_pos (o lo rimanda allo slot).
# Usato dal MULTI-TOUCH (speedrun); stessa logica del drag singolo.
func _place_dragged_piece(piece: Node, slot: int, world_pos: Vector2) -> void:
	var target_grid := pixel_to_grid(world_pos.x, world_pos.y)
	if is_in_grid(target_grid) and all_pieces[target_grid.x][target_grid.y] == null and (not _moves_enabled or current_moves > 0):
		piece.set_meta("origin", "grid")
		_restore_normal_look(piece)   # sulla griglia: grafica cubo normale
		_kill_piece_scale_tween(piece)   # nessun tween orfano che ingrandisca il cubo piazzato
		piece.scale = Vector2(_grid_piece_scale, _grid_piece_scale)
		piece.global_position = grid_to_pixel(target_grid.x, target_grid.y)
		all_pieces[target_grid.x][target_grid.y] = piece
		cell_active[target_grid.x][target_grid.y] = true
		settings.play_place()
		bottom_pieces[slot] = null
		_replenish_bottom_slot(slot)
		if _moves_enabled:
			current_moves -= 1
			if current_moves < 0:
				current_moves = 0
			update_moves_label()
			_show_move_cost_popup()
		_moves_since_balance += 1
		_stat_placements += 1
		score += points_per_placement
		lifetime_score += points_per_placement
		if _is_speedrun:
			if score > _speedrun_best:
				_speedrun_best = score
		elif score > high_score:
			high_score = score
		_show_points_gain_popup(points_per_placement)
		_update_point_label()
		_update_high_score_labels_everywhere()
		_save_scores()
		check_game_over()
		_combo_count = 0
		_find_wave = 0
		_combo_matches = 0
		_last_combo_shown = 0
		if not find_matches():
			_maybe_balance_board()
		check_game_over()
	else:
		piece.global_position = _bottom_slot_pixel(slot)
		piece.scale = Vector2(_bottom_scale, _bottom_scale)
		_apply_select_look(piece)   # tornato nel tray: grafica SELECT
	if piece is CanvasItem:
		piece.z_index = 0


# Multi-touch (solo speedrun): un drag indipendente per ogni dito (event.index).
func _handle_multitouch(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var wp: Vector2 = get_global_transform_with_canvas().affine_inverse() * event.position
		if event.pressed:
			if _multi_drags.has(event.index):
				return
			var clicked := _bottom_piece_at(wp)
			if clicked != null and not _multi_drags.values().has(clicked):
				_multi_drags[event.index] = clicked
				_restore_normal_look(clicked)   # preso col dito: grafica cubo normale
				if clicked is CanvasItem:
					clicked.z_index = 999
				clicked.scale = Vector2(_grid_piece_scale, _grid_piece_scale)
				settings.play_pickup()
		elif _multi_drags.has(event.index):
			var piece: Node = _multi_drags[event.index]
			_multi_drags.erase(event.index)
			_hide_placement_preview()
			_place_dragged_piece(piece, int(piece.get_meta("slot_idx")), wp - Vector2(0, DRAG_LIFT))
	elif event is InputEventScreenDrag and _multi_drags.has(event.index):
		var piece2: Node = _multi_drags[event.index]
		var fw2: Vector2 = get_global_transform_with_canvas().affine_inverse() * event.position
		piece2.global_position = fw2 - Vector2(0, DRAG_LIFT)
		_show_preview_for(piece2, fw2)   # fantasma di piazzamento anche in speedrun


func update_moves_label() -> void:
	# mode_c: il contatore mostra le COMBO totali, non le mosse
	if _is_mode_c:
		_update_combo_counter()
		return
	var counter_label = $"../UI/MOOVES/Counter"
	if counter_label:
		counter_label.text = str(current_moves)
		counter_label.add_theme_color_override("font_color", _moves_color(current_moves))

func _update_combo_counter() -> void:
	var counter_label = get_node_or_null("../UI/MOOVES/Counter")
	if counter_label:
		counter_label.text = str(_total_combos)
		counter_label.add_theme_color_override("font_color", Color(1, 0.84, 0.10))  # giallo

func _get_piece_mooves(p: Object) -> int:
	if p == null:
		return 0
	var v = p.get("mooves")
	if v == null:
		return 0
	return int(v)


func _would_form_match_at(x: int, y: int, color: String) -> bool:
	if color == "" or color == null:
		return false

	# Orizzontale
	var count := 1
	var i := x - 1
	while i >= 0 and all_pieces[i][y] != null and all_pieces[i][y].color == color:
		count += 1
		i -= 1
	i = x + 1
	while i < width and all_pieces[i][y] != null and all_pieces[i][y].color == color:
		count += 1
		i += 1
	if count >= 3:
		return true

	# Verticale
	count = 1
	var j := y - 1
	while j >= 0 and all_pieces[x][j] != null and all_pieces[x][j].color == color:
		count += 1
		j -= 1
	j = y + 1
	while j < height and all_pieces[x][j] != null and all_pieces[x][j].color == color:
		count += 1
		j += 1
	return count >= 3


func _would_form_match_if_swap(x1: int, y1: int, x2: int, y2: int) -> bool:
	var a = all_pieces[x1][y1]
	var b = all_pieces[x2][y2]
	if a == null or b == null:
		return false

	all_pieces[x1][y1] = b
	all_pieces[x2][y2] = a

	var res: bool = _would_form_match_at(x1, y1, b.color) or _would_form_match_at(x2, y2, a.color)

	all_pieces[x1][y1] = a
	all_pieces[x2][y2] = b
	return res
	
# consider_swaps: se vero, si valuta la possibilità di creare match con uno swap adiacente
# consider_bottom: se vero, si valuta la possibilità di creare match piazzando uno dei 3 pezzi della barra
func _is_deadlocked(consider_swaps: bool = true, consider_bottom: bool = true) -> bool:

	if _board_has_immediate_match():
		return false


	if consider_swaps and _any_valid_swap():
		return false


	if consider_bottom and _any_valid_bottom_placement():
		return false


	return true
	
	
func _board_has_immediate_match() -> bool:
	# Orizzontali
	for y in range(height):
		var run_color: String = ""
		var run_len: int = 0
		for x in range(width):
			var p = all_pieces[x][y]

			# leggi il colore in modo sicuro e tipizzato
			var c: String = ""
			if p != null:
				var v = p.get("color")
				if v is String:
					c = v
				elif v != null:
					c = str(v)

			if c != "" and c == run_color:
				run_len += 1
			else:
				if run_len >= 3:
					return true
				run_color = c
				run_len = (1 if c != "" else 0)
		if run_len >= 3:
			return true

	# Verticali
	for x in range(width):
		var run_color_v: String = ""
		var run_len_v: int = 0
		for y in range(height):
			var p2 = all_pieces[x][y]

			var c2: String = ""
			if p2 != null:
				var v2 = p2.get("color")
				if v2 is String:
					c2 = v2
				elif v2 != null:
					c2 = str(v2)

			if c2 != "" and c2 == run_color_v:
				run_len_v += 1
			else:
				if run_len_v >= 3:
					return true
				run_color_v = c2
				run_len_v = (1 if c2 != "" else 0)
		if run_len_v >= 3:
			return true

	return false

func _any_valid_swap() -> bool:
	for y in range(height):
		for x in range(width):
			if x + 1 < width and _would_form_match_if_swap(x, y, x + 1, y):
				return true
			if y + 1 < height and _would_form_match_if_swap(x, y, x, y + 1):
				return true
	return false

func _any_valid_bottom_placement() -> bool:
	for s in range(3):
		var bp: Node = bottom_pieces[s]
		if bp == null:
			continue

		var v = bp.get("color")
		var color: String = ""
		if v is String:
			color = v
		elif v != null:
			color = str(v)

		if color == "":
			continue

		for yy in range(height):
			for xx in range(width):
				if all_pieces[xx][yy] == null and _would_form_match_at(xx, yy, color):
					return true
	return false

# STORIA: obiettivo punti raggiunto → livello completato (overlay + ritorno alla mappa).
# STORIA: registra un cubo distrutto (totale + per colore) per gli obiettivi del livello.
func _story_add_destroyed(color: String, n: int) -> void:
	_story_destroyed += n
	_story_color_tally[color] = int(_story_color_tally.get(color, 0)) + n

func _story_fmt_num(n: int) -> String:
	var s := str(n)
	var out := ""
	var c := 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		c += 1
		if c % 3 == 0 and i > 0:
			out = "." + out
	return out

func _story_color_short(key: String) -> String:
	match key:
		"red": return loc.t("Rossi")
		"green": return loc.t("Verdi")
		"yellow": return loc.t("Gialli")
	return key

func _setup_story_hud() -> void:
	var ui := get_node_or_null("../UI")
	if ui == null:
		return
	var pfont: Font = null
	var timed := _story_time > 0.0
	var pl = ui.get_node_or_null("PointLabel") as Label
	if pl:
		pfont = pl.get_theme_font("font")
		if timed:
			pl.add_theme_font_size_override("font_size", 42)
			pl.offset_top = 86.0
			pl.offset_bottom = 128.0
		else:
			pl.add_theme_font_size_override("font_size", 66)
			pl.offset_top = 128.0
			pl.offset_bottom = 218.0
	# 3 STELLE in alto, centrate tra la X e le impostazioni
	_story_star_icons.clear()
	var ssz := 46.0
	var sgap := 16.0
	var stot := 3.0 * ssz + 2.0 * sgap
	var sx0 := (576.0 - stot) * 0.5
	for i in 3:
		var sic := TextureRect.new()
		sic.texture = STORY_STAR_EMPTY
		sic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		sic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		sic.position = Vector2(sx0 + i * (ssz + sgap), 2.0)
		sic.size = Vector2(ssz, ssz)
		sic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ui.add_child(sic)
		_story_star_icons.append(sic)
	# ETICHETTA obiettivo/progresso (sotto le stelle)
	_story_hud = Label.new()
	if pfont:
		_story_hud.add_theme_font_override("font", pfont)
	_story_hud.add_theme_font_size_override("font_size", 30)
	_story_hud.add_theme_color_override("font_color", Color(1, 0.92, 0.45))
	_story_hud.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_story_hud.add_theme_constant_override("outline_size", 6)
	_story_hud.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_story_hud.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_story_hud.offset_left = 20.0
	_story_hud.offset_right = 556.0
	_story_hud.offset_top = 52.0
	_story_hud.offset_bottom = 86.0
	_story_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(_story_hud)
	# TIMER (livelli a tempo) sotto il punteggio
	if timed and _timer_label:
		_timer_label.add_theme_font_size_override("font_size", 62)
		_timer_label.offset_top = 150.0
		_timer_label.offset_bottom = 228.0
	# BARRA DI PROGRESSO pixel verso le 3 stelle — solo nei livelli NON a tempo (a tempo c'è il timer)
	if not timed:
		var bx := 128.0
		var bw := 320.0
		var by := 90.0
		var bh := 26.0
		var border := ColorRect.new()
		border.color = Color(0.02, 0.05, 0.12)
		border.position = Vector2(bx, by)
		border.size = Vector2(bw, bh)
		border.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ui.add_child(border)
		var track := ColorRect.new()
		track.color = Color(0.11, 0.17, 0.30)
		track.position = Vector2(bx + 5, by + 5)
		track.size = Vector2(bw - 10, bh - 10)
		track.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ui.add_child(track)
		_story_bar_fill = ColorRect.new()
		_story_bar_fill.color = Color(0.29, 0.82, 0.34)
		_story_bar_fill.position = Vector2(bx + 5, by + 5)
		_story_bar_fill.size = Vector2(0, bh - 10)
		_story_bar_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ui.add_child(_story_bar_fill)
		_story_bar_hi = ColorRect.new()
		_story_bar_hi.color = Color(0.55, 0.98, 0.6)
		_story_bar_hi.position = Vector2(bx + 5, by + 5)
		_story_bar_hi.size = Vector2(0, 5)
		_story_bar_hi.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ui.add_child(_story_bar_hi)
		_story_bar_max_w = bw - 10.0
	_update_story_hud()

# quante soglie superate (0..3) dal valore v nell'array crescente arr
func _th_count(v: int, arr: Array) -> int:
	var n := 0
	for t in arr:
		if int(t) > 0 and v >= int(t):
			n += 1
	return n

# STELLE guadagnate ORA (0..3) in base al goal del livello
func _story_stars_now() -> int:
	match _story_goal:
		"cubes":
			return _th_count(_story_destroyed, _story_cube_th)
		"colors":
			var got := 0
			for tier in _story_color_tiers:
				var ok := true
				for k in tier:
					if int(_story_color_tally.get(k, 0)) < int(tier[k]):
						ok = false
						break
				if ok:
					got += 1
				else:
					break
			return got
		_:
			return _th_count(score, _story_score_th)

# progresso complessivo 0..1 verso le 3 stelle (per la barra)
func _story_progress_fraction() -> float:
	match _story_goal:
		"cubes":
			return float(_story_destroyed) / float(maxi(1, int(_story_cube_th[2]) if _story_cube_th.size() == 3 else 1))
		"colors":
			var got := 0
			var need := 0
			if _story_color_tiers.size() == 3:
				var t3: Dictionary = _story_color_tiers[2]
				for k in t3:
					got += mini(int(_story_color_tally.get(k, 0)), int(t3[k]))
					need += int(t3[k])
			return float(got) / float(maxi(1, need))
		_:
			return float(score) / float(maxi(1, int(_story_score_th[2]) if _story_score_th.size() == 3 else 1))

func _update_story_hud() -> void:
	if _story_hud == null:
		return
	# testo progresso verso la 3ª stella (soglia massima)
	var txt := ""
	match _story_goal:
		"cubes":
			var c3: int = int(_story_cube_th[2]) if _story_cube_th.size() == 3 else _story_goal_cubes
			txt = "%s %d/%d" % [loc.t("Cubi"), _story_destroyed, c3]
		"colors":
			var parts: Array = []
			var t3: Dictionary = _story_color_tiers[2] if _story_color_tiers.size() == 3 else _story_goal_colors
			for k in t3:
				parts.append("%s %d/%d" % [_story_color_short(str(k)), mini(int(_story_color_tally.get(k, 0)), int(t3[k])), int(t3[k])])
			txt = "   ".join(parts)
		_:
			var s3: int = int(_story_score_th[2]) if _story_score_th.size() == 3 else _story_target
			txt = "%s / %s" % [_story_fmt_num(score), _story_fmt_num(s3)]
	_story_hud.text = txt
	# stelle: accende quelle raggiunte
	var st := _story_stars_now()
	for i in _story_star_icons.size():
		if is_instance_valid(_story_star_icons[i]):
			_story_star_icons[i].texture = STORY_STAR_FULL if i < st else STORY_STAR_EMPTY
	# barra di progresso (solo dove esiste)
	if _story_bar_fill:
		var w: float = _story_bar_max_w * clampf(_story_progress_fraction(), 0.0, 1.0)
		_story_bar_fill.size.x = w
		if _story_bar_hi:
			_story_bar_hi.size.x = w

# STORIA: l'obiettivo del livello è stato raggiunto?
func _story_goal_met() -> bool:
	match _story_goal:
		"cubes":
			return _story_goal_cubes > 0 and _story_destroyed >= _story_goal_cubes
		"colors":
			if _story_goal_colors.is_empty():
				return false
			for cname in _story_goal_colors:
				if int(_story_color_tally.get(cname, 0)) < int(_story_goal_colors[cname]):
					return false
			return true
		_:
			# "score" e "speedrun": obiettivo a punteggio
			return _story_target > 0 and score >= _story_target

func _story_win() -> void:
	if _story_won:
		return
	_story_won = true
	is_game_over = true
	can_move = false
	# vittoria = 3 STELLE (salva e sblocca il livello successivo)
	settings.story_set_stars(_story_level, 3)
	settings.vibrate(40)
	var layer := CanvasLayer.new()
	layer.layer = 3000
	add_child(layer)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(dim)
	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_CENTER)
	vb.grow_horizontal = Control.GROW_DIRECTION_BOTH
	vb.grow_vertical = Control.GROW_DIRECTION_BOTH
	vb.add_theme_constant_override("separation", 20)
	layer.add_child(vb)
	# riga di 3 STELLE piene (vittoria = 3 stelle)
	var stars_box := HBoxContainer.new()
	stars_box.alignment = BoxContainer.ALIGNMENT_CENTER
	stars_box.add_theme_constant_override("separation", 18)
	for _i in 3:
		var si := TextureRect.new()
		si.texture = STORY_STAR_FULL
		si.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		si.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		si.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		si.custom_minimum_size = Vector2(96, 96)
		stars_box.add_child(si)
	vb.add_child(stars_box)
	var t := Label.new()
	t.text = loc.t("LIVELLO COMPLETATO!")
	t.add_theme_font_override("font", POP_FONT)
	t.add_theme_font_size_override("font_size", 64)
	t.add_theme_color_override("font_color", Color(1, 0.85, 0.2))
	t.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	t.add_theme_constant_override("outline_size", 8)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t)
	var sc := Label.new()
	sc.text = "%d %s" % [score, loc.t("punti")]
	sc.add_theme_font_override("font", POP_FONT)
	sc.add_theme_font_size_override("font_size", 44)
	sc.add_theme_color_override("font_color", Color(1, 1, 1))
	sc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(sc)
	# tasto CLOSE (immagine, testo già stampato): torna alla mappa storia
	var b := TextureButton.new()
	b.texture_normal = load("res://CORE/Assets/Art/Story/btn_close_wide.png")
	b.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	b.ignore_texture_size = true
	b.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	b.custom_minimum_size = Vector2(260, 101)   # 360:140 in scala
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(func() -> void:
		settings.vibrate(15)
		settings.open_story_on_load = true   # torna alla MAPPA storia, non alla home
		transition.change_scene("res://CORE/Scene/MainMenu.tscn"))
	var b_wrap := CenterContainer.new()
	b_wrap.add_child(b)
	vb.add_child(b_wrap)


func _trigger_game_over(reason := "no_space") -> void:
	is_game_over = true
	if _tut_active:
		_tutorial_end()   # sicurezza: chiudi eventuale tutorial ancora aperto

	# Telemetria economia mosse (per calibrare il bilanciamento):
	# mosse spese = piazzamenti; guadagnate = cubi-mossa matchati; residue = fine partita.
	var _dur_s := (Time.get_ticks_msec() - _game_start_ms) / 1000
	print("STATS mode=%s reason=%s dur=%ds score=%d placements=%d moves_earned=%d moves_left=%d net=%+d" % [
		_mode, reason, _dur_s, score, _stat_placements, _stat_moves_earned,
		(current_moves if _moves_enabled else 0), _stat_moves_earned - _stat_placements])

	# Bonus di fine partita: le mosse rimaste diventano punteggio (100 pt l'una)
	# In mode_b non ci sono mosse -> nessun bonus finale.
	_end_moves = current_moves if _moves_enabled else 0
	_end_bonus = _end_moves * END_MOVE_POINTS
	score += _end_bonus
	current_moves = 0

	# mode_c: le combo accumulate durante la partita diventano punteggio (100 pt ciascuna)
	_combo_bonus = _total_combos * COMBO_END_POINTS if _is_mode_c else 0
	score += _combo_bonus

	# missioni: punteggio raggiunto in questa partita + una partita giocata
	missions.report_score(score)
	missions.report_play()
	# missione MENSILE: 500.000 punti in CLASSIC (mode_c, non speedrun)
	if _mode == "mode_c" and not _is_speedrun:
		missions.report_score_classic(score)

	# Nuovo record? (sul punteggio finale, bonus incluso)
	if _is_speedrun:
		_is_new_record = score > _prev_speedrun_best and score > 0
		if score > _speedrun_best:
			_speedrun_best = score
	else:
		_is_new_record = score > _prev_high_score and score > 0
	# DEBUG (tasti TEST): forza lo stato record/non-record per testare le grafiche
	if _debug_force_record == 1:
		_is_new_record = true
	elif _debug_force_record == 0:
		_is_new_record = false

	# Aggiorna HighScore (classic). In speedrun il record è _speedrun_best: non toccare high_score.
	if not _is_speedrun and score > high_score:
		high_score = score

	# Salva su disco
	_save_scores()

	# Classifica online: a fine partita i record sono definitivi
	leaderboard.submit_best("classic", high_score)
	leaderboard.submit_best("speedrun", _speedrun_best)

	# Aggiorna UI
	_update_point_label()
	_update_high_score_labels_everywhere()
	_update_gameover_current_score()

	# Statistiche partita (per calibrare la durata)
	var dur_s: int = (Time.get_ticks_msec() - _game_start_ms) / 1000
	_last_session_stats = "%d:%02d  ·  %d %s  ·  %d %s" % [dur_s / 60, dur_s % 60, _stat_placements, loc.t("pose"), score, loc.t("pt")]
	print("SESSION STATS → durata=%ds pose=%d punteggio=%d" % [dur_s, _stat_placements, score])

	_last_defeat_reason = reason

	# Flusso di sconfitta: strip motivo -> revive -> schermata finale
	var flow = get_node_or_null("%DefeatFlow")
	if flow and not _is_speedrun and not _debug_test_gameover:   # speedrun/test: diritti alla schermata finale
		if not flow.finished.is_connected(_on_defeat_finished):
			flow.finished.connect(_on_defeat_finished)
			flow.revive_requested.connect(_on_revive_requested)
		# la schermata revive si può mostrare max 3 volte per partita
		flow.start(reason, revive_count < MAX_REVIVES)
	else:
		_show_game_over_screen()

func _on_defeat_finished() -> void:
	_show_game_over_screen()

func _on_revive_requested() -> void:
	revive_count += 1
	revive(_last_defeat_reason)

# Continua la partita dopo il REVIVE.
func revive(reason: String) -> void:
	is_game_over = false
	is_resolving = false
	# dopo un revive (reset) riparti sempre con almeno 10 mosse
	current_moves = maxi(current_moves, 10)
	# se non c'era più spazio, libera abbastanza celle per continuare a giocare
	if reason == "no_space":
		_remove_random_cells(10)
	update_moves_label()

# Rimuove n cubi casuali e trasforma quelle celle in BUCHI (spazio reale e duraturo),
# con animazione di esplosione. Usato dal revive quando la tavola è piena.
func _remove_random_cells(n: int) -> void:
	var occupied: Array = []
	for i in width:
		for j in height:
			if all_pieces[i][j] != null:
				occupied.append(Vector2i(i, j))
	occupied.shuffle()
	var removed := 0
	for k in mini(n, occupied.size()):
		var c: Vector2i = occupied[k]
		var piece = all_pieces[c.x][c.y]
		all_pieces[c.x][c.y] = null
		cell_active[c.x][c.y] = false
		_spawn_explosion(grid_to_pixel(c.x, c.y), piece)
		removed += 1
	if removed > 0:
		settings.play_explosion()
		settings.vibrate(50)

func _show_game_over_screen() -> void:
	# invia il punteggio alla CLASSIFICA online a fine partita (così appare anche
	# senza aprire la classifica): speedrun -> "speedrun", classic (mode_c) -> "classic".
	if _is_speedrun:
		leaderboard.submit_best("speedrun", _speedrun_best)
	elif _mode == "mode_c":
		leaderboard.submit_best("classic", high_score)
	# Speedrun: si va dritti alla schermata finale senza DefeatFlow, quindi la
	# board resta sotto. Nascondila (e il timer) così i cubi non si sovrappongono
	# al punteggio mostrato.
	if _is_speedrun:
		visible = false
		if _timer_label:
			_timer_label.visible = false
	# Interstitial a ogni sconfitta (anche speedrun): appare sopra la
	# schermata finale, alla chiusura si ritrova il game over.
	# Il suono finale (Game Over / New High Score) parte SOLO dopo che
	# l'adv e' chiusa e si torna sulla schermata del punteggio. Se non c'e'
	# adv da mostrare, il suono parte subito.
	# suono finale + coriandoli (se record) SOLO dopo la chiusura dell'adv
	var _showed_ad: bool = ads.show_interstitial()
	if _showed_ad:
		ads.interstitial_closed.connect(_on_gameover_after_ad, CONNECT_ONE_SHOT)
	var screen = get_node_or_null("%GameOverScreen")
	if screen:
		if screen.has_method("set_session_stats"):
			screen.set_session_stats(_last_session_stats)
		if screen.has_method("set_end_bonus"):
			screen.set_end_bonus(score, _end_moves, END_MOVE_POINTS)
		# nuovo record -> layout viola "record" in TUTTE le modalità (anche speedrun)
		var rec: bool = _is_new_record
		if screen.has_method("show_result"):
			screen.show_result(rec)
		else:
			screen.visible = true
		if _is_speedrun and screen.has_method("set_speedrun_mode"):
			screen.set_speedrun_mode(_speedrun_best, _is_new_record)
		# etichetta modalità in alto (così negli screenshot si vede CLASSIC / SPEEDRUN)
		if screen.has_method("set_mode_tag"):
			screen.set_mode_tag("speedrun" if _is_speedrun else "classic")
		if screen is CanvasItem:
			screen.z_index = 99999
	# se non c'era adv, esegui subito (dopo aver mostrato lo schermo)
	if not _showed_ad:
		_on_gameover_after_ad()


# Suono finale + coriandoli (se record). Chiamato DOPO la chiusura dell'interstitial
# (o subito se non c'e' adv), così i coriandoli appaiono al ritorno sullo schermo.
func _on_gameover_after_ad() -> void:
	if _is_new_record:
		settings.play_highscore()
	else:
		settings.play_gameover()
	if _is_new_record:
		var s = get_node_or_null("%GameOverScreen")
		if s and s.has_method("play_confetti"):
			s.play_confetti()

# Toggle musica dai settings: ferma/riprende anche la musica speedrun (player della scena).
func _on_music_toggled(enabled: bool) -> void:
	var sfp := get_node_or_null("../AudioStreamPlayer2D") as AudioStreamPlayer
	if sfp == null or sfp.stream == null or not sfp.playing:
		return
	# solo MUTA/SMUTA (non ferma): la musica resta in sync col timer
	sfp.volume_db = -8.0 if enabled else -80.0


# Speedrun: punteggio più piccolo in alto + TIMER grande sotto; nasconde COMBO/HighScore.
func _setup_speedrun_ui() -> void:
	var ui := get_node_or_null("../UI")
	if ui == null:
		return
	var pfont: Font = null
	var pl = ui.get_node_or_null("PointLabel")
	if pl:
		pfont = pl.get_theme_font("font")
		pl.add_theme_font_size_override("font_size", 54)
		pl.offset_top = 50
		pl.offset_bottom = 104
	_timer_label = Label.new()
	if pfont:
		_timer_label.add_theme_font_override("font", pfont)
	_timer_label.add_theme_font_size_override("font_size", 100)
	_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_timer_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_timer_label.offset_left = 38
	_timer_label.offset_right = 538
	_timer_label.offset_top = 104
	_timer_label.offset_bottom = 234
	ui.add_child(_timer_label)
	var mv = ui.get_node_or_null("MOOVES")
	if mv:
		mv.visible = false
	var hs = ui.get_node_or_null("HighScore")
	if hs:
		hs.visible = false
	_update_timer_label()


var _last_timer_sec: int = -1
func _update_timer_label() -> void:
	if _timer_label == null:
		return
	var s := int(ceil(_speedrun_time_left))
	if s == _last_timer_sec:
		return   # aggiorna solo quando cambia il secondo (evita lavoro ogni frame)
	_last_timer_sec = s
	_timer_label.text = "%d:%02d" % [s / 60, s % 60]
	if _speedrun_time_left <= 30.0:
		_timer_label.add_theme_color_override("font_color", Color(0.42, 0.03, 0.03))  # rosso scuro: ultimi 30s
		_timer_label.add_theme_color_override("font_outline_color", Color(1, 1, 1))   # stroke bianco
		_timer_label.add_theme_constant_override("outline_size", 12)
	else:
		_timer_label.add_theme_color_override("font_color", Color(1, 1, 1))
		_timer_label.add_theme_constant_override("outline_size", 0)


func _update_point_label() -> void:
	var lbl := get_node_or_null("%PointLabel")
	if lbl == null:
		lbl = get_node_or_null("../UI/PointLabel")
	if lbl and lbl is Label:
		var increased := _last_shown_score >= 0 and score > _last_shown_score
		_last_shown_score = score
		if increased:
			_animate_score_count(lbl, score)   # numero che sale (come le monete)
			_pop_point_label(lbl)
		else:
			lbl.text = str(score)

# Il punteggio "sale" fino al nuovo valore (stessa idea dell'animazione monete).
func _animate_score_count(lbl: Label, to_v: int) -> void:
	var from_v := int(lbl.text) if lbl.text.is_valid_int() else to_v
	if _score_count_tween != null and _score_count_tween.is_valid():
		_score_count_tween.kill()
	_score_count_tween = lbl.create_tween()
	_score_count_tween.tween_method(func(v: float) -> void: lbl.set_text(str(int(round(v)))), float(from_v), float(to_v), 0.3)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

# Animazione di ingrandimento del numero centrale a ogni guadagno di punti
func _pop_point_label(lbl: Control) -> void:
	lbl.pivot_offset = lbl.size / 2.0
	if _score_pop_tween != null and _score_pop_tween.is_valid():
		_score_pop_tween.kill()
	lbl.scale = Vector2.ONE
	_score_pop_tween = lbl.create_tween()
	_score_pop_tween.tween_property(lbl, "scale", Vector2(1.3, 1.3), 0.09).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_score_pop_tween.tween_property(lbl, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _update_high_score_labels_everywhere() -> void:
	var hs := get_node_or_null("../UI/HighScore")
	if hs and hs is Label:
		hs.text = loc.t("HighScore:") + " " + str(high_score)

	# BEST SCORE del game over: DIPENDE dalla modalità (speedrun -> _speedrun_best,
	# classic -> high_score). Altrimenti in speedrun mostrava il record classico.
	var gos = get_node_or_null("%GameOverScreen")
	if gos:
		var best := gos.get_node_or_null("Items/L_BestScoreNumber")
		if best and best is Label:
			best.text = str(_speedrun_best if _is_speedrun else high_score)

func _update_gameover_current_score() -> void:
	var gos = get_node_or_null("%GameOverScreen")
	if gos:
		var cur := gos.get_node_or_null("Items/L_ScoreNumber")
		if cur and cur is Label:
			cur.text = str(score)

		var best := gos.get_node_or_null("Items/L_BestScoreNumber")
		if best and best is Label:
			best.text = str(high_score)

func _is_board_full() -> bool:
	for x in range(width):
		for y in range(height):
			if all_pieces[x][y] == null:
				return false
	return true

#Menu

func _on_ui_menu_open() -> void:
	can_move = false
	

func _on_settings_menu_menu_closed() -> void:
	can_move = true
	# riprende il gameplay quando si chiudono le impostazioni
	get_tree().paused = false

func _update_difficulty() -> void:
	# Difficoltà GRADUALE = max(tempo, punteggio). Il TEMPO è la leva principale:
	# +1 livello ogni ~3.5 minuti → livello max verso i ~35 min (il punteggio accelera i bravi).
	# Target durate: occasionale 3-8 min, medio 8-15 min, esperto 20-40 min (oltre 1h se tiene viva la partita).
	var elapsed_min := float(Time.get_ticks_msec() - _game_start_ms) / 60000.0
	var time_level := int(elapsed_min / 3.5)
	var score_level := int(score / difficulty_step_score)
	var new_level: int = min(maxi(time_level, score_level), max_difficulty_level)

	if new_level == difficulty_level:
		return

	difficulty_level = new_level
	print("DIFFICOLTÀ → Livello", difficulty_level)

	# Mode C: la difficoltà introduce gradualmente nuovi colori (parte da 5).
	if _is_mode_c:
		_mc_active_count = _mode_c_active_count()

	# Più difficoltà = più vuoti al refill (tavola più ostica)
	var t := float(difficulty_level) / float(max_difficulty_level)
	empty_refill_probability = lerpf(0.63, max_empty_refill_probability, t)

# =========================================================
# Helper: scala pezzi (drag), colore mosse, popup "+N"
# =========================================================
func _tween_piece_scale(p: Node2D, s: float) -> void:
	if p == null:
		return
	# uccidi un eventuale tween di scala ancora attivo su QUESTO pezzo: altrimenti
	# due tween litigano sulla scala e ne resta uno orfano che, al piazzamento,
	# continua ad animare il cubo (es. verso 1.35) lasciandolo ingrandito/sballato.
	_kill_piece_scale_tween(p)
	var tw := p.create_tween()
	tw.tween_property(p, "scale", Vector2(s, s), 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	p.set_meta("scale_tween", tw)
	_drag_scale_tween = tw

# Ferma qualsiasi tween di scala legato a questo pezzo (per-pezzo, non solo l'ultimo).
func _kill_piece_scale_tween(p: Node) -> void:
	if p == null:
		return
	if not p.has_meta("scale_tween"):
		return
	var prev: Variant = p.get_meta("scale_tween")
	if prev is Tween and prev.is_valid():
		prev.kill()
	p.remove_meta("scale_tween")

func _moves_color(m: int) -> Color:
	if m <= 1:
		return Color(0.90, 0.16, 0.16)   # rosso: manca una mossa
	elif m <= 3:
		return Color(1.0, 0.55, 0.10)    # arancione
	elif m <= 5:
		return Color(1.0, 0.84, 0.10)    # giallo
	return Color(1, 1, 1)                 # bianco (default)

func _show_move_gain_popup(amount: int) -> void:
	if amount <= 0:
		return
	var moves_label = get_node_or_null("../UI/MOOVES")
	if moves_label == null:
		return
	var pop := Label.new()
	pop.text = "+" + str(amount)
	pop.add_theme_font_size_override("font_size", 24)
	pop.add_theme_color_override("font_color", Color(0.30, 0.85, 0.35))
	pop.position = Vector2(74, -26)
	pop.z_index = 50
	moves_label.add_child(pop)
	var start_y: float = pop.position.y
	var tw := pop.create_tween()
	tw.tween_property(pop, "position:y", start_y - 22.0, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	var tw2 := pop.create_tween()
	tw2.tween_property(pop, "modulate:a", 0.0, 0.8)
	tw2.tween_callback(pop.queue_free)

# Popup rosso "-1" a OGNI mossa usata: rende tangibile il costo del piazzamento.
func _show_move_cost_popup() -> void:
	var moves_label = get_node_or_null("../UI/MOOVES")
	if moves_label == null:
		return
	var pop := Label.new()
	pop.text = "-1"
	pop.add_theme_font_size_override("font_size", 24)
	pop.add_theme_color_override("font_color", Color(0.95, 0.25, 0.22))
	pop.position = Vector2(74, 6)
	pop.z_index = 50
	pop.pivot_offset = Vector2(10, 14)
	moves_label.add_child(pop)
	var start_y: float = pop.position.y
	# piccolo pop di scala + scende e sfuma
	pop.scale = Vector2(0.4, 0.4)
	var tws := pop.create_tween()
	tws.tween_property(pop, "scale", Vector2(1.15, 1.15), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tws.tween_property(pop, "scale", Vector2(1.0, 1.0), 0.08)
	var tw := pop.create_tween()
	tw.tween_property(pop, "position:y", start_y + 20.0, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	var tw2 := pop.create_tween()
	tw2.tween_interval(0.18)
	tw2.tween_property(pop, "modulate:a", 0.0, 0.4)
	tw2.tween_callback(pop.queue_free)

# Popup verde "+N" sopra il numero grande centrale, a ogni guadagno di punti
func _show_points_gain_popup(amount: int) -> void:
	if amount <= 0:
		return
	var ui = get_node_or_null("../UI")
	if ui == null:
		return
	var pop := Label.new()
	pop.text = "+" + str(amount)
	pop.add_theme_font_override("font", POP_FONT)
	pop.add_theme_font_size_override("font_size", 40)
	pop.add_theme_color_override("font_color", Color(0.25, 0.85, 0.35))
	pop.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pop.size = Vector2(240, 50)
	# classic: centrato, un po' più in basso. speedrun: in alto e spostato a destra
	# del counter (che è centrato) così non si sovrappone a counter/timer.
	if _is_speedrun:
		pop.position = Vector2(288 - 120, 6)   # centrato, SOPRA il counter dei punti
	else:
		pop.position = Vector2(288 - 120, 48)
	pop.z_index = 60
	ui.add_child(pop)
	var start_y: float = pop.position.y
	var tw := pop.create_tween()
	tw.tween_property(pop, "position:y", start_y - 24.0, 0.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	var tw2 := pop.create_tween()
	tw2.tween_property(pop, "modulate:a", 0.0, 0.9)
	tw2.tween_callback(pop.queue_free)

# =========================================================
# Preview di posizionamento: cella evidenziata dove il cubo verrà piazzato
# =========================================================
func _ensure_placement_preview() -> void:
	if _placement_preview != null:
		return
	var spr := Sprite2D.new()
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	spr.z_index = 1                     # sopra la griglia, sotto il pezzo trascinato
	spr.visible = false
	add_child(spr)
	_placement_preview = spr

const PREVIEW_ALPHA := 0.35   # opacità bassa del fantasma

func _update_placement_preview() -> void:
	_show_preview_for(dragging_piece, get_global_mouse_position())

# Mostra il fantasma di piazzamento per un pezzo qualsiasi (usato anche dal multi-touch
# della speedrun, dove i pezzi trascinati non sono `dragging_piece` ma stanno in _multi_drags).
func _show_preview_for(piece: Node, world_pos: Vector2) -> void:
	if piece == null:
		_hide_placement_preview()
		return
	var g := pixel_to_grid(world_pos.x, world_pos.y - DRAG_LIFT)
	if is_in_grid(g) and all_pieces[g.x][g.y] == null and (not _moves_enabled or current_moves > 0):
		_ensure_placement_preview()
		if _preview_fade_tween != null and _preview_fade_tween.is_valid():
			_preview_fade_tween.kill()
		# fantasma del pezzo (texture NORMALE del cubo, non la grafica SELECT del tray)
		var dspr := piece.get_node_or_null("Sprite2D") as Sprite2D
		if piece.has_meta("normal_tex"):
			_placement_preview.texture = piece.get_meta("normal_tex")
		elif dspr:
			_placement_preview.texture = dspr.texture
		_placement_preview.scale = Vector2(_cell_sprite_scale, _cell_sprite_scale)
		_placement_preview.position = grid_to_pixel(g.x, g.y)
		_placement_preview.modulate = Color(1, 1, 1, PREVIEW_ALPHA)
		_placement_preview.visible = true
	else:
		_hide_placement_preview()

func _hide_placement_preview() -> void:
	if _placement_preview == null or not _placement_preview.visible:
		return
	# dissolvenza dolce dell'opacità fino a zero (non scompare di colpo)
	if _preview_fade_tween != null and _preview_fade_tween.is_valid():
		_preview_fade_tween.kill()
	_preview_fade_tween = _placement_preview.create_tween()
	_preview_fade_tween.tween_property(_placement_preview, "modulate:a", 0.0, 0.18).set_trans(Tween.TRANS_SINE)
	_preview_fade_tween.tween_callback(_on_preview_faded)

func _on_preview_faded() -> void:
	if _placement_preview != null:
		_placement_preview.visible = false

# =========================================================
# Esplosione cubo (6 frame) + bilanciamento tavola
# =========================================================
# Memorizza la posizione base del nodo board (a cui si aggiunge il jitter dello shake).
func _setup_shake_camera() -> void:
	_shake_base_pos = position

# Innesca uno shake dello schermo (ampiezza in px); si somma/limita a SHAKE_MAX.
func _screen_shake(strength: float) -> void:
	_shake_amount = minf(SHAKE_MAX, maxf(_shake_amount, strength))


func _spawn_explosion(world_pos: Vector2, piece: Node) -> void:
	var asp := AnimatedSprite2D.new()
	asp.sprite_frames = _explo_frames
	asp.animation = "boom"
	asp.position = world_pos
	asp.scale = Vector2(_cell_sprite_scale, _cell_sprite_scale)
	asp.z_index = 100
	add_child(asp)
	asp.play("boom")
	# il cubo dietro sparisce al 3° frame (indice 2 → t = 2/fps). Timer one-shot: nessuna cattura ripetuta
	get_tree().create_timer(2.0 / EXPLO_FPS).timeout.connect(func() -> void:
		if is_instance_valid(piece):
			piece.queue_free()
	)
	# libera l'overlay a fine animazione + timer di sicurezza (mai residui a schermo)
	asp.animation_finished.connect(asp.queue_free)
	get_tree().create_timer(1.2).timeout.connect(func() -> void:
		if is_instance_valid(asp):
			asp.queue_free()
	)

func _count_occupied() -> int:
	var c := 0
	for i in width:
		for j in height:
			if all_pieces[i][j] != null:
				c += 1
	return c

# Ogni BALANCE_INTERVAL mosse, se la tavola è piena oltre soglia, esplodono
# alcuni blocchi casuali (più è piena, più ne toglie) per dare respiro al player.
func _maybe_balance_board() -> void:
	if is_game_over or is_resolving or _tut_active:
		return
	# mode_b / mode_c (block blast): niente auto-svuotamento, lo spazio è la minaccia
	if _mode == "mode_b" or _is_mode_c:
		return
	var fullness := float(_count_occupied()) / float(width * height)
	if fullness < BALANCE_FULLNESS_TRIGGER:
		return
	# non a ogni mossa
	if _moves_since_balance < BALANCE_COOLDOWN:
		return
	_moves_since_balance = 0
	# quanti: 1 di base, 2 se ≥80%, rarissimamente 3 se ≥85%
	var n := 1
	if fullness >= 0.80:
		n = 2
	if fullness >= 0.85 and randf() < 0.12:
		n = 3
	_remove_random_blocks_staggered(n)

# Rimuove i cubi UNO ALLA VOLTA (non tutti insieme), con un piccolo ritardo tra loro.
func _remove_random_blocks_staggered(n: int) -> void:
	_remove_one_random_block()
	for k in range(1, n):
		get_tree().create_timer(0.45 * k).timeout.connect(_remove_one_random_block)

func _remove_one_random_block() -> void:
	if is_game_over:
		return
	var occupied: Array = []
	for i in width:
		for j in height:
			if all_pieces[i][j] != null:
				occupied.append(Vector2i(i, j))
	if occupied.is_empty():
		return
	var c: Vector2i = occupied[randi() % occupied.size()]
	var piece = all_pieces[c.x][c.y]
	all_pieces[c.x][c.y] = null
	# la cella esplosa torna un buco: spazio reale e duraturo per il player
	cell_active[c.x][c.y] = false
	_spawn_explosion(grid_to_pixel(c.x, c.y), piece)
	settings.play_explosion()
	settings.vibrate(45)

# =========================================================
# Combo: refill che favorisce le combo + suggerimenti al player fermo
# =========================================================
# Probabilità che un cubo in caduta scelga un colore che forma combo (più alta all'inizio)
func _combo_refill_bias() -> float:
	# Le combo sono il cuore del gioco (dopamina): molto presenti all'inizio,
	# ancora ben presenti a difficoltà alta.
	var t := float(difficulty_level) / float(max_difficulty_level)
	# Mode C: combo ancora più frequenti (obiettivo: una combo ogni 1-2 azioni).
	if _is_mode_c:
		if _is_test:
			# TEST: combo FACILISSIME e continue (super dinamica, tanta dopamina).
			# Bias molto alto e falloff quasi assente -> catene lunghe, escalation combo.
			var bt := lerpf(0.90, 0.82, t)
			if _last_combo_shown >= 12:
				bt *= 0.7
			return bt
		if _is_speedrun:
			# SPEEDRUN: le combo NON sono automatiche. Cadenza: si "alimentano" solo ~1
			# piazzamento su 3 (non ogni mossa); nelle altre mosse quasi zero bias.
			var c := _last_combo_shown
			var combo_move := (_stat_placements % 3 == 0)
			var bs := (0.50 if combo_move else 0.04)
			# falloff crescente: ~7 medio, ~10 tosto, ~15 difficile, 20 super raro
			if c >= 18:
				bs *= 0.05
			elif c >= 13:
				bs *= 0.12
			elif c >= 9:
				bs *= 0.25
			elif c >= 6:
				bs *= 0.45
			elif c >= 3:
				bs *= 0.70
			return bs
		# classic (non speedrun): combo un filo più probabili
		var b := lerpf(0.56, 0.40, t)
		if _last_combo_shown >= 3:
			b *= 0.5
		return b
	return lerpf(0.46, 0.16, t)

# Probabilità adattiva dei cubi +mosse: cadono di più quando il player è a corto
# di mosse (aiuto quando serve), di meno quando ne ha tante; la difficoltà li riduce.
# Raggruppa i cubi-mossa per valore (l'array è ordinato per colore: +1,+2,+3).
func _build_plus_pools() -> void:
	_plus_pool = {1: [], 2: [], 3: [], 4: [], 5: []}
	for i in possible_plus_pieces.size():
		var v := (i % 3) + 1
		_plus_pool[v].append(possible_plus_pieces[i])
	for xb in possible_xbomb_pieces:
		_plus_pool[4].append(xb)
	for ab in possible_angles_pieces:
		_plus_pool[5].append(ab)

# MODE C: costruisce le liste colore (normali + bonus) ordinate, per la progressione.
func _build_mode_c_pools() -> void:
	# STORIA usa un ordine colori dedicato (rosso/verde/giallo come 3 base)
	var _color_order: Array = STORY_COLOR_ORDER if _is_story else MODE_C_COLOR_ORDER
	_mc_normal_scenes.clear()
	for c in _color_order:
		if _color_to_scene.has(c):
			_mc_normal_scenes.append(_color_to_scene[c])
	_mc_plus_by_color.clear()
	for i in possible_plus_pieces.size():
		var color: String = MODE_C_PLUS_COLOR_ORDER[i / 3]
		var v := (i % 3) + 1
		if not _mc_plus_by_color.has(color):
			_mc_plus_by_color[color] = {}
		_mc_plus_by_color[color][v] = possible_plus_pieces[i]
	# bomba X (valore 4) e ANGOLI (valore 5) per colore
	for i in possible_xbomb_pieces.size():
		var xcol: String = MODE_C_PLUS_COLOR_ORDER[i]
		if not _mc_plus_by_color.has(xcol):
			_mc_plus_by_color[xcol] = {}
		_mc_plus_by_color[xcol][4] = possible_xbomb_pieces[i]
	for i in possible_angles_pieces.size():
		var acol: String = MODE_C_PLUS_COLOR_ORDER[i]
		if not _mc_plus_by_color.has(acol):
			_mc_plus_by_color[acol] = {}
		_mc_plus_by_color[acol][5] = possible_angles_pieces[i]

# Numero di colori attivi in Mode C: parte da 5, +1 ogni MODE_C_COLORS_PER_STEP livelli.
# SPEEDRUN: pochi colori all'inizio (tantissimi match) — basato sul TEMPO trascorso:
# solo 3 colori per i primi 3 minuti, poi cresce lentamente (+1 ogni ~40s) fino a 6.
func _mode_c_active_count() -> int:
	if _is_story:
		return _story_colors   # STORIA: numero colori FISSO per il livello (3/5/7)
	if _is_test or _is_test_6:
		return 4        # TEST / TEST 6: solo 4 colori
	if _is_speedrun:
		var elapsed := 300.0 - _speedrun_time_left   # secondi giocati
		if elapsed < 60.0:
			return 4        # 1° minuto: 4 colori (con 3 le combo partivano da sole)
		elif elapsed < 120.0:
			return 5        # 2° minuto: 5 colori
		elif elapsed < 180.0:
			return 6        # 3° minuto: 6 colori
		return MODE_C_COLOR_ORDER.size()   # dal 4° minuto: TUTTI i colori (7)
	return clampi(MODE_C_START_COLORS + difficulty_level / MODE_C_COLORS_PER_STEP,
		MODE_C_START_COLORS, MODE_C_COLOR_ORDER.size())

# Sceglie un cubo NORMALE. In Mode C solo tra i colori attivi (progressione).
func _pick_normal_piece() -> PackedScene:
	if _is_test:
		# bombe (senza colore) RARISSIME di base, ma più probabili se la board si riempie:
		# aiutano a liberare spazio senza svuotarla da sola (si può comunque perdere).
		var fullness := float(_count_occupied()) / float(width * height)
		var bombp := lerpf(0.003, 0.035, clampf((fullness - 0.70) / 0.30, 0.0, 1.0))
		if randf() < bombp:
			return _pick_test_ability()
	if _is_mode_c and not _mc_normal_scenes.is_empty():
		var n: int = mini(_mc_active_count, _mc_normal_scenes.size())
		return _mc_normal_scenes[randi() % n]
	return possible_pieces.pick_random()

# Sceglie un cubo-mossa con VALORE pesato dalle mosse correnti:
#  - tante mosse  -> per lo più +1 (presenti ma income basso, così non si accumula)
#  - a corto      -> più +2/+3 (aiuto reale)
func _pick_plus_scene() -> PackedScene:
	if _plus_pool[1].is_empty():
		_build_plus_pools()
	# STORIA: solo le abilità abilitate dal livello (1=colonna, 2=riga, 3=bomba 3×3).
	# Niente bomba X/angoli. Colore attivo così matcha con i normali.
	if _is_story:
		if _story_abilities.is_empty():
			return _pick_normal_piece()
		# la BOMBA (3) è RARA: frecce (1,2) con peso 4, bomba con peso 1 (~1 su 9 se tutte attive)
		var sv: int = _story_weighted_ability()
		var sn: int = mini(_mc_active_count, STORY_COLOR_ORDER.size())
		var scol: String = STORY_COLOR_ORDER[randi() % sn]
		if _mc_plus_by_color.has(scol) and _mc_plus_by_color[scol].has(sv):
			return _mc_plus_by_color[scol][sv]
		return _plus_pool[sv].pick_random()
	if _is_test:
		# TEST: i cubi-bonus COLORATI sono SOLO frecce (V/O) e si attivano col match di colore
		# (come prima). Le bombe sono separate: senza colore, attivate dallo swap.
		var vt := 1 if randf() < 0.5 else 2
		if not _mc_plus_by_color.is_empty():
			var nn: int = mini(_mc_active_count, MODE_C_COLOR_ORDER.size())
			var col: String = MODE_C_COLOR_ORDER[randi() % nn]
			if _mc_plus_by_color.has(col) and _mc_plus_by_color[col].has(vt):
				return _mc_plus_by_color[col][vt]
		return _plus_pool[vt].pick_random()
	var w1: float
	var w2: float
	if _is_mode_c:
		# Mode C: i +N sono power-up (non mosse). La bomba 3x3 è ESCLUSIVA (rarissima), così
		# la board resta piena e si può perdere; anche +1/+2 un po' più rare di prima.
		# +1 colonna 62.3%, +2 riga 37.5%, +3 bomba 3x3 ~0.2% (rarissima).
		w1 = 0.623; w2 = 0.375
		# quando la tavola è quasi piena la bomba diventa un filo più probabile (respiro):
		# a tavola completamente piena +3 sale ~2% -> ~12% (a scapito di +1/+2).
		var fullness := float(_count_occupied()) / float(width * height)
		if fullness >= 0.82:
			var extra := lerpf(0.0, 0.10, clampf((fullness - 0.82) / 0.18, 0.0, 1.0))
			w1 -= extra * 0.6
			w2 -= extra * 0.4
	elif current_moves <= 12:
		w1 = 0.30; w2 = 0.40      # media ~2.0 (+3 = 0.30)
	elif current_moves <= 25:
		w1 = 0.50; w2 = 0.35      # media ~1.65 (+3 = 0.15)
	else:
		w1 = 0.72; w2 = 0.23      # media ~1.33 (+3 = 0.05) — ricco: presenti ma poco income
	# Soppressione bombe: subito DOPO una bomba (+3) la successiva è molto meno
	# probabile (sposta la sua probabilità su +1/+2). Decade nel tempo.
	if _bomb_suppress > 0.0:
		var bomb_p := maxf(0.0, 1.0 - w1 - w2)   # prob attuale della bomba +3
		var cut := bomb_p * _bomb_suppress
		w1 += cut * 0.6
		w2 += cut * 0.4
	# SPEEDRUN: TUTTE le bombe (+3, X, angoli) molto più rare, SOPRATTUTTO all'inizio.
	# fattore ~0.05 nei primi ~40s, sale fino a max 0.60 (comunque più raro della classic).
	var sr_bomb := 1.0
	if _is_speedrun:
		var el := 300.0 - _speedrun_time_left
		sr_bomb = 0.05 + 0.55 * clampf((el - 40.0) / 140.0, 0.0, 1.0)
		# riduci la bomba +3 spostando la sua probabilità su +1/+2
		var bp := maxf(0.0, 1.0 - w1 - w2)
		var cut2 := bp * (1.0 - sr_bomb)
		w1 += cut2 * 0.6
		w2 += cut2 * 0.4
	var r := randf()
	var v := 3
	if r < w1:
		v = 1
	elif r < w1 + w2:
		v = 2
	# BOMBA X: molto RARA di base, ma diventa più probabile quando la tavola si riempie
	# troppo (libera spazio con le due diagonali -> allunga il gameplay). Sostituisce lo speciale.
	var xfull := float(_count_occupied()) / float(width * height)
	var xprob := 0.0035
	if xfull >= 0.75:
		xprob = lerpf(0.0035, 0.20, clampf((xfull - 0.75) / 0.25, 0.0, 1.0))
	xprob *= sr_bomb   # speedrun: X bomb più rara (all'inizio quasi nulla)
	if randf() < xprob:
		v = 4
	# BOMBA ANGOLI: molto RARA di base, ma più probabile se gli ANGOLI sono COPERTI (così
	# aiuta a liberarli e ad allungare il gameplay, soprattutto in classic).
	var corners_occ := 0
	for cc in [Vector2i(0, 0), Vector2i(width - 1, 0), Vector2i(0, height - 1), Vector2i(width - 1, height - 1)]:
		if is_in_grid(cc) and all_pieces[cc.x][cc.y] != null:
			corners_occ += 1
	var aprob := 0.0025
	if corners_occ >= 3:
		aprob = lerpf(0.0025, 0.16, clampf(float(corners_occ - 2) / 2.0, 0.0, 1.0))
	aprob *= sr_bomb   # speedrun: bomba angoli più rara (all'inizio quasi nulla)
	if randf() < aprob:
		v = 5
	# se è uscita una bomba +3, sopprimi la prossima (recupero nel tempo, vedi _process)
	if v == 3:
		_bomb_suppress = 1.0
	# Mode C: il cubo-bonus deve avere un colore ATTIVO (così matcha con i normali).
	if _is_mode_c and not _mc_plus_by_color.is_empty():
		var n: int = mini(_mc_active_count, MODE_C_COLOR_ORDER.size())
		var color: String = MODE_C_COLOR_ORDER[randi() % n]
		if _mc_plus_by_color.has(color) and _mc_plus_by_color[color].has(v):
			return _mc_plus_by_color[color][v]
	return _plus_pool[v].pick_random()

# STORIA: sceglie un'abilità pesata — frecce (1,2) frequenti, BOMBA (3) rara.
func _story_weighted_ability() -> int:
	var pool: Array = []
	for v in _story_abilities:
		var w: int = 1 if v == 3 else 4
		for _k in w:
			pool.append(v)
	if pool.is_empty():
		return int(_story_abilities[0])
	return int(pool[randi() % pool.size()])


# STORIA: mette 1+ abilità del livello sulla board GIÀ all'avvio (visibili subito), rimpiazzando
# un cubo normale con un'abilità dello STESSO colore (così non forma un match immediato).
func _story_seed_abilities() -> void:
	if _story_abilities.is_empty():
		return
	var cap := 1
	if width >= 7:
		cap = 3
	elif width >= 5:
		cap = 2
	cap = mini(cap, _story_abilities.size())
	# abilità di valore più alto prima (bomba > riga > colonna): sono le "appena introdotte"
	var vals: Array = _story_abilities.duplicate()
	vals.sort()
	vals.reverse()
	var cells: Array = []
	for i in width:
		for j in height:
			if all_pieces[i][j] != null:
				cells.append(Vector2i(i, j))
	cells.shuffle()
	var placed := 0
	for v in vals:
		if placed >= cap or cells.is_empty():
			break
		var c: Vector2i = cells.pop_back()
		var old = all_pieces[c.x][c.y]
		if old == null:
			continue
		var color := str(old.color)
		if not (_mc_plus_by_color.has(color) and _mc_plus_by_color[color].has(v)):
			continue
		var np = _mc_plus_by_color[color][v].instantiate()
		add_child(np)
		_apply_bomb_bw(np)
		np.scale = Vector2(_grid_piece_scale, _grid_piece_scale)
		np.position = grid_to_pixel(c.x, c.y)
		old.queue_free()
		all_pieces[c.x][c.y] = np
		placed += 1


# Con probabilità 'prob' restituisce un cubo-mossa (valore pesato dalle mosse),
# altrimenti un cubo normale. Usato da tutti i punti di spawn.
func _spawn_plus_or_normal(prob: float) -> PackedScene:
	if randf() < prob:
		return _pick_plus_scene()
	return _pick_normal_piece()

func _effective_plus_prob() -> float:
	# STORIA: se il livello non prevede abilità, ZERO cubi-bonus (solo normali); altrimenti la
	# frequenza di frecce/bombe d'aiuto CALA col livello (più aiuto all'inizio, meno alla fine).
	if _is_story:
		# meno cubi-abilità di prima (troppe bombe/frecce): cala col livello
		return lerpf(0.09, 0.04, _story_gd) if not _story_abilities.is_empty() else 0.0
	# Mode C: frequenza fissa dei cubi-bonus (leggermente ridotta a difficoltà alta).
	if _is_mode_c:
		# power-up più rari (prima ce n'erano troppi): la board tende a riempirsi -> si può perdere
		var tc := float(difficulty_level) / float(max_difficulty_level)
		return clampf(lerpf(0.10, 0.07, tc), 0.06, 0.12)
	# Rubber-band centrato sulla FASCIA OBIETTIVO (~20-30 mosse a fine partita).
	# Le mosse guadagnate arrivano SOLO da questi cubi-mossa nel refill: se sopra la
	# fascia il rubinetto quasi si chiude, la spesa (1/mossa piazzata) fa calare le
	# mosse verso la fascia invece di accumularle. Sotto la fascia, aiuto forte.
	# Così un giocatore forte (che cancella tanto) non accumula più centinaia di mosse.
	# I cubi-mossa restano SEMPRE ben presenti (floor alto): il bilanciamento
	# dell'income lo fa soprattutto il VALORE (_pick_plus_scene). Qui moduliamo
	# solo la quantità: un po' di più quando sei a corto, un po' meno quando ricco.
	var need := 1.0
	if current_moves <= 6:
		need = 1.9          # a corto: più cubi-mossa (e con valore più alto)
	elif current_moves <= 14:
		need = 1.4
	elif current_moves <= 26:
		need = 1.0
	elif current_moves <= 40:
		need = 0.8
	else:
		need = 0.6          # surplus estremo: freno morbido, ma restano presenti
	var t := float(difficulty_level) / float(max_difficulty_level)
	var diff_mult := lerpf(1.0, 0.7, t)   # a difficoltà alta un filo meno
	return clampf(plus_piece_probability * need * diff_mult, 0.11, 0.6)

# Restituisce un colore che, messo in (x,y), forma un match; "" se nessuno
func _match_color_at(x: int, y: int) -> String:
	for color in _color_to_scene.keys():
		if _would_form_match_at(x, y, color):
			return color
	return ""

# Trova una mossa utile: {slot, cell} con cui uno dei 3 cubi forma un match
func _find_useful_move() -> Dictionary:
	for s in range(3):
		var bp = bottom_pieces[s]
		if bp == null:
			continue
		var v = bp.get("color")
		var color: String = str(v) if v != null else ""
		if color == "":
			continue
		for yy in range(height):
			for xx in range(width):
				if all_pieces[xx][yy] == null and _would_form_match_at(xx, yy, color):
					return {"slot": s, "cell": Vector2i(xx, yy)}
	return {}

func _show_hint() -> void:
	# 1) se hai mosse e c'è un piazzamento utile dei 3 cubi in basso, suggerisci quello
	# NB: NIENTE animazione sul cubo del tray (l'utente non la vuole): solo il fantasma
	# sulla cella della griglia indica dove piazzare.
	if current_moves > 0:
		var move := _find_useful_move()
		if not move.is_empty():
			_wiggle_hint_at(move["cell"], bottom_pieces[int(move["slot"])])
			return
	# 2) altrimenti (mosse finite o niente piazzamento utile): suggerisci uno swap nella griglia
	var sw := _find_useful_swap()
	if not sw.is_empty():
		_show_swap_hint(sw["a"], sw["b"])

# Trova uno scambio tra due cubi adiacenti che forma un match: {a, b} oppure {}
func _find_useful_swap() -> Dictionary:
	for y in range(height):
		for x in range(width):
			if x + 1 < width and _would_form_match_if_swap(x, y, x + 1, y):
				return {"a": Vector2i(x, y), "b": Vector2i(x + 1, y)}
			if y + 1 < height and _would_form_match_if_swap(x, y, x, y + 1):
				return {"a": Vector2i(x, y), "b": Vector2i(x, y + 1)}
	return {}

# Mostra lo scambio suggerito: i due cubi si muovono l'uno verso l'altro e tornano
func _show_swap_hint(a: Vector2i, b: Vector2i) -> void:
	_clear_hint()
	var pa = all_pieces[a.x][a.y]
	var pb = all_pieces[b.x][b.y]
	if pa == null or pb == null:
		return
	var pa_pos: Vector2 = grid_to_pixel(a.x, a.y)
	var pb_pos: Vector2 = grid_to_pixel(b.x, b.y)
	_hint_swap_pieces = [pa, pb]
	_hint_swap_base = [pa_pos, pb_pos]
	if pa is CanvasItem: pa.z_index = 40
	if pb is CanvasItem: pb.z_index = 40
	# un tween per cubo (concorrenti): ognuno va verso l'altro e torna, 3 volte
	var pa_to: Vector2 = pa_pos.lerp(pb_pos, 0.5)
	var pb_to: Vector2 = pb_pos.lerp(pa_pos, 0.5)
	var ta: Tween = pa.create_tween().set_loops(3)
	ta.tween_property(pa, "position", pa_to, 0.3).set_trans(Tween.TRANS_SINE)
	ta.tween_property(pa, "position", pa_pos, 0.3).set_trans(Tween.TRANS_SINE)
	var tb: Tween = pb.create_tween().set_loops(3)
	tb.tween_property(pb, "position", pb_to, 0.3).set_trans(Tween.TRANS_SINE)
	tb.tween_property(pb, "position", pb_pos, 0.3).set_trans(Tween.TRANS_SINE)
	_hint_swap_tweens = [ta, tb]

# Uno dei 3 cubi in basso rimbalza (utile da posizionare)
func _bounce_bottom_piece(slot: int) -> void:
	var p = bottom_pieces[slot]
	if p == null:
		return
	var base_y: float = _bottom_slot_pixel(slot).y
	var tw: Tween = p.create_tween()
	for i in 2:
		tw.tween_property(p, "position:y", base_y - 22.0, 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tw.tween_property(p, "position:y", base_y, 0.24).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

# Fantasma che oscilla avanti e indietro nella cella suggerita (stile Candy Crush)
func _wiggle_hint_at(cell: Vector2i, src: Node) -> void:
	_clear_hint()
	var ghost := Sprite2D.new()
	# usa la texture NORMALE del cubo (i blocchi del tray usano la grafica SELECT, più
	# grande: copiarla farebbe un fantasma troppo grande nella griglia).
	if src != null and src.has_meta("normal_tex"):
		ghost.texture = src.get_meta("normal_tex")
	elif src != null and src.has_node("Sprite2D"):
		ghost.texture = src.get_node("Sprite2D").texture
	ghost.scale = Vector2(_cell_sprite_scale, _cell_sprite_scale)
	ghost.modulate = Color(1, 1, 1, 0.0)   # parte invisibile
	ghost.z_index = 60
	ghost.position = grid_to_pixel(cell.x, cell.y)
	add_child(ghost)
	_hint_ghost = ghost
	# lampeggia 2 volte: 0 -> poca opacità -> 0 (niente movimento laterale)
	var peak := 0.6
	var tw := ghost.create_tween().set_loops(2)
	tw.tween_property(ghost, "modulate:a", peak, 0.28).set_trans(Tween.TRANS_SINE)
	tw.tween_property(ghost, "modulate:a", 0.0, 0.28).set_trans(Tween.TRANS_SINE)
	# dopo i 2 lampeggi la preview sparisce; ricompare al prossimo ciclo (HINT_REPEAT_MS)
	var life := ghost.create_tween()
	life.tween_interval(2.0 * 0.56 + 0.15)
	life.tween_callback(ghost.queue_free)

func _clear_hint() -> void:
	if _hint_ghost != null and is_instance_valid(_hint_ghost):
		_hint_ghost.queue_free()
	_hint_ghost = null
	# ferma l'eventuale animazione di swap e ripristina le posizioni dei cubi
	for t in _hint_swap_tweens:
		if t != null and t.is_valid():
			t.kill()
	_hint_swap_tweens = []
	for i in range(_hint_swap_pieces.size()):
		var p = _hint_swap_pieces[i]
		if p != null and is_instance_valid(p):
			p.position = _hint_swap_base[i]
			if p is CanvasItem:
				p.z_index = 0
	_hint_swap_pieces = []
	_hint_swap_base = []

# Scuote il testo "MOOVES" + numero (in alto a sinistra) quando si prova a
# posizionare un cubo ma le mosse sono finite.
func _shake_moves_label() -> void:
	var m = get_node_or_null("../UI/MOOVES")
	if m == null or not (m is Control):
		return
	settings.vibrate(35)
	var base_x: float = m.position.x
	var tw: Tween = m.create_tween()
	for i in 4:
		tw.tween_property(m, "position:x", base_x - 12.0, 0.05).set_trans(Tween.TRANS_SINE)
		tw.tween_property(m, "position:x", base_x + 12.0, 0.05).set_trans(Tween.TRANS_SINE)
	tw.tween_property(m, "position:x", base_x, 0.05)

# =========================================================
# Animazione COMBO (sopra i cubi della combo, senza coprirli)
# =========================================================
func _combo_effect_pos(cells: Array) -> Vector2:
	if cells.is_empty():
		return Vector2(288, 500)
	var sum_x := 0.0
	var min_y := 1.0e9
	for pos in cells:
		var px := grid_to_pixel(pos.x, pos.y)
		sum_x += px.x
		min_y = min(min_y, px.y)
	var cx: float = sum_x / float(cells.size())
	var effect_w := 500.0 * COMBO_EFFECT_SCALE
	var effect_h := 302.0 * COMBO_EFFECT_SCALE
	# leggermente sopra i cubi della combo
	var cy: float = min_y - offset * 0.4
	# ANCORAGGIO: clampa così l'animazione (più grande) non esce mai dallo schermo
	# design 576x1024: se la combo è a sinistra si sposta a destra (e viceversa), e resta sopra
	cx = clampf(cx, effect_w * 0.5 + 6.0, 576.0 - effect_w * 0.5 - 6.0)
	cy = clampf(cy, 235.0 + effect_h * 0.5, 900.0)
	return Vector2(cx, cy)

# Getter LAZY con cache: costruisce le SpriteFrames del livello solo alla prima
# occorrenza (evita di caricare centinaia di MB in _ready → niente crash memoria).
const COMBO_FRAME_STEP := 2   # usa 1 frame ogni 2: metà upload GPU -> meno lag su device deboli

func _get_combo_frames(level: int) -> SpriteFrames:
	if not _combo_frames.has(level):
		_combo_frames[level] = _build_combo_frames("combo%d" % level, COMBO_FRAME_STEP)
	return _combo_frames[level]

func _get_combo_fx(level: int) -> SpriteFrames:
	if not _combo_fx.has(level):
		var fx := _build_combo_frames("effect%d" % level, COMBO_FRAME_STEP)
		if fx.get_frame_count("c") == 0 and level > 1:
			fx = _get_combo_fx(level - 1)   # es. il 9 (assente) usa l'8
		_combo_fx[level] = fx
	return _combo_fx[level]

# Costruisce le SpriteFrames di una combo. step>1 salta frame (meno texture da caricare/uploadare)
# mantenendo la STESSA durata (fps proporzionale).
func _build_combo_frames(prefix: String, step: int = 1) -> SpriteFrames:
	var sf := SpriteFrames.new()
	sf.add_animation("c")
	sf.set_animation_loop("c", false)
	sf.set_animation_speed("c", 33.0 / float(step))
	var i := 1
	while i <= 200:
		var path := "res://CORE/Assets/Art/Game/Combo/%s_%03d.png" % [prefix, i]
		if not ResourceLoader.exists(path):
			break
		sf.add_frame("c", load(path))
		i += step
	return sf

# Scalda in BACKGROUND (thread) le combo piu' comuni (1..4) subito dopo l'avvio,
# cosi' la prima combo non deve caricare i frame al volo (niente lag/hitch).
func _preload_common_combos() -> void:
	await get_tree().create_timer(0.3).timeout
	if not is_inside_tree():
		return   # partita già uscita
	for lvl in range(1, 5):
		for prefix in ["combo%d" % lvl, "effect%d" % lvl]:
			var i := 1
			while true:
				var p := "res://CORE/Assets/Art/Game/Combo/%s_%03d.png" % [prefix, i]
				if not ResourceLoader.exists(p):
					break
				ResourceLoader.load_threaded_request(p)
				i += COMBO_FRAME_STEP   # solo i frame effettivamente usati
		await get_tree().process_frame
	# NB: non pre-costruiamo le SpriteFrames sul main thread (causava hitch all'avvio):
	# i frame sono già in cache via thread, quindi la prima combo li prende al volo.

# Effetto COMBO a schermo intero: cornice sui 4 lati, adattata a OGNI dispositivo.
# Sta su una CanvasLayer (spazio-schermo, indipendente da camera/risoluzione) e viene
# scalato in modo NON uniforme così tocca esattamente tutti e 4 i bordi.
# TEST: le combo ACCELERANO col livello (combo 1 normale, 2 più veloce, ... 10 velocissima)
# per creare un'escalation di dopamina. Nelle altre modalità nessun cambiamento (1.0).
func _combo_speed_factor(level: int) -> float:
	if not _is_test:
		return 1.0
	return clampf(1.0 + float(level - 1) * 0.13, 1.0, 2.2)


func _show_combo_fullscreen(level: int) -> void:
	var fx: SpriteFrames = _get_combo_fx(level)
	if fx == null or fx.get_frame_count("c") == 0:
		return
	# sostituisci l'effetto precedente (le combo si susseguono rapide)
	if is_instance_valid(_active_combo_fx):
		_active_combo_fx.queue_free()
	var tex0: Texture2D = fx.get_frame_texture("c", 0)
	var fw := float(tex0.get_width())
	var fh := float(tex0.get_height())
	var view := get_viewport_rect().size
	var layer := CanvasLayer.new()
	layer.layer = 90
	add_child(layer)
	_active_combo_fx = layer
	var asp := AnimatedSprite2D.new()
	asp.sprite_frames = fx
	asp.animation = "c"
	asp.centered = true
	asp.position = view * 0.5
	asp.scale = Vector2(view.x / fw, view.y / fh)   # riempie tutti e 4 i lati
	asp.speed_scale = 0.85 * _combo_speed_factor(level)
	layer.add_child(asp)
	asp.animation_finished.connect(layer.queue_free)
	asp.play("c")

func _show_combo_effect(level: int, world_pos: Vector2) -> void:
	var anim_level: int = clampi(level, 1, 20)   # animazioni combo fino alla 20; oltre usa la 20
	# SHAKE più marcato sulle COMBO (cresce col livello di combo)
	_screen_shake(5.0 + float(anim_level) * 0.8)
	_show_combo_fullscreen(anim_level)           # cornice a schermo intero per ogni combo
	var frames: SpriteFrames = _get_combo_frames(anim_level)
	if frames == null or frames.get_frame_count("c") == 0:
		return
	# niente sovrapposizioni: rimuovi il numero COMBO precedente ancora in animazione
	if is_instance_valid(_active_combo_num):
		_active_combo_num.queue_free()
	var asp := AnimatedSprite2D.new()
	asp.sprite_frames = frames
	asp.animation = "c"
	# nel tutorial la combo esce più in basso (era troppo in alto)
	asp.position = world_pos + (Vector2(0, 180) if _tut_active else Vector2.ZERO)
	asp.scale = Vector2(COMBO_EFFECT_SCALE, COMBO_EFFECT_SCALE)
	asp.speed_scale = COMBO_SPEED * _combo_speed_factor(anim_level)
	asp.z_index = 200
	add_child(asp)
	_active_combo_num = asp
	asp.animation_finished.connect(asp.queue_free)
	asp.play("c")
	settings.play_combo(level)
	missions.report_combo(level)   # missioni: "fai una COMBO N"
	# vibrazione un po' più forte a ogni combo (cresce col livello)
	settings.vibrate(48 + mini(level, 5) * 6)

# Conta i gruppi di match (componenti connesse per colore) attualmente marcati.
# Due linee di colore diverso = 2 gruppi (anche se simultanee nella stessa mossa).
func _count_new_match_groups() -> int:
	var visited := {}
	var groups := 0
	for i in width:
		for j in height:
			var c0 := Vector2i(i, j)
			var p = all_pieces[i][j]
			if p != null and p.matched and not visited.has(c0):
				groups += 1
				var col = p.get("color")
				var stack: Array = [c0]
				while not stack.is_empty():
					var c: Vector2i = stack.pop_back()
					if visited.has(c):
						continue
					visited[c] = true
					for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
						var nb: Vector2i = c + d
						if is_in_grid(nb) and not visited.has(nb):
							var np = all_pieces[nb.x][nb.y]
							if np != null and np.matched and np.get("color") == col:
								stack.append(nb)
	return groups


# =========================================================
# MINI-TUTORIAL GUIDATO (prima partita CLASSIC dopo l'installazione)
# =========================================================
# Board SCRIPTATA e semplice: si impara FACENDO. 3 fasi:
#   0) PIAZZA  : due rossi al centro con un buco + tray col rosso → piazzalo = match
#   1) SCAMBIA : setup verde/giallo → uno swap col dito fa match
#   2) FATTO   : "buona partita" → parte la VERA partita random
# Durante il tutorial: niente game over, niente gravità/refill/cascate, niente
# bilanciamento. Il flag "visto" (ver) si salva solo alla FINE.
func _tutorial_should_run() -> bool:
	# solo CLASSIC (mode_c non-speedrun); gating per VERSIONE (salvato a fine tutorial)
	if not _is_mode_c or _is_speedrun or _is_test or _is_test_6 or _is_test_7:
		return false
	if TUT_ALWAYS_TEST and OS.is_debug_build():
		return true   # TEST (build debug): parte sempre
	var cfg := ConfigFile.new()
	cfg.load(TUT_CFG)
	return int(cfg.get_value("tut", "ver", 0)) < TUT_VERSION

func _tut_begin() -> void:
	_tut_active = true
	_tut_phase = 0
	_tut_phase_done = false
	_build_tutorial_ui()
	_tut_setup_place()

# --- Fase 0: PIAZZA un blocco per fare 3 in fila ---
func _tut_setup_place() -> void:
	_tut_clear_board()
	_tut_phase_done = false
	_tut_need_color = "red"
	_tut_target_cell = Vector2i(3, 3)   # solo qui (e solo il rosso) si può piazzare
	# due rossi al centro (riga 3) con un BUCO in mezzo: (2,3) _ (4,3) → piazza a (3,3)
	_tut_place("red", 2, 3)
	_tut_place("red", 4, 3)
	# tray: il ROSSO da usare + due distrattori
	_tut_set_tray(["red", "yellow", "orange"])
	_tut_show_hint(_tut_target_cell)
	_tutorial_show_text("Trascina il cubo ROSSO in mezzo agli altri due")

# --- Fase 1: SCAMBIA due blocchi per fare match ---
func _tut_setup_swap() -> void:
	_tut_clear_board()
	_tut_phase_done = false
	_tut_need_color = ""
	_tut_set_tray([])   # niente tray attivo: qui si scambia sulla board
	# ...ma lascio i 3 blocchi in basso in BIANCO/NERO e non toccabili, così si capisce
	# che durante il gioco vero i 3 blocchi restano lì.
	_tut_decor_tray(["purple", "yellow", "orange"])
	# riga 3: verde giallo verde   ·   riga 4: giallo verde giallo
	# scambiando i due centrali (3,3)↔(3,4) si formano DUE linee → match
	_tut_place("green", 2, 3)
	_tut_place("yellow", 3, 3)
	_tut_place("green", 4, 3)
	_tut_place("yellow", 2, 4)
	_tut_place("green", 3, 4)
	_tut_place("yellow", 4, 4)
	_tutorial_show_text("Ora SCORRI col dito: scambia i 2 cubi al centro")

# Riquadro PULSANTE che indica dove piazzare il cubo (fasi con drop dal tray).
func _tut_show_hint(cell: Vector2i) -> void:
	_tut_clear_hint_marker()
	if not is_in_grid(cell):
		return
	var h: float = offset * 0.46
	var poly := Polygon2D.new()
	poly.polygon = PackedVector2Array([Vector2(-h, -h), Vector2(h, -h), Vector2(h, h), Vector2(-h, h)])
	poly.color = Color(1, 1, 1, 0.55)
	poly.position = grid_to_pixel(cell.x, cell.y)
	poly.z_index = 60
	add_child(poly)
	_tut_hint_node = poly
	var tw := create_tween().set_loops()
	tw.tween_property(poly, "scale", Vector2(1.12, 1.12), 0.5).set_trans(Tween.TRANS_SINE)
	tw.parallel().tween_property(poly, "modulate:a", 0.25, 0.5)
	tw.tween_property(poly, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_SINE)
	tw.parallel().tween_property(poly, "modulate:a", 1.0, 0.5)

func _tut_clear_hint_marker() -> void:
	if is_instance_valid(_tut_hint_node):
		_tut_hint_node.queue_free()
	_tut_hint_node = null

# piazza sulla board un pezzo da una SCENA (freccia/bomba), attivo e toccabile.
func _tut_place_scene(path: String, i: int, j: int) -> void:
	if not is_in_grid(Vector2i(i, j)):
		return
	var scene = load(path)
	if scene == null:
		return
	var p = scene.instantiate()
	add_child(p)
	_apply_bomb_bw(p)   # bombe: grafica nera (primo frame statico)
	p.position = grid_to_pixel(i, j)
	p.scale = Vector2(_grid_piece_scale, _grid_piece_scale)
	all_pieces[i][j] = p
	cell_active[i][j] = true

# riempie una COLONNA/RIGA con cubi non-abbinabili (per far vedere il beam che li distrugge tutti)
func _tut_fill_col(x: int, skip_y: int) -> void:
	var seq := ["green", "yellow", "orange", "purple", "pink"]
	for y in height:
		if y == skip_y:
			continue
		_tut_place(seq[y % seq.size()], x, y)

func _tut_fill_row(y: int, skip_x: int) -> void:
	var seq := ["green", "yellow", "orange", "purple", "pink"]
	for x in width:
		if x == skip_x:
			continue
		_tut_place(seq[x % seq.size()], x, y)

# --- Fase 2: FRECCIA VERTICALE — l'utente completa la linea blu; la freccia distrugge tutta la COLONNA (piena) ---
func _tut_setup_arrow_v() -> void:
	_tut_clear_board()
	_tut_phase_done = false
	_tut_need_color = "red"
	_tut_target_cell = Vector2i(4, 3)
	_tut_fill_col(3, 3)                                                      # colonna 3 PIENA (si vedrà sparire tutta)
	_tut_place_scene("res://CORE/Scene/PieceScene/red_plus_1.tscn", 3, 3)    # freccia verticale (rossa)
	_tut_place("red", 2, 3)
	_tut_set_tray(["red", "purple", "orange"])
	_tut_show_hint(_tut_target_cell)
	_tutorial_show_text("Metti il cubo ROSSO qui: la FRECCIA\ndistrugge TUTTA la colonna!")

# --- Fase 3: FRECCIA ORIZZONTALE — l'utente completa la linea rossa; la freccia distrugge tutta la RIGA (piena) ---
func _tut_setup_arrow_h() -> void:
	_tut_clear_board()
	_tut_phase_done = false
	_tut_need_color = "red"
	_tut_target_cell = Vector2i(3, 4)
	_tut_fill_row(3, 3)                                                      # riga 3 PIENA (si vedrà sparire tutta)
	_tut_place_scene("res://CORE/Scene/PieceScene/red_plus_2.tscn", 3, 3)    # freccia orizzontale (rossa)
	_tut_place("red", 3, 2)
	_tut_set_tray(["red", "yellow", "green"])
	_tut_show_hint(_tut_target_cell)
	_tutorial_show_text("Metti il cubo ROSSO qui: la FRECCIA\ndistrugge TUTTA la riga!")

# Fase-bomba generica: BOARD PIENA (così si VEDE bene cosa esplode) + bomba al centro; lo swap
# con un cubo vicino la fa detonare (in classic `_bomb_swap` detona qualsiasi bomba con lo swap).
func _tut_bomb_phase(path: String, text: String) -> void:
	_tut_clear_board()
	_tut_phase_done = false
	_tut_need_color = ""
	_tut_set_tray([])
	_tut_fill_fake_board()            # riempie tutta la griglia: il pattern d'esplosione è chiaro
	var c := Vector2i(3, 3)
	if all_pieces[c.x][c.y] != null and is_instance_valid(all_pieces[c.x][c.y]):
		all_pieces[c.x][c.y].queue_free()
	_tut_place_scene(path, c.x, c.y)  # bomba al centro (sostituisce il cubo finto)
	_tutorial_show_text(text)

# --- Fase 4: BOMBA 3×3 — board piena, si vede che esplode SOLO nel quadrato 3×3 ---
func _tut_setup_bomb() -> void:
	_tut_bomb_phase("res://CORE/Scene/PieceScene/green_plus_3.tscn",
		"Scambia la BOMBA con un cubo vicino:\nesplode SOLO nel 3×3 attorno!")

# --- Fase 5: BOMBA X — colpisce le due DIAGONALI ---
func _tut_setup_bombx() -> void:
	_tut_bomb_phase("res://CORE/Scene/PieceScene/purple_xbomb.tscn",
		"BOMBA X: scambiala,\ncolpisce le due DIAGONALI!")

# --- Fase 6: BOMBA ANGOLI — colpisce i 4 angoli della griglia ---
func _tut_setup_bombangles() -> void:
	_tut_bomb_phase("res://CORE/Scene/PieceScene/orange_angles.tscn",
		"BOMBA ANGOLI: scambiala,\ncolpisce i 4 ANGOLI!")

# --- Fine: parte la VERA partita ---
func _tut_show_done() -> void:
	_tut_need_color = ""
	_tut_clear_board()
	_tutorial_show_text("Sei pronto!  Buona partita!")
	get_tree().create_timer(1.3).timeout.connect(_tut_finish)

# DEMO abilità: passo "show" (mostra il cubo) o "explode" (mappa piena → l'abilità esplode).
func _tut_demo_step(idx: int) -> void:
	if not _tut_active:
		return
	if idx >= TUT_DEMO.size():
		_tut_show_goodbye()
		return
	var d: Dictionary = TUT_DEMO[idx]
	_tut_clear_board()
	_tut_need_color = ""
	if str(d["type"]) == "show":
		var paths: Array = d["paths"]
		var cells := [Vector2i(3, 3)] if paths.size() == 1 else [Vector2i(2, 3), Vector2i(4, 3)]
		for k in paths.size():
			var scene = load(paths[k])
			if scene:
				var p = scene.instantiate()
				add_child(p)
				_apply_bomb_bw(p)      # bombe: nuova grafica nera (primo frame statico)
				p.position = grid_to_pixel(cells[k].x, cells[k].y)
				p.scale = Vector2(_grid_piece_scale, _grid_piece_scale)
				_tut_decor.append(p)   # decorativo: non in all_pieces → non toccabile
		_tutorial_show_text(str(d["text"]))
		get_tree().create_timer(2.6).timeout.connect(_tut_demo_step.bind(idx + 1))
	else:
		# ESPLODE: riempi una mappa finta, metti lo speciale al centro, poi fallo esplodere
		_tut_fill_fake_board()
		var center := Vector2i(3, 3)
		var scene = load(str(d["path"]))
		if scene:
			# libera il cubo finto già presente al centro, altrimenti resta orfano/visibile
			if all_pieces[center.x][center.y] != null and is_instance_valid(all_pieces[center.x][center.y]):
				all_pieces[center.x][center.y].queue_free()
			var sp = scene.instantiate()
			add_child(sp)
			_apply_bomb_bw(sp)     # bombe: nuova grafica nera (primo frame statico)
			sp.position = grid_to_pixel(center.x, center.y)
			sp.scale = Vector2(_grid_piece_scale, _grid_piece_scale)
			all_pieces[center.x][center.y] = sp
			cell_active[center.x][center.y] = true
		_tutorial_show_text(str(d["text"]))
		get_tree().create_timer(0.9).timeout.connect(_tut_do_explode.bind(center, int(d["val"])))
		get_tree().create_timer(3.4).timeout.connect(_tut_demo_step.bind(idx + 1))

# Fa scattare l'abilità nel tutorial (riusa il vero motore dei power-up + beam per le frecce).
func _tut_do_explode(center: Vector2i, val: int) -> void:
	if not _tut_active:
		return
	if val == 1:
		_spawn_special_beam(center, false, "blue")    # colonna
	elif val == 2:
		_spawn_special_beam(center, true, "red")       # riga
	# la BOMBA stessa esplode con la SUA animazione (come i blocchi): la stacco dalla board
	# così _trigger_powerup non la copre con l'esplosione bianca.
	var bomb = all_pieces[center.x][center.y]
	if bomb != null and is_instance_valid(bomb) and _get_piece_mooves(bomb) >= 3:
		all_pieces[center.x][center.y] = null
		_destroy_piece_single(bomb)
	_trigger_powerup(center, val, [])

# Riempie tutta la griglia con cubi colorati finti (solo per la demo abilità).
func _tut_fill_fake_board() -> void:
	var cols := ["blue", "red", "yellow", "green", "purple", "orange", "pink"]
	for i in width:
		for j in height:
			var col: String = cols[(i * 3 + j * 5) % cols.size()]
			if not _color_to_scene.has(col):
				continue
			var p = _color_to_scene[col].instantiate()
			add_child(p)
			p.position = grid_to_pixel(i, j)
			p.scale = Vector2(_grid_piece_scale, _grid_piece_scale)
			all_pieces[i][j] = p
			cell_active[i][j] = true

func _tut_show_goodbye() -> void:
	if not _tut_active:
		return
	_tutorial_show_text("Sei pronto!  Buona partita!")
	get_tree().create_timer(2.2).timeout.connect(_tut_finish)

func _tut_finish() -> void:
	if not _tut_active:
		return
	_tut_clear_board()
	_tut_active = false   # da qui: meccaniche di gioco normali
	# la partita VERA inizia adesso: azzera il cronometro (stats + ritmo consigli idle)
	_game_start_ms = Time.get_ticks_msec()
	_last_action_ms = _game_start_ms
	score = 0             # il tutorial non conta nel punteggio
	_update_point_label()
	# avvia la VERA partita random
	_spawn_mode_c_start()
	_spawn_bottom_pieces()
	_animate_board_intro()   # riempimento dall'alto verso il basso
	is_resolving = false
	can_move = true
	_tutorial_end()       # chiude la banda + salva "visto"

# Avanza di fase quando la fase è completata (mossa dell'utente avvenuta e board ferma).
# Tutte le mosse (piazza, scambia, frecce, bomba) le FA l'utente → si impara facendo.
func _tut_scripted_tick() -> void:
	if not _tut_active or is_resolving or _tut_advancing or not _tut_phase_done:
		return
	# PAUSA: lascia vedere l'effetto (esplosione bomba / beam della freccia) prima di proseguire
	_tut_advancing = true
	_tut_clear_hint_marker()
	_tutorial_show_text("Bravo!")
	get_tree().create_timer(TUT_PHASE_PAUSE).timeout.connect(_tut_advance)

func _tut_advance() -> void:
	if not _tut_active:
		return
	_tut_advancing = false
	_tut_phase_done = false
	_tut_phase += 1
	match _tut_phase:
		1: _tut_setup_swap()          # scambia (fa una COMBO)
		2: _tut_setup_arrow_v()       # freccia verticale (l'utente la attiva)
		3: _tut_setup_arrow_h()       # freccia orizzontale
		4: _tut_setup_bomb()          # bomba 3×3 (swap)
		5: _tut_setup_bombx()         # bomba X (diagonali)
		6: _tut_setup_bombangles()    # bomba angoli
		_: _tut_show_done()           # fine → buona partita

# Durante il tutorial: un drop dal tray è valido SOLO se rispetta la fase.
# Fase 0 (piazza): solo il colore richiesto (rosso) e SOLO nel buco previsto.
# Altre fasi: nessun drop dal tray.
func _tut_drop_allowed(piece, target: Vector2i) -> bool:
	if not _tut_active:
		return true
	if _tut_need_color == "":
		return false
	return str(piece.get("color")) == _tut_need_color and target == _tut_target_cell

# --- helper board/tray del tutorial ---
func _tut_place(color: String, i: int, j: int) -> void:
	if not is_in_grid(Vector2i(i, j)) or not _color_to_scene.has(color):
		return
	var p = _color_to_scene[color].instantiate()
	add_child(p)
	p.position = grid_to_pixel(i, j)
	p.scale = Vector2(_grid_piece_scale, _grid_piece_scale)
	all_pieces[i][j] = p
	cell_active[i][j] = true

func _tut_set_tray(colors: Array) -> void:
	for s in range(3):
		if bottom_pieces[s] != null and is_instance_valid(bottom_pieces[s]):
			bottom_pieces[s].queue_free()
		bottom_pieces[s] = null
	for s in range(mini(3, colors.size())):
		if not _color_to_scene.has(colors[s]):
			continue
		var p = _color_to_scene[colors[s]].instantiate()
		add_child(p)
		p.position = _bottom_slot_pixel(s)
		p.scale = Vector2(_bottom_scale, _bottom_scale)
		p.set_meta("origin", "bottom")
		p.set_meta("slot_idx", s)
		_apply_select_look(p)
		bottom_pieces[s] = p

func _tut_clear_board() -> void:
	_tut_clear_hint_marker()
	for p in _tut_decor:
		if is_instance_valid(p):
			p.queue_free()
	_tut_decor.clear()
	for i in width:
		for j in height:
			if all_pieces[i][j] != null and is_instance_valid(all_pieces[i][j]):
				all_pieces[i][j].queue_free()
			all_pieces[i][j] = null
			cell_active[i][j] = false

# Cubi DECORATIVI in basso (tray) in bianco/nero, NON in bottom_pieces → non toccabili.
func _tut_decor_tray(colors: Array) -> void:
	var mat := _tut_gray_material()
	for s in range(mini(3, colors.size())):
		if not _color_to_scene.has(colors[s]):
			continue
		var p = _color_to_scene[colors[s]].instantiate()
		add_child(p)
		p.position = _bottom_slot_pixel(s)
		p.scale = Vector2(_bottom_scale, _bottom_scale)
		p.modulate = Color(1, 1, 1, 0.85)   # un filo trasparente = "non attivo"
		var spr = p.get_node_or_null("Sprite2D")
		if spr:
			spr.material = mat   # shader: desatura a bianco/nero
		_tut_decor.append(p)

# ShaderMaterial grayscale (creato una volta) per i cubi decorativi del tutorial.
func _tut_gray_material() -> ShaderMaterial:
	if _tut_gray_mat != null:
		return _tut_gray_mat
	var sh := Shader.new()
	sh.code = "shader_type canvas_item;\nvoid fragment() {\n\tvec4 c = texture(TEXTURE, UV);\n\tfloat g = dot(c.rgb, vec3(0.299, 0.587, 0.114));\n\tCOLOR = vec4(vec3(g), c.a);\n}\n"
	_tut_gray_mat = ShaderMaterial.new()
	_tut_gray_mat.shader = sh
	return _tut_gray_mat

func _build_tutorial_ui() -> void:
	# CanvasLayer PROPRIO (layer alto): garantisce che il banner sia sempre sopra il
	# gameplay e in SCREEN-SPACE (posizione indipendente dalla camera del gioco).
	var lay := CanvasLayer.new()
	lay.layer = 100   # sopra il gameplay/UI, sotto la transizione a schermo (128)
	add_child(lay)
	_tut_layer = lay
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lay.add_child(root)

	# BANDA nera translucida a TUTTA LARGHEZZA (stile striscia NO SPACE / NO MOVES):
	# opacità bassa, riempie orizzontalmente lo schermo, testo bianco centrato.
	_tut_panel = ColorRect.new()
	_tut_panel.color = Color(0, 0, 0, 0.5)
	_tut_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tut_panel.anchor_left = 0.0
	_tut_panel.anchor_right = 1.0
	_tut_panel.anchor_top = 0.30
	_tut_panel.anchor_bottom = 0.30
	_tut_panel.offset_left = 0.0
	_tut_panel.offset_right = 0.0
	_tut_panel.offset_top = 0.0
	_tut_panel.offset_bottom = 108.0
	root.add_child(_tut_panel)

	_tut_label = Label.new()
	_tut_label.add_theme_font_override("font", POP_FONT)
	_tut_label.add_theme_font_size_override("font_size", 30)
	_tut_label.add_theme_color_override("font_color", Color(1, 1, 1))
	_tut_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_tut_label.add_theme_constant_override("outline_size", 6)
	_tut_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tut_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_tut_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tut_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_tut_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tut_panel.add_child(_tut_label)

func _tutorial_show_text(txt: String) -> void:
	if _tut_label == null:
		return
	_tut_label.text = loc.t(txt)
	_tut_panel.modulate.a = 1.0   # la banda appare subito (come la striscia NO SPACE)

func _tutorial_end() -> void:
	# segna "visto" per questa versione (bumpare TUT_VERSION per rifarlo comparire)
	var cfg := ConfigFile.new()
	cfg.load(TUT_CFG)
	cfg.set_value("tut", "ver", TUT_VERSION)
	cfg.save(TUT_CFG)
	# chiude la banda e libera il CanvasLayer del tutorial
	if _tut_panel != null and is_instance_valid(_tut_panel):
		var p := _tut_panel
		var tw := create_tween()
		tw.tween_property(p, "modulate:a", 0.0, 0.3)
		tw.tween_callback(p.queue_free)
	var lay = _tut_layer
	if lay != null and is_instance_valid(lay):
		get_tree().create_timer(0.5).timeout.connect(func() -> void:
			if is_instance_valid(lay):
				lay.queue_free())
	_tut_panel = null
	_tut_label = null
	_tut_layer = null
