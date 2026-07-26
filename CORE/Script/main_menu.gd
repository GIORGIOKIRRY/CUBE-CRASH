extends Control

@onready var music_player := %AudioStreamPlayer2D

const MODE_FONT := preload("res://CORE/Assets/Font/Jersey10-Regular.ttf")

# Test A/B/C: 3 tasti Play, uno per modalità di gioco.
const MODES := [
	{"mode": "classic", "label": "CLASSIC",  "sub": "mosse attuali",       "color": Color(0.20, 0.55, 0.80)},
	{"mode": "mode_a",  "label": "MOD A",    "sub": "ogni azione = 1 mossa", "color": Color(0.90, 0.55, 0.15)},
	{"mode": "mode_b",  "label": "MOD B",    "sub": "no mosse (block blast)", "color": Color(0.25, 0.70, 0.35)},
]


func _ready() -> void:
	settings.play_music(music_player.stream)
	_build_mode_buttons()


# Nasconde il vecchio PlayButton e crea 3 tasti impilati (uno per modalità).
func _build_mode_buttons() -> void:
	var old := get_node_or_null("PlayButton")
	if old:
		old.visible = false

	var w := 320.0
	var h := 92.0
	var gap := 16.0
	var x := 288.0 - w * 0.5
	var y0 := 600.0

	for i in MODES.size():
		var m: Dictionary = MODES[i]
		var y := y0 + i * (h + gap)

		var btn := Button.new()
		btn.position = Vector2(x, y)
		btn.size = Vector2(w, h)
		btn.focus_mode = Control.FOCUS_NONE

		var sb := StyleBoxFlat.new()
		sb.bg_color = m["color"]
		sb.set_corner_radius_all(20)
		sb.shadow_color = Color(0, 0, 0, 0.35)
		sb.shadow_size = 6
		sb.shadow_offset = Vector2(0, 4)
		var sb_pressed := sb.duplicate()
		sb_pressed.bg_color = m["color"].darkened(0.2)
		btn.add_theme_stylebox_override("normal", sb)
		btn.add_theme_stylebox_override("hover", sb)
		btn.add_theme_stylebox_override("pressed", sb_pressed)
		btn.add_theme_stylebox_override("focus", sb)

		# titolo grande
		var title := Label.new()
		title.text = m["label"]
		title.add_theme_font_override("font", MODE_FONT)
		title.add_theme_font_size_override("font_size", 44)
		title.add_theme_color_override("font_color", Color(1, 1, 1))
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.position = Vector2(0, 6)
		title.size = Vector2(w, 52)
		btn.add_child(title)

		# sottotitolo piccolo
		var sub := Label.new()
		sub.text = m["sub"]
		sub.add_theme_font_override("font", MODE_FONT)
		sub.add_theme_font_size_override("font_size", 22)
		sub.add_theme_color_override("font_color", Color(1, 1, 1, 0.85))
		sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sub.position = Vector2(0, 56)
		sub.size = Vector2(w, 30)
		btn.add_child(sub)

		btn.pressed.connect(_start_mode.bind(m["mode"]))
		add_child(btn)


func _start_mode(mode: String) -> void:
	settings.game_mode = mode
	settings.play_playbutton()
	settings.vibrate(15)
	transition.change_scene("res://CORE/Scene/game.tscn")


func _on_play_button_pressed() -> void:
	# vecchio tasto (nascosto): avvia comunque la modalità classica
	_start_mode("classic")


func _on_settings_button_pressed() -> void:
	settings.button_feedback()
	%SettingsMenu.visible = true


# Link in alto a sinistra: condividi il gioco (App Store)
func _on_link_button_pressed() -> void:
	settings.button_feedback()
	OS.shell_open(settings.APPSTORE_URL)


# Pergamena in alto a destra: apre la sezione ringraziamenti
func _on_terms_button_pressed() -> void:
	settings.button_feedback()
	%SettingsMenu.open_thanks_from_home()
