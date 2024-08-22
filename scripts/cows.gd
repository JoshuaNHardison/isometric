extends Node2D

var all_boids = []

func _ready():
	# Populate all_boids with all instances of Cow in the scene
	populate_all_boids()

func populate_all_boids():
	all_boids.clear()
	for cow in get_tree().get_nodes_in_group("boids"):
		if cow is Cow:
			all_boids.append(cow)
	print("All Boids:", all_boids)

# Add each cow instance to the "boids" group either in the editor or dynamically in code
func _init():
	add_to_group("boids")
