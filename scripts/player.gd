extends CharacterBody2D
class_name Player

signal teaching_obstacle_touched(obstacle: Node)

const GRAVITY_ACCELERATION := 980.0
const VISUAL_ROTATION_STEP_DEGREES := 90.0
const VISUAL_LEAN_DEGREES := 3.0
const MOVE_AXIS_DEADZONE := 0.1

@export var move_speed := 240.0
@export var jump_velocity := 480.0
@export var gravity_scale := 1.0
@export var control_enabled := true

var gravity_vector := Vector2.DOWN
var screen_right := Vector2.RIGHT

var _lateral_velocity := 0.0
var _vertical_velocity := 0.0
var _facing_direction := 1.0
var _target_visual_lean_degrees := 0.0
var _touched_obstacles: Array[Node] = []
var _visual_rotation_tween: Tween
var _visual_lean_tween: Tween

@onready var _visual_pivot: Node2D = $VisualPivot
@onready var _visual: AnimatedSprite2D = $VisualPivot/Visual
@onready var _push_sensor: Area2D = $PushSensor


func _ready() -> void:
	set_gravity(gravity_vector, screen_right)
	_visual.play("idle")


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
	_update_facing(move_axis)
	_update_visual()
	_update_visual_lean(move_axis)
	_update_push_box_contact(move_axis)
	_report_teaching_obstacles()


func _update_facing(move_axis: float) -> void:
	if absf(move_axis) <= MOVE_AXIS_DEADZONE:
		return

	_facing_direction = 1.0 if move_axis > 0.0 else -1.0
	_visual.flip_h = _facing_direction > 0.0


func _update_visual() -> void:
	var target_anim := "idle"
	if not is_on_floor():
		target_anim = "jump"
	elif absf(_lateral_velocity) > 1.0:
		target_anim = "walk"

	if _visual.animation != StringName(target_anim):
		_visual.play(target_anim)


func _update_visual_lean(move_axis: float) -> void:
	var target_lean := 0.0
	if absf(move_axis) > MOVE_AXIS_DEADZONE and is_on_floor():
		target_lean = VISUAL_LEAN_DEGREES * _facing_direction

	if is_equal_approx(target_lean, _target_visual_lean_degrees):
		return

	_target_visual_lean_degrees = target_lean
	if _visual_lean_tween and _visual_lean_tween.is_valid():
		_visual_lean_tween.kill()

	_visual_lean_tween = create_tween()
	_visual_lean_tween.set_trans(Tween.TRANS_SINE)
	_visual_lean_tween.set_ease(Tween.EASE_OUT)
	_visual_lean_tween.tween_property(
		_visual,
		"rotation_degrees",
		_target_visual_lean_degrees,
		0.16
	)


func _report_teaching_obstacles() -> void:
	for collision_index in get_slide_collision_count():
		var collider := get_slide_collision(collision_index).get_collider()
		if not collider or not collider.is_in_group("teaching_obstacle"):
			continue

		if not _touched_obstacles.has(collider):
			_touched_obstacles.append(collider)
			teaching_obstacle_touched.emit(collider)


func begin_visual_rotation(direction: float = 1.0) -> void:
	if _visual_rotation_tween and _visual_rotation_tween.is_valid():
		_visual_rotation_tween.kill()

	_visual_rotation_tween = create_tween()
	_visual_rotation_tween.set_trans(Tween.TRANS_SINE)
	_visual_rotation_tween.set_ease(Tween.EASE_IN_OUT)
	_visual_rotation_tween.tween_property(
		_visual_pivot,
		"rotation_degrees",
		_visual_pivot.rotation_degrees + VISUAL_ROTATION_STEP_DEGREES * direction,
		GravityManager.ROTATION_DURATION
	)


func _update_push_box_contact(move_axis: float) -> void:
	var push_boxes: Array[Node] = []
	for body in _push_sensor.get_overlapping_bodies():
		if body.is_in_group("push_box") and _can_push_box(body):
			push_boxes.append(body)

	for collision_index in get_slide_collision_count():
		var collision := get_slide_collision(collision_index)
		var collider := collision.get_collider()

		if not collider or not collider.is_in_group("push_box") or not _can_push_box(collider):
			continue

		if not push_boxes.has(collider):
			push_boxes.append(collider)

	for box in push_boxes:
		if box.get("requires_interact_push") == true and not Input.is_action_pressed("interact"):
			box.stop_player_push()
			continue
		if is_zero_approx(move_axis):
			box.stop_player_push()
		else:
			var push_direction := screen_right * signf(move_axis)
			var push_speed := absf(move_axis) * move_speed
			box.apply_player_push(push_direction, push_speed)


func _can_push_box(box: Node2D) -> bool:
	var pointer_offset := box.global_position - global_position
	var along_gravity := absf(pointer_offset.dot(gravity_vector))
	var box_half_extent := _collision_half_extent(box, gravity_vector)
	var player_half_extent := _collision_half_extent(self, gravity_vector)

	if box_half_extent <= 0.0 or player_half_extent <= 0.0:
		return along_gravity < 8.0

	return along_gravity < box_half_extent + player_half_extent - 2.0


func _collision_half_extent(node: Node2D, axis: Vector2) -> float:
	var collision := node.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision == null:
		return 0.0

	var rectangle := collision.shape as RectangleShape2D
	if rectangle == null:
		return 0.0

	var local_axis := axis.rotated(-node.global_rotation)
	var half_size := rectangle.size * 0.5
	return absf(local_axis.x) * half_size.x + absf(local_axis.y) * half_size.y
