import 'dart:io';
import 'package:flutter/rendering.dart' show Rect;
import 'package:flutter_test/flutter_test.dart';
import 'package:advent_calendar/advent_calendar.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class Memory implements AdventBoolStorage {
  final values = <String,bool>{};
  @override
  Future<bool?> read(String key) async => values[key];
  @override
  Future<void> write(String key,bool value) async { values[key]=value; }
}
void main() {
  setUpAll(tzdata.initializeTimeZones);
  final data=AdventContent.decode(File('assets/advent/calendar_2026.json').readAsStringSync());
  const campaign=AdventProgress.campaignId;
  LocalAdventRepository repo(Memory memory,String user) => LocalAdventRepository(storage:memory,calendar:data.calendar,userId:user);
  test('persistent contract survives reconstruction and concurrent opens; users isolated', () async {
    final memory=Memory(), a=repo(Memory(),'unused');
    expect(await a.read(campaign),isEmpty);
    final first=repo(memory,'user-1'), second=repo(memory,'user-1');
    await Future.wait([first.recordOpened(campaign,data.calendar.days[0].id),second.recordOpened(campaign,data.calendar.days[1].id),first.recordOpened(campaign,data.calendar.days[0].id)]);
    expect(await repo(memory,'user-1').read(campaign),hasLength(2));
    expect(await repo(memory,'user-2').read(campaign),isEmpty);
    expect(()=>first.recordOpened(campaign,'unknown'),throwsArgumentError);
  });
  test('saved advice independent from opens, restore/remove, event rejected', () async {
    final memory=Memory(), day=data.calendar.days[2];final first=repo(memory,'user');
    await first.setSaved(campaign,day.id,true);
    expect(await repo(memory,'user').readSaved(campaign),{day.id});
    expect(await first.read(campaign),isEmpty);
    await first.setSaved(campaign,day.id,false);expect(await first.readSaved(campaign),isEmpty);
    expect(()=>first.setSaved(campaign,data.calendar.days.first.id,true),throwsArgumentError);
    await expectLater(first.read('wrong'),throwsArgumentError);
  });
  test('timed source exports Moscow instant and crosses New Year correctly', () {
    final zone=tz.getLocation('Europe/Moscow');
    final payload=calendarExport(data.calendar.days.last,zone,CalendarExportMode.sourceTime);
    expect(payload.start,DateTime.utc(2026,12,31,20));expect(payload.end,DateTime.utc(2026,12,31,21));
    expect(payload.allDay,isFalse);
    expect(()=>calendarExport(data.calendar.days[3],zone,CalendarExportMode.sourceTime),throwsStateError);
    final allDay=calendarExport(data.calendar.days.last,zone,CalendarExportMode.allDay);
    expect(allDay.end.year,2027);expect(allDay.end.month,1);expect(allDay.end.day,1);
  });
  test('calendar cancelled before OS, unsupported and launch failures', () async {
    var launches=0;
    final actions=NativeAdventActions(confirmCalendar:(_) async=>null,shareOrigin:()=>Rect.zero,
      calendarSupported:true,launchCalendar:(_)async{launches++;return true;});
    expect(await actions.addToCalendar(data.calendar.days.first,tz.getLocation('Europe/Moscow')),SystemActionResult.cancelled);
    expect(launches,0);
    final failed=NativeAdventActions(confirmCalendar:(_)async=>CalendarExportMode.allDay,shareOrigin:()=>Rect.zero,calendarSupported:true,launchCalendar:(_)async=>false);
    expect(await failed.addToCalendar(data.calendar.days[3],tz.getLocation('Europe/Moscow')),SystemActionResult.unavailable);
    expect(await failed.addToCalendar(data.calendar.days[2],tz.getLocation('Europe/Moscow')),SystemActionResult.unavailable);
  });
  test('share source includes original details and propagates cancellation/errors', () async {
    final actions=NativeAdventActions(confirmCalendar:(_)async=>null,shareOrigin:()=>const Rect.fromLTWH(0,0,10,10),share:(title,text,origin)async{
      expect(text,contains('39 этаж, переговорная Б.39.04; 28 этаж'));expect(origin.width,10);return SystemActionResult.cancelled;
    });
    expect(await actions.share(data.calendar.days[3]),SystemActionResult.cancelled);
  });
}
