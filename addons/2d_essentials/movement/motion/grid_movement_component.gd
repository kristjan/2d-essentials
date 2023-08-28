class_name GodotEssentialsGridMovementComponent extends Node2D

signal moved(result: Dictionary)
signal flushed_recorded_grid_movements(movements: Array[Dictionary])
signal movements_completed(movements: Array[Dictionary])

@export_group("GridSize")
## The tile size for this grid based movement
@export var TILE_SIZE: int = 64

@export_group("GridBehaviour")
## Number of grid movements recorded before deletion (set to 0 to keep them indefinitely)
@export var MAX_RECORDED_GRID_MOVEMENTS: int = 5
## Number of movements to be performed before emitting a signal notification.
@export var EMIT_SIGNAL_EVERY_N_MOVEMENTS: int = 3

@onready var body: CharacterBody2D = get_parent() as CharacterBody2D

var recorded_grid_movements: Array[Dictionary] = []
var movements_count: int = 0

func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	var parent_node = get_parent()
	
	if parent_node == null or not parent_node is CharacterBody2D:
		warnings.append("This component needs a CharacterBody2D parent in order to work properly")
			
	return warnings


func _ready():
	if body:
		snap_body_position(body)
	
	moved.connect(on_moved)
	flushed_recorded_grid_movements.connect(on_flushed_recorded_grid_movements)
	
	
func follow_path(moves: Array[Vector2]):
	pass


func move(direction: Vector2, valid_position_callback: Callable = _default_valid_position_callback):
	direction = _handle_grid_direction(direction)
	
	if direction.is_zero_approx():
		return
	
	var original_position = body.global_position
	var next_position = original_position + direction * TILE_SIZE
	
	var result = {
		"from": original_position, 
		"to": next_position, 
		"direction": direction
	}
	

	if _default_valid_position_callback(result):
		body.global_position = next_position
		look_at(direction + body.global_position)

		moved.emit(result)
		

func on_moved(result: Dictionary):
	if MAX_RECORDED_GRID_MOVEMENTS == 0 or recorded_grid_movements.size() < MAX_RECORDED_GRID_MOVEMENTS:
		recorded_grid_movements.append(result)
	
	movements_count += 1
	
	if movements_count >= EMIT_SIGNAL_EVERY_N_MOVEMENTS:
		var movements: Array[Dictionary] = recorded_grid_movements.duplicate()
		movements.reverse()
		
		movements_completed.emit(movements.slice(0, movements_count))
		movements_count = 0

	if recorded_grid_movements.size() >= MAX_RECORDED_GRID_MOVEMENTS:
		flushed_recorded_grid_movements.emit(recorded_grid_movements)
	

func on_flushed_recorded_grid_movements(movements: Array[Dictionary]):
	movements.clear()


func _normalize_vector(value: Vector2) -> Vector2:
	return value if value.is_normalized() else value.normalized()


func snap_body_position(body: CharacterBody2D):
	body.global_position = body.global_position.snapped(Vector2.ONE * TILE_SIZE)
	body.global_position += Vector2.ONE * TILE_SIZE/2


func _handle_grid_direction(direction: Vector2):
	direction = _normalize_vector(direction)
	
	# Normalize diagonals
	if _is_diagonal(direction):
		direction *= sqrt(2)

	return direction

func _default_valid_position_callback(result: Dictionary = {}) -> bool:
	return true

func _is_diagonal(direction: Vector2) -> bool:
	return direction.x != 0 and direction.y != 0
