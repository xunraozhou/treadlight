# 游戏美术与声音

《踏光：两拍回响》v0.2 的音画素材已集中整理，可直接浏览图像和试听配乐，并查阅对应源码与来源说明。

**[下载完整素材包](https://github.com/xunraozhou/treadlight/releases/download/v0.2.0/Treadlight-v0.2-game-art-audio.zip)** · [项目素材总表](../assets.md) · [逐文件清单](素材清单.csv)

| 内容 | 数量与规格 | 原工程位置 |
| --- | --- | --- |
| 项目图标 | 1 个；128 × 128 SVG | [icon.svg](../../icon.svg) |
| 游戏画面 | 5 张；1280 × 720 PNG | [标题](../title.png)、[起跳造路](../gameplay.png)、[落拍留光](../restored.png)、[教学](../tutorial.png)、[暂停](../pause.png) |
| 循环配乐 | 1 段；120 BPM、16 秒，44.1 kHz 单声道 PCM16 | [awakening.wav](../../campaign/audio/awakening.wav) |
| 实现与生成文件 | 10 份源码与配置快照 | 绘制脚本、节拍控制、主场景、工程配置、截图与音乐工具 |
| 来源及许可 | 中文说明、逐文件清单及完整声明 | 与素材一同放在下载包内 |

![随拍起跳的实际画面](../gameplay.png)

图形主要由工程代码实时绘制，截图来自实际 Godot 渲染；音轨由 Python 标准库合成，无网络采样。当前没有独立修复、失败和通关音效。素材包保留原始文件，没有改动运行中的图形或音乐。

下载包内的 `README.md` 提供浏览入口，`素材来源与用途.md` 解释制作方式，`素材清单.csv` 对照归档路径与工程位置。系统字体文件不随包分发。源码快照供查阅；运行游戏及重新生成画面时使用完整工程。

整理日期：2026 年 10 月 23 日。音画文件对应 v0.2，素材快照基于 [工程提交](https://github.com/xunraozhou/treadlight/commit/1d64f910fe65506c3d2b5ffa94ae4d8b7abe4dd2)。本目录汇总游戏素材；演示稿的摄影与图标见[演示素材清单](../presentation/asset-sources.md)。
