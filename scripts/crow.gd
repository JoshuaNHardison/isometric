extends RigidBody2D

@export var speed: float = 150.0
var player: Node2D = null

func _ready():
	# Assume player is a node in the scene named "Player"
	var player = $"../Goblin"
#
func _integrate_forces(state: PhysicsDirectBodyState2D):
	if player:
		var direction = (player.global_position - global_position).normalized()
		var force = direction * speed
		apply_central_impulse(force * state.step)
