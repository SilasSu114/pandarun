extends Node2D


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") or event.is_action_pressed("ui_cancel"):
		LevelRouter.goto_scene("res://scenes/main_menu.tscn")
