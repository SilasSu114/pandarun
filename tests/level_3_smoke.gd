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
	var router = root.get_node("LevelRouter")
	router.reset_progress()
	var level = load("res://scenes/level_3.tscn").instantiate()
	root.add_child(level)
	current_scene = level
	await create_timer(0.5).timeout

	_check(level.folder_visuals.visible, "第三关初始显示文件夹")
	_check(not level.exit_area.is_visible_in_tree(), "第三关拾取前隐藏出口")
	_check(level.folder_areas.size() == 2, "第三关上下两个文件夹都能交互")
	for area in level.folder_areas:
		_check(area.monitoring, "第三关拾取前文件夹监测正常")

	level._on_exit_body_entered(level.player)
	_check(not level._level_finished, "第三关拾取前出口不会通关")

	var expected_gravities: Array[Vector2] = [
		Vector2.RIGHT,
		Vector2.UP,
		Vector2.LEFT,
		Vector2.DOWN,
	]
	var initial_visual_rotation: float = level.player.get_node("VisualPivot").rotation_degrees
	for expected_gravity in expected_gravities:
		_check(level.gravity_manager.try_rotate(), "第三关可以触发四向重力旋转")
		await create_timer(level.gravity_manager.ROTATION_DURATION + 0.1).timeout
		_check(
			level.gravity_manager.current_gravity.is_equal_approx(expected_gravity),
			"第三关重力切换到预期方向"
		)
	_check(
		not is_equal_approx(
			level.player.get_node("VisualPivot").rotation_degrees,
			initial_visual_rotation
		),
		"第三关旋转时同步旋转玩家朝向"
	)

	var lower_area: Area2D = level.folder_areas[1]
	lower_area.body_entered.emit(level.player)
	_check(level._folder_in_range, "第三关下方文件夹进入拾取范围")
	level._collect_folder()
	await process_frame

	_check(level._folder_collected, "第三关文件夹进入已拾取状态")
	_check(router.level_3_condition_collected, "第三关记录已拾取通关条件")
	_check(not level.folder_visuals.visible, "第三关拾取后文件夹整体消失")
	_check(level.exit_visual.visible, "第三关拾取后显示出口")
	for area in level.folder_areas:
		_check(not area.monitoring, "第三关拾取后关闭文件夹监测")
		for child in area.get_children():
			if child is CollisionShape2D:
				_check(child.disabled, "第三关拾取后关闭文件夹判定形状")

	level._on_exit_body_entered(level.player)
	await create_timer(1.1).timeout
	_check(
		current_scene != null and current_scene.name == "Level3Inner1",
		"第三关表世界出口进入里世界一"
	)

	quit(_failures)
