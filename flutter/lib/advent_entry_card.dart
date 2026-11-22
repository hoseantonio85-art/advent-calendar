import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Compact home-screen entrance to the approved Advent 2026 calendar.
///
/// Navigation is delegated to [onOpen]; the HOST should use a full-screen
/// native route (e.g. Navigator.push), never a modal bottom sheet.
/// The detailed event/advice cards inside the calendar can use bottom sheets.
///
/// Add the exact glass Christmas tree file from this repository to the host
/// assets and register 'assets/advent/hero_tree.webp' in pubspec.yaml.
class AdventEntryCard extends StatelessWidget {
  const AdventEntryCard({
    super.key,
    required this.daysUntilNewYear,
    required this.onOpen,
  });

  /// Computed using the campaign's timezone by the host; clamps at zero.
  final int daysUntilNewYear;

  /// Opens the FULL calendar as a normal screen, not a bottom sheet.
  final VoidCallback onOpen;

  // The 3D tree is intentionally absent from the current entry candidate.
  // It can return later as a *background* motif, not a separate object.

  static const _gold = Color(0xFFFFDEA2);
  static const _text = Color(0xFFFFF8E8);
  static const _corner = BorderRadius.all(Radius.circular(21));

  static String _dayWord(int n) {
    if (n % 100 >= 11 && n % 100 <= 14) return 'дней';
    switch (n % 10) {
      case 1:
        return 'день';
      case 2:
      case 3:
      case 4:
        return 'дня';
      default:
        return 'дней';
    }
  }

  @override
  Widget build(BuildContext context) {
    final days = math.max(0, daysUntilNewYear);

    return LayoutBuilder(
      builder: (context, box) {
        final compact = box.maxWidth < 300;
        final height = compact ? 121.0 : 125.0;

        return Semantics(
          label: days > 0
              ? 'Адвент 2026. Открой свой календарь. '
                  'До 2027 года $days ' + _dayWord(days) + '.'
              : 'Адвент 2026. С Новым годом! Открой календарь.',
          button: true,
          enabled: true,
          onTap: onOpen,
          excludeSemantics: true,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              borderRadius: _corner,
              boxShadow: [
                BoxShadow(
                  color: Color(0x4511271D),
                  blurRadius: 23,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: Material(
              color: const Color(0xFF0A3026),
              clipBehavior: Clip.antiAlias,
              borderRadius: _corner,
              child: Ink(
                height: height,
                decoration: BoxDecoration(
                  borderRadius: _corner,
                  border: Border.all(
                    color: const Color(0x50EFF1CD),
                    width: 1,
                  ),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF1C4434),
                      Color(0xFF103328),
                      Color(0xFF08251E),
                    ],
                  ),
                ),
                child: InkWell(
                  onTap: onOpen,
                  customBorder:
                      const RoundedRectangleBorder(borderRadius: _corner),
                  child: SizedBox(
                    height: height,
                    child: Stack(
                      clipBehavior: Clip.hardEdge,
                      children: [
                        // Small golden glint: no persistent animated background.
                        const Positioned(
                          right: 105,
                          top: 14,
                          child: Icon(
                            Icons.auto_awesome_rounded,
                            size: 14,
                            color: Color(0x88FFF4D3),
                          ),
                        ),
                        Positioned(
                          left: compact ? 13 : 16,
                          top: compact ? 16 : 18,
                          right: 12,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: .32),
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: compact ? 9 : 10,
                                  vertical: compact ? 8 : 9,
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.calendar_month_outlined,
                                      size: 17,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'АДВЕНТ · 2026',
                                      style: TextStyle(
                                        fontFamily: 'Roboto',
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.15,
                                        color: Color(0xFFF2F4EF),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: compact ? 13 : 16,
                          top: compact ? 60 : 62,
                          right: compact ? 88 : 92,
                          child: Text(
                            'Открой свой календарь',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            softWrap: false,
                            style: TextStyle(
                              fontFamily: 'Yeseva One',
                              fontFamilyFallback: const ['Georgia'],
                              fontSize: compact ? 17.1 : 19,
                              height: 1.15,
                              letterSpacing: -0.5,
                              color: _text,
                            ),
                          ),
                        ),
                        Positioned(
                          right: compact ? 10 : 13,
                          bottom: compact ? 10 : 12,
                          child: _YearCountdown(days: days),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _YearCountdown extends StatelessWidget {
  const _YearCountdown({required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 84,
      constraints: const BoxConstraints(minHeight: 73),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(17),
        color: const Color(0xCC203E34),
        border: Border.all(color: const Color(0x6EF7E9BB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x56001C14),
            blurRadius: 11,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (days > 0) ...[
            Text(
              '$days',
              maxLines: 1,
              style: const TextStyle(
                fontFamily: 'Yeseva One',
                fontFamilyFallback: ['Georgia'],
                fontSize: 33,
                height: 1,
                color: AdventEntryCard._gold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              AdventEntryCard._dayWord(days) + '\nдо 2027',
              textAlign: TextAlign.center,
              maxLines: 2,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 9,
                height: 1.1,
                fontWeight: FontWeight.w600,
                color: Color(0xFFF1E2C5),
              ),
            ),
          ] else ...[
            const Icon(Icons.auto_awesome_rounded,
                size: 21, color: AdventEntryCard._gold),
            const SizedBox(height: 6),
            const Text(
              'С Новым годом!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AdventEntryCard._gold,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
