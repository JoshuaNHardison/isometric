extends Node2D

var all_cowboys = []
var target_positions = []
var current_cowboy_index = 0
var current_cowboy

@onready var camera: Camera2D = $Camera2D

func _ready():
	# Delay populate call until the scene tree is ready
	await get_tree().process_frame
	populate_all_cowboys()
	var scene = get_tree().current_scene
	camera = scene.get_child(0)
	activate_next_cowboy(current_cowboy_index)
	print("camera: ", camera)

#calculate the center of mass then rotate the cowboys based on that


func _physics_process(delta):
	await get_tree().process_frame
	if current_cowboy.active:
		camera.position = current_cowboy.global_position
	else:
		pass


func populate_all_cowboys():
	print("Populating all cowboys...")
	all_cowboys.clear()
	for cowboy in get_tree().get_nodes_in_group("cowboys"):
		all_cowboys.append(cowboy)
	print("Cowboys found: ", all_cowboys.size())

func _input(event: InputEvent):
	if event is InputEventKey and event.keycode == KEY_K and event.pressed:
		rotate_group(-PI / 160)
	if event is InputEventKey and event.keycode == KEY_J and event.pressed:
		rotate_group(PI / 160)
	if event is InputEventKey and event.keycode == KEY_Q and event.pressed:
		switch_to_next_cowboy()
	if event is InputEventKey and event.keycode == KEY_F and event.pressed:
		face_one_direction(Vector2(1,0))
		match_mount_status()
		reset_speed()
		switch_to_all_cowboys()
	if event is InputEventKey and event.keycode == KEY_1 and event.pressed:
		switch_to_specific_cowboy(0)
	if event is InputEventKey and event.keycode == KEY_2 and event.pressed:
		switch_to_specific_cowboy(1)
	if event is InputEventKey and event.keycode == KEY_3 and event.pressed:
		switch_to_specific_cowboy(2)
	if event is InputEventKey and event.keycode == KEY_4 and event.pressed:
		switch_to_specific_cowboy(3)

func get_group_center():
	var total_position = Vector2.ZERO
	for cowboy in all_cowboys:
		total_position += cowboy.global_position
	return total_position / all_cowboys.size()

func rotate_group(angle_delta: float):
	target_positions.clear()
	var center = get_group_center()
	for cowboy in all_cowboys:
		var relative_position = cowboy.global_position - center
		relative_position = relative_position.rotated(angle_delta)
		target_positions.append(center + relative_position)
	move_to_target_positions()

func move_to_target_positions():
	for i in range(all_cowboys.size()):
		var cowboy = all_cowboys[i]
		var target_position = target_positions[i]
		var direction = (target_position - cowboy.global_position).normalized()
		var distance = cowboy.global_position.distance_to(target_position)
		if distance > 2:
			cowboy.global_position += direction * cowboy.max_speed * get_process_delta_time()
		else:
			cowboy.global_position = target_position

func get_next_cowboy():
	current_cowboy_index = (current_cowboy_index + 1) % all_cowboys.size()
	return all_cowboys[current_cowboy_index]

func get_specific_cowboy(index):
	return all_cowboys[index]

func activate_next_cowboy(index):
	for cowboy in all_cowboys:
		cowboy.deactivate()
	all_cowboys[index].activate()
	current_cowboy = all_cowboys[index]

func activate_specific_cowboy(index):
	if index < 0 or index >= all_cowboys.size():
		print("Error:: Invalid index: ", index)
		return
	for cowboy in all_cowboys:
		cowboy.deactivate()
	all_cowboys[index].activate()
	current_cowboy = all_cowboys[index]

func switch_to_next_cowboy():
	var next_cowboy = get_next_cowboy()
	activate_next_cowboy(current_cowboy_index)

func switch_to_specific_cowboy(index):
	if index < 0 or index >= all_cowboys.size():
		print("Invalid cowboy index: ", index)
		return
	current_cowboy_index = index
	activate_specific_cowboy(index)
	
	var selected_cowboy = all_cowboys[index]
	if selected_cowboy:
		# Find the camera node (assuming it's named "Camera2D")
		if camera:
			camera.handle_cowboy_change(selected_cowboy)

func get_current_cowboy():
	return all_cowboys[current_cowboy_index]

func get_all_cowboys():
	return all_cowboys

func switch_to_all_cowboys():
	var cowboys = get_all_cowboys()
	activate_all_cowboys(cowboys)

func activate_all_cowboys(listOfCowboys):
	for cowboy in listOfCowboys:
		cowboy.activate()

func face_one_direction(direction: Vector2):
	for cowboy in all_cowboys:
		cowboy.target_direction = direction  # Assuming cowboys use `target_direction` for facing
		cowboy.current_direction = direction   # Update any related variables if needed
		cowboy.update_animation("idle")     # Refresh animation based on the new direction

func reset_speed():
	for cowboy in all_cowboys:
		cowboy.momentum = 0.0

func match_mount_status():
	for cowboy in all_cowboys:
		cowboy.on_mount(cowboy.horse)
