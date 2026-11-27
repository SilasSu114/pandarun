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


func _press_level_action(level: Node) -> void:
	var event := InputEventAction.new()
	event.action = &"space_rotate"
	event.pressed = true
	level._unhandled_input(event)


func _run() -> void:
	var router = root.get_node("LevelRouter")
	router.reset_progress()
	# 直接从里世界一开始测试时，补上表世界已经取得通关条件的前置状态。
	router.level_3_condition_collected = true

	var level = load("res://scenes/level_3_inner_1.tscn").instantiate()
	root.add_child(level)
	current_scene = level
	await create_timer(0.5).timeout

	_check(level.png_box.freeze, "里世界一初始 PNG 悬空锁定")
	_check(level.png_box.collision_layer == 0, "里世界一初始 PNG 不阻挡玩家")
	_check(not level.png_interaction_area.monitoring, "里世界一初始不可选中 PNG")
	_check(not level.log_visual.visible, "里世界一初始隐藏 LOG")
	_check(not level.log_area.monitoring, "里世界一初始不启用 LOG 交互")
	_check(not level.preview_panel.visible, "里世界一初始隐藏 PREVIEW")
	_check(not level.repair_panel.visible, "里世界一初始隐藏修复面板")
	_check(not level.return_visual.visible, "里世界一初始隐藏返回按钮")
	_check(level.png_box.requires_interact_push, "里世界一 PNG 必须按 E 推动")

	var initial_png_position: Vector2 = level.png_box.global_position
	_press_level_action(level)
	_check(level.gravity_manager.is_rotating, "里世界一可以响应空格旋转")

	for _step in range(60):
		await create_timer(0.1).timeout
		if level._initial_png_dropped:
			break

	_check(level._initial_png_dropped, "第一次旋转后 PNG 通过真实物理掉落到位")
	_check(level.png_interaction_area.monitoring, "PNG 掉落后开启选中区域")
	_check(level._png_in_range, "PNG 掉落后玩家处于可交互范围")
	var drop_travel: Vector2 = level.png_box.global_position - initial_png_position
	_check(
		drop_travel.dot(level.gravity_manager.current_gravity) > 30.0,
		"PNG 沿旋转后的真实重力方向移动，而不是固定坐标瞬移"
	)
	_check(level.png_box.freeze, "PNG 掉落后停在玩家附近并锁定位置")
	_check(level.png_box.collision_layer == 0, "未选中的 PNG 不阻挡玩家")
	_check(level.player.gravity_scale == 1.0, "PNG 掉落后恢复玩家重力")

	level._select_png()
	await process_frame
	await process_frame
	_check(level._png_selected, "靠近 PNG 后进入已选中状态")
	_check(level.preview_panel.visible, "选中 PNG 后弹出 PREVIEW")
	var preview_title := level.preview_panel.get_node("Title") as Label
	var preview_style := level.preview_panel.get_theme_stylebox("panel") as StyleBoxFlat
	_check(preview_title.text == "PREVIEW", "PREVIEW 标题显示正确")
	_check(
		preview_style != null
		and preview_style.border_color.r > 0.9
		and preview_style.border_color.g > 0.7
		and preview_style.border_color.b < 0.3,
		"PREVIEW 使用黄色高亮边框"
	)
	_check(level.log_visual.visible, "选中 PNG 后 LOG 才出现")
	_check(level.log_area.monitoring, "选中 PNG 后 LOG 交互启用")

	var selected_png_position: Vector2 = level.png_box.global_position
	_press_level_action(level)
	for _step in range(20):
		await create_timer(0.1).timeout
		if level._log_discovered:
			break
	_check(level.gravity_manager.rotation_index == 2, "选中 PNG 后可旋转前往 LOG")
	_check(level._log_discovered, "旋转后玩家经过并定位 LOG")
	_check(
		level.png_box.global_position.is_equal_approx(selected_png_position),
		"选中后的 PNG 在旋转过程中保持锁定且不跳位"
	)

	level._start_repair()
	await process_frame
	_check(level._repair_started, "定位 LOG 后可按 E 开始修复")
	_check(level.repair_panel.visible, "修复开始后显示 REPAIRING")
	_check(level.repair_label.text == "REPAIRING", "修复过程显示 REPAIRING 文案")
	_check(not level.gravity_manager.rotation_unlocked, "修复读条期间锁定旋转")
	var repair_rotation_index: int = level.gravity_manager.rotation_index
	_press_level_action(level)
	_check(
		level.gravity_manager.rotation_index == repair_rotation_index
		and not level.gravity_manager.is_rotating,
		"修复读条期间空格不会启动旋转"
	)

	level._process(level.REPAIR_DURATION + 0.1)
	await process_frame
	_check(level._repair_done, "修复读条结束后进入完成状态")
	_check(level.repair_label.text == "DONE", "修复完成后显示 DONE")
	_check(level.gravity_manager.rotation_unlocked, "修复完成后恢复旋转")

	_press_level_action(level)
	_check(level.gravity_manager.is_rotating, "修复后可执行第一次掉落旋转")
	await create_timer(level.gravity_manager.ROTATION_DURATION + 0.12).timeout
	_check(not level._png_released, "只旋转一次时 PNG 仍保持锁定")

	_press_level_action(level)
	_check(level.gravity_manager.is_rotating, "修复后可执行第二次掉落旋转")
	await create_timer(level.gravity_manager.ROTATION_DURATION + 0.12).timeout

	_check(level._png_released, "累计两次旋转后释放选中的 PNG")
	_check(not level.png_box.freeze, "释放后的 PNG 进入物理掉落")
	_check(level.png_box.collision_layer == 4, "释放后的 PNG 开启实体碰撞")
	_check(level.gravity_manager.current_gravity == Vector2.DOWN, "修复后两次旋转恢复向下重力")
	var release_position: Vector2 = level.png_box.global_position
	await create_timer(1.0).timeout
	var release_travel: Vector2 = level.png_box.global_position - release_position
	_check(
		release_travel.dot(level.gravity_manager.current_gravity) > 20.0,
		"PNG 沿当前重力方向掉落到中央平台"
	)

	level.player.global_position = Vector2(380.0, 606.0)
	level.player.velocity = Vector2.ZERO
	level.player.set_gravity(Vector2.DOWN, Vector2.RIGHT)
	level.player.control_enabled = true
	level.player.set_physics_process(true)
	await physics_frame

	Input.action_press("interact")
	Input.action_press("move_right")
	for _frame in range(180):
		await physics_frame
		if level._return_armed:
			break
	Input.action_release("move_right")
	Input.action_release("interact")
	await create_timer(0.2).timeout

	_check(
		level.png_box.global_position.x >= level.PUSH_TARGET_X,
		"按住 E 可将 PNG 从中央平台推到右下障碍物"
	)
	_check(
		absf(level.png_box.global_position.y - level.PUSH_TARGET_Y)
		<= level.PUSH_TARGET_Y_TOLERANCE,
		"PNG 实际站在右下障碍物顶部"
	)
	_check(level._return_armed, "PNG 到达右下障碍物顶部后启用返回按钮")
	_check(level.return_visual.visible, "返回按钮在条件满足后显示")

	level.player.global_position = Vector2(560.0, 618.0)
	level.player.velocity = Vector2.ZERO
	await physics_frame
	level._on_return_body_entered(level.player)
	level._request_return()
	await process_frame
	_check(router.level_3_inner1_completed, "里世界一返回后记录完成状态")
	await create_timer(1.2).timeout
	_check(
		current_scene != null and current_scene.name == "Level3",
		"里世界一绿色按钮返回表世界"
	)
	_check(not current_scene.folder_visuals.visible, "返回表世界后文件夹保持消失")
	_check(current_scene.exit_area.visible, "返回表世界后出口保持开启")

	current_scene._on_exit_body_entered(current_scene.player)
	await create_timer(1.2).timeout
	_check(
		current_scene != null and current_scene.name == "Level4Placeholder",
		"表世界完成后出口进入第四关占位"
	)

	quit(_failures)
