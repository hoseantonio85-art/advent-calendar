import 'dart:io';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:advent_calendar/advent_calendar.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class Clock implements AdventClock {
  Clock(this.value);
  DateTime value;
  @override
  DateTime nowUtc() => value;
}
class Store implements ProgressRepository {
  final ids = <String>{};
  @override
  Future<Set<String>> read(String campaignId) async => {...ids};
  @override
  Future<void> recordOpened(String campaignId, String dayId) async { ids.add(dayId); }
}
void main() {
  final source = File('assets/advent/calendar_2026.json').readAsStringSync();
  final content = AdventContent.decode(source), calendar = content.calendar;
  setUpAll(tzdata.initializeTimeZones);
  test('31 unique days, 14 events, 17 advice, immutable source', () {
    expect(calendar.days.length, 31);
    expect(calendar.days.where((d) => d.kind == DayKind.event).length, 14);
    expect(calendar.days.where((d) => d.kind == DayKind.advice).length, 17);
    expect(() => calendar.days.first.event!['title'] = 'changed', throwsUnsupportedError);
    expect(calendar.days[10].title, calendar.days[14].title);
    expect(calendar.days[10].id, isNot(calendar.days[14].id));
    expect(calendar.days[3].event!['startTime'], isNull);
    expect(calendar.days[3].event!['locations'], hasLength(2));
  });
  test('invalid count, duplicate and normalized invalid dates rejected', () {
    for (final mode in ['count','duplicate','date','kind']) {
      final data = jsonDecode(source) as Map<String, dynamic>;
      final days = data['days'] as List;
      if(mode == 'count') days.removeLast();
      if(mode == 'duplicate') days[1]['id'] = days[0]['id'];
      if(mode == 'date') days[0]['date'] = '2026-11-31';
      if(mode == 'kind') days[0]['kind'] = 'advice';
      expect(() => AdventContent.decode(jsonEncode(data)), throwsFormatException);
    }
  });
  test('events available across years; advice uses full date', () {
    for(final day in calendar.days) {
      expect(calendar.isAvailable(day, DateTime.utc(2025)), day.kind == DayKind.event && !day.revealOnDate);
      expect(calendar.isAvailable(day, day.date), isTrue);
      expect(calendar.isAvailable(day, DateTime.utc(2027)), isTrue);
      if(day.kind == DayKind.advice) expect(calendar.isAvailable(day, day.date.subtract(const Duration(days: 1))), isFalse);
    }
  });
  test('unique available opens only, unknown/corrupt restored ids excluded', () {
    final date = DateTime.utc(2026,12,2), event = calendar.days.first.id, advice = calendar.days[2].id;
    final opened = calendar.open(event, [], date);
    expect(calendar.open(event, opened, date), {event});
    expect(calendar.open(advice, opened, date), {event});
    expect(calendar.open('unknown', opened, date), {event});
    expect(calendar.eligibleProgress([event,event,advice,'unknown'],date), {event});
    expect(calendar.open(advice, opened, DateTime.utc(2026,12,3)), {event,advice});
  });
  test('configured IANA zones: midnight, year rollover, DST', () {
    final clock = Clock(DateTime.parse('2026-12-02T20:59:59Z'));
    final time = CampaignTime(clock: clock,location: tz.getLocation('Europe/Moscow'));
    expect(time.today, DateTime.utc(2026,12,2));
    clock.value = clock.value.add(const Duration(seconds: 1));
    expect(time.today, DateTime.utc(2026,12,3));
    clock.value = DateTime.parse('2026-12-31T21:00:00Z');
    expect(time.today, DateTime.utc(2027)); expect(time.daysUntilNewYear,0);
    clock.value = DateTime.parse('2026-12-30T21:00:00Z');expect(time.daysUntilNewYear,1);
    final ny = CampaignTime(clock: clock,location: tz.getLocation('America/New_York'));
    clock.value = DateTime.parse('2026-03-08T06:59:59Z');
    final before = ny.today;clock.value = clock.value.add(const Duration(seconds:1));expect(ny.today,before);
  });
  test('approved Moscow factory ignores device timezone', () {
    final clock = Clock(DateTime.parse('2026-12-02T21:00:00Z'));
    final previous = tz.local;
    try {
      tz.setLocalLocation(tz.getLocation('America/Los_Angeles'));
      final time = CampaignTime.moscow(clock: clock);
      expect(time.location.name, 'Europe/Moscow');
      expect(time.today, DateTime.utc(2026, 12, 3));
      expect(time.daysUntilNewYear, 29);
    } finally { tz.setLocalLocation(previous); }
  });
  test('host service rejects locked opens and store merges concurrent repeats', () async {
    final clock=Clock(DateTime.parse('2026-12-02T20:59:59Z')), store=Store();
    final service=AdventProgress(calendar:calendar,time:CampaignTime(clock:clock,location:tz.getLocation('Europe/Moscow')),repository:store);
    expect(await service.open(calendar.days[2].id),isFalse);expect(store.ids,isEmpty);
    expect(await service.open('unknown'),isFalse);
    await Future.wait([service.open(calendar.days.first.id),service.open(calendar.days.first.id),service.open(calendar.days[1].id)]);
    expect(await service.read(),hasLength(2));
    clock.value=clock.value.add(const Duration(seconds:1));expect(await service.open(calendar.days[2].id),isTrue);
    expect(await service.read(),hasLength(3));
  });
}
