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
	var level = load("res://scenes/level_1.tscn").instantiate()
	root.add_child(level)
	current_scene = level
	await create_timer(0.5).timeout

	var condition_area: Area2D = level.get_node("ConditionPickup")
	var condition_frame: StaticBody2D = level.get_node("ConditionFrame")

	level._on_condition_body_entered(level.player)
	await process_frame

	_check(level._condition_collected, "第一关卡片进入已拾取状态")
	_check(not level.condition_bit_visual.visible, "第一关拾取物立即隐藏")
	_check(not level.condition_card_visual.visible, "第一关卡片视觉立即隐藏")
	_check(not condition_frame.visible, "第一关条件框视觉立即隐藏")
	_check(condition_frame.collision_layer == 0, "第一关条件框关闭实体碰撞层")
	_check(condition_frame.collision_mask == 0, "第一关条件框关闭碰撞检测层")
	_check(not condition_area.monitoring, "第一关拾取区域停止监测")
	for child in condition_frame.get_children():
		if child is CollisionShape2D:
			_check(child.disabled, "第一关条件框碰撞形状已禁用")
	_check(level.exit_visual.visible, "第一关拾取后显示出口")

	quit(_failures)
