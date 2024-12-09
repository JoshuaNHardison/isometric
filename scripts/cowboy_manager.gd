extends Node2D

var all_cowboys = []
var current_cowboy_index = 0

func _ready():
	# Delay populate call until the scene tree is ready
	await get_tree().process_frame
	populate_all_cowboys()
	activate_next_cowboy(current_cowboy_index)

func populate_all_cowboys():
	print("Populating all cowboys...")
	all_cowboys.clear()
	for cowboy in get_tree().get_nodes_in_group("cowboys"):
		all_cowboys.append(cowboy)
	print("Cowboys found: ", all_cowboys.size())

func _input(event: InputEvent):
	if event is InputEventKey and event.keycode == KEY_Q and event.pressed:
		switch_to_next_cowboy()
	if event is InputEventKey and event.keycode == KEY_F and event.pressed:
		face_one_direction(Vector2(1,0))
		match_mount_status()
		reset_speed()
		switch_to_all_cowboys()

func get_next_cowboy():
	current_cowboy_index = (current_cowboy_index + 1) % all_cowboys.size()
	return all_cowboys[current_cowboy_index]

func activate_next_cowboy(index):
	for cowboy in all_cowboys:
		cowboy.deactivate()
	all_cowboys[index].activate()

func switch_to_next_cowboy():
	var next_cowboy = get_next_cowboy()
	activate_next_cowboy(current_cowboy_index)

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
