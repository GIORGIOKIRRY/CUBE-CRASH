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
# Pagina THANKS: sfondo dedicato + freccia indietro rosa + tasto FOLLOW ME
const THANKS_BG := preload("res://CORE/Assets/Art/UI/Settings/thanks_bg.png")
const BACK_THANKS := preload("res://CORE/Assets/Art/UI/Settings/back_thanks.png")
const FOLLOW_ME := preload("res://CORE/Assets/Art/UI/Settings/follow_me.png")
const NAME_BOX := preload("res://CORE/Assets/Art/UI/Settings/name_box.png")
const SEND_BTN := preload("res://CORE/Assets/Art/UI/Settings/send_button.png")
# Social ufficiali Cube Crash (riga in fondo alla pagina MORE)
const SOCIAL_IG := preload("res://CORE/Assets/Art/UI/Settings/social_instagram.svg")
const SOCIAL_YT := preload("res://CORE/Assets/Art/UI/Settings/social_youtube.svg")
const SOCIAL_TIKTOK := preload("res://CORE/Assets/Art/UI/Settings/social_tiktok.svg")
const IG_URL := "https://www.instagram.com/cubecrashofficial/"
const YT_URL := "https://www.youtube.com/@CubeCrashOfficial"
const TIKTOK_URL := "https://www.tiktok.com/@cubecrashofficial?_r=1&_t=ZN-98YGDrdo8hC"

const PATCHNOTES_TEXT := "🎮 CUBE CRASH\nNovità di questa versione:\n\n🧪 ICONA BETA TESTER — chi gioca durante la BETA la trova già sbloccata nelle missioni: riscattala!\n🎬 DIVENTA CREATOR — manda il modulo in Impostazioni › More: se approvato ottieni l'icona Creator esclusiva e il nome VERDE brillante in classifica\n🎊 Coriandoli del NUOVO RECORD sistemati: ora partono sempre da fuori schermo\n\n🎬 NUOVA SCHERMATA DI CARICAMENTO\n🔊 Voce “Cube Crash” all'avvio + barra di caricamento pixel\n\n🧩 MODALITÀ\n💥 CLASSIC — combo un filo più frequenti, gameplay ribilanciato\n⏱️ SPEEDRUN — pochi colori all'inizio, combo più difficili da incatenare (oltre 10 = impresa), animazioni ricalibrate\n\n💣 BOMBE (3x3 · X · ANGOLI)\n🎯 Ora RARISSIME da trovare: sono un vero jolly\n\n🎯 MISSIONI\n✅ GIORNALIERE (24h) · ⭐ SETTIMANALI (7 giorni)\n🗓️ NUOVE MISSIONI MENSILI con ricompensa ICONA PROFILO:\n🎮 entra 7 giorni di fila → icona 🔥\n🏆 500.000 punti in Classic → icona 🏆\n🪙 Suoni nuovi per monete e riscossione missioni\n\n👤 PROFILO\n🖼️ Nuove icone profilo; quelle speciali si SBLOCCANO con le missioni (in B/N finché non le ottieni)\n\n🎉 NUOVO RECORD\n🎊 Pioggia di coriandoli pixelati sulla schermata record\n\n🏆 CLASSIFICA — Top 1-100 Classic e Speedrun, rinnovo settimanale\n\n📖 RINGRAZIAMENTI\n❤️ Lista supporter aggiornabile + tasto FOLLOW ME\n🔗 Social ufficiali: Instagram · YouTube · TikTok\n\n🔔 NOTIFICHE — promemoria giornalieri per non perdere le missioni\n\n🎵 SUONI — nuovi effetti per bombe, blocchi V/O, frecce\n⚙️ Le impostazioni mettono in pausa il gioco\n\n⚡ PRESTAZIONI — grafica più leggera, meno memoria, meno surriscaldamento\n🐛 Vari fix e miglioramenti\n\n🛒 Shop in arrivo!\n\n📱 Grazie per aver provato Cube Crash!"

const CONTACT_EMAIL := "cubecrash.game@gmail.com"
# Link del canale (per il tasto "follow" nella pagina THANKS). Da aggiornare col vero canale.
const CHANNEL_URL := "https://www.instagram.com/giorgiorossellini/"
# Lista OG SUPPORTERS aggiornabile da remoto (editabile dal telefono, nessuna build):
# editor: https://www.npoint.io/docs/c0e50f85707a48094b11
const SUPPORTERS_URL := "https://api.npoint.io/c0e50f85707a48094b11"
# Posta in arrivo delle proposte utenti ("manda il tuo nome"):
# editor: https://www.npoint.io/docs/d580adb16f1a8cd182d6
const PENDING_URL := "https://api.npoint.io/d580adb16f1a8cd182d6"
# Posta in arrivo delle richieste "diventa Creator":
# editor: https://www.npoint.io/docs/d307da3a533b2dd1bafa
const CREATOR_URL := "https://api.npoint.io/d307da3a533b2dd1bafa"
const PRIVACY_TEXT := "PRIVACY POLICY\nUltimo aggiornamento: 2026\n\nCube Crash (\"il Gioco\") rispetta la tua privacy. Questa policy spiega quali dati vengono trattati.\n\n1. DATI CHE NON RACCOGLIAMO\nNon richiediamo registrazione né account. Non raccogliamo nome reale, email, contatti o posizione. I progressi (punteggi, monete, profilo) sono salvati SOLO sul tuo dispositivo.\n\n2. CLASSIFICA ONLINE\nSe usi la classifica, vengono inviati solo il nome che scegli e il punteggio, per mostrarli nella classifica pubblica. Non sono dati identificativi.\n\n3. PUBBLICITÀ (AdMob)\nIl Gioco mostra annunci tramite Google AdMob. Google può raccogliere identificatori del dispositivo e dati d'uso per fornire annunci. Consulta la Privacy Policy di Google: https://policies.google.com/privacy\nPuoi limitare gli annunci personalizzati dalle impostazioni del dispositivo.\n\n4. MINORI\nIl Gioco è adatto a tutti. Non raccogliamo consapevolmente dati personali da minori.\n\n5. CONTATTI\nPer domande: cubecrash.game@gmail.com"
const TERMS_TEXT := "TERMS OF SERVICE\nUltimo aggiornamento: 2026\n\nBenvenuto in Cube Crash. Usando il Gioco accetti questi termini.\n\n1. LICENZA\nTi concediamo una licenza personale, non esclusiva e non trasferibile per giocare a Cube Crash per uso personale e non commerciale.\n\n2. USO CORRETTO\nNon puoi copiare, modificare, decompilare o distribuire il Gioco, né usare cheat, bot o exploit che alterino punteggi e classifiche.\n\n3. CONTENUTI E PROGRESSI\nI progressi sono salvati sul dispositivo. Aggiornamenti o disinstallazioni possono azzerarli. Non garantiamo il recupero dei dati.\n\n4. PUBBLICITÀ E ACQUISTI\nIl Gioco può mostrare annunci di terze parti. Eventuali acquisti futuri sono soggetti alle regole dello store.\n\n5. NESSUNA GARANZIA\nIl Gioco è fornito \"così com'è\", senza garanzie. Non siamo responsabili per eventuali danni derivanti dall'uso.\n\n6. MODIFICHE\nPossiamo aggiornare questi termini; l'uso continuato implica l'accettazione.\n\n7. CONTATTI\ncubecrash.game@gmail.com"

var _more_root: Control = null
var _more_back: TextureButton = null   # freccia per tornare alla pagina 1 dei settings
var _subpages: Dictionary = {}   # nome -> Control
var _opened_from_home: bool = false   # thanks aperto direttamente dalla home
var _supporters_label: Label = null   # etichetta nomi OG (aggiornata da remoto)
var _supporters_http: HTTPRequest = null
const SUPPORTERS_DEFAULT := "Giorgio Rossellini, Marco Zappa, Tu"
# Modulo "manda il tuo nome" (appare solo dopo aver premuto FOLLOW ME)
var _submit_box: Control = null
var _name_input: LineEdit = null
var _submit_btn: BaseButton = null
var _submit_status: Label = null
var _submit_http: HTTPRequest = null
var _submit_phase: int = 0        # 0 idle, 1 GET pending, 2 POST pending
var _submit_entry: String = ""    # proposta in corso
# Modulo "diventa Creator"
var _creator_input: LineEdit = null
var _creator_btn: BaseButton = null
var _creator_status: Label = null
var _creator_http: HTTPRequest = null
var _creator_phase: int = 0
var _creator_entry: String = ""
var _thanks_vb: Control = null       # VBox contenuto thanks
var _thanks_scroll: ScrollContainer = null   # scroll della pagina thanks

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
	var step := 106.0   # padding tra sezioni (leggermente aumentato)
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
		_title.text = loc.t("MORE") if on else loc.t("SETTINGS")
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
		{"text": "TERMS OF SERVICE", "cb": Callable(self, "_open_terms")},
		{"text": "PRIVACY POLICY", "cb": Callable(self, "_open_privacy")},
		{"text": "BECOME A CREATOR", "cb": Callable(self, "_open_creator")},
	]
	var row_h := 106.0   # stesso passo delle righe di SETTINGS
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

		# divisore sotto ogni riga (anche l'ultima: separa dalla riga social)
		var d := ColorRect.new()
		d.color = Color(0.03, 0.09, 0.24, 1.0)   # blu scuro
		d.mouse_filter = Control.MOUSE_FILTER_IGNORE
		d.position = Vector2(12, y + 90.0)
		d.size = Vector2(416, 4)
		_more_root.add_child(d)

	# --- riga SOCIAL ufficiali in fondo (Instagram, YouTube, TikTok) ---
	var socials := [
		{"tex": SOCIAL_IG, "url": IG_URL},
		{"tex": SOCIAL_YT, "url": YT_URL},
		{"tex": SOCIAL_TIKTOK, "url": TIKTOK_URL},
	]
	var sy := entries.size() * row_h + 24.0   # un po' distanziate dalle righe sopra
	var isize := 52.0                        # più piccole
	var gap := 44.0
	var total := socials.size() * isize + (socials.size() - 1) * gap
	var sx := (440.0 - total) * 0.5
	for s in socials:
		var btn := TextureButton.new()
		btn.texture_normal = s["tex"]
		btn.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		btn.ignore_texture_size = true
		btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		btn.position = Vector2(sx, sy)
		btn.size = Vector2(isize, isize)
		var url: String = s["url"]
		btn.pressed.connect(func() -> void:
			settings.button_feedback()
			OS.shell_open(url))
		_more_root.add_child(btn)
		sx += isize + gap

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
	_fetch_supporters()

func _open_patchnotes() -> void:
	settings.button_feedback()
	_show_subpage("patchnotes")

func _open_creator() -> void:
	settings.button_feedback()
	_show_subpage("creator")

# ==========================
# Sotto-pagine a schermo intero
# ==========================
func _build_subpages() -> void:
	_subpages["terms"] = _make_subpage("TERMS OF SERVICE", _terms_content())
	_subpages["privacy"] = _make_subpage("PRIVACY POLICY", _privacy_content())
	_subpages["thanks"] = _make_subpage("THANKS", _thanks_content(), THANKS_BG, BACK_THANKS)
	_subpages["patchnotes"] = _make_subpage("NOVITÀ", _patchnotes_content())
	_subpages["creator"] = _make_subpage("CREATOR", _creator_content())

func _show_subpage(name: String) -> void:
	for k in _subpages:
		_subpages[k].visible = (k == name)

# Apertura diretta dei ringraziamenti dalla home (tastino pergamena in alto a destra)
func open_thanks_from_home() -> void:
	_opened_from_home = true
	visible = true
	_show_more(false)
	_show_subpage("thanks")
	_fetch_supporters()

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
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER   # niente barra a destra
	scroll.clip_contents = true
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

# --- Modulo "DIVENTA UN CREATOR" (stessa grafica del form supporters) -----------
func _creator_content() -> Control:
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	var cw := 528.0

	var q := _make_text("Vuoi diventare un Content Creator ufficiale di Cube Crash?\nManda il modulo di verifica 🎬", Color(1, 1, 1), 28)
	q.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	q.add_theme_font_override("font", _pixel_emoji_font())
	q.custom_minimum_size = Vector2(cw, 0)
	_add_stroke(q)
	vb.add_child(q)

	# anteprima dell'icona profilo esclusiva Creator
	var icon_wrap := CenterContainer.new()
	icon_wrap.custom_minimum_size = Vector2(cw, 168.0)
	var icon := TextureRect.new()
	icon.texture = load("res://CORE/Assets/Art/Home/Profile/profile_creator.png")
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(160.0, 160.0)
	icon_wrap.add_child(icon)
	vb.add_child(icon_wrap)

	# box nome/canale (immagine name_box + LineEdit)
	var box_h := cw * 322.0 / 2693.0
	var name_wrap := Control.new()
	name_wrap.custom_minimum_size = Vector2(cw, box_h)
	var nb := TextureRect.new()
	nb.texture = NAME_BOX
	nb.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	nb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	nb.stretch_mode = TextureRect.STRETCH_SCALE
	nb.set_anchors_preset(Control.PRESET_FULL_RECT)
	nb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_wrap.add_child(nb)
	var inp := LineEdit.new()
	inp.placeholder_text = "Nome + link del tuo canale"
	inp.max_length = 80
	inp.alignment = HORIZONTAL_ALIGNMENT_CENTER
	inp.set_anchors_preset(Control.PRESET_FULL_RECT)
	inp.offset_left = 22
	inp.offset_right = -22
	inp.offset_top = 4
	inp.offset_bottom = -4
	inp.add_theme_font_override("font", FONT)
	inp.add_theme_font_size_override("font_size", 26)
	inp.add_theme_color_override("font_color", Color(0.1, 0.05, 0.12))
	inp.add_theme_color_override("font_placeholder_color", Color(0.4, 0.4, 0.45))
	inp.add_theme_color_override("caret_color", Color(0.1, 0.05, 0.12))
	var empty := StyleBoxEmpty.new()
	inp.add_theme_stylebox_override("normal", empty)
	inp.add_theme_stylebox_override("focus", empty)
	name_wrap.add_child(inp)
	vb.add_child(name_wrap)
	_creator_input = inp

	# tasto SEND (immagine)
	var send_h := cw * 299.0 / 2735.0
	var send := TextureButton.new()
	send.texture_normal = SEND_BTN
	send.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	send.ignore_texture_size = true
	send.stretch_mode = TextureButton.STRETCH_SCALE
	send.custom_minimum_size = Vector2(cw, send_h)
	send.button_down.connect(func() -> void: send.modulate = Color(0.9, 0.9, 0.9))
	send.button_up.connect(func() -> void: send.modulate = Color(1, 1, 1))
	send.pressed.connect(_on_creator_submit)
	vb.add_child(send)
	_creator_btn = send

	var status := _make_text("", Color(1, 1, 1), 24)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.custom_minimum_size = Vector2(cw, 0)
	_add_stroke(status)
	vb.add_child(status)
	_creator_status = status

	# requisiti
	var req := _make_text("Per diventare Cube Crash Creator devi aver fatto almeno 3 video sul gioco. Ti accetteremo come CubeCrash Creator e otterrai un'ICONA PROFILO ESCLUSIVA! 🏆", Color(1.0, 0.92, 0.45), 22)
	req.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	req.add_theme_font_override("font", _pixel_emoji_font())
	req.custom_minimum_size = Vector2(cw, 0)
	_add_stroke(req)
	vb.add_child(req)

	return vb

func _creator_player_name() -> String:
	var cfg := ConfigFile.new()
	if cfg.load("user://profile.cfg") == OK:
		var n := str(cfg.get_value("profile", "name", "")).strip_edges()
		if n != "":
			return n
	return "?"

func _on_creator_submit() -> void:
	if _creator_phase != 0:
		return
	var nm := ""
	if is_instance_valid(_creator_input):
		nm = _creator_input.text.strip_edges()
	if nm.length() < 3:
		if _creator_status:
			_creator_status.text = "Scrivi nome e canale."
		return
	settings.button_feedback()
	_creator_entry = nm
	if _creator_status:
		_creator_status.text = "Invio..."
	if _creator_btn:
		_creator_btn.disabled = true
	if _creator_http == null:
		_creator_http = HTTPRequest.new()
		add_child(_creator_http)
		_creator_http.request_completed.connect(_on_creator_http)
	_creator_phase = 1
	_creator_http.request(CREATOR_URL)

func _on_creator_http(_result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if _creator_phase == 1:
		var arr: Array = []
		var approved: Array = []
		if code == 200:
			var data: Variant = JSON.parse_string(body.get_string_from_utf8())
			if typeof(data) == TYPE_DICTIONARY:
				if data.has("creator_requests") and typeof(data["creator_requests"]) == TYPE_ARRAY:
					arr = data["creator_requests"]
				if data.has("creator_approved") and typeof(data["creator_approved"]) == TYPE_ARRAY:
					approved = data["creator_approved"]
		# invia anche il NOME PROFILO del giocatore, così l'admin può assegnare
		# l'icona esclusiva al giocatore giusto (non solo il testo del canale)
		arr.append({"player": _creator_player_name(), "info": _creator_entry})
		var payload := JSON.stringify({"creator_requests": arr, "creator_approved": approved})
		_creator_phase = 2
		var headers := PackedStringArray(["Content-Type: application/json"])
		_creator_http.request(CREATOR_URL, headers, HTTPClient.METHOD_POST, payload)
	elif _creator_phase == 2:
		_creator_phase = 0
		if code == 200 or code == 201:
			if _creator_input:
				_creator_input.release_focus()
				_creator_input.get_parent().visible = false
			if _creator_btn:
				_creator_btn.visible = false
			if _creator_status:
				_creator_status.text = "Richiesta inviata! Ti ricontatteremo ❤️"
				_creator_status.add_theme_font_override("font", _pixel_emoji_font())
		else:
			if _creator_status:
				_creator_status.text = "Errore di rete, riprova."
			if _creator_btn:
				_creator_btn.disabled = false

func _hide_subpages() -> void:
	for k in _subpages:
		_subpages[k].visible = false

func _make_subpage(title: String, content: Control, bg_tex: Texture2D = SUBPAGE_BG, back_tex: Texture2D = BACK_ICON) -> Control:
	var page := Control.new()
	page.set_anchors_preset(Control.PRESET_FULL_RECT)
	page.visible = false
	page.z_index = 50
	page.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(page)

	# sfondo dedicato a tutto schermo
	var bg := TextureRect.new()
	bg.texture = bg_tex
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page.add_child(bg)

	# shift camera: la home è sul canvas della Camera2D (si sposta su schermi alti);
	# così la freccia cade dove sta l'icona profilo della home.
	var vh := 1024.0
	var vw := 576.0
	var vp := get_viewport()
	if vp:
		vh = vp.get_visible_rect().size.y
		vw = vp.get_visible_rect().size.x   # larghezza reale (su iPad > 576)
	var cam_shift := maxf(0.0, vh * 0.5 - 512.0)

	# freccia indietro nella posizione dell'icona profilo della home
	var back := TextureButton.new()
	back.texture_normal = back_tex
	back.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	back.ignore_texture_size = true
	back.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	back.position = Vector2(24, 74 + cam_shift)
	back.size = Vector2(78, 78)
	back.pressed.connect(_on_subpage_back)
	page.add_child(back)

	# titolo: CENTRATO su tutta la larghezza (anche iPad) e alla stessa altezza della freccia.
	var lbl := Label.new()
	lbl.text = title
	lbl.position = Vector2(0, 74 + cam_shift)
	lbl.size = Vector2(vw, 78)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_override("font", FONT)
	lbl.add_theme_font_size_override("font_size", 50)
	lbl.add_theme_color_override("font_color", Color(1, 1, 1))
	lbl.add_theme_color_override("font_outline_color", Color(0, 0.06, 0.2))
	lbl.add_theme_constant_override("outline_size", 6)
	page.add_child(lbl)

	# contenuto CENTRATO orizzontalmente (blocco largo 528, centrato su vw) sotto il titolo
	var cy := 200.0 + cam_shift
	var content_w := 528.0
	content.position = Vector2((vw - content_w) * 0.5, cy)
	content.size = Vector2(content_w, maxf(300.0, vh - cy - 30.0))
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

# Applica uno stroke (outline) scuro al testo così resta leggibile sullo sfondo colorato.
func _add_stroke(l: Label, size: int = 8) -> void:
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("outline_size", size)

func _thanks_content() -> Control:
	# la pagina THANKS è scrollabile (i nomi saranno tanti)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	scroll.clip_contents = true
	_thanks_scroll = scroll

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 16)
	vb.size_flags_horizontal = Control.SIZE_FILL
	_thanks_vb = vb
	var cw := 528.0   # larghezza contenuto (pagina left_x=24)
	vb.custom_minimum_size = Vector2(cw, 0)
	scroll.add_child(vb)

	# ringraziamento speciale (inglese) a tutti gli iscritti al canale
	var msg := _make_text(
		"A special thank you to everyone subscribed to the channel who has supported this project since day one. You made Cube Crash possible. ❤️",
		Color(1, 1, 1), 30)
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.add_theme_font_override("font", _pixel_emoji_font())
	msg.custom_minimum_size = Vector2(cw, 0)
	_add_stroke(msg)
	vb.add_child(msg)

	# invito: vuoi il tuo nome qui? segui il canale
	var invite := _make_text(
		"Want your name here? Tap the button and follow me!",
		Color(1, 1, 1), 26)
	invite.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	invite.custom_minimum_size = Vector2(cw, 0)
	_add_stroke(invite)
	vb.add_child(invite)

	# ricompensa OG: tag [OG] + icona profilo esclusiva
	var og_reward := _make_text(
		"Once you're added to the OG list you unlock the [OG] tag next to your name and the exclusive OG profile icon! 👑",
		Color(1.0, 0.86, 0.2), 24)
	og_reward.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	og_reward.add_theme_font_override("font", _pixel_emoji_font())
	og_reward.custom_minimum_size = Vector2(cw, 0)
	_add_stroke(og_reward)
	vb.add_child(og_reward)

	# anteprima dell'icona OG esclusiva (per far vedere cosa si ottiene)
	var og_icon_wrap := CenterContainer.new()
	og_icon_wrap.custom_minimum_size = Vector2(cw, 172.0)
	var og_icon := TextureRect.new()
	og_icon.texture = load("res://CORE/Assets/Art/Home/Profile/profile_og.png")
	og_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	og_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	og_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	og_icon.custom_minimum_size = Vector2(160.0, 160.0)
	og_icon_wrap.add_child(og_icon)
	vb.add_child(og_icon_wrap)

	# modulo "manda il tuo nome" (SOPRA il follow, nascosto finché non premi FOLLOW ME)
	vb.add_child(_build_submit_form(cw))

	# spazio sopra il tasto follow
	var top_gap := Control.new()
	top_gap.custom_minimum_size = Vector2(cw, 20)
	top_gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(top_gap)

	# tasto FOLLOW ME (immagine) -> apre il canale. Wrapper per il saltellio.
	var follow_wrap := Control.new()
	follow_wrap.custom_minimum_size = Vector2(cw, 128)
	follow_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var follow := TextureButton.new()
	follow.texture_normal = FOLLOW_ME
	follow.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	follow.ignore_texture_size = true
	follow.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	follow.size = Vector2(cw, 128)   # aspect 1472:576 -> ~328x128 centrato
	follow.pressed.connect(func() -> void:
		settings.button_feedback()
		OS.shell_open(CHANNEL_URL)
		# il modulo "manda il tuo nome" appare 2s dopo aver premuto FOLLOW ME
		_reveal_submit_after_delay())
	# mini animazione di pressione (affonda + vibra)
	follow.button_down.connect(func() -> void:
		follow.position.y += 5.0
		settings.vibrate(15))
	follow.button_up.connect(func() -> void:
		follow.position.y -= 5.0)
	follow_wrap.add_child(follow)
	vb.add_child(follow_wrap)
	# saltellio continuo del tasto (avviato quando è nell'albero)
	follow.ready.connect(func() -> void: _bounce_follow(follow))
	if follow.is_inside_tree():
		_bounce_follow(follow)

	# spazio extra tra il tasto e l'elenco dei nomi
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(cw, 44)
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(spacer)

	# "OG SUPPORTERS" in oro pixel con stroke nero + luccichio (luminosità)
	var og := _make_text("OG SUPPORTERS", Color(1.0, 0.86, 0.25), 34)
	og.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	og.custom_minimum_size = Vector2(cw, 0)
	_add_stroke(og)   # stroke nero
	vb.add_child(og)
	# luccichio: pulsazione continua della luminosità/alone
	og.ready.connect(func() -> void: _shine_gold(og))
	if og.is_inside_tree():
		_shine_gold(og)

	var names := _make_text(SUPPORTERS_DEFAULT, Color(1, 1, 1), 28)
	names.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	names.custom_minimum_size = Vector2(cw, 0)
	names.add_theme_constant_override("line_spacing", 6)
	_add_stroke(names)
	vb.add_child(names)
	_supporters_label = names

	# spazio in fondo per scrollare comodamente
	var bottom_gap := Control.new()
	bottom_gap.custom_minimum_size = Vector2(cw, 60)
	bottom_gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(bottom_gap)

	return scroll

# Scarica la lista OG SUPPORTERS da remoto (npoint) e aggiorna la label.
# Editabile dal telefono: https://www.npoint.io/docs/c0e50f85707a48094b11
# Se offline / errore, resta la lista di default già mostrata.
func _fetch_supporters() -> void:
	if _supporters_http == null:
		_supporters_http = HTTPRequest.new()
		add_child(_supporters_http)
		_supporters_http.request_completed.connect(_on_supporters_fetched)
	# evita richieste sovrapposte
	if _supporters_http.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		return
	_supporters_http.request(SUPPORTERS_URL)

func _on_supporters_fetched(_result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if code != 200:
		return
	var data: Variant = JSON.parse_string(body.get_string_from_utf8())
	if typeof(data) != TYPE_DICTIONARY or not data.has("og_supporters"):
		return
	var arr: Array = data["og_supporters"]
	var clean: Array = []
	for n in arr:
		var s := str(n).strip_edges()
		if s != "":
			clean.append(s)
	if clean.is_empty():
		return
	if is_instance_valid(_supporters_label):
		_supporters_label.text = ", ".join(clean)

# --- Modulo "manda il tuo nome" -------------------------------------------------
func _build_submit_form(cw: float) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	box.custom_minimum_size = Vector2(cw, 0)
	box.visible = false   # appare 3s dopo FOLLOW ME

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(cw, 24)
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(spacer)

	var q := _make_text("To be added we'll verify that you follow us.\nSend your name:", Color(1, 1, 1), 26)
	q.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	q.custom_minimum_size = Vector2(cw, 0)
	_add_stroke(q)
	box.add_child(q)

	# campo nome dentro il box-immagine
	var box_h := cw * 322.0 / 2693.0   # aspect del box
	var name_wrap := Control.new()
	name_wrap.custom_minimum_size = Vector2(cw, box_h)
	var nb := TextureRect.new()
	nb.texture = NAME_BOX
	nb.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	nb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	nb.stretch_mode = TextureRect.STRETCH_SCALE
	nb.set_anchors_preset(Control.PRESET_FULL_RECT)
	nb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_wrap.add_child(nb)
	var inp := LineEdit.new()
	inp.placeholder_text = "Your name (or @instagram)"
	inp.max_length = 30
	inp.alignment = HORIZONTAL_ALIGNMENT_CENTER
	inp.set_anchors_preset(Control.PRESET_FULL_RECT)
	inp.offset_left = 22
	inp.offset_right = -22
	inp.offset_top = 4
	inp.offset_bottom = -4
	inp.add_theme_font_override("font", FONT)
	inp.add_theme_font_size_override("font_size", 30)
	inp.add_theme_color_override("font_color", Color(0.1, 0.05, 0.12))
	inp.add_theme_color_override("font_placeholder_color", Color(0.4, 0.4, 0.45))
	inp.add_theme_color_override("caret_color", Color(0.1, 0.05, 0.12))
	var empty := StyleBoxEmpty.new()
	inp.add_theme_stylebox_override("normal", empty)
	inp.add_theme_stylebox_override("focus", empty)
	inp.focus_entered.connect(_on_name_focus_in)
	inp.focus_exited.connect(_on_name_focus_out)
	name_wrap.add_child(inp)
	box.add_child(name_wrap)
	_name_input = inp

	# tasto SEND (immagine)
	var send_h := cw * 299.0 / 2735.0   # aspect del tasto
	var send := TextureButton.new()
	send.texture_normal = SEND_BTN
	send.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	send.ignore_texture_size = true
	send.stretch_mode = TextureButton.STRETCH_SCALE
	send.custom_minimum_size = Vector2(cw, send_h)
	send.button_down.connect(func() -> void: send.modulate = Color(0.9, 0.9, 0.9))
	send.button_up.connect(func() -> void: send.modulate = Color(1, 1, 1))
	send.pressed.connect(_on_submit_name)
	box.add_child(send)
	_submit_btn = send

	# esito
	var status := _make_text("", Color(1, 1, 1), 24)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.custom_minimum_size = Vector2(cw, 0)
	_add_stroke(status)
	box.add_child(status)
	_submit_status = status

	_submit_box = box
	return box

# Mostra il box mezzo secondo dopo aver premuto FOLLOW ME.
func _reveal_submit_after_delay() -> void:
	if _submit_box == null or _submit_box.visible:
		return
	await get_tree().create_timer(0.5).timeout
	if _submit_box:
		_submit_box.visible = true

# Quando il campo nome prende il focus, porto il modulo in cima all'area scroll
# (così resta in alto, sopra la tastiera, senza tagliare nulla).
func _on_name_focus_in() -> void:
	if _thanks_scroll == null or _submit_box == null:
		return
	await get_tree().process_frame   # attende il layout
	if is_instance_valid(_thanks_scroll) and is_instance_valid(_submit_box):
		var target := int(maxf(0.0, _submit_box.position.y - 8.0))
		_thanks_scroll.scroll_vertical = target

func _on_name_focus_out() -> void:
	pass

func _on_submit_name() -> void:
	if _submit_phase != 0:
		return   # invio già in corso
	var nm := ""
	if is_instance_valid(_name_input):
		nm = _name_input.text.strip_edges()
	if nm.length() < 2:
		if _submit_status:
			_submit_status.text = "Please enter your name."
		return
	settings.button_feedback()
	_submit_entry = nm
	if _submit_status:
		_submit_status.text = "Sending..."
	if _submit_btn:
		_submit_btn.disabled = true
	if _submit_http == null:
		_submit_http = HTTPRequest.new()
		add_child(_submit_http)
		_submit_http.request_completed.connect(_on_submit_http)
	# leggo la lista attuale, poi aggiungo (read-modify-write)
	_submit_phase = 1
	_submit_http.request(PENDING_URL)

func _on_submit_http(_result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if _submit_phase == 1:
		# fase GET: prendo la lista, aggiungo la nuova proposta, poi POST
		var arr: Array = []
		if code == 200:
			var data: Variant = JSON.parse_string(body.get_string_from_utf8())
			if typeof(data) == TYPE_DICTIONARY and data.has("pending") and typeof(data["pending"]) == TYPE_ARRAY:
				arr = data["pending"]
		arr.append(_submit_entry)
		var payload := JSON.stringify({"pending": arr})
		_submit_phase = 2
		var headers := PackedStringArray(["Content-Type: application/json"])
		_submit_http.request(PENDING_URL, headers, HTTPClient.METHOD_POST, payload)
	elif _submit_phase == 2:
		# fase POST: esito finale
		_submit_phase = 0
		if code == 200 or code == 201:
			# chiudo la tastiera e nascondo tutto il modulo tranne il "grazie",
			# così la sezione non resta a ingombrare la pagina.
			if _name_input:
				_name_input.release_focus()
				_name_input.get_parent().visible = false   # nasconde box nome
			if _submit_btn:
				_submit_btn.visible = false
			if _submit_status:
				_submit_status.text = "Thanks! We've added you ❤️"
				_submit_status.add_theme_font_override("font", _pixel_emoji_font())
			# dopo 2.5s sparisce l'intera sezione
			get_tree().create_timer(2.5).timeout.connect(func() -> void:
				if is_instance_valid(_submit_box):
					_submit_box.visible = false)
		else:
			_submit_phase = 0
			if _submit_status:
				_submit_status.text = "Network error, try again."
			if _submit_btn:
				_submit_btn.disabled = false

# Saltellio continuo del tasto FOLLOW ME (su e giù, in loop).
func _bounce_follow(btn: Control) -> void:
	if not is_instance_valid(btn):
		return
	var base_y := btn.position.y
	var t := btn.create_tween().set_loops()
	t.tween_property(btn, "position:y", base_y - 12.0, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_property(btn, "position:y", base_y, 0.55).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

# Luccichio dorato: pulsazione continua di luminosità + alone brillante.
func _shine_gold(l: Label) -> void:
	if not is_instance_valid(l):
		return
	var t := l.create_tween().set_loops()
	t.tween_method(_apply_gold_shine.bind(l), 0.0, 1.0, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_method(_apply_gold_shine.bind(l), 1.0, 0.0, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _apply_gold_shine(k: float, l: Label) -> void:
	if not is_instance_valid(l):
		return
	# solo luminosità (luccichio): lo stroke resta nero
	l.modulate = Color(1, 1, 1).lerp(Color(1.5, 1.35, 0.8), k)

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
