extends Node
# Sistema MISSIONI + valuta (monete). 6 missioni che si rigenerano ogni 24h.
# Tipi: score (punti in una partita), break_color (rompi N cubi di un colore),
# break_total (rompi N cubi), combo (fai una COMBO N), play (gioca N partite).
# I progressi arrivano da grid.gd via report_*(). Le ricompense (monete) si riscuotono a mano.

const SAVE_PATH := "user://missions.dat"
const REFRESH_SECONDS := 86400   # 24h
const DATA_VERSION := 2           # bump per FORZARE un reset delle missioni una volta
var _data_version: int = 0
const NUM_MISSIONS := 6
const COLORS := ["blue", "red", "yellow", "green", "purple", "orange", "pink"]
const COLOR_IT := {
	"blue": "BLU", "red": "ROSSI", "yellow": "GIALLI", "green": "VERDI",
	"purple": "VIOLA", "orange": "ARANCIONI", "pink": "ROSA",
}

var coins: int = 0
var missions: Array = []      # 6 dict: {type, param, target, progress, reward, claimed}
var last_refresh: int = 0     # unix time dell'ultima rigenerazione


func _ready() -> void:
	_load()
	if _data_version < DATA_VERSION:
		# reset forzato delle missioni (le monete restano)
		_generate()
		last_refresh = _now()
		_data_version = DATA_VERSION
		_save()
	_maybe_refresh()


func _now() -> int:
	return int(Time.get_unix_time_from_system())


func seconds_until_refresh() -> int:
	return maxi(0, REFRESH_SECONDS - (_now() - last_refresh))


func _maybe_refresh() -> void:
	if missions.is_empty() or (_now() - last_refresh) >= REFRESH_SECONDS:
		_generate()
		last_refresh = _now()
		_save()


func _generate() -> void:
	var pool: Array = []
	pool.append(_mk_score())
	var cols: Array = COLORS.duplicate()
	cols.shuffle()
	pool.append(_mk_break_color(cols[0]))
	pool.append(_mk_break_color(cols[1]))
	pool.append(_mk_combo())
	pool.append(_mk_break_total())
	pool.append(_mk_play())
	while pool.size() < NUM_MISSIONS:
		pool.append(_mk_break_color(COLORS[randi() % COLORS.size()]))
	pool.shuffle()
	missions = pool.slice(0, NUM_MISSIONS)


func _mk_score() -> Dictionary:
	var t: int = [800, 1500, 3000, 5000].pick_random()
	return {"type": "score", "param": "", "target": t, "progress": 0, "reward": int(t / 20.0), "claimed": false}

func _mk_break_color(c: String) -> Dictionary:
	var t: int = [20, 40, 60].pick_random()
	return {"type": "break_color", "param": c, "target": t, "progress": 0, "reward": t, "claimed": false}

func _mk_break_total() -> Dictionary:
	var t: int = [80, 150, 250].pick_random()
	return {"type": "break_total", "param": "", "target": t, "progress": 0, "reward": int(t / 2.0), "claimed": false}

func _mk_combo() -> Dictionary:
	var t: int = [3, 4, 5].pick_random()
	return {"type": "combo", "param": "", "target": t, "progress": 0, "reward": t * 30, "claimed": false}

func _mk_play() -> Dictionary:
	var t: int = [3, 5].pick_random()
	return {"type": "play", "param": "", "target": t, "progress": 0, "reward": t * 20, "claimed": false}


# --- Report progressi (chiamati da grid.gd) ------------------------------------
func report_break(color: String, n: int = 1) -> void:
	var changed := false
	for m in missions:
		if m["claimed"]:
			continue
		if m["type"] == "break_total":
			m["progress"] = mini(m["target"], m["progress"] + n)
			changed = true
		elif m["type"] == "break_color" and m["param"] == color:
			m["progress"] = mini(m["target"], m["progress"] + n)
			changed = true
	if changed:
		_save()

func report_score(s: int) -> void:
	var changed := false
	for m in missions:
		if m["claimed"]:
			continue
		if m["type"] == "score" and s > m["progress"]:
			m["progress"] = mini(m["target"], s)
			changed = true
	if changed:
		_save()

func report_combo(level: int) -> void:
	var changed := false
	for m in missions:
		if m["claimed"]:
			continue
		if m["type"] == "combo" and level > m["progress"]:
			m["progress"] = mini(m["target"], level)
			changed = true
	if changed:
		_save()

func report_play() -> void:
	var changed := false
	for m in missions:
		if m["claimed"]:
			continue
		if m["type"] == "play":
			m["progress"] = mini(m["target"], m["progress"] + 1)
			changed = true
	if changed:
		_save()


# --- Stato / riscossione -------------------------------------------------------
func is_complete(m: Dictionary) -> bool:
	return int(m["progress"]) >= int(m["target"])

func claim(index: int) -> int:
	if index < 0 or index >= missions.size():
		return 0
	var m: Dictionary = missions[index]
	if m["claimed"] or not is_complete(m):
		return 0
	m["claimed"] = true
	coins += int(m["reward"])
	_save()
	return int(m["reward"])

func describe(m: Dictionary) -> String:
	match m["type"]:
		"score":
			return "Raggiungi %d punti in una partita" % m["target"]
		"break_color":
			return "Rompi %d cubi %s" % [m["target"], COLOR_IT.get(m["param"], m["param"])]
		"break_total":
			return "Rompi %d cubi in totale" % m["target"]
		"combo":
			return "Fai una COMBO %d" % m["target"]
		"play":
			return "Gioca %d partite" % m["target"]
	return "?"


# --- Persistenza ---------------------------------------------------------------
func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("m", "coins", coins)
	cfg.set_value("m", "last_refresh", last_refresh)
	cfg.set_value("m", "missions", missions)
	cfg.set_value("m", "version", DATA_VERSION)
	cfg.save(SAVE_PATH)

func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		coins = int(cfg.get_value("m", "coins", 0))
		last_refresh = int(cfg.get_value("m", "last_refresh", 0))
		missions = cfg.get_value("m", "missions", [])
		_data_version = int(cfg.get_value("m", "version", 0))
