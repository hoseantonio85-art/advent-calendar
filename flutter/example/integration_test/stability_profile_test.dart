import 'dart:io';
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:advent_calendar/advent_calendar.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'calendar_motion_test.dart' show Store;

class ProfileClock implements AdventClock {
  final elapsed=Stopwatch()..start();
  @override
  DateTime nowUtc()=>DateTime.utc(2026,12,15,9).add(elapsed.elapsed);
}

// Physical ARM64 device only. This fixture is never the user APK entrypoint.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  testWidgets('physical profile: scrolling, motion, glass, idle and repeated sheets', (t) async {
    expect(kProfileMode, isTrue, reason: 'Run flutter drive --profile on a physical Android.');
    expect(Platform.isAndroid, isTrue);
    tzdata.initializeTimeZones();
    final content = await AdventContent.load(), store = Store(), time = CampaignTime.moscow(clock: ProfileClock());
    await t.pumpWidget(MaterialApp(home: AdventCalendarScreen(content: content, time: time,
      progress: AdventProgress(calendar: content.calendar, time: time, repository: store))));
    await t.pump(const Duration(seconds: 4));
    final results = <String, dynamic>{'mode': 'physical Android PROFILE; test-only fixture',
      'refreshHz': WidgetsBinding.instance.platformDispatcher.views.first.display.refreshRate};
    Future<void> measure(String name, Future<void> Function() action) async {
      final frames = <FrameTiming>[];
      void collect(List<FrameTiming> batch) => frames.addAll(batch);
      SchedulerBinding.instance.addTimingsCallback(collect);
      final before = ProcessInfo.currentRss;
      try { await action(); await t.pump(const Duration(seconds: 1)); }
      finally { SchedulerBinding.instance.removeTimingsCallback(collect); }
      results[name] = {'frames': frames.length, 'buildUs': frames.map((f) => f.buildDuration.inMicroseconds).toList(),
        'rasterUs': frames.map((f) => f.rasterDuration.inMicroseconds).toList(),
        'rssBefore': before, 'rssAfter': ProcessInfo.currentRss};
    }
    await measure('scroll', () async {
      final scroll = find.byKey(const ValueKey('calendar-scroll'));
      for (var i=0; i<8; i++) { await t.drag(scroll, Offset(0, i<4 ? -380 : 380)); await t.pump(const Duration(milliseconds: 500)); }
    });
    await measure('idle_animation', () => t.pump(const Duration(seconds: 12)));
    await measure('sheets', () async {
      for(var i=0;i<20;i++) {
        final day=find.byKey(const ValueKey('day-1')); await t.ensureVisible(day); await t.tap(day); await t.pump(const Duration(milliseconds: 700));
        await t.tap(find.byTooltip('Закрыть')); await t.pump(const Duration(milliseconds: 700));
      }
    });
    await measure('history_glass_counter', () async {
      final button=find.text('Твоя история декабря'); await Scrollable.ensureVisible(t.element(button), alignment:.4);
      await t.tap(button); await t.pump(const Duration(seconds: 15));
      await t.tap(find.byTooltip('Закрыть')); await t.pump(const Duration(milliseconds: 700));
    });
    results['maxRssBytes'] = ProcessInfo.maxRss;
    binding.reportData = results;
    expect(t.takeException(), isNull); await t.pumpWidget(const SizedBox());
  }, timeout: const Timeout(Duration(minutes: 5)));
}
