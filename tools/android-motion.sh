#!/usr/bin/env bash
set -euo pipefail
cd flutter/example
mkdir -p build/android-motion
adb shell wm size 720x1280
adb shell wm density 320
adb shell settings put system font_scale 0.8
adb logcat -c

# Native system screenshots avoid converting Flutter's rendering surface.
# The integration test signals a fully laid-out state and holds it for 8 s.
capture_history() {
  for scale in 100 200; do
    local captured=false
    for ((attempt=0; attempt<360; attempt++)); do
      if adb logcat -d -v raw -s flutter:I 2>/dev/null | grep -F "HISTORY_CAPTURE_READY:$scale" >/dev/null; then
        adb exec-out screencap -p > "build/android-motion/history-countdown-android-text$scale.png"
        test -s "build/android-motion/history-countdown-android-text$scale.png"
        echo "Captured Android history at text $scale%"
        captured=true
        break
      fi
      sleep 0.5
    done
    if [[ "$captured" != true ]]; then
      echo "Timed out waiting for history capture at text $scale%" >&2
      return 1
    fi
  done
}
capture_history > build/android-motion/history-capture.log 2>&1 &
capture_pid=$!

adb shell screenrecord --size 720x1280 --bit-rate 1000000 --time-limit 150 /sdcard/advent-motion.mp4 > build/android-motion/recorder.log 2>&1 &
recorder_pid=$!
status=0
flutter drive --no-enable-impeller --driver=test_driver/integration_test.dart --target=integration_test/calendar_motion_test.dart --use-application-binary=build/app/outputs/flutter-apk/app-debug.apk > build/android-motion/driver.log 2>&1 || status=$?
if [[ "$status" == 0 ]]; then
  wait "$capture_pid" || status=$?
else
  kill "$capture_pid" 2>/dev/null || true
  wait "$capture_pid" 2>/dev/null || true
fi
adb shell pkill -INT screenrecord || true
wait "$recorder_pid" || true
adb pull /sdcard/advent-motion.mp4 build/android-motion/android-motion.mp4 || true
adb logcat -d > build/android-motion/android-logcat.txt 2>&1 || true
if [[ "$status" == 0 ]]; then
  cp build/android-motion/android-logcat.txt build/android-motion/android-logcat-first-process.txt
  adb shell am force-stop com.example.advent_demo
  adb logcat -c
  adb shell am start -W -n com.example.advent_demo/.MainActivity > build/android-motion/process-restart.log 2>&1
  restored=false
  for ((attempt=0; attempt<120; attempt++)); do
    if adb logcat -d -v raw -s flutter:I 2>/dev/null | grep -F 'REAL_RESTART_STORAGE_RESTORED' >/dev/null; then
      restored=true
      echo 'PASS: raw opened/saved and derived progress restored after Android process restart' >> build/android-motion/process-restart.log
      break
    fi
    sleep 0.5
  done
  if [[ "$restored" != true ]]; then status=1; echo 'FAIL: process restore marker not received' >> build/android-motion/process-restart.log; fi
  adb logcat -d > build/android-motion/android-logcat.txt 2>&1 || true
  adb shell am force-stop com.example.advent_demo
  cat build/android-motion/process-restart.log
fi
cat build/android-motion/driver.log
cat build/android-motion/history-capture.log
exit "$status"
