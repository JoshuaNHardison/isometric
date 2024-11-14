extends Node2D

var all_boids = []
var cow = Cow



#@onready var player = get_node('Walls/Goblin')
#var all_cows = []

func _ready():
	# Delay populate call until the scene tree is ready
	await(get_tree().process_frame)
	populate_all_boids()
	connect("lasso", Callable(self, "_on_lasso"))


func populate_all_boids():
	print("all boids called")
	for cow in get_tree().get_nodes_in_group("boids"):
		if cow is Cow:
			all_boids.append(cow)


#func _on_lasso():
	#print("the player lasso'd")
	#for boid in all_boids:
		#if boid is Cow:
			#boid.original_cohesion_strength = boid.cohesion_strength  # Save the original value
			#boid.cohesion_strength *= 4  # Increase the cohesion strength (change as needed)
			#print("Updated cohesion_strength to: ", boid.cohesion_strength)
	#var timer = Timer.new()
	#timer.wait_time = 2.0
	#timer.one_shot = true
	#timer.connect("timeout", _step2_lasso)  # Connect timer to reset function
	#add_child(timer)
	#timer.start()
	#var closest_cow = get_closest_cows(dog, 1, 200)
	#if closest_cow.size() > 0:
		#print("Inside _on_lasso() -> Closest cow: ", closest_cow[0])
		#var cow_position = closest_cow[0].position
		#var boids_center = center_of_mass()
		#var direction = (boids_center - self.global_position).normalized()
		#closest_cow[0].position += direction * speed 
#func _step2_lasso():
	#cohesion_strength = original_cohesion_strength
	#print("cohesion str: " + str(cohesion_strength))
	#
	#original_separation_strength = separation_strength
	#separation_strength += 2
	#
	#var timer = Timer.new()
	#timer.wait_time = 2.0
	#timer.one_shot = true
	#timer.connect("timeout", _step3_lasso)
	#add_child(timer)
	#timer.start()
#func _step3_lasso():
	#separation_strength = original_separation_strength
