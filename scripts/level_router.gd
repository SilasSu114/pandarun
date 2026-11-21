extends CanvasLayer

const FADE_OUT_DURATION := 0.6
const FADE_IN_DURATION := 0.35

var _changing := false
var _overlay: ColorRect


func _ready() -> void:
	layer = 128
	_overlay = ColorRect.new()
	_overlay.color = Color(0, 0, 0, 0)
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_overlay)


func goto_scene(path: String) -> void:
	if _changing:
		return

	_changing = true
	var out_tween := create_tween()
	out_tween.tween_property(_overlay, "color:a", 1.0, FADE_OUT_DURATION)
	await out_tween.finished

	get_tree().change_scene_to_file(path)
	await get_tree().process_frame

	var in_tween := create_tween()
	in_tween.tween_property(_overlay, "color:a", 0.0, FADE_IN_DURATION)
	await in_tween.finished
	_changing = false
