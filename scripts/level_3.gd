extends Node2D

const INNER_WORLD_SCENE := "res://scenes/level_3_inner_1.tscn"
const FINAL_SCENE := "res://scenes/level_4_placeholder.tscn"

@onready var player: Player = $Player
@onready var gravity_manager: GravityManager = $GravityManager
@onready var folder_visuals: Node2D = $FolderVisuals
@onready var folder_areas: Array[Area2D] = [
	$FolderAreas/Upper as Area2D,
	$FolderAreas/Lower as Area2D,
]
@onready var exit_area: Area2D = $ExitArea
@onready var exit_visual: Sprite2D = $ExitArea/Visual
@onready var hint_label: Label = $HUD/UIRoot/HintLabel

var _folder_contact_areas: Dictionary = {}
var _folder_in_range := false
var _folder_collected := false
var _level_finished := false


func _ready() -> void:
	player.set_gravity(gravity_manager.current_gravity, gravity_manager.get_screen_right())
	gravity_manager.rotation_unlocked = true
	gravity_manager.rotation_started.connect(_on_rotation_started)
	gravity_manager.rotation_finished.connect(_on_rotation_finished)
	for area in folder_areas:
		area.body_entered.connect(_on_folder_body_entered.bind(area))
		area.body_exited.connect(_on_folder_body_exited.bind(area))
	exit_area.body_entered.connect(_on_exit_body_entered)

	if LevelRouter.level_3_condition_collected:
		_restore_collected_state()
	else:
		folder_visuals.visible = true
		exit_area.visible = false
		hint_label.text = "A / D 移动　W 跳跃　空格旋转　靠近文件夹按 E"


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		LevelRouter.goto_scene("res://scenes/main_menu.tscn")
		return

	if _level_finished:
		return

	if event.is_action_pressed("interact") and _folder_in_range and not _folder_collected:
		_collect_folder()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("space_rotate"):
		gravity_manager.try_rotate()


func _on_rotation_started(_target_gravity: Vector2, _target_index: int) -> void:
	player.control_enabled = false
	player.begin_visual_rotation(float(gravity_manager.rotation_direction))


func _on_rotation_finished(current_gravity: Vector2, _current_index: int) -> void:
	gravity_manager.current_gravity = current_gravity
	player.set_gravity(current_gravity, gravity_manager.get_screen_right())
	player.control_enabled = not _level_finished


func _on_folder_body_entered(body: Node2D, area: Area2D) -> void:
	if body != player or _folder_collected or _level_finished:
		return

	_folder_contact_areas[area] = true
	_folder_in_range = true
	hint_label.text = "按 E 拾取文件夹"


func _on_folder_body_exited(body: Node2D, area: Area2D) -> void:
	if body != player or _folder_collected or _level_finished:
		return

	_folder_contact_areas.erase(area)
	_folder_in_range = not _folder_contact_areas.is_empty()
	if not _folder_in_range:
		hint_label.text = "A / D 移动　W 跳跃　空格旋转　靠近文件夹按 E"


func _collect_folder() -> void:
	if _folder_collected or not _folder_in_range:
		return

	_folder_collected = true
	LevelRouter.level_3_condition_collected = true
	_folder_in_range = false
	_folder_contact_areas.clear()
	folder_visuals.visible = false
	for area in folder_areas:
		area.set_deferred("monitoring", false)
		for child in area.get_children():
			if child is CollisionShape2D:
				child.set_deferred("disabled", true)
	exit_area.visible = true
	exit_area.modulate = Color(1.0, 1.0, 1.0, 0.0)
	create_tween().tween_property(exit_area, "modulate:a", 1.0, 0.25)
	hint_label.text = "已获得通关条件，进入绿色出口"


func _restore_collected_state() -> void:
	_folder_collected = true
	_folder_in_range = false
	_folder_contact_areas.clear()
	folder_visuals.visible = false
	for area in folder_areas:
		area.set_deferred("monitoring", false)
		for child in area.get_children():
			if child is CollisionShape2D:
				child.set_deferred("disabled", true)
	exit_area.visible = true
	exit_area.modulate = Color.WHITE
	hint_label.text = "通关条件已取得，进入绿色出口"


func _on_exit_body_entered(body: Node2D) -> void:
	if body != player or not _folder_collected or _level_finished:
		return

	_level_finished = true
	player.control_enabled = false
	gravity_manager.rotation_unlocked = false
	if LevelRouter.level_3_inner1_completed:
		hint_label.text = "表世界已恢复，正在进入第四关"
		LevelRouter.goto_scene(FINAL_SCENE)
	else:
		hint_label.text = "表世界完成，正在进入里世界一"
		LevelRouter.goto_scene(INNER_WORLD_SCENE)
