extends Camera2D


func zoom():
	if Input.is_action_just_released('zoom_out'):
		set_zoom(get_zoom() - Vector2(0.25, 0.25))
	if Input.is_action_just_released('zoom_in'): #and get_zoom() > Vector2.ONE:
		set_zoom(get_zoom() + Vector2(0.25, 0.25))

func _physics_process(delta):
	zoom()
