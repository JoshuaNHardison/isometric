class_name PlayerControls
extends Resource

func handle_controls(player: Player, delta: float) -> void:
	if Input.is_action_just_pressed("mount_toggle"):
		if player.isMounted:
			player.on_dismount()
		else:
			var distance_to_horse = player.distance_to_horse(player.horse)
			if distance_to_horse < 100:
				player.on_mount(player.horse)
	
	if player.isMounted:
		_horse_movement(player, delta)
	else:
		_normal_movement(player, delta)

func _normal_movement(player: Player, delta: float) -> void:
	var motion = Vector2()
	motion.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	motion.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	motion.y /= 2
	motion = motion.normalized() * player.current_speed

	player.set_velocity(motion)
	player.move_and_slide()

	if player.velocity.length() > 0:
		player.last_direction = player.velocity
		player.update_animation("walk")
	else:
		player.update_animation("idle")

func _horse_movement(player: Player, delta: float) -> void:
	if player.current_direction == null or player.current_direction == Vector2.ZERO:
		player.current_direction = Vector2(1, 0)

	if Input.is_action_just_pressed("move_up"):
		player.momentum = clamp(player.momentum + player.speed_step, player.min_speed, player.max_speed)
	elif Input.is_action_just_pressed("move_down"):
		player.momentum = clamp(player.momentum - player.speed_step, player.min_speed, player.max_speed)

	var turn_input = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	if turn_input != 0:
		var turn_angle = turn_input * player.turn_speed * delta
		player.current_direction = player.current_direction.rotated(turn_angle).normalized()

	player.velocity = player.current_direction * player.momentum
	player.move_and_slide()

	if player.momentum > player.min_speed:
		player.last_direction = player.current_direction
		player.update_animation("walk")
	else:
		player.update_animation("idle")
