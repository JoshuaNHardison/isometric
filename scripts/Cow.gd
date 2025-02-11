extends CharacterBody2D

class_name Cow

@export var speed: float = 20
@export var lost_cow: bool = false
@export var avoid_distance: float = 500.0  # Distance to start avoiding
@export var boids_distance: float = 500.0
@export var push_strength = 1
@export var player_push_strength = 5
@export var dog_push_strength = 1
@export var separation_radius = 200
@export var separation_strength = 5
@export var alignment_radius = 1000
@export var alignment_strength = 5
@export var cohesion_radius = 1000
@export var cohesion_strength = 5
@export var goal_seeking_strength = 2
@export var risk_aversion_strength = 2
@export var max_speed = 100.0
@export var boids_radius = 300


@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var raycast = $RayCast2D
@onready var collisionBox: CollisionShape2D = $CollisionShape2D
@onready var herdArea: Area2D = $herdArea
@onready var cowboys_group = "cowboys"
@onready var player = $"../Goblin"
@onready var dog = $"../Dog"
@onready var players = [player, dog]


@onready var closest_cows = []
@onready var neighbors = []
@onready var isHerdingActive:bool = false
var original_cohesion_strength = cohesion_strength
var original_separation_strength = separation_strength
var timer = 0.0
var player_position
var dog_position
var target_position
var distance_to_player
var distance_to_dog
var push_velocity




#signal on each cow and the player finds all cows in yelling radius and the cow emits a signal "cow.emitsignal signal could be player_yelled_at_cow
#cow has a function called increased scared/emotion. the dog and the human are responsible for finding the cows and running that function on them
#each emotion has a flag or boolean value


func _ready():
	var mob_types = anim.sprite_frames.get_animation_names()
	anim.play(mob_types[randi() % mob_types.size()])
	
	
	herdArea.connect("area_entered", Callable(self, "_on_area_entered"))
	herdArea.connect("area_exited", Callable(self, "_on_area_exited"))
	
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING


func get_closest_cows(reference_node: Node2D, num_cows: int, max_distance: int) -> Array:
	var closest_cows = []
	var distances = []
	var reference_node_position = reference_node.position
	# Loop through all cows, but ignore the reference node (current cow itself)
	for cow in CowManager.all_boids:
		if cow != reference_node: # Exclude the current cow from the list
			var distance = reference_node_position.distance_to(cow.position)
			if distance <= max_distance:
				distances.append({'cow': cow, 'distance': distance})
	
	# Sort by distance (closest first)
	distances.sort_custom(func(a, b): return a['distance'] < b['distance'])
	# Collect the closest cows, limiting to the number requested
	for i in range(min(num_cows, distances.size())):
		closest_cows.append(distances[i]['cow'])
	
	#print("self: " + str(self.name) + "\n" + "closest_cows" + str(closest_cows) + "\n" + "\n")
	return closest_cows


func calculate_distance_to(target: Node2D) -> float:
	return global_position.distance_to(target.global_position)


func _physics_process(delta: float):
	timer = Time.get_ticks_msec()
	distance_to_player = calculate_distance_to(player)
	updateHerdingStatus()
	herd_behavior(delta)
	#if isHerdingActive == true:
		#herd_behavior(delta)
	#elif lost_cow:
		#print("lost")
		#behavior_wander(delta)


func updateHerdingStatus():
	#get distance to player
	if distance_to_player < 800:
		isHerdingActive = true
	else:
		isHerdingActive = false
	return isHerdingActive

#func herd_behavior(delta):
	#if players:
		#neighbors = get_closest_cows(self, 2, boids_distance)
		#var player_push = behavior_player_push(delta)
		#var cohesion = behavior_cohesion(delta)
		#var alignment = behavior_alignment(delta)
		#var separation = behavior_separation(delta)
		#var target_velocity =  player_push + cohesion + alignment + separation
		#if target_velocity.length() > max_speed:
			#target_velocity = target_velocity.normalized() * max_speed
		#var path_target_position = global_position + target_velocity.normalized() * 300
#
		## Set the target position for the NavigationAgent2D
		#$NavigationAgent2D.target_position = path_target_position
		#if !$NavigationAgent2D.is_target_reachable():
			#velocity = Vector2.ZERO
			#return
		## Get the next path position from NavigationAgent2D
		#var next_position = $NavigationAgent2D.get_next_path_position()
		## Calculate velocity toward the next path position
		#var desired_velocity = (next_position - global_position).normalized() * max_speed
		#velocity = velocity.lerp(desired_velocity, 0.1)
		## Smooth the change in velocity (optional for more fluid motion)
		##velocity = velocity.lerp(target_velocity, 0.5)
		## Final check to ensure cows always move at max speed if not influenced otherwise
		#if velocity.length() < max_speed and target_velocity.length() > 0:
			#velocity = velocity.normalized() * max_speed
		#$Label.text = "cohesion: " + str(round(cohesion.length())) + "\n" + "alignment: " + str(round(alignment.length())) + "\n" +"separation: " + str(round(separation.length())) + "\n" +"player_push: " + str(round(player_push.length()))
		#move_and_slide()
		#raycast.rotation = velocity.angle()


func herd_behavior(delta):
	# Retrieve velocities for player push
	var player_push_velocities = behavior_player_push(delta)
	# Combine push velocities from all players
	var player_push = Vector2.ZERO
	if player_push_velocities.size() > 0:
		for vel in player_push_velocities:
			player_push += vel

	# Other behaviors
	neighbors = get_closest_cows(self, 2, boids_distance)
	var cohesion = behavior_cohesion(delta)
	var alignment = behavior_alignment(delta)
	var separation = behavior_separation(delta)

	# Combine all behaviors
	var target_velocity = player_push + cohesion + alignment + separation + player.velocity
	#if target_velocity.length() > max_speed:
		#target_velocity = target_velocity.normalized() * max_speed

	# Navigate the cow
	var path_target_position = global_position + target_velocity.normalized() * 300
	$NavigationAgent2D.target_position = path_target_position

	if !$NavigationAgent2D.is_target_reachable():
		velocity = Vector2.ZERO
		return

	# Calculate and apply the next movement step
	var next_position = $NavigationAgent2D.get_next_path_position()
	var desired_velocity = (next_position - global_position).normalized() * max_speed
	velocity = velocity.lerp(desired_velocity, 0.1)

	# Ensure the cow moves at max speed if influenced
	if velocity.length() < max_speed and target_velocity.length() > 0:
		velocity = velocity.normalized() * max_speed

	# Debugging information
	$Label.text = "cohesion: " + str(round(cohesion.length())) + "\n" + \
					"alignment: " + str(round(alignment.length())) + "\n" + \
					"separation: " + str(round(separation.length())) + "\n" + \
					"player_push: " + str(round(player_push.length()))

	# Apply movement
	move_and_slide()
	raycast.rotation = velocity.angle()

func behavior_alignment(delta):
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
	var direction = Vector2.ZERO
	for boid in neighbors:
		var distance = (boid.global_position - global_position).length()
		if distance <= separation_radius:
			#var ratio = clamp((boid.global_position - global_position).length() / separation_radius, 0.0, 1.0)
			direction -= (boid.global_position - global_position).normalized()
	#return velocity as a variable named separation
	var separation = direction.normalized() * speed * separation_strength
	return separation

func behavior_cohesion(delta):
	var direction = Vector2.ZERO
	var center_of_mass = Vector2.ZERO
	
	# Calculate the center of mass of nearby boids
	if neighbors.size() > 0:
		for boid in neighbors:
			center_of_mass += boid.global_position
		
		center_of_mass /= neighbors.size()  # Get the average position
		
		# Steer towards the center of mass
		direction = (center_of_mass - global_position).normalized()
	var cohesion = direction * speed * cohesion_strength
	return cohesion #return 

func _center_of_mass():
	var boids_in_range = get_closest_cows(self, 4, boids_distance)
	var center_of_mass = Vector2.ZERO
	var count = boids_in_range.size()
	
	if count == 0:
		return Vector2.ZERO
	for boid in boids_in_range:
		center_of_mass += boid.global_position
	center_of_mass /= boids_in_range.size()
	return center_of_mass

##func behavior_dog_push(delta):
	###dog push cow logic
	##dog_position = dog.position
	##target_position = (dog_position - position).normalized()
	##distance_to_dog = calculate_distance_to(dog)
	##var direction = (dog_position - position).normalized()
	##if distance_to_dog <= avoid_distance:
		##velocity = -direction.normalized() * speed * dog_push_strength
		##return velocity
	##else:
		##return velocity


#func behavior_player_push(delta):
	## Player and cow positions
	#player_position = player.position
	#distance_to_player = calculate_distance_to(player)
	#var direction = (player_position - position).normalized()
	## If too close to the player, push away quickly
	#if distance_to_player <= avoid_distance:
		## Inside avoid radius: Move away faster with player_push_strength
		#velocity = -direction.normalized() * speed * player_push_strength
	#return velocity


func behavior_player_push(delta):
	var velocities = []  # List to store velocities for each player
	
	# Iterate through all players in the group
	for pushingCowboy in get_tree().get_nodes_in_group(cowboys_group):

		var player_position = pushingCowboy.position  # Use global position for accuracy
		var distance_to_player = calculate_distance_to(pushingCowboy)
		var direction = (player_position - position).normalized()
		# If too close to the player, calculate the push velocity
		if distance_to_player <= avoid_distance:
			push_velocity = -direction * speed * player_push_strength
			velocities.append(push_velocity)
	return velocities


#func behavior_wander(delta):
	##random radius and random angle
	#distance_to_player = calculate_distance_to(player)
	#if distance_to_player >= avoid_distance:
		#if timer % 100 == 0:
			#var rng = RandomNumberGenerator.new()
			#var random_angle = rng.randf_range(0, 2 * PI)
			#var random_radius = rng.randf_range(200, 1000)
			##make a vector
			#var x = Vector2.from_angle(random_angle)
			#velocity = x * random_radius
			#return velocity
		#else:
			#return velocity
	#else:
		#return velocity


#func behavior_risk_aversion(delta):
	##create a group called "risks" where all the risk nodes are added
	#var risk_nodes = get_tree().get_nodes_in_group("risks")
	#if risk_nodes.is_empty():  #no risks
		#return velocity
	#var closest_risk = null
	#var min_distance = INF
	#for risk in risk_nodes:
		#var distance = (risk.global_position - global_position).length()
		#if distance < min_distance:
			#min_distance = distance
			#closest_risk = risk
	#if closest_risk:
		#if closest_risk == dog:
			#risk_aversion_strength = 10
		#var risk_direction = (global_position - closest_risk.global_position).normalized()
		#var risk_velocity = risk_direction * speed * risk_aversion_strength
		#var smooth_factor = 0.1
		#velocity = velocity.lerp(risk_velocity, smooth_factor)
		#risk_aversion_strength = 2
	#return velocity


#func behavior_goal_seeking(delta):
	##create a group named "goals" where all the goal nodes are added
	#var goal_nodes = get_tree().get_nodes_in_group("goals")
	#if goal_nodes.is_empty():
		#return velocity # No goals to seek
	#var closest_goal = null
	#var min_distance = 300
	#for goal in goal_nodes:
		#var distance = (goal.global_position - global_position).length()
		#if distance < min_distance:
			#min_distance = distance
			#closest_goal = goal
	#if closest_goal:
		#var goal_direction = (closest_goal.global_position - global_position).normalized()
		#var goal_velocity = goal_direction * speed *  goal_seeking_strength
		#var smooth_factor = 0.1
		#velocity = velocity.lerp(goal_velocity, smooth_factor)
	#return velocity


func _on_tighter():
	print("the player said tighter")
	original_cohesion_strength = cohesion_strength
	self.cohesion_strength += 4
	var timer = Timer.new()
	timer.wait_time = 2.0
	timer.one_shot = true
	timer.connect("timeout", _step2_tighter)
	add_child(timer)
	timer.start()

func _step2_tighter():
	self.cohesion_strength = original_cohesion_strength

func _on_looser():
	print("the player said looser")
	original_separation_strength = separation_strength
	self.separation_strength += 4
	var timer = Timer.new()
	timer.wait_time = 2.0
	timer.one_shot = true
	timer.connect("timeout", _step2_looser)
	add_child(timer)
	timer.start()

func _step2_looser():
	self.separation_strength = original_separation_strength

func _on_lasso():
	print("the player lasso'd")
	original_cohesion_strength = cohesion_strength
	self.cohesion_strength += 4
	print(self.cohesion_strength)
	var timer = Timer.new()
	timer.wait_time = 2.0
	timer.one_shot = true
	timer.connect("timeout", _step2_lasso)
	add_child(timer)
	timer.start()

func _step2_lasso():
	self.cohesion_strength = original_cohesion_strength
	print(self.cohesion_strength)
	print("step2")

#func _on_lasso():
	#print("the player lasso'd")
	#var com = _center_of_mass()
	#print("center of mass:" + str(com))
	#original_cohesion_strength = cohesion_strength
	#cohesion_strength *= 4
	#var timer = Timer.new()
	#timer.wait_time = 2.0
	#timer.one_shot = true
	#timer.connect("timeout", _step2_lasso)  # Connect timer to reset function
	#add_child(timer)
	#timer.start()
	##var closest_cow = get_closest_cows(dog, 1, 200)
	##if closest_cow.size() > 0:
		##print("Inside _on_lasso() -> Closest cow: ", closest_cow[0])
		##var cow_position = closest_cow[0].position
		##var boids_center = center_of_mass()
		##var direction = (boids_center - self.global_position).normalized()
		##closest_cow[0].position += direction * speed 

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

##func _on_dog_bark():
	##print("The dog barked! React accordingly.")
	##var closest_cows = get_closest_cows(dog, 1, 200)
	###add a distance check for closest cow
	##if closest_cows.size() > 0:
		##print("Closest cow: ", closest_cows[0])
		##closest_cows[0].speed += 200
	##else:
		##print("No cows found.")



func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()
