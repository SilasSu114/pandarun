extends Control

const SAVE_PATH := "user://savegame.json"

@onready var start_button: Button = $DesktopIcons/StartButton
@onready var continue_button: Button = $DesktopIcons/ContinueButton
@onready var demo_button: Button = $DesktopIcons/DemoButton
@onready var exit_button: Button = $Taskbar/Content/ExitButton


func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	demo_button.pressed.connect(_on_demo_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	continue_button.visible = FileAccess.file_exists(SAVE_PATH)


func _on_start_pressed() -> void:
	LevelRouter.goto_scene("res://scenes/level_1.tscn")


func _on_continue_pressed() -> void:
	LevelRouter.goto_scene("res://scenes/level_1.tscn")


func _on_demo_pressed() -> void:
	LevelRouter.goto_scene("res://scenes/main.tscn")


func _on_exit_pressed() -> void:
	get_tree().quit()
