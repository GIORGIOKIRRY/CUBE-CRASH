extends Control

signal MenuClosed

# ==========================
# File di salvataggio
# ==========================
const SETTINGS_PATH := "user://settings.dat"

# ==========================
# Stato vibrazione
# ==========================
var vibration_enabled: bool = true

# ==========================
# Nodi
# ==========================
@onready var sound_button: TextureButton = %SoundButton
@onready var music_button: TextureButton = %MusicButton
@onready var vibration_button: TextureButton = %VibrationButton

# ==========================
# Texture
# ==========================
@export var sound_on_texture: Texture2D
@export var sound_off_texture: Texture2D

@export var music_on_texture: Texture2D
@export var music_off_texture: Texture2D

@export var vibration_on_texture: Texture2D
@export var vibration_off_texture: Texture2D

# ==========================
# Ready
# ==========================
func _ready() -> void:
	_load_vibration_setting()
	_update_all_buttons()

# ==========================
# Pulsanti
# ==========================

func _on_sound_button_pressed() -> void:
	settings.set_sound_enabled(!settings.sound_enabled)
	_update_sound_button()

func _on_music_button_pressed() -> void:
	settings.set_music_enabled(!settings.music_enabled)
	_update_music_button()

func _on_vibration_button_pressed() -> void:
	vibration_enabled = !vibration_enabled
	_update_vibration_button()
	_save_vibration_setting()

# ==========================
# Close menu
# ==========================
func _on_close_button_pressed() -> void:
	visible = false
	MenuClosed.emit()

# ==========================
# Aggiornamento UI
# ==========================
func _update_all_buttons() -> void:
	_update_sound_button()
	_update_music_button()
	_update_vibration_button()

func _update_sound_button() -> void:
	if sound_button:
		sound_button.texture_normal = (
			sound_on_texture if settings.sound_enabled else sound_off_texture
		)

func _update_music_button() -> void:
	if music_button:
		music_button.texture_normal = (
			music_on_texture if settings.music_enabled else music_off_texture
		)

func _update_vibration_button() -> void:
	if vibration_button:
		vibration_button.texture_normal = (
			vibration_on_texture if vibration_enabled else vibration_off_texture
		)

# ==========================
# Salvataggio
# ==========================
func _save_vibration_setting() -> void:
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH) # preserva altri dati
	cfg.set_value("feedback", "vibration", vibration_enabled)
	cfg.save(SETTINGS_PATH)

# ==========================
# Caricamento
# ==========================
func _load_vibration_setting() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		vibration_enabled = bool(
			cfg.get_value("feedback", "vibration", true)
		)
