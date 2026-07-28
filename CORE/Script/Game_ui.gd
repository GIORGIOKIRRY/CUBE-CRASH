extends Control

@onready var SettingsMenu = %SettingsMenu
signal MenuOpen

const MODE_FONT := preload("res://CORE/Assets/Font/Jersey10-Regular.ttf")

var _exit_popup: Control = null

func _ready() -> void:
	SettingsMenu.visible = false

func _on_back_button_pressed() -> void:
	settings.button_feedback()
	_show_exit_confirm()

func _on_settings_button_pressed() -> void:
	settings.button_feedback()
	SettingsMenu.visible = true
	MenuOpen.emit()


# --- Popup conferma uscita dalla partita ---------------------------------------
func _show_exit_confirm() -> void:
	if _exit_popup != null and is_instance_valid(_exit_popup):
		_exit_popup.visible = true
	else:
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
	root.add_child(dim)

	var panel := ColorRect.new()
	panel.color = Color(0.11, 0.21, 0.33, 1.0)
	panel.offset_left = 64.0
	panel.offset_top = 372.0
	panel.offset_right = 512.0
	panel.offset_bottom = 652.0
	root.add_child(panel)

	var title := Label.new()
	title.text = "USCIRE DALLA PARTITA?"
	title.add_theme_font_override("font", MODE_FONT)
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Color(1, 1, 1))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.offset_left = 84.0
	title.offset_top = 392.0
	title.offset_right = 492.0
	title.offset_bottom = 486.0
	root.add_child(title)

	var sub := Label.new()
	sub.text = "Ci sono ancora mosse possibili!"
	sub.add_theme_font_override("font", MODE_FONT)
	sub.add_theme_font_size_override("font_size", 24)
	sub.add_theme_color_override("font_color", Color(1, 1, 1, 0.8))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.offset_left = 84.0
	sub.offset_top = 490.0
	sub.offset_right = 492.0
	sub.offset_bottom = 524.0
	root.add_child(sub)

	var stay := _mk_popup_button("RESTA", Color(0.25, 0.60, 0.35))
	stay.offset_left = 84.0
	stay.offset_top = 556.0
	stay.offset_right = 282.0
	stay.offset_bottom = 626.0
	stay.pressed.connect(_on_exit_cancel)
	root.add_child(stay)

	var quit := _mk_popup_button("ESCI", Color(0.78, 0.26, 0.26))
	quit.offset_left = 294.0
	quit.offset_top = 556.0
	quit.offset_right = 492.0
	quit.offset_bottom = 626.0
	quit.pressed.connect(_on_exit_confirm)
	root.add_child(quit)

	return root

func _mk_popup_button(txt: String, col: Color) -> Button:
	var b := Button.new()
	b.text = txt
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_override("font", MODE_FONT)
	b.add_theme_font_size_override("font_size", 34)
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.set_corner_radius_all(14)
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", sb)
	var sbp := sb.duplicate()
	sbp.bg_color = col.darkened(0.2)
	b.add_theme_stylebox_override("pressed", sbp)
	return b

func _on_exit_cancel() -> void:
	get_tree().paused = false
	settings.button_feedback()
	if _exit_popup != null and is_instance_valid(_exit_popup):
		_exit_popup.visible = false

func _on_exit_confirm() -> void:
	get_tree().paused = false
	settings.button_feedback()
	transition.change_scene("res://CORE/Scene/MainMenu.tscn")
