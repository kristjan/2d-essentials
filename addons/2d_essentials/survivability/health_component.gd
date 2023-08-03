@tool

class_name HealthComponent extends Node2D

signal health_changed(amount, type)
signal invulnerability_changed(active)
signal died

var invulnerability_timer: Timer
var health_regen_timer: Timer

@export_group("Health Parameters")
## The maximum health it can reach
@export var max_health: int = 100
## The actual health
@export var current_health: int = max_health
## The amount of health regenerated each second
@export var health_regen_per_second: int = 0
## The invulnerability flag, when is true no damage is received but can be healed
@export var is_invulnerable:bool = false
@export var invulnerability_time: float = 1.0

enum TYPES {
	DAMAGE,
	HEALTH,
	REGEN
}


func _ready():
	current_health = max(max_health, current_health)

	_create_health_regen_timer()
	_create_invulnerability_timer()
	enable_health_regen(health_regen_per_second)
	
	health_changed.connect(on_health_changed)


func damage(amount: int):
	if is_invulnerable: 
		amount = 0
	
	amount = absi(amount)
	
	current_health = max(0, current_health - amount)
	
	health_changed.emit(amount, TYPES.DAMAGE)


func health(amount: int, type: TYPES = TYPES.HEALTH):
	amount = absi(amount)
	current_health = min(max_health, current_health + amount)
	
	health_changed.emit(amount, type)
	
	
func check_is_dead() -> bool:
	var is_dead: bool = current_health == 0
	
	if is_dead:
		died.emit()

	return is_dead

func get_health_percent() -> float:
	return float(current_health) / max_health
	

func enable_invulnerability(enable: bool, time: float = 0.05):
	if enable:
		is_invulnerable = true
		
		if invulnerability_timer == null:
			_create_invulnerability_timer(time) 
		
		invulnerability_timer.start()
			
		invulnerability_changed.emit(true)
	else:
		is_invulnerable = false
		
		if invulnerability_timer:
			invulnerability_timer.stop()
		
		invulnerability_changed.emit(false)


func enable_health_regen(amount_per_second: int = health_regen_per_second):
	health_regen_per_second = amount_per_second
	
	if health_regen_timer:
		if current_health == max_health and health_regen_timer.time_left > 0:
			health_regen_timer.stop()
			return
		
		if health_regen_timer.is_stopped() and health_regen_per_second > 0:
			health_regen_timer.start()

func _create_health_regen_timer(time: float = 1.0):
	if health_regen_timer == null:
		var new_health_regen_timer: Timer = Timer.new()
		
		new_health_regen_timer.name = "HealthRegenTimer"
		new_health_regen_timer.wait_time = time
		new_health_regen_timer.one_shot = false
		
		health_regen_timer = new_health_regen_timer
		add_child(new_health_regen_timer)
		
		new_health_regen_timer.timeout.connect(on_health_regen_timer_timeout)

func _create_invulnerability_timer(time: float = invulnerability_time):
	if invulnerability_timer and invulnerability_timer.wait_time != time:
		invulnerability_timer.stop()
		invulnerability_timer.wait_time = time
	else:
		var new_invulnerability_timer: Timer = Timer.new()
		
		new_invulnerability_timer.name = "InvulnerabilityTimer"
		new_invulnerability_timer.wait_time = time
		new_invulnerability_timer.one_shot = true
		new_invulnerability_timer.autostart = false
		
		invulnerability_timer = new_invulnerability_timer
		add_child(new_invulnerability_timer)
		
		new_invulnerability_timer.timeout.connect(on_invulnerability_timer_timeout)
	
func on_health_changed(amount: int, type: TYPES):
	if type == TYPES.DAMAGE:
		enable_health_regen()
		Callable(check_is_dead).call_deferred()


func on_health_regen_timer_timeout():
	health(health_regen_per_second, TYPES.REGEN)
	
		
func on_invulnerability_timer_timeout():
	enable_invulnerability(false)
	invulnerability_changed.emit(false)

