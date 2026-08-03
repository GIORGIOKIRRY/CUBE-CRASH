extends Node

# ============================================================
# Autoload "leaderboard" — classifica online su Firebase
# (Realtime Database, API REST: niente SDK, solo HTTPRequest).
# STRUTTURA DATI: leaderboards/{mode}/{settimana}/{player_id}
#                 -> {"name": ..., "score": ..., "icon": ...}
# La settimana unix nel percorso rende automatico il reset
# settimanale (stessa logica del timer nella UI).
# Se DB_URL è vuoto o non c'è rete: fetch_top() torna [] e la UI
# ripiega sulla classifica finta di sempre.
# ============================================================

# URL del Realtime Database (console Firebase -> Realtime Database).
# Es: "https://cube-crash-default-rtdb.europe-west1.firebasedatabase.app"
const DB_URL := "https://cube-80594-default-rtdb.europe-west1.firebasedatabase.app"

const PROFILE_CFG := "user://profile.cfg"   # nome, icona, id giocatore
const MAX_NAME_LEN := 16

var _player_id: String = ""

func _ready() -> void:
	_load_or_create_player_id()

# ID anonimo stabile del giocatore (per aggiornare il proprio punteggio)
func _load_or_create_player_id() -> void:
	var cfg := ConfigFile.new()
	cfg.load(PROFILE_CFG)
	_player_id = str(cfg.get_value("profile", "lb_id", ""))
	if _player_id.is_empty():
		randomize()
		_player_id = "p%d%04d" % [int(Time.get_unix_time_from_system()), randi_range(0, 9999)]
		cfg.set_value("profile", "lb_id", _player_id)
		cfg.save(PROFILE_CFG)

func _week() -> int:
	return int(Time.get_unix_time_from_system()) / 604800

func player_id() -> String:
	return _player_id

func _profile() -> Dictionary:
	var cfg := ConfigFile.new()
	cfg.load(PROFILE_CFG)
	var nm := str(cfg.get_value("profile", "name", "")).strip_edges()
	if nm.is_empty() or nm == "PLAYER":
		# default persistente "PLAYER"+cifre (stessa chiave usata dal menu)
		nm = str(cfg.get_value("profile", "default_name", ""))
		if nm.is_empty():
			randomize()
			nm = "PLAYER%04d" % randi_range(0, 9999)
			cfg.set_value("profile", "default_name", nm)
			cfg.save(PROFILE_CFG)
	return {
		"name": nm.substr(0, MAX_NAME_LEN),
		"icon": int(cfg.get_value("profile", "icon", 0)),
	}

# ============================================================
# INVIO PUNTEGGIO (fire-and-forget, chiamato a fine partita)
# ============================================================
# Rimuove la voce del giocatore dalla classifica online per una modalità (DELETE).
func remove_best(mode: String) -> void:
	if DB_URL.is_empty() or _player_id.is_empty():
		return
	var url := "%s/leaderboards/%s/%d/%s.json" % [DB_URL, mode, _week(), _player_id]
	var req := HTTPRequest.new()
	add_child(req)
	req.request_completed.connect(func(_r, _code, _h, _b) -> void: req.queue_free())
	if req.request(url, [], HTTPClient.METHOD_DELETE) != OK:
		req.queue_free()

# Invia il punteggio SOLO se è più alto di quello già in classifica per questo
# giocatore (MONOTÒNO): così una partita con punteggio inferiore NON può mai
# abbassare/cancellare il record online. Prima legge il valore attuale, poi
# scrive solo se il nuovo è maggiore (o se non esiste ancora).
func submit_best(mode: String, score: int) -> void:
	if DB_URL.is_empty() or score <= 0 or _player_id.is_empty():
		return
	var base := "%s/leaderboards/%s/%d/%s" % [DB_URL, mode, _week(), _player_id]
	var getreq := HTTPRequest.new()
	add_child(getreq)
	getreq.request_completed.connect(func(_r: int, code: int, _h: PackedStringArray, body: PackedByteArray) -> void:
		getreq.queue_free()
		# punteggio attuale sul server (o -1 se non c'è)
		var cur := -1
		if code == 200:
			var v: Variant = JSON.parse_string(body.get_string_from_utf8())
			if typeof(v) == TYPE_FLOAT or typeof(v) == TYPE_INT:
				cur = int(v)
		var p := _profile()
		var putreq := HTTPRequest.new()
		add_child(putreq)
		putreq.request_completed.connect(func(_r2, _c2, _h2, _b2) -> void: putreq.queue_free())
		if score > cur:
			# nuovo record: aggiorna TUTTO (PUT sovrascrive la voce)
			var payload := JSON.stringify({"name": p["name"], "score": score, "icon": p["icon"]})
			if putreq.request(base + ".json", ["Content-Type: application/json"], HTTPClient.METHOD_PUT, payload) != OK:
				putreq.queue_free()
		else:
			# punteggio NON migliore: NON abbassare lo score, ma aggiorna comunque
			# nome + icona (PATCH lascia intatto "score") -> così cambiare icona/nome
			# si riflette sempre in classifica.
			var payload := JSON.stringify({"name": p["name"], "icon": p["icon"]})
			if putreq.request(base + ".json", ["Content-Type: application/json"], HTTPClient.METHOD_PATCH, payload) != OK:
				putreq.queue_free())
	# leggi solo il campo "score" del giocatore
	if getreq.request(base + "/score.json") != OK:
		getreq.queue_free()

# ============================================================
# LETTURA TOP 100 (async; [] se offline / errore / DB non configurato)
# ============================================================
func fetch_top(mode: String) -> Array:
	if DB_URL.is_empty():
		return []
	var url := '%s/leaderboards/%s/%d.json?orderBy="score"&limitToLast=100' % [DB_URL, mode, _week()]
	var req := HTTPRequest.new()
	req.timeout = 6.0
	add_child(req)
	if req.request(url) != OK:
		req.queue_free()
		return []
	var res: Array = await req.request_completed
	req.queue_free()
	var result: int = res[0]
	var code: int = res[1]
	var body: PackedByteArray = res[3]
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		return []
	var data = JSON.parse_string(body.get_string_from_utf8())
	if data == null or not (data is Dictionary):
		return []   # DB vuoto per questa settimana ("null") o risposta strana
	var entries: Array = []
	for id in data:
		var e = data[id]
		if not (e is Dictionary):
			continue
		entries.append({
			"name": str(e.get("name", "???")).substr(0, MAX_NAME_LEN),
			"score": int(e.get("score", 0)),
			"icon": int(e.get("icon", 0)),
			"is_player": str(id) == _player_id,
		})
	entries.sort_custom(func(a, b): return a["score"] > b["score"])
	return entries
