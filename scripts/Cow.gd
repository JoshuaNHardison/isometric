extends CharacterBody2D

class_name Cow

@export var speed: float = 20
@export var patrol_path: Array[Marker2D] = []
@export var patrol_wait_time = 1.0
@export var lost_cow: bool = false
@export var random_patrol_range: float = 600.0  # Range for generating random patrol points
@export var follow_distance: float = 800.0  # Distance to start following
@export var avoid_distance: float = 500.0  # Distance to start avoiding
@export var boids_distance: float = 300
@export var push_strength = 2
@export var player_push_strength = 2
@export var dog_push_strength = 1
@export var separation_radius = 50
@export var separation_strength = 1
@export var alignment_radius = 200
@export var alignment_strength = 3
@export var cohesion_radius = 200
@export var cohesion_strength = 3
@export var goal_seeking_strength = 2
@export var risk_aversion_strength = 2
#@export var stop_distance: float = 3.0 # Distance at which cow stops moving away


@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
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
	
	herdArea.connect("area_entered", Callable(self, "_on_area_entered"))
	herdArea.connect("area_exited", Callable(self, "_on_area_exited"))
	
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING


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


func get_closest_cows(reference_node: Node2D, num_cows: int) -> Array:
	var distances = []
	var reference_node_position = reference_node.position
	for cow in all_cows:
		if cow:
			var distance = reference_node_position.distance_to(cow.position)
			distances.append({'cow': cow, 'distance': distance})
	
	distances.sort_custom(func(a, b): return a['distance'] < b['distance'])
	var closest_cows = []
	
	for i in range(min(1, distances.size())):
		closest_cows.append(distances[i]['cow'])
	
	return closest_cows


func calculate_distance_to(target: Node2D) -> float:
	return global_position.distance_to(target.global_position)


func _physics_process(delta: float):
	timer = Time.get_ticks_msec()
	if !lost_cow:
		$Label.text = var_to_str(velocity.length())
		#print("not lost")
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


func herd_behavior(delta):
	if player:
		#if another cow is within the herd distance
		#add a bunch of dif vectors to calc vel
		#like player pos
		#set velocity to the behavior_follow/behavior_drive (the single command)
		#get vectors (in a similar way to the previous command) for separation, alignment and cohesion
		#maybe add all the given vectors together
		#var push_pull = behavior_push_pull(delta)
		var player_push = behavior_player_push(delta)
		var dog_push = behavior_dog_push(delta)
		var wander = behavior_wander(delta)
		var separation = behavior_separation(delta)
		var alignment = behavior_alignment(delta)
		var cohesion = behavior_cohesion(delta)
		var goal_seeking = behavior_goal_seeking(delta)
		var risk_aversion = behavior_risk_aversion(delta)
		var smooth_factor = 0.1
		var max_speed = 100  # Adjust this to a suitable value
		velocity = (player_push + dog_push + separation + alignment + cohesion + goal_seeking + risk_aversion + wander)
		#velocity = push_pull + separation 
		if velocity.length() > 0:
			velocity = velocity.normalized() * max_speed
		
		velocity = velocity.lerp(velocity, 0.05)
		
		move_and_slide()
		#maybe wait after determining the velocity until something happens?
		#goals for cows include water, grass, stay away from player


func behavior_variable_speed(delta):
	pass


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
	populate_all_boids()
	var direction = Vector2.ZERO
	var boids_in_range = []
	var headings = []
	for boid in all_boids:
		if boid != self and (boid.global_position - global_position).length() <= follow_distance:
			boids_in_range.append(boid)
	for boid in boids_in_range:
		var distance = (boid.global_position - global_position).length()
		if distance <= alignment_radius:
			var ratio = clamp((boid.global_position - global_position).length() / alignment_radius, 0.0, 1.0)
			var heading = (boid.velocity).normalized() * ratio # Calculate the heading of the boid
			headings.append(heading)
	if headings.size() > 0:
		direction = Vector2.ZERO
		for heading in headings:
			direction += heading
		direction = direction.normalized() * speed * alignment_strength
	return direction
			#calculate the heading of the boid and store it in an array?
	#calculate the average of the heading array


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
	#follow player logic
	dog_position = dog.position
	target_position = (dog_position - position).normalized()
	distance_to_dog = calculate_distance_to(dog)
	var direction = (dog_position - position).normalized()
	if distance_to_dog <= avoid_distance:
		#print("push")
		velocity = -direction.normalized() * speed * dog_push_strength
		return velocity
	else:
		return velocity


func behavior_player_push(delta):
	#follow player logic
	player_position = player.position
	target_position = (player_position - position).normalized()
	distance_to_player = calculate_distance_to(player)
	var direction = (player_position - position).normalized()
	if distance_to_player <= avoid_distance:
		#print("push")
		velocity = -direction.normalized() * speed * player_push_strength
		return velocity
	else:
		return velocity


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

#func behavior_push_pull(delta):
	#var target_info = {}
	#var target_position = Vector2.ZERO
	#var distance_to_target = 0.0
	## Check for both dog and player
	#if dog:
		#target_info = get_target_position_and_distance(dog)
	#elif player:
		#target_info = get_target_position_and_distance(player)
	#else:
		#return Vector2.ZERO
	#target_position = target_info["position"]
	#distance_to_target = target_info["distance"]
	## Determine the velocity based on the distance
	#return calculate_velocity(target_position, distance_to_target)


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

 #Define the function to handle wandering behavior
#func behavior_wander(delta):
	## Define the range for random movement
	#player_position = player.position
	#target_position = (player_position - position).normalized()
	#var distance_to_player = calculate_distance_to(player)
	#
	#if distance_to_player <= follow_distance:
		#var wander_radius = 100  # Adjust this value as needed
		#var origin = self.position
		## Generate a random offset within the defined range
		#var random_offset = Vector2(
			#randf_range(-wander_radius, wander_radius),
			#randf_range(-wander_radius, wander_radius)
		#)
		## Calculate the random destination based on the current position and the random offset
		#var random_destination = origin + random_offset
		## Move the cow towards the random destination
		#var direction = (random_destination - self.position).normalized()
		#var speed = 100  # Adjust this value to control the movement speed
		#var velocity = direction * speed
#
		## Apply the movement to the cow
		#self.position += velocity * delta
		#
	#else:
		#return
		#
#
	## Optionally, you can add logic to stop or change direction if the cow reaches the destination
#
#
#
##func behavior_wander(delta):
	##var origin = self.position
	##var random_destination = 
#
#
#
##
##func follow_player(delta: float):
	##if player:
		##var direction_to_player = position - player.global_position
		##var distance_to_player = direction_to_player.length()
		##if distance_to_player > stop_distance:
			##direction_to_player = direction_to_player.normalized()
			##velocity = direction_to_player * speed
			##move_and_slide()
		##else:
			##velocity = Vector2.ZERO
			##move_and_slide()
##
##
##func herding_mode(delta: float):
	##print("herding mode")
##
##
##func move_along_path(delta: float):
	### Check if we need to use random patrol points
	##if lost_cow:
		##if patrol_path.size() == 0 or current_patrol_target >= patrol_path.size():
		### Generate 4 random points around the cow
			##patrol_path = []
			##for i in range(4):
				##var random_point = position + Vector2(
				##randf_range(-random_patrol_range, random_patrol_range),
				##randf_range(-random_patrol_range, random_patrol_range)
				##)
				##var marker = Marker2D.new()
				##marker.position = random_point
				##patrol_path.append(marker)
				###patrol_path.append(Marker2D.new().set_position(random_point))
				##current_patrol_target = 0
##
	##if patrol_path.size() > 0:
		##var target_position = patrol_path[current_patrol_target].global_position
		##var direction = (target_position - position).normalized()
		##var distance_to_target = position.distance_to(target_position)
##
		##if distance_to_target > speed * delta:
			##velocity = direction * speed
			##move_and_slide()
		##else:
			##position = target_position
			##wait_timer += delta
		##if wait_timer >= patrol_wait_time:
			##wait_timer = 0.0
			##current_patrol_target = (current_patrol_target + 1) % patrol_path.size()
##
##
##
###func move_along_path(delta: float):
	###var target_position = patrol_path[current_patrol_target].global_position
	###var direction = (target_position - position).normalized()
	###var distance_to_target = position.distance_to(target_position)
	###
	###if distance_to_target > speed * delta:
		###velocity = direction * speed
		###move_and_slide()
	###else:
		###position = target_position
		###wait_timer += delta
		###if wait_timer >= patrol_wait_time:
			###wait_timer = 0.0
			###current_patrol_target = (current_patrol_target + 1) % patrol_path.size()
##
##
##func avoid_touching_player(delta: float):
	##if player:
		##var direction_to_player = (player.global_position - position).normalized()
		##avoidance_direction = -direction_to_player.normalized()  
		##velocity = avoidance_direction * speed
		##move_and_slide()
##
##
##func herd_behavior(delta: float):
	##print("herding behavior")
	##if player:
		##print(player)
		##var distance_to_player = position.distance_to(player.global_position)
		##if distance_to_player < avoid_distance:
			##avoid_touching_player(delta)
		##elif distance_to_player < follow_distance:
			##follow_player(delta)
		##else:
			##move_along_path(delta)
#func _on_area_2d_area_entered(area:Area2D):
	#if area.name == "goblin":
		#player = area
		#avoiding_player = true
#
#
#func _on_area_2d_area_exited(area:Area2D):
	#if area.name == "goblin":
		#player = area
		#avoiding_player = false
#func _rotation():
	## Calculate the direction vector from the cow to the player
	#var cow_position = global_position
	#var direction_to_player = (player_position - cow_position).normalized()
	## Compute the angle between the cow's right direction (Vector2.RIGHT) and the direction to the player
	#var angle_to_player = direction_to_player.angle_to(Vector2.RIGHT)
	#var direction = (player_position - position).normalized()
	#rotation = angle_to_player
#func herd_behavior(delta):
	#if player:
		#var distance_to_player = calculate_distance_to(player)
		#if distance_to_player <= avoid_distance:
			#behavior_drive(delta)  # Move away from the player
			#print("avoid", avoid_distance)
		#elif distance_to_player <= follow_distance:
			#behavior_follow(delta)  # Follow the player
			#print("follow", follow_distance)
		##add a bunch of dif vectors to calc vel
		##like player pos
		##set velocity to the behavior_follow/behavior_drive (the single command)
		##get vectors (in a similar way to the previous command) for separation, alignment and cohesion
		##maybe add all the given vectors together
		#velocity = direction * speed
		#move_and_slide()
		#look_at(player_position)
		##elif distance_to_player >= follow_distance:
			##behavior_wander(delta)
#turn follow and drive into one function that returns a vector pointing away from or towards the player based on the written logic
#func behavior_follow(delta):
	##follow player logic
	#player_position = player.position
	#target_position = (player_position - position).normalized()
	#var distance_to_player = calculate_distance_to(player)
	#
	#if distance_to_player >= follow_distance or position.distance_to(player_position) <= avoid_distance:
		#return
	#else:
		#var direction = (player_position - position).normalized()
		#velocity = direction * speed
		#move_and_slide()
		#look_at(player_position)
#func behavior_drive(delta):
	#player_position = player.position
	#target_position = (player_position - position).normalized()
	#var distance_to_player = calculate_distance_to(player)
	#
	#if distance_to_player >= avoid_distance:
		#return
	#else:
		#var direction = (player_position - position).normalized()
		#velocity = -direction * speed
		##velocity = (-target_position).normalized() * speed
		#move_and_slide()
		#look_at(-player_position)
