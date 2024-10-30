extends Node2D

var all_boids = []
#var all_cows = []

#func _ready():
	#populate_all_boids() #this is running on each cow
	##all_cows.append(self)
	##populate_all_cows()

func populate_all_boids():
	print("all boids called")
	for cow in get_tree().get_nodes_in_group("boids"):
		if cow is Cow:
			print("Found cow: ", cow.name)
			all_boids.append(cow)

#func populate_all_cows():
	#for cow in get_tree().get_nodes_in_group("boids"):
		#if cow is Cow:
			#all_cows.append(cow)
