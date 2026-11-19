#!/bin/bash
# Installs one side's APK on an Android phone, runs it, and saves its table.
#   tool/run_android.sh <adb device id> <apk> <package> <output.txt>
# Both apps print the table to logcat, each line tagged [PREFS_BENCH].
E=$1; APK=$2; PKG=$3; OUT=$4
adb -s "$E" install -r "$APK" > /dev/null || exit 1
adb -s "$E" shell am force-stop "$PKG"
adb -s "$E" logcat -c
ACT=$(adb -s "$E" shell cmd package resolve-activity --brief "$PKG" | tail -1)
adb -s "$E" shell am start -n "$ACT" > /dev/null
for i in $(seq 1 900); do
  adb -s "$E" logcat -d | grep -q "\[PREFS_BENCH\] \(DONE\|FAIL\)" && break
  sleep 2
done
adb -s "$E" logcat -d | grep "\[PREFS_BENCH\]" | sed 's/^.*\[PREFS_BENCH\] //' > "$OUT"
adb -s "$E" shell am force-stop "$PKG"
echo "$(grep -c '^| [a-z]' "$OUT") rows in $OUT"
