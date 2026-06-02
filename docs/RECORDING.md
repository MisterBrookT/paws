# 录制 Demo GIF

## 推荐流程（高清源 + 后期放大角标）

终端无法把单行 HUD 的字号单独放大（CJK 标签也没法用块状字拼），所以右上角状态
靠**后期放大**来突出，而不是改 app。为保证放大后清晰，录**高清 `.mov` 并保留**：

1. 准备：Kaku 窗口 ~1000px 宽、字体 16pt+；先给 agent 发一个会跑 ~8–10s 的小任务，
   让右上角 HUD 转圈。
2. `CMD+Shift+5` → 录制选定区域，框住 Kaku 窗口。
3. 动作（慢一点）：停 2s 露出右上角 → `CMD+G` 开菜单 → 选 🌍 Earth Online → 停 5s
   展示游戏+HUD（别挡右上角，让它在录制中跑完、状态翻成闪烁 ✓）→ `CMD+G` 切回。
4. 把高清 `.mov` 交给后期：烧入 `⌘G` 键位提示 + 右上角 HUD 平滑放大特写，最后才导出 GIF。

> 在高清 `.mov` 上做完字幕/放大再转 GIF，角标放大才不糊。

## 前置依赖

```bash
brew install ffmpeg
```

## 一键录制（快速版，无放大）

```bash
./scripts/record-demo.sh
```

脚本会录制 30 秒屏幕，自动转成 `docs/demo.gif`（800px 宽，12fps）。
注意：这个会把 `.mov` 删掉，**不适合需要后期放大角标的版本**。

## 录制技巧

- 窗口宽度 ~1000px，字体 16pt
- 先启动一个 agent session，让它在跑
- 录制开始后：CMD+G 打开游戏 → 玩几秒 → CMD+G 切回
- 动作不要太快，GIF 帧率低

## 手动录制（备选）

如果脚本不好使，可以用 CMD+Shift+5 录屏，然后手动转：

```bash
ffmpeg -i input.mov -vf "fps=12,scale=800:-1:flags=lanczos" -loop 0 docs/demo.gif
```

## 字幕 / 转场

录制完 `demo.gif` 后，可以用脚本添加字幕和标题卡。

### 添加定时字幕

```bash
# 用法: ./scripts/caption.sh <输入.gif> <输出.gif> <文字> <开始秒> <结束秒>
./scripts/caption.sh docs/demo.gif docs/demo2.gif "CMD+G to switch" 2 5
```

字幕会以半透明黑底白字的形式烧录在画面底部。可以多次叠加：

```bash
# Paws demo 推荐字幕序列
./scripts/caption.sh docs/demo.gif /tmp/s1.gif "选个游戏" 0 3
./scripts/caption.sh /tmp/s1.gif /tmp/s2.gif "Agent 完成会闪烁提醒" 5 8
./scripts/caption.sh /tmp/s2.gif docs/demo-captioned.gif "CMD+G 切回" 9 12
```

### 添加标题卡

在 GIF 开头加一个 1.5 秒的标题画面：

```bash
# 用法: ./scripts/title-card.sh <gif> [标题文字]
./scripts/title-card.sh docs/demo-captioned.gif
# → 生成 docs/demo-captioned-titled.gif，原文件不变

# 自定义标题
./scripts/title-card.sh docs/demo.gif "🐾 Paws Demo"
```

### 完整流程示例

```bash
./scripts/record-demo.sh                                          # 录制
./scripts/caption.sh docs/demo.gif /tmp/s1.gif "选个游戏" 0 3
./scripts/caption.sh /tmp/s1.gif /tmp/s2.gif "Agent 完成会闪烁提醒" 5 8
./scripts/caption.sh /tmp/s2.gif docs/demo-final.gif "CMD+G 切回" 9 12
./scripts/title-card.sh docs/demo-final.gif                       # 加标题卡
```
