import 'dart:io';
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:advent_calendar/advent_calendar.dart';
import 'package:timezone/data/latest.dart' as tzdata;

class _Clock implements AdventClock {
  @override
  DateTime nowUtc() => DateTime.utc(2026, 12, 2, 9);
}
class _Store implements ProgressRepository {
  final ids = <String>{};
  @override
  Future<Set<String>> read(String campaign) async => {...ids};
  @override
  Future<void> recordOpened(String campaign, String id) async { ids.add(id); }
}
void main() {
  setUpAll(tzdata.initializeTimeZones);
  final content = AdventContent.decode(File('assets/advent/calendar_2026.json').readAsStringSync());
  Future<_Store> mount(WidgetTester tester, {double scale = 1, bool reduced = true}) async {
    tester.view.physicalSize = const Size(360, 1000);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 24);
    addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    final time = CampaignTime.moscow(clock: _Clock()), store = _Store();
    await tester.pumpWidget(MaterialApp(builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale), disableAnimations: reduced), child: child!),
      home: AdventCalendarScreen(content: content, time: time,
        progress: AdventProgress(calendar: content.calendar, time: time, repository: store))));
    await tester.pump();
    return store;
  }
  testWidgets('XXS uses CSS minimum; enlarged typography remains enlarged', (tester) async {
    final heights = <double>[];
    for (final scale in [.8, 1.0, 2.0]) {
      await mount(tester, scale: scale);
      heights.add(tester.getSize(find.byKey(const ValueKey('hero-title'))).height);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    }
    expect(heights[0], heights[1]); expect(heights[2], greaterThan(heights[1]));
  });
  testWidgets('locked advice and surprise share one safe top live notice, never progress/sheets', (tester) async {
    final store = await mount(tester);
    final semantics = tester.ensureSemantics();
    try {
    final notice = find.byKey(const ValueKey('closed-date-notice'));
    await tester.tap(find.byKey(const ValueKey('day-3'))); await tester.pump();
    expect(find.text('Откроется 3 декабря'), findsOneWidget);
    expect(tester.getTopLeft(notice).dy, greaterThanOrEqualTo(36));
    expect(tester.getTopLeft(notice).dy, lessThan(150));
    expect(tester.getSemantics(notice).getSemanticsData().flagsCollection.isLiveRegion, isTrue);
    await tester.pump(const Duration(seconds: 2));
    await tester.tap(find.byKey(const ValueKey('day-3'))); await tester.pump();
    expect(notice, findsOneWidget);
    await tester.pump(const Duration(seconds: 1)); expect(notice, findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('day-4'))); await tester.pump();
    expect(find.text('Сюрприз откроется 4 декабря'), findsOneWidget);
    expect(find.text('Откроется 3 декабря'), findsNothing);
    expect(find.byTooltip('Закрыть'), findsNothing); expect(store.ids, isEmpty);
    await tester.pump(const Duration(milliseconds: 2800)); expect(notice, findsNothing);
    await tester.pumpWidget(const SizedBox());
    } finally { semantics.dispose(); }
  });
  testWidgets('360 ms sheet moves progressively and remains dismissible by handle, Back, close', (tester) async {
    await mount(tester, reduced: false);
    Future<void> open() async {
      await tester.tap(find.byKey(const ValueKey('day-1'))); await tester.pump(); await tester.pump();
    }
    final chrome = find.byKey(const ValueKey('sheet-chrome'));
    await open();
    final route = ModalRoute.of(tester.element(chrome))!;
    expect(route.transitionDuration, const Duration(milliseconds: 360));
    await tester.pump(const Duration(milliseconds: 70)); final early = tester.getTopLeft(chrome).dy;
    await tester.pump(const Duration(milliseconds: 140)); final middle = tester.getTopLeft(chrome).dy;
    await tester.pump(const Duration(milliseconds: 250)); final finalY = tester.getTopLeft(chrome).dy;
    expect(early, greaterThan(middle)); expect(middle, greaterThanOrEqualTo(finalY));
    await tester.timedDrag(chrome, const Offset(0, 750), const Duration(milliseconds: 600)); await tester.pump(const Duration(milliseconds: 500));
    expect(chrome, findsNothing);
    await open(); await tester.pump(const Duration(milliseconds: 500));
    await tester.binding.handlePopRoute(); await tester.pump(); await tester.pump(const Duration(milliseconds: 500)); expect(chrome, findsNothing);
    await open(); await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.byTooltip('Закрыть')); await tester.pump(); await tester.pump(const Duration(milliseconds: 500)); expect(chrome, findsNothing);
    expect(tester.takeException(), isNull); await tester.pumpWidget(const SizedBox());
  });
  testWidgets('reduced motion sheet skips the entrance animation', (tester) async {
    await mount(tester);
    await tester.tap(find.byKey(const ValueKey('day-1'))); await tester.pump(); await tester.pump();
    final chrome = find.byKey(const ValueKey('sheet-chrome'));
    expect(ModalRoute.of(tester.element(chrome))!.transitionDuration, Duration.zero);
    await tester.tap(find.byTooltip('Закрыть')); await tester.pump(); await tester.pump();
    await tester.pumpWidget(const SizedBox());
  });
}
