extends CharacterBody2D
class_name Player

signal teaching_obstacle_touched(obstacle: Node)

const GRAVITY_ACCELERATION := 980.0

@export var move_speed := 240.0
@export var jump_velocity := 480.0
@export var gravity_scale := 1.0
@export var control_enabled := true

var gravity_vector := Vector2.DOWN
var screen_right := Vector2.RIGHT

var _lateral_velocity := 0.0
var _vertical_velocity := 0.0
var _touched_obstacles: Array[Node] = []


func _ready() -> void:
	set_gravity(gravity_vector, screen_right)


func set_gravity(new_gravity: Vector2, new_screen_right: Vector2) -> void:
	gravity_vector = new_gravity
	screen_right = new_screen_right
	up_direction = -gravity_vector
	velocity = Vector2.ZERO
	floor_snap_length = 0.0
	_lateral_velocity = 0.0
	_vertical_velocity = 1.0


func is_touching_teaching_obstacle() -> bool:
	for collision_index in get_slide_collision_count():
		var collider := get_slide_collision(collision_index).get_collider()
		if collider and collider.is_in_group("teaching_obstacle"):
			return true
	return false


func _physics_process(delta: float) -> void:
	var move_axis := 0.0

	if control_enabled:
		move_axis = Input.get_axis("move_left", "move_right")

	_lateral_velocity = move_axis * move_speed

	if control_enabled and Input.is_action_just_pressed("jump") and is_on_floor():
		_vertical_velocity = -jump_velocity

	_vertical_velocity += GRAVITY_ACCELERATION * gravity_scale * delta
	velocity = screen_right * _lateral_velocity + gravity_vector * _vertical_velocity
	move_and_slide()

	_lateral_velocity = velocity.dot(screen_right)
	_vertical_velocity = velocity.dot(gravity_vector)
	_update_push_box_contact(move_axis)
	_report_teaching_obstacles()


func _report_teaching_obstacles() -> void:
	for collision_index in get_slide_collision_count():
		var collider := get_slide_collision(collision_index).get_collider()
		if not collider or not collider.is_in_group("teaching_obstacle"):
			continue

		if not _touched_obstacles.has(collider):
			_touched_obstacles.append(collider)
			teaching_obstacle_touched.emit(collider)


func _update_push_box_contact(move_axis: float) -> void:
	for collision_index in get_slide_collision_count():
		var collision := get_slide_collision(collision_index)
		var collider := collision.get_collider()

		if not collider or not collider.is_in_group("push_box"):
			continue

		if is_zero_approx(move_axis):
			collider.stop_player_push()
			continue

		var push_direction := screen_right * signf(move_axis)
		var push_speed := absf(move_axis) * move_speed

		if collision.get_normal().dot(push_direction) > -0.25:
			continue

		collider.apply_player_push(push_direction, push_speed)
