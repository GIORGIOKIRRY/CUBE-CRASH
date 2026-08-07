extends Node

# emesso quando la musica viene attivata/disattivata (es. la scena speedrun,
# che ha un suo player, la ferma/riprende di conseguenza)
signal music_toggled(enabled: bool)

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

# DEBUG: se != "", all'avvio della partita si forza subito una schermata di fine
# partita per testarne la grafica dai tasti TEST nella home:
#   "classic" = game over classic (non record) · "speedrun" = game over speedrun
#   "record"  = schermata NUOVO RECORD (con coriandoli)
# TOGLIERE prima della release (tasti TEST + questo flag).
var debug_gameover: String = ""

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
var _sfx_combo: Array[AudioStreamPlayer] = []       # combo NUOVI 1..11 (volume pieno)
var _sfx_combo_old: Array[AudioStreamPlayer] = []   # combo VECCHI 1..5 (layer più basso)

const SFX_DIR := "res://CORE/Assets/Music&Sound/SFX/"

# ---- Skin dei cubi (scelte dal Cube Deck, applicate anche in gameplay) ----
# Per ogni colore: lista di skin {static, frames(anim distruzione/match)}.
const CUBE_SKINS := {
	"red": [
		{"static": "res://CORE/Assets/Art/Game/Cubes/Red/Red.svg",
		 "frames": ["res://CORE/Assets/Art/Game/Cubes/Red/Red.svg", "res://CORE/Assets/Art/Game/Cubes/Red/Red_2.svg", "res://CORE/Assets/Art/Game/Cubes/Red/Red_3.svg", "res://CORE/Assets/Art/Game/Cubes/Red/Red_4.svg", "res://CORE/Assets/Art/Game/Cubes/Red/Red_5.svg", "res://CORE/Assets/Art/Game/Cubes/Red/Red_6.svg", "res://CORE/Assets/Art/Game/Cubes/Red/Red_7.svg"]},
		{"static": "res://CORE/Assets/Art/Home/CubeInfo/RedSkin2/red2_1.png",
		 "frames": ["res://CORE/Assets/Art/Home/CubeInfo/RedSkin2/red2_1.png", "res://CORE/Assets/Art/Home/CubeInfo/RedSkin2/red2_2.png", "res://CORE/Assets/Art/Home/CubeInfo/RedSkin2/red2_3.png", "res://CORE/Assets/Art/Home/CubeInfo/RedSkin2/red2_4.png", "res://CORE/Assets/Art/Home/CubeInfo/RedSkin2/red2_5.png", "res://CORE/Assets/Art/Home/CubeInfo/RedSkin2/red2_6.png"]},
	],
	"blue": [
		{"static": "res://CORE/Assets/Art/Game/Cubes/Blue/Blue.svg",
		 "frames": ["res://CORE/Assets/Art/Game/Cubes/Blue/Blue.svg", "res://CORE/Assets/Art/Game/Cubes/Blue/Blue_2.svg", "res://CORE/Assets/Art/Game/Cubes/Blue/Blue_3.svg", "res://CORE/Assets/Art/Game/Cubes/Blue/Blue_4.svg", "res://CORE/Assets/Art/Game/Cubes/Blue/Blue_5.svg", "res://CORE/Assets/Art/Game/Cubes/Blue/Blue_6.svg", "res://CORE/Assets/Art/Game/Cubes/Blue/Blue_7.svg"]},
		{"static": "res://CORE/Assets/Art/Home/CubeInfo/BlueSkin2/blue2_1.png",
		 "frames": ["res://CORE/Assets/Art/Home/CubeInfo/BlueSkin2/blue2_1.png", "res://CORE/Assets/Art/Home/CubeInfo/BlueSkin2/blue2_2.png", "res://CORE/Assets/Art/Home/CubeInfo/BlueSkin2/blue2_3.png", "res://CORE/Assets/Art/Home/CubeInfo/BlueSkin2/blue2_4.png", "res://CORE/Assets/Art/Home/CubeInfo/BlueSkin2/blue2_5.png", "res://CORE/Assets/Art/Home/CubeInfo/BlueSkin2/blue2_6.png"]},
	],
	"green": [
		{"static": "res://CORE/Assets/Art/Game/Cubes/Green/Green.svg",
		 "frames": ["res://CORE/Assets/Art/Game/Cubes/Green/Green.svg", "res://CORE/Assets/Art/Game/Cubes/Green/Green_2.svg", "res://CORE/Assets/Art/Game/Cubes/Green/Green_3.svg", "res://CORE/Assets/Art/Game/Cubes/Green/Green_4.svg", "res://CORE/Assets/Art/Game/Cubes/Green/Green_5.svg", "res://CORE/Assets/Art/Game/Cubes/Green/Green_6.svg", "res://CORE/Assets/Art/Game/Cubes/Green/Green_7.svg"]},
		{"static": "res://CORE/Assets/Art/Home/CubeInfo/GreenSkin2/green2_1.png",
		 "frames": ["res://CORE/Assets/Art/Home/CubeInfo/GreenSkin2/green2_1.png", "res://CORE/Assets/Art/Home/CubeInfo/GreenSkin2/green2_2.png", "res://CORE/Assets/Art/Home/CubeInfo/GreenSkin2/green2_3.png", "res://CORE/Assets/Art/Home/CubeInfo/GreenSkin2/green2_4.png", "res://CORE/Assets/Art/Home/CubeInfo/GreenSkin2/green2_5.png", "res://CORE/Assets/Art/Home/CubeInfo/GreenSkin2/green2_6.png"]},
	],
	"yellow": [
		{"static": "res://CORE/Assets/Art/Game/Cubes/Yellow/Yellow.svg",
		 "frames": ["res://CORE/Assets/Art/Game/Cubes/Yellow/Yellow.svg", "res://CORE/Assets/Art/Game/Cubes/Yellow/Yellow_2.svg", "res://CORE/Assets/Art/Game/Cubes/Yellow/Yellow_3.svg", "res://CORE/Assets/Art/Game/Cubes/Yellow/Yellow_4.svg", "res://CORE/Assets/Art/Game/Cubes/Yellow/Yellow_5.svg", "res://CORE/Assets/Art/Game/Cubes/Yellow/Yellow_6.svg", "res://CORE/Assets/Art/Game/Cubes/Yellow/Yellow_7.svg"]},
		{"static": "res://CORE/Assets/Art/Home/CubeInfo/YellowSkin2/yellow2_1.png",
		 "frames": ["res://CORE/Assets/Art/Home/CubeInfo/YellowSkin2/yellow2_1.png", "res://CORE/Assets/Art/Home/CubeInfo/YellowSkin2/yellow2_2.png", "res://CORE/Assets/Art/Home/CubeInfo/YellowSkin2/yellow2_3.png", "res://CORE/Assets/Art/Home/CubeInfo/YellowSkin2/yellow2_4.png", "res://CORE/Assets/Art/Home/CubeInfo/YellowSkin2/yellow2_5.png", "res://CORE/Assets/Art/Home/CubeInfo/YellowSkin2/yellow2_6.png"]},
	],
	"orange": [
		{"static": "res://CORE/Assets/Art/Game/Cubes/Orange/Orange.svg",
		 "frames": ["res://CORE/Assets/Art/Game/Cubes/Orange/Orange.svg", "res://CORE/Assets/Art/Game/Cubes/Orange/Orange_2.svg", "res://CORE/Assets/Art/Game/Cubes/Orange/Orange_3.svg", "res://CORE/Assets/Art/Game/Cubes/Orange/Orange_4.svg", "res://CORE/Assets/Art/Game/Cubes/Orange/Orange_5.svg", "res://CORE/Assets/Art/Game/Cubes/Orange/Orange_6.svg", "res://CORE/Assets/Art/Game/Cubes/Orange/Orange_7.svg"]},
		{"static": "res://CORE/Assets/Art/Home/CubeInfo/OrangeSkin2/orange2_1.png",
		 "frames": ["res://CORE/Assets/Art/Home/CubeInfo/OrangeSkin2/orange2_1.png", "res://CORE/Assets/Art/Home/CubeInfo/OrangeSkin2/orange2_2.png", "res://CORE/Assets/Art/Home/CubeInfo/OrangeSkin2/orange2_3.png", "res://CORE/Assets/Art/Home/CubeInfo/OrangeSkin2/orange2_4.png", "res://CORE/Assets/Art/Home/CubeInfo/OrangeSkin2/orange2_5.png", "res://CORE/Assets/Art/Home/CubeInfo/OrangeSkin2/orange2_6.png"]},
	],
	"purple": [
		{"static": "res://CORE/Assets/Art/Game/Cubes/Purple/Purple.svg",
		 "frames": ["res://CORE/Assets/Art/Game/Cubes/Purple/Purple.svg", "res://CORE/Assets/Art/Game/Cubes/Purple/Purple_2.svg", "res://CORE/Assets/Art/Game/Cubes/Purple/Purple_3.svg", "res://CORE/Assets/Art/Game/Cubes/Purple/Purple_4.svg", "res://CORE/Assets/Art/Game/Cubes/Purple/Purple_5.svg", "res://CORE/Assets/Art/Game/Cubes/Purple/Purple_6.svg", "res://CORE/Assets/Art/Game/Cubes/Purple/Purple_7.svg"]},
		{"static": "res://CORE/Assets/Art/Home/CubeInfo/PurpleSkin2/purple2_1.png",
		 "frames": ["res://CORE/Assets/Art/Home/CubeInfo/PurpleSkin2/purple2_1.png", "res://CORE/Assets/Art/Home/CubeInfo/PurpleSkin2/purple2_2.png", "res://CORE/Assets/Art/Home/CubeInfo/PurpleSkin2/purple2_3.png", "res://CORE/Assets/Art/Home/CubeInfo/PurpleSkin2/purple2_4.png", "res://CORE/Assets/Art/Home/CubeInfo/PurpleSkin2/purple2_5.png", "res://CORE/Assets/Art/Home/CubeInfo/PurpleSkin2/purple2_6.png"]},
	],
	"pink": [
		{"static": "res://CORE/Assets/Art/Game/Cubes/Pink/Pink.svg",
		 "frames": ["res://CORE/Assets/Art/Game/Cubes/Pink/Pink.svg", "res://CORE/Assets/Art/Game/Cubes/Pink/Pink_2.svg", "res://CORE/Assets/Art/Game/Cubes/Pink/Pink_3.svg", "res://CORE/Assets/Art/Game/Cubes/Pink/Pink_4.svg", "res://CORE/Assets/Art/Game/Cubes/Pink/Pink_5.svg", "res://CORE/Assets/Art/Game/Cubes/Pink/Pink_6.svg", "res://CORE/Assets/Art/Game/Cubes/Pink/Pink_7.svg"]},
		{"static": "res://CORE/Assets/Art/Home/CubeInfo/PinkSkin2/pink2_1.png",
		 "frames": ["res://CORE/Assets/Art/Home/CubeInfo/PinkSkin2/pink2_1.png", "res://CORE/Assets/Art/Home/CubeInfo/PinkSkin2/pink2_2.png", "res://CORE/Assets/Art/Home/CubeInfo/PinkSkin2/pink2_3.png", "res://CORE/Assets/Art/Home/CubeInfo/PinkSkin2/pink2_4.png", "res://CORE/Assets/Art/Home/CubeInfo/PinkSkin2/pink2_5.png", "res://CORE/Assets/Art/Home/CubeInfo/PinkSkin2/pink2_6.png"]},
	],
}
const SKIN_CFG := "user://cube_skins.cfg"
var selected_skin: Dictionary = {}   # color -> indice skin

func _load_skins() -> void:
	var cf := ConfigFile.new()
	if cf.load(SKIN_CFG) == OK and cf.has_section("skins"):
		for k in cf.get_section_keys("skins"):
			selected_skin[k] = int(cf.get_value("skins", k, 0))

func _save_skins() -> void:
	var cf := ConfigFile.new()
	for k in selected_skin:
		cf.set_value("skins", k, selected_skin[k])
	cf.save(SKIN_CFG)

func get_skin_index(color: String) -> int:
	return int(selected_skin.get(color, 0))

func get_skin(color: String) -> Dictionary:
	var arr: Array = CUBE_SKINS.get(color, [])
	if arr.is_empty():
		return {}
	return arr[clampi(get_skin_index(color), 0, arr.size() - 1)]

func set_skin(color: String, idx: int) -> void:
	selected_skin[color] = idx
	_save_skins()


func _ready() -> void:
	_load_skins()
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
	for i in range(1, 12):   # 11 suoni combo NUOVI (1..11); oltre l'11 usa l'11
		_sfx_combo.append(_make_sfx(SFX_DIR + "combo%d.wav" % i))
	for i in range(1, 6):    # combo VECCHI (1..5) sotto, più bassi di volume
		var op := _make_sfx(SFX_DIR + "combo%d.mp3" % i)
		if op:
			op.volume_db = -12.0
		_sfx_combo_old.append(op)

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
	_play_sfx(_sfx_combo[i])           # nuovo suono (volume pieno)
	if not _sfx_combo_old.is_empty():  # vecchio suono in layer, più basso
		var j: int = clampi(level, 1, _sfx_combo_old.size()) - 1
		_play_sfx(_sfx_combo_old[j])

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
	music_toggled.emit(enabled)   # avvisa le scene con musica propria (speedrun)
	save_settings()

func set_sound_enabled(enabled: bool) -> void:
	if sound_enabled == enabled:
		return
	sound_enabled = enabled
	if not sound_enabled:
		var all_sfx := [_sfx_uiclick, _sfx_destroy, _sfx_extramove, _sfx_disappear, _sfx_pickup,
			_sfx_place, _sfx_playbtn, _sfx_toggle_on, _sfx_toggle_off,
			_sfx_error, _sfx_gameover, _sfx_highscore] + _sfx_combo + _sfx_combo_old
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
