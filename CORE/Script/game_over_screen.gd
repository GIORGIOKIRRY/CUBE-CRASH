extends Control

# Colori schermata "nuovo record"
const RECORD_PURPLE := Color(0.478431, 0.270588, 0.815686)  # sfondo viola
const RECORD_YELLOW := Color(0.980392, 0.788235, 0.098039)  # "BEST SCORE!"
const RECORD_LAVENDER := Color(0.850980, 0.619608, 1.0)     # etichetta "SCORE"
const PLAY_AGAIN_GOLD := preload("res://CORE/Assets/Art/UI/GameOver/PlayAgainGold.svg")
const LINK_PURPLE := preload("res://CORE/Assets/Art/UI/Menu/LinkPurple.svg")
const CLOSE_PURPLE := preload("res://CORE/Assets/Art/UI/Menu/ClosePurple.svg")

# Tasti "gioca ancora" per stato + X viola del nuovo record
const PLAY_AGAIN_TEX := preload("res://CORE/Assets/Art/UI/GameOver/play_again_r.png")
const PLAY_AGAIN_RECORD_TEX := preload("res://CORE/Assets/Art/UI/GameOver/play_again_record_r.png")
const REVIVE_TEX := preload("res://CORE/Assets/Art/UI/GameOver/revive_r.png")
const X_NEWRECORD_TEX := preload("res://CORE/Assets/Art/UI/GameOver/x_newrecord.png")


# Imposta la texture del tasto "gioca ancora"/revive mantenendone l'aspect (1472:576)
func _set_play_texture(tex: Texture2D) -> void:
	var play: TextureButton = $Items/PlayAgainButton
	play.texture_normal = tex
	play.ignore_texture_size = true
	play.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	play.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# piccolo, centrato sul centro schermo (Items ha origine x=268; +20 = 288) e alzato
	play.offset_left = -148.0
	play.offset_right = 188.0
	play.offset_top = 246.0
	play.offset_bottom = 377.0   # w=336 h=131 -> aspect 2.56


const STATS_FONT := preload("res://CORE/Assets/Font/Jersey10-Regular.ttf")


func _ready() -> void:
	# tutti i tasti UI: piccola animazione verso il basso + vibrazione alla pressione
	_press_fx(get_node_or_null("Items/PlayAgainButton"))
	_press_fx(get_node_or_null("Items/CloseButton"))

# Feedback pressione riutilizzabile per un tasto UI (affonda + vibra)
func _press_fx(b: BaseButton) -> void:
	if b == null:
		return
	b.button_down.connect(func() -> void:
		b.position.y += 5.0
		settings.vibrate(15))
	b.button_up.connect(func() -> void:
		b.position.y -= 5.0)

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
	# nuovo record anche in speedrun -> TUTTO lo stile viola (già applicato da show_result
	# tramite _apply_new_record_layout): non sovrascrivere col rosso.
	if is_record:
		return
	# speedrun senza record: sfondo rosso (come il gameplay) + X rossa + PLAY AGAIN (come mode 1)
	# (il tasto REVIVE è riservato al caso "revive col timer di 5s")
	$Items/BG.color = Color(147.0 / 255.0, 32.0 / 255.0, 20.0 / 255.0, 1.0)
	if has_node("Items/CloseButton"):
		$Items/CloseButton.texture_normal = load("res://CORE/Assets/Art/UI/Game/exit_x_red.png")
	_set_play_texture(PLAY_AGAIN_TEX)
	var light_red := Color(1.0, 0.5, 0.45)   # "SCORE"/"RECORD" rosso chiaro
	var title := get_node_or_null("Items/L_GameOver") as Label
	if title:
		title.text = "SPEEDRUN"
	var best_lbl := get_node_or_null("Items/BestScore") as Label
	if best_lbl:
		best_lbl.text = "NUOVO RECORD!" if is_record else "RECORD"
		best_lbl.visible = true
		best_lbl.add_theme_color_override("font_color", light_red)
	var best_num := get_node_or_null("Items/L_BestScoreNumber") as Label
	if best_num:
		best_num.text = str(record)
		best_num.visible = true
		best_num.add_theme_color_override("font_color", Color(1, 1, 1))   # numero bianco
	# "SCORE" rosso chiaro, numero bianco
	var score_lbl := get_node_or_null("Items/Score") as Label
	if score_lbl:
		score_lbl.add_theme_color_override("font_color", light_red)
	var score_num := get_node_or_null("Items/L_ScoreNumber") as Label
	if score_num:
		score_num.add_theme_color_override("font_color", Color(1, 1, 1))   # numero bianco


# Schermata REVIVE con countdown di 5s (speedrun): sfondo rosso, tasto REVIVE verde,
# X rossa per rinunciare, grande conto alla rovescia al centro.
func set_revive_mode(seconds: int = 5) -> void:
	visible = true
	$Items/BG.color = Color(147.0 / 255.0, 32.0 / 255.0, 20.0 / 255.0, 1.0)
	if has_node("Items/LinkButton"):
		$Items/LinkButton.visible = false
	if has_node("Items/CloseButton"):
		var cb: TextureButton = $Items/CloseButton
		cb.texture_normal = load("res://CORE/Assets/Art/UI/Game/exit_x_red.png")
		cb.ignore_texture_size = true
		cb.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	_set_play_texture(REVIVE_TEX)
	# nascondi le righe punteggio: qui conta solo il revive
	for n in ["Score", "BestScore", "L_ScoreNumber", "L_BestScoreNumber"]:
		var x := get_node_or_null("Items/" + n) as CanvasItem
		if x:
			x.visible = false
	var title := get_node_or_null("Items/L_GameOver") as Label
	if title:
		title.text = "CONTINUA?"
		title.add_theme_color_override("font_color", Color(1, 1, 1))
		title.add_theme_color_override("font_outline_color", Color(0, 0, 0))
		title.add_theme_constant_override("outline_size", 8)
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.offset_left = -290.0
		title.offset_right = 330.0
	# sottotitolo: guarda una pubblicità per riprendere
	var sub := get_node_or_null("Items/ReviveSub") as Label
	if sub == null:
		sub = Label.new()
		sub.name = "ReviveSub"
		sub.add_theme_font_override("font", STATS_FONT)
		sub.add_theme_font_size_override("font_size", 30)
		sub.add_theme_color_override("font_color", Color(1, 1, 1))
		sub.add_theme_color_override("font_outline_color", Color(0, 0, 0))
		sub.add_theme_constant_override("outline_size", 6)
		sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		sub.offset_left = -250.0
		sub.offset_right = 290.0
		sub.offset_top = 150.0
		sub.offset_bottom = 240.0
		$Items.add_child(sub)
	sub.text = "Guarda una pubblicità\nper riprendere la partita"
	sub.visible = true


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
		# NB: i coriandoli partono da grid.gd DOPO la chiusura dell'adv (play_confetti())
	else:
		# sconfitta normale: stesso sfondo del gameplay (classic = blu #00478E) + tasto
		# "gioca ancora". In speedrun set_speedrun_mode() sovrascrive con rosso + PLAY AGAIN.
		$Items/BG.color = Color(0.0, 71.0 / 255.0, 142.0 / 255.0, 1.0)
		_set_play_texture(PLAY_AGAIN_TEX)
		# "SCORE" / "BEST SCORE" in azzurro chiaro
		var light_blue := Color(0.55, 0.82, 1.0)
		var s_lbl := get_node_or_null("Items/Score") as Label
		if s_lbl:
			s_lbl.add_theme_color_override("font_color", light_blue)
		var bs_lbl := get_node_or_null("Items/BestScore") as Label
		if bs_lbl:
			bs_lbl.add_theme_color_override("font_color", light_blue)
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

	# share rimosso; la X del nuovo record usa l'icona viola dedicata
	if has_node("Items/CloseButton"):
		$Items/CloseButton.texture_normal = X_NEWRECORD_TEX

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

	# Play Again "nuovo record" (centrato, aspect mantenuto)
	_set_play_texture(PLAY_AGAIN_RECORD_TEX)


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


# --- Coriandoli PIXELATI che scendono dall'alto (schermata nuovo record) --------
var _confetti_done := false
func play_confetti() -> void:
	if _confetti_done:
		return
	_confetti_done = true
	# contenitore dietro al testo (dopo il BG dentro Items)
	var cont := Control.new()
	cont.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$Items.add_child(cont)
	$Items.move_child(cont, 1)   # subito dopo BG -> dietro il punteggio/testo
	var cols := [
		Color(1.0, 0.86, 0.15), Color(1.0, 0.35, 0.45), Color(0.35, 0.8, 1.0),
		Color(0.45, 1.0, 0.45), Color(1.0, 0.55, 0.9), Color(1.0, 0.6, 0.12),
		Color(1.0, 1.0, 1.0),
	]
	# 110 coriandoli, con ritardi fino a ~7s: pioggia LUNGA (~10s totali)
	# NB: partono BEN sopra il bordo alto (fuori schermo su ogni dispositivo) e con
	# altezza di partenza sfalsata, così non si vedono mai "fermi" in alto durante il
	# ritardo — su schermi molto alti l'area sopra y=0 è visibile con lo stretch "expand".
	var END_Y := 820.0    # sotto il bordo basso su ogni dispositivo (Items è centrato)
	for i in 110:
		var c := ColorRect.new()
		c.color = cols[i % cols.size()]
		var sz := roundf(randf_range(12.0, 22.0))   # quadrati pixel
		c.size = Vector2(sz, sz)
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		c.pivot_offset = Vector2(sz, sz) * 0.5
		var sx := randf_range(-300.0, 340.0)   # copre la larghezza (Items è centrato)
		var sy := randf_range(-1500.0, -860.0)   # ben fuori dallo schermo, in alto, sfalsati
		c.position = Vector2(sx, sy)
		c.rotation = randf_range(0.0, TAU)
		cont.add_child(c)
		var delay := randf_range(0.0, 6.0)          # spalmati nel tempo
		# velocità di caduta ~costante: durata proporzionale alla distanza da percorrere
		var dur := (END_Y - sy) / 380.0
		var tw := c.create_tween()
		tw.tween_interval(delay)
		tw.tween_property(c, "position:y", END_Y, dur).set_trans(Tween.TRANS_LINEAR)
		tw.parallel().tween_property(c, "position:x", sx + randf_range(-70.0, 70.0), dur)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.parallel().tween_property(c, "rotation", c.rotation + randf_range(-8.0, 8.0), dur)
		tw.tween_callback(c.queue_free)
