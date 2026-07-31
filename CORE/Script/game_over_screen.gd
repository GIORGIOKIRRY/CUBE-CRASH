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


var _end_final := 0
var _end_moves := 0
var _end_per := 0

# Bonus di fine partita: mosse rimaste -> punteggio (con animazione)
func set_end_bonus(final_score: int, moves: int, per_move: int) -> void:
	_end_final = final_score
	_end_moves = moves
	_end_per = per_move


# Speedrun: titolo "SPEEDRUN" e riga record dedicato (RECORD / NUOVO RECORD!)
func set_speedrun_mode(record: int, is_record: bool) -> void:
	# speedrun: sfondo rosso (come il gameplay) + X rossa
	$Items/BG.color = Color(147.0 / 255.0, 32.0 / 255.0, 20.0 / 255.0, 1.0)
	if has_node("Items/CloseButton"):
		$Items/CloseButton.texture_normal = load("res://CORE/Assets/Art/UI/Game/exit_x_red.png")
	var title := get_node_or_null("Items/L_GameOver") as Label
	if title:
		title.text = "SPEEDRUN"
	var best_lbl := get_node_or_null("Items/BestScore") as Label
	if best_lbl:
		best_lbl.text = "NUOVO RECORD!" if is_record else "RECORD"
		best_lbl.visible = true
	var best_num := get_node_or_null("Items/L_BestScoreNumber") as Label
	if best_num:
		best_num.text = str(record)
		best_num.visible = true


# Mostra la schermata di fine partita.
# Se is_new_record == true usa il layout viola "BEST SCORE!" (tutto centrato).
func show_result(is_new_record: bool) -> void:
	# rimuovi il tasto condividi; usa la nuova X per chiudere
	if has_node("Items/LinkButton"):
		$Items/LinkButton.visible = false
	if has_node("Items/CloseButton"):
		var cb: TextureButton = $Items/CloseButton
		cb.texture_normal = load("res://CORE/Assets/Art/UI/Game/exit_x.png")
		cb.ignore_texture_size = true
		cb.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	if is_new_record:
		_apply_new_record_layout()
	visible = true
	_play_end_bonus_anim()   # dopo il layout: anima le mosse rimaste in punteggio


func _play_end_bonus_anim() -> void:
	var num := get_node_or_null("Items/L_ScoreNumber") as Label
	if num == null or _end_moves <= 0:
		return
	var base := _end_final - _end_moves * _end_per
	num.text = str(base)
	# popup verde: "+2700 (27 mosse)" sopra il numero, dove sta lo score in questo layout
	var pop := Label.new()
	pop.name = "EndBonus"
	pop.add_theme_font_override("font", STATS_FONT)
	pop.add_theme_font_size_override("font_size", 34)
	pop.add_theme_color_override("font_color", Color(0.25, 0.85, 0.35))
	pop.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pop.offset_left = -260.0
	pop.offset_right = 300.0
	pop.offset_top = num.offset_top - 46.0
	pop.offset_bottom = num.offset_top - 8.0
	$Items.add_child(pop)
	pop.text = "+%d  (%d mosse)" % [_end_moves * _end_per, _end_moves]
	pop.modulate.a = 0.0
	# breve attesa, poi conta su lo score e fai salire/sfumare il popup
	await get_tree().create_timer(0.55).timeout
	settings.play_newmove()
	var tw := create_tween()
	tw.tween_method(_set_score_text, float(base), float(_end_final), 1.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	var tp := create_tween()
	tp.tween_property(pop, "modulate:a", 1.0, 0.2)
	tp.tween_interval(0.9)
	tp.parallel().tween_property(pop, "position:y", pop.position.y - 26.0, 0.5)
	tp.parallel().tween_property(pop, "modulate:a", 0.0, 0.5)
	tp.tween_callback(pop.queue_free)

func _set_score_text(v: float) -> void:
	var num := get_node_or_null("Items/L_ScoreNumber") as Label
	if num:
		num.text = str(int(round(v)))


func _apply_new_record_layout() -> void:
	# Sfondo viola (il BG è grande abbastanza da coprire tutto lo schermo, anche l'overscan)
	$Items/BG.color = RECORD_PURPLE

	# (share rimosso; la X resta quella nuova impostata in show_result)

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
	transition.change_scene("res://CORE/Scene/MainMenu.tscn")


func _on_play_again_button_pressed() -> void:
	settings.button_feedback()
	transition.change_scene("res://CORE/Scene/game.tscn")


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
