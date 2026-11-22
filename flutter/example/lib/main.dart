// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:advent_calendar/advent_calendar.dart';
import 'package:timezone/data/latest.dart' as tzdata;

void main() { tzdata.initializeTimeZones(); runApp(const MyApp()); }
class SystemClock implements AdventClock {
  @override
  DateTime nowUtc() => DateTime.now().toUtc();
}
/// Demo session only. Real host must supply durable user-scoped storage.
class SessionStore implements ProgressRepository, SavedAdviceRepository {
  final opened = <String>{}, saved = <String>{};
  @override
  Future<Set<String>> read(String campaignId) async => {...opened};
  @override
  Future<void> recordOpened(String campaignId, String dayId) async { opened.add(dayId); }
  @override
  Future<Set<String>> readSaved(String campaignId) async => {...saved};
  @override
  Future<void> setSaved(String campaignId,String dayId,bool value) async { if(value) { saved.add(dayId); } else { saved.remove(dayId); } }
}
class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _AppState();
}
class _AppState extends State<MyApp> {
  final store = SessionStore();
  late final content = AdventContent.load();
  final time = CampaignTime.moscow(clock: SystemClock());
  @override
  Widget build(BuildContext context) => MaterialApp(debugShowCheckedModeBanner:false,
    theme: ThemeData(colorSchemeSeed:const Color(0xff284936),fontFamily:'Roboto'),
    home: FutureBuilder<AdventContent>(future:content,builder:(context,snapshot) {
      if(snapshot.hasError) return const Scaffold(body:Center(child:Text('Не удалось загрузить календарь')));
      if(!snapshot.hasData) return const Scaffold(body:Center(child:CircularProgressIndicator()));
      final data=snapshot.data!;
      return Scaffold(backgroundColor:const Color(0xff0a2a20),body:SafeArea(child:Padding(padding:const EdgeInsets.all(16),child:Column(children:[
        AdventEntryCard(daysUntilNewYear:time.daysUntilNewYear,onOpen:()=>Navigator.push(context,MaterialPageRoute<void>(builder:(_)=>AdventCalendarScreen(
          content:data,time:time,progress:AdventProgress(calendar:data.calendar,time:time,repository:store),savedAdvice:store)))),
        const SizedBox(height:24),const Text('Автономное demo. Прогресс и сохранённые советы — только на время сессии. Системные действия подключает хост.',style:TextStyle(color:Colors.white70)),
      ]))));
    }));
}
