extends Node2D

const TABLE_SCENE := "res://scenes/level_3.tscn"
const REPAIR_DURATION := 2.4
const ROTATIONS_UNTIL_DROP := 2
const INITIAL_DROP_TIMEOUT := 5.0
const PUSH_TARGET_X := 790.0
const PUSH_TARGET_Y := 716.0
const PUSH_TARGET_Y_TOLERANCE := 16.0

@onready var player: Player = $Player
@onready var gravity_manager: GravityManager = $GravityManager
@onready var png_box: PushBox = $PNGBox
@onready var png_interaction_area: Area2D = $PNGBox/InteractionArea
@onready var log_visual: Sprite2D = $LogVisual
@onready var log_area: Area2D = $LogArea
@onready var return_area: Area2D = $ReturnArea
@onready var return_visual: Sprite2D = $ReturnArea/Visual
@onready var preview_panel: Panel = $HUD/UIRoot/PreviewPanel
@onready var preview_status: Label = $HUD/UIRoot/PreviewPanel/Status
@onready var repair_panel: Panel = $HUD/UIRoot/RepairPanel
@onready var repair_label: Label = $HUD/UIRoot/RepairPanel/Title
@onready var repair_progress: ProgressBar = $HUD/UIRoot/RepairPanel/Progress
@onready var hint_label: Label = $HUD/UIRoot/HintLabel

var _initial_drop_started := false
var _initial_png_dropped := false
var _initial_drop_elapsed := 0.0
var _png_selected := false
var _log_discovered := false
var _repair_started := false
var _repair_done := false
var _repair_elapsed := 0.0
var _rotations_after_repair := 0
var _png_released := false
var _return_armed := false
var _level_finished := false
var _png_in_range := false
var _return_in_range := false
var _pulse_elapsed := 0.0


func _ready() -> void:
	player.set_gravity(gravity_manager.current_gravity, gravity_manager.get_screen_right())
	gravity_manager.rotation_unlocked = true
	gravity_manager.rotation_started.connect(_on_rotation_started)
	gravity_manager.rotation_finished.connect(_on_rotation_finished)
	png_interaction_area.body_entered.connect(_on_png_body_entered)
	png_interaction_area.body_exited.connect(_on_png_body_exited)
	log_area.body_entered.connect(_on_log_body_entered)
	return_area.body_entered.connect(_on_return_body_entered)
	return_area.body_exited.connect(_on_return_body_exited)

	png_interaction_area.monitoring = false
	log_area.monitoring = false
	log_visual.visible = false
	png_box.freeze = true
	png_box.gravity_scale = 0.0
	png_box.collision_layer = 0
	png_box.collision_mask = 0
	return_visual.visible = false
	preview_panel.visible = false
	repair_panel.visible = false
	repair_progress.value = 0.0
	_update_hint()


func _process(delta: float) -> void:
	if _initial_drop_started and not _initial_png_dropped:
		_initial_drop_elapsed += delta
		if _initial_drop_elapsed >= INITIAL_DROP_TIMEOUT:
			_finish_initial_png_drop()

	if _repair_started and not _repair_done:
		_repair_elapsed += delta
		repair_progress.value = clampf(_repair_elapsed / REPAIR_DURATION * 100.0, 0.0, 100.0)
		if _repair_elapsed >= REPAIR_DURATION:
			_finish_repair()

	if return_visual.visible:
		_pulse_elapsed += delta
		var pulse := 1.0 + sin(_pulse_elapsed * 5.0) * 0.06
		return_visual.scale = Vector2.ONE * 0.55 * pulse


func _physics_process(_delta: float) -> void:
	if (
		_png_released
		and not _return_armed
		and png_box.global_position.x >= PUSH_TARGET_X
		and absf(png_box.global_position.y - PUSH_TARGET_Y) <= PUSH_TARGET_Y_TOLERANCE
	):
		_arm_return()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		LevelRouter.goto_scene("res://scenes/main_menu.tscn")
		return

	if _level_finished:
		return

	if event.is_action_pressed("interact"):
		if _png_in_range and _initial_png_dropped and not _png_selected:
			_select_png()
			get_viewport().set_input_as_handled()
			return
		if _log_discovered and _png_selected and not _repair_started:
			_start_repair()
			get_viewport().set_input_as_handled()
			return
		if _return_in_range and _return_armed:
			_request_return()
			get_viewport().set_input_as_handled()
			return

	if event.is_action_pressed("space_rotate") and not (_repair_started and not _repair_done):
		gravity_manager.try_rotate()


func _on_rotation_started(_target_gravity: Vector2, _target_index: int) -> void:
	player.control_enabled = false
	player.begin_visual_rotation(float(gravity_manager.rotation_direction))


func _on_rotation_finished(current_gravity: Vector2, _current_index: int) -> void:
	gravity_manager.current_gravity = current_gravity
	player.set_gravity(current_gravity, gravity_manager.get_screen_right())

	if not _initial_drop_started:
		_start_initial_png_drop(current_gravity)
		return

	player.control_enabled = not _level_finished
	if _repair_done and not _png_released:
		_rotations_after_repair += 1
		if _rotations_after_repair >= ROTATIONS_UNTIL_DROP:
			_release_png()
		else:
			_update_hint()


func _start_initial_png_drop(current_gravity: Vector2) -> void:
	_initial_drop_started = true
	_initial_drop_elapsed = 0.0
	gravity_manager.rotation_unlocked = false
	player.control_enabled = false
	player.gravity_scale = 0.0
	player.velocity = Vector2.ZERO

	png_box.set_gravity(current_gravity)
	png_box.collision_layer = 4
	png_box.collision_mask = 3
	png_box.gravity_scale = 1.0
	png_box.linear_velocity = Vector2.ZERO
	png_box.angular_velocity = 0.0
	png_box.freeze = false
	png_box.sleeping = false
	png_interaction_area.set_deferred("monitoring", true)
	_update_hint()


func _finish_initial_png_drop() -> void:
	if not _initial_drop_started or _initial_png_dropped or _level_finished:
		return

	_initial_png_dropped = true
	png_box.freeze = true
	png_box.linear_velocity = Vector2.ZERO
	png_box.angular_velocity = 0.0
	png_box.gravity_scale = 0.0
	png_box.collision_layer = 0
	png_box.collision_mask = 0
	png_interaction_area.set_deferred("monitoring", true)
	player.gravity_scale = 1.0
	player.control_enabled = true
	gravity_manager.rotation_unlocked = true
	_update_hint()


func _select_png() -> void:
	if not _initial_png_dropped or _png_selected or _level_finished:
		return

	_png_selected = true
	_png_in_range = false
	preview_panel.visible = true
	preview_status.text = "PNG 已选中，LOG 已出现"
	png_box.modulate = Color(1.0, 0.92, 0.62, 1.0)
	log_visual.visible = true
	log_visual.modulate = Color(1.0, 1.0, 1.0, 0.0)
	create_tween().tween_property(log_visual, "modulate:a", 1.0, 0.22)
	log_area.set_deferred("monitoring", true)
	_update_hint()


func _start_repair() -> void:
	if not _png_selected or not _log_discovered or _repair_started or _level_finished:
		return

	_repair_started = true
	_repair_elapsed = 0.0
	gravity_manager.rotation_unlocked = false
	repair_panel.visible = true
	repair_label.text = "REPAIRING"
	repair_progress.value = 0.0
	_update_hint()


func _finish_repair() -> void:
	if _repair_done:
		return

	_repair_done = true
	_repair_elapsed = REPAIR_DURATION
	repair_progress.value = 100.0
	repair_label.text = "DONE"
	repair_panel.self_modulate = Color(0.64, 1.0, 0.72, 1.0)
	preview_status.text = "PNG / DONE"
	_rotations_after_repair = 0
	gravity_manager.rotation_unlocked = not _level_finished
	_update_hint()


func _release_png() -> void:
	if _png_released:
		return

	_png_released = true
	png_box.modulate = Color.WHITE
	png_box.set_gravity(gravity_manager.current_gravity)
	png_box.collision_layer = 4
	png_box.collision_mask = 3
	png_box.gravity_scale = 1.0
	png_box.linear_velocity = Vector2.ZERO
	png_box.angular_velocity = 0.0
	png_box.freeze = false
	png_box.sleeping = false
	_update_hint()


func _arm_return() -> void:
	if _return_armed:
		return

	_return_armed = true
	return_visual.visible = true
	return_visual.modulate = Color(1.0, 1.0, 1.0, 0.0)
	return_visual.scale = Vector2.ONE * 0.35
	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(return_visual, "modulate:a", 1.0, 0.2)
	tween.tween_property(return_visual, "scale", Vector2.ONE * 0.55, 0.24)
	_update_hint()


func _request_return() -> void:
	if not _return_armed or _level_finished:
		return

	_level_finished = true
	player.control_enabled = false
	gravity_manager.rotation_unlocked = false
	LevelRouter.level_3_inner1_completed = true
	hint_label.text = "修复完成，正在返回表世界"
	LevelRouter.goto_scene(TABLE_SCENE)


func _on_png_body_entered(body: Node2D) -> void:
	if body != player or _png_selected or _level_finished:
		return

	_png_in_range = true
	if _initial_drop_started and not _initial_png_dropped:
		call_deferred("_finish_initial_png_drop")
		return

	_update_hint()


func _on_png_body_exited(body: Node2D) -> void:
	if body != player:
		return

	_png_in_range = false
	_update_hint()


func _on_log_body_entered(body: Node2D) -> void:
	if body != player or not _png_selected or _repair_started or _level_finished:
		return

	_log_discovered = true
	_update_hint()


func _on_return_body_entered(body: Node2D) -> void:
	if body != player:
		return

	_return_in_range = true
	_update_hint()


func _on_return_body_exited(body: Node2D) -> void:
	if body != player:
		return

	_return_in_range = false
	_update_hint()


func _update_hint() -> void:
	if _level_finished:
		return
	if _initial_drop_started and not _initial_png_dropped:
		hint_label.text = "PNG 正在沿旋转后的重力方向掉落"
		return
	if _repair_started and not _repair_done:
		hint_label.text = "正在修复选中的 PNG，请等待进度完成"
		return
	if _repair_done and not _png_released:
		var remaining := ROTATIONS_UNTIL_DROP - _rotations_after_repair
		hint_label.text = "修复完成　还需旋转 %d 次，让 PNG 掉落" % remaining
		return
	if _png_released and not _return_armed:
		hint_label.text = "按住 E 并移动，把 PNG 推到右下障碍物旁"
		return
	if _return_armed and _return_in_range:
		hint_label.text = "按 E 返回表世界"
		return
	if _return_armed:
		hint_label.text = "已搭好踏板，登上中央高台按 E 返回"
		return
	if _png_selected and _log_discovered:
		hint_label.text = "按 E 打开 LOG 修复 PNG"
		return
	if _png_selected:
		hint_label.text = "再次旋转场景，靠近左上方的 LOG"
		return
	if _initial_png_dropped and _png_in_range:
		hint_label.text = "按 E 选中 PNG"
		return
	if _initial_png_dropped:
		hint_label.text = "PNG 已掉落，靠近后按 E 选中"
		return
	hint_label.text = "空格旋转场景，让左平台上的 PNG 掉下来"
