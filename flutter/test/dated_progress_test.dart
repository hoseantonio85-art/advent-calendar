import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:advent_calendar/advent_calendar.dart';
import 'package:timezone/data/latest.dart' as zones;
import 'package:timezone/timezone.dart' as tz;

class Clock implements AdventClock {
  Clock(this.value);
  DateTime value;
  @override
  DateTime nowUtc() => value;
}
class Memory implements AdventBoolStorage {
  final values = <String,bool>{};
  @override
  Future<bool?> read(String key) async => values[key];
  @override
  Future<void> write(String key, bool value) async { values[key] = value; }
}
class ViewsOnly implements ProgressRepository {
  final ids=<String>{};
  @override Future<Set<String>> read(String campaign) async=>{...ids};
  @override Future<void> recordOpened(String campaign,String id) async {ids.add(id);}
}
void main() {
  setUpAll(zones.initializeTimeZones);
  final calendar = AdventContent.decode(File('assets/advent/calendar_2026.json').readAsStringSync()).calendar;
  String id(int day) => calendar.days[day-1].id;
  LocalAdventRepository repo(Memory storage, {String user = 'owner'}) =>
    LocalAdventRepository(storage: storage, calendar: calendar, userId: user);
  AdventProgress service(Clock clock, ProgressRepository store) => AdventProgress(
    calendar: calendar, time: CampaignTime.moscow(clock: clock), repository: store);

  test('1/2/8 example: early views survive and accrue without reopening', () async {
    final clock = Clock(DateTime.utc(2026,12,1,9)), store = repo(Memory());
    final progress = service(clock,store);
    for (final day in [1,2,8]) { expect(await progress.open(id(day)), isTrue); }
    expect(await store.read(AdventProgress.campaignId), {id(1),id(2),id(8)});
    expect(await progress.read(), {id(1)});
    clock.value = DateTime.utc(2026,12,2,9); expect(await progress.read(), {id(1),id(2)});
    clock.value = DateTime.utc(2026,12,8,9); expect(await progress.read(), {id(1),id(2),id(8)});
    clock.value = DateTime.utc(2026,12,12,9); expect(await progress.read(), {id(1),id(2),id(8)});
  });
  test('pure domain API retains future views across additional openings', () {
    var viewed = calendar.open(id(8), [], DateTime.utc(2026,12,1));
    viewed = calendar.open(id(2), viewed, DateTime.utc(2026,12,1));
    viewed = calendar.open(id(1), viewed, DateTime.utc(2026,12,1));
    expect(viewed, {id(1),id(2),id(8)});
    expect(calendar.eligibleProgress(viewed,DateTime.utc(2026,12,1)),{id(1)});
    expect(calendar.eligibleProgress(viewed,DateTime.utc(2026,12,8)),viewed);
    expect(calendar.open(id(3),viewed,DateTime.utc(2026,12,1)),viewed);
  });
  test('unviewed transitions add nothing; late advice and duplicates count once', () async {
    final clock = Clock(DateTime.utc(2026,12,1)), store = repo(Memory());
    final progress = service(clock,store);
    clock.value = DateTime.utc(2026,12,12); expect(await progress.read(),isEmpty);
    expect(await progress.open(id(5)),isTrue);
    await Future.wait([progress.open(id(5)), progress.open(id(5))]);
    expect(await progress.read(),{id(5)});
    expect(await progress.open('unknown'),isFalse);
    expect(await progress.read(),{id(5)});
  });
  test('all early ordinary events cannot exceed elapsed days; full dates bound the year', () async {
    final clock = Clock(DateTime.utc(2026,12,1)), store = repo(Memory());
    final progress = service(clock,store);
    for (final day in calendar.days.where((d)=>d.kind==DayKind.event && !d.revealOnDate)) {
      expect(await progress.open(day.id),isTrue);
    }
    expect(await store.read(AdventProgress.campaignId),hasLength(10));
    expect(await progress.read(),{id(1)});
    for(final date in [DateTime.utc(2025,12,31),DateTime.utc(2026,11,30),DateTime.utc(2026,1,31)]) {
      clock.value=date;expect(await progress.read(),isEmpty);
    }
    clock.value=DateTime.utc(2027);expect(await progress.read(),hasLength(10));
    for(final day in calendar.days) { await progress.open(day.id); }
    expect(await progress.read(),hasLength(31));
    expect(calendar.eligibleProgress([id(1),id(1),'bad'],DateTime.utc(2027)),{id(1)});
  });
  test('Moscow midnight credits only a stored view, independently of device zone', () async {
    final original = tz.local;
    try {
      for(final zone in ['America/Los_Angeles','Asia/Tokyo']) {
        tz.setLocalLocation(tz.getLocation(zone));
        final clock = Clock(DateTime.parse('2026-12-07T20:59:59Z')), store = repo(Memory());
        final progress = service(clock,store);
        expect(await progress.open(id(8)),isTrue);expect(await progress.read(),isEmpty);
        clock.value=DateTime.parse('2026-12-07T21:00:00Z');expect(await progress.read(),{id(8)});
        clock.value=DateTime.utc(2026,12,10,9);expect(await progress.read(),{id(8)});
      }
    } finally { tz.setLocalLocation(original); }
  });
  test('legacy keys survive reads/restart and missed dates without any migration', () async {
    final storage=Memory(), old=repo(storage), clock=Clock(DateTime.utc(2026,12,1,9));
    for(final day in [1,2,8]) { await old.recordOpened(AdventProgress.campaignId,id(day)); }
    final originalKeys=Map<String,bool>.from(storage.values);
    expect(await service(clock,repo(storage)).read(),{id(1)});
    clock.value=DateTime.utc(2026,12,12,9);
    expect(await service(clock,repo(storage)).read(),{id(1),id(2),id(8)});
    expect(storage.values,originalKeys);
    expect(await service(clock,repo(storage,user:'other')).read(),isEmpty);
  });
  test('existing host adapters need only raw views for the shared counter', () async {
    final clock=Clock(DateTime.utc(2026,12,4,9)), store=ViewsOnly();
    store.ids.addAll([id(4),id(8)]);
    final progress=service(clock,store);
    expect(progress.surprises,isNull);expect(await progress.read(),{id(4)});
    clock.value=DateTime.utc(2026,12,8,9);expect(await progress.read(),{id(4),id(8)});
  });
  test('surprise claims and saved advice stay independent of crediting legacy/new views', () async {
    final storage=Memory(), store=repo(storage), clock=Clock(DateTime.parse('2026-12-03T20:59:59Z'));
    final progress=service(clock,store), campaign=AdventProgress.campaignId;
    await store.setSaved(campaign,id(3),true);expect(await progress.read(),isEmpty);
    expect(await progress.open(id(4)),isFalse);expect(await store.read(campaign),isEmpty);
    clock.value=DateTime.parse('2026-12-03T21:00:00Z');expect(await progress.read(),isEmpty);
    // A genuine old opened id is authoritative, even without a newer confetti flag.
    await store.recordOpened(campaign,id(4));expect(await progress.read(),{id(4)});
    expect(await store.readSurprises(campaign),isEmpty);
    expect(await store.claimSurprise(campaign,id(4)),isTrue);
    expect(await store.claimSurprise(campaign,id(4)),isFalse);
    expect(await progress.read(),{id(4)});
    expect(await progress.open(id(3)),isTrue);expect(await progress.read(),{id(3),id(4)});
    await store.setSaved(campaign,id(3),false);expect(await progress.read(),{id(3),id(4)});
  });
}
