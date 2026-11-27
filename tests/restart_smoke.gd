extends SceneTree

const LEVEL_PATHS := [
	"res://scenes/level_1.tscn",
	"res://scenes/level_2.tscn",
	"res://scenes/level_3.tscn",
	"res://scenes/level_3_inner_1.tscn",
	"res://scenes/level_4_placeholder.tscn",
]

var _failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if condition:
		print("通过：", message)
	else:
		_failures += 1
		push_error("失败：" + message)


func _make_restart_event() -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = KEY_R
	event.pressed = true
	return event


func _run() -> void:
	_check(InputMap.has_action("restart_level"), "重新开始动作已注册")
	var router = root.get_node("LevelRouter")
	_check(is_instance_valid(router), "关卡路由节点已加载")

	for path in LEVEL_PATHS:
		if is_instance_valid(current_scene):
			current_scene.queue_free()
			current_scene = null
			await process_frame

		var packed_scene := load(path) as PackedScene
		var original: Node = packed_scene.instantiate()
		root.add_child(original)
		current_scene = original
		await process_frame

		router._unhandled_input(_make_restart_event())
		await create_timer(1.1).timeout

		_check(
			is_instance_valid(current_scene)
				and current_scene != original
				and current_scene.scene_file_path == path,
			path + " 可以按 R 重新开始"
		)

	quit(_failures)
