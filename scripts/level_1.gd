extends Node2D

@onready var player: Player = $Player
@onready var gravity_manager: GravityManager = $GravityManager
@onready var condition_area: Area2D = $ConditionPickup
@onready var condition_bit_visual: Sprite2D = $ConditionPickup/Visual
@onready var condition_frame_body: StaticBody2D = $ConditionFrame
@onready var condition_card_visual: Sprite2D = $Obstacles/ConditionCard/Visual
@onready var exit_area: Area2D = $ExitArea
@onready var exit_visual: Sprite2D = $ExitArea/Visual
@onready var hint_label: Label = $TeachingLayer/HintLabel

var _rotation_unlocked := false
var _condition_collected := false
var _level_finished := false


func _ready() -> void:
	condition_area.body_entered.connect(_on_condition_body_entered)
	exit_area.body_entered.connect(_on_exit_body_entered)
	player.teaching_obstacle_touched.connect(_on_teaching_obstacle_touched)
	gravity_manager.rotation_started.connect(_on_rotation_started)
	gravity_manager.rotation_finished.connect(_on_rotation_finished)

	_set_player_gravity()
	hint_label.text = "左右移动：A / D    跳跃：W"


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		LevelRouter.goto_scene("res://scenes/main_menu.tscn")
		return

	if _level_finished:
		return

	if event.is_action_pressed("space_rotate"):
		if not gravity_manager.rotation_unlocked:
			hint_label.text = "碰到障碍后才会解锁场景旋转"
		elif gravity_manager.try_rotate():
			hint_label.text = "场景旋转中..."


func _set_player_gravity() -> void:
	player.set_gravity(gravity_manager.current_gravity, gravity_manager.get_screen_right())


func _on_teaching_obstacle_touched(_obstacle: Node) -> void:
	if _rotation_unlocked:
		return

	_rotation_unlocked = true
	gravity_manager.rotation_unlocked = true
	hint_label.text = "解锁场景旋转：按空格键越过走不通的高障碍"


func _on_rotation_started(_target_gravity: Vector2, _target_index: int) -> void:
	player.control_enabled = false
	player.begin_visual_rotation(float(gravity_manager.rotation_direction))


func _on_rotation_finished(current_gravity: Vector2, current_index: int) -> void:
	gravity_manager.current_gravity = current_gravity
	gravity_manager.rotation_index = current_index
	_set_player_gravity()
	player.control_enabled = true

	if not _condition_collected:
		hint_label.text = "移动去拿右侧发亮的黄色元件"
	elif not _level_finished:
		hint_label.text = "走向左侧出口"


func _on_condition_body_entered(body: Node2D) -> void:
	if _condition_collected or body != player:
		return

	_condition_collected = true
	condition_bit_visual.visible = false
	condition_card_visual.visible = false
	condition_frame_body.visible = false
	condition_frame_body.collision_layer = 0
	condition_frame_body.collision_mask = 0
	for child in condition_frame_body.get_children():
		if child is CollisionShape2D:
			child.set_deferred("disabled", true)
	condition_area.set_deferred("monitoring", false)
	exit_visual.visible = true
	hint_label.text = "已获得通关目标：再次旋转场景，然后走向左侧出口"
	if exit_area.get_overlapping_bodies().has(player):
		_on_exit_body_entered(player)


func _on_exit_body_entered(body: Node2D) -> void:
	if _level_finished or body != player or not _condition_collected:
		return

	_level_finished = true
	player.control_enabled = false
	hint_label.text = "第一关完成"
	LevelRouter.goto_scene("res://scenes/level_2.tscn")
