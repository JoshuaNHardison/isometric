extends Node2D

var all_cowboys = []
var current_cowboy_index = 0


func _ready():
	# Delay populate call until the scene tree is ready
	await(get_tree().process_frame)
	populate_all_cowboys()
	initialize_cowboy(0)


func populate_all_cowboys():
	print("all cowboys called")
	all_cowboys.clear()
	for cowboy in get_tree().get_nodes_in_group("cowboys"):
		all_cowboys.append(cowboy)
	print("Cowboys found: ", all_cowboys.size())

func initialize_cowboy(index):
	print("initializing cowboy: ", index)
	all_cowboys[index].active = true
	all_cowboys[index].set_process(true)
	all_cowboys[index].set_physics_process(true)

func get_next_cowboy():
	print("Current Index (Before Swap): ", current_cowboy_index)
	current_cowboy_index = (current_cowboy_index + 1) % all_cowboys.size()
	print("Current Index (After Swap): ", current_cowboy_index)
	print("Current cowboy: ", all_cowboys[current_cowboy_index].name)
	#if current_cowboy_index == array_size:
		#print("reset")
		#initialize_cowboy(0)
		#return
	return all_cowboys[current_cowboy_index]


func activate_next_cowboy(index):
	var array_size = all_cowboys.size() - 1
	if index == array_size:
		print("reset")
		initialize_cowboy(0)
	else:
		var current_cowboy = all_cowboys[index]
		var next_cowboy = get_next_cowboy()
		for cowboy in all_cowboys:
			cowboy.active = false
			cowboy.set_process(false)
			cowboy.set_physics_process(false)
		all_cowboys[index].active = true
		all_cowboys[index].set_process(true)
		all_cowboys[index].set_physics_process(true)
		print("activated cowboy: ", all_cowboys[index])


func get_current_cowboy():
	return all_cowboys[current_cowboy_index]
