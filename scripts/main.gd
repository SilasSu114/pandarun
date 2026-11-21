extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var gravity_manager: Node = $GravityManager
@onready var key_area: Area2D = $Key
@onready var exit_area: Area2D = $Exit
@onready var exit_visual: ColorRect = $Exit/Visual

var exit_active := false
var level_complete := false
var key_collected := false


func _ready() -> void:
	player.set_gravity(gravity_manager.current_gravity, gravity_manager.get_screen_right())
	player.teaching_obstacle_touched.connect(_on_teaching_obstacle_touched)
	gravity_manager.rotation_started.connect(_on_rotation_started)
	gravity_manager.rotation_finished.connect(_on_rotation_finished)
	key_area.body_entered.connect(_on_key_body_entered)
	exit_area.body_entered.connect(_on_exit_body_entered)
	_update_exit_visual()


func _physics_process(_delta: float) -> void:
	if level_complete:
		return

	if Input.is_action_just_pressed("space_rotate"):
		gravity_manager.try_rotate()


func _on_teaching_obstacle_touched(_obstacle: Node) -> void:
	if not gravity_manager.rotation_unlocked:
		gravity_manager.rotation_unlocked = true


func _on_rotation_started(_target_gravity: Vector2, _target_index: int) -> void:
	player.control_enabled = false


func _on_rotation_finished(current_gravity: Vector2, _current_index: int) -> void:
	player.control_enabled = true
	player.set_gravity(current_gravity, gravity_manager.get_screen_right())


func _on_key_body_entered(body: Node2D) -> void:
	if body != player or key_collected:
		return

	key_collected = true
	exit_active = true
	key_area.set_deferred("monitoring", false)
	key_area.visible = false
	_update_exit_visual()


func _on_exit_body_entered(body: Node2D) -> void:
	if body != player or level_complete or not exit_active:
		return

	level_complete = true
	player.control_enabled = false
	player.set_physics_process(false)
	gravity_manager.rotation_unlocked = false
	exit_visual.color = Color(0.9, 0.8, 0.25, 0.95)
	LevelRouter.goto_scene("res://scenes/level_2.tscn")


func _update_exit_visual() -> void:
	if exit_active:
		exit_visual.color = Color(0.18, 0.72, 0.36, 0.9)
	else:
		exit_visual.color = Color(0.25, 0.42, 0.34, 0.45)
