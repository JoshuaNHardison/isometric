extends CharacterBody2D

class_name Cow

@export var speed: float = 20
@export var patrol_path: Array[Marker2D] = []
@export var patrol_wait_time = 1.0
@export var lost_cow: bool = false
@export var random_patrol_range: float = 600.0  # Range for generating random patrol points
@export var follow_distance: float = 800.0  # Distance to start following
@export var avoid_distance: float = 500.0  # Distance to start avoiding
@export var boids_distance: float = 500.0
@export var push_strength = 2
@export var player_push_strength = 2
@export var dog_push_strength = 1
@export var separation_radius = 80
@export var separation_strength = 10
@export var alignment_radius = 1000
@export var alignment_strength = 30
@export var cohesion_radius = 200
@export var cohesion_strength = 2
@export var goal_seeking_strength = 2
@export var risk_aversion_strength = 2
@export var max_speed = 100.0
#@export var stop_distance: float = 3.0 # Distance at which cow stops moving away


@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var raycast = $RayCast2D
@onready var collisionBox: CollisionShape2D = $CollisionShape2D
@onready var herdArea: Area2D = $herdArea
@onready var player = $"../Goblin"
@onready var dog = $"../Dog"
@onready var players = [player, dog]


var all_cows = []
var timer = 0.0
var avoidance_direction = Vector2.ZERO
var player_position
var dog_position
var target_position
var distance_to_player
var distance_to_dog
var all_boids = []
var distance_moved = 0.0
var recalculation_distance = 50.0  # Distance after which to recalculate behavior


#signal on each cow and the player finds all cows in yelling radius and the cow emits a signal "cow.emitsignal signal could be player_yelled_at_cow
#cow has a function called increased scared/emotion. the dog and the human are responsible for finding the cows and running that function on them
#each emotion has a flag or boolean value


func _ready():
	var mob_types = anim.sprite_frames.get_animation_names()
	anim.play(mob_types[randi() % mob_types.size()])
	
	all_cows.append(self)
	populate_all_cows()
	populate_all_boids()
	
	herdArea.connect("area_entered", Callable(self, "_on_area_entered"))
	herdArea.connect("area_exited", Callable(self, "_on_area_exited"))
	
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING


func populate_local_boids(current_cow: Node2D, num_neighbors: int) -> Array:
	var closest_cows = get_closest_cows(current_cow, num_neighbors)
	return closest_cows

func get_closest_cows(reference_node: Node2D, num_cows: int) -> Array:
	var distances = []
	var reference_node_position = reference_node.position
	
	# Loop through all cows, but ignore the reference node (current cow itself)
	for cow in all_cows:
		if cow != reference_node: # Exclude the current cow from the list
			var distance = reference_node_position.distance_to(cow.position)
			distances.append({'cow': cow, 'distance': distance})
	
	# Sort by distance (closest first)
	distances.sort_custom(func(a, b): return a['distance'] < b['distance'])
	
	# Collect the closest cows, limiting to the number requested
	var closest_cows = []
	for i in range(min(num_cows, distances.size())):
		closest_cows.append(distances[i]['cow'])
	
	return closest_cows

func populate_all_boids():
	all_boids.clear()
	for cow in get_tree().get_nodes_in_group("boids"):
		if cow is Cow:
			all_boids.append(cow)
			lost_cow = false
		else:
			lost_cow = true

func populate_all_cows():
	all_cows.clear()
	for cow in get_tree().get_nodes_in_group("boids"):
		if cow is Cow:
			all_cows.append(cow)


#func get_closest_cows(reference_node: Node2D, num_cows: int) -> Array:
	#var distances = []
	#var reference_node_position = reference_node.position
	#for cow in all_cows:
		#if cow:
			#var distance = reference_node_position.distance_to(cow.position)
			#distances.append({'cow': cow, 'distance': distance})
	#
	#distances.sort_custom(func(a, b): return a['distance'] < b['distance'])
	#var closest_cows = []
	#
	#for i in range(min(num_cows, distances.size())):
		#closest_cows.append(distances[i]['cow'])
	#
	#return closest_cows


func calculate_distance_to(target: Node2D) -> float:
	return global_position.distance_to(target.global_position)


func _physics_process(delta: float):
	timer = Time.get_ticks_msec()
	if !lost_cow:
		$Label.text = var_to_str(velocity.length())
		herd_behavior(delta)
	elif lost_cow:
		#print("lost")
		behavior_wander(delta)

#should i connect the lasso signal to the "teleport" function? 
func _on_lasso():
	print("the player lasso'd")
	var closest_cow = get_closest_cows(dog, 1)
	if closest_cow.size() > 0:
		print("Closest cow: ", closest_cow[0])
		var cow_position = closest_cow[0].position
		var boids_center = center_of_mass()
		var direction = (boids_center - self.global_position).normalized()
		self.position += direction * speed 


func _on_dog_bark():
	print("The dog barked! React accordingly.")
	var closest_cows = get_closest_cows(dog, 1)
	#add a distance check for closest cow
	if closest_cows.size() > 0:
		print("Closest cow: ", closest_cows[0])
		closest_cows[0].speed += 200
	else:
		print("No cows found.")

func behavior_flock(delta):
	var alignment_weight = 1.0
	var cohesion_weight = 1.0
	var separation_weight = 1.5
	var perception_radius = 100.0  # Adjust based on your needs

	var alignment = Vector2.ZERO
	var cohesion = Vector2.ZERO
	var separation = Vector2.ZERO
	var total_neighbors = 0

	for cow in all_boids:  # Iterate through the populated list
		if cow != self:  # Avoid self
			var distance = position.distance_to(cow.position)
			if distance < perception_radius:
				total_neighbors += 1
				
				# Alignment
				alignment += cow.velocity
				
				# Cohesion
				cohesion += cow.position
				
				# Separation
				var diff = position - cow.position
				diff /= distance  # Weight by distance
				separation += diff

	if total_neighbors > 0:
		# Average the vectors
		alignment /= total_neighbors
		alignment = alignment.normalized() * max_speed  # Set to max speed
		alignment = (alignment - velocity) * alignment_weight  # Steering force
		
		cohesion /= total_neighbors
		cohesion = (cohesion - position).normalized() * max_speed  # Set to max speed
		cohesion = (cohesion - velocity) * cohesion_weight  # Steering force
		
		separation = (separation / total_neighbors).normalized() * max_speed
		separation = (separation - velocity) * separation_weight  # Steering force
		
		# Combine the forces
		var flocking_velocity = alignment + cohesion + separation
		return flocking_velocity
	else:
		return Vector2.ZERO  # No neighbors, return zero vector


func herd_behavior(delta):
	if player:
		var combined_push = behavior_player_dog_push(delta)
		#var player_push = behavior_player_push(delta)
		#var dog_push = behavior_dog_push(delta)
		var wander = behavior_wander(delta)
		var separation = behavior_separation(delta)
		var alignment = behavior_alignment(delta)
		var cohesion = behavior_cohesion(delta)
		var goal_seeking = behavior_goal_seeking(delta)
		var risk_aversion = behavior_risk_aversion(delta)

		# Combine all behavior vectors
		var target_velocity = combined_push + separation + alignment + cohesion + goal_seeking + risk_aversion + wander

		# Ensure we don't slow down unnecessarily by checking against max_speed
		if target_velocity.length() > max_speed:
			target_velocity = target_velocity.normalized() * max_speed

		# Smooth the change in velocity (optional for more fluid motion)
		velocity = velocity.lerp(target_velocity, 0.5)

		# Final check to ensure cows always move at max speed if not influenced otherwise
		if velocity.length() < max_speed and target_velocity.length() > 0:
			velocity = velocity.normalized() * max_speed
		
		move_and_slide()
		raycast.rotation = velocity.angle()


func behavior_risk_aversion(delta):
	#create a group called "risks" where all the risk nodes are added
	var risk_nodes = get_tree().get_nodes_in_group("risks")
	if risk_nodes.is_empty():
		return Vector2.ZERO #no risks
	var closest_risk = null
	var min_distance = INF
	for risk in risk_nodes:
		var distance = (risk.global_position - global_position).length()
		if distance < min_distance:
			min_distance = distance
			closest_risk = risk
	if closest_risk:
		if closest_risk == dog:
			risk_aversion_strength = 10
		var risk_direction = (global_position - closest_risk.global_position).normalized()
		var risk_velocity = risk_direction * speed * risk_aversion_strength
		var smooth_factor = 0.1
		velocity = velocity.lerp(risk_velocity, smooth_factor)
		risk_aversion_strength = 2
	return velocity


func behavior_goal_seeking(delta):
	#create a group named "goals" where all the goal nodes are added
	var goal_nodes = get_tree().get_nodes_in_group("goals")
	if goal_nodes.is_empty():
		return Vector2.ZERO  # No goals to seek
	var closest_goal = null
	var min_distance = 300
	for goal in goal_nodes:
		var distance = (goal.global_position - global_position).length()
		if distance < min_distance:
			min_distance = distance
			closest_goal = goal
	if closest_goal:
		var goal_direction = (closest_goal.global_position - global_position).normalized()
		var goal_velocity = goal_direction * speed *  goal_seeking_strength
		var smooth_factor = 0.1
		velocity = velocity.lerp(goal_velocity, smooth_factor)
	return velocity


func behavior_alignment(delta):
	var neighbors = populate_local_boids(self, 5) # Get 5 closest boids (neighbors)
	var direction = Vector2.ZERO
	var headings = []
	
	# Loop through the neighbors, which are the closest boids
	for neighbor in neighbors:
		var distance = (neighbor.global_position - global_position).length()
		# If within alignment_radius, calculate heading
		if distance <= alignment_radius:
			# Calculate the ratio based on proximity
			var ratio = clamp(distance / alignment_radius, 0.0, 1.0)
			# Get the heading of the neighbor's velocity, scaled by ratio
			var heading = (neighbor.velocity).normalized() * ratio
			headings.append(heading)
	
	# If we have headings, calculate the average direction
	if headings.size() > 0:
		direction = Vector2.ZERO
		for heading in headings:
			direction += heading
		
		# Normalize the resulting direction and scale it by speed and alignment strength
		direction = direction.normalized() * speed * alignment_strength
	
	return direction



func behavior_separation(delta):
	populate_all_boids()
	var direction = Vector2.ZERO
	var boids_in_range = []
	for boid in all_boids:
		if boid != self and (boid.global_position - global_position).length() <= follow_distance:
			boids_in_range.append(boid)
	for boid in boids_in_range:
		var distance = (boid.global_position - global_position).length()
		if distance <= separation_radius:
			var ratio = clamp((boid.global_position - global_position).length() / separation_radius, 0.0, 1.0)
			direction -= (boid.global_position - global_position).normalized() * (1 / ratio)
	#velocity = direction.normalized() * speed
	#return velocity
	return direction.normalized() * speed * separation_strength


func behavior_cohesion(delta):
	populate_all_boids()
	var direction = Vector2.ZERO
	var boids_in_range = []
	var center_of_mass = Vector2.ZERO

	# Find all boids within the follow distance
	for boid in all_boids:
		if boid != self and (boid.global_position - global_position).length() <= follow_distance:
			boids_in_range.append(boid)
	# Calculate the center of mass of nearby boids
	if boids_in_range.size() > 0:
		for boid in boids_in_range:
			center_of_mass += boid.global_position
		
		center_of_mass /= boids_in_range.size()  # Get the average position
		
		# Steer towards the center of mass
		direction = (center_of_mass - global_position).normalized()
	return direction * speed * cohesion_strength


func center_of_mass():
	populate_all_boids()
	var boids_in_range = []
	var center_of_mass = Vector2()
	for boid in all_boids:
			if boid != self and (boid.global_position - global_position).length() <= follow_distance:
				boids_in_range.append(boid)
	if boids_in_range.size() > 0:
		for boid in boids_in_range:
			center_of_mass += boid.global_position
		
		center_of_mass /= boids_in_range.size()
		return center_of_mass
	return player.position + 10


func behavior_dog_push(delta):
	#dog push cow logic
	dog_position = dog.position
	target_position = (dog_position - position).normalized()
	distance_to_dog = calculate_distance_to(dog)
	var direction = (dog_position - position).normalized()
	if distance_to_dog <= avoid_distance:
		velocity = -direction.normalized() * speed * dog_push_strength
		return velocity
	else:
		return velocity


func behavior_player_push(delta):
	# Player and cow positions
	player_position = player.position
	distance_to_player = calculate_distance_to(player)
	var direction = (player_position - position).normalized()
	# If too close to the player, push away quickly
	if distance_to_player <= avoid_distance:
		# Inside avoid radius: Move away faster with player_push_strength
		velocity = -direction.normalized() * speed * player_push_strength
	else:
		# Outside avoid radius: Move at normal speed (not slower)
		velocity = direction * speed  # Full speed when outside avoid distance
	return velocity


func behavior_push_from_entities(delta, entity_position):
	var distance_to_entity = position.distance_to(entity_position)  # Update this line
	var direction = (entity_position - position).normalized()

	# If the entity (player or dog) is within the avoid distance, push away
	if distance_to_entity <= avoid_distance:
		return -direction * speed
	else:
		return Vector2.ZERO


func behavior_player_dog_push(delta):
	var player_push = behavior_push_from_entities(delta, player.position)
	var dog_push = behavior_push_from_entities(delta, dog.position)

	# Combine the forces from both player and dog equally
	var combined_push = player_push + dog_push

	return combined_push



func behavior_push_pull(delta):
	#follow player logic
	player_position = player.position
	print("pull")
	target_position = (player_position - position).normalized()
	distance_to_player = calculate_distance_to(player)
	var direction = (player_position - position).normalized()
	if distance_to_player >= avoid_distance and distance_to_player <= follow_distance:
		print("pull")
		velocity = direction.normalized() * speed
		return velocity
	elif distance_to_player <= avoid_distance:
		#print("push")
		velocity = -direction.normalized() * speed * push_strength
		return velocity
	else:
		return velocity


func behavior_wander(delta):
	#random radius and random angle
	distance_to_player = calculate_distance_to(player)
	if distance_to_player >= avoid_distance:
		if timer % 100 == 0:
			var rng = RandomNumberGenerator.new()
			var random_angle = rng.randf_range(0, 2 * PI)
			var random_radius = rng.randf_range(200, 1000)
			#make a vector
			var x = Vector2.from_angle(random_angle)
			velocity = x * random_radius
			return velocity
		else:
			return velocity
	else:
		return velocity


func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()
