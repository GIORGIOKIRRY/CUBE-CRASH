extends Control


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
