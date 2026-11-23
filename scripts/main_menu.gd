extends Control

const SAVE_PATH := "user://savegame.json"

@onready var start_button: Button = $DesktopIcons/StartButton
@onready var continue_button: Button = $DesktopIcons/ContinueButton
@onready var demo_button: Button = $DesktopIcons/DemoButton
@onready var exit_button: Button = $Taskbar/Content/ExitButton
@onready var fullscreen_button: Button = $Taskbar/Content/FullscreenButton


func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	demo_button.pressed.connect(_on_demo_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	fullscreen_button.pressed.connect(_on_fullscreen_pressed)
	DisplaySettings.fullscreen_changed.connect(_on_fullscreen_changed)
	continue_button.visible = FileAccess.file_exists(SAVE_PATH)
	_update_fullscreen_label()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()


func _on_start_pressed() -> void:
	LevelRouter.goto_scene("res://scenes/level_1.tscn")


func _on_continue_pressed() -> void:
	LevelRouter.goto_scene("res://scenes/level_1.tscn")


func _on_demo_pressed() -> void:
	LevelRouter.goto_scene("res://scenes/main.tscn")


func _on_exit_pressed() -> void:
	get_tree().quit()


func _on_fullscreen_pressed() -> void:
	DisplaySettings.toggle_fullscreen()


func _on_fullscreen_changed(_enabled: bool) -> void:
	_update_fullscreen_label()


func _update_fullscreen_label() -> void:
	fullscreen_button.text = "全屏:开" if DisplaySettings.is_fullscreen() else "全屏:关"
