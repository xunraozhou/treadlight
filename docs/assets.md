# 美术、音乐与依赖清单

本清单记录 v0.2 实际使用的画面、声音与依赖。几何场景由代码实时绘制，源码和生成工具随工程提供；下列链接均指向仓库中的实际文件。

## 一、画面资源与实现

| 内容 | 文件或实现位置 | 方式与用途 |
| --- | --- | --- |
| 遗迹、背景星点、出口 | [campaign.gd](../campaign/campaign.gd) | Godot 绘制几何图形、线条和色块 |
| 角色、轨迹、节拍光环 | [player.gd](../campaign/player.gd) | 随运动与节拍更新 |
| 青桥、金桥、修复波纹 | [light_bridge.gd](../campaign/light_bridge.gd) | 按临时、固定和到期状态绘制 |
| 激光与预警 | [laser.gd](../campaign/laser.gd) | 虚线预警与实体危险光束 |
| 菜单、节拍灯、提示 | [hud.gd](../campaign/hud.gd) | Godot 控件和绘制接口 |
| 项目图标 | [icon.svg](../icon.svg) | 矢量几何图形 |

## 二、实际画面截图

| 文件 | 展示内容 |
| --- | --- |
| [title.png](title.png) | 标题与作品视觉 |
| [gameplay.png](gameplay.png) | 随拍起跳与临时桥 |
| [restored.png](restored.png) | 落拍修复后的金桥 |
| [tutorial.png](tutorial.png) | 游戏内玩法教学 |
| [pause.png](pause.png) | 暂停与操作提示 |

截图由 [capture.gd](../tests/capture.gd) 在受控时间下驱动实际角色起落，并采集 Godot 渲染结果。它们用于说明画面与状态，不作为真人通关记录。

## 三、音乐与声音

| 文件 | 内容 | 来源与制作方式 |
| --- | --- | --- |
| [awakening.wav](../campaign/audio/awakening.wav) | 120 BPM、16 秒循环配乐 | 由本项目的 [generate_music.py](../tools/generate_music.py) 使用 Python 标准库合成，无网络采样 |

当前游戏尚未加入单独的修复、失败和通关音效。视频解说属于介绍材料，不是游戏内声音资源；本地成片上传情况见[材料清单](submission-checklist.md)。

## 四、字体、引擎与许可

| 类别 | 来源与处理 |
| --- | --- |
| 界面字体 | 请求操作系统已有字体，不随包分发字体文件；目标设备须检查中文显示 |
| Godot 引擎 | Godot 4.4.1，MIT 许可，见 [Godot-LICENSE.txt](../licenses/Godot-LICENSE.txt) |
| 引擎内置依赖 | 见 [Godot-COPYRIGHT.txt](../licenses/Godot-COPYRIGHT.txt) |
| 项目代码 | Apache-2.0，见 [LICENSE](../LICENSE) 与 [NOTICE](../NOTICE) |

更完整的依赖说明见[第三方声明](../THIRD_PARTY_NOTICES.md)。

## 五、交付整理建议

将以下实际文件随最终材料提供，便于查看和复核：

1. 图标及五张画面截图。
2. 循环音轨 `awakening.wav`。
3. 本清单、必要的许可声明。
4. 完整工程中的绘制代码、截图工具和音乐生成工具。

上述文件已有工程内路径；目前尚未另生成集中素材包。手册并未限定独立素材 ZIP，可使用清楚的文件夹结构提交。后续加入外部图像、音乐或音效时，补充作者、原始来源、许可和实际使用位置，不填写未经确认的授权或归属。
