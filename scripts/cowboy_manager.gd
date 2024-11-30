extends Node2D

var all_cowboys = []
var current_cowboy_index = 0


func _ready():
	# Delay populate call until the scene tree is ready
	await(get_tree().process_frame)
	populate_all_cowboys()
	activate_cowboy(current_cowboy_index)


func populate_all_cowboys():
	print("all cowboys called")
	all_cowboys.clear()
	for cowboy in get_tree().get_nodes_in_group("cowboys"):
		all_cowboys.append(cowboy)
	print("Cowboys found: ", all_cowboys.size())

func get_next_cowboy():
	print("Current Index (Before Swap): ", current_cowboy_index)
	if current_cowboy_index == all_cowboys.size() - 1:
		current_cowboy_index = 0
		print("Reached end of list. Wrapping to start.")
	else:
		current_cowboy_index += 1
	#activate_cowboy(current_cowboy_index)
	print("Current Index (After Swap): ", current_cowboy_index)
	print("Current cowboy: ", all_cowboys[current_cowboy_index].name)
	return all_cowboys[current_cowboy_index]

func activate_cowboy(index):
	for cowboy in all_cowboys:
		cowboy.active = false
	all_cowboys[index].active = true
	print("activated cowboy: ", all_cowboys[index])

func get_current_cowboy():
	return all_cowboys[current_cowboy_index]
