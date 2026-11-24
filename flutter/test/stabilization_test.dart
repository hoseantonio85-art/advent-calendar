import 'dart:async';
import 'dart:io';
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:advent_calendar/advent_calendar.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'visual_test.dart' show TestAssets;

class StableClock implements AdventClock {
  @override
  DateTime nowUtc() => DateTime.utc(2026, 12, 15, 9);
}
class RaceStore implements ProgressRepository {
  final first = Completer<Set<String>>();
  final ids = <String>{};
  var reads = 0;
  bool fail = false;
  @override
  Future<Set<String>> read(String c) async {
    if (fail) throw StateError('storage unavailable');
    if (++reads == 1) return first.future;
    return {...ids};
  }
  @override
  Future<void> recordOpened(String c, String id) async { ids.add(id); }
}
class SavedRaceStore extends RaceStore implements SavedAdviceRepository {
  SavedRaceStore(this.saved);
  final Set<String> saved;
  @override
  Future<Set<String>> readSaved(String c) async => {...saved};
  @override
  Future<void> setSaved(String c,String id,bool value) async { if(value){saved.add(id);}else{saved.remove(id);} }
}
class FailingActions implements AdventSystemActions {
  var fail = true;
  @override
  Future<SystemActionResult> share(AdventDay d) async {
    if (fail) throw PlatformException(code: 'permission_denied');
    return SystemActionResult.cancelled;
  }
  @override
  Future<SystemActionResult> addToCalendar(AdventDay d, tz.Location zone) => share(d);
}

void main() {
  setUpAll(tzdata.initializeTimeZones);
  final content = AdventContent.decode(File('assets/advent/calendar_2026.json').readAsStringSync());
  Future<void> mount(WidgetTester t, RaceStore store, {String user = 'a', AdventSystemActions? actions}) async {
    t.view.physicalSize = const Size(390, 1000); t.view.devicePixelRatio = 1;
    final time = CampaignTime.moscow(clock: StableClock());
    await t.pumpWidget(DefaultAssetBundle(bundle: TestAssets(), child: MaterialApp(
      builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(disableAnimations: true), child: child!),
      home: AdventCalendarScreen(key: ValueKey(user), content: content, time: time,
        progress: AdventProgress(calendar: content.calendar, time: time, repository: store), savedAdvice: store is SavedAdviceRepository ? store as SavedAdviceRepository : null, actions: actions))));
    await t.pumpAndSettle();
  }
  void reset(WidgetTester t) { addTearDown(t.view.resetPhysicalSize); addTearDown(t.view.resetDevicePixelRatio); }

  testWidgets('entry route, day sheet and native Back return to entry', (t) async {
    reset(t); final store=RaceStore()..first.complete({}), time=CampaignTime.moscow(clock:StableClock());
    t.view.physicalSize=const Size(390,1000);t.view.devicePixelRatio=1;
    await t.pumpWidget(DefaultAssetBundle(bundle:TestAssets(),child:MaterialApp(
      builder:(context,child)=>MediaQuery(data:MediaQuery.of(context).copyWith(disableAnimations:true),child:child!),
      home:Scaffold(body:Builder(builder:(context)=>AdventEntryCard(daysUntilNewYear:time.daysUntilNewYear,
        onOpen:()=>Navigator.push(context,MaterialPageRoute<void>(builder:(_)=>AdventCalendarScreen(content:content,time:time,
          progress:AdventProgress(calendar:content.calendar,time:time,repository:store))))))))));
    await t.tap(find.byType(AdventEntryCard));await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('day-1')));await t.pumpAndSettle();
    await t.tap(find.byTooltip('Закрыть'));await t.pumpAndSettle();
    await t.binding.handlePopRoute();await t.pumpAndSettle();
    expect(find.byType(AdventEntryCard),findsOneWidget);expect(store.ids,hasLength(1));
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('late initial read cannot overwrite a newly recorded open', (t) async {
    reset(t); final store = RaceStore(); await mount(t, store);
    await t.tap(find.byKey(const ValueKey('day-1'))); await t.pumpAndSettle();
    await t.tap(find.byTooltip('Закрыть')); await t.pumpAndSettle();
    expect(find.text('1 / 31'), findsOneWidget);
    store.first.complete({}); await t.pumpAndSettle();
    expect(find.text('1 / 31'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
  });
  testWidgets('late progress snapshot preserves existing saved advice after a new view', (t) async {
    reset(t); final advice=content.calendar.days[2], store=SavedRaceStore({content.calendar.days[2].id});
    await mount(t,store); await t.tap(find.byKey(const ValueKey('day-1'))); await t.pumpAndSettle();
    await t.tap(find.byTooltip('Закрыть')); await t.pumpAndSettle();
    store.first.complete({}); await t.pumpAndSettle();
    expect(find.text('1 / 31'),findsOneWidget);
    await t.tap(find.text('Твоя история декабря')); await t.pumpAndSettle();
    expect(find.text(advice.title),findsOneWidget);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('logout keyed replacement ignores old in-flight account data', (t) async {
    reset(t); final a = RaceStore(), b = RaceStore(); await mount(t, a);
    await mount(t, b, user: 'b');
    b.first.complete({}); a.first.complete({content.calendar.days.first.id}); await t.pumpAndSettle();
    expect(find.text('0 / 31'), findsOneWidget); expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
  });
  testWidgets('progress read failure can retry without resetting stored facts', (t) async {
    reset(t); final store = RaceStore()..fail = true; await mount(t, store);
    expect(find.text('Не удалось загрузить прогресс. Повторить'), findsOneWidget);
    store.fail = false; store.first.complete({content.calendar.days.first.id});
    await t.tap(find.text('Не удалось загрузить прогресс. Повторить')); await t.pumpAndSettle();
    expect(find.text('1 / 31'), findsOneWidget); expect(store.ids, isEmpty);
    await t.pumpWidget(const SizedBox());
  });
  testWidgets('OS permission errors leave actions retryable; cancellation is silent', (t) async {
    reset(t); final store = RaceStore()..first.complete({}), actions = FailingActions();
    await mount(t, store, actions: actions); await t.tap(find.byKey(const ValueKey('day-1'))); await t.pumpAndSettle();
    final share = find.text('Поделиться'); await t.ensureVisible(share); await t.tap(share); await t.pumpAndSettle();
    expect(find.text('Не удалось выполнить действие. Попробуйте ещё раз.'), findsOneWidget);
    actions.fail = false; await t.pump(const Duration(seconds: 5)); await t.tap(share); await t.pumpAndSettle();
    expect(find.text('Не удалось выполнить действие. Попробуйте ещё раз.'), findsNothing);
    expect(t.takeException(), isNull); await t.pumpWidget(const SizedBox());
  });
}
