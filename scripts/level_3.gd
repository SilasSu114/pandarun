extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var gravity_manager: Node = $GravityManager
@onready var switch_1: Area2D = $Switch1
@onready var switch_2: Area2D = $Switch2
@onready var switch_3: Area2D = $Switch3
@onready var switch_4: Area2D = $Switch4
@onready var gate_1: StaticBody2D = $Gate1
@onready var gate_2: StaticBody2D = $Gate2
@onready var gate_3: StaticBody2D = $Gate3
@onready var exit_area: Area2D = $Exit
@onready var inactive_exit_visual: ColorRect = $Exit/InactiveVisual
@onready var active_exit_visual: ColorRect = $Exit/ActiveVisual

var exit_active := false
var level_complete := false


func _ready() -> void:
	player.set_gravity(gravity_manager.current_gravity, gravity_manager.get_screen_right())
	gravity_manager.rotation_unlocked = true
	gravity_manager.rotation_started.connect(_on_rotation_started)
	gravity_manager.rotation_finished.connect(_on_rotation_finished)
	switch_1.activated.connect(_on_switch_1_activated)
	switch_2.activated.connect(_on_switch_2_activated)
	switch_3.activated.connect(_on_switch_3_activated)
	switch_4.activated.connect(_on_switch_4_activated)
	exit_area.body_entered.connect(_on_exit_body_entered)


func _physics_process(_delta: float) -> void:
	if level_complete:
		return

	if Input.is_action_just_pressed("space_rotate"):
		gravity_manager.try_rotate()


func _on_rotation_started(_target_gravity: Vector2, _target_index: int) -> void:
	player.control_enabled = false


func _on_rotation_finished(current_gravity: Vector2, _current_index: int) -> void:
	player.control_enabled = true
	player.set_gravity(current_gravity, gravity_manager.get_screen_right())


func _on_switch_1_activated() -> void:
	gate_1.open()


func _on_switch_2_activated() -> void:
	gate_2.open()


func _on_switch_3_activated() -> void:
	gate_3.open()


func _on_switch_4_activated() -> void:
	if exit_active:
		return

	exit_active = true
	inactive_exit_visual.visible = false
	active_exit_visual.visible = true


func _on_exit_body_entered(body: Node2D) -> void:
	if body != player or not exit_active or level_complete:
		return

	level_complete = true
	player.control_enabled = false
	player.set_physics_process(false)
	gravity_manager.rotation_unlocked = false
