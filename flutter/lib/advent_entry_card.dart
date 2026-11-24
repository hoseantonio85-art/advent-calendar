import 'dart:math' as math;
import 'dart:ui' show ImageFilter;
// Retain compatibility with pre-3.47 hosts until their SDK is known.
// ignore: deprecated_member_use
import 'package:flutter/material.dart';

/// Approved v9 entry card. The host pushes the full Advent page through onOpen;
/// only event/advice details use sheets. Requires registered v9 background WebP.
class AdventEntryCard extends StatelessWidget {
  const AdventEntryCard({super.key, required this.daysUntilNewYear, required this.onOpen});
  final int daysUntilNewYear;
  final VoidCallback onOpen;

  static const _radius = BorderRadius.all(Radius.circular(21));

  static String _dayWord(int n) {
    if (n % 100 >= 11 && n % 100 <= 14) return 'дней';
    switch (n % 10) {
      case 1: return 'день';
      case 2:
      case 3:
      case 4: return 'дня';
      default: return 'дней';
    }
  }

  @override
  Widget build(BuildContext context) {
    final days = math.max(0, daysUntilNewYear);
    return LayoutBuilder(builder: (context, constraints) {
      final compact = constraints.maxWidth < 300;
      return Semantics(
        button: true, enabled: true, excludeSemantics: true, onTap: onOpen,
        label: days == 0 ? 'Открой свой декабрь. С Новым годом!'
            : 'Открой свой декабрь. До 2027 года $days ' + _dayWord(days) + '.',
        child: DecoratedBox(
          decoration: const BoxDecoration(
            borderRadius: _radius,
            boxShadow: [BoxShadow(color: Color(0x4511271D), blurRadius: 23, offset: Offset(0,12))],
          ),
          child: Material(
            color: const Color(0xFF103328), borderRadius: _radius, clipBehavior: Clip.antiAlias,
            child: Ink(
              decoration: const BoxDecoration(
                borderRadius: _radius,
                gradient: LinearGradient(
                  begin: Alignment.centerLeft, end: Alignment.bottomRight,
                  colors: [Color(0xFF193D30), Color(0xFF113428), Color(0xFF0A2A21)],
                ),
                // Approved v9: photograph-based pine needles and warm light from
                // the isolated HTML reference, subdued so typography stays primary.
                image: DecorationImage(
                  image: AssetImage('assets/advent/entry_fir_v9.webp', package: 'advent_calendar'),
                  fit: BoxFit.fill,
                  opacity: .90,
                ),
              ),
              child: InkWell(
                onTap: onOpen,
                customBorder: const RoundedRectangleBorder(borderRadius: _radius),
                child: SizedBox(
                  height: compact ? 114 : 120,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(children: [
                      Expanded(child: FittedBox(
                        fit: BoxFit.scaleDown, alignment: Alignment.centerLeft,
                        child: Text(
                        'Открой свой\nдекабрь',
                        maxLines: 2, softWrap: false,
                        style: TextStyle(
                          fontFamily: 'packages/advent_calendar/Yeseva One', fontFamilyFallback: const ['Georgia'],
                          fontSize: compact ? 25 : 28, height: 1.13, letterSpacing: -1.0,
                          color: const Color(0xFFFFF8E8),
                        ),
                      ))),
                      SizedBox(width: compact ? 9 : 10),
                      _CountdownCalendar(days: days, compact: compact),
                    ]),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}

class _CountdownCalendar extends StatelessWidget {
  const _CountdownCalendar({required this.days, required this.compact});
  final int days;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: compact ? 82 : 88, height: compact ? 82 : 88,
      child: Stack(children: [
        // Clip only the background filter. Foreground type stays sharp and
        // the single 88/82 dp blur never paints outside its rounded bounds.
        Positioned.fill(child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 9, sigmaY: 9),
            // Separate paint layers: a gradient in BoxDecoration replaces
            // its colour fill. Keep the green tint beneath the glass highlight.
            child: ColoredBox(
              color: const Color(0x59102E25),
              child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0x38F5F5DE), width: 1),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [Color(0x18FFFFFF), Color(0x06E0EDCF)],
                ),
              ),
              child: const SizedBox.expand(),
              ),
            ),
          ),
        )),
        const Positioned(top: 9, left: 12, child: _CalendarHole()),
        const Positioned(top: 9, right: 12, child: _CalendarHole()),
        Center(child: SizedBox(
          height: compact ? 60 : 64,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FittedBox(fit: BoxFit.scaleDown,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (days > 0) ...[
            const SizedBox(height: 4),
            Text('$days', maxLines: 1, style: TextStyle(
              fontFamily: 'packages/advent_calendar/Yeseva One', fontFamilyFallback: const ['Georgia'],
              fontSize: compact ? 36 : 39, height: 1,
              color: const Color(0xFFFFE0A3),
            )),
            const SizedBox(height: 6),
            Text(AdventEntryCard._dayWord(days) + ' до 2027',
              maxLines: 1, softWrap: false,
              style: TextStyle(fontFamily: 'packages/advent_calendar/Roboto',
                fontSize: compact ? 9 : 9.5, fontWeight: FontWeight.w600,
                color: const Color(0xFFF1E2C5)),
            ),
          ] else ...[
            const Icon(Icons.auto_awesome_rounded, size: 25, color: Color(0xFFFFE0A3)),
            const SizedBox(height: 6),
            const Text('С Новым годом!', maxLines: 1,
              style: TextStyle(fontFamily:'packages/advent_calendar/Roboto',fontSize:9,
                color:Color(0xFFF1E2C5),fontWeight:FontWeight.w600)),
          ],
        ])),
          ),
        )),
      ]),
    );
  }
}

class _CalendarHole extends StatelessWidget {
  const _CalendarHole();
  @override
  Widget build(BuildContext context) => const DecoratedBox(
    decoration: BoxDecoration(
      color: Color(0xBE092D24), shape: BoxShape.circle,
      boxShadow: [BoxShadow(color: Color(0x66000000),blurRadius:2,offset:Offset(0,1))],
    ),
    child: SizedBox(width: 6,height: 6),
  );
}
