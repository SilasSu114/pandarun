extends RigidBody2D
class_name PushBox

const GRAVITY_ACCELERATION := 980.0

@export var gravity_manager_path: NodePath
@export var box_id := 1

var _gravity_manager: Node
var gravity_direction := Vector2.DOWN


func _ready() -> void:
	_gravity_manager = get_node_or_null(gravity_manager_path)

	if _gravity_manager:
		_gravity_manager.rotation_finished.connect(_on_gravity_rotation_finished)
		set_gravity(_gravity_manager.current_gravity)


func _physics_process(_delta: float) -> void:
	constant_force = gravity_direction * GRAVITY_ACCELERATION * mass

	if not _is_touching_player():
		stop_player_push()


func _is_touching_player() -> bool:
	for body in get_colliding_bodies():
		if body is CharacterBody2D:
			return true

	return false


func set_gravity(new_gravity_direction: Vector2) -> void:
	gravity_direction = new_gravity_direction
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0


func apply_player_push(push_direction: Vector2, push_speed: float) -> void:
	if push_direction.is_zero_approx() or push_speed <= 0.0:
		return

	var gravity_speed := maxf(0.0, linear_velocity.dot(gravity_direction))
	linear_velocity = push_direction.normalized() * push_speed + gravity_direction * gravity_speed


func stop_player_push() -> void:
	var gravity_speed := linear_velocity.dot(gravity_direction)

	if absf(gravity_speed) < 1.0:
		linear_velocity = Vector2.ZERO
	else:
		linear_velocity = gravity_direction * gravity_speed


func _on_gravity_rotation_finished(current_gravity: Vector2, _current_index: int) -> void:
	set_gravity(current_gravity)
