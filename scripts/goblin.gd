extends CharacterBody2D

class_name player

signal hit
signal lasso
signal tighter
signal looser
signal mountToggle

@onready var horse = $"../horse"

@export var max_speed: float = 300.0
@export var min_speed: float = 0.0
@export var speed_step: float = 50.0  # How much to increase/decrease speed with each key press
@export var base_speed = 100.0
@export var mounted_speed = 300.0
@export var acceleration = 50.0
@export var turn_speed = 5.0
@export var deceleration = 30.0

var current_horse_speed: float = min_speed  # Start at minimum speed
var isMounted: bool = false
var current_speed: float
var momentum: float = 0.0 # Current momentum
var target_direction = Vector2(1, 0)
var last_direction = Vector2(1, 0)
var current_direction



var anim_directions = {
	"idle": [ # list of [animation name, horizontal flip]
		["side_right_idle", false],
		["45front_right_idle", false],
		["front_idle", false],
		["45front_left_idle", false],
		["side_left_idle", false],
		["45back_left_idle", false],
		["back_idle", false],
		["45back_right_idle", false],
	],

	"walk": [
		["side_right_walk", false],
		["45front_right_walk", false],
		["front_walk", false],
		["45front_left_walk", false],
		["side_left_walk", false],
		["45back_left_walk", false],
		["back_walk", false],
		["45back_right_walk", false],
	],
}

func _physics_process(delta):
	if Input.is_action_just_pressed("mount_toggle"):
		if isMounted:
			on_dismount()
		else:
			on_mount(horse)  # Pass the horse Node if necessary
	if isMounted:
		_horse_movement(delta)
	else:
		_normal_movement(delta)

func _normal_movement(delta):
	# Default player movement system
	var motion = Vector2()
	motion.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	motion.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	motion.y /= 2  # Example of dampened vertical movement
	motion = motion.normalized() * current_speed
	set_velocity(motion)
	move_and_slide()
	if velocity.length() > 0:
		last_direction = velocity
		update_animation("walk")
	else:
		update_animation("idle")

func _horse_movement(delta):
	# Ensure current_direction retains its value or initializes properly
	if current_direction == null or current_direction == Vector2.ZERO:
		current_direction = Vector2(1, 0)  # Default to facing right
	# Adjust speed using W and S keys
	if Input.is_action_just_pressed("move_up"):  # W key
		momentum = clamp(momentum + speed_step, min_speed, max_speed)
	elif Input.is_action_just_pressed("move_down"):  # S key
		momentum = clamp(momentum - speed_step, min_speed, max_speed)

	var turn_input = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	if turn_input != 0:
		var turn_angle = turn_input * turn_speed * delta  # Adjust the angle based on input and turn speed
		current_direction = current_direction.rotated(turn_angle).normalized()  # Rotate the direction vector

	# Set velocity based on current direction and momentum
	velocity = current_direction * momentum
	move_and_slide()
	# Update animations
	if momentum > min_speed:
		last_direction = current_direction
		update_animation("walk")
	else:
		update_animation("idle")


func update_animation(anim_set):
	var angle = rad_to_deg(last_direction.angle()) + 22.5
	var slice_dir = floor(angle / 45)

	$Sprite2D.play(anim_directions[anim_set][slice_dir][0])
	$Sprite2D.flip_h = anim_directions[anim_set][slice_dir][1]


func _input(event: InputEvent):
	if event is InputEventKey and event.keycode == KEY_C and event.pressed:
		emit_signal("lasso")
		$Label.text = "lasso"
		await get_tree().create_timer(1.0).timeout
		$Label.text = ""
	if event is InputEventKey and event.keycode == KEY_Z and event.pressed:
		emit_signal("tighter")
		$Label.text = "tighter"
		await get_tree().create_timer(1.0).timeout
		$Label.text = ""
	if event is InputEventKey and event.keycode == KEY_X and event.pressed:
		emit_signal("looser")
		$Label.text = "looser"
		await get_tree().create_timer(1.0).timeout
		$Label.text = ""
	if event is InputEventKey and event.keycode == KEY_Q and event.pressed:
		swap_cowboy()

func swap_cowboy():
	var next_cowboy = CowboyManager.get_next_cowboy()
	if next_cowboy == self:
		return
	self.set_process(false)
	self.set_physics_process(false)
	
	next_cowboy.set_process(true)
	next_cowboy.set_physics_process(true)
	
	print("Swapped control to: ", next_cowboy.name)


func on_mount(horse: Node):
	isMounted = true
	current_speed = mounted_speed
	print("Mounted the horse! Speed increased.")

func on_dismount():
	isMounted = false
	current_speed = base_speed
	print("Dismounted the horse! Speed reset.")


func _on_area_2d_area_entered(area):
	if area.name == "Cow":
		print("Cow detected")
		$CollisionShape2D.set_deferred("disabled", true)


func start(pos):
	position = pos
	show()
	$CollisionShape2D.disabled = false

func _ready():
	current_speed = base_speed
	for cow in get_tree().get_nodes_in_group("boids"):
		self.tighter.connect(cow._on_tighter)
		self.looser.connect(cow._on_looser)
