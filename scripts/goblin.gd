extends CharacterBody2D

class_name player

signal hit
signal lasso
signal tighter
signal looser
signal mountToggle

@export var base_speed = 100.0
@export var mounted_speed = 300.0
@export var acceleration = 50.0
@export var turn_speed = 5.0
@export var deceleration = 30.0

var isMounted: bool = false
var current_speed: float
var momentum: float = 0.0 # Current momentum
var target_direction = Vector2(1, 0)
var last_direction = Vector2(1, 0)

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
	# Horse-like movement system
	var input_dir = Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	)
	if input_dir.length() > 0:
		target_direction = input_dir.normalized()

	# Smooth turning to the target direction
	var current_direction = velocity.normalized()
	current_direction = current_direction.lerp(target_direction, turn_speed * delta)

	# Accelerate when input is given
	if input_dir.length() > 0:
		momentum += acceleration * delta
		momentum = min(momentum, mounted_speed)  # Cap at mounted speed
	else:
		# Decelerate if no input
		momentum -= deceleration * delta
		momentum = max(momentum, 0)  # Prevent negative momentum

	# Set velocity based on current direction and momentum
	set_velocity(current_direction * momentum)
	move_and_slide()

	# Update animations
	if momentum > 0:
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
