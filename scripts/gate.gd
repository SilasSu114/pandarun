extends StaticBody2D
class_name Gate

var is_open := false

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var visual: ColorRect = $Visual


func open() -> void:
	if is_open:
		return

	is_open = true
	collision_shape.set_deferred("disabled", true)
	visual.modulate = Color(1, 1, 1, 0.25)
