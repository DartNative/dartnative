#!/bin/bash
# Legend List's example/autoscroll.sh with the gesture reversed: the same
# swipe (700 pixels in 48 ms, 100 ms apart, at the left edge) from the
# upper point to the lower one, so the list scrolls back up at the same
# pace it came down. Thank you to @naqvitalha for the original script.
#
# Usage: ./autoscroll_up.sh [SPEED_MULTIPLIER] [DURATION_MS]

START_Y=800
X=2
SWIPE_DISTANCE=700
BASE_SWIPE_DURATION=48
SLEEP_BETWEEN=100

SPEED_MULTIPLIER=${1:-1}
DURATION=${2:--1}
SWIPE_DURATION=$(echo "scale=0; $BASE_SWIPE_DURATION / $SPEED_MULTIPLIER" | bc)
if [ -z "$SWIPE_DURATION" ] || [ "$SWIPE_DURATION" -lt 1 ]; then SWIPE_DURATION=1; fi
END_Y=$(( START_Y + SWIPE_DISTANCE ))
SLEEP_SECONDS=$(echo "scale=3; $SLEEP_BETWEEN / 1000" | bc)

START_TIME=$(date +%s)
while true; do
  adb shell input swipe $X $START_Y $X $END_Y $SWIPE_DURATION
  sleep "$SLEEP_SECONDS"
  if [ "$DURATION" -ne -1 ]; then
    ELAPSED_MS=$(( ($(date +%s) - START_TIME) * 1000 ))
    if [ "$ELAPSED_MS" -ge "$DURATION" ]; then break; fi
  fi
done
