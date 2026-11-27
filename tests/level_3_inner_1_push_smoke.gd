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
	var level = load("res://scenes/level_3_inner_1.tscn").instantiate()
	root.add_child(level)
	current_scene = level
	await create_timer(0.5).timeout

	var player = level.player
	var box = level.png_box
	var platform_top := 650.0
	var box_half_height := 44.0
	var player_half_height := 31.5

	player.set_gravity(Vector2.DOWN, Vector2.RIGHT)
	box.set_gravity(Vector2.DOWN)
	box.freeze = false
	box.collision_layer = 4
	box.collision_mask = 3
	box.gravity_scale = 1.0
	box.global_position = Vector2(700.0, platform_top - box_half_height)
	player.global_position = Vector2(
		615.0,
		platform_top - player_half_height
	)
	player.control_enabled = true
	player.set_physics_process(true)
	await physics_frame

	_check(player._can_push_box(box), "玩家站在 PNG 侧面时允许推动")

	var start_x: float = box.global_position.x
	Input.action_press("interact")
	Input.action_press("move_right")
	for _frame in range(24):
		await physics_frame
	Input.action_release("move_right")
	Input.action_release("interact")

	_check(box.global_position.x > start_x + 20.0, "按住 E 并移动可以推动 PNG")

	box.global_position = Vector2(700.0, platform_top - box_half_height)
	box.linear_velocity = Vector2.ZERO
	player.global_position = Vector2(
		615.0,
		platform_top - player_half_height
	)
	player.set_gravity(Vector2.DOWN, Vector2.RIGHT)
	await physics_frame

	var no_interact_start_x: float = box.global_position.x
	Input.action_press("move_right")
	for _frame in range(24):
		await physics_frame
	Input.action_release("move_right")
	_check(
		box.global_position.x < no_interact_start_x + 10.0,
		"未按住 E 时不会用移动键推动 PNG"
	)

	quit(_failures)
