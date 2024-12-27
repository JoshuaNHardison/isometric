extends Node2D
class_name Tile

enum TileType {
	WALL,
	LAND
}

@export var tile_type: TileType

@onready var sprite := $Sprite2D

func _ready():
	sprite.modulate = Color(0, 1, 1, 1) if tile_type == TileType.WALL else Color.WHITE
