extends Node

var music_enabled: bool = true
var sound_enabled: bool = true

var music_players: Array[AudioStreamPlayer] = []
var sfx_players: Array[AudioStreamPlayer] = []

const SETTINGS_PATH := "user://settings.dat"

func _ready() -> void:
	load_settings()
	_apply_all()

# ---- REGISTRA PLAYER ----
func register_music(player: AudioStreamPlayer2D) -> void:
	if not music_players.has(player):
		music_players.append(player)

		if music_enabled:
			player.play()
		else:
			player.stop()

func register_sfx(player: AudioStreamPlayer2D) -> void:
	if not sfx_players.has(player):
		sfx_players.append(player)
		player.bus = "SFX"

# ---- SETTERS ----
func set_music_enabled(enabled: bool) -> void:
	if music_enabled == enabled:
		return

	music_enabled = enabled
	_apply_music()
	save_settings()

func set_sound_enabled(enabled: bool) -> void:
	if sound_enabled == enabled:
		return

	sound_enabled = enabled
	_apply_sfx()
	save_settings()

# ---- APPLY ----
func _apply_music() -> void:
	for p in music_players:
		if music_enabled:
			if not p.playing:
				p.play()
		else:
			p.stop()

func _apply_sfx() -> void:
	for p in sfx_players:
		p.volume_db = 0 if sound_enabled else -80

func _apply_all() -> void:
	_apply_music()
	_apply_sfx()

# ---- SAVE / LOAD ----
func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "music", music_enabled)
	cfg.set_value("audio", "sound", sound_enabled)
	cfg.save(SETTINGS_PATH)

func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		music_enabled = cfg.get_value("audio", "music", true)
		sound_enabled = cfg.get_value("audio", "sound", true)
