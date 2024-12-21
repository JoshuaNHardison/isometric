extends Camera2D


var target_position: Vector2 = Vector2.ZERO

func zoom():
	if Input.is_action_just_released('zoom_out'):
		set_zoom(get_zoom() - Vector2(0.25, 0.25))
	if Input.is_action_just_released('zoom_in'): #and get_zoom() > Vector2.ONE:
		set_zoom(get_zoom() + Vector2(0.25, 0.25))

func _physics_process(delta):
	zoom()
	position = target_position

func handle_cowboy_change(the_cowboy):
	if the_cowboy and the_cowboy.global_position:
		target_position = the_cowboy.global_position
		print("target: ", target_position)
