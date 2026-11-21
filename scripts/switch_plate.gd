extends Area2D
class_name SwitchPlate

signal activated

enum Activator {
	PLAYER,
	PUSH_BOX,
}

@export var activator: Activator = Activator.PLAYER
@export var required_box_id := -1

var is_active := false

@onready var active_visual: ColorRect = $ActiveVisual
@onready var inactive_visual: ColorRect = $InactiveVisual


func _ready() -> void:
	active_visual.visible = false
	inactive_visual.visible = true
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if is_active:
		return

	match activator:
		Activator.PLAYER:
			if not body.is_in_group("player"):
				return
		Activator.PUSH_BOX:
			if not body.is_in_group("push_box"):
				return
			if required_box_id >= 0 and body.get("box_id") != required_box_id:
				return

	is_active = true
	active_visual.visible = true
	inactive_visual.visible = false
	activated.emit()
