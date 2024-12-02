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

func get_next_cowboy():
	current_cowboy_index = (current_cowboy_index + 1) % all_cowboys.size()
	return all_cowboys[current_cowboy_index]

func activate_next_cowboy(index):
	for cowboy in all_cowboys:
		cowboy.deactivate()
	all_cowboys[index].activate()
	print("Activated cowboy: ", all_cowboys[index].name)

func switch_to_next_cowboy():
	var next_cowboy = get_next_cowboy()
	activate_next_cowboy(current_cowboy_index)
	print("Switched to cowboy: ", next_cowboy.name)

func get_current_cowboy():
	return all_cowboys[current_cowboy_index]
