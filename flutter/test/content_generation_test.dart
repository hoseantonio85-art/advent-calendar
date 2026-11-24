import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:advent_calendar/advent_calendar.dart';
import 'package:timezone/data/latest.dart' as zones;

class ContentClock implements AdventClock {
  ContentClock(this.value);
  DateTime value;
  @override
  DateTime nowUtc() => value;
}

class ContentMemory implements AdventBoolStorage {
  final values = <String, bool>{};
  @override
  Future<bool?> read(String key) async => values[key];
  @override
  Future<void> write(String key, bool value) async { values[key] = value; }
}

void main() {
  late Map<String, dynamic> fixtures;
  AdventContent content(String key) => AdventContent.decode(jsonEncode(fixtures[key]));
  setUpAll(() {
    zones.initializeTimeZones();
    // Exercise the real build-time generator; temporary variants never become
    // app assets and require no edits to the approved source or its outputs.
    final result = Process.runSync('node', ['../tools/content-test-fixtures.cjs'],
        stdoutEncoding: utf8, stderrEncoding: utf8);
    expect(result.exitCode, 0, reason: result.stderr as String);
    fixtures = jsonDecode(result.stdout as String) as Map<String, dynamic>;
  });

  test('generated overlays with 15/13/0 events load without a fixed event-count constraint', () {
    for (final entry in {'original':14, 'edit19':14, 'added3':15,
      'restored3':14, 'removed1':13, 'removed4':13, 'allAdvice':0}.entries) {
      final calendar = content(entry.key).calendar;
      expect(calendar.days, hasLength(31));
      expect(calendar.days.where((d) => d.kind == DayKind.event), hasLength(entry.value));
      expect(calendar.days.map((d) => d.id).toSet(), hasLength(31));
    }
    final changed = content('edit19').calendar.days[18];
    expect(changed.title, 'Проверка редактирования 19 декабря');
    expect(changed.event!['desc'], contains('из единого источника'));
    expect(changed.event!['startTime'], isNull);
    expect(changed.event!['locations'], ['Система оценок']);
    final restored = content('removed1').calendar.days.first;
    expect(restored.id, 'december-2026-01');
    expect(restored.kind, DayKind.advice);
    expect(restored.title, restored.advice['title']);
    expect(restored.art, 'spark'); expect(restored.theme, 'alt'); expect(restored.columns, 1);
  });

  test('overlay and advice restoration preserve raw keys, favorites and Moscow progress A', () async {
    final original = content('original').calendar, memory = ContentMemory();
    LocalAdventRepository store(String variant) => LocalAdventRepository(
      storage: memory, calendar: content(variant).calendar, userId: 'stable-editor-user');
    final one = original.days.first.id, three = original.days[2].id;
    final before = store('original');
    await before.recordOpened(AdventProgress.campaignId, one);
    await before.recordOpened(AdventProgress.campaignId, three);
    await before.setSaved(AdventProgress.campaignId, three, true);
    final raw = Map<String, bool>.from(memory.values);
    final overlay = store('added3');
    expect(await overlay.read(AdventProgress.campaignId), {one, three});
    expect(await overlay.readSaved(AdventProgress.campaignId), isEmpty);
    expect(memory.values, raw, reason: 'event hides a saved advice without clearing it');
    final restored = store('restored3');
    expect(await restored.readSaved(AdventProgress.campaignId), {three});
    final clock = ContentClock(DateTime.parse('2026-12-02T20:59:59Z'));
    final progress = AdventProgress(calendar: content('restored3').calendar,
      time: CampaignTime.moscow(clock: clock), repository: restored);
    expect(await progress.read(), {one});
    clock.value = DateTime.parse('2026-12-02T21:00:00Z');
    expect(await progress.read(), {one, three});
    await progress.open(three); await progress.open(three);
    expect(await progress.read(), {one, three}); expect(memory.values, raw);
  });

  test('removed surprise becomes advice and restoring it does not repeat its claim', () async {
    final memory = ContentMemory(), original = content('original').calendar;
    LocalAdventRepository store(String variant) => LocalAdventRepository(
      storage: memory, calendar: content(variant).calendar, userId: 'stable-surprise-user');
    final four = original.days[3].id;
    expect(await store('original').claimSurprise(AdventProgress.campaignId, four), isTrue);
    final raw = Map<String, bool>.from(memory.values);
    expect(content('removed4').calendar.days[3].revealOnDate, isFalse);
    expect(await store('removed4').readSurprises(AdventProgress.campaignId), isEmpty);
    await expectLater(store('removed4').claimSurprise(AdventProgress.campaignId, four), throwsArgumentError);
    expect(await store('original').claimSurprise(AdventProgress.campaignId, four), isFalse);
    expect(memory.values, raw);
  });

  test('loader still rejects missing advice and a surprise on an advice day', () {
    for (final mode in ['advice', 'surprise']) {
      final data = jsonDecode(jsonEncode(fixtures['allAdvice'])) as Map<String, dynamic>;
      if (mode == 'advice') { data['days'][0].remove('advice'); }
      else { data['days'][3]['revealOnDate'] = true; }
      expect(() => AdventContent.decode(jsonEncode(data)), throwsFormatException);
    }
  });
}
