import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:advent_calendar/advent_calendar.dart';
import 'package:timezone/data/latest.dart' as data;
import 'package:timezone/timezone.dart' as tz;
class Clock implements AdventClock{Clock(this.now);DateTime now;@override DateTime nowUtc()=>now;}
class Memory implements AdventBoolStorage{final values=<String,bool>{};@override Future<bool?> read(String key)async=>values[key];@override Future<void> write(String key,bool v)async{values[key]=v;}}
void main(){
 final calendar=AdventContent.decode(File('assets/advent/calendar_2026.json').readAsStringSync()).calendar;
 setUpAll(data.initializeTimeZones);
 test('four surprises unlock at Moscow midnight, independently of device/year',(){
   for(final d in calendar.days){
     expect(calendar.isAvailable(d,DateTime.utc(2025)),d.kind==DayKind.event&&!d.revealOnDate);
     if(d.revealOnDate){expect([4,9,11,15],contains(d.date.day));expect(calendar.isAvailable(d,d.date.subtract(const Duration(days:1))),isFalse);expect(calendar.isAvailable(d,d.date),isTrue);expect(d.event!['startTime'],isNull);}
   }
   final clock=Clock(DateTime.parse('2026-12-03T20:59:59Z')),time=CampaignTime.moscow(clock:Clock(DateTime.parse('2026-12-03T20:59:59Z')));
   expect(calendar.isAvailable(calendar.days[3],time.today),isFalse);
   clock.now=DateTime.parse('2026-12-03T21:00:00Z');
   expect(calendar.isAvailable(calendar.days[3],CampaignTime.moscow(clock:clock).today),isTrue);
   expect(tz.getLocation('Europe/Moscow').name,'Europe/Moscow');
 });
 test('legacy opens do not consume reveal; no progress at midnight; first claim is unique',()async{
   final memory=Memory(),clock=Clock(DateTime.parse('2026-12-03T20:59:59Z'));
   final repo=LocalAdventRepository(storage:memory,calendar:calendar,userId:'a');
   final progress=AdventProgress(calendar:calendar,time:CampaignTime.moscow(clock:clock),repository:repo);
   final id=calendar.days[3].id;await repo.recordOpened(AdventProgress.campaignId,id);
   expect(await progress.read(),isEmpty);expect(await progress.open(id),isFalse);
   clock.now=DateTime.parse('2026-12-03T21:00:00Z');expect(await progress.read(),isEmpty);
   expect(await progress.open(id),isTrue);
   final claims=await Future.wait([repo.claimSurprise(AdventProgress.campaignId,id),repo.claimSurprise(AdventProgress.campaignId,id)]);
   expect(claims.where((v)=>v),hasLength(1));expect(await progress.read(),{id});
   final restored=LocalAdventRepository(storage:memory,calendar:calendar,userId:'a');expect(await restored.claimSurprise(AdventProgress.campaignId,id),isFalse);
   expect(await LocalAdventRepository(storage:memory,calendar:calendar,userId:'b').readSurprises(AdventProgress.campaignId),isEmpty);
 });
 test('new event preserves old advice, exact counts and no invented time',(){
   final day=calendar.days[18];expect(day.kind,DayKind.event);expect(day.advice['title'],'Помни о главном');expect(day.event!['time'],'Не указано');expect(day.event!['locations'],['Система оценок']);
   expect(calendar.days.where((d)=>d.kind==DayKind.event),hasLength(14));expect(calendar.days.where((d)=>d.kind==DayKind.advice),hasLength(17));
 });
}
