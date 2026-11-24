import 'dart:io';
import 'dart:ui' show ImageByteFormat;
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:advent_calendar/advent_calendar.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'visual_test.dart' show VisualStore, TestAssets;

class CountdownClock implements AdventClock {
  DateTime value = DateTime.utc(2026, 12, 15, 9, 5, 7);
  @override
  DateTime nowUtc() => value;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AdventContent content;
  setUpAll(() async {
    tzdata.initializeTimeZones();
    content = AdventContent.decode(File('assets/advent/calendar_2026.json').readAsStringSync());
    for (final font in [('Yeseva One', 'YesevaOne-Regular.ttf'), ('Roboto', 'Roboto-Variable.ttf')]) {
      await (FontLoader('packages/advent_calendar/${font.$1}')
        ..addFont(Future.value(ByteData.sublistView(File('assets/fonts/${font.$2}').readAsBytesSync())))).load();
    }
    await (FontLoader('MaterialIcons')..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  Future<void> mount(WidgetTester tester, double width, double scale, CountdownClock clock) async {
    await tester.pumpWidget(const SizedBox());
    tester.view.physicalSize = Size(width, 844); tester.view.devicePixelRatio = 1;
    final store = VisualStore()..ids.addAll(content.calendar.days.take(2).map((d) => d.id));
    final time = CampaignTime.moscow(clock: clock);
    await tester.pumpWidget(RepaintBoundary(key: const ValueKey('history-capture'),
      child: DefaultAssetBundle(bundle: TestAssets(), child: MaterialApp(debugShowCheckedModeBanner: false,
        theme: ThemeData(fontFamily: 'packages/advent_calendar/Roboto'),
        builder: (context, child) => MediaQuery(data: MediaQueryData(size: Size(width, 844),
          textScaler: TextScaler.linear(scale), disableAnimations: true), child: child!),
        home: AdventCalendarScreen(content: content, time: time,
          progress: AdventProgress(calendar: content.calendar, time: time, repository: store), savedAdvice: store),
      )),
    ));
    await tester.runAsync(() => precacheImage(
      const AssetImage('assets/advent/entry_fir_v9.webp', package: 'advent_calendar'),
      tester.element(find.byType(AdventCalendarScreen))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Твоя история декабря')); await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('history-countdown'))); await tester.pumpAndSettle();
  }

  void cleanup(WidgetTester tester) {
    addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
  }

  String value(WidgetTester tester, int index) => tester.widget<Text>(find.byKey(ValueKey('countdown-value-$index'))).data!;

  for (final width in [320.0, 360.0, 390.0, 430.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('history countdown fits $width dp / text $scale with sharp glass values', (tester) async {
        cleanup(tester);
        await mount(tester, width, scale, CountdownClock());
        expect(tester.takeException(), isNull);
        final counter = find.byKey(const ValueKey('history-countdown'));
        final bounds = tester.getRect(counter);
        final tiles = List.generate(4, (i) => tester.getRect(find.byKey(ValueKey('countdown-tile-$i'))));
        expect(find.descendant(of: counter, matching: find.byType(BackdropFilter)), findsNWidgets(4));
        for (final filter in find.descendant(of: counter, matching: find.byType(BackdropFilter)).evaluate()) {
          expect(find.ancestor(of: find.byWidget(filter.widget), matching: find.byType(ClipRRect)), findsWidgets);
          expect(find.descendant(of: find.byWidget(filter.widget), matching: find.byType(Text)), findsNothing);
        }
        for (var i = 0; i < 4; i++) {
          expect(bounds.contains(tiles[i].topLeft), isTrue); expect(bounds.contains(tiles[i].bottomRight), isTrue);
          final number = tester.renderObject<RenderParagraph>(find.byKey(ValueKey('countdown-value-$i')));
          expect(number.didExceedMaxLines, isFalse);
          final painted = MatrixUtils.transformRect(number.getTransformTo(null), Offset.zero & number.size);
          expect(tiles[i].inflate(1).contains(painted.topLeft), isTrue);
          expect(tiles[i].inflate(1).contains(painted.bottomRight), isTrue);
        }
        expect(tiles[0].top, tiles[1].top);
        if (scale == 1) {
          expect(tiles.map((r) => r.top).toSet().length, 1);
          expect(tiles[2].left, greaterThan(tiles[1].right));
          // Previous block geometry at standard scale, without inflated padding.
          expect(bounds.height, lessThan(210));
        } else {
          expect(tiles[2].top, greaterThan(tiles[0].bottom));
          expect(tiles[2].left, tiles[0].left); expect(tiles[3].top, tiles[2].top);
        }
        expect(List.generate(4, (i) => value(tester, i)), ['16', '11', '54', '53']);
        expect(find.text('Засчитано 2 из 31 дней календаря'), findsOneWidget);
        await tester.pumpWidget(const SizedBox());
      });
    }
  }

  testWidgets('second tick preserves background layer and Moscow new year boundary', (tester) async {
    cleanup(tester);
    final clock = CountdownClock();
    await mount(tester, 390, 1, clock);
    expect(List.generate(4, (i) => value(tester, i)), ['16', '11', '54', '53']);
    final bg = tester.renderObject<RenderRepaintBoundary>(find.byKey(const ValueKey('history-countdown-background')));
    final paints = bg.debugSymmetricPaintCount + bg.debugAsymmetricPaintCount;
    clock.value = clock.value.add(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1)); await tester.pump();
    expect(List.generate(4, (i) => value(tester, i)), ['16', '11', '54', '52']);
    expect(bg.debugSymmetricPaintCount + bg.debugAsymmetricPaintCount, paints,
      reason: 'The photograph must not be repainted when only the clock ticks.');
    // A changed holiday message may legitimately change the block's height;
    // check its arithmetic separately from the ordinary-tick paint assertion.
    clock.value = DateTime.utc(2026, 12, 31, 20, 59, 59);
    await mount(tester, 390, 1, clock);
    expect(List.generate(4, (i) => value(tester, i)), ['00', '00', '00', '01']);
    clock.value = clock.value.add(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1)); await tester.pump();
    expect(List.generate(4, (i) => value(tester, i)), ['00', '00', '00', '00']);
    expect(find.text('С Новым годом! Пусть сбудется всё самое светлое.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('history countdown visual audit at four widths and large text', (tester) async {
    cleanup(tester);
    for (final width in [320.0, 360.0, 390.0, 430.0]) {
      for (final scale in [1.0, 2.0]) {
        await mount(tester, width, scale, CountdownClock());
        expect(tester.takeException(), isNull);
        await tester.runAsync(() async {
          final image = await tester.renderObject<RenderRepaintBoundary>(find.byKey(const ValueKey('history-capture'))).toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ImageByteFormat.png); image.dispose();
          final folder = Directory('build/history-countdown-qa'); await folder.create(recursive: true);
          await File('${folder.path}/history-countdown-${width.toInt()}-text${(scale * 100).toInt()}.png')
            .writeAsBytes(bytes!.buffer.asUint8List());
        });
      }
    }
    await tester.pumpWidget(const SizedBox());
  }, skip: !const bool.fromEnvironment('ADVENT_VISUALS'));
}
