import 'dart:io';
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:advent_calendar/advent_calendar.dart';
import 'package:timezone/data/latest.dart' as tzdata;

class Clock implements AdventClock {
  DateTime value = DateTime.parse('2026-12-02T12:00:00Z');
  @override
  DateTime nowUtc() => value;
}
class Store implements ProgressRepository {
  final ids = <String>{};
  @override
  Future<Set<String>> read(String id) async => {...ids};
  @override
  Future<void> recordOpened(String campaign, String id) async { ids.add(id); }
}
void main() {
  setUpAll(tzdata.initializeTimeZones);
  final content = AdventContent.decode(File('assets/advent/calendar_2026.json').readAsStringSync());
  for (final width in [320.0, 360.0, 390.0, 430.0]) {
    testWidgets('native route fits $width at normal and enlarged text', (tester) async {
      tester.view.physicalSize = Size(width, 1000); tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
      final clock = Clock(), store = Store(); final time = CampaignTime.moscow(clock: clock);
      for (final scale in [1.0, 2.0]) {
        await tester.pumpWidget(MaterialApp(home: MediaQuery(data: MediaQueryData(size: Size(width,1000), disableAnimations: true, textScaler: TextScaler.linear(scale)),
          child: AdventCalendarScreen(content: content, time: time, progress: AdventProgress(calendar: content.calendar,time:time,repository:store)))));
        await tester.pumpAndSettle();
        expect(find.text('Твоя история декабря'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      }
    });
  }
  testWidgets('future advice blocked; event sheet opens once and dismisses', (tester) async {
    tester.view.physicalSize = const Size(390,1000); tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
    final clock=Clock(), store=Store(), time=CampaignTime.moscow(clock:Clock());
    await tester.pumpWidget(MaterialApp(home: MediaQuery(data: const MediaQueryData(size:Size(390,1000),disableAnimations:true), child: AdventCalendarScreen(
      content: content,time:time,progress:AdventProgress(calendar:content.calendar,time:time,repository:store)))));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('day-3')));await tester.pumpAndSettle();
    expect(store.ids,isEmpty);expect(find.text('Оставь место чуду'),findsNothing);
    for(var i=0;i<2;i++) {
      await tester.tap(find.byKey(const ValueKey('day-1')));await tester.pumpAndSettle();
      expect(find.text('Конец регистрации в игре «Тайный Санта»'),findsOneWidget);
      expect(find.text('Время\n18:00'),findsOneWidget);
      await tester.tap(find.byTooltip('Закрыть'));await tester.pumpAndSettle();
    }
    expect(store.ids,hasLength(1));expect(find.text('1 / 31'),findsOneWidget);
    clock.value=DateTime.parse('2026-12-03T00:00:00Z');
    await tester.pumpWidget(const SizedBox());
  });
}
