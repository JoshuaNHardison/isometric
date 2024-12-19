extends CharacterBody2D

class_name Horse

@export var mount_distance: float = 500.0
@export var speed: float = 20


@onready var player = $"../Goblin"
@onready var isPlayerMounted:bool = false
@onready var collision_shape = $CollisionShape2D

var distance_to_player


func _ready():
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	if player:
		player.connect("mounted", _on_player_mounted)
		player.connect("dismounted", _on_player_dismounted)


func _physics_process(delta):
	if isPlayerMounted:
		collision_shape.disabled = true
		global_position = player.global_position
	else:
		collision_shape.disabled = false

func _on_player_mounted(player_instance):
	isPlayerMounted = true

func _on_player_dismounted(player_instance):
	isPlayerMounted = false
