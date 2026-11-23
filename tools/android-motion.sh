#!/usr/bin/env bash
set -euo pipefail
cd flutter/example
mkdir -p build/android-motion
adb shell wm size 720x1280
adb shell wm density 320
adb shell settings put system font_scale 0.8
adb shell screenrecord --time-limit 150 /sdcard/advent-motion.mp4 > build/android-motion/recorder.log 2>&1 &
recorder_pid=$!
status=0
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/calendar_motion_test.dart --use-application-binary=build/app/outputs/flutter-apk/app-debug.apk > build/android-motion/driver.log 2>&1 || status=$?
adb shell pkill -INT screenrecord || true
wait "$recorder_pid" || true
adb pull /sdcard/advent-motion.mp4 build/android-motion/android-motion.mp4 || true
cat build/android-motion/driver.log
exit "$status"
