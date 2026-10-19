# 踏光：律动之旅 / Treadlight

**随节拍起跳，让前方的光桥亮起来。** 基于 [FireEntity1 / LIGHT//BOUND](https://github.com/FireEntity1/lightbound-demo) 的 Godot 4.4 项目改版，新增三个短房间的旅程模式。保留原版激光生存玩法和关卡编辑器入口。

![标题画面](docs/title.png)

## 直接试玩

到本仓库的 **[Releases](https://github.com/xunraozhou/treadlight/releases)** 下载 `Treadlight-Windows-x64.zip`，解压后双击 `Treadlight.exe`。Windows x64，使用 OpenGL 兼容渲染器；无需安装 Godot。请先解压整个文件夹。

源码开发：用 **Godot 4.4.1 Standard** 导入根目录的 `project.godot`，等待资源导入，然后按 **F5** 运行项目。默认主场景为 `campaign/main.tscn`。不需要 .NET。

## 操作

| 按键 | 功能 |
| --- | --- |
| A / D、← / → | 左右移动 |
| 空格、W、↑ | 从地面起跳 |
| R | 当前房间重试 |
| Esc | 暂停 / 继续，结果页返回标题 |
| Enter | 标题开始、失败重试、过关后继续 |
| [ / ] | 判定校准每次 -10 / +10 毫秒，自动保存 |
| M | 音乐开关 |

新版只使用地面单次跳跃，便于掌握相同的跳跃轨迹。原版的二段跳、下砸、冲刺等仍属于原版模式。

## 玩法

1. 开场四拍准备；底部四盏灯与角色的收缩光环提示下一拍。
2. 随时都能普通起跳。在虚线光桥前的安全平台踩拍起跳，会唤醒这一段光桥。
3. 距最近节拍 **±80 ms** 为「准确」，**±150 ms** 为「良好」，两者均可点亮光桥。
4. 光桥自实际激活时刻起持续 **4 拍 / 2 秒**，最后一拍闪烁；保持向前移动，及时通过。
5. 偏拍仍能正常跳跃；可以在安全平台等待下一拍。同一拍只接受一次成功判定，空中按键不能刷分。
6. 金色虚线是激光的一拍预警，粉色实体光束危险一拍。可以等待，也可以用普通跳跃越过。
7. 坠落或触碰激光后按 Enter/R 重试：当前房间的音乐、计分和机关重新开始。

准确 +100 光能，良好 +60。只累计已通关房间的光能，失败尝试不计入总分。

![光桥与节拍提示](docs/gameplay.png)

## 三个房间

| 房间 | 内容 | 自动路线用时，不含两秒准备 |
| --- | --- | --- |
| 听见节拍 | 固定平台、一段光桥，无激光 | 约 18 秒 |
| 穿过光隙 | 一段光桥，同一种横向激光 | 约 20 秒 |
| 点亮终点 | 两段光桥与激光组合 | 约 25 秒 |

路线长度、140 px/s 移速、200 px 光桥和跳跃参数一起验证过。首次游玩通常会因等待节拍而更慢。场景会在过关后逐渐恢复颜色。

## 时间同步与声音

统一时钟位于 `campaign/beat_clock.gd`。每次房间重开记录单调系统时间，并补偿 `AudioServer.get_time_to_next_mix()` 和 `AudioServer.get_output_latency()`；判定、光桥、激光、提示均读取同一时间基准。暂停会同时冻结音乐与时钟。

采用 Godot 对短音乐片段建议的[系统时钟同步方案](https://docs.godotengine.org/en/4.4/tutorials/audio/sync_with_audio.html)。这里的配乐是 16 秒无缝循环的原创合成试作曲，120 BPM；当前房间最长只需几十秒，未加入变速。源码、固定随机种子和生成方式在 `tools/generate_music.py`，仅依赖 Python 标准库。

蓝牙耳机、电视和不同声卡可能需要校准。正校准值表示接受稍晚于节拍的输入；在标题或游玩时用 `[`、`]` 调整，范围 ±250 ms。设置保存在 Godot `user://treadlight.cfg`。

## 结构

| 文件 | 职责 |
| --- | --- |
| `campaign/player.gd` | 移动、地面起跳与实际起跳信号 |
| `campaign/beat_clock.gd` | 音频时间基准、判定、去重和校准 |
| `campaign/light_bridge.gd` | 四拍实体光桥、最后一拍闪烁 |
| `campaign/laser.gd` | 一拍预警、一拍伤害的横向激光 |
| `campaign/campaign.gd` | 三个房间、计分、流程、暂停与重试 |
| `campaign/hud.gd` | 中文界面、节拍灯、结果反馈 |
| `scripts/`、`scenes/`、`components/` | 保留的原版游戏及编辑器 |

## 验证与导出

```powershell
# godot 可替换为本机 Godot console 可执行文件的完整路径。
godot --headless --path . --import
godot --headless --path . --script res://tests/run_tests.gd --fixed-fps 60
# 或使用会检查运行时错误的封装：
./tools/test.ps1 -Godot 'C:/path/to/Godot_v4.4.1-stable_win64_console.exe'
```

测试覆盖判定边界、校准、同拍去重、桥梁碰撞开关/过期、激光预警/伤害、真实地面起跳、空中输入、暂停恢复、失败、重试以及三关实际物理路线。自动路线只提供方向/跳跃输入，不传送角色，不关闭伤害；通过固定步长驱动共享时钟以保证结果可复现。测试脚本与截图脚本不会进入可玩包。

截图由 `tests/capture.gd` 在 Godot OpenGL 渲染器下生成；游戏场景使用受控时间与位置展示光桥状态。UI 已检查中文显示、遮罩层级与主要文字范围。实际音频设备的听感与延迟仍需人工校准体验。

GitHub Actions 会在推送后使用 Godot 4.4.1 执行导入和同一组测试。Windows 发布构建需要安装 4.4.1 导出模板，然后运行：

```powershell
New-Item -ItemType Directory -Force build
godot --headless --path . --export-release 'Windows Desktop' build/Treadlight.exe
```

## 来源与许可

原项目作者 **FireEntity1**，仓库：[lightbound-demo](https://github.com/FireEntity1/lightbound-demo)，原版游戏：[LIGHT//BOUND](https://fire-entity.itch.io/lightbound)。原始 Apache-2.0 许可保留在 `LICENSE`，署名见 `NOTICE`，字体及引擎许可见 `THIRD_PARTY_NOTICES.md` 和 `licenses/`。原 README 保存在 `docs/UPSTREAM_README.md`，原提交历史保留。

本改版新增独立旅程模式和原创合成试作配乐。原音乐制作工程含 Windows 不支持的 `::` 目录名，已从当前树移除；它们不参与游戏运行，仍可从上游及 Git 历史获取。原工程的开发者统计插件已停用，原版编辑器的数据目录改为 Godot `user://lightbound-data`。参赛前请按赛事对复用代码的要求说明本项目来源。
