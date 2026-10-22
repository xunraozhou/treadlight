# 美术、音乐与依赖来源清单

本清单记录 v0.2 工程中的画面、音乐与依赖来源。对应文件及生成代码随工程提供。

## 本项目中的画面与音乐

| 内容 | 文件或实现位置 | 生成方式 |
| --- | --- | --- |
| 背景遗迹、星点、出口 | `campaign/campaign.gd` | 用 Godot 绘制几何图形、色块和线条 |
| 角色、轨迹与节拍光环 | `campaign/player.gd` | 用代码绘制，随角色运动与节拍更新 |
| 临时桥、永久桥、修复波纹 | `campaign/light_bridge.gd` | 用代码绘制，按机关状态切换青色与金色 |
| 激光与预警 | `campaign/laser.gd` | 用代码绘制虚线和实体光束 |
| 菜单、节拍灯与信息提示 | `campaign/hud.gd` | Godot 控件与绘制接口 |
| 项目图标 | `icon.svg` | 本项目生成的矢量几何图形 |
| 120 BPM 试作配乐 | `campaign/audio/awakening.wav` | `tools/generate_music.py` 用 Python 标准库合成，16 秒循环，无网络采样 |

以上文件由本项目迭代生成，开发过程中使用了 AI 辅助编程与设计。

## 字体与引擎

| 类别 | 来源及处理 |
| --- | --- |
| 界面字体 | 请求操作系统已有字体，不随包分发字体文件 |
| Godot 引擎 | Godot 4.4.1，MIT 许可；引擎与内置依赖声明在 `licenses/` |
| 文档截图 | `tests/capture.gd` 在受控时间下驱动实际角色起落，由 Godot 渲染后采集，位于 `docs/` |

代码许可见 [LICENSE](../LICENSE)，详细来源声明见 [NOTICE](../NOTICE) 和 [THIRD_PARTY_NOTICES.md](../THIRD_PARTY_NOTICES.md)。

## 素材导出

图标位于 `icon.svg`，音轨位于 `campaign/audio/awakening.wav`；几何场景通过代码实时绘制，静态展示可使用 `docs/` 中的实际渲染截图。复用时请保留许可与开发辅助记录。新增外部素材后，应补充作者、来源、许可和使用位置。
