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
