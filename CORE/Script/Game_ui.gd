extends Control

@onready var SettingsMenu = %SettingsMenu
signal MenuOpen

const MODE_FONT := preload("res://CORE/Assets/Font/Jersey10-Regular.ttf")

var _exit_popup: Control = null

func _ready() -> void:
	SettingsMenu.visible = false
	# tasti UI di gioco: animazione verso il basso + vibrazione alla pressione
	_press_fx(get_node_or_null("BackButton"))
	_press_fx(get_node_or_null("SettingsButton"))

func _press_fx(b: BaseButton) -> void:
	if b == null:
		return
	b.button_down.connect(func() -> void:
		b.position.y += 5.0
		settings.vibrate(15))
	b.button_up.connect(func() -> void:
		b.position.y -= 5.0)

func _on_back_button_pressed() -> void:
	settings.button_feedback()
	_show_exit_confirm()

func _on_settings_button_pressed() -> void:
	settings.button_feedback()
	SettingsMenu.visible = true
	MenuOpen.emit()


# --- Popup conferma uscita dalla partita ---------------------------------------
func _show_exit_confirm() -> void:
	# ricostruisci ogni volta (punteggio aggiornato)
	if _exit_popup != null and is_instance_valid(_exit_popup):
		_exit_popup.queue_free()
	_exit_popup = _build_exit_popup()
	add_child(_exit_popup)
	# mette in pausa il gioco (così in speedrun il timer non scorre mentre decidi)
	get_tree().paused = true

func _build_exit_popup() -> Control:
	var root := Control.new()
	root.z_index = 2000
	root.process_mode = Node.PROCESS_MODE_ALWAYS   # funziona anche a gioco in pausa
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.7)
	dim.offset_left = -400.0
	dim.offset_top = -400.0
	dim.offset_right = 1000.0
	dim.offset_bottom = 1600.0
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	# tap FUORI dal frame -> torna al gameplay
	dim.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed:
			_on_exit_cancel())
	root.add_child(dim)

	# frame (2496x1984 -> box scura interna a y 0.274..0.661)
	var FL := 28.0
	var FT := 306.0
	var FW := 520.0
	var FH := 413.0
	var frame := TextureRect.new()
	frame.texture = load("res://CORE/Assets/Art/UI/Game/exit_frame.png")
	frame.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame.stretch_mode = TextureRect.STRETCH_SCALE
	frame.mouse_filter = Control.MOUSE_FILTER_STOP   # i tap sul frame NON tornano al gameplay
	frame.position = Vector2(FL, FT)
	frame.size = Vector2(FW, FH)
	root.add_child(frame)

	# titolo (più grande + stroke maggiore) + sottotitolo (inglese)
	var title_lbl := _popup_label("EXIT GAME?", 52, Color(1, 1, 1), Vector2(FL, FT + 18.0), Vector2(FW, 54.0), true)
	title_lbl.add_theme_constant_override("outline_size", 11)
	root.add_child(title_lbl)
	root.add_child(_popup_label("You still have moves available!", 22, Color(1, 1, 1, 0.92), Vector2(FL + 16.0, FT + 80.0), Vector2(FW - 32.0, 30.0), false))

	# punteggio grande nella box scura del frame
	var sc_val := 0
	var g := get_node_or_null("../grid")
	if g:
		var sv = g.get("score")
		if sv != null:
			sc_val = int(sv)
	var box_top := FT + 0.274 * FH
	var box_h := (0.661 - 0.274) * FH
	# etichetta SCORE più in basso, subito sopra il numero
	root.add_child(_popup_label("SCORE", 24, Color(0.72, 0.87, 1.0), Vector2(FL, box_top + 6.0), Vector2(FW, 24.0), false))
	root.add_child(_popup_label(str(sc_val), 80, Color(1, 1, 1), Vector2(FL, box_top + 36.0), Vector2(FW, box_h - 44.0), true))

	# tasti: END RUN (rosso, esci) a sx, RESUME (verde, riprendi) a dx
	var btn_w := 210.0
	var btn_h := 82.0
	var btn_y := FT + FH - 118.0
	var gap := 24.0
	var cx := FL + FW * 0.5
	root.add_child(_popup_texbtn("res://CORE/Assets/Art/UI/Game/btn_end_run.png", Vector2(cx - gap * 0.5 - btn_w, btn_y), Vector2(btn_w, btn_h), _on_exit_confirm))
	root.add_child(_popup_texbtn("res://CORE/Assets/Art/UI/Game/btn_resume.png", Vector2(cx + gap * 0.5, btn_y), Vector2(btn_w, btn_h), _on_exit_cancel))

	return root

func _popup_label(txt: String, size: int, col: Color, pos: Vector2, sz: Vector2, outline: bool) -> Label:
	var l := Label.new()
	l.text = txt
	l.add_theme_font_override("font", MODE_FONT)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	if outline:
		l.add_theme_color_override("font_outline_color", Color(0, 0, 0))
		l.add_theme_constant_override("outline_size", 6)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.position = pos
	l.size = sz
	return l

func _popup_texbtn(tex_path: String, pos: Vector2, sz: Vector2, cb: Callable) -> TextureButton:
	var b := TextureButton.new()
	b.texture_normal = load(tex_path)
	b.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	b.ignore_texture_size = true
	b.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	b.position = pos
	b.size = sz
	b.pressed.connect(cb)
	_press_fx(b)
	return b

func _on_exit_cancel() -> void:
	get_tree().paused = false
	settings.button_feedback()
	if _exit_popup != null and is_instance_valid(_exit_popup):
		_exit_popup.queue_free()
		_exit_popup = null

func _on_exit_confirm() -> void:
	get_tree().paused = false
	settings.button_feedback()
	transition.change_scene("res://CORE/Scene/MainMenu.tscn")
