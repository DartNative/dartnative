#!/bin/bash
# Installs one side's app on an iPhone, launches it without a tool attached,
# and copies its table off the phone when it is done.
#   tool/run_ios.sh <device UDID> <Runner.app> <bundle id> <output.txt>
# Both apps write the table to tmp/prefs_bench.txt in their container.
D=$1; APP=$2; ID=$3; OUT=$4
xcrun devicectl device install app --device "$D" "$APP" > /dev/null || exit 1
rm -f "$OUT"
xcrun devicectl device process launch --terminate-existing --device "$D" "$ID" > /dev/null
sleep 8
for i in $(seq 1 360); do
  xcrun devicectl device copy from --device "$D" --domain-type appDataContainer \
    --domain-identifier "$ID" --source tmp/prefs_bench.txt --destination "$OUT" \
    > /dev/null 2>&1 && grep -q "DONE\|FAIL" "$OUT" && break
  sleep 5
done
echo "$(grep -c '^| [a-z]' "$OUT" 2>/dev/null) rows in $OUT"
