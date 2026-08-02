extends Node

# ============================================================
# Autoload "settings" — impostazioni + audio + feedback aptico.
# MUSICA: gestita qui con 2 player persistenti per il CROSSFADE
#         (dissolvenza tra menu e gameplay e all'attivazione/disattivazione).
# SFX: player persistenti (tap / destroy / newmove), gated da sound_enabled.
# VIBRAZIONE: vibrate() gated da vibration_enabled.
# ============================================================

var music_enabled: bool = true
var sound_enabled: bool = true
var vibration_enabled: bool = true

# Modalità di gioco per il test A/B/C (scelta dai 3 tasti Play del menu):
#  "classic" = sistema mosse attuale
#  "mode_a"  = ogni azione (piazzamento + swap che fa match) costa una mossa
#  "mode_b"  = niente mosse, stile Block Blast (si perde solo per spazio)
var game_mode: String = "classic"

const SETTINGS_PATH := "user://settings.dat"

# Link condivisione (App Store). TODO: sostituire con l'ID reale a pubblicazione.
const APPSTORE_URL := "https://apps.apple.com/app/cubecrash"

# --- Musica: 2 player per crossfade ---
var _music_players: Array[AudioStreamPlayer] = []
var _active_music: int = 0
var _current_stream: AudioStream = null
const MUSIC_FADE := 1.2
const MUSIC_VOL_DB := -8.0   # musica come sottofondo: gli effetti sonori restano in evidenza
const SILENCE_DB := -60.0

# --- SFX ---
var _sfx_uiclick: AudioStreamPlayer     # click generici UI
var _sfx_destroy: AudioStreamPlayer     # distruzione blocchi nei match (suono precedente)
var _sfx_extramove: AudioStreamPlayer   # mossa guadagnata
var _sfx_disappear: AudioStreamPlayer   # cubo casuale che scompare
var _sfx_pickup: AudioStreamPlayer      # prendi un cubo dalla scorta
var _sfx_place: AudioStreamPlayer       # posizioni un cubo
var _sfx_playbtn: AudioStreamPlayer     # bottone play
var _sfx_tvon: AudioStreamPlayer        # accensione schermo cabinato (intro home)
var home_intro_played: bool = false     # intro "TV on" già mostrata in questa sessione
var _sfx_toggle_on: AudioStreamPlayer
var _sfx_toggle_off: AudioStreamPlayer
var _sfx_error: AudioStreamPlayer       # motivo sconfitta (no space / no moves)
var _sfx_gameover: AudioStreamPlayer    # sconfitta senza record
var _sfx_highscore: AudioStreamPlayer   # record battuto
var _sfx_bomb: AudioStreamPlayer        # esplosione bombe (+3 / X / angoli)
var _sfx_arrow: AudioStreamPlayer       # frecce cambio modalità (home)
var _sfx_coin: AudioStreamPlayer        # animazione monete che salgono
var _sfx_mission: AudioStreamPlayer     # riscossione missione completata
var _sfx_combo: Array[AudioStreamPlayer] = []   # combo 1..5

const SFX_DIR := "res://CORE/Assets/Music&Sound/SFX/"

func _ready() -> void:
	_setup_music_players()
	_setup_sfx_players()
	load_settings()

# ============================================================
# SETUP
# ============================================================
func _setup_music_players() -> void:
	for i in 2:
		var p := AudioStreamPlayer.new()
		p.volume_db = SILENCE_DB
		p.finished.connect(_on_music_finished.bind(p))
		add_child(p)
		_music_players.append(p)

# Fallback loop: se una traccia finisce, riparte (home e gameplay).
func _on_music_finished(p: AudioStreamPlayer) -> void:
	if music_enabled and _current_stream != null and p == _music_players[_active_music]:
		p.play()

func _setup_sfx_players() -> void:
	_sfx_uiclick = _make_sfx(SFX_DIR + "ui_click.mp3")
	_sfx_destroy = _make_sfx(SFX_DIR + "cube_destruction.mp3")   # match normali
	_sfx_extramove = _make_sfx(SFX_DIR + "extra_move.mp3")
	_sfx_disappear = _make_sfx(SFX_DIR + "cube_disappear.mp3")   # cubi che esplodono casualmente
	_sfx_pickup = _make_sfx(SFX_DIR + "pickup_cube.mp3")
	_sfx_place = _make_sfx(SFX_DIR + "place_cube.mp3")
	_sfx_playbtn = _make_sfx(SFX_DIR + "play_button.mp3")
	_sfx_tvon = _make_sfx(SFX_DIR + "tv_on.mp3")
	_sfx_toggle_on = _make_sfx(SFX_DIR + "toggle_on.mp3")
	_sfx_toggle_off = _make_sfx(SFX_DIR + "toggle_off.mp3")
	_sfx_error = _make_sfx(SFX_DIR + "error.mp3")
	_sfx_gameover = _make_sfx(SFX_DIR + "game_over.mp3")
	_sfx_highscore = _make_sfx(SFX_DIR + "new_high_score.mp3")
	_sfx_bomb = _make_sfx(SFX_DIR + "bomb_explode.mp3")
	_sfx_arrow = _make_sfx(SFX_DIR + "arrow.mp3")
	_sfx_coin = _make_sfx(SFX_DIR + "coin.mp3")
	_sfx_mission = _make_sfx(SFX_DIR + "mission.mp3")
	for i in range(1, 6):
		_sfx_combo.append(_make_sfx(SFX_DIR + "combo%d.mp3" % i))

func _make_sfx(path: String) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	var stream: AudioStream = load(path)
	if stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = false
	elif stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = false
	p.stream = stream
	add_child(p)
	return p

# ============================================================
# MUSICA (crossfade)
# ============================================================
func play_music(stream: AudioStream, fade: float = MUSIC_FADE) -> void:
	if stream == null:
		return
	# già in riproduzione? niente da fare
	if _current_stream == stream and _music_players[_active_music].playing:
		return
	_ensure_loop(stream)
	_current_stream = stream

	var old_player := _music_players[_active_music]
	var new_idx := 1 - _active_music
	var new_player := _music_players[new_idx]
	_active_music = new_idx

	new_player.stream = stream
	new_player.volume_db = SILENCE_DB
	if music_enabled:
		new_player.play()
		_fade(new_player, MUSIC_VOL_DB, fade)
	_fade_out_stop(old_player, MUSIC_FADE)

func _ensure_loop(stream: AudioStream) -> void:
	if stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true
	elif stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	# WAV: il loop è gestito dall'import (loop_mode) + fallback su _on_music_finished

func _fade(player: AudioStreamPlayer, to_db: float, dur: float) -> void:
	var tw := create_tween()
	tw.tween_property(player, "volume_db", to_db, dur)

func _fade_out_stop(player: AudioStreamPlayer, dur: float) -> void:
	if not player.playing:
		return
	var tw := create_tween()
	tw.tween_property(player, "volume_db", SILENCE_DB, dur)
	tw.tween_callback(player.stop)

# Spegne con dissolvenza la musica corrente (es. quando la gestisce direttamente una scena).
func fade_out_music() -> void:
	_current_stream = null
	for p in _music_players:
		_fade_out_stop(p, MUSIC_FADE)

# ============================================================
# SFX (play once, no overlap)
# ============================================================
func play_tap() -> void:            # click generici UI
	_play_sfx(_sfx_uiclick)

func play_destroy() -> void:        # cubi distrutti in un match (suono precedente)
	_play_sfx(_sfx_destroy)

func play_newmove() -> void:        # mossa guadagnata
	_play_sfx(_sfx_extramove)

func play_explosion() -> void:      # cubo casuale che scompare
	_play_sfx(_sfx_disappear)

func play_bomb() -> void:            # esplosione bombe (+3 / X / angoli)
	_play_sfx(_sfx_bomb)

func play_arrow() -> void:           # frecce cambio modalità (home)
	_play_sfx(_sfx_arrow)

func play_coin() -> void:            # monete che salgono (contatore)
	_play_sfx(_sfx_coin)

func play_mission() -> void:         # missione completata riscossa
	_play_sfx(_sfx_mission)

func play_pickup() -> void:         # prendi un cubo dalla scorta
	_play_sfx(_sfx_pickup)

func play_place() -> void:          # posizioni un cubo
	_play_sfx(_sfx_place)

func play_playbutton() -> void:     # bottone play
	_play_sfx(_sfx_playbtn)

func play_tvon() -> void:            # accensione schermo cabinato
	_play_sfx(_sfx_tvon)

func play_toggle(on: bool) -> void: # toggle impostazioni on/off
	_play_sfx(_sfx_toggle_on if on else _sfx_toggle_off)

func play_error() -> void:          # motivo sconfitta (no space / no moves)
	_play_sfx(_sfx_error)

func play_gameover() -> void:       # sconfitta senza record
	_play_sfx(_sfx_gameover)

func play_highscore() -> void:      # nuovo record
	_play_sfx(_sfx_highscore)

func play_combo1() -> void:
	play_combo(1)

# livello combo -> suono (1..5; dal 5 in poi usa combo 5)
func play_combo(level: int) -> void:
	if _sfx_combo.is_empty():
		return
	var i: int = clampi(level, 1, _sfx_combo.size()) - 1
	_play_sfx(_sfx_combo[i])

func _play_sfx(p: AudioStreamPlayer) -> void:
	if p == null or not sound_enabled:
		return
	p.stop()
	p.play()

# ============================================================
# VIBRAZIONE
# ============================================================
func vibrate(ms: int = 20) -> void:
	if vibration_enabled:
		Input.vibrate_handheld(ms)

# Feedback combinato per i pulsanti (suono + vibrazione, ognuno gated).
func button_feedback() -> void:
	play_tap()
	vibrate(15)

# ============================================================
# SETTERS
# ============================================================
func set_music_enabled(enabled: bool) -> void:
	if music_enabled == enabled:
		return
	music_enabled = enabled
	var cur := _music_players[_active_music]
	if enabled:
		if _current_stream != null and not cur.playing:
			cur.stream = _current_stream
			cur.volume_db = SILENCE_DB
			cur.play()
		_fade(cur, MUSIC_VOL_DB, MUSIC_FADE)
	else:
		_fade_out_stop(cur, MUSIC_FADE)
	save_settings()

func set_sound_enabled(enabled: bool) -> void:
	if sound_enabled == enabled:
		return
	sound_enabled = enabled
	if not sound_enabled:
		var all_sfx := [_sfx_uiclick, _sfx_destroy, _sfx_extramove, _sfx_disappear, _sfx_pickup,
			_sfx_place, _sfx_playbtn, _sfx_toggle_on, _sfx_toggle_off,
			_sfx_error, _sfx_gameover, _sfx_highscore] + _sfx_combo
		for p in all_sfx:
			if p != null:
				p.stop()
	save_settings()

func set_vibration_enabled(enabled: bool) -> void:
	if vibration_enabled == enabled:
		return
	vibration_enabled = enabled
	save_settings()

# ============================================================
# SAVE / LOAD
# ============================================================
func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)
	cfg.set_value("audio", "music", music_enabled)
	cfg.set_value("audio", "sound", sound_enabled)
	cfg.set_value("feedback", "vibration", vibration_enabled)
	cfg.save(SETTINGS_PATH)

func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		music_enabled = bool(cfg.get_value("audio", "music", true))
		sound_enabled = bool(cfg.get_value("audio", "sound", true))
		vibration_enabled = bool(cfg.get_value("feedback", "vibration", true))
