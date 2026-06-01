#!/bin/bash
# Add a timed text caption to a GIF (burned in at the bottom).
# Usage: ./scripts/caption.sh <input.gif> <output.gif> <text> <start_sec> <end_sec>
# Example: ./scripts/caption.sh docs/demo.gif docs/demo2.gif "CMD+G to switch" 2 5
set -e

if [ $# -lt 5 ]; then
  echo "Usage: $0 <input.gif> <output.gif> <text> <start_sec> <end_sec>"
  exit 1
fi

INPUT="$1"; OUTPUT="$2"; TEXT="$3"; START="$4"; END="$5"
FONT="/System/Library/Fonts/Supplemental/Arial.ttf"
[ ! -f "$FONT" ] && FONT="/System/Library/Fonts/Helvetica.ttc"

ffmpeg -y -i "$INPUT" \
  -vf "drawtext=fontfile=${FONT}:text='${TEXT}':fontcolor=white:fontsize=24:\
x=(w-text_w)/2:y=h-text_h-20:\
box=1:boxcolor=black@0.6:boxborderw=8:\
enable='between(t,${START},${END})'" \
  -loop 0 "$OUTPUT" 2>/dev/null

echo "✓ 字幕已添加: $OUTPUT"
