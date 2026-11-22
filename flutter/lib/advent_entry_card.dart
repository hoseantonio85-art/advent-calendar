import 'dart:math' as math;
import 'package:flutter/material.dart';

/// The host must push the full Advent page with onOpen; day details use sheets.
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
        label: days == 0 ? 'Открой календарь. С Новым годом!'
            : 'Открой календарь. До 2027 года $days ' + _dayWord(days) + '.',
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
              ),
              child: InkWell(
                onTap: onOpen,
                customBorder: const RoundedRectangleBorder(borderRadius: _radius),
                child: SizedBox(
                  height: compact ? 121 : 126,
                  child: Padding(
                    padding: EdgeInsets.all(compact ? 14 : 16),
                    child: Row(children: [
                      Expanded(child: Text(
                        'Открой\nкалендарь',
                        maxLines: 2,
                        style: TextStyle(
                          fontFamily: 'Yeseva One', fontFamilyFallback: const ['Georgia'],
                          fontSize: compact ? 27 : 30, height: 1.06, letterSpacing: -0.5,
                          color: const Color(0xFFFFF8E8),
                        ),
                      )),
                      SizedBox(width: compact ? 12 : 14),
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
      width: compact ? 98 : 104, height: compact ? 83 : 86,
      child: Stack(children: [
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Color(0x17FFFFFF), Color(0x0DE0EDCF)],
            ),
          ),
          child: const SizedBox.expand(),
        ),
        const Positioned(top: 9, left: 12, child: _CalendarHole()),
        const Positioned(top: 9, right: 12, child: _CalendarHole()),
        Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (days > 0) ...[
            const SizedBox(height: 4),
            Text('$days', maxLines: 1, style: TextStyle(
              fontFamily: 'Yeseva One', fontFamilyFallback: const ['Georgia'],
              fontSize: compact ? 36 : 39, height: 1,
              color: const Color(0xFFFFE0A3),
            )),
            const SizedBox(height: 6),
            Text(AdventEntryCard._dayWord(days) + ' до 2027',
              maxLines: 1, softWrap: false, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontFamily: 'Roboto',
                fontSize: compact ? 9 : 9.5, fontWeight: FontWeight.w600,
                color: const Color(0xFFF1E2C5)),
            ),
          ] else ...[
            const Icon(Icons.auto_awesome_rounded, size: 25, color: Color(0xFFFFE0A3)),
            const SizedBox(height: 6),
            const Text('С Новым годом!', maxLines: 1,
              style: TextStyle(fontFamily:'Roboto',fontSize:9,
                color:Color(0xFFF1E2C5),fontWeight:FontWeight.w600)),
          ],
        ])),
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
