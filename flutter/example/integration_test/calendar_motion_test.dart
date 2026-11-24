// ignore: deprecated_member_use
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
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  testWidgets('Android XXS, toast, sheet motion, dismissal and reduced motion', (tester) async {
    // Entry-only native smoke test before the existing calendar checks.
    // The Android job uses the real package assets and XXS system setting.
    var entryOpens = 0;
    for (final scale in [1.0, 2.0]) {
      for (final days in [38, 0]) {
        await tester.pumpWidget(MaterialApp(debugShowCheckedModeBanner: false,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)), child: child!),
          home: Scaffold(backgroundColor: const Color(0xff0a2a20),
            body: Center(child: Padding(padding: const EdgeInsets.all(16),
              child: AdventEntryCard(daysUntilNewYear: days, onOpen: () => entryOpens++))))));
        await tester.pump(const Duration(seconds: 1));
        expect(find.byType(BackdropFilter), findsOneWidget);
        await tester.tap(find.byType(AdventEntryCard));
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull);
      }
    }
    expect(entryOpens, 4);
    await tester.pumpWidget(const SizedBox());
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
    await tester.pump(const Duration(seconds: 3)); await tester.pump(const Duration(milliseconds: 250)); expect(notice, findsNothing);
    expect(store.ids.length, 7);
    expect(find.text('2 / 31'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('day-4'))); await tester.pump(const Duration(seconds: 1));
    expect(find.text('Сюрприз откроется 4 декабря'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    final chrome = find.byKey(const ValueKey('sheet-chrome'));
    final samples = <double>[];
    final motionFrames = <Map<String, num>>[];
    var sampling = true;
    final watch = Stopwatch()..start();
    void sample(Duration _) {
      if (!sampling) return;
      final elements = chrome.evaluate();
      if (elements.isNotEmpty) {
        final box = elements.first.findRenderObject();
        if (box is RenderBox && box.hasSize && box.attached) {
          final y = box.localToGlobal(Offset.zero).dy;
          samples.add(y); motionFrames.add({'us': watch.elapsedMicroseconds, 'top': y});
        }
      }
      SchedulerBinding.instance.addPostFrameCallback(sample);
    }
    SchedulerBinding.instance.addPostFrameCallback(sample);
    await tester.tap(find.byKey(const ValueKey('day-1'))); await tester.pump(); await tester.pump();
    expect(ModalRoute.of(tester.element(chrome))!.transitionDuration, const Duration(milliseconds: 420));
    await tester.pump(const Duration(milliseconds: 650)); sampling = false; watch.stop();
    expect(samples.length, greaterThan(1));
    expect(samples.first, greaterThan(samples.last));
    await tester.pump(const Duration(seconds: 2));
    await tester.timedDrag(chrome, const Offset(0, 700), const Duration(milliseconds: 400));
    await tester.pump(const Duration(seconds: 1)); expect(chrome, findsNothing);
    await tester.tap(find.text('Твоя история декабря')); await tester.pump(const Duration(seconds: 2));
    expect(find.text('Засчитано 2 из 31 дней календаря'), findsOneWidget);
    await tester.binding.handlePopRoute(); await tester.pump(); await tester.pump(const Duration(seconds: 1)); expect(chrome, findsNothing);
    reduced.value = true; await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.byKey(const ValueKey('day-1'))); await tester.pump(); await tester.pump();
    expect(ModalRoute.of(tester.element(chrome))!.transitionDuration, Duration.zero);
    await tester.pump(const Duration(seconds: 2)); await tester.tap(find.byTooltip('Закрыть'));
    await tester.pump(const Duration(seconds: 1)); expect(chrome, findsNothing);
    SchedulerBinding.instance.removeTimingsCallback(timings);
    binding.reportData = {
      'mode': 'debug; Android emulator; software GPU; diagnostics only, not device performance acceptance',
      'sheetTopSamples': samples, 'sheetFrames': motionFrames, 'frameCount': frames.length,
      'buildUs': frames.map((f) => f.buildDuration.inMicroseconds).toList(),
      'rasterUs': frames.map((f) => f.rasterDuration.inMicroseconds).toList(),
      'verified': ['entry glass/countdown/festive/text200/tap', 'XXS minimum', 'locked advice/surprise', 'single safe top notice', 'no locked progress', '420ms motion', 'handle drag', 'Back', 'close', 'reduced motion'],
    };
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox()); reduced.dispose();
  });
}
