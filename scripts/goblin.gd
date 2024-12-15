extends CharacterBody2D

class_name Player

signal hit
signal lasso
signal tighter
signal looser
signal mountToggle


@onready var horse = $"../horse"
@onready var active: bool = false
signal mounted(horse)
signal dismounted(horse)

@export var max_speed: float = 300.0
@export var min_speed: float = 0.0
@export var speed_step: float = 50.0
@export var base_speed = 100.0
@export var mounted_speed = 300.0
@export var acceleration = 50.0
@export var turn_speed = 5.0
@export var deceleration = 30.0

var current_horse_speed: float = min_speed
var isMounted: bool = false
var current_speed: float
var momentum: float = 0.0
var target_direction = Vector2(1, 0)
var last_direction = Vector2(1, 0)
var current_direction
var is_swapping = false
var controls: PlayerControls

var anim_directions = {
	"idle": [
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

func _ready():
	current_speed = base_speed
	controls = preload("res://resources/PlayerControls.gd").new()

func _physics_process(delta):
	if not active:
		return
	controls.handle_controls(self, delta)

func update_animation(anim_set):
	var angle = rad_to_deg(last_direction.angle()) + 22.5
	var slice_dir = floor(angle / 45)

	$Sprite2D.play(anim_directions[anim_set][slice_dir][0])
	$Sprite2D.flip_h = anim_directions[anim_set][slice_dir][1]

func on_mount(horse: Node):
	isMounted = true
	current_speed = mounted_speed
	emit_signal("mounted", horse)
	print("Mounted the horse! Speed increased.")

func on_dismount():
	isMounted = false
	current_speed = base_speed
	emit_signal("dismounted", horse)
	print("Dismounted the horse! Speed reset.")

func activate():
	active = true
	set_process(true)
	set_physics_process(true)
	print(name, "is now active.")

func deactivate():
	active = false
	set_process(false)
	set_physics_process(false)
	print(name, "is now inactive.")


func _input(event: InputEvent):
	if not active:
		return
	else:
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

func distance_to_horse(horseNode):
	return int((self.global_position - horseNode.global_position).length())

