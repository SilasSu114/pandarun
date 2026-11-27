extends Node2D

const LEVEL_CENTER := Vector2(540.0, 540.0)
const BEAM_MAX_OFFSET := 430.0
const BEAM_SPEED := 250.0
const BEAM_SCAN_AXIS := Vector2.RIGHT
const BEAM_START_Y := -470.0
const BEAM_END_Y := 470.0
const TUTORIAL_DURATION := 1.8
const DEFEAT_ZOOM := Vector2(1.18, 1.18)

@onready var player: Player = $Player
@onready var gravity_manager: GravityManager = $GravityManager
@onready var camera: Camera2D = $Camera2D
@onready var pointer: PushBox = $PointerBody
@onready var folder_open_visual: Sprite2D = $FolderArea/OpenVisual
@onready var exit_area: Area2D = $ExitArea
@onready var exit_visual: Sprite2D = $ExitArea/Visual
@onready var background_mono: Sprite2D = $BackgroundMono
@onready var scan_beam: Area2D = $ScanBeam
@onready var beam_ray: RayCast2D = $ScanBeam/RayCast2D
@onready var beam_collision: CollisionShape2D = $ScanBeam/CollisionShape2D
@onready var beam_shape: RectangleShape2D = $ScanBeam/CollisionShape2D.shape
@onready var beam_glow: Line2D = $ScanBeam/Glow
@onready var beam_core: Line2D = $ScanBeam/Core
@onready var screen_flash: ColorRect = $UI/UIRoot/ScreenFlash

var _tutorial_started := false
var _tutorial_running := false
var _tutorial_elapsed := 0.0
var _folder_opened := false
var _exit_armed := false
var _level_finished := false
var _defeated := false
var _beam_armed := false
var _beam_offset := BEAM_MAX_OFFSET
var _beam_direction := -1.0
var _rotation_count := 0
var _invulnerability_left := 0.0
var _safe_position := Vector2.ZERO


func _ready() -> void:
	player.set_gravity(gravity_manager.current_gravity, gravity_manager.get_screen_right())
	gravity_manager.rotation_unlocked = false
	gravity_manager.rotation_started.connect(_on_rotation_started)
	gravity_manager.rotation_finished.connect(_on_rotation_finished)
	$BeamTutorialTrigger.body_entered.connect(_on_tutorial_body_entered)
	$FolderArea.body_entered.connect(_on_folder_body_entered)
	exit_area.body_entered.connect(_on_exit_body_entered)
	scan_beam.body_entered.connect(_on_beam_body_entered)
	_safe_position = player.global_position
	_update_beam_transform()
	_update_beam_geometry()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		LevelRouter.goto_scene("res://scenes/main_menu.tscn")
		return

	if _level_finished or _defeated or _tutorial_running:
		return

	if event.is_action_pressed("space_rotate"):
		gravity_manager.try_rotate()


func _physics_process(delta: float) -> void:
	if _level_finished or _defeated:
		return

	_invulnerability_left = maxf(0.0, _invulnerability_left - delta)

	if _tutorial_running:
		_tutorial_elapsed += delta
		var progress := clampf(_tutorial_elapsed / TUTORIAL_DURATION, 0.0, 1.0)
		_beam_offset = lerpf(BEAM_MAX_OFFSET, -BEAM_MAX_OFFSET, progress)
		_update_beam_transform()
		_update_beam_geometry()
		if progress >= 1.0:
			_finish_tutorial()
		return

	if not scan_beam.visible:
		return

	_beam_offset += _beam_direction * BEAM_SPEED * delta
	if _beam_offset <= -BEAM_MAX_OFFSET:
		_beam_offset = -BEAM_MAX_OFFSET
		_beam_direction = 1.0
	elif _beam_offset >= BEAM_MAX_OFFSET:
		_beam_offset = BEAM_MAX_OFFSET
		_beam_direction = -1.0

	_update_beam_transform()
	_update_beam_geometry()

	if _beam_armed and _invulnerability_left <= 0.0 and scan_beam.get_overlapping_bodies().has(player):
		_request_defeat()


func _on_tutorial_body_entered(body: Node2D) -> void:
	if body != player or _tutorial_started or _level_finished:
		return

	_tutorial_started = true
	_tutorial_running = true
	_tutorial_elapsed = 0.0
	_beam_offset = BEAM_MAX_OFFSET
	_beam_direction = -1.0
	_beam_armed = false
	background_mono.visible = true
	scan_beam.visible = true
	player.control_enabled = false
	player.set_physics_process(false)
	gravity_manager.rotation_unlocked = false
	_update_beam_transform()
	_update_beam_geometry()


func _finish_tutorial() -> void:
	_tutorial_running = false
	_beam_direction = 1.0
	_beam_armed = true
	_invulnerability_left = 0.8
	_safe_position = player.global_position
	player.set_physics_process(true)
	player.control_enabled = true
	gravity_manager.rotation_unlocked = true


func _on_rotation_started(_target_gravity: Vector2, _target_index: int) -> void:
	player.control_enabled = false
	player.begin_visual_rotation(float(gravity_manager.rotation_direction))


func _on_rotation_finished(current_gravity: Vector2, _current_index: int) -> void:
	gravity_manager.current_gravity = current_gravity
	player.set_gravity(current_gravity, gravity_manager.get_screen_right())
	player.control_enabled = not _defeated and not _level_finished
	_rotation_count += 1

	_exit_armed = _folder_opened and _rotation_count >= 2
	scan_beam.visible = _tutorial_started
	_beam_armed = _tutorial_started and not _tutorial_running and not _defeated
	if not _defeated:
		_safe_position = player.global_position
		_invulnerability_left = 0.8
	_update_beam_transform()
	_update_beam_geometry()


func _on_folder_body_entered(body: Node2D) -> void:
	if body != pointer or _folder_opened or _level_finished:
		return

	_folder_opened = true
	pointer.visible = false
	pointer.set_deferred("freeze", true)
	pointer.set_deferred("collision_layer", 0)
	pointer.set_deferred("collision_mask", 0)
	folder_open_visual.visible = true
	folder_open_visual.scale = Vector2.ONE * 0.35
	create_tween().tween_property(folder_open_visual, "scale", Vector2.ONE * 0.55, 0.18)
	exit_visual.visible = true
	exit_visual.modulate = Color(1.0, 1.0, 1.0, 0.0)
	create_tween().tween_property(exit_visual, "modulate:a", 1.0, 0.25)
	_exit_armed = _rotation_count >= 2


func _on_exit_body_entered(body: Node2D) -> void:
	if body != player or not _exit_armed or _level_finished or _defeated:
		return

	_level_finished = true
	_beam_armed = false
	scan_beam.visible = false
	player.control_enabled = false
	player.set_physics_process(false)
	gravity_manager.rotation_unlocked = false
	screen_flash.color = Color(1.0, 1.0, 1.0, 0.0)
	var tween := create_tween()
	tween.tween_property(screen_flash, "color:a", 1.0, 0.12)
	await tween.finished
	LevelRouter.goto_scene("res://scenes/level_3.tscn")


func _on_beam_body_entered(body: Node2D) -> void:
	if body != player:
		return
	_request_defeat()


func _request_defeat() -> void:
	if not _beam_armed or _defeated or _level_finished or _invulnerability_left > 0.0:
		return
	_defeated = true
	call_deferred("_run_defeat")


func _run_defeat() -> void:
	_beam_armed = false
	player.control_enabled = false
	player.set_physics_process(false)
	if not _folder_opened:
		pointer.freeze = true
	player.modulate = Color(1.0, 0.25, 0.3, 1.0)
	screen_flash.color = Color(1.0, 0.08, 0.12, 0.0)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(camera, "global_position", player.global_position, 0.18)
	tween.tween_property(camera, "zoom", DEFEAT_ZOOM, 0.18)
	tween.tween_property(screen_flash, "color:a", 0.32, 0.08)
	tween.chain().tween_interval(0.35)
	tween.chain().tween_property(screen_flash, "color:a", 0.0, 0.12)
	await tween.finished

	player.global_position = _safe_position
	player.set_gravity(gravity_manager.current_gravity, gravity_manager.get_screen_right())
	player.modulate = Color.WHITE
	camera.global_position = LEVEL_CENTER
	camera.zoom = Vector2.ONE
	if not _folder_opened:
		pointer.freeze = false
	player.set_physics_process(true)
	player.control_enabled = true
	_beam_offset = -BEAM_MAX_OFFSET if _rotation_count >= 2 else BEAM_MAX_OFFSET
	_beam_direction = 1.0 if _rotation_count >= 2 else -1.0
	_invulnerability_left = 1.0
	_defeated = false
	_beam_armed = true
	_update_beam_transform()
	_update_beam_geometry()


func _update_beam_transform() -> void:
	scan_beam.global_position = LEVEL_CENTER + BEAM_SCAN_AXIS * _beam_offset
	scan_beam.global_rotation = 0.0


func _update_beam_geometry() -> void:
	beam_ray.force_raycast_update()
	var end_y := BEAM_END_Y
	if beam_ray.is_colliding():
		end_y = clampf(scan_beam.to_local(beam_ray.get_collision_point()).y, BEAM_START_Y, BEAM_END_Y)

	var beam_length := maxf(1.0, end_y - BEAM_START_Y)
	beam_shape.size = Vector2(14.0, beam_length)
	beam_collision.position = Vector2(0.0, BEAM_START_Y + beam_length * 0.5)
	var points := PackedVector2Array([Vector2(0.0, BEAM_START_Y), Vector2(0.0, end_y)])
	beam_glow.points = points
	beam_core.points = points
