extends Node2D

var all_boids = []
#var all_cows = []

func _ready():
	# Delay populate call until the scene tree is ready
	await(get_tree().process_frame)
	populate_all_boids()


func populate_all_boids():
	print("all boids called")
	for cow in get_tree().get_nodes_in_group("boids"):
		if cow is Cow:
			all_boids.append(cow)
