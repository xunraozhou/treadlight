# 开发与验证说明

## 运行环境与结构

使用 Godot 4.4.1 Standard 与 GDScript，无需 .NET 或额外插件。默认主场景是 `campaign/main.tscn`，Windows 试玩包使用 OpenGL 兼容渲染器。

| 文件 | 职责 |
| --- | --- |
| `campaign/player.gd` | 角色移动、真实地面起跳与落地信号 |
| `campaign/beat_clock.gd` | 音乐时钟、判定窗口、同拍去重和校准 |
| `campaign/light_bridge.gd` | 四拍临时桥、到期失效和永久修复 |
| `campaign/laser.gd` | 激光预警、实体伤害与状态更新 |
| `campaign/campaign.gd` | 房间布局、修复目标、开门、计分与流程 |
| `campaign/hud.gd` | 菜单、教学、节拍提示与结算展示 |

## 节拍与移动参数

| 参数 | 当前值 |
| --- | --- |
| 音乐速度 | 120 BPM，每拍 0.5 秒 |
| 准确 / 良好窗口 | 节拍前后 80 / 150 ms |
| 平地起落 | 约两拍，普通与踩拍跳跃共用轨迹 |
| 临时桥寿命 | 自激活起四拍，最后一拍闪烁 |
| 永久桥条件 | 有效造桥后真实落在该桥上，且落地判定成功 |
| 水平速度 / 桥宽 | 140 px/s / 200 px |
| 激光 | 提前一拍预警，实体危险一拍 |
| 校准范围 | ±250 ms，每次调整 10 ms |

时钟采用单调系统时间，并减去下一次混音等待与音频输出延迟。音乐、判定、机关和提示读取同一时间基准。暂停同时冻结音乐与时钟；当前房间重试后重新计时。

## 检查命令

```powershell
python tools/audit_sources.py
godot --headless --path . --import
godot --headless --path . --script res://tests/run_tests.gd --fixed-fps 60
```

`godot` 可替换为本机 Godot console 可执行文件的完整路径。Windows 上也可使用检查导入与运行时错误的封装：

```powershell
./tools/test.ps1 -Godot 'C:/path/to/Godot_v4.4.1-stable_win64_console.exe'
```

v0.2 的 54 项自动检查覆盖判定边界、正负校准、同拍去重、起跳信号、空中输入、桥梁到期、永久桥保留、落拍修复、偏拍不修复、两岸补救、目标锁门、激光、暂停、重试和三关物理路线。源文件检查用于防止当前运行工程再次引用旧游戏资源。

机器人通关路线只提供方向与跳跃输入，不传送角色，不关闭伤害；用于检查边界的个别测试会设置初始位置与时间。截图脚本使用受控时间记录实际起落的临时桥与永久桥状态。相关脚本和文档不进入 Windows 可玩包。

自动检查不替代真人手感测试、实际音频设备校准或赛事资格核验。运行记录见 [GitHub Actions](https://github.com/xunraozhou/treadlight/actions)。

## 导出

安装 Godot 4.4.1 对应导出模板后，在项目根目录运行：

```powershell
New-Item -ItemType Directory -Force build
godot --headless --path . --export-release 'Windows Desktop' build/Treadlight.exe
```

分发时保留 EXE 与 PCK，并附上 `LICENSE`、`NOTICE`、`THIRD_PARTY_NOTICES.md` 及 `licenses/`。源码包可由对应提交生成；已发布的 v0.2 包保持为该版本快照，最新文字介绍见仓库主页。
