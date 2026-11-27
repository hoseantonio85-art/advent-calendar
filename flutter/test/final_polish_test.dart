import 'dart:async';
import 'dart:convert';
import 'dart:io';
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:advent_calendar/advent_calendar.dart';
import 'package:timezone/data/latest.dart' as zones;
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';
import 'visual_test.dart' show TestAssets, VisualClock, VisualStore;

class PendingStore extends VisualStore {
  final gate = Completer<void>();
  bool fail = false;
  @override
  Future<void> recordOpened(String campaign, String id) async {
    await gate.future;
    if (fail) throw StateError('storage unavailable');
    return super.recordOpened(campaign, id);
  }
}

class MapLauncher extends UrlLauncherPlatform {
  final urls = <String>[];
  bool available = true, fail = false;
  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    urls.add(url);
    expect(options.mode, PreferredLaunchMode.externalApplication);
    if (fail) throw PlatformException(code: 'no_handler');
    return available;
  }
}

void main() {
  setUpAll(zones.initializeTimeZones);
  final source = File('assets/advent/calendar_2026.json').readAsStringSync();
  final content = AdventContent.decode(source);
  const mapUrl = 'https://yandex.com/maps/org/navka_arena/26422616706/';

  Future<VisualStore> mount(WidgetTester t, {VisualStore? store, double width = 390,
    double scale = 1, int day = 14, AdventSystemActions? actions}) async {
    t.view.physicalSize = Size(width, 844); t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize); addTearDown(t.view.resetDevicePixelRatio);
    final repository = store ?? VisualStore();
    final time = CampaignTime.moscow(clock: VisualClock(DateTime.utc(2026, 12, day, 9)));
    await t.pumpWidget(DefaultAssetBundle(bundle: TestAssets(), child: MaterialApp(
      builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(
        disableAnimations: true, textScaler: TextScaler.linear(scale)), child: child!),
      home: AdventCalendarScreen(content: content, time: time,
        progress: AdventProgress(calendar: content.calendar, time: time, repository: repository),
        savedAdvice: repository, actions: actions))));
    await t.pumpAndSettle();
    return repository;
  }
  Future<void> open(WidgetTester t, int day) async {
    final tile = find.byKey(ValueKey('day-$day'));
    await t.ensureVisible(tile); await t.pumpAndSettle();
    await t.tap(tile); await t.pumpAndSettle();
  }
  Future<void> close(WidgetTester t) async {
    await t.tap(find.byTooltip('Закрыть')); await t.pumpAndSettle();
  }

  test('mapUrl remains optional and rejects malformed or non-HTTPS runtime URLs', () {
    expect(content.calendar.days[13].event!['mapUrl'], mapUrl);
    expect(content.calendar.days[13].event!['locations'],
      ['Навка Арена · Москва, ул. Нижние Мнёвники, 10А']);
    for (final value in [null, 42, '', 'javascript:alert(1)', 'http://example.com',
      'https:example.com', 'https://', 'https://u:p@example.com/',
      'https://example.com/a b', r'https://example.com/\bad', 'https://example.com/%zz',
      'https://example.com:99999/']) {
      final json = jsonDecode(source) as Map<String, dynamic>;
      json['days'][13]['event']['mapUrl'] = value;
      expect(() => AdventContent.decode(jsonEncode(json)), throwsFormatException, reason: '$value');
    }
    final json = jsonDecode(source) as Map<String, dynamic>;
    json['days'][13]['event'].remove('mapUrl');
    expect(AdventContent.decode(jsonEncode(json)).calendar.days[13].event!.containsKey('mapUrl'), isFalse);
  });

  testWidgets('sheet begins on tap before slow storage, and still records once', (t) async {
    final store = PendingStore(); await mount(t, store: store);
    await t.tap(find.byKey(const ValueKey('day-1')));
    await t.pump(const Duration(milliseconds: 16));
    expect(find.byKey(const ValueKey('sheet-chrome')), findsOneWidget);
    expect(store.ids, isEmpty, reason: 'route never waits for the pending write');
    store.gate.complete(); await t.pumpAndSettle();
    expect(store.ids, {content.calendar.days.first.id});
    await close(t); expect(find.text('1 / 31'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('storage failure preserves usable sheet without fabricated progress', (t) async {
    final store = PendingStore()..fail = true; await mount(t, store: store);
    await open(t, 1); expect(find.byTooltip('Закрыть'), findsOneWidget);
    store.gate.complete(); await t.pumpAndSettle();
    expect(store.ids, isEmpty); await close(t);
    expect(find.text('0 / 31'), findsOneWidget);
    expect(find.text('Не удалось открыть день. Попробуйте ещё раз.'), findsOneWidget);
    expect(t.takeException(), isNull); await t.pumpWidget(const SizedBox());
  });

  testWidgets('reached advice uses one stable-position indicator through save/remove; future stays closed', (t) async {
    final store = await mount(t, day: 10);
    final tile = find.byKey(const ValueKey('day-10'));
    await t.ensureVisible(tile); await t.pumpAndSettle();
    final star = find.descendant(of: tile, matching: find.byKey(const ValueKey('advice-star-indicator')));
    final heart = find.descendant(of: tile, matching: find.byKey(const ValueKey('advice-saved-indicator')));
    expect(star, findsOneWidget); expect(heart, findsNothing);
    final original = t.getRect(star);
    await open(t, 10);
    await t.ensureVisible(find.text('Сохранить совет')); await t.tap(find.text('Сохранить совет')); await t.pumpAndSettle();
    await close(t);
    expect(star, findsNothing); expect(heart, findsOneWidget); expect(t.getRect(heart), original);
    expect(store.saved, {content.calendar.days[9].id});
    await open(t, 10); await t.ensureVisible(find.text('Совет сохранён'));
    await t.tap(find.text('Совет сохранён')); await t.pumpAndSettle(); await close(t);
    expect(star, findsOneWidget); expect(heart, findsNothing); expect(store.saved, isEmpty);
    final past = find.byKey(const ValueKey('day-3')), future = find.byKey(const ValueKey('day-21'));
    expect(find.descendant(of: past, matching: find.byKey(const ValueKey('advice-star-indicator'))), findsOneWidget);
    expect(find.descendant(of: future, matching: find.byKey(const ValueKey('advice-star-indicator'))), findsNothing);
    expect(t.takeException(), isNull); await t.pumpWidget(const SizedBox());
  });

  testWidgets('14/17/18 places, external URL, unavailable/error and retry; old host actions stay compatible', (t) async {
    final original = UrlLauncherPlatform.instance, launcher = MapLauncher();
    UrlLauncherPlatform.instance = launcher; addTearDown(() => UrlLauncherPlatform.instance = original);
    final semantics = t.ensureSemantics(); addTearDown(semantics.dispose);
    await mount(t);
    for (final entry in {14:'Навка Арена · Москва, ул. Нижние Мнёвники, 10А',
      17:'БКЗ, корпус Г', 18:'Елка возле переговорной Б.39.04'}.entries) {
      await open(t, entry.key); expect(find.text(entry.value), findsOneWidget);
      final link = find.byKey(const ValueKey('event-map-link'));
      if (entry.key == 14) {
        await t.ensureVisible(link); await t.pumpAndSettle();
        expect(t.getSemantics(link).getSemanticsData().flagsCollection.isLink, isTrue);
        for (var scenario = 0; scenario < 3; scenario++) {
          launcher.available = scenario != 0; launcher.fail = scenario == 1;
          await t.tap(link); await t.pumpAndSettle();
          expect(launcher.urls.last, mapUrl);
          if (scenario == 0) expect(find.text('Действие недоступно на этом устройстве'), findsOneWidget);
          if (scenario == 1) expect(find.text('Не удалось выполнить действие. Попробуйте ещё раз.'), findsOneWidget);
          await t.pump(const Duration(seconds: 5)); await t.pumpAndSettle();
        }
      } else { expect(link, findsNothing); }
      await close(t);
    }
    expect(launcher.urls, [mapUrl, mapUrl, mapUrl]);
    expect(t.takeException(), isNull); await t.pumpWidget(const SizedBox());
  });

  for (final width in [320.0, 360.0, 390.0, 430.0]) {
    testWidgets('advice Share bottom edge is visible and tappable at $width, including large text', (t) async {
      var shares = 0;
      final actions = NativeAdventActions(confirmCalendar: (_) async => null,
        shareOrigin: () => const Rect.fromLTWH(0, 0, 10, 10),
        share: (_, __, ___) async { shares++; return SystemActionResult.cancelled; });
      for (final scale in [1.0, 2.0]) {
        await mount(t, width: width, scale: scale, actions: actions);
        await open(t, 3);
        final button = find.byKey(const ValueKey('advice-share'));
        await t.ensureVisible(button); await t.pumpAndSettle();
        final rect = t.getRect(button);
        expect(rect.height, greaterThanOrEqualTo(48)); expect(rect.bottom, lessThanOrEqualTo(844));
        final text = t.getRect(find.text('Поделиться советом'));
        expect(rect.contains(text.topLeft), isTrue); expect(rect.contains(text.bottomRight), isTrue);
        final touch = await t.startGesture(Offset(rect.center.dx, rect.bottom - 2));
        await t.pump(const Duration(milliseconds: 150));
        expect(t.takeException(), isNull);
        await touch.up(); await t.pumpAndSettle();
        await t.pumpWidget(const SizedBox());
      }
      expect(shares, 2, reason: 'both bottom-edge taps reach the real Share callback');
    });
  }
}
