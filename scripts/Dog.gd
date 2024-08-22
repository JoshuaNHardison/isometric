extends CharacterBody2D

class_name Dog

const SPEED = 200.0

signal bark
var cow_scene = preload("res://scenes/cow.tscn")
var cow_node


func _ready():
	#cow_node = cow_scene.instance()
	add_child(cow_node)
	#connect_to_cow(cow_node)


func _physics_process(delta):
	var mouse_position = get_global_mouse_position()
	var direction = (mouse_position - global_position).normalized()
	velocity.x = direction.x * SPEED
	velocity.y = direction.y * SPEED
	
	move_and_slide()
	
	if global_position.distance_to(mouse_position) < SPEED * delta:
		global_position = mouse_position


func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		emit_signal("bark")  # Step 3: Emit the bark signal


#func connect_to_cow(cow_node):
	#connect("bark", cow_node, "_on_dog_bark")
