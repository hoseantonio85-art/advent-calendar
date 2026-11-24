// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:advent_calendar/advent_calendar.dart';
import 'package:timezone/data/latest.dart' as tzdata;

void main() { tzdata.initializeTimeZones(); runApp(const MyApp()); }
class SystemClock implements AdventClock {
  @override
  DateTime nowUtc() => DateTime.now().toUtc();
}
class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _AppState();
}
class _AppState extends State<MyApp> {
  final storage = PreferencesBoolStorage();
  late final content = AdventContent.load();
  final time = CampaignTime.moscow(clock: SystemClock());
  @override
  Widget build(BuildContext context) => MaterialApp(debugShowCheckedModeBanner:false,
    theme: ThemeData(colorSchemeSeed:const Color(0xff284936),fontFamily:'packages/advent_calendar/Roboto'),
    home: FutureBuilder<AdventContent>(future:content,builder:(context,snapshot) {
      if(snapshot.hasError) return const Scaffold(body:Center(child:Text('Не удалось загрузить календарь')));
      if(!snapshot.hasData) return const Scaffold(body:Center(child:CircularProgressIndicator()));
      final data=snapshot.data!;
      final store=LocalAdventRepository(storage:storage,calendar:data.calendar,userId:'standalone-demo');
      final actions=NativeAdventActions(
        shareOrigin:()=>Offset.zero & MediaQuery.sizeOf(context),
        confirmCalendar:(day)=>showDialog<CalendarExportMode>(context:context,builder:(context)=>AlertDialog(
          title:const Text('Добавить событие?'),
          content:Text('${day.title}\n${day.date.day} декабря 2026\n${day.event!['time']} · Москва\n${day.event!['place']}\n\nПроверьте дату, время и место перед сохранением.'),
          actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('Отмена')),
            if(day.event!['startTime']!=null) TextButton(onPressed:()=>Navigator.pop(context,CalendarExportMode.sourceTime),child:const Text('Указанное время')),
            TextButton(onPressed:()=>Navigator.pop(context,CalendarExportMode.allDay),child:const Text('Дата на весь день')),
          ])));

      return Scaffold(backgroundColor:const Color(0xff0a2a20),body:SafeArea(child:Padding(padding:const EdgeInsets.all(16),child:Column(children:[
        AdventEntryCard(daysUntilNewYear:time.daysUntilNewYear,onOpen:()=>Navigator.push(context,MaterialPageRoute<void>(builder:(_)=>AdventCalendarScreen(
          content:data,time:time,progress:AdventProgress(calendar:data.calendar,time:time,repository:store),savedAdvice:store,actions:actions)))),
        const SizedBox(height:24),const Text('Автономное demo. Открытые дни и советы сохраняются на этом устройстве. Календарь ОС доступен на Android и iOS.',style:TextStyle(color:Colors.white70)),
      ]))));
    }));
}
