extends Node
class_name GravityManager

signal rotation_started(target_gravity: Vector2, target_index: int)
signal rotation_finished(current_gravity: Vector2, current_index: int)

const ROTATION_DURATION := 0.35
const GRAVITY_DIRECTIONS: Array[Vector2] = [
	Vector2.DOWN,
	Vector2.LEFT,
	Vector2.UP,
	Vector2.RIGHT,
]

@export var camera_path: NodePath
@export var ui_root_path: NodePath
@export var enable_runtime_asserts := true

var camera: Camera2D
var ui_root: Control

var rotation_index := 0
var rotation_unlocked := false
var current_gravity := Vector2.DOWN
var is_rotating := false
var visual_rotation_degrees := 0.0
var target_visual_rotation_degrees := 0.0
var target_gravity := Vector2.ZERO
var _rotation_tween: Tween


func _ready() -> void:
	camera = get_node_or_null(camera_path) as Camera2D
	ui_root = get_node_or_null(ui_root_path) as Control

	if enable_runtime_asserts:
		assert(is_instance_valid(camera), "GravityManager.camera is not assigned")
		assert(is_instance_valid(ui_root), "GravityManager.ui_root is not assigned")

	visual_rotation_degrees = float(rotation_index) * 90.0
	target_visual_rotation_degrees = visual_rotation_degrees

	if is_instance_valid(camera):
		camera.ignore_rotation = false
		camera.make_current()
		camera.rotation_degrees = visual_rotation_degrees
		camera.reset_smoothing()

	if is_instance_valid(ui_root):
		ui_root.pivot_offset = ui_root.size * 0.5
		ui_root.rotation_degrees = visual_rotation_degrees


func try_rotate() -> bool:
	if not rotation_unlocked or is_rotating:
		return false

	camera = get_node_or_null(camera_path) as Camera2D
	ui_root = get_node_or_null(ui_root_path) as Control

	if enable_runtime_asserts:
		assert(is_instance_valid(camera), "GravityManager.camera is not assigned")
		assert(is_instance_valid(ui_root), "GravityManager.ui_root is not assigned")

	if not is_instance_valid(camera) or not is_instance_valid(ui_root):
		return false

	rotation_index = (rotation_index + 1) % GRAVITY_DIRECTIONS.size()
	target_gravity = GRAVITY_DIRECTIONS[rotation_index]
	visual_rotation_degrees += 90.0
	target_visual_rotation_degrees = visual_rotation_degrees
	is_rotating = true

	camera.ignore_rotation = false
	camera.make_current()
	ui_root.pivot_offset = ui_root.size * 0.5

	_rotation_tween = create_tween()
	_rotation_tween.set_parallel(true)
	_rotation_tween.set_trans(Tween.TRANS_SINE)
	_rotation_tween.set_ease(Tween.EASE_IN_OUT)
	_rotation_tween.tween_property(
		camera,
		"rotation_degrees",
		target_visual_rotation_degrees,
		ROTATION_DURATION
	)
	_rotation_tween.tween_property(
		ui_root,
		"rotation_degrees",
		target_visual_rotation_degrees,
		ROTATION_DURATION
	)
	_rotation_tween.finished.connect(_on_rotation_tween_finished)

	rotation_started.emit(target_gravity, rotation_index)
	return true


func _on_rotation_tween_finished() -> void:
	current_gravity = target_gravity
	visual_rotation_degrees = target_visual_rotation_degrees
	camera.rotation_degrees = visual_rotation_degrees
	camera.reset_smoothing()
	ui_root.rotation_degrees = visual_rotation_degrees
	is_rotating = false
	rotation_finished.emit(current_gravity, rotation_index)


func get_screen_right() -> Vector2:
	return Vector2.RIGHT.rotated(rotation_index * PI * 0.5)
