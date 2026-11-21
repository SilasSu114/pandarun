# Godot 4.7 修复提示词：UI 旋转失效与正方形房间

你是一个 Godot 4.7 游戏开发 Agent。请修复当前重力旋转教学关 Demo 中的两个问题：

1. 按下 `Space` 后，重力向量会变化，角色也会向新重力方向掉落，但游戏画面和 UI 没有跟随重力同步旋转 90 度。
2. 当前房间是长方形，旋转后画面边界不协调。请把可游玩房间改为正方形。

## 项目版本要求

当前工作区有两个项目目录：

- `projects/godot-gravity-tutorial-demo-(4.3)/`：`project.godot` 标记为 Godot `4.3`。
- `projects/godot-gravity-tutorial-demo/`：`project.godot` 标记为 Godot `4.7`。

请只修改 `projects/godot-gravity-tutorial-demo/`。不要修改或删除 `projects/godot-gravity-tutorial-demo-(4.3)/`。所有代码、场景和导出节点路径都必须按 Godot 4.7 语法和 API 校验。完成后请确认：

```ini
config/features=PackedStringArray("4.7")
```

如果发现项目仍有旧的 4.3 兼容标记，请更新为 `4.7`。

## 修复 1：画面和 UI 必须跟随重力旋转

现在 `gravity_manager.gd` 里已经有旋转 `Camera2D` 和 `UIRoot` 的意图，但实际运行中视觉没有变化。请检查并修复以下问题：

1. `Camera2D` 必须是当前激活相机。
   - 在场景加载后调用 `camera.make_current()`。
   - 保持 `camera.ignore_rotation = false`。
   - 确认 `GravityManager.camera` 的 `NodePath` 正确指向场景中的 `Camera2D`。
2. 旋转相机时，不要依赖默认值，显式设置：

```gdscript
camera.ignore_rotation = false
camera.make_current()
camera.rotation_degrees = float(rotation_index) * 90.0
camera.reset_smoothing()
```

3. `UIRoot` 是 `CanvasLayer` 下的 `Control` 节点。旋转前必须更新旋转中心：

```gdscript
ui_root.pivot_offset = ui_root.size * 0.5
ui_root.rotation_degrees = float(rotation_index) * 90.0
```

4. 请在 `GravityManager` 中打印或断言一次关键状态，确保运行时 `camera` 和 `ui_root` 不是 `null`：

```gdscript
assert(is_instance_valid(camera), "GravityManager.camera is not assigned")
assert(is_instance_valid(ui_root), "GravityManager.ui_root is not assigned")
```

5. 每次按 `Space` 后，必须同时发生：
   - 重力向量切换。
   - `Camera2D.rotation_degrees` 变为 `90 * rotation_index`。
   - `UIRoot.rotation_degrees` 变为 `90 * rotation_index`。
   - 玩家移动方向和跳跃方向仍按当前屏幕方向计算。

不要用多个脚本分别计算旋转状态。视觉旋转状态必须由 `GravityManager.rotation_index` 统一驱动。

## 修复 2：把房间改成正方形

当前场景使用 `1152 x 648` 的长方形房间，旋转后边界会显得不协调。请将可游玩房间改为 `720 x 720` 的正方形。

### 项目设置

在 `project.godot` 中设置游戏视口为正方形：

```ini
[display]

window/size/viewport_width=720
window/size/viewport_height=720
window/stretch/mode="canvas_items"
window/stretch/aspect="keep"
```

### 场景调整

请同步调整 `scenes/main.tscn`：

- 背景改为 `720 x 720`。
- 上墙、下墙、左墙、右墙共同围成 `720 x 720` 的封闭正方形。
- 四面墙的碰撞体必须完整覆盖边界，不允许玩家在任何重力方向掉出房间。
- `Camera2D.position` 改为房间中心 `(360, 360)`。
- `UIRoot.pivot_offset` 改为 `(360, 360)`。
- 玩家、低障碍、高障碍、钥匙、出口、提示区域的坐标也要按正方形房间重新摆放。

### 布局要求

正方形房间内仍要保持教学关流程：

- 玩家初始位置在左下角。
- 保留一个低矮障碍，用于触发跳跃教学。
- 保留一个更高障碍，正常跳跃不能直接越过。
- 钥匙必须放在普通跳跃拿不到的位置，需要通过重力旋转到达。
- 出口初始不可用，拾取钥匙后激活。
- 旋转 4 次后，画面和重力应回到初始状态。

## 验收标准

修复完成后，请按以下顺序手动验证：

1. 使用 Godot 4.7 打开 `projects/godot-gravity-tutorial-demo/project.godot` 并运行主场景。
2. 窗口视口为 `720 x 720` 正方形。
3. 玩家初始在左下角，四边碰撞正常，不会掉出房间。
4. 碰到低障碍并解锁 `Space` 后，每按一次 `Space`：
   - 角色重力切换。
   - 游戏画面以房间中心为轴旋转 90 度。
   - UI 提示文字同步旋转 90 度。
5. 连续按 4 次 `Space` 后，画面、UI 和重力都回到初始状态。
6. 在四个重力方向下，玩家都能被对应边界挡住，不会穿墙或掉出地图。
7. 钥匙和出口流程仍然可用：拾取钥匙后出口激活，接触出口后显示通关提示。

## 输出要求

请完成修改后，报告以下内容：

1. 实际修改了哪些文件。
2. `project.godot` 的 Godot 版本标记。
3. `Camera2D` 和 `UIRoot` 的最终旋转实现。
4. 正方形房间的最终尺寸和边界结构。
5. 手动测试结果。
