@tool

class_name VelocityComponent2D extends Node2D

############ SIGNALS ############
signal dashed
signal knockback_received
signal jumped

########## EDITABLE PARAMETERS ##########
@export_group("Speed")
## The max speed this character can reach
@export var max_speed: int = 125
## This value makes smoother the time it takes to reach maximum speed  
@export var acceleration: float = 400.0
@export var friction: float =  800.0

@export_group("Dash")
## The speed multiplier would be applied to the player velocity on runtime
@export var dash_speed_multiplier: int = 2
## The times this character can dash until the cooldown is activated
@export_range(1, 5, 1, "or_greater") var times_can_dash: int = 1
## The time it takes for the dash ability to become available again.
@export var dash_cooldown: float = 1.5

@export_group("Jump")

## The maximum height the character can reach
@export var jump_height: float = 100.0
## Time it takes to reach the maximum jump height
@export var jump_time_to_peak: float = 0.4
## Time it takes to reach the floor after jump
@export var jump_time_to_fall: float = 0.5

## Jumps allowed to perform in a row
@export var allowed_jumps : int = 1
## Reduced amount of jump effectiveness at each iteration
@export var height_reduced_by_jump : int = 0

## Enable the wall jump action
@export var wall_jump_enabled : bool = false
## Decide if it counts as a jump to reduce the allowed jump counter.
@export var counts_as_jump: bool = false
## The maximum angle of deviation that a wall can have to allow the jump to be executed.
@export var maximum_permissible_wall_angle : float = 0.0

## Enable the coyote jump
@export var coyote_jump_enabled: bool = false
## The time window this jump can be executed when the character is not on the floor
@export var coyote_jump_time_window: float = 0.2

@onready var jump_velocity: float = ((2.0 * jump_height) / jump_time_to_peak) * -1.0
@onready var jump_gravity: float =  (2.0 * jump_height) / pow(jump_time_to_peak, 2) 
@onready var fall_gravity: float =  (2.0 * jump_height) / pow(jump_time_to_fall, 2) 

@export_group("Knockback")
## The amount of power the character is pushed in the direction of the force source
@export var knockback_power: int = 300
#################################################

var can_dash: bool = false
var dash_queue: Array[String] = []

var velocity: Vector2 = Vector2.ZERO
var facing_direction: Vector2 = Vector2.ZERO
var last_faced_direction: Vector2 = Vector2.DOWN


func _ready():
	enable_dash(dash_cooldown)


func move(body: CharacterBody2D = get_parent()):
	if body:
		body.velocity = velocity
		body.move_and_slide()
	
	return self
	
func accelerate_in_direction(direction: Vector2):
	if !direction.is_equal_approx(Vector2.ZERO):
		last_faced_direction = direction
		
	facing_direction = direction

	velocity = velocity.move_toward(facing_direction * max_speed, acceleration * get_physics_process_delta_time())
	
	return self

func accelerate_to_target(target: Node2D):
	var target_direction: Vector2 = (target.global_position - global_position).normalized()
	
	return accelerate_in_direction(target_direction)

func accelerate_to_position(position: Vector2):
	var target_direction: Vector2 = (position - global_position).normalized()
	
	return accelerate_in_direction(target_direction)

				
func decelerate():
	velocity = velocity.move_toward(Vector2.ZERO, friction * get_physics_process_delta_time())
	
	return self
	
func knockback(from: Vector2, power: int = knockback_power):
	var knockback_direction: Vector2 = (from - velocity).normalized() * power
	velocity = knockback_direction

	move()
	knockback_received.emit()		
	
func dash(target_direction: Vector2 = facing_direction):
	if !velocity.is_zero_approx() and can_dash and dash_queue.size() < times_can_dash:
		dash_queue.append("dash")
		
		velocity *= dash_speed_multiplier
		facing_direction = target_direction
		move()
		
		_create_dash_cooldown_timer()
		dashed.emit()
		
	
func get_gravity() -> float:
	return jump_gravity if velocity.y < 0.0 else fall_gravity

func apply_gravity():
	velocity.y += get_gravity() * get_physics_process_delta_time()	
	
func jump():
	velocity.y = jump_velocity
	jumped.emit()
	
func enable_dash(cooldown: float = dash_cooldown, times: int = times_can_dash):
	can_dash =  cooldown > 0 and times_can_dash > 0
	times_can_dash = times

func _create_dash_cooldown_timer(time: float = dash_cooldown):
	var dash_cooldown_timer: Timer = Timer.new()

	dash_cooldown_timer.process_callback = Timer.TIMER_PROCESS_PHYSICS
	dash_cooldown_timer.wait_time = max(0.05, time)
	dash_cooldown_timer.one_shot = true
	dash_cooldown_timer.autostart = true
	
	add_child(dash_cooldown_timer)
	dash_cooldown_timer.timeout.connect(on_dash_cooldown_timer_timeout.bind(dash_cooldown_timer))

func on_dash_cooldown_timer_timeout(timer: Timer):
	dash_queue.pop_back()
	can_dash = dash_queue.size() < times_can_dash
	
	timer.queue_free()

