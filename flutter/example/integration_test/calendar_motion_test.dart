import 'dart:ui' show FrameTiming;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:advent_calendar/advent_calendar.dart';
import 'package:timezone/data/latest.dart' as tzdata;

class Clock implements AdventClock {
  @override
  DateTime nowUtc() => DateTime.utc(2026, 12, 2, 9);
}
class Store implements ProgressRepository {
  final ids = <String>{};
  @override
  Future<Set<String>> read(String campaign) async => {...ids};
  @override
  Future<void> recordOpened(String campaign, String id) async { ids.add(id); }
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Android XXS, toast, sheet motion, dismissal and reduced motion', (tester) async {
    tzdata.initializeTimeZones();
    final content = await AdventContent.load(), store = Store();
    store.ids.addAll(content.calendar.days.where((d) => d.kind == DayKind.event && !d.revealOnDate).take(7).map((d) => d.id));
    final time = CampaignTime.moscow(clock: Clock()), reduced = ValueNotifier(false);
    final frames = <FrameTiming>[];
    void timings(List<FrameTiming> batch) => frames.addAll(batch);
    SchedulerBinding.instance.addTimingsCallback(timings);
    await tester.pumpWidget(MaterialApp(debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'packages/advent_calendar/Roboto'),
      builder: (context, child) => ValueListenableBuilder<bool>(valueListenable: reduced,
        builder: (context, value, _) => MediaQuery(data: MediaQuery.of(context).copyWith(disableAnimations: value), child: child!)),
      home: AdventCalendarScreen(content: content, time: time,
        progress: AdventProgress(calendar: content.calendar, time: time, repository: store))));
    await tester.pump(const Duration(seconds: 3));
    final heroContext = tester.element(find.byKey(const ValueKey('hero-title')));
    expect(MediaQuery.textScalerOf(heroContext).scale(11), greaterThanOrEqualTo(11));
    final notice = find.byKey(const ValueKey('closed-date-notice'));
    await tester.tap(find.byKey(const ValueKey('day-3'))); await tester.pump(const Duration(seconds: 1));
    expect(find.text('Откроется 3 декабря'), findsOneWidget);
    expect(tester.getTopLeft(notice).dy, lessThan(150));
    await tester.tap(find.byKey(const ValueKey('day-3'))); await tester.pump(const Duration(seconds: 1));
    expect(notice, findsOneWidget);
    await tester.pump(const Duration(seconds: 3)); expect(notice, findsNothing);
    expect(store.ids.length, 7);
    await tester.tap(find.byKey(const ValueKey('day-4'))); await tester.pump(const Duration(seconds: 1));
    expect(find.text('Сюрприз откроется 4 декабря'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    final chrome = find.byKey(const ValueKey('sheet-chrome'));
    final samples = <double>[];
    await tester.tap(find.byKey(const ValueKey('day-1'))); await tester.pump(); await tester.pump();
    expect(ModalRoute.of(tester.element(chrome))!.transitionDuration, const Duration(milliseconds: 420));
    for (final ms in [70, 140, 250]) { await tester.pump(Duration(milliseconds: ms)); samples.add(tester.getTopLeft(chrome).dy); }
    expect(samples.first, greaterThan(samples.last));
    await tester.pump(const Duration(seconds: 2));
    await tester.drag(chrome, const Offset(0, 700), duration: const Duration(milliseconds: 400));
    await tester.pump(const Duration(seconds: 1)); expect(chrome, findsNothing);
    await tester.tap(find.text('Твоя история декабря')); await tester.pump(const Duration(seconds: 2));
    await tester.binding.handlePopRoute(); await tester.pump(const Duration(seconds: 1)); expect(chrome, findsNothing);
    reduced.value = true; await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.byKey(const ValueKey('day-1'))); await tester.pump(); await tester.pump();
    expect(ModalRoute.of(tester.element(chrome))!.transitionDuration, Duration.zero);
    await tester.pump(const Duration(seconds: 2)); await tester.tap(find.byTooltip('Закрыть'));
    await tester.pump(const Duration(seconds: 1)); expect(chrome, findsNothing);
    SchedulerBinding.instance.removeTimingsCallback(timings);
    binding.reportData = {
      'mode': 'debug; Android emulator; software GPU; diagnostics only, not device performance acceptance',
      'sheetTopSamples': samples, 'frameCount': frames.length,
      'buildUs': frames.map((f) => f.buildDuration.inMicroseconds).toList(),
      'rasterUs': frames.map((f) => f.rasterDuration.inMicroseconds).toList(),
      'verified': ['XXS minimum', 'locked advice/surprise', 'single safe top notice', 'no locked progress', '420ms motion', 'handle drag', 'Back', 'close', 'reduced motion'],
    };
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox()); reduced.dispose();
  });
}
