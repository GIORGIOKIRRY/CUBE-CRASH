extends Control

# Colori schermata "nuovo record"
const RECORD_PURPLE := Color(0.478431, 0.270588, 0.815686)  # sfondo viola
const RECORD_YELLOW := Color(0.980392, 0.788235, 0.098039)  # "BEST SCORE!"
const RECORD_LAVENDER := Color(0.850980, 0.619608, 1.0)     # etichetta "SCORE"
const PLAY_AGAIN_GOLD := preload("res://CORE/Assets/Art/UI/GameOver/PlayAgainGold.svg")
const LINK_PURPLE := preload("res://CORE/Assets/Art/UI/Menu/LinkPurple.svg")
const CLOSE_PURPLE := preload("res://CORE/Assets/Art/UI/Menu/ClosePurple.svg")


const STATS_FONT := preload("res://CORE/Assets/Font/Jersey10-Regular.ttf")

# Riga statistiche partita (temporanea, per calibrare la durata)
func set_session_stats(txt: String) -> void:
	var lbl := get_node_or_null("Items/SessionStats") as Label
	if lbl == null:
		lbl = Label.new()
		lbl.name = "SessionStats"
		lbl.add_theme_font_override("font", STATS_FONT)
		lbl.add_theme_font_size_override("font_size", 26)
		lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.75))
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.offset_left = -240.0
		lbl.offset_right = 280.0
		lbl.offset_top = 418.0
		lbl.offset_bottom = 452.0
		$Items.add_child(lbl)
	lbl.text = txt


# Mostra la schermata di fine partita.
# Se is_new_record == true usa il layout viola "BEST SCORE!" (tutto centrato).
func show_result(is_new_record: bool) -> void:
	if is_new_record:
		_apply_new_record_layout()
	visible = true


func _apply_new_record_layout() -> void:
	# Sfondo viola (il BG è grande abbastanza da coprire tutto lo schermo, anche l'overscan)
	$Items/BG.color = RECORD_PURPLE

	# Tastini share (link) e X in viola scuro invece del blu profondo
	$Items/LinkButton.texture_normal = LINK_PURPLE
	$Items/CloseButton.texture_normal = CLOSE_PURPLE

	# Titolo -> "BEST SCORE!" giallo, centrato
	var title: Label = $Items/L_GameOver
	title.text = "BEST SCORE!"
	title.add_theme_color_override("font_color", RECORD_YELLOW)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.offset_left = -290.0
	title.offset_right = 330.0
	# (verticale invariato: resta in alto come nel mockup)

	# Etichetta "SCORE" -> lavanda, centrata, spostata al centro schermo
	var score_lbl: Label = $Items/Score
	score_lbl.add_theme_color_override("font_color", RECORD_LAVENDER)
	score_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_lbl.offset_left = -130.0
	score_lbl.offset_right = 170.0
	score_lbl.offset_top = -45.0
	score_lbl.offset_bottom = -3.0

	# Numero punteggio -> bianco, centrato
	var num: Label = $Items/L_ScoreNumber
	num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	num.offset_left = -240.0
	num.offset_right = 280.0
	num.offset_top = -33.0
	num.offset_bottom = 105.0

	# In modalità record mostriamo un solo punteggio: nascondi la riga "BEST SCORE"
	$Items/BestScore.visible = false
	$Items/L_BestScoreNumber.visible = false

	# Play Again dorato (solo nel record) e centrato orizzontalmente (texture 474x120)
	var play: TextureButton = $Items/PlayAgainButton
	play.texture_normal = PLAY_AGAIN_GOLD
	play.offset_left = -217.0
	play.offset_right = 257.0
	play.offset_top = 260.0
	play.offset_bottom = 380.0


func _on_close_button_pressed() -> void:
	settings.button_feedback()
	get_tree().change_scene_to_file("res://CORE/Scene/MainMenu.tscn")


func _on_play_again_button_pressed() -> void:
	settings.button_feedback()
	get_tree().change_scene_to_file("res://CORE/Scene/game.tscn")


# Pulsante in alto a sinistra: cattura uno screenshot del punteggio e lo condivide.
func _on_link_button_pressed() -> void:
	settings.button_feedback()
	_share_score_screenshot()


func _share_score_screenshot() -> void:
	# cattura il frame renderizzato (include la schermata di game over col punteggio)
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var path := "user://cubecrash_score.png"
	img.save_png(path)
	# Apre la condivisione: su iOS la condivisione nativa (UIActivityViewController)
	# richiede un plugin nativo; qui salviamo il PNG e ne apriamo il percorso.
	OS.shell_open(ProjectSettings.globalize_path(path))
