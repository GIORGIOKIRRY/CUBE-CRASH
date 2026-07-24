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

const SETTINGS_PATH := "user://settings.dat"

# Link condivisione (App Store). TODO: sostituire con l'ID reale a pubblicazione.
const APPSTORE_URL := "https://apps.apple.com/app/cubecrash"

# --- Musica: 2 player per crossfade ---
var _music_players: Array[AudioStreamPlayer] = []
var _active_music: int = 0
var _current_stream: AudioStream = null
const MUSIC_FADE := 0.8
const MUSIC_VOL_DB := 0.0
const SILENCE_DB := -60.0

# --- SFX ---
var _sfx_tap: AudioStreamPlayer
var _sfx_destroy: AudioStreamPlayer
var _sfx_newmove: AudioStreamPlayer

const SFX_TAP_PATH := "res://CORE/Assets/Music&Sound/SFX/tap.mp3"
const SFX_DESTROY_PATH := "res://CORE/Assets/Music&Sound/SFX/destroy.mp3"
const SFX_NEWMOVE_PATH := "res://CORE/Assets/Music&Sound/SFX/newmove.mp3"

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
	_sfx_tap = _make_sfx(SFX_TAP_PATH)
	_sfx_destroy = _make_sfx(SFX_DESTROY_PATH)
	_sfx_newmove = _make_sfx(SFX_NEWMOVE_PATH)

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
func play_music(stream: AudioStream) -> void:
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
		_fade(new_player, MUSIC_VOL_DB, MUSIC_FADE)
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

# ============================================================
# SFX (play once, no overlap)
# ============================================================
func play_tap() -> void:
	_play_sfx(_sfx_tap)

func play_destroy() -> void:
	_play_sfx(_sfx_destroy)

func play_newmove() -> void:
	_play_sfx(_sfx_newmove)

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
		for p in [_sfx_tap, _sfx_destroy, _sfx_newmove]:
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
