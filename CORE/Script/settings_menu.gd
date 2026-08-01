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
const BACK_ICON := preload("res://CORE/Assets/Art/UI/Settings/back_icon.png")
const DIVIDER := preload("res://CORE/Assets/Art/UI/Settings/Divider.svg")
const FONT := preload("res://CORE/Assets/Font/Jersey10-Regular.ttf")
# Nuovo design
const SETTINGS_FRAME := preload("res://CORE/Assets/Art/UI/Settings/settings_frame.png")
const CLOSE_ICON := preload("res://CORE/Assets/Art/UI/Settings/close_icon.png")
const TOGGLE_ON := preload("res://CORE/Assets/Art/UI/Settings/toggle_on.png")
const TOGGLE_OFF := preload("res://CORE/Assets/Art/UI/Settings/toggle_off.png")
const SUBPAGE_BG := preload("res://CORE/Assets/Art/UI/Settings/subpage_bg.png")
const ARROW_BTN := preload("res://CORE/Assets/Art/UI/Settings/arrow_setting.png")

const PATCHNOTES_TEXT := "🎮 CUBE CRASH\nNovità di questa versione:\n\n🕹️ NUOVA HOME ARCADE\n🎯 Cabinato + tasto PLAY, scegli la modalità con le frecce\n📱 Menu in basso: Missioni · Home · Shop (ottimizzata per tablet/iPad)\n\n🧩 MODALITÀ\n💥 CLASSIC — combo a raffica + bombe (durata ribilanciata)\n⏱️ SPEEDRUN — più punti in 5 minuti (countdown 3-2-1-GO!)\n\n👤 PROFILO\n🖼️ Schermata EDIT PROFILE: scegli icona e nome personalizzati\n\n🏆 CLASSIFICA (TOP CRASHER)\n📊 Top 1-100 per Classic e Speedrun, si rinnova ogni 7 giorni\n🟢 La tua posizione evidenziata\n\n🎯 MISSIONI\n✅ GIORNALIERE (24h) e ⭐ SETTIMANALI (7 giorni)\n🪙 200 monete a missione giornaliera, 1000 a settimanale\n🔔 Badge quando hai ricompense da riscuotere\n✨ Monete e punteggio animati (contatore che sale)\n\n🔗 COMBO fino a 11 con animazioni a schermo intero\n💠 Abilità speciali con beam colorato per colore\n🎵 Nuova musica in home + nuova grafica gameplay\n\n⚡ PRESTAZIONI\n🚀 Avvio partita più veloce + animazioni combo più leggere\n👆 Tocco più preciso nel piazzare i cubi\n🐛 Fix crash e vari bug\n\n🛒 Shop in arrivo!\n\n📱 Grazie per aver provato questa build!"

const CONTACT_EMAIL := "cubecrash.game@gmail.com"
const PRIVACY_TEXT := "PRIVACY POLICY\nUltimo aggiornamento: 2026\n\nCube Crash (\"il Gioco\") rispetta la tua privacy. Questa policy spiega quali dati vengono trattati.\n\n1. DATI CHE NON RACCOGLIAMO\nNon richiediamo registrazione né account. Non raccogliamo nome reale, email, contatti o posizione. I progressi (punteggi, monete, profilo) sono salvati SOLO sul tuo dispositivo.\n\n2. CLASSIFICA ONLINE\nSe usi la classifica, vengono inviati solo il nome che scegli e il punteggio, per mostrarli nella classifica pubblica. Non sono dati identificativi.\n\n3. PUBBLICITÀ (AdMob)\nIl Gioco mostra annunci tramite Google AdMob. Google può raccogliere identificatori del dispositivo e dati d'uso per fornire annunci. Consulta la Privacy Policy di Google: https://policies.google.com/privacy\nPuoi limitare gli annunci personalizzati dalle impostazioni del dispositivo.\n\n4. MINORI\nIl Gioco è adatto a tutti. Non raccogliamo consapevolmente dati personali da minori.\n\n5. CONTATTI\nPer domande: cubecrash.game@gmail.com"
const TERMS_TEXT := "TERMS OF SERVICE\nUltimo aggiornamento: 2026\n\nBenvenuto in Cube Crash. Usando il Gioco accetti questi termini.\n\n1. LICENZA\nTi concediamo una licenza personale, non esclusiva e non trasferibile per giocare a Cube Crash per uso personale e non commerciale.\n\n2. USO CORRETTO\nNon puoi copiare, modificare, decompilare o distribuire il Gioco, né usare cheat, bot o exploit che alterino punteggi e classifiche.\n\n3. CONTENUTI E PROGRESSI\nI progressi sono salvati sul dispositivo. Aggiornamenti o disinstallazioni possono azzerarli. Non garantiamo il recupero dei dati.\n\n4. PUBBLICITÀ E ACQUISTI\nIl Gioco può mostrare annunci di terze parti. Eventuali acquisti futuri sono soggetti alle regole dello store.\n\n5. NESSUNA GARANZIA\nIl Gioco è fornito \"così com'è\", senza garanzie. Non siamo responsabili per eventuali danni derivanti dall'uso.\n\n6. MODIFICHE\nPossiamo aggiornare questi termini; l'uso continuato implica l'accettazione.\n\n7. CONTATTI\ncubecrash.game@gmail.com"

var _more_root: Control = null
var _more_back: TextureButton = null   # freccia per tornare alla pagina 1 dei settings
var _subpages: Dictionary = {}   # nome -> Control
var _opened_from_home: bool = false   # thanks aperto direttamente dalla home

# ==========================
# Ready
# ==========================
func _ready() -> void:
	_apply_new_design()
	_update_all_buttons()
	_build_more_page()
	_build_subpages()
	_apply_press_fx_all(self)   # affondamento + vibrazione su tutti i tasti

# Nuovo design: frame, titolo, X, toggle, padding, tap-fuori-per-chiudere
func _apply_new_design() -> void:
	# frame nuovo (settings_frame.png), aspect 2496:3392 = 0.736 -> 440x598
	if _menu:
		_menu.texture = SETTINGS_FRAME
		_menu.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_menu.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_menu.stretch_mode = TextureRect.STRETCH_SCALE
		_menu.mouse_filter = Control.MOUSE_FILTER_STOP
		_menu.offset_left = -250.0
		_menu.offset_right = 250.0
		_menu.offset_top = -339.5
		_menu.offset_bottom = 339.5
	var bg := get_node_or_null("Menu/BG")
	if bg:
		bg.visible = false
	# titolo SETTINGS in alto
	if _title:
		_title.add_theme_font_size_override("font_size", 44)
		_title.add_theme_color_override("font_color", Color(1, 1, 1))
		_title.add_theme_color_override("font_outline_color", Color(0, 0.06, 0.2))
		_title.add_theme_constant_override("outline_size", 6)
		_title.offset_left = -130.0
		_title.offset_right = 130.0
		_title.offset_top = 46.0     # centro verticale allineato alla X (centro ~73)
		_title.offset_bottom = 100.0
		_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	# X vicino al testo SETTINGS, un po' più in basso, staccata dal bordo
	if _close_btn:
		_close_btn.texture_normal = CLOSE_ICON
		_close_btn.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_close_btn.ignore_texture_size = true
		_close_btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		_close_btn.offset_left = 402.0
		_close_btn.offset_top = 40.0
		_close_btn.offset_right = 468.0
		_close_btn.offset_bottom = 106.0
	# toggle on/off + tasti freccia (More/Share e righe): stessa grafica
	sound_on_texture = TOGGLE_ON
	sound_off_texture = TOGGLE_OFF
	music_on_texture = TOGGLE_ON
	music_off_texture = TOGGLE_OFF
	vibration_on_texture = TOGGLE_ON
	vibration_off_texture = TOGGLE_OFF
	for b in [sound_button, music_button, vibration_button]:
		_style_right_button(b, null)
	_style_right_button(get_node_or_null("Menu/Control/MoreSettings/MoreButton"), ARROW_BTN)
	_style_right_button(get_node_or_null("Menu/Control/ShareSettings/ShareButton"), ARROW_BTN)
	# righe con più PADDING tra le sezioni
	var rows := ["SoundSettings", "MusicSettings", "VibrationSettings", "MoreSettings", "ShareSettings"]
	var divs := ["Divider1", "Divider2", "Divider3", "Divider4"]
	var lbl_names := {"SoundSettings": "Sound", "MusicSettings": "Music", "VibrationSettings": "Vibration", "MoreSettings": "More", "ShareSettings": "Share"}
	var y0 := 54.0      # più spazio tra la zona titolo/X e le sezioni
	var step := 100.0   # padding tra sezioni (leggermente aumentato)
	var row_h := 73.0
	for i in rows.size():
		var r := get_node_or_null("Menu/Control/" + rows[i]) as Control
		if r:
			r.offset_left = 0.0
			r.offset_right = 440.0
			r.offset_top = y0 + i * step
			r.offset_bottom = y0 + i * step + row_h
			var lb := r.get_node_or_null(str(lbl_names[rows[i]])) as Label
			if lb:
				lb.add_theme_font_size_override("font_size", 38)
				lb.offset_left = 83.0
				lb.offset_right = 340.0
	# nascondi i vecchi divider e metti linee blu scuro a tutta sezione tra una e l'altra
	for i in divs.size():
		var d := get_node_or_null("Menu/Control/" + divs[i]) as Control
		if d:
			d.visible = false
	if _options:
		for i in range(rows.size() - 1):
			var line := ColorRect.new()
			line.color = Color(0.03, 0.09, 0.24, 1.0)   # blu scuro
			line.mouse_filter = Control.MOUSE_FILTER_IGNORE
			line.position = Vector2(12.0, y0 + i * step + row_h + (step - row_h) * 0.5 - 2.0)
			line.size = Vector2(416.0, 4.0)
			_options.add_child(line)
		_options.offset_left = -220.0
		_options.offset_right = 220.0
		_options.offset_top = -260.0
		_options.offset_bottom = 320.0
	# tap FUORI dal frame (zona scura) -> chiudi (come edit profile)
	var dim := get_node_or_null("ColorRect")
	if dim:
		dim.mouse_filter = Control.MOUSE_FILTER_STOP
		dim.gui_input.connect(func(e: InputEvent) -> void:
			if e is InputEventMouseButton and e.pressed:
				_on_close_button_pressed())

# Stile comune per i tasti a destra delle righe (toggle o freccia)
func _style_right_button(b: TextureButton, tex: Texture2D) -> void:
	if b == null:
		return
	if tex != null:
		b.texture_normal = tex
	b.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	b.ignore_texture_size = true
	b.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	b.offset_left = 352.0    # far right: più lontano dal testo
	b.offset_top = 14.0
	b.offset_right = 434.0
	b.offset_bottom = 65.0   # ~82x51, aspect 1.6

func _apply_press_fx_all(node: Node) -> void:
	for c in node.get_children():
		if c is BaseButton and not c.has_meta("pfx"):
			var b := c as BaseButton
			b.set_meta("pfx", true)
			b.button_down.connect(func() -> void:
				b.position.y += 5.0
				settings.vibrate(15))
			b.button_up.connect(func() -> void:
				b.position.y -= 5.0)
		_apply_press_fx_all(c)

# ==========================
# Pulsanti audio/vibrazione
# ==========================
func _on_sound_button_pressed() -> void:
	var new_state := not settings.sound_enabled
	settings.vibrate(15)
	if new_state:
		settings.set_sound_enabled(true)
		settings.play_toggle(true)
	else:
		settings.play_toggle(false)   # suona prima di disattivare l'audio
		settings.set_sound_enabled(false)
	_update_sound_button()

func _on_music_button_pressed() -> void:
	var new_state := not settings.music_enabled
	settings.play_toggle(new_state)
	settings.vibrate(15)
	settings.set_music_enabled(new_state)
	_update_music_button()

func _on_vibration_button_pressed() -> void:
	var new_state := not settings.vibration_enabled
	settings.play_toggle(new_state)
	settings.vibrate(15)
	settings.set_vibration_enabled(new_state)
	_update_vibration_button()

func _on_share_button_pressed() -> void:
	settings.button_feedback()
	OS.shell_open(settings.APPSTORE_URL)

# ==========================
# More page (frame Group7 + 5 righe)
# ==========================
func _on_more_button_pressed() -> void:
	settings.button_feedback()
	_opened_from_home = false
	_show_more(true)

func _show_more(on: bool) -> void:
	if _more_root == null:
		return
	# La box e il titolo "SETTINGS" restano gli stessi della schermata precedente:
	# cambiano solo le righe elencate sotto (niente titolo "More Settings" separato).
	_more_root.visible = on
	_options.visible = not on
	if _title:
		_title.text = "MORE" if on else "SETTINGS"
	if _more_back:
		_more_back.visible = on

func _build_more_page() -> void:
	# Stessa area interna delle righe delle impostazioni (dentro il box Menu),
	# così la box è identica/alta come nella schermata precedente.
	_more_root = Control.new()
	_more_root.position = Vector2(30, 133)
	_more_root.size = Vector2(440, 540)
	_more_root.visible = false
	_menu.add_child(_more_root)

	# freccia indietro (a sinistra del titolo MORE) -> torna alla pagina 1 dei settings
	_more_back = TextureButton.new()
	_more_back.texture_normal = BACK_ICON
	_more_back.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_more_back.ignore_texture_size = true
	_more_back.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	_more_back.offset_left = 32.0
	_more_back.offset_top = 40.0
	_more_back.offset_right = 98.0
	_more_back.offset_bottom = 106.0
	_more_back.visible = false
	_more_back.pressed.connect(func() -> void:
		settings.button_feedback()
		_show_more(false))
	_menu.add_child(_more_back)

	var entries := [
		{"text": "CONTACT US", "cb": Callable(self, "_on_contact")},
		{"text": "SHARE GAME", "cb": Callable(self, "_on_share_button_pressed")},
		{"text": "TERMS OF SERVICE", "cb": Callable(self, "_open_terms")},
		{"text": "PRIVACY POLICY", "cb": Callable(self, "_open_privacy")},
		{"text": "THANKS", "cb": Callable(self, "_open_thanks")},
	]
	var row_h := 100.0   # stesso passo delle righe di SETTINGS
	for i in entries.size():
		var y := i * row_h

		var lbl := Label.new()
		lbl.text = entries[i]["text"]
		lbl.position = Vector2(24, y)
		lbl.size = Vector2(300, 73.0)
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.add_theme_font_override("font", FONT)
		lbl.add_theme_font_size_override("font_size", 38)   # stessa grandezza di SETTINGS
		lbl.add_theme_color_override("font_color", Color(1, 1, 1))
		_more_root.add_child(lbl)

		# freccia a destra della riga (stessa posizione/dimensione dei toggle)
		var arr := TextureRect.new()
		arr.texture = ARROW_BTN
		arr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		arr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		arr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		arr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		arr.position = Vector2(352, y + 14.0)
		arr.size = Vector2(82, 51)
		_more_root.add_child(arr)

		_more_root.add_child(_make_invisible_button(
			Vector2(0, y), Vector2(440, 73.0), entries[i]["cb"]))

		if i < entries.size() - 1:
			var d := ColorRect.new()
			d.color = Color(0.03, 0.09, 0.24, 1.0)   # blu scuro
			d.mouse_filter = Control.MOUSE_FILTER_IGNORE
			d.position = Vector2(12, y + 87.0)
			d.size = Vector2(416, 4)
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
	_subpages["patchnotes"] = _make_subpage("NOVITÀ", _patchnotes_content())

func _show_subpage(name: String) -> void:
	for k in _subpages:
		_subpages[k].visible = (k == name)

# Apertura diretta dei ringraziamenti dalla home (tastino pergamena in alto a destra)
func open_thanks_from_home() -> void:
	_opened_from_home = true
	visible = true
	_show_more(false)
	_show_subpage("thanks")

# Apertura diretta delle PATCH NOTES dalla home (tastino pergamena in alto a destra)
func open_patchnotes_from_home() -> void:
	_opened_from_home = true
	visible = true
	_show_more(false)
	_show_subpage("patchnotes")

# Font pixel (Jersey10) con fallback emoji di sistema, per le patch notes
func _pixel_emoji_font() -> Font:
	var emoji := SystemFont.new()
	emoji.font_names = PackedStringArray(["Apple Color Emoji", "Segoe UI Emoji", "Noto Color Emoji"])
	var f: FontFile = FONT.duplicate()
	var fb: Array[Font] = f.fallbacks.duplicate()
	fb.append(emoji)
	f.fallbacks = fb
	return f

func _patchnotes_content() -> Control:
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size = Vector2(496, 640)
	var lbl := Label.new()
	lbl.text = PATCHNOTES_TEXT
	lbl.add_theme_font_override("font", _pixel_emoji_font())
	lbl.add_theme_font_size_override("font_size", 28)
	lbl.add_theme_color_override("font_color", Color(1, 1, 1))
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.custom_minimum_size = Vector2(496, 0)
	scroll.add_child(lbl)
	return scroll

func _hide_subpages() -> void:
	for k in _subpages:
		_subpages[k].visible = false

func _make_subpage(title: String, content: Control) -> Control:
	var page := Control.new()
	page.set_anchors_preset(Control.PRESET_FULL_RECT)
	page.visible = false
	page.z_index = 50
	page.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(page)

	# sfondo dedicato (subpage_bg) a tutto schermo
	var bg := TextureRect.new()
	bg.texture = SUBPAGE_BG
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page.add_child(bg)

	# shift camera: la home è sul canvas della Camera2D (si sposta su schermi alti);
	# così la freccia cade dove sta l'icona profilo della home.
	var vh := 1024.0
	var vp := get_viewport()
	if vp:
		vh = vp.get_visible_rect().size.y
	var cam_shift := maxf(0.0, vh * 0.5 - 512.0)

	# freccia indietro nella posizione dell'icona profilo della home
	var back := TextureButton.new()
	back.texture_normal = BACK_ICON
	back.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	back.ignore_texture_size = true
	back.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	back.position = Vector2(24, 74 + cam_shift)
	back.size = Vector2(78, 78)
	back.pressed.connect(_on_subpage_back)
	page.add_child(back)

	# titolo
	var lbl := Label.new()
	lbl.text = title
	lbl.position = Vector2(0, 168 + cam_shift)
	lbl.size = Vector2(576, 70)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_override("font", FONT)
	lbl.add_theme_font_size_override("font_size", 50)
	lbl.add_theme_color_override("font_color", Color(1, 1, 1))
	lbl.add_theme_color_override("font_outline_color", Color(0, 0.06, 0.2))
	lbl.add_theme_constant_override("outline_size", 6)
	page.add_child(lbl)

	# contenuto (scrollabile, fino in fondo) sotto il titolo
	var cy := 258.0 + cam_shift
	content.position = Vector2(40, cy)
	content.size = Vector2(496, maxf(300.0, vh - cy - 30.0))
	page.add_child(content)

	return page

func _on_subpage_back() -> void:
	settings.button_feedback()
	_hide_subpages()
	# se la sotto-pagina era stata aperta direttamente dalla home, torna alla home
	# (chiudi tutto il menu) invece di mostrare i settings
	if _opened_from_home:
		_opened_from_home = false
		visible = false
		MenuClosed.emit()

func _make_text(txt: String, color: Color, size: int) -> Label:
	var l := Label.new()
	l.text = txt
	l.add_theme_font_override("font", FONT)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l

func _scrollable_text(txt: String) -> Control:
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER   # niente barra laterale
	scroll.clip_contents = true
	scroll.size = Vector2(496, 700)
	var lbl := _make_text(txt, Color(1, 1, 1), 26)
	lbl.custom_minimum_size = Vector2(496, 0)
	# spazio in fondo così l'ultima riga si legge tutta
	lbl.add_theme_constant_override("line_spacing", 4)
	scroll.add_child(lbl)
	return scroll

func _terms_content() -> Control:
	return _scrollable_text(TERMS_TEXT)

func _privacy_content() -> Control:
	return _scrollable_text(PRIVACY_TEXT)

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
	# la X chiude SEMPRE tutto (dalla pagina 1 o da MORE); per tornare a pagina 1 c'è la freccia
	_show_more(false)
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
