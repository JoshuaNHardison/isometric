extends Node2D

class_name World

const TILE_SIZE_Y = 64
const TILE_SIZE_X = 128
const TILE_SIZE = 32
const WALL_LEVEL = 0.0
const RENDER_DISTANCE = 16.0

@export var altitude_noise: FastNoiseLite
@export var tile: PackedScene

func _ready():
	for n in RENDER_DISTANCE:
		var x = n - RENDER_DISTANCE / 2.0
		
		for m in RENDER_DISTANCE:
			var y = m - RENDER_DISTANCE / 2.0
			
			generate_terrain_tile(x,y)

func generate_terrain_tile(x:int, y: int):
	var tile = tile.instantiate()
	tile.tile_type = altitude_value(x,y)
	#tile.position = Vector2(x * TILE_SIZE_X,y * TILE_SIZE_Y)
	tile.position = Vector2(x,y) * TILE_SIZE
	add_child(tile)

func altitude_value(x:int, y:int) -> Tile.TileType:
	var value = altitude_noise.get_noise_2d(x,y)
	
	if value >= WALL_LEVEL:
		return Tile.TileType.LAND
	return Tile.TileType.WALL
