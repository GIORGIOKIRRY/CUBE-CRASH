extends Node
func _ready() -> void:
	settings.game_mode="story"; settings.story_level=1
	settings.story_grid=3; settings.story_colors=3
	settings.story_ab_vert=false; settings.story_ab_horiz=false; settings.story_ab_bomb=false
	settings.story_goal="score"; settings.story_target=1000
	settings.story_goal_cubes=0; settings.story_goal_colors={}; settings.story_time=0.0
	var s=load("res://CORE/Scene/game.tscn").instantiate(); add_child(s)
	for i in 22: await get_tree().process_frame
	var g=s.get_node("grid"); g.score=1500; g._story_last_score=-1; g._update_story_hud()
	await get_tree().process_frame; await get_tree().create_timer(0.3).timeout
	print("view=%s" % str(get_viewport_rect().size))
	get_viewport().get_texture().get_image().save_png("/tmp/hud_ipad.png"); print("OK")
	get_tree().quit()
