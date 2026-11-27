extends Control

# 主界面按 1920x1080 的设计稿布局，再随窗口尺寸整体缩放，保证任意分辨率下比例不变。
const DESIGN_SIZE := Vector2(1920.0, 1080.0)
const WINDOW_SIZE := Vector2(768.0, 476.0)
const WINDOW_CENTER := Vector2(0.50205, 0.5051)
const SETTINGS_SIZE := Vector2(560.0, 380.0)
const SETTINGS_OFFSET := Vector2(70.0, 50.0)
const TITLE_HEIGHT := 50.0
const BUTTON_SIZE := Vector2(172.0, 57.0)
const CLOSE_SIZE := Vector2(27.0, 28.0)
const TEX_ASPECT := 16.0 / 9.0

@onready var background: TextureRect = $Background
@onready var background_fill: TextureRect = $BackgroundFill
@onready var main_window: Control = $MainWindow
@onready var main_title_bar: Panel = $MainWindow/TitleBar
@onready var main_title_label: Label = $MainWindow/TitleBar/TitleLabel
@onready var main_close: Button = $MainWindow/TitleBar/CloseButton
@onready var start_button: Button = $MainWindow/StartButton
@onready var settings_button: Button = $MainWindow/SettingsButton
@onready var settings_window: Control = $SettingsWindow
@onready var settings_title_bar: Panel = $SettingsWindow/TitleBar
@onready var settings_title_label: Label = $SettingsWindow/TitleBar/TitleLabel
@onready var settings_close: Button = $SettingsWindow/TitleBar/CloseButton
@onready var settings_body: VBoxContainer = $SettingsWindow/Body
@onready var fullscreen_button: Button = $SettingsWindow/Body/FullscreenButton
@onready var exit_button: Button = $SettingsWindow/Body/ExitButton
@onready var back_button: Button = $SettingsWindow/Body/BackButton

var _ui_scale := 1.0
var _burst_countdown := 2.5


func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	main_close.pressed.connect(_on_exit_pressed)
	settings_close.pressed.connect(_on_settings_closed)
	back_button.pressed.connect(_on_settings_closed)
	exit_button.pressed.connect(_on_exit_pressed)
	fullscreen_button.pressed.connect(_on_fullscreen_pressed)
	DisplaySettings.fullscreen_changed.connect(_on_fullscreen_changed)
	resized.connect(_apply_layout)
	_apply_layout()
	_update_fullscreen_label()
	_pop_in(main_window, 0.18)
	start_button.grab_focus()


func _process(delta: float) -> void:
	_burst_countdown -= delta
	if _burst_countdown <= 0.0:
		_burst_countdown = randf_range(3.5, 7.5)
		var tween := create_tween()
		tween.tween_method(_set_burst, 0.0, 1.0, 0.06)
		tween.tween_method(_set_burst, 1.0, 0.0, 0.3)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if settings_window.visible:
			_on_settings_closed()
		else:
			get_tree().quit()


func _set_burst(value: float) -> void:
	(background.material as ShaderMaterial).set_shader_parameter("burst", value)


func _pop_in(window: Control, duration: float) -> void:
	window.pivot_offset = window.size / 2.0
	window.scale = Vector2(0.94, 0.94)
	window.modulate.a = 0.0
	var tween := create_tween().set_parallel(true)
	tween.tween_property(window, "scale", Vector2.ONE, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(window, "modulate:a", 1.0, duration)


func _apply_layout() -> void:
	var vp := size
	if vp.x <= 0.0 or vp.y <= 0.0:
		return
	_ui_scale = clampf(minf(vp.x / DESIGN_SIZE.x, vp.y / DESIGN_SIZE.y), 0.5, 3.0)
	var s := _ui_scale
	var center := Vector2((WINDOW_CENTER.x - 0.5) * vp.x, (WINDOW_CENTER.y - 0.5) * vp.y)
	main_window.offset_left = center.x - WINDOW_SIZE.x * s / 2.0
	main_window.offset_right = center.x + WINDOW_SIZE.x * s / 2.0
	main_window.offset_top = center.y - WINDOW_SIZE.y * s / 2.0
	main_window.offset_bottom = center.y + WINDOW_SIZE.y * s / 2.0
	main_window.pivot_offset = main_window.size / 2.0
	main_title_bar.offset_bottom = TITLE_HEIGHT * s
	main_title_label.offset_left = 18.0 * s
	main_title_label.offset_right = -44.0 * s
	main_title_label.add_theme_font_size_override("font_size", int(round(22.0 * s)))
	_place_close(main_close, s)
	_place_main_button(start_button, s)
	_place_main_button(settings_button, s)
	start_button.add_theme_font_size_override("font_size", int(round(22.0 * s)))
	settings_button.add_theme_font_size_override("font_size", int(round(22.0 * s)))

	var sc := SETTINGS_OFFSET * s
	settings_window.offset_left = sc.x - SETTINGS_SIZE.x * s / 2.0
	settings_window.offset_right = sc.x + SETTINGS_SIZE.x * s / 2.0
	settings_window.offset_top = sc.y - SETTINGS_SIZE.y * s / 2.0
	settings_window.offset_bottom = sc.y + SETTINGS_SIZE.y * s / 2.0
	settings_window.pivot_offset = settings_window.size / 2.0
	settings_title_bar.offset_bottom = TITLE_HEIGHT * s
	settings_title_label.offset_left = 18.0 * s
	settings_title_label.offset_right = -44.0 * s
	settings_title_label.add_theme_font_size_override("font_size", int(round(22.0 * s)))
	_place_close(settings_close, s)
	settings_body.offset_left = -160.0 * s
	settings_body.offset_right = 160.0 * s
	settings_body.offset_top = -71.0 * s
	settings_body.offset_bottom = 121.0 * s
	settings_body.add_theme_constant_override("separation", int(round(18.0 * s)))
	for button in [fullscreen_button, exit_button, back_button]:
		button.custom_minimum_size = Vector2(320.0 * s, 52.0 * s)
		button.add_theme_font_size_override("font_size", int(round(20.0 * s)))

	_scale_borders(s)
	_fit_background(vp)


func _place_close(button: Button, s: float) -> void:
	button.offset_left = -(10.0 + CLOSE_SIZE.x) * s
	button.offset_right = -10.0 * s
	button.offset_top = -CLOSE_SIZE.y * s / 2.0
	button.offset_bottom = CLOSE_SIZE.y * s / 2.0


func _place_main_button(button: Button, s: float) -> void:
	button.offset_left = -BUTTON_SIZE.x * s / 2.0
	button.offset_right = BUTTON_SIZE.x * s / 2.0
	button.offset_top = -BUTTON_SIZE.y * s / 2.0
	button.offset_bottom = BUTTON_SIZE.y * s / 2.0


func _scale_borders(s: float) -> void:
	var wide := int(max(1.0, round(3.0 * s)))
	var thin := int(max(1.0, round(2.0 * s)))
	for path in ["MainWindow/WindowPanel", "SettingsWindow/WindowPanel"]:
		var box: StyleBoxFlat = (get_node(path) as Control).get_theme_stylebox("panel")
		box.border_width_left = wide
		box.border_width_top = wide
		box.border_width_right = wide
		box.border_width_bottom = wide
	for path in ["MainWindow/TitleBar", "SettingsWindow/TitleBar"]:
		var box: StyleBoxFlat = (get_node(path) as Control).get_theme_stylebox("panel")
		box.border_width_left = wide
		box.border_width_top = wide
		box.border_width_right = wide
		box.border_width_bottom = wide
	for button in [start_button, settings_button, fullscreen_button, exit_button, back_button]:
		for style in ["normal", "hover", "pressed"]:
			var box: StyleBoxFlat = button.get_theme_stylebox(style)
			box.border_width_left = wide
			box.border_width_top = wide
			box.border_width_right = wide
			box.border_width_bottom = wide
	for button in [main_close, settings_close]:
		for style in ["normal", "hover", "pressed"]:
			var box: StyleBoxFlat = button.get_theme_stylebox(style)
			box.border_width_left = thin
			box.border_width_top = thin
			box.border_width_right = thin
			box.border_width_bottom = thin


# 背景按高度等比缩放并左对齐：窄屏裁掉右侧天空，宽屏用贴图最右列拉伸补满，
# 保证左侧图标列与底部任务栏在任何比例下都完整。
func _fit_background(vp: Vector2) -> void:
	var bg_width := vp.y * TEX_ASPECT
	background.offset_right = bg_width
	var fraction := bg_width / vp.x
	if fraction < 1.0:
		background_fill.visible = true
		background_fill.anchor_left = fraction
	else:
		background_fill.visible = false


func _on_start_pressed() -> void:
	LevelRouter.reset_progress()
	LevelRouter.goto_scene("res://scenes/level_1.tscn")


func _on_settings_pressed() -> void:
	settings_window.visible = true
	_pop_in(settings_window, 0.14)
	fullscreen_button.grab_focus()


func _on_settings_closed() -> void:
	settings_window.visible = false
	settings_button.grab_focus()


func _on_exit_pressed() -> void:
	get_tree().quit()


func _on_fullscreen_pressed() -> void:
	DisplaySettings.toggle_fullscreen()


func _on_fullscreen_changed(_enabled: bool) -> void:
	_update_fullscreen_label()


func _update_fullscreen_label() -> void:
	fullscreen_button.text = "全屏:开" if DisplaySettings.is_fullscreen() else "全屏:关"
