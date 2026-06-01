#!/bin/bash
# Paws demo recorder
# Usage: ./scripts/record-demo.sh
# Records your screen for 30 seconds, then converts to GIF.

set -e

DURATION=30
OUTPUT_DIR="$(cd "$(dirname "$0")/.." && pwd)/docs"
MOV_FILE="$OUTPUT_DIR/demo.mov"
GIF_FILE="$OUTPUT_DIR/demo.gif"

mkdir -p "$OUTPUT_DIR"

# Check ffmpeg
if ! command -v ffmpeg &>/dev/null; then
  echo "需要 ffmpeg: brew install ffmpeg"
  exit 1
fi

echo "🐾 Paws Demo 录制"
echo ""
echo "录制前请准备:"
echo "  1. 把 Kaku 窗口调到合适大小 (~1000px 宽)"
echo "  2. 确保字体够大 (16pt)"
echo "  3. 准备好一个 agent session 在跑"
echo ""
echo "录制开始后你需要做:"
echo "  1. CMD+G → 选一个游戏"
echo "  2. 玩几秒 (展示游戏 + HUD)"
echo "  3. CMD+G → 切回 agent"
echo ""
echo "按 Enter 开始 ${DURATION}s 录制 (录制整个屏幕)..."
read

echo "⏺  录制中... (${DURATION}s 后自动停止)"
screencapture -v -V $DURATION "$MOV_FILE"

echo "🎬 转换为 GIF..."
ffmpeg -y -i "$MOV_FILE" \
  -vf "fps=12,scale=800:-1:flags=lanczos" \
  -loop 0 "$GIF_FILE" 2>/dev/null

rm -f "$MOV_FILE"
echo ""
echo "✓ 完成! GIF 保存在: $GIF_FILE"
echo "  大小: $(du -h "$GIF_FILE" | cut -f1)"
echo ""
echo "下一步: git add docs/demo.gif && git commit && git push"
echo "README 已经引用了这个文件，push 后就能看到。"
