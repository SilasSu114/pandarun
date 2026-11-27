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
	await create_timer(1.0).timeout

	_check(not level.gravity_manager.rotation_unlocked, "教学前锁定旋转")
	_check(not level.scan_beam.visible, "教学前隐藏光束")
	_check(not level.background_mono.visible, "教学前使用原色背景")
	_check(not level._tutorial_started, "玩家未到第一块障碍物下方时不会触发教学")

	var trigger_shape: RectangleShape2D = level.get_node("BeamTutorialTrigger/CollisionShape2D").shape
	var player_shape: RectangleShape2D = level.player.get_node("CollisionShape2D").shape
	var platform_shape: RectangleShape2D = level.get_node("LeftPlatform/CollisionShape2D").shape
	var trigger_left_x: float = level.get_node("BeamTutorialTrigger").global_position.x - trigger_shape.size.x * 0.5
	var player_center_at_entry_x: float = trigger_left_x - player_shape.size.x * 0.5
	var platform_left_x: float = level.get_node("LeftPlatform").global_position.x - platform_shape.size.x * 0.5
	_check(player_center_at_entry_x > platform_left_x, "教学触发的玩家中心位置已进入障碍物横向范围")

	var emitter_camera_local: Vector2 = level.camera.to_local(
		level.scan_beam.to_global(Vector2(0.0, -470.0))
	)
	_check(emitter_camera_local.y < -100.0, "初始激光从画面上侧发射")

	Input.action_press("move_right")
	for _frame in range(180):
		await physics_frame
		if level._tutorial_started:
			break
	Input.action_release("move_right")
	_check(level._tutorial_started, "玩家进入第一块障碍物下方后触发教学")
	_check(level.background_mono.visible, "教学开始后切换黑白背景")
	_check(level.scan_beam.visible, "教学开始后显示光束")
	_check(
		is_equal_approx(level._beam_offset, 430.0) and level._beam_direction < 0.0,
		"教学从画面上侧开始向左扫描"
	)
	await create_timer(level.TUTORIAL_DURATION + 0.1).timeout
	_check(not level._tutorial_running, "教学扫描按预期结束")
	_check(level.gravity_manager.rotation_unlocked, "教学结束后解锁旋转")
	var offset_at_tutorial_end: float = level._beam_offset
	_check(
		offset_at_tutorial_end < 0.0
		and level._beam_direction > 0.0,
		"教学结束后激光从左侧继续回扫"
	)
	await create_timer(0.1).timeout
	_check(
		level._beam_offset > offset_at_tutorial_end,
		"教学结束后不会瞬移回右侧重新扫描"
	)

	level._beam_offset = -180.0
	level._update_beam_transform()
	level._update_beam_geometry()
	_check(level.beam_shape.size.y < 700.0, "浮空平台能够遮挡光束")

	level._beam_armed = true
	level._invulnerability_left = 0.0
	var pointer_position: Vector2 = level.pointer.global_position
	level._request_defeat()
	await create_timer(1.0).timeout
	_check(not level._defeated, "战败特写结束后恢复操作")
	_check(level.player.global_position.distance_to(level._safe_position) < 1.0, "战败后回到安全点")
	_check(level.camera.zoom == Vector2.ONE, "战败特写结束后恢复镜头")
	_check(level.pointer.global_position.distance_to(pointer_position) < 2.0, "战败后保留指针位置")
	_check(not level._folder_opened, "战败不会触发文件夹")

	level._beam_armed = true
	level._beam_offset = 0.0
	level._beam_direction = 1.0
	level._update_beam_transform()
	level._update_beam_geometry()
	_check(level.gravity_manager.try_rotate(), "第一次旋转可以触发")
	_check(level._beam_armed, "第一次转向开始时不解除激光判定")
	_check(level.scan_beam.visible, "第一次转向过程中光束保持显示")
	_check(
		is_zero_approx(level._beam_offset),
		"第一次转向开始时光束不会跳回边界"
	)
	level._beam_armed = false
	await create_timer(0.1).timeout
	var offset_during_first_turn: float = level._beam_offset
	_check(level.scan_beam.visible, "第一次转向动画中光束仍然可见")
	_check(
		offset_during_first_turn > 0.0 and level._beam_direction > 0.0,
		"第一次转向动画中光束继续按原方向扫描"
	)
	await create_timer(0.6).timeout
	_check(level.gravity_manager.current_gravity == Vector2.RIGHT, "第一次旋转后指针向右掉落")
	_check(
		level._beam_offset > offset_during_first_turn
		and level._beam_offset < 430.0
		and level._beam_direction > 0.0,
		"第一次转向结束后保留扫描进度和方向"
	)
	emitter_camera_local = level.camera.to_local(
		level.scan_beam.to_global(Vector2(0.0, -470.0))
	)
	_check(emitter_camera_local.x > 100.0, "第一次旋转后激光从画面右侧发射")
	level._beam_armed = false
	await create_timer(2.0).timeout
	_check(level.pointer.global_position.x > 900.0, "指针落到右侧推动区域")
	level.player.global_position = level.pointer.global_position + Vector2(0.0, 65.0)
	level.player.set_physics_process(false)
	await physics_frame

	for index in range(150):
		if level._folder_opened:
			break
		level.player.global_position = level.pointer.global_position + Vector2(0.0, 65.0)
		level.pointer.apply_player_push(Vector2.UP, 240.0)
		await physics_frame

	_check(level._folder_opened, "指针可以沿推动路线进入文件夹")
	_check(not level.pointer.visible, "交互后指针消失")
	_check(level.folder_open_visual.visible, "交互后文件夹打开")
	_check(level.exit_visual.visible, "交互后出口显示")
	_check(not level._exit_armed, "第二次旋转前出口不能通关")

	level._beam_offset = 0.0
	level._beam_direction = -1.0
	level._beam_armed = true
	level._update_beam_transform()
	level._update_beam_geometry()
	_check(level.gravity_manager.try_rotate(), "第二次旋转可以触发")
	_check(level._beam_armed, "第二次转向开始时不解除激光判定")
	_check(level.scan_beam.visible, "第二次转向过程中光束保持显示")
	_check(
		is_zero_approx(level._beam_offset),
		"第二次转向开始时光束不会跳回边界"
	)
	level._beam_armed = false
	await create_timer(0.1).timeout
	var offset_during_second_turn: float = level._beam_offset
	_check(level.scan_beam.visible, "第二次转向动画中光束仍然可见")
	_check(
		offset_during_second_turn < 0.0 and level._beam_direction < 0.0,
		"第二次转向动画中光束继续按原方向扫描"
	)
	await create_timer(0.6).timeout
	_check(level.gravity_manager.current_gravity == Vector2.UP, "第二次旋转后重力向上")
	_check(level._exit_armed, "第二次旋转后出口开放")
	_check(
		level._beam_offset < offset_during_second_turn
		and level._beam_offset > -430.0
		and level._beam_direction < 0.0,
		"第二次转向结束后保留扫描进度和方向"
	)
	emitter_camera_local = level.camera.to_local(
		level.scan_beam.to_global(Vector2(0.0, -470.0))
	)
	_check(emitter_camera_local.y > 100.0, "第二次旋转后激光从画面底部发射")

	level._on_exit_body_entered(level.player)
	await create_timer(1.3).timeout
	_check(
		current_scene != null and current_scene.name == "Level3",
		"第二关通关后进入第三关表世界"
	)

	quit(_failures)
