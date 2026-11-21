extends Control

@onready var start_button: Button = $Window/Content/StartButton
@onready var exit_button: Button = $Window/Content/ExitButton
@onready var demo_button: Button = $DemoButton


func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	demo_button.pressed.connect(_on_demo_pressed)


func _on_start_pressed() -> void:
	LevelRouter.goto_scene("res://scenes/level_1.tscn")


func _on_demo_pressed() -> void:
	LevelRouter.goto_scene("res://scenes/main.tscn")


func _on_exit_pressed() -> void:
	get_tree().quit()
