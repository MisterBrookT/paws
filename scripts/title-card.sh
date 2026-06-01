#!/bin/bash
# Prepend a title card to a GIF.
# Usage: ./scripts/title-card.sh <gif> [title-text]
set -e

if [ $# -lt 1 ]; then
  echo "Usage: $0 <gif> [title-text]"
  exit 1
fi

GIF="$1"
TITLE="${2:-🐾 Paws — play while your agent works}"
FONT="/System/Library/Fonts/Supplemental/Arial.ttf"
[ ! -f "$FONT" ] && FONT="/System/Library/Fonts/Helvetica.ttc"

TMPDIR_CARD="$(mktemp -d)"
CARD="$TMPDIR_CARD/card.gif"

# Get dimensions from input GIF
DIMS=$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=p=0 "$GIF")
W=$(echo "$DIMS" | cut -d, -f1)
H=$(echo "$DIMS" | cut -d, -f2)

# Generate a 1.5s title card GIF (dark bg, white text)
ffmpeg -y -f lavfi -i "color=c=0x1a1a1a:s=${W}x${H}:d=1.5:r=12" \
  -vf "drawtext=fontfile=${FONT}:text='${TITLE}':fontcolor=white:fontsize=28:\
x=(w-text_w)/2:y=(h-text_h)/2" \
  -loop 0 "$CARD" 2>/dev/null

# Concatenate: title card + original gif
OUTPUT="${GIF%.gif}-titled.gif"
ffmpeg -y -i "$CARD" -i "$GIF" \
  -filter_complex "[0:v][1:v]concat=n=2:v=1:a=0[out]" \
  -map "[out]" -loop 0 "$OUTPUT" 2>/dev/null

rm -rf "$TMPDIR_CARD"
echo "✓ 标题卡已添加: $OUTPUT"
echo "  原始文件未修改: $GIF"
