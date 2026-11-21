# Godot 4.7 修改提示词：平滑重力旋转、放大正方形房间、移除文字引导

你是一个 Godot 4.7 游戏开发 Agent。请修改 `projects/godot-gravity-tutorial-demo/` 项目，不要修改 `projects/godot-gravity-tutorial-demo-(4.3)/`。目标是在保留现有核心玩法的基础上，完成以下三点：

1. `Space` 切换重力时增加平滑过渡动画，不再瞬间旋转 90 度。
2. 把正方形房间放大，为后续放置更多关卡元素预留空间。
3. 移除当前所有文字引导，不再在画面上显示教学提示文本。

## 版本与范围

请继续使用 Godot 4.7 语法和 API，并确认：

```ini
config/features=PackedStringArray("4.7")
```

只修改 `projects/godot-gravity-tutorial-demo/`。不要处理旧目录、不要重建项目、不要添加菜单、存档、音效或复杂美术资源。

## 修改 1：重力切换改为平滑过渡

当前 `GravityManager.try_rotate()` 会立即修改重力索引、重力向量和相机/UI 旋转，导致视觉上非常突兀。请将旋转改为带过渡动画的状态。

### 交互规则

- 玩家解锁 `Space` 后，每按一次 `Space` 只触发一次 90 度顺时针旋转。
- 旋转过程中再次按 `Space` 无效，不要排队触发下一次旋转。
- 旋转过程中不要让 UI 或相机出现跳变。
- 动画结束后，玩家实际使用的重力向量再切换到新方向。
- 连续按 4 次后，画面、UI 和重力应回到初始状态。

### 实现要求

在 `gravity_manager.gd` 中使用 Godot `Tween` 或等价机制驱动过渡动画：

1. 增加一个类似 `is_rotating` 的状态，标记当前是否有旋转动画进行中。
2. `Space` 触发时：
   - 先判断 `rotation_unlocked` 和 `is_rotating`。
   - 更新 `rotation_index`，但不要立刻把 `current_gravity` 应用给玩家。
   - 计算新的目标重力向量。
   - 将相机和 UI 的目标旋转设置为当前视觉角度加 `90.0` 度。
3. 使用同一个动画时长同步旋转：

```gdscript
const ROTATION_DURATION := 0.35
```

相机和 UI 的旋转建议使用 `Tween`，并使用平滑的插值方式，例如：

```gdscript
tween.set_trans(Tween.TRANS_SINE)
tween.set_ease(Tween.EASE_IN_OUT)
```

4. 不要把相机/UI 旋转角度简单 wrap 到 `0-360` 后再插值。应保存一个累计的 `visual_rotation_degrees`，每次加 `90.0`，否则从 `270` 度转回 `0` 度时可能出现反向旋转。
5. 动画完成后再执行：
   - 把目标重力向量赋值给 `current_gravity`。
   - 通知 `Player` 使用新的重力向量。
   - 将 `is_rotating` 设为 `false`。
6. 旋转过程中玩家输入应保持稳定：
   - 可以暂停玩家的移动和跳跃输入。
   - 也可以继续使用旧重力完成短暂下落，但不要在动画中途突然改成新重力。
   - 不要让角色穿过四面边界。
7. 如果使用 `Camera2D.position_smoothing_enabled = true`，动画开始或结束时要正确调用 `reset_smoothing()`；如果保持 `false`，也必须在场景中确认该设置不会造成额外抖动。

### 推荐信号结构

可以让 `GravityManager` 暴露类似信号：

```gdscript
signal rotation_started(target_gravity: Vector2, target_index: int)
signal rotation_finished(current_gravity: Vector2, current_index: int)
```

`main.gd` 监听 `rotation_finished` 后再调用：

```gdscript
player.set_gravity(gravity_manager.current_gravity, gravity_manager.get_screen_right())
```

这样能避免重力在动画还没结束时就被提前切换。

## 修改 2：放大正方形房间

当前 `720 x 720` 的房间对后续关卡内容偏小。请将可游玩房间和游戏视口统一放大为：

```text
1080 x 1080
```

### 项目设置

在 `project.godot` 中设置：

```ini
[display]

window/size/viewport_width=1080
window/size/viewport_height=1080
window/stretch/mode="canvas_items"
window/stretch/aspect="keep"
```

### 场景调整

请同步调整 `scenes/main.tscn`：

- 背景、上下左右四面墙共同构成 `1080 x 1080` 的封闭正方形。
- 四面墙必须覆盖完整边界，任何重力方向下玩家都不能穿出房间。
- `Camera2D.position` 改为 `(540, 540)`。
- 如果 UI 根节点仍保留，其旋转中心应为 `(540, 540)`，或在运行时按 `ui_root.size * 0.5` 计算。
- 不要只是把旧元素简单平移；请根据更大的空间重新摆放玩家、低障碍、高障碍、钥匙和出口，让间距更合理。

### 布局要求

- 玩家初始位置仍在左下角附近。
- 保留低障碍和高障碍，低障碍用于解锁 `Space`，高障碍不能被普通跳跃直接越过。
- 钥匙仍然必须通过重力旋转才能拿到。
- 出口仍然在拾取钥匙后才激活。
- 为后续更多关卡元素预留明显的空白区域，不要把房间塞满。

## 修改 3：移除文字引导

请删除当前画面上所有教学引导文本，包括类似下面的提示：

- “按 A / D 左右移动”
- “按 W 跳跃”
- “靠近高障碍物时，按 Space 旋转重力”
- “钥匙已拾取，前往出口”
- “通关 / Level Clear”

### 具体要求

1. 移除 `PromptLabel` 或将所有教学提示文本清空且不再显示。
2. 删除或禁用 `main.gd` 中与教学文本相关的 `_set_prompt()` 调用、提示文案状态和对应信号处理逻辑。
3. 不要在场景中保留任何固定显示的操作说明。
4. 通关后可以只做一个简单的视觉状态变化，例如玩家变色、出口变色或场景短暂暂停；不要新增文字提示。
5. 如果 `UIRoot` 已经没有任何可见内容，可以保留一个空的 UI 根节点供后续使用，也可以直接删除；但如果保留，它仍应跟随重力旋转逻辑更新。

## 保留的核心机制

虽然文字引导被移除，但以下机制必须保留：

- `A` / `D` 控制当前屏幕左右方向移动。
- `W` 沿当前重力反方向跳跃。
- `Space` 在碰到低障碍后才解锁；解锁前按 `Space` 无效。
- `Space` 顺时针旋转重力，并伴随平滑过渡动画。
- 钥匙激活出口。
- 接触激活出口后过关。

## 验收标准

完成后请手动验证以下内容：

1. 使用 Godot 4.7 打开 `projects/godot-gravity-tutorial-demo/project.godot`。
2. 游戏窗口/视口为 `1080 x 1080` 正方形。
3. 房间四边封闭，玩家在任何重力方向都不会掉出地图。
4. 解锁 `Space` 前，按 `Space` 无效。
5. 解锁后按一次 `Space`：
   - 相机和 UI 以平滑动画旋转 90 度。
   - 动画过程中再次按 `Space` 不会立刻触发下一次旋转。
   - 动画结束后角色使用新的重力方向。
6. 连续按 4 次 `Space`，画面、UI 和重力回到初始状态。
7. 场景中没有显示任何文字引导。
8. 钥匙拾取后出口激活，接触激活出口后仍能过关。

## 完成后报告

请简要报告：

1. 修改了哪些文件。
2. 平滑旋转的时长和触发逻辑。
3. 正方形房间的最终尺寸。
4. 已移除的文字引导内容。
5. 手动测试结果。
