extends RayCast2D

var target: Node2D


func _physics_process(delta: float):
	if is_colliding():
		target = get_collider()
	else:
		pass

func return_seen():
	if is_colliding():
		return target
	else:
		return
