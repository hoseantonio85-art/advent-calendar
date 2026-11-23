#!/usr/bin/env bash
set -euo pipefail
cd flutter/example
mkdir -p build/android-motion
adb shell wm size 720x1280
adb shell wm density 320
adb shell settings put system font_scale 0.8
adb logcat -c
adb shell screenrecord --size 720x1280 --bit-rate 1000000 --time-limit 150 /sdcard/advent-motion.mp4 > build/android-motion/recorder.log 2>&1 &
recorder_pid=$!
status=0
flutter drive --no-enable-impeller --driver=test_driver/integration_test.dart --target=integration_test/calendar_motion_test.dart --use-application-binary=build/app/outputs/flutter-apk/app-debug.apk > build/android-motion/driver.log 2>&1 || status=$?
adb shell pkill -INT screenrecord || true
wait "$recorder_pid" || true
adb pull /sdcard/advent-motion.mp4 build/android-motion/android-motion.mp4 || true
adb logcat -d > build/android-motion/android-logcat.txt 2>&1 || true
cat build/android-motion/driver.log
exit "$status"
