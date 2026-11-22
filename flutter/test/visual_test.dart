import 'dart:convert';
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
  @override
  DateTime nowUtc()=>DateTime.utc(2026,12,15,9);
}
class VisualStore implements ProgressRepository, SavedAdviceRepository {
  @override
  Future<Set<String>> readSaved(String c) async => {};
  @override
  Future<void> setSaved(String c,String id,bool saved) async {}
  final ids=<String>{};
  @override
  Future<Set<String>> read(String c)async=>ids;
  @override
  Future<void> recordOpened(String c,String id)async{ids.add(id);}
}
class TestAssets extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key)=>rootBundle.load(key.replaceFirst('packages/advent_calendar/',''));
}
void main(){
  testWidgets('capture real-font native screens', (tester)async{
    tzdata.initializeTimeZones();
    await tester.runAsync(() async {
    for(final font in [('Yeseva One','YesevaOne-Regular.ttf'),('Roboto','Roboto-Variable.ttf')]){
      final loader=FontLoader('packages/advent_calendar/${font.$1}')..addFont(Future.value(ByteData.sublistView(File('assets/fonts/${font.$2}').readAsBytesSync())));
      await loader.load();
    }
      final icons=FontLoader('MaterialIcons')..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
    });
    final content=AdventContent.decode(File('assets/advent/calendar_2026.json').readAsStringSync());
    final time=CampaignTime.moscow(clock:VisualClock()), store=VisualStore();
    addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);
    Future<void> capture(String name)async{
      await tester.runAsync(() async {
      final boundary=tester.renderObject<RenderRepaintBoundary>(find.byKey(const ValueKey('capture')));
      final image=await boundary.toImage(pixelRatio:1);
      final bytes=await image.toByteData(format:ImageByteFormat.png);image.dispose();
      final encoded=base64Encode(bytes!.buffer.asUint8List());
      for(var i=0;i<encoded.length;i+=40000){
        // Machine-readable QA artifact, only enabled by the CI flag below.
        print('ADVENT_PNG|$name|${i~/40000}|${encoded.substring(i, (i+40000).clamp(0,encoded.length))}');
      }
      });
    }
    for(final width in [320.0,360.0,390.0,430.0]){
      tester.view.physicalSize=Size(width,844);tester.view.devicePixelRatio=1;
      await tester.pumpWidget(RepaintBoundary(key:const ValueKey('capture'),child:DefaultAssetBundle(bundle:TestAssets(),child:MaterialApp(
        debugShowCheckedModeBanner:false,
        theme:ThemeData(colorSchemeSeed:const Color(0xff284936),fontFamily:'packages/advent_calendar/Roboto'),
        home:MediaQuery(data:MediaQueryData(size:Size(width,844),disableAnimations:true),
          child:AdventCalendarScreen(content:content,time:time,progress:AdventProgress(calendar:content.calendar,time:time,repository:store),
            savedAdvice:store,actions:NativeAdventActions(confirmCalendar:(_)async=>null,shareOrigin:()=>const Rect.fromLTWH(0,0,10,10))))))));
      await tester.pumpAndSettle();
      await tester.runAsync(()=>Future<void>.delayed(const Duration(milliseconds:200)));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        for(final asset in content.assets.values) {
          await precacheImage(AssetImage(asset,package:'advent_calendar'),tester.element(find.byType(AdventCalendarScreen)));
        }
      });
      await tester.pumpAndSettle();
      await capture('calendar-${width.toInt()}');
      if(width==390){
        await tester.tap(find.byKey(const ValueKey('day-1')));await tester.pumpAndSettle();await capture('event-390');
        await tester.tap(find.byTooltip('Закрыть'));await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('day-3')));await tester.pumpAndSettle();await capture('advice-390');
        await tester.tap(find.byTooltip('Закрыть'));await tester.pumpAndSettle();
      }
      expect(tester.takeException(),isNull);
      await tester.pumpWidget(const SizedBox());
    }
  },timeout:const Timeout(Duration(minutes:1)),skip:!const bool.fromEnvironment('ADVENT_VISUALS'));
}
