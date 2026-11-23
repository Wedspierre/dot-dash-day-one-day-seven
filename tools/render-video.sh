#!/bin/bash
# render-video.sh — assemble the day-one-day-seven video from recorded frames.
# Usage: render-video.sh <frames-dir> [output.mp4]
# The frames dir holds frames-day-one/ and frames-day-seven/ (30 fps JPEGs
# from tools/record-frames.mjs) plus makefun-card-9x16-transparent.webm and
# JetBrainsMono-Bold.ttf for the referral end card. Produces a 1080x1920,
# H.264 + AAC MP4, 26 s: day one (0-8 s), transition (8-10 s), day seven
# (10-22 s), close-up of the newest build (22-26 s), with make.fun's
# referral end card (press pack, 9:16 transparent webm) laid over the last
# 2.5 s and the referral code typed into its field, per press/llms.txt.
set -euo pipefail
FRAMES_DIR="${1:?frames dir}"; OUT="${2:-day-one-day-seven-final.mp4}"
cd "$FRAMES_DIR"
BOLD=/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf
MONO=$FRAMES_DIR/JetBrainsMono-Bold.ttf
CARD=$FRAMES_DIR/makefun-card-9x16-transparent.webm
CODE=ta01qs0h

# Day one, 0-8 s
ffmpeg -y -v error -framerate 30 -i frames-day-one/frame-%04d.jpg \
  -vf "scale=1080:1920:flags=lanczos,
drawtext=fontfile=$BOLD:text='DAY 1':fontsize=120:fontcolor=white:borderw=3:bordercolor=black:x=(w-text_w)/2:y=620:enable='between(t,0,2.2)',
drawtext=fontfile=$BOLD:text='I built a tiny game.':fontsize=56:fontcolor=white:borderw=3:bordercolor=black:x=(w-text_w)/2:y=800:enable='between(t,0,2.2)',
drawtext=fontfile=$BOLD:text='DAY ONE':fontsize=72:fontcolor=white:borderw=3:bordercolor=black:x=(w-text_w)/2:y=200:enable='between(t,2.2,8)'" \
  -c:v libx264 -pix_fmt yuv420p -r 30 seg-a.mp4

# Transition, 8-10 s
ffmpeg -y -v error -f lavfi -i color=c=0x191419:s=1080x1920:d=2 \
  -vf "drawtext=fontfile=$BOLD:text='7 DAYS LATER':fontsize=96:fontcolor=white:x=(w-text_w)/2:y=860,
drawtext=fontfile=$BOLD:text='same game, updated every day':fontsize=48:fontcolor=0xffd23f:x=(w-text_w)/2:y=1000" \
  -c:v libx264 -pix_fmt yuv420p -r 30 seg-b.mp4

# Day seven, 10-22 s (game t=0-12 s)
ffmpeg -y -v error -framerate 30 -i frames-day-seven/frame-%04d.jpg -frames:v 360 \
  -vf "scale=1080:1920:flags=lanczos,
drawtext=fontfile=$BOLD:text='DAY SEVEN':fontsize=72:fontcolor=white:borderw=3:bordercolor=black:x=(w-text_w)/2:y=200,
drawtext=fontfile=$BOLD:text='same map. same start.':fontsize=46:fontcolor=white:borderw=3:bordercolor=black:x=(w-text_w)/2:y=300:enable='between(t,0,3)'" \
  -c:v libx264 -pix_fmt yuv420p -r 30 seg-c.mp4

# Close-up of the newest build, 22-26 s (game t=12-16 s)
ffmpeg -y -v error -framerate 30 -start_number 360 -i frames-day-seven/frame-%04d.jpg -frames:v 120 \
  -vf "scale=1620:2880:flags=lanczos,crop=1080:1920:270:480,
drawtext=fontfile=$BOLD:text='the newest build':fontsize=52:fontcolor=white:borderw=3:bordercolor=black:x=(w-text_w)/2:y=1400,
drawtext=fontfile=$BOLD:text='Start yours at make.fun':fontsize=62:fontcolor=0xffd23f:borderw=3:bordercolor=black:x=(w-text_w)/2:y=1500" \
  -c:v libx264 -pix_fmt yuv420p -r 30 seg-d.mp4

# Concat + silent audio
ffmpeg -y -v error -i seg-a.mp4 -i seg-b.mp4 -i seg-c.mp4 -i seg-d.mp4 \
  -f lavfi -i anullsrc=r=44100:cl=stereo \
  -filter_complex "[0:v][1:v][2:v][3:v]concat=n=4:v=1:a=0[v]" \
  -map "[v]" -map 4:a -c:v libx264 -pix_fmt yuv420p -c:a aac -shortest -t 26 base.mp4

# Referral end card, per make.fun press/llms.txt (HOLD=0)
LEN=2.5 REST=1.433 CX=210 CY=1232 CW=5 CH=78 MID=1271 SIZE=62
D=$(ffprobe -v error -show_entries format=duration -of csv=p=0 base.mp4)
T=$(awk "BEGIN{print $D-$LEN}")
ffmpeg -y -v error -i base.mp4 -c:v libvpx-vp9 -i "$CARD" -filter_complex "
[0:v]scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920,setsar=1,fps=60,tpad=stop_mode=clone:stop_duration=0,format=yuva420p,split[clip][soft];
[soft]gblur=sigma=28,eq=saturation=0.35,fade=t=in:st=$T:d=0.8:alpha=1[soft];
[clip][soft]overlay[bg];
[1:v]format=yuva420p,setpts=PTS-STARTPTS+$T/TB[card];
[bg][card]overlay=eof_action=pass,
drawbox=x=$CX-2:y=$CY-2:w=$CW+4:h=$CH+4:color=white:t=fill:enable='gte(t,$T+$REST)',
drawtext=fontfile=$MONO:text=$CODE:fontsize=$SIZE:fontcolor=0x191419:x=$CX:y=$MID-(ascent-descent)/2:enable='gte(t,$T+$REST)'[v]" \
  -map '[v]' -map '0:a' -c:v libx264 -pix_fmt yuv420p -crf 18 -c:a aac -movflags +faststart \
  "$OUT"

ffprobe -v error -show_entries stream=codec_type,codec_name,width,height -show_entries format=duration,size -of default=nw=1 "$OUT"
