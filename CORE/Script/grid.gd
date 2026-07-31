extends Node2D

# ----- Export Variables -----
@export var width: int = 10
@export var height: int = 10
@export var x_start: float = 0.0
@export var y_start: float = 0.0
@export var offset: float = 64.0

# Posizionamento BottomGrid (3 slot)
@export var bottom_y_offset_pixels: int = 124 # quanto sotto alla griglia principale
@export var bottom_spacing_px: int = 140      # distanza orizzontale tra i 3 slot

# Scala dei 3 cubi trascinabili: in basso sono più grandi, quando li
# prendi per trascinarli si rimpiccioliscono alla dimensione della griglia.
const BOTTOM_PIECE_SCALE := 1.35
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
var _fall_speed_mult: float = 1.0   # caduta leggermente più lenta nella CLASSIC (non speedrun)
var _is_speedrun: bool = false               # gameplay mode_c + timer 5 min + input libero durante le cascate
var _speedrun_time_left: float = 300.0       # 5 minuti
var _timer_label: Label = null
var _speedrun_best: int = 0                   # record dedicato alla modalità speedrun
var _prev_speedrun_best: int = 0             # record speedrun PRIMA di questa partita
var _speedrun_started: bool = false          # il timer parte solo dopo il countdown 3-2-1-GO
const MODE_C_COLOR_ORDER := ["blue", "red", "yellow", "green", "purple", "orange", "pink"]
const MODE_C_START_COLORS := 5           # colori a inizio partita (facili le combo)
const MODE_C_COLORS_PER_STEP := 2        # +1 colore ogni N livelli (colori più in fretta = match più duri prima)
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

# Cubi-mossa raggruppati per valore (+1/+2/+3). Costruito da possible_plus_pieces
# in _ready (ordine per colore: +1,+2,+3). Serve a scegliere il VALORE in base
# alle mosse: così i cubi-mossa sono SEMPRE presenti, ma quando ne hai tante escono
# per lo più +1 (poco income), quando sei a corto escono più +2/+3 (aiuto vero).
var _plus_pool := {1: [], 2: [], 3: []}

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
	_is_mode_c = _mode == "mode_c" or _is_speedrun   # speedrun = gameplay CLASSIC/mode_c
	_fall_speed_mult = 1.25 if (_mode == "mode_c" and not _is_speedrun) else (1.15 if _is_speedrun else 1.0)
	_moves_enabled = _mode != "mode_b" and not _is_mode_c
	_swap_costs_move = _mode == "mode_a"
	# SPEEDRUN: griglia e sfondo dedicati
	if _is_speedrun:
		var gnode := get_node_or_null("Grid") as TextureRect
		if gnode:
			gnode.texture = load("res://CORE/Assets/Art/Game/griglia_speedrun.svg")
		var sfnode := get_node_or_null("../Sfondo") as TextureRect
		if sfnode:
			sfnode.texture = load("res://CORE/Assets/Art/Game/sfondo_speedrun.svg")
	# icona uscita: speedrun = freccia ROSSA, classic = X, altre = freccia
	var back_btn := get_node_or_null("../UI/BackButton") as TextureButton
	if back_btn:
		if _is_speedrun:
			back_btn.texture_normal = load("res://CORE/Assets/Art/UI/Game/exit_arrow_red.png")
		elif _mode == "mode_c":
			back_btn.texture_normal = load("res://CORE/Assets/Art/UI/Game/exit_x.png")
		else:
			back_btn.texture_normal = load("res://CORE/Assets/Art/UI/Game/exit_arrow.png")
	# speedrun: anche impostazioni ROSSE
	if _is_speedrun:
		var set_btn := get_node_or_null("../UI/SettingsButton") as TextureButton
		if set_btn:
			set_btn.texture_normal = load("res://CORE/Assets/Art/UI/Game/settings_red.png")
	_build_plus_pools()
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
		_spawn_mode_c_start()      # griglia iniziale casuale/varia (non scacchiera)
	else:
		_spawn_checkerboard()
	_spawn_bottom_pieces()
	update_moves_label()
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

	# speedrun: prima di far partire il timer, countdown 3-2-1-GO! (input bloccato)
	if _is_speedrun:
		_speedrun_countdown()

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

# Sceglie il blocco per uno slot del tray in basso. Mode C: raramente uno speciale
# (V/O/BOMBA) così piazzarlo e matcharlo dà un vantaggio (colonna/riga/3x3).
func _pick_bottom_piece() -> PackedScene:
	if _is_mode_c and randf() < BOTTOM_SPECIAL_PROB:
		return _pick_plus_scene()
	return _pick_normal_piece()

func _spawn_bottom_pieces() -> void:
	for s in range(3):
		if bottom_pieces[s] == null:
			var piece = _pick_bottom_piece().instantiate()
			add_child(piece)
			piece.position = _bottom_slot_pixel(s)
			piece.scale = Vector2(BOTTOM_PIECE_SCALE, BOTTOM_PIECE_SCALE)
			# Etichetta per distinguere logica (non serve modificare lo script del pezzo)
			piece.set_meta("origin", "bottom")
			piece.set_meta("slot_idx", s)
			_apply_select_look(piece)
			bottom_pieces[s] = piece

func _replenish_bottom_slot(slot_idx: int) -> void:
	if bottom_pieces[slot_idx] == null:
		var piece = _pick_bottom_piece().instantiate()
		add_child(piece)
		piece.position = _bottom_slot_pixel(slot_idx)
		piece.scale = Vector2(BOTTOM_PIECE_SCALE, BOTTOM_PIECE_SCALE)
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

# =========================================================
# 3) Match detection
# =========================================================
func match_at(i: int, j: int, color) -> bool:
	if i > 1:
		if all_pieces[i - 1][j] != null and all_pieces[i - 2][j] != null:
			if all_pieces[i - 1][j].color == color and all_pieces[i - 2][j].color == color:
				return true
	if j > 1:
		if all_pieces[i][j - 1] != null and all_pieces[i][j - 2] != null:
			if all_pieces[i][j - 1].color == color and all_pieces[i][j - 2].color == color:
				return true
	return false

func find_matches() -> bool:
	var any_match := false
	for i in width:
		for j in height:
			if all_pieces[i][j] != null:
				var current_color = all_pieces[i][j].color
				# orizzontale
				if i > 0 and i < width - 1:
					if all_pieces[i - 1][j] != null and all_pieces[i + 1][j] != null:
						if all_pieces[i - 1][j].color == current_color and all_pieces[i + 1][j].color == current_color:
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
						if all_pieces[i][j - 1].color == current_color and all_pieces[i][j + 1].color == current_color:
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
		_combo_count += 1   # una wave di match = una combo nella catena (per la ricompensa)
		# SFX + vibrazione: distruzione cubi (più intensa, scala col numero distrutto)
		settings.play_destroy()
		settings.vibrate(45 + min(destroyed_count, 6) * 8)

		# Match da 3 cubi = 100 punti base, +30 per ogni cubo oltre i 3,
		# poi MOLTIPLICATORE combo: match normale x1, combo 1 x2, combo 2 x3, ...
		var base_gain := points_per_match + maxi(0, destroyed_count - 3) * 30
		# moltiplicatore = numero di gruppi di match nella catena (match singolo x1, combo1 x2, ...)
		var mult := maxi(1, _combo_matches)
		var gained := base_gain * mult
		score += gained
		lifetime_score += gained
		_show_points_gain_popup(gained)

		# High score live-update (solo classic: lo speedrun ha il suo _speedrun_best)
		if not _is_speedrun and score > high_score:
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
			all_pieces[c.x][c.y] = null
			# V/O: pop del match (l'esplosione bianca resta SOLO per bomba val 3 / mode_b)
			if is_beam or (_is_mode_c and val != 3):
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
		if is_beam or (_is_mode_c and val != 3):
			settings.play_destroy()    # V/O: suono del match
		else:
			settings.play_explosion()  # bomba / mode_b
		if val == 3:
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
			_tween_piece_scale(dragging_piece, BOTTOM_PIECE_SCALE)
			_apply_select_look(dragging_piece)   # tornato nel tray: grafica SELECT
		if dragging_piece is CanvasItem:
			dragging_piece.z_index = 0
		dragging_piece = null
		dragging_from_slot = -1

# =========================================================
# Input: swipe per swap nella griglia + drag&drop dei pezzi dal BottomGrid
# =========================================================
func _process(_delta: float) -> void:
	if is_game_over:
		return
	# speedrun: il timer 5 min parte solo dopo il countdown 3-2-1-GO; a 0 finisce la partita
	if _is_speedrun:
		if _speedrun_started:
			_speedrun_time_left -= _delta
			if _speedrun_time_left <= 0.0:
				_speedrun_time_left = 0.0
				_update_timer_label()
				_trigger_game_over("time")
				return
			# rete di sicurezza anti-blocco: se la board è piena, libera spazio
			if not is_resolving and _is_board_full():
				_remove_random_cells(10)
		_update_timer_label()
	# difficoltà basata sul tempo: aggiorna ~1 volta al secondo anche mentre si risolve
	if Time.get_ticks_msec() - _last_diff_update_ms > 1000:
		_last_diff_update_ms = Time.get_ticks_msec()
		_update_difficulty()
	if is_resolving:
		return
	_handle_grid_touch_swap()
	_check_idle_hint()

# Suggerimenti se il player resta fermo troppo a lungo
func _check_idle_hint() -> void:
	if dragging_piece != null:
		return
	var now := Time.get_ticks_msec()
	if now - _last_action_ms < IDLE_HINT_MS:
		return
	if now < _next_hint_ms:
		return
	_next_hint_ms = now + HINT_REPEAT_MS
	_show_hint()

# Swipe per scambiare due pezzi adiacenti nella griglia
func _handle_grid_touch_swap() -> void:
	if can_move == true:
		if Input.is_action_just_pressed("ui_touch"):
			var g = pixel_to_grid(get_global_mouse_position().x, get_global_mouse_position().y)
			if is_in_grid(g):
				first_touch = g
				controlling = true

	if Input.is_action_just_released("ui_touch"):
		var g = pixel_to_grid(get_global_mouse_position().x, get_global_mouse_position().y)
		if is_in_grid(g) and controlling:
			controlling = false
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
				_tween_piece_scale(dragging_piece, GRID_PIECE_SCALE)
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
			and (not _moves_enabled or current_moves > 0):
				# Inserimento dalla BottomGrid: se spot vuoto, rimane anche senza match
				dragging_piece.set_meta("origin", "grid")
				_restore_normal_look(dragging_piece)   # sulla griglia: grafica cubo normale
				# ferma il tween di scala del drag: altrimenti combatte con il pop di dim()
				if _drag_scale_tween != null and _drag_scale_tween.is_valid():
					_drag_scale_tween.kill()
				dragging_piece.scale = Vector2(GRID_PIECE_SCALE, GRID_PIECE_SCALE)
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
				if not _is_speedrun and score > high_score:
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
				# Ritorna allo slot originale se non valido
				dragging_piece.global_position = _bottom_slot_pixel(dragging_from_slot)
				_tween_piece_scale(dragging_piece, BOTTOM_PIECE_SCALE)
				_apply_select_look(dragging_piece)   # tornato nel tray: grafica SELECT
				# posto valido ma niente mosse -> scuoti "MOOVES" per farlo capire
				if current_moves <= 0 and is_in_grid(target_grid) and all_pieces[target_grid.x][target_grid.y] == null:
					_shake_moves_label()

			# Reset parametri di drag
			_hide_placement_preview()
			if dragging_piece is CanvasItem:
				dragging_piece.z_index = 0

			dragging_piece = null
			dragging_from_slot = -1
			get_viewport().set_input_as_handled()

func check_game_over() -> void:
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
		piece.scale = Vector2(GRID_PIECE_SCALE, GRID_PIECE_SCALE)
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
		if not _is_speedrun and score > high_score:
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
		piece.scale = Vector2(BOTTOM_PIECE_SCALE, BOTTOM_PIECE_SCALE)
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
				clicked.scale = Vector2(GRID_PIECE_SCALE, GRID_PIECE_SCALE)
				settings.play_pickup()
		elif _multi_drags.has(event.index):
			var piece: Node = _multi_drags[event.index]
			_multi_drags.erase(event.index)
			_place_dragged_piece(piece, int(piece.get_meta("slot_idx")), wp - Vector2(0, DRAG_LIFT))
	elif event is InputEventScreenDrag and _multi_drags.has(event.index):
		var piece2: Node = _multi_drags[event.index]
		piece2.global_position = (get_global_transform_with_canvas().affine_inverse() * event.position) - Vector2(0, DRAG_LIFT)


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

func _trigger_game_over(reason := "no_space") -> void:
	is_game_over = true

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

	# Nuovo record? (sul punteggio finale, bonus incluso)
	if _is_speedrun:
		_is_new_record = score > _prev_speedrun_best and score > 0
		if score > _speedrun_best:
			_speedrun_best = score
	else:
		_is_new_record = score > _prev_high_score and score > 0

	# Aggiorna HighScore (classic). In speedrun il record è _speedrun_best: non toccare high_score.
	if not _is_speedrun and score > high_score:
		high_score = score

	# Salva su disco
	_save_scores()

	# Aggiorna UI
	_update_point_label()
	_update_high_score_labels_everywhere()
	_update_gameover_current_score()

	# Statistiche partita (per calibrare la durata)
	var dur_s: int = (Time.get_ticks_msec() - _game_start_ms) / 1000
	_last_session_stats = "%d:%02d  ·  %d pose  ·  %d pt" % [dur_s / 60, dur_s % 60, _stat_placements, score]
	print("SESSION STATS → durata=%ds pose=%d punteggio=%d" % [dur_s, _stat_placements, score])

	_last_defeat_reason = reason

	# Flusso di sconfitta: strip motivo -> revive -> schermata finale
	var flow = get_node_or_null("%DefeatFlow")
	if flow and not _is_speedrun:   # speedrun: niente revive, si va diritti alla schermata finale
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
	# Speedrun: si va dritti alla schermata finale senza DefeatFlow, quindi la
	# board resta sotto. Nascondila (e il timer) così i cubi non si sovrappongono
	# al punteggio mostrato.
	if _is_speedrun:
		visible = false
		if _timer_label:
			_timer_label.visible = false
	# Interstitial a ogni sconfitta (anche speedrun): appare sopra la
	# schermata finale, alla chiusura si ritrova il game over.
	ads.show_interstitial()
	# suono finale: record battuto -> New High Score, altrimenti Game Over
	if _is_new_record:
		settings.play_highscore()
	else:
		settings.play_gameover()
	var screen = get_node_or_null("%GameOverScreen")
	if screen:
		if screen.has_method("set_session_stats"):
			screen.set_session_stats(_last_session_stats)
		if screen.has_method("set_end_bonus"):
			screen.set_end_bonus(score, _end_moves, END_MOVE_POINTS)
		# speedrun: niente layout viola "record"; titolo "SPEEDRUN" + record dedicato
		var rec: bool = _is_new_record and not _is_speedrun
		if screen.has_method("show_result"):
			screen.show_result(rec)
		else:
			screen.visible = true
		if _is_speedrun and screen.has_method("set_speedrun_mode"):
			screen.set_speedrun_mode(_speedrun_best, _is_new_record)
		if screen is CanvasItem:
			screen.z_index = 99999


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


func _update_timer_label() -> void:
	if _timer_label == null:
		return
	var s := int(ceil(_speedrun_time_left))
	_timer_label.text = "%d:%02d" % [s / 60, s % 60]
	if _speedrun_time_left <= 30.0:
		_timer_label.add_theme_color_override("font_color", Color(0.95, 0.25, 0.25))  # rosso: ultimi 30s
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
		hs.text = "HighScore: " + str(high_score)

	var gos = get_node_or_null("%GameOverScreen")
	if gos:
		var best := gos.get_node_or_null("Items/L_BestScoreNumber")
		if best and best is Label:
			best.text = str(high_score)

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
	var tw := p.create_tween()
	tw.tween_property(p, "scale", Vector2(s, s), 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_drag_scale_tween = tw

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
	if dragging_piece == null:
		_hide_placement_preview()
		return
	var g := pixel_to_grid(get_global_mouse_position().x, get_global_mouse_position().y - DRAG_LIFT)
	if is_in_grid(g) and all_pieces[g.x][g.y] == null and current_moves > 0:
		_ensure_placement_preview()
		if _preview_fade_tween != null and _preview_fade_tween.is_valid():
			_preview_fade_tween.kill()
		# fantasma del pezzo (texture NORMALE del cubo, non la grafica SELECT del tray)
		var dspr := dragging_piece.get_node_or_null("Sprite2D") as Sprite2D
		if dragging_piece.has_meta("normal_tex"):
			_placement_preview.texture = dragging_piece.get_meta("normal_tex")
		elif dspr:
			_placement_preview.texture = dspr.texture
		_placement_preview.scale = Vector2(CELL_SPRITE_SCALE, CELL_SPRITE_SCALE)
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
func _spawn_explosion(world_pos: Vector2, piece: Node) -> void:
	var asp := AnimatedSprite2D.new()
	asp.sprite_frames = _explo_frames
	asp.animation = "boom"
	asp.position = world_pos
	asp.scale = Vector2(CELL_SPRITE_SCALE, CELL_SPRITE_SCALE)
	asp.z_index = 100
	add_child(asp)
	asp.play("boom")
	# il cubo dietro sparisce al 3° frame (indice 2 → t = 2/fps). Timer one-shot: nessuna cattura ripetuta
	get_tree().create_timer(2.0 / EXPLO_FPS).timeout.connect(func() -> void:
		if is_instance_valid(piece):
			piece.queue_free()
	)
	# libera l'overlay a fine animazione
	asp.animation_finished.connect(asp.queue_free)

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
	if is_game_over or is_resolving:
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
		# combo presenti ma non regalate (più rare di prima): il player le costruisce
		var b := lerpf(0.50, 0.34, t)
		# ...ma le combo ALTE devono restare un traguardo: la 2 e la 3 sono comuni, la 4+ rara.
		# già a combo 3 (_last_combo_shown>=3): prolungare ancora (→4+) è poco probabile.
		if _last_combo_shown >= 3:
			b *= 0.4
		return b
	return lerpf(0.46, 0.16, t)

# Probabilità adattiva dei cubi +mosse: cadono di più quando il player è a corto
# di mosse (aiuto quando serve), di meno quando ne ha tante; la difficoltà li riduce.
# Raggruppa i cubi-mossa per valore (l'array è ordinato per colore: +1,+2,+3).
func _build_plus_pools() -> void:
	_plus_pool = {1: [], 2: [], 3: []}
	for i in possible_plus_pieces.size():
		var v := (i % 3) + 1
		_plus_pool[v].append(possible_plus_pieces[i])

# MODE C: costruisce le liste colore (normali + bonus) ordinate, per la progressione.
func _build_mode_c_pools() -> void:
	_mc_normal_scenes.clear()
	for c in MODE_C_COLOR_ORDER:
		if _color_to_scene.has(c):
			_mc_normal_scenes.append(_color_to_scene[c])
	_mc_plus_by_color.clear()
	for i in possible_plus_pieces.size():
		var color: String = MODE_C_PLUS_COLOR_ORDER[i / 3]
		var v := (i % 3) + 1
		if not _mc_plus_by_color.has(color):
			_mc_plus_by_color[color] = {}
		_mc_plus_by_color[color][v] = possible_plus_pieces[i]

# Numero di colori attivi in Mode C: parte da 5, +1 ogni MODE_C_COLORS_PER_STEP livelli.
func _mode_c_active_count() -> int:
	return clampi(MODE_C_START_COLORS + difficulty_level / MODE_C_COLORS_PER_STEP,
		MODE_C_START_COLORS, MODE_C_COLOR_ORDER.size())

# Sceglie un cubo NORMALE. In Mode C solo tra i colori attivi (progressione).
func _pick_normal_piece() -> PackedScene:
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
	var w1: float
	var w2: float
	if _is_mode_c:
		# Mode C: i +N sono power-up (non mosse). La bomba 3x3 è ESCLUSIVA (rarissima), così
		# la board resta piena e si può perdere; anche +1/+2 un po' più rare di prima.
		# +1 colonna 58%, +2 riga 40%, +3 bomba 3x3 2% (esclusiva).
		w1 = 0.58; w2 = 0.40
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
	var r := randf()
	var v := 3
	if r < w1:
		v = 1
	elif r < w1 + w2:
		v = 2
	# Mode C: il cubo-bonus deve avere un colore ATTIVO (così matcha con i normali).
	if _is_mode_c and not _mc_plus_by_color.is_empty():
		var n: int = mini(_mc_active_count, MODE_C_COLOR_ORDER.size())
		var color: String = MODE_C_COLOR_ORDER[randi() % n]
		if _mc_plus_by_color.has(color) and _mc_plus_by_color[color].has(v):
			return _mc_plus_by_color[color][v]
	return _plus_pool[v].pick_random()

# Con probabilità 'prob' restituisce un cubo-mossa (valore pesato dalle mosse),
# altrimenti un cubo normale. Usato da tutti i punti di spawn.
func _spawn_plus_or_normal(prob: float) -> PackedScene:
	if randf() < prob:
		return _pick_plus_scene()
	return _pick_normal_piece()

func _effective_plus_prob() -> float:
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
	if current_moves > 0:
		var move := _find_useful_move()
		if not move.is_empty():
			_bounce_bottom_piece(int(move["slot"]))
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
	if src != null and src.has_node("Sprite2D"):
		ghost.texture = src.get_node("Sprite2D").texture
	ghost.scale = Vector2(CELL_SPRITE_SCALE, CELL_SPRITE_SCALE)
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
	asp.speed_scale = 0.85
	layer.add_child(asp)
	asp.animation_finished.connect(layer.queue_free)
	asp.play("c")

func _show_combo_effect(level: int, world_pos: Vector2) -> void:
	var anim_level: int = clampi(level, 1, 11)   # dalla 12ª combo in poi usa COMBO 11
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
	asp.position = world_pos
	asp.scale = Vector2(COMBO_EFFECT_SCALE, COMBO_EFFECT_SCALE)
	asp.speed_scale = COMBO_SPEED
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
