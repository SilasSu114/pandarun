# 熊猫卫士：逆转协议

正式版项目的 Godot 4.7 工程。

## 下载游玩

Windows 64 位第一版（单文件，推荐）：
[直接下载 PandaGuardian.exe](https://github.com/SilasSu114/pandarun/raw/main/PandaGuardian.exe)

下载后直接双击即可游玩，不需要解压或安装 Godot。

如需压缩包版本：
[下载 PandaGuardian_v0.1.0_windows_x64.zip](https://github.com/SilasSu114/pandarun/raw/main/release/PandaGuardian_v0.1.0_windows_x64.zip)

## 运行

使用 Godot 4.7 打开根目录的 `project.godot`，按 `F5` 运行。

## 工程结构

- `assets/`：正式场景使用的图片与布局数据。
- `scenes/`：主菜单、正式关卡和保留的演示彩蛋场景。
- `scripts/`：关卡、角色、重力、界面与平台设置脚本。
- `shaders/`：主界面使用的着色器。
- `tests/`：无界面冒烟测试，不参与正常游戏流程。
- `docs/`：工程交接、资源映射和架构记录。
- `export_presets.cfg`：Windows 导出预设。

`.godot/` 是编辑器自动生成的缓存，可随时重建，不应提交。

## 自动验证

在项目根目录执行：

```powershell
godot --headless --path . --script tests/level_2_smoke.gd
godot --headless --path . --script tests/restart_smoke.gd
godot --headless --path . --script tests/push_box_unstick_smoke.gd
```

## 当前入口

- 主场景：`res://scenes/main_menu.tscn`
- 正式关卡：`res://scenes/level_1.tscn` 至 `res://scenes/level_3.tscn`
- 演示彩蛋：`res://scenes/main.tscn`
