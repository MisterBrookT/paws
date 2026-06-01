# 录制 Demo GIF

## 前置依赖

```bash
brew install ffmpeg
```

## 一键录制

```bash
./scripts/record-demo.sh
```

脚本会录制 30 秒屏幕，自动转成 `docs/demo.gif`（800px 宽，12fps）。

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
