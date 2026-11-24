import 'dart:io';
import 'dart:ui' show ImageByteFormat;
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:advent_calendar/advent_entry_card.dart';
import 'fixtures/entry_card_before_polish.dart';

class EntryAssets extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) => rootBundle.load(key.replaceFirst('packages/advent_calendar/', ''));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    for (final font in [('Yeseva One', 'YesevaOne-Regular.ttf'), ('Roboto', 'Roboto-Variable.ttf')]) {
      await (FontLoader('packages/advent_calendar/${font.$1}')
        ..addFont(Future.value(ByteData.sublistView(File('assets/fonts/${font.$2}').readAsBytesSync())))).load();
    }
    await (FontLoader('Roboto')..addFont(Future.value(ByteData.sublistView(File('assets/fonts/Roboto-Variable.ttf').readAsBytesSync())))).load();
    await (FontLoader('MaterialIcons')..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  Future<void> mount(WidgetTester tester, double width, {double scale = 1, int days = 38,
      bool before = false, VoidCallback? onOpen}) async {
    await tester.pumpWidget(const SizedBox());
    tester.view.physicalSize = Size(width, 176);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(RepaintBoundary(key: const ValueKey('entry-capture'),
      child: DefaultAssetBundle(bundle: EntryAssets(), child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(fontFamily: 'packages/advent_calendar/Roboto'),
        builder: (context, child) => MediaQuery(
          data: MediaQueryData(size: Size(width, 176), textScaler: TextScaler.linear(scale)), child: child!),
        home: Scaffold(backgroundColor: const Color(0xff0a2a20), body: Center(child: Padding(
          padding: const EdgeInsets.all(16),
          child: before ? EntryCardBeforePolish(daysUntilNewYear: days, onOpen: onOpen ?? () {})
            : AdventEntryCard(daysUntilNewYear: days, onOpen: onOpen ?? () {}),
        ))),
      )),
    ));
    await tester.runAsync(() => precacheImage(
      const AssetImage('assets/advent/entry_fir_v9.webp', package: 'advent_calendar'),
      tester.element(find.byType(Scaffold))));
    await tester.pumpAndSettle();
  }

  void resetView(WidgetTester tester) {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  // Check the painted text bounds after FittedBox transforms, with real fonts.
  void expectTextInside(WidgetTester tester, Finder text, Rect bounds) {
    final paragraph = tester.renderObject<RenderParagraph>(text);
    expect(paragraph.didExceedMaxLines, isFalse);
    final boxes = paragraph.getBoxesForSelection(TextSelection(
      baseOffset: 0, extentOffset: paragraph.text.toPlainText().length));
    expect(boxes, isNotEmpty);
    for (final box in boxes) {
      final painted = MatrixUtils.transformRect(paragraph.getTransformTo(null), box.toRect());
      expect(bounds.inflate(1).contains(painted.topLeft), isTrue, reason: '$painted in $bounds');
      expect(bounds.inflate(1).contains(painted.bottomRight), isTrue, reason: '$painted in $bounds');
    }
  }

  for (final width in [320.0, 360.0, 390.0, 430.0]) {
    for (final scale in [.8, 1.0, 1.5, 2.0]) {
      testWidgets('entry v9: $width dp, text $scale, countdown and festive fit', (tester) async {
        resetView(tester);
        for (final days in [38, 365, 0, -1]) {
          await mount(tester, width, scale: scale, days: days);
          expect(tester.takeException(), isNull);
          final compact = width - 32 < 300;
          final card = tester.getRect(find.byType(AdventEntryCard));
          expect(card.height, compact ? 114 : 120);
          final glass = tester.getRect(find.byType(BackdropFilter));
          expect(glass.size, Size.square(compact ? 82 : 88));
          expect(card.right - glass.right, 16);
          expect(glass.top - card.top, 16);
          // The filter has its own rounded clip and contains no foreground type.
          final clip = find.ancestor(of: find.byType(BackdropFilter), matching: find.byType(ClipRRect));
          expect(clip, findsOneWidget);
          expect(tester.getRect(clip), glass);
          expect(find.descendant(of: find.byType(BackdropFilter), matching: find.byType(Text)), findsNothing);
          expectTextInside(tester, find.text('Открой свой\nдекабрь'),
            Rect.fromLTRB(card.left + 16, card.top + 16, glass.left - (compact ? 9 : 10), card.bottom - 16));
          expectTextInside(tester, find.text(days > 0 ? 'дней до 2027' : 'С Новым годом!'), glass.deflate(4));
          if (scale == 1 && days == 38) {
            final title = tester.renderObject<RenderParagraph>(find.text('Открой свой\nдекабрь'));
            final paintedSize = (compact ? 25 : 28) * title.getTransformTo(null).getMaxScaleOnAxis();
            expect(paintedSize, greaterThan(compact ? 23 : 26));
            debugPrint('ENTRY_FONT: viewport $width dp, actual $paintedSize dp');
          }
          if (days > 0) expectTextInside(tester, find.text('$days'), glass.deflate(4));
          else expect(find.text('0'), findsNothing);
        }
      });
    }
  }

  testWidgets('entry v9: full card remains one accessible navigation button', (tester) async {
    resetView(tester);
    final semantics = tester.ensureSemantics();
    try {
    var opens = 0;
    await mount(tester, 390, onOpen: () => opens++);
    final card = tester.getRect(find.byType(AdventEntryCard));
    final label = find.bySemanticsLabel('Открой свой декабрь. До 2027 года 38 дней.');
    expect(label, findsOneWidget);
    for (final point in [card.center, Offset(card.center.dx, card.top + 2),
      Offset(card.center.dx, card.bottom - 2), Offset(card.left + 2, card.center.dy),
      Offset(card.right - 2, card.center.dy), tester.getCenter(find.byType(BackdropFilter))]) {
      await tester.tapAt(point);
      await tester.pumpAndSettle();
    }
    expect(opens, 6);
    await mount(tester, 390, days: 0);
    expect(find.bySemanticsLabel('Открой свой декабрь. С Новым годом!'), findsOneWidget);
    } finally { semantics.dispose(); }
  });

  testWidgets('entry v9: before/after images with real fonts', (tester) async {
    resetView(tester);
    for (final width in [320.0, 360.0, 390.0, 430.0]) {
      for (final state in ['normal', 'text200', 'festive']) {
        for (final before in [true, false]) {
          // The old implementation is captured at standard scale only; at 200%
          // it overflows. The matching baseline remains labelled scale 100%.
          await mount(tester, width, days: state == 'festive' ? 0 : 38,
            scale: state == 'text200' && !before ? 2 : 1, before: before);
          expect(tester.takeException(), isNull);
          await tester.runAsync(() async {
            final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(const ValueKey('entry-capture')));
            final image = await boundary.toImage(pixelRatio: 2);
            final bytes = await image.toByteData(format: ImageByteFormat.png);
            image.dispose();
            final folder = Directory('build/entry-card-qa');
            await folder.create(recursive: true);
            await File('${folder.path}/${before ? 'before' : 'after'}-$state-${width.toInt()}.png')
              .writeAsBytes(bytes!.buffer.asUint8List());
          });
        }
      }
    }
    await tester.pumpWidget(const SizedBox());
  }, skip: !const bool.fromEnvironment('ADVENT_VISUALS'));
}
