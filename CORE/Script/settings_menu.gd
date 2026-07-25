extends Control

signal MenuClosed

# ==========================
# Nodi
# ==========================
@onready var sound_button: TextureButton = %SoundButton
@onready var music_button: TextureButton = %MusicButton
@onready var vibration_button: TextureButton = %VibrationButton
@onready var _menu: Control = $Menu
@onready var _options: Control = $Menu/Control
@onready var _title: Label = $Menu/Label
@onready var _close_btn: TextureButton = $Menu/CloseButton

# ==========================
# Texture toggle
# ==========================
@export var sound_on_texture: Texture2D
@export var sound_off_texture: Texture2D
@export var music_on_texture: Texture2D
@export var music_off_texture: Texture2D
@export var vibration_on_texture: Texture2D
@export var vibration_off_texture: Texture2D

# ==========================
# More settings / pagine
# ==========================
const BACK_ICON := preload("res://CORE/Assets/Art/UI/Settings/back.svg")
const DIVIDER := preload("res://CORE/Assets/Art/UI/Settings/Divider.svg")
const FONT := preload("res://CORE/Assets/Font/Jersey10-Regular.ttf")

const CONTACT_EMAIL := "cubecrash.game@gmail.com"
const PRIVACY_TEXT := "La tua privacy è importante.\nCube Crash non richiede account, non raccoglie dati personali e salva i progressi solo sul tuo dispositivo."
const TERMS_TEXT := "Usando Cube Crash accetti i termini di servizio del gioco."

var _more_root: Control = null
var _subpages: Dictionary = {}   # nome -> Control

# ==========================
# Ready
# ==========================
func _ready() -> void:
	_update_all_buttons()
	_build_more_page()
	_build_subpages()

# ==========================
# Pulsanti audio/vibrazione
# ==========================
func _on_sound_button_pressed() -> void:
	settings.button_feedback()
	settings.set_sound_enabled(!settings.sound_enabled)
	_update_sound_button()

func _on_music_button_pressed() -> void:
	settings.button_feedback()
	settings.set_music_enabled(!settings.music_enabled)
	_update_music_button()

func _on_vibration_button_pressed() -> void:
	settings.play_tap()
	settings.vibrate(15)
	settings.set_vibration_enabled(!settings.vibration_enabled)
	_update_vibration_button()

func _on_share_button_pressed() -> void:
	settings.button_feedback()
	OS.shell_open(settings.APPSTORE_URL)

# ==========================
# More page (frame Group7 + 5 righe)
# ==========================
func _on_more_button_pressed() -> void:
	settings.button_feedback()
	_show_more(true)

func _show_more(on: bool) -> void:
	if _more_root == null:
		return
	# La box e il titolo "SETTINGS" restano gli stessi della schermata precedente:
	# cambiano solo le righe elencate sotto (niente titolo "More Settings" separato).
	_more_root.visible = on
	_options.visible = not on

func _build_more_page() -> void:
	# Stessa area interna delle righe delle impostazioni (dentro il box Menu),
	# così la box è identica/alta come nella schermata precedente.
	_more_root = Control.new()
	_more_root.position = Vector2(16, 98)
	_more_root.size = Vector2(363, 377)
	_more_root.visible = false
	_menu.add_child(_more_root)

	var entries := [
		{"text": "CONTACT US", "cb": Callable(self, "_on_contact")},
		{"text": "SHARE GAME", "cb": Callable(self, "_on_share_button_pressed")},
		{"text": "TERMS OF SERVICE", "cb": Callable(self, "_open_terms")},
		{"text": "PRIVACY POLICY", "cb": Callable(self, "_open_privacy")},
		{"text": "THANKS", "cb": Callable(self, "_open_thanks")},
	]
	var row_h := 75.0
	for i in entries.size():
		var y := i * row_h

		var lbl := Label.new()
		lbl.text = entries[i]["text"]
		lbl.position = Vector2(24, y)
		lbl.size = Vector2(315, row_h)
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.add_theme_font_override("font", FONT)
		lbl.add_theme_font_size_override("font_size", 30)
		lbl.add_theme_color_override("font_color", Color(1, 1, 1))
		_more_root.add_child(lbl)

		_more_root.add_child(_make_invisible_button(
			Vector2(0, y), Vector2(363, row_h), entries[i]["cb"]))

		if i < entries.size() - 1:
			var d := TextureRect.new()
			d.texture = DIVIDER
			d.position = Vector2(19, y + row_h - 1.0)
			_more_root.add_child(d)

func _make_invisible_button(pos: Vector2, sz: Vector2, cb: Callable) -> Button:
	var b := Button.new()
	b.position = pos
	b.size = sz
	var empty := StyleBoxEmpty.new()
	b.add_theme_stylebox_override("normal", empty)
	b.add_theme_stylebox_override("hover", empty)
	b.add_theme_stylebox_override("pressed", empty)
	b.add_theme_stylebox_override("focus", empty)
	b.pressed.connect(cb)
	return b

# ==========================
# Azioni righe
# ==========================
func _on_contact() -> void:
	settings.button_feedback()
	var subject := "Cube Crash"
	var body := "Ciao team Cube Crash,"
	OS.shell_open("mailto:%s?subject=%s&body=%s" % [
		CONTACT_EMAIL, subject.uri_encode(), body.uri_encode()
	])

func _open_terms() -> void:
	settings.button_feedback()
	_show_subpage("terms")

func _open_privacy() -> void:
	settings.button_feedback()
	_show_subpage("privacy")

func _open_thanks() -> void:
	settings.button_feedback()
	_show_subpage("thanks")

# ==========================
# Sotto-pagine a schermo intero
# ==========================
func _build_subpages() -> void:
	_subpages["terms"] = _make_subpage("TERMS OF SERVICE", _terms_content())
	_subpages["privacy"] = _make_subpage("PRIVACY POLICY", _privacy_content())
	_subpages["thanks"] = _make_subpage("THANKS", _thanks_content())

func _show_subpage(name: String) -> void:
	for k in _subpages:
		_subpages[k].visible = (k == name)

# Apertura diretta dei ringraziamenti dalla home (tastino pergamena in alto a destra)
func open_thanks_from_home() -> void:
	visible = true
	_show_more(false)
	_show_subpage("thanks")

func _hide_subpages() -> void:
	for k in _subpages:
		_subpages[k].visible = false

func _make_subpage(title: String, content: Control) -> Control:
	var page := Control.new()
	page.visible = false
	page.z_index = 50
	add_child(page)

	# sfondo blu a tutto schermo
	var bg := ColorRect.new()
	bg.color = Color(0.08627451, 0.41568628, 0.59607846, 1)
	bg.position = Vector2(-900, -900)
	bg.size = Vector2(2400, 2800)
	page.add_child(bg)

	# tasto indietro: stessa posizione dell'icona Link nella home (36, 0), 62x62
	var back := TextureButton.new()
	back.texture_normal = BACK_ICON
	back.position = Vector2(36, 0)
	back.size = Vector2(62, 62)
	back.pressed.connect(_on_subpage_back)
	page.add_child(back)

	# titolo
	var lbl := Label.new()
	lbl.text = title
	lbl.position = Vector2(0, 150)
	lbl.size = Vector2(576, 90)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_override("font", FONT)
	lbl.add_theme_font_size_override("font_size", 52)
	lbl.add_theme_color_override("font_color", Color(1, 1, 1))
	page.add_child(lbl)

	# contenuto
	content.position = Vector2(40, 260)
	content.size = Vector2(496, 640)
	page.add_child(content)

	return page

func _on_subpage_back() -> void:
	settings.button_feedback()
	_hide_subpages()

func _make_text(txt: String, color: Color, size: int) -> Label:
	var l := Label.new()
	l.text = txt
	l.add_theme_font_override("font", FONT)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l

func _terms_content() -> Control:
	var c := _make_text(TERMS_TEXT, Color(1, 1, 1), 30)
	c.custom_minimum_size = Vector2(496, 0)
	return c

func _privacy_content() -> Control:
	var c := _make_text(PRIVACY_TEXT, Color(1, 1, 1), 30)
	c.custom_minimum_size = Vector2(496, 0)
	return c

func _thanks_content() -> Control:
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	var og := _make_text("OG", Color(1, 0.85, 0.1), 34)
	var names := _make_text("Giorgio Rossellini, Tu", Color(1, 1, 1), 30)
	vb.add_child(og)
	vb.add_child(names)
	return vb

# ==========================
# Close (X): back se sei in More, altrimenti chiudi
# ==========================
func _on_close_button_pressed() -> void:
	settings.button_feedback()
	if _more_root != null and _more_root.visible:
		_show_more(false)
		return
	visible = false
	MenuClosed.emit()

# ==========================
# Aggiornamento UI toggle
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
			vibration_on_texture if settings.vibration_enabled else vibration_off_texture
		)
