extends Node
func _ready() -> void:
	settings.story_stars = {1:3, 2:2, 3:1, 4:1}
	settings.story_completed = 4
	var mm = load("res://CORE/Scene/MainMenu.tscn").instantiate(); add_child(mm)
	for i in 30: await get_tree().process_frame
	mm._open_story_map()
	for i in 15: await get_tree().process_frame
	await get_tree().create_timer(0.25).timeout
	get_viewport().get_texture().get_image().save_png("/tmp/map_stars.png")
	mm._open_story_level_popup(1)
	for i in 5: await get_tree().process_frame
	await get_tree().create_timer(0.25).timeout
	get_viewport().get_texture().get_image().save_png("/tmp/popup_stars.png")
	print("OK ms")
	get_tree().quit()
