import 'dart:io';
import 'dart:ui' show ImageByteFormat;
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:advent_calendar/advent_calendar.dart';
import 'package:timezone/data/latest.dart' as tzdata;

class VisualClock implements AdventClock {
  VisualClock([DateTime? date]):value=date??DateTime.utc(2026,12,15,9);
  final DateTime value;
  @override
  DateTime nowUtc()=>value;
}
class VisualStore implements ProgressRepository,SavedAdviceRepository,SurpriseRepository{
  final ids=<String>{},saved=<String>{},revealed=<String>{};
  @override
  Future<Set<String>> readSurprises(String c)async=>revealed;
  @override
  Future<bool> claimSurprise(String c,String id)async=>revealed.add(id);
  @override
  Future<Set<String>> read(String c)async=>{...ids};
  @override
  Future<void> recordOpened(String c,String id)async{ids.add(id);}
  @override
  Future<Set<String>> readSaved(String c)async=>{...saved};
  @override
  Future<void> setSaved(String c,String id,bool value)async{if(value){saved.add(id);}else{saved.remove(id);}}
}
class TestAssets extends CachingAssetBundle{
  @override
  Future<ByteData> load(String key)=>rootBundle.load(key.replaceFirst('packages/advent_calendar/',''));
}
void main(){
  testWidgets('visual audit: all sizes, frozen days, finale, long sheets and text 200%',(tester)async{
    tzdata.initializeTimeZones();
    await tester.runAsync(()async{
      for(final font in [('Yeseva One','YesevaOne-Regular.ttf'),('Roboto','Roboto-Variable.ttf')]){
        await (FontLoader('packages/advent_calendar/${font.$1}')..addFont(Future.value(ByteData.sublistView(File('assets/fonts/${font.$2}').readAsBytesSync())))).load();
      }
      final emoji=File('/usr/share/fonts/truetype/noto/NotoColorEmoji.ttf');
      if(await emoji.exists()){await (FontLoader('Noto Color Emoji')..addFont(Future.value(ByteData.sublistView(await emoji.readAsBytes())))).load();}
      await (FontLoader('MaterialIcons')..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    });
    final content=AdventContent.decode(File('assets/advent/calendar_2026.json').readAsStringSync());
    final assets=TestAssets();
    addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);
    Future<void> capture(String name)async{
      await tester.pumpAndSettle();expect(tester.takeException(),isNull,reason:name);
      await tester.runAsync(()async{
        final image=await tester.renderObject<RenderRepaintBoundary>(find.byKey(const ValueKey('capture'))).toImage(pixelRatio:1);
        final bytes=await image.toByteData(format:ImageByteFormat.png);image.dispose();
        final folder=Directory('build/visual-qa');await folder.create(recursive:true);
        await File('${folder.path}/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
      });
    }
    Future<void> mount(double width,{double scale=1,DateTime? date,int savedCount=4,int openedCount=0})async{
      await tester.pumpWidget(const SizedBox());
      tester.view.physicalSize=Size(width,844);tester.view.devicePixelRatio=1;
      final time=CampaignTime.moscow(clock:VisualClock(date)),store=VisualStore();
      store.ids.addAll(content.calendar.days.where((d)=>d.kind==DayKind.event&&!d.revealOnDate).take(openedCount).map((d)=>d.id));
      store.saved.addAll(content.calendar.days.where((d)=>d.kind==DayKind.advice).take(savedCount).map((d)=>d.id));
      await tester.pumpWidget(RepaintBoundary(key:const ValueKey('capture'),child:DefaultAssetBundle(bundle:assets,child:MaterialApp(
        debugShowCheckedModeBanner:false,theme:ThemeData(fontFamily:'packages/advent_calendar/Roboto',colorSchemeSeed:const Color(0xff284936)),
        builder:(context,child)=>MediaQuery(data:MediaQueryData(size:Size(width,844),disableAnimations:true,textScaler:TextScaler.linear(scale)),child:child!),
        home:AdventCalendarScreen(content:content,time:time,progress:AdventProgress(calendar:content.calendar,time:time,repository:store),savedAdvice:store,
          actions:NativeAdventActions(confirmCalendar:(_)async=>null,shareOrigin:()=>const Rect.fromLTWH(0,0,10,10)))))));
      await tester.pumpAndSettle();
      await tester.runAsync(()async{for(final asset in content.assets.values){await precacheImage(AssetImage(asset,package:'advent_calendar'),tester.element(find.byType(AdventCalendarScreen)));}});
      await tester.pumpAndSettle();
    }
    Future<void> show(int day)async{
      if(day==1||day==3){
        tester.state<ScrollableState>(find.descendant(of:find.byKey(const ValueKey('calendar-scroll')),matching:find.byType(Scrollable)).first).position.jumpTo(0);
      }else{await tester.ensureVisible(find.byKey(ValueKey('day-$day')));}
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ValueKey('day-$day')));await tester.pumpAndSettle();
      expect(find.byTooltip('Закрыть').hitTestable(),findsOneWidget);
    }
    Future<void> close()async{await tester.tap(find.byTooltip('Закрыть'));await tester.pumpAndSettle();}
    for(final width in [320.0,360.0,390.0,430.0]){
      await mount(width);await capture('calendar-${width.toInt()}');
      if(width==320||width==390){
        final scroll=tester.state<ScrollableState>(find.descendant(of:find.byKey(const ValueKey('calendar-scroll')),matching:find.byType(Scrollable)).first);
        scroll.position.jumpTo(scroll.position.maxScrollExtent);await capture('finale-${width.toInt()}');
      }
      if(width==390){
        await Scrollable.ensureVisible(tester.element(find.byKey(const ValueKey('day-15'))),alignment:.4);await capture('middle-390');
        await show(1);await capture('event-390');await close();
        await show(3);await capture('advice-390');await tester.tap(find.text('Совет сохранён'));await tester.pumpAndSettle();expect(find.text('Сохранить совет'),findsOneWidget);await tester.tap(find.text('Сохранить совет'));await tester.pumpAndSettle();expect(find.text('Совет сохранён'),findsOneWidget);await close();
        tester.state<ScrollableState>(find.descendant(of:find.byKey(const ValueKey('calendar-scroll')),matching:find.byType(Scrollable)).first).position.jumpTo(0);await tester.pumpAndSettle();
        await tester.tap(find.text('Твоя история декабря'));await capture('history-390');await tester.ensureVisible(find.text('Показать все 4'));await tester.tap(find.text('Показать все 4'));await tester.pumpAndSettle();expect(find.text('Свернуть'),findsOneWidget);await tester.tap(find.text(content.calendar.days[2].title));await capture('history-expanded-390');await close();
      }
    }
    for(final scale in [1.0,2.0]){
      await mount(320,scale:scale);
      if(scale==2){await tester.ensureVisible(find.byKey(const ValueKey('progress-count')));await capture('text200-calendar-320');}
      await show(11);await capture(scale==1?'long-event-320':'text200-long-event-320');
      final scroll=tester.state<ScrollableState>(find.descendant(of:find.byKey(const ValueKey('day-sheet-scroll')),matching:find.byType(Scrollable)).first);
      scroll.position.jumpTo(scroll.position.maxScrollExtent);await tester.pumpAndSettle();
      expect(find.byTooltip('Закрыть').hitTestable(),findsOneWidget);
      expect(find.text('Поделиться').hitTestable(),findsOneWidget);
      await capture(scale==1?'long-event-bottom-320':'text200-long-event-bottom-320');await close();
    }
    for(final width in [320.0,360.0,390.0,430.0]){
      await mount(width,scale:.8,openedCount:7);await capture('xxs-progress-'+width.toInt().toString());
    }
    await mount(390,date:DateTime.utc(2026,12,2,9));
    await tester.tap(find.byKey(const ValueKey('day-3')));await capture('locked-advice-toast-390');
    for(final count in [0,1]){
      await mount(390,savedCount:count);await tester.tap(find.text('Твоя история декабря'));
      await capture('history-saved-$count-390');
      expect(find.text('Показать все 4'),findsNothing);
      if(count==0){expect(find.text('Пока нет сохранённых советов. Открой совет и нажми «Сохранить совет» — он появится здесь.'),findsOneWidget);}
      else{expect(find.text(content.calendar.days[2].title),findsOneWidget);}
      await close();
    }
    for(final day in [3,4]){
      await mount(390,date:DateTime.utc(2026,12,day,9));await capture('surprise-$day-390');
      if(day==3){await tester.ensureVisible(find.byKey(const ValueKey('day-4')));await tester.tap(find.byKey(const ValueKey('day-4')));await tester.pumpAndSettle();expect(find.text('День какао'),findsNothing);expect(find.text('Сюрприз откроется 4 декабря'),findsOneWidget);}
      else{await show(4);await capture('surprise-revealed-sheet-390');await close();}
    }
    await tester.pumpWidget(const SizedBox());
  },timeout:const Timeout(Duration(minutes:2)),skip:!const bool.fromEnvironment('ADVENT_VISUALS'));
}
