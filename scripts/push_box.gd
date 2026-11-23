extends RigidBody2D
class_name PushBox

const GRAVITY_ACCELERATION := 980.0
const PLAYER_PUSH_HOLD_SECONDS := 0.2
const SUPPORT_HOLD_SECONDS := 0.08

@export var gravity_manager_path: NodePath
@export var box_id := 1
@export var hold_position_when_supported_by_player := false

var _gravity_manager: Node
var gravity_direction := Vector2.DOWN
var _player_push_hold_left := 0.0
var _support_hold_left := 0.0
var _support_player: Player


func _ready() -> void:
	_gravity_manager = get_node_or_null(gravity_manager_path)

	if _gravity_manager:
		_gravity_manager.rotation_finished.connect(_on_gravity_rotation_finished)
		set_gravity(_gravity_manager.current_gravity)


func _physics_process(delta: float) -> void:
	if hold_position_when_supported_by_player:
		_update_player_support(delta)
		if is_instance_valid(_support_player):
			constant_force = Vector2.ZERO
			linear_velocity = Vector2.ZERO
			return

	constant_force = gravity_direction * GRAVITY_ACCELERATION * mass
	_player_push_hold_left = maxf(0.0, _player_push_hold_left - delta)

	if _player_push_hold_left <= 0.0 and not _is_touching_player():
		stop_player_push()


func _update_player_support(delta: float) -> void:
	if is_instance_valid(_support_player):
		if _is_player_in_support_zone(_support_player):
			_support_hold_left = SUPPORT_HOLD_SECONDS
			return

		_support_hold_left = maxf(0.0, _support_hold_left - delta)
		if _support_hold_left <= 0.0:
			_end_player_support()
		return

	var supporting_player := _find_supporting_player()
	if supporting_player:
		_support_player = supporting_player
		_support_hold_left = SUPPORT_HOLD_SECONDS
		_support_player.add_collision_exception_with(self)
		add_collision_exception_with(_support_player)
		freeze = true
		return

func _is_touching_player() -> bool:
	for body in get_colliding_bodies():
		if body is CharacterBody2D:
			return true

	return false


func _find_supporting_player() -> Player:
	for body in get_colliding_bodies():
		if not body is Player:
			continue

		var player_offset := body.global_position - global_position
		if player_offset.dot(gravity_direction) > 4.0:
			return body

	return null


func _is_player_in_support_zone(player: Player) -> bool:
	var player_offset := player.global_position - global_position
	var lateral_axis := gravity_direction.orthogonal()
	var along_gravity := player_offset.dot(gravity_direction)
	var lateral_distance := absf(player_offset.dot(lateral_axis))
	return along_gravity > 4.0 and along_gravity < 110.0 and lateral_distance < 60.0


func _end_player_support() -> void:
	if not is_instance_valid(_support_player):
		_support_player = null
		return

	_support_player.remove_collision_exception_with(self)
	remove_collision_exception_with(_support_player)
	_support_player = null
	freeze = false


func set_gravity(new_gravity_direction: Vector2) -> void:
	_end_player_support()
	gravity_direction = new_gravity_direction
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0


func apply_player_push(push_direction: Vector2, push_speed: float) -> void:
	if push_direction.is_zero_approx() or push_speed <= 0.0:
		return

	_player_push_hold_left = PLAYER_PUSH_HOLD_SECONDS
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
