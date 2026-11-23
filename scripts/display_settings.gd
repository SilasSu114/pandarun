extends Node

signal fullscreen_changed(enabled: bool)

const CONFIG_PATH := "user://display_settings.cfg"
const BASE_WINDOW_SIZE := Vector2i(1920, 1080)
const SIZE_MARGIN_RATIO := 0.9

var fullscreen := false


func _ready() -> void:
	_load_config()
	_apply_windowed_size()
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F11:
		toggle_fullscreen()


func is_fullscreen() -> bool:
	return fullscreen


func set_fullscreen(value: bool) -> void:
	fullscreen = value
	if fullscreen:
		var screen_position := DisplayServer.screen_get_position()
		var screen_size := DisplayServer.screen_get_size()
		DisplayServer.window_set_size(screen_size)
		DisplayServer.window_set_position(screen_position)
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		_apply_windowed_size()
	if _is_main_menu():
		get_window().content_scale_size = get_window().size
	_save_config()
	fullscreen_changed.emit(fullscreen)


func toggle_fullscreen() -> void:
	set_fullscreen(not fullscreen)


func _apply_windowed_size() -> void:
	var screen := DisplayServer.screen_get_usable_rect()
	var limit := Vector2i(int(screen.size.x * SIZE_MARGIN_RATIO), int(screen.size.y * SIZE_MARGIN_RATIO))
	var size := BASE_WINDOW_SIZE
	if size.x > limit.x or size.y > limit.y:
		var shrink := minf(float(limit.x) / float(BASE_WINDOW_SIZE.x), float(limit.y) / float(BASE_WINDOW_SIZE.y))
		size = Vector2i(int(BASE_WINDOW_SIZE.x * shrink), int(BASE_WINDOW_SIZE.y * shrink))
	DisplayServer.window_set_size(size)
	DisplayServer.window_set_position(screen.position + (screen.size - size) / 2)


func _load_config() -> void:
	var config := ConfigFile.new()
	if config.load(CONFIG_PATH) == OK:
		fullscreen = bool(config.get_value("display", "fullscreen", false))


func _save_config() -> void:
	var config := ConfigFile.new()
	config.set_value("display", "fullscreen", fullscreen)
	config.save(CONFIG_PATH)

func _is_main_menu() -> bool:
	var scene := get_tree().current_scene
	return scene != null and scene.name == "MainMenu"
