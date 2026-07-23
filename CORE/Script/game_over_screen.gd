extends Control



func _on_close_button_pressed() -> void:
	get_tree().change_scene_to_file("res://CORE/Scene/MainMenu.tscn")


func _on_play_again_button_pressed() -> void:
	get_tree().change_scene_to_file("res://CORE/Scene/game.tscn")
