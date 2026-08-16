extends Node
# Sistema MISSIONI + valuta (monete). 6 missioni che si rigenerano ogni 24h.
# Tipi: score (punti in una partita), break_color (rompi N cubi di un colore),
# break_total (rompi N cubi), combo (fai una COMBO N), play (gioca N partite).
# I progressi arrivano da grid.gd via report_*(). Le ricompense (monete) si riscuotono a mano.

const SAVE_PATH := "user://missions.dat"
const REFRESH_SECONDS := 86400      # 24h (giornaliere)
const WEEKLY_REFRESH_SECONDS := 604800   # 7 giorni (settimanali)
const DATA_VERSION := 12          # bump per FORZARE un reset delle missioni una volta
# Economia (2026-08-08): free-earn ridotto così i cosmetici sono un traguardo, non regalati.
#  Giornaliere: 150 x6 = 900/g -> ~6.300/sett.  Settimanali: 600 x6 = 3.600/sett.
#  Totale completamento pieno ~9.900/sett (prima ~14.400). Skin 5.000 = ~mezza settimana.
const DAILY_REWARD := 150         # ogni missione giornaliera vale 150 monete
const WEEKLY_REWARD := 600        # ogni missione settimanale vale 600 monete
const MONTHLY_REFRESH_SECONDS := 2592000   # 30 giorni (mensili)
var _data_version: int = 0
const NUM_MISSIONS := 6
const COLORS := ["blue", "red", "yellow", "green", "purple", "orange", "pink"]
const COLOR_IT := {
	"blue": "BLU", "red": "ROSSI", "yellow": "GIALLI", "green": "VERDI",
	"purple": "VIOLA", "orange": "ARANCIONI", "pink": "ROSA",
}

var coins: int = 0
var missions: Array = []      # 6 dict GIORNALIERE: {type, param, target, progress, reward, claimed}
var weekly: Array = []        # 6 dict SETTIMANALI (stessa struttura, target/ricompense maggiori)
var monthly: Array = []       # 2 dict MENSILI: ricompensa = ICONA profilo sbloccabile
var last_refresh: int = 0     # unix time dell'ultima rigenerazione giornaliera
var last_weekly_refresh: int = 0   # unix time dell'ultima rigenerazione settimanale
var last_monthly_refresh: int = 0  # unix time dell'ultima rigenerazione mensile

# Streak login (per la missione "entra ogni giorno per 1 settimana")
var login_streak: int = 0     # giorni consecutivi di accesso
var last_login_day: int = 0   # ultimo giorno (unix/86400) di accesso registrato
# Icone profilo sbloccate dalle missioni mensili: id -> true
var unlocked_icons: Dictionary = {}


func _ready() -> void:
	_load()
	if _data_version < DATA_VERSION:
		# reset forzato delle missioni (le monete e le icone sbloccate restano)
		_generate()
		last_refresh = _now()
		_generate_weekly()
		last_weekly_refresh = _now()
		_generate_monthly()
		last_monthly_refresh = _now()
		_data_version = DATA_VERSION
		_save()
	_maybe_refresh()
	report_login()   # registra l'accesso di oggi (streak)


func _now() -> int:
	return int(Time.get_unix_time_from_system())


func seconds_until_refresh() -> int:
	return maxi(0, REFRESH_SECONDS - (_now() - last_refresh))


func seconds_until_weekly_refresh() -> int:
	return maxi(0, WEEKLY_REFRESH_SECONDS - (_now() - last_weekly_refresh))


func _maybe_refresh() -> void:
	var changed := false
	if missions.is_empty() or (_now() - last_refresh) >= REFRESH_SECONDS:
		_generate()
		last_refresh = _now()
		changed = true
	if weekly.is_empty() or (_now() - last_weekly_refresh) >= WEEKLY_REFRESH_SECONDS:
		_generate_weekly()
		last_weekly_refresh = _now()
		changed = true
	# MENSILI (icone): NON scadono a tempo — restano finché non vengono completate/riscosse.
	if monthly.is_empty():
		_generate_monthly()
		last_monthly_refresh = _now()
		changed = true
	if changed:
		_save()

func seconds_until_monthly_refresh() -> int:
	return maxi(0, MONTHLY_REFRESH_SECONDS - (_now() - last_monthly_refresh))

# --- MENSILI: ricompensa = ICONA profilo sbloccabile (non monete) ---------------
func _generate_monthly() -> void:
	# NB: se una missione mensile era già stata riscattata (icona sbloccata) resta tale.
	monthly = [
		# BETA TESTER: già completata per chi gioca durante la beta (basta riscuotere l'icona)
		{"type": "beta", "param": "", "target": 1, "progress": 1,
			"reward_type": "icon", "reward_icon": "beta", "claimed": false},
		{"type": "streak", "param": "", "target": 7, "progress": 0,
			"reward_type": "icon", "reward_icon": "fire", "claimed": false},
		{"type": "score_classic", "param": "", "target": 500000, "progress": 0,
			"reward_type": "icon", "reward_icon": "trophy", "claimed": false},
		{"type": "score_classic", "param": "", "target": 1000000, "progress": 0,
			"reward_type": "icon", "reward_icon": "cupgold", "claimed": false},
		{"type": "score_classic", "param": "", "target": 1500000, "progress": 0,
			"reward_type": "icon", "reward_icon": "cupgreen", "claimed": false},
	]
	# ripristina lo stato "claimed" se l'icona è già stata sbloccata
	for m in monthly:
		if unlocked_icons.get(m["reward_icon"], false):
			m["claimed"] = true
			m["progress"] = m["target"]

func is_icon_unlocked(icon_id: String) -> bool:
	return bool(unlocked_icons.get(icon_id, false))

# Sblocca direttamente un'icona (usato per l'icona Creator, concessa da remoto
# quando l'admin approva la richiesta). Ritorna true se è una NUOVA icona.
func unlock_icon(icon_id: String) -> bool:
	if bool(unlocked_icons.get(icon_id, false)):
		return false
	unlocked_icons[icon_id] = true
	_save()
	return true

# Streak login: chiamato all'avvio. Aggiorna i giorni consecutivi + la missione streak.
func report_login() -> void:
	var today: int = int(_now() / 86400)   # giorno assoluto
	if today == last_login_day:
		pass                                 # già registrato oggi
	elif today == last_login_day + 1:
		login_streak += 1                    # giorno consecutivo
	else:
		login_streak = 1                     # gap: riparte
	last_login_day = today
	for m in monthly:
		if m["type"] == "streak" and not m["claimed"]:
			m["progress"] = mini(int(m["target"]), login_streak)
	_save()

# Punteggio in CLASSIC (per la missione mensile 500.000)
func report_score_classic(s: int) -> void:
	var changed := false
	for m in monthly:
		if m["type"] == "score_classic" and not m["claimed"] and s > int(m["progress"]):
			m["progress"] = mini(int(m["target"]), s)
			changed = true
	if changed:
		_save()

func claim_monthly(index: int) -> String:
	if index < 0 or index >= monthly.size():
		return ""
	var m: Dictionary = monthly[index]
	if m["claimed"] or not is_complete(m):
		return ""
	m["claimed"] = true
	var icon_id := str(m["reward_icon"])
	unlocked_icons[icon_id] = true
	_save()
	return icon_id


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
	var t: int = [15000, 20000, 25000].pick_random()
	return {"type": "score", "param": "", "target": t, "progress": 0, "reward": DAILY_REWARD, "claimed": false}

func _mk_break_color(c: String) -> Dictionary:
	var t: int = [20, 40, 60].pick_random()
	return {"type": "break_color", "param": c, "target": t, "progress": 0, "reward": DAILY_REWARD, "claimed": false}

func _mk_break_total() -> Dictionary:
	var t: int = [80, 150, 250].pick_random()
	return {"type": "break_total", "param": "", "target": t, "progress": 0, "reward": DAILY_REWARD, "claimed": false}

func _mk_combo() -> Dictionary:
	var t: int = [3, 4, 5].pick_random()
	return {"type": "combo", "param": "", "target": t, "progress": 0, "reward": DAILY_REWARD, "claimed": false}

func _mk_play() -> Dictionary:
	var t: int = [3, 5].pick_random()
	return {"type": "play", "param": "", "target": t, "progress": 0, "reward": DAILY_REWARD, "claimed": false}


# --- SETTIMANALI: target e ricompense molto piu' grandi (durano 7 giorni) --------
func _generate_weekly() -> void:
	var pool: Array = []
	pool.append(_mk_w_score())
	var cols: Array = COLORS.duplicate()
	cols.shuffle()
	pool.append(_mk_w_break_color(cols[0]))
	pool.append(_mk_w_break_color(cols[1]))
	pool.append(_mk_w_combo())
	pool.append(_mk_w_break_total())
	pool.append(_mk_w_play())
	pool.shuffle()
	weekly = pool.slice(0, NUM_MISSIONS)

func _mk_w_score() -> Dictionary:
	var t: int = [40000, 50000, 60000].pick_random()
	return {"type": "score", "param": "", "target": t, "progress": 0, "reward": WEEKLY_REWARD, "claimed": false}

func _mk_w_break_color(c: String) -> Dictionary:
	var t: int = [300, 450, 600].pick_random()
	return {"type": "break_color", "param": c, "target": t, "progress": 0, "reward": WEEKLY_REWARD, "claimed": false}

func _mk_w_break_total() -> Dictionary:
	var t: int = [1500, 2500, 4000].pick_random()
	return {"type": "break_total", "param": "", "target": t, "progress": 0, "reward": WEEKLY_REWARD, "claimed": false}

func _mk_w_combo() -> Dictionary:
	var t: int = [8, 9, 10].pick_random()
	return {"type": "combo", "param": "", "target": t, "progress": 0, "reward": WEEKLY_REWARD, "claimed": false}

func _mk_w_play() -> Dictionary:
	var t: int = [25, 40].pick_random()
	return {"type": "play", "param": "", "target": t, "progress": 0, "reward": WEEKLY_REWARD, "claimed": false}


# --- Report progressi (chiamati da grid.gd) ------------------------------------
# I progressi valgono per ENTRAMBE le liste (giornaliere + settimanali).
func _all_lists() -> Array:
	return [missions, weekly]

func report_break(color: String, n: int = 1) -> void:
	var changed := false
	for arr in _all_lists():
		for m in arr:
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
	for arr in _all_lists():
		for m in arr:
			if m["claimed"]:
				continue
			if m["type"] == "score" and s > m["progress"]:
				m["progress"] = mini(m["target"], s)
				changed = true
	if changed:
		_save()

func report_combo(level: int) -> void:
	var changed := false
	for arr in _all_lists():
		for m in arr:
			if m["claimed"]:
				continue
			if m["type"] == "combo" and level > m["progress"]:
				m["progress"] = mini(m["target"], level)
				changed = true
	if changed:
		_save()

func report_play() -> void:
	var changed := false
	for arr in _all_lists():
		for m in arr:
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

func _claim_from(arr: Array, index: int) -> int:
	if index < 0 or index >= arr.size():
		return 0
	var m: Dictionary = arr[index]
	if m["claimed"] or not is_complete(m):
		return 0
	m["claimed"] = true
	coins += int(m["reward"])
	_save()
	return int(m["reward"])

func claim(index: int) -> int:
	return _claim_from(missions, index)

func claim_weekly(index: int) -> int:
	return _claim_from(weekly, index)

# Numero con i punti come separatori delle migliaia (es. 1500000 -> "1.500.000").
func fmt(n: int) -> String:
	var s := str(n)
	var out := ""
	var cnt := 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		cnt += 1
		if cnt % 3 == 0 and i > 0:
			out = "." + out
	return out

func describe(m: Dictionary) -> String:
	match m["type"]:
		"score":
			return loc.tf("Raggiungi %s punti in una partita", [fmt(int(m["target"]))])
		"break_color":
			var cname := loc.t(COLOR_IT.get(m["param"], m["param"]))
			return loc.tf("Rompi %s cubi %s", [fmt(int(m["target"])), cname])
		"break_total":
			return loc.tf("Rompi %s cubi in totale", [fmt(int(m["target"]))])
		"combo":
			return loc.tf("Fai una COMBO %d", [m["target"]])
		"play":
			return loc.tf("Gioca %d partite", [m["target"]])
		"streak":
			return loc.tf("Entra ogni giorno per %d giorni", [m["target"]])
		"score_classic":
			return loc.tf("Fai %s punti in CLASSIC", [fmt(int(m["target"]))])
		"beta":
			return loc.t("Hai giocato alla versione BETA di Cube Crash!")
	return "?"


# Spende monete (per lo shop). Ritorna true se ce n'erano abbastanza.
func spend_coins(n: int) -> bool:
	if n <= 0:
		return true
	if coins < n:
		return false
	coins -= n
	_save()
	return true

# --- Persistenza ---------------------------------------------------------------
func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("m", "coins", coins)
	cfg.set_value("m", "last_refresh", last_refresh)
	cfg.set_value("m", "missions", missions)
	cfg.set_value("m", "weekly", weekly)
	cfg.set_value("m", "last_weekly_refresh", last_weekly_refresh)
	cfg.set_value("m", "monthly", monthly)
	cfg.set_value("m", "last_monthly_refresh", last_monthly_refresh)
	cfg.set_value("m", "login_streak", login_streak)
	cfg.set_value("m", "last_login_day", last_login_day)
	cfg.set_value("m", "unlocked_icons", unlocked_icons)
	cfg.set_value("m", "version", DATA_VERSION)
	cfg.save(SAVE_PATH)

func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		coins = int(cfg.get_value("m", "coins", 0))
		last_refresh = int(cfg.get_value("m", "last_refresh", 0))
		missions = cfg.get_value("m", "missions", [])
		weekly = cfg.get_value("m", "weekly", [])
		last_weekly_refresh = int(cfg.get_value("m", "last_weekly_refresh", 0))
		monthly = cfg.get_value("m", "monthly", [])
		last_monthly_refresh = int(cfg.get_value("m", "last_monthly_refresh", 0))
		login_streak = int(cfg.get_value("m", "login_streak", 0))
		last_login_day = int(cfg.get_value("m", "last_login_day", 0))
		unlocked_icons = cfg.get_value("m", "unlocked_icons", {})
		_data_version = int(cfg.get_value("m", "version", 0))
