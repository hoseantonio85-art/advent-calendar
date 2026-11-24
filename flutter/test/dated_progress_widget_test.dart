import 'dart:io';
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:advent_calendar/advent_calendar.dart';
import 'package:timezone/data/latest.dart' as zones;

class Clock implements AdventClock {
  Clock(this.value); DateTime value;
  @override DateTime nowUtc()=>value;
}
class Memory implements AdventBoolStorage {
  final values=<String,bool>{};
  @override Future<bool?> read(String key)async=>values[key];
  @override Future<void> write(String key,bool value)async{values[key]=value;}
}
void main() {
  setUpAll(zones.initializeTimeZones);
  final content=AdventContent.decode(File('assets/advent/calendar_2026.json').readAsStringSync());
  String id(int day)=>content.calendar.days[day-1].id;
  LocalAdventRepository repo(Memory data)=>LocalAdventRepository(storage:data,calendar:content.calendar,userId:'owner');
  Future<void> mount(WidgetTester tester,Clock clock,LocalAdventRepository store)async{
    tester.view.physicalSize=const Size(390,1000);tester.view.devicePixelRatio=1;
    final time=CampaignTime.moscow(clock:clock);
    await tester.pumpWidget(MaterialApp(builder:(context,child)=>MediaQuery(
      data:MediaQuery.of(context).copyWith(disableAnimations:true),child:child!),
      home:AdventCalendarScreen(content:content,time:time,
        progress:AdventProgress(calendar:content.calendar,time:time,repository:store),savedAdvice:store)));
    await tester.pumpAndSettle();
  }
  testWidgets('future event opens normally but both visible counters defer it to its date', (tester)async{
    addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);
    final clock=Clock(DateTime.utc(2026,12,1,9)), store=repo(Memory());await mount(tester,clock,store);
    await tester.ensureVisible(find.byKey(const ValueKey('day-8')));await tester.tap(find.byKey(const ValueKey('day-8')));await tester.pumpAndSettle();
    expect(find.byTooltip('Закрыть'),findsOneWidget);
    await tester.tap(find.byTooltip('Закрыть'));await tester.pumpAndSettle();
    expect(await store.read(AdventProgress.campaignId),{id(8)});
    expect(find.text('0 / 31'),findsOneWidget);
    final scroll=tester.state<ScrollableState>(find.descendant(of:find.byKey(const ValueKey('calendar-scroll')),matching:find.byType(Scrollable)).first);
    scroll.position.jumpTo(0);await tester.pumpAndSettle();
    await tester.tap(find.text('Твоя история декабря'));await tester.pumpAndSettle();
    expect(find.text('Засчитано 0 из 31 дней календаря'),findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    clock.value=DateTime.utc(2026,12,12,9);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);await tester.pumpAndSettle();
    expect(find.text('Засчитано 1 из 31 дней календаря'),findsOneWidget);
    await tester.tap(find.byTooltip('Закрыть'));await tester.pumpAndSettle();expect(find.text('1 / 31'),findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('Moscow midnight updates an already open history without another tap', (tester)async{
    addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);
    final clock=Clock(DateTime.parse('2026-12-07T20:59:59Z')), storage=Memory();final store=repo(storage);
    await store.recordOpened(AdventProgress.campaignId,id(8));final before=Map<String,bool>.from(storage.values);
    await mount(tester,clock,store);expect(find.text('0 / 31'),findsOneWidget);
    await tester.tap(find.text('Твоя история декабря'));await tester.pumpAndSettle();
    expect(find.text('Засчитано 0 из 31 дней календаря'),findsOneWidget);
    clock.value=DateTime.parse('2026-12-07T21:00:00Z');await tester.pump(const Duration(seconds:1));await tester.pumpAndSettle();
    expect(find.text('Засчитано 1 из 31 дней календаря'),findsOneWidget);expect(storage.values,before);
    await tester.tap(find.byTooltip('Закрыть'));await tester.pumpAndSettle();expect(find.text('1 / 31'),findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('restart restores credited views; late advice and repeated opens count once', (tester)async{
    addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);
    final clock=Clock(DateTime.utc(2026,12,1,9)), storage=Memory();
    for(final day in [1,2,8]) { await repo(storage).recordOpened(AdventProgress.campaignId,id(day)); }
    await mount(tester,clock,repo(storage));expect(find.text('1 / 31'),findsOneWidget);
    await tester.pumpWidget(const SizedBox());clock.value=DateTime.utc(2026,12,12,9);
    final restored=repo(storage);await mount(tester,clock,restored);expect(find.text('3 / 31'),findsOneWidget);
    for(var repeat=0;repeat<2;repeat++){
      await tester.ensureVisible(find.byKey(const ValueKey('day-5')));await tester.tap(find.byKey(const ValueKey('day-5')));await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Закрыть'));await tester.pumpAndSettle();expect(find.text('4 / 31'),findsOneWidget);
    }
    expect(await restored.read(AdventProgress.campaignId),{id(1),id(2),id(5),id(8)});
    await tester.pumpWidget(const SizedBox());
  });
}
