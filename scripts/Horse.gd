extends CharacterBody2D

class_name Horse

@export var mount_distance: float = 500.0
@export var speed: float = 20


@onready var player = $"../Goblin"
@onready var isPlayerMounted:bool = false


var distance_to_player


func _ready():
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING


func _physics_process(delta):
	distance_to_player = calculate_distance_to(player)
	if distance_to_player < mount_distance:
		#activate ability to mount
		if Input.is_action_just_pressed("mount_toggle") and not isPlayerMounted:
			isPlayerMounted = true
			player.call("on_mount", self)  # Hide the player if mounted
			print("Player has mounted the horse!")
	if isPlayerMounted and Input.is_action_just_pressed("mount_toggle"):
		isPlayerMounted = false
		player.call("on_dismount")
		print("The player has dismounted the horse.")


func calculate_distance_to(target: Node2D) -> float:
	return global_position.distance_to(target.global_position)


