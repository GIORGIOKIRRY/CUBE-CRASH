extends Node2D

# ----- Export Variables -----
@export var width: int = 10
@export var height: int = 10
@export var x_start: int = 0
@export var y_start: int = 0
@export var offset: int = 64

# Posizionamento BottomGrid (3 slot)
@export var bottom_y_offset_pixels: int = 96 # quanto sotto alla griglia principale
@export var bottom_spacing_px: int = 96      # distanza orizzontale tra i 3 slot
@export var spawn_rows_above: int = 1       # quante "righe" sopra la griglia fanno partire la caduta
@export var enable_empty_fall_fx: bool = true

# ----- Difficulty Progression -----
@export var difficulty_step_score: int = 500   # ogni quanti punti sale la difficoltà
@export var max_difficulty_level: int = 10

var difficulty_level: int = 0

@export_range(0.0, 1.0, 0.01)
var max_empty_refill_probability: float = 0.88  # limite massimo vuoti

@export var bonus_moves_penalty_per_level: int = 1

# Probabilità refill (0.0-1.0). Es: 0.2 = 20% spazio vuoto, 80% pezzi
@export_range(0.0, 1.0, 0.01) var empty_refill_probability: float = 0.63

@export_range(0.0, 1.0, 0.01)
var plus_piece_probability: float = 0.14  # 10% di probabilità di generare un plus piece

@export var max_moves: int = 30  # numero di mosse iniziali
var current_moves: int = 0
var is_game_over: bool = false
var is_resolving: bool = false  # nuovo: blocca mosse durante la risoluzione

# Revive: max 3 volte per partita
var revive_count: int = 0
const MAX_REVIVES := 3
var _last_defeat_reason: String = "no_space"

# ----- Scoring -----
@export var points_per_piece: int = 10  # punti per ogni pezzo distrutto
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
	else:
		high_score = 0
		lifetime_score = 0

func _save_scores() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("scores", "high_score", high_score)
	cfg.set_value("scores", "lifetime_score", lifetime_score)
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

# ----- Grid State -----
var all_pieces: Array = []      # 2D [width][height] -> Node or null

# ----- Touch/Swap -----
var first_touch = Vector2i(0, 0)
var final_touch = Vector2i(0, 0)
var controlling := false

# ----- BottomGrid (3 pezzi trascinabili) -----
var bottom_pieces: Array = [null, null, null]  # 3 slot
var dragging_piece: Node = null
var dragging_from_slot: int = -1
var drag_start_pos: Vector2 = Vector2.ZERO

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
	randomize()
	current_moves = max_moves
	all_pieces = make_2d_array()
	_spawn_checkerboard()
	_spawn_bottom_pieces()
	update_moves_label()
	_load_scores()
	_prev_high_score = high_score   # record da battere in questa partita
	score = 0
	_update_point_label()
	_update_high_score_labels_everywhere()

# 1) Griglia iniziale a scacchiera: (pezzo, spazio vuoto) alternati
func _spawn_checkerboard() -> void:
	for i in width:
		for j in height:
			if ((i + j) % 2) == 0:
				var piece := _random_piece_instance_avoiding_match(i, j)
				add_child(piece)
				piece.position = grid_to_pixel(i, j)
				all_pieces[i][j] = piece
			else:
				all_pieces[i][j] = null

# Evita match immediato sul posizionamento
func _random_piece_instance_avoiding_match(i: int, j: int) -> Node:
	var pool = possible_plus_pieces if randf() < plus_piece_probability else possible_pieces
	var piece = pool.pick_random().instantiate()
	var loops := 0

	while match_at(i, j, piece.color) and loops < 100:
		pool = possible_plus_pieces if randf() < plus_piece_probability else possible_pieces
		piece = pool.pick_random().instantiate()
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

func _spawn_bottom_pieces() -> void:
	for s in range(3):
		if bottom_pieces[s] == null:
			var piece = possible_pieces.pick_random().instantiate()
			add_child(piece)
			piece.position = _bottom_slot_pixel(s)
			# Etichetta per distinguere logica (non serve modificare lo script del pezzo)
			piece.set_meta("origin", "bottom")
			piece.set_meta("slot_idx", s)
			bottom_pieces[s] = piece

func _replenish_bottom_slot(slot_idx: int) -> void:
	if bottom_pieces[slot_idx] == null:
		var piece = possible_pieces.pick_random().instantiate()
		add_child(piece)
		piece.position = _bottom_slot_pixel(slot_idx)
		piece.set_meta("origin", "bottom")
		piece.set_meta("slot_idx", slot_idx)
		bottom_pieces[slot_idx] = piece

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
		is_resolving = true
		_cancel_drag()
		get_parent().get_node("DestroyTimer").start()
	return any_match

func destroy_matched() -> Array:
	var destroyed_positions: Array = []
	var bonus_moves := 0
	var destroyed_count := 0

	for i in width:
		for j in height:
			var piece = all_pieces[i][j]
			if piece != null and piece.matched:
				# Somma mooves solo se la proprietà esiste
				bonus_moves += _get_piece_mooves(piece)

				# Punteggio: conta ogni pezzo distrutto
				destroyed_count += 1

				piece.queue_free()
				all_pieces[i][j] = null
				destroyed_positions.append(Vector2i(i, j))

	# 🔹 Applica bonus mosse se presente
	if bonus_moves > 0:
		# SFX: nuova mossa guadagnata (pezzo +1/+2/+3 distrutto)
		settings.play_newmove()

		var penalty_ratio: float = clamp(0.15 + difficulty_level * 0.08, 0.0, 0.85)
		var penalized: int = int(round(bonus_moves * (1.0 - penalty_ratio)))

		current_moves += penalized
		update_moves_label()

		print("Bonus:", bonus_moves,
			" | penalty %:", penalty_ratio,
			" | final:", penalized)

	# Applica punteggio
	if destroyed_count > 0:
		# SFX + vibrazione: distruzione cubi (una volta per ondata, no overlap)
		settings.play_destroy()
		settings.vibrate(25)

		var gained := destroyed_count * points_per_piece
		score += gained
		lifetime_score += gained

		# High score live-update
		if score > high_score:
			high_score = score

		# UI + Salva
		_update_point_label()
		_update_high_score_labels_everywhere()
		_save_scores()
	_update_difficulty()
	return destroyed_positions

func _apply_local_gravity(destroyed_positions: Array) -> void:
	# collassa solo le colonne toccate dal match
	var affected_columns: Array = []
	for pos in destroyed_positions:
		if not affected_columns.has(pos.x):
			affected_columns.append(pos.x)

	for x in affected_columns:
		_collapse_column(x)

func _collapse_column(x: int) -> void:
	var write_y := 0
	for read_y in range(0, height):
		var p = all_pieces[x][read_y]
		if p != null:
			if write_y != read_y:
				all_pieces[x][write_y] = p
				all_pieces[x][read_y] = null
				var target_px := grid_to_pixel(x, write_y)
				if p.has_method("move"):
					p.move(target_px)
				else:
					var dist := float(abs(read_y - write_y))
					_tween_to(p, target_px, 0.1 + 0.05 * dist)
			write_y += 1

	for y in range(write_y, height):
		all_pieces[x][y] = null

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

	# 1) collassa SOLO le colonne coinvolte
	_apply_local_gravity(destroyed_cells)

	# 2) refill dall’alto su quelle colonne
	_refill_destroyed_cells_random(destroyed_cells)

	# 3) cascata
	if find_matches():
		return

	# 4) fine cascata → sblocca input
	is_resolving = false

	check_game_over()

func _tween_to(node: Node2D, to_pos: Vector2, dur: float = 0.15) -> void:
	var tw := create_tween()
	tw.tween_property(node, "position", to_pos, dur)\
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
					var pool = possible_plus_pieces if randf() < plus_piece_probability else possible_pieces
					var piece = pool.pick_random().instantiate()
					add_child(piece)

					var spawn_px := grid_to_pixel(x, spawn_row)
					var target_px := grid_to_pixel(x, y)
					piece.position = spawn_px

					if piece.has_method("move"):
						piece.move(target_px)
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
	if not find_matches():
		# nessun match -> annulla (revert)
		all_pieces[column][row] = first_piece
		all_pieces[nx][ny] = other_piece
		first_piece.move(grid_to_pixel(column, row))
		other_piece.move(grid_to_pixel(nx, ny))

func _cancel_drag() -> void:
	if dragging_piece != null:
		# torna allo slot
		if dragging_from_slot >= 0:
			dragging_piece.global_position = _bottom_slot_pixel(dragging_from_slot)
		if dragging_piece is CanvasItem:
			dragging_piece.z_index = 0
		dragging_piece = null
		dragging_from_slot = -1

# =========================================================
# Input: swipe per swap nella griglia + drag&drop dei pezzi dal BottomGrid
# =========================================================
func _process(_delta: float) -> void:
	if is_game_over or is_resolving:
		return
	_handle_grid_touch_swap()

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
	if can_move == true:
		if is_game_over or is_resolving:
			return
		# Inizio drag: mouse down su un pezzo della BottomGrid
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var clicked := _get_bottom_piece_under_mouse()
			if clicked != null:
				dragging_piece = clicked
				dragging_from_slot = int(clicked.get_meta("slot_idx"))
				drag_start_pos = clicked.global_position
				# porta sopra gli altri mentre trascini
				if dragging_piece is CanvasItem:
					dragging_piece.z_index = 999
		
		# Durante drag
		if dragging_piece != null and event is InputEventMouseMotion:
			dragging_piece.global_position = get_global_mouse_position()

		# Fine drag
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed and dragging_piece != null:
			var target_grid := pixel_to_grid(get_global_mouse_position().x, get_global_mouse_position().y)

			if is_in_grid(target_grid) \
			and all_pieces[target_grid.x][target_grid.y] == null \
			and current_moves > 0:
				# Inserimento dalla BottomGrid: se spot vuoto, rimane anche senza match
				dragging_piece.set_meta("origin", "grid")
				dragging_piece.global_position = grid_to_pixel(target_grid.x, target_grid.y)
				all_pieces[target_grid.x][target_grid.y] = dragging_piece

				bottom_pieces[dragging_from_slot] = null
				_replenish_bottom_slot(dragging_from_slot)

				# Decrementa una mossa
				current_moves -= 1
				if current_moves < 0:
					current_moves = 0
				update_moves_label() # 👈 aggiorna il testo del label
				print("✅ Mossa usata! Mosse rimanenti:", current_moves)
				
				check_game_over()

				# Verifica match dopo l’inserimento
				find_matches()

				# Controlla il game over
				check_game_over()
			else:
				# Ritorna allo slot originale se non valido
				dragging_piece.global_position = _bottom_slot_pixel(dragging_from_slot)

			# Reset parametri di drag
			if dragging_piece is CanvasItem:
				dragging_piece.z_index = 0

			dragging_piece = null
			dragging_from_slot = -1
			get_viewport().set_input_as_handled()

func check_game_over() -> void:
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
	var mouse_pos = get_global_mouse_position()

	for s in range(3):
		var p: Node = bottom_pieces[s]
		if p == null:
			continue

		var sprite: Sprite2D = null
		if p.has_node("Sprite2D"):
			sprite = p.get_node("Sprite2D")
		if sprite != null and sprite.texture != null:
			# calcolo il rect globale in base a texture e scala
			var tex_size: Vector2 = sprite.texture.get_size() * sprite.scale
			# posizione del centro: uso la global_position del pezzo (non dello sprite)
			# posizione del centro: uso la global_position del pezzo (non dello sprite)
			var center: Vector2 = p.global_position
			var rect := Rect2(center - tex_size * 0.5, tex_size)
			if rect.has_point(mouse_pos):
				return p
		else:
			# fallback: piccolo box quadrato attorno al centro del pezzo
			var r := Rect2(p.global_position - Vector2(24, 24), Vector2(48, 48))
			if r.has_point(mouse_pos):
				return p

	return null

func update_moves_label() -> void:
	var counter_label = $"../UI/MOOVES/Counter"
	if counter_label:
		counter_label.text = str(current_moves)

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

	# Nuovo record? (il record si batte se il punteggio supera quello di inizio partita)
	_is_new_record = score > _prev_high_score and score > 0

	# Aggiorna HighScore
	if score > high_score:
		high_score = score

	# Salva su disco
	_save_scores()

	# Aggiorna UI
	_update_point_label()
	_update_high_score_labels_everywhere()
	_update_gameover_current_score()

	_last_defeat_reason = reason

	# Flusso di sconfitta: strip motivo -> revive -> schermata finale
	var flow = get_node_or_null("%DefeatFlow")
	if flow:
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
	if reason == "no_moves":
		# non c'erano più mosse -> +10 mosse
		current_moves += 10
	else:
		# non c'era più spazio -> rimuovi 5 celle casuali
		_remove_random_cells(5)
	update_moves_label()

func _remove_random_cells(n: int) -> void:
	var occupied: Array = []
	for i in width:
		for j in height:
			if all_pieces[i][j] != null:
				occupied.append(Vector2i(i, j))
	occupied.shuffle()
	for k in mini(n, occupied.size()):
		var c: Vector2i = occupied[k]
		all_pieces[c.x][c.y].queue_free()
		all_pieces[c.x][c.y] = null

func _show_game_over_screen() -> void:
	var screen = get_node_or_null("%GameOverScreen")
	if screen:
		if screen.has_method("show_result"):
			screen.show_result(_is_new_record)
		else:
			screen.visible = true
		if screen is CanvasItem:
			screen.z_index = 99999


func _update_point_label() -> void:
	var lbl := get_node_or_null("%PointLabel")
	if lbl == null:
		lbl = get_node_or_null("../UI/PointLabel")
	if lbl and lbl is Label:
		lbl.text = str(score)

func _update_high_score_labels_everywhere() -> void:
	var hs := get_node_or_null("%HS_Num")
	if hs == null:
		hs = get_node_or_null("../UI/HighScore/HS_Num")
	if hs and hs is Label:
		hs.text = str(high_score)

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
	var new_level: int = score / difficulty_step_score
	new_level = min(new_level, max_difficulty_level)

	if new_level == difficulty_level:
		return

	difficulty_level = new_level
	print("DIFFICOLTÀ AUMENTATA → Livello", difficulty_level)

	# 1) Aumenta vuoti al refill
	var t := float(difficulty_level) / float(max_difficulty_level)
	empty_refill_probability = lerp(0.63, max_empty_refill_probability, t)
