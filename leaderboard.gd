extends Node

# ============================================================
# Autoload "leaderboard" — classifica online su Firebase
# (Realtime Database, API REST: niente SDK, solo HTTPRequest).
# STRUTTURA DATI: leaderboards/{mode}/{periodo_mensile}/{player_id}
#                 -> {"name": ..., "score": ..., "icon": ...}
# Il periodo = mese di calendario (UTC) nel percorso rende automatico il
# reset MENSILE (stessa logica del timer nella UI).
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

# Periodo classifica = MESE di calendario (UTC). Reset automatico all'inizio di ogni mese
# (es. il periodo di agosto finisce/azzera a fine 31 agosto). Dura un mese.
func _period() -> int:
	var d := Time.get_datetime_dict_from_system(true)   # UTC
	return int(d["year"]) * 12 + int(d["month"])

# Secondi al prossimo reset (inizio del mese successivo, UTC). Per il countdown in UI.
func seconds_until_reset() -> int:
	var d := Time.get_datetime_dict_from_system(true)
	var y := int(d["year"])
	var m := int(d["month"]) + 1
	if m > 12:
		m = 1
		y += 1
	var next := Time.get_unix_time_from_datetime_dict({
		"year": y, "month": m, "day": 1, "hour": 0, "minute": 0, "second": 0})
	return maxi(0, int(next) - int(Time.get_unix_time_from_system()))

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
	var url := "%s/leaderboards/%s/%d/%s.json" % [DB_URL, mode, _period(), _player_id]
	var req := HTTPRequest.new()
	add_child(req)
	req.request_completed.connect(func(_r, _code, _h, _b) -> void: req.queue_free())
	if req.request(url, [], HTTPClient.METHOD_DELETE) != OK:
		req.queue_free()

# Aggiorna SUBITO nome+icona nelle classifiche (Classic + Speedrun) senza aspettare
# la fine partita. Usato quando cambi avatar/nome nel profilo: aggiorna la voce SOLO
# se esiste già (con uno score), così non crea entry "senza punteggio".
func push_profile() -> void:
	if DB_URL.is_empty() or _player_id.is_empty():
		return
	var p := _profile()
	for mode in ["classic", "speedrun"]:
		_push_profile_mode(mode, p)

func _push_profile_mode(mode: String, p: Dictionary) -> void:
	var base := "%s/leaderboards/%s/%d/%s" % [DB_URL, mode, _period(), _player_id]
	var getreq := HTTPRequest.new()
	add_child(getreq)
	getreq.request_completed.connect(func(_r: int, code: int, _h: PackedStringArray, body: PackedByteArray) -> void:
		getreq.queue_free()
		var exists := false
		if code == 200:
			var v: Variant = JSON.parse_string(body.get_string_from_utf8())
			if typeof(v) == TYPE_FLOAT or typeof(v) == TYPE_INT:
				exists = true
		if not exists:
			return   # nessuna voce in classifica -> niente da aggiornare (comparirà giocando)
		var patchreq := HTTPRequest.new()
		add_child(patchreq)
		patchreq.request_completed.connect(func(_a, _b, _c, _d) -> void: patchreq.queue_free())
		var payload := JSON.stringify({"name": p["name"], "icon": p["icon"]})
		if patchreq.request(base + ".json", ["Content-Type: application/json"], HTTPClient.METHOD_PATCH, payload) != OK:
			patchreq.queue_free())
	if getreq.request(base + "/score.json") != OK:
		getreq.queue_free()


# Invia il punteggio SOLO se è più alto di quello già in classifica per questo
# giocatore (MONOTÒNO): così una partita con punteggio inferiore NON può mai
# abbassare/cancellare il record online. Prima legge il valore attuale, poi
# scrive solo se il nuovo è maggiore (o se non esiste ancora).
func submit_best(mode: String, score: int) -> void:
	if DB_URL.is_empty() or score <= 0 or _player_id.is_empty():
		return
	var base := "%s/leaderboards/%s/%d/%s" % [DB_URL, mode, _period(), _player_id]
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
# UNICITÀ NOME UTENTE (registro /usernames/{nome} = player_id)
# ============================================================
# Chiave Firebase sicura dal nome (no . $ # [ ] / e minuscolo).
func _name_key(name: String) -> String:
	var k := name.to_lower().strip_edges()
	for ch in [".", "$", "#", "[", "]", "/", " "]:
		k = k.replace(ch, "_")
	return k

# Controlla se il nome è libero (o già TUO); se sì lo "reclama" e chiama cb(true).
# Se è di un altro giocatore chiama cb(false). Offline / DB assente → cb(true) (best effort).
func check_and_claim_name(name: String, cb: Callable) -> void:
	var key := _name_key(name)
	if DB_URL.is_empty() or _player_id.is_empty() or key.is_empty():
		cb.call(true)
		return
	var url := "%s/usernames/%s.json" % [DB_URL, key.uri_encode()]
	var getreq := HTTPRequest.new()
	getreq.timeout = 6.0
	add_child(getreq)
	getreq.request_completed.connect(func(_r: int, code: int, _h: PackedStringArray, body: PackedByteArray) -> void:
		var owner := ""
		if code == 200:
			var v: Variant = JSON.parse_string(body.get_string_from_utf8())
			if v is String:
				owner = v
		if owner != "" and owner != _player_id:
			getreq.queue_free()
			cb.call(false)   # nome già preso da un ALTRO
			return
		# libero o già mio → reclama (PUT del mio id)
		var putreq := HTTPRequest.new()
		add_child(putreq)
		putreq.request_completed.connect(func(_a, _b, _c, _d) -> void:
			putreq.queue_free()
			getreq.queue_free()
			cb.call(true))
		if putreq.request(url, ["Content-Type: application/json"], HTTPClient.METHOD_PUT, JSON.stringify(_player_id)) != OK:
			putreq.queue_free()
			getreq.queue_free()
			cb.call(true))
	if getreq.request(url) != OK:
		getreq.queue_free()
		cb.call(true)

# ============================================================
# LETTURA TOP 100 (async; [] se offline / errore / DB non configurato)
# ============================================================
func fetch_top(mode: String) -> Array:
	if DB_URL.is_empty():
		return []
	var url := '%s/leaderboards/%s/%d.json?orderBy="score"&limitToLast=100' % [DB_URL, mode, _period()]
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
