extends Node2D

var all_cowboys = []
var current_cowboy_index = 0



func _ready():
	# Delay populate call until the scene tree is ready
	await(get_tree().process_frame)
	populate_all_cowboys()


func populate_all_cowboys():
	print("all cowboys called")
	all_cowboys.clear()
	for cowboy in get_tree().get_nodes_in_group("cowboys"):
		all_cowboys.append(cowboy)
	print("Cowboys found: ", all_cowboys.size())

func get_next_cowboy():
	current_cowboy_index = (current_cowboy_index + 1) % all_cowboys.size()
	print("current index inside get_next_cowboy",current_cowboy_index)
	return all_cowboys[current_cowboy_index]

func get_current_cowboy():
	return all_cowboys[current_cowboy_index]
