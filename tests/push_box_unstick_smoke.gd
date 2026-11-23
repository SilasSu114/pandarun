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
	var level = load("res://scenes/level_2.tscn").instantiate()
	root.add_child(level)
	current_scene = level
	await create_timer(0.6).timeout

	var player = level.player
	var pointer = level.pointer
	player.global_position = Vector2(700.0, 900.0)
	pointer.global_position = Vector2(700.0, 800.0)
	pointer.linear_velocity = Vector2.ZERO
	pointer.set_gravity(Vector2.DOWN)
	player.set_gravity(Vector2.DOWN, Vector2.RIGHT)
	player.control_enabled = true
	player.set_physics_process(true)

	for _frame in range(90):
		await physics_frame

	var player_start: Vector2 = player.global_position
	var pointer_start: Vector2 = pointer.global_position
	Input.action_press("move_right")
	for _frame in range(12):
		await physics_frame

	var pointer_supported_position: Vector2 = pointer.global_position
	_check(player.global_position.x > player_start.x + 20.0, "玩家被指针压住后可以横向走开")
	_check(absf(pointer_supported_position.x - pointer_start.x) < 8.0, "玩家被压住时指针不会横向移动")
	_check(absf(pointer_supported_position.y - pointer_start.y) < 4.0, "玩家仍在指针下方时指针保持高度")

	for _frame in range(60):
		await physics_frame
	Input.action_release("move_right")
	_check(pointer.global_position.y > pointer_supported_position.y + 12.0, "玩家离开后指针重新向下掉落")

	player.global_position = Vector2(700.0, 910.0)
	pointer.global_position = Vector2(700.0, 974.0)
	pointer.linear_velocity = Vector2.ZERO
	for _frame in range(30):
		await physics_frame

	player_start = player.global_position
	pointer_start = pointer.global_position
	Input.action_press("move_right")
	for _frame in range(60):
		await physics_frame
	Input.action_release("move_right")

	_check(player.global_position.x > player_start.x + 20.0, "玩家站在指针上时可以自行走开")
	_check(absf(pointer.global_position.x - pointer_start.x) < 8.0, "玩家站在指针上时不会横向拖动指针")
	quit(_failures)
