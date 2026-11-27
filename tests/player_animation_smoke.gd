extends SceneTree

var _failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if condition:
		print("通过：", message)
	else:
		_failures += 1
		push_error("失败：" + message)


func _run() -> void:
	var walk_paths := [
		"res://assets/player/walk_1.png",
		"res://assets/player/walk_2.png",
		"res://assets/player/walk_3.png",
		"res://assets/player/walk_4.png",
		"res://assets/player/walk_5.png",
	]
	var jump_paths := [
		"res://assets/player/jump_1.png",
		"res://assets/player/jump_2.png",
		"res://assets/player/jump_3.png",
	]
	_check(_all_hashes_unique(walk_paths), "行走帧不是重复图片")
	_check(_all_hashes_unique(jump_paths), "跳跃帧不是重复图片")

	var floor_body := StaticBody2D.new()
	floor_body.position = Vector2(0.0, 42.0)
	var floor_shape := CollisionShape2D.new()
	var floor_rectangle := RectangleShape2D.new()
	floor_rectangle.size = Vector2(400.0, 20.0)
	floor_shape.shape = floor_rectangle
	floor_body.add_child(floor_shape)
	root.add_child(floor_body)

	var player = load("res://scenes/player.tscn").instantiate()
	root.add_child(player)
	for _frame in range(30):
		await physics_frame

	_check(player.is_on_floor(), "测试角色稳定站在地面上")
	_check(player._visual.sprite_frames.get_frame_count("walk") == 5, "行走动画包含 5 帧")
	_check(player._visual.sprite_frames.get_frame_count("jump") == 3, "跳跃动画包含 3 帧")

	Input.action_press("move_right")
	await create_timer(0.25).timeout
	_check(player._visual.flip_h, "静止后第一次向右移动会立即镜像朝向")
	_check(player._visual.animation == &"walk", "移动时播放行走动画")
	_check(player._visual.frame > 0, "行走动画会切到后续帧")
	_check(player._visual.rotation_degrees > 2.0, "向右移动时轻微向右前倾")

	Input.action_release("move_right")
	await create_timer(0.25).timeout
	_check(player._visual.animation == &"idle", "停止移动后恢复待机动画")
	_check(player._visual.flip_h, "停止移动后保持向右朝向")
	_check(absf(player._visual.rotation_degrees) < 0.2, "停止移动后身体恢复直立")

	Input.action_press("move_left")
	await create_timer(0.1).timeout
	_check(not player._visual.flip_h, "向左移动时立即恢复素材原始朝向")
	_check(player._visual.rotation_degrees < -2.0, "向左移动时轻微向左前倾")
	Input.action_release("move_left")

	player.begin_visual_rotation(1.0)
	await create_timer(GravityManager.ROTATION_DURATION + 0.1).timeout
	_check(
		is_equal_approx(player._visual_pivot.rotation_degrees, 90.0),
		"重力旋转只作用于外层视觉节点"
	)
	_check(not player._visual.flip_h, "重力旋转后保留当前左右朝向")

	quit(_failures)


func _all_hashes_unique(paths: Array) -> bool:
	var hashes: Array[String] = []
	for path in paths:
		hashes.append(FileAccess.get_sha256(path))
	return hashes.size() == paths.size() and hashes.size() == _unique_count(hashes)


func _unique_count(values: Array[String]) -> int:
	var unique: Array[String] = []
	for value in values:
		if not unique.has(value):
			unique.append(value)
	return unique.size()
