import 'package:flutter/material.dart';

/// First UI candidate for the host application's start screen.
/// The host provides the data, campaign timezone, and destination route.
/// This widget is not the full calendar and needs no third-party packages.
class AdventEntryCard extends StatelessWidget {
  const AdventEntryCard({
    super.key,
    required this.openedDays,
    required this.daysUntilNewYear,
    required this.onOpen,
    this.totalDays = 31,
  });

  final int openedDays;
  final int daysUntilNewYear;
  final int totalDays;
  final VoidCallback onOpen;

  static const _gold = Color(0xFFF0D29C);
  static const _muted = Color(0xFFB9CBB9);

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
    final total = totalDays > 0 ? totalDays : 31;
    final opened = openedDays.clamp(0, total);
    final days = daysUntilNewYear < 0 ? 0 : daysUntilNewYear;
    final progress = opened / total;
    final yearLabel = days == 0
        ? 'Новый год наступил'
        : 'До Нового года осталось $days ' + _dayWord(days);
    const radius = BorderRadius.all(Radius.circular(20));

    return LayoutBuilder(builder: (context, constraints) {
      final narrow = constraints.maxWidth < 355;
      return DecoratedBox(
        decoration: const BoxDecoration(
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: Color(0x48000E0A),
              blurRadius: 22,
              offset: Offset(0, 9),
            ),
          ],
        ),
        child: Semantics(
          button: true,
          enabled: true,
          excludeSemantics: true,
          label: 'Открой свой декабрь. Открыто $opened из $total. $yearLabel.',
          onTap: onOpen,
          child: Material(
            color: const Color(0xFF071D19),
            borderRadius: radius,
            clipBehavior: Clip.antiAlias,
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: radius,
                border: Border.all(color: const Color(0x3FD6E5BE)),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF235441),
                    Color(0xFF0A2E24),
                    Color(0xFF071D19),
                  ],
                  stops: [0, 0.55, 1],
                ),
              ),
              child: InkWell(
                onTap: onOpen,
                customBorder:
                    const RoundedRectangleBorder(borderRadius: radius),
                child: Stack(
                  children: [
                    const Positioned(
                      top: -15,
                      right: 58,
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        size: 73,
                        color: Color(0x0FFFF1C2),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: narrow ? 14 : 17,
                        vertical: 17,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const _EntryMedallion(),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      'АДВЕНТ · 2026',
                                      style: TextStyle(
                                        fontFamily: 'Roboto',
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.3,
                                        color: _muted,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Открой свой декабрь',
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontFamily: 'Yeseva One',
                                        fontFamilyFallback: const ['Georgia'],
                                        fontSize: narrow ? 20 : 23,
                                        letterSpacing: -0.5,
                                        height: 1.08,
                                        color: const Color(0xFFF9F0DA),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              _NewYearBadge(days: days),
                            ],
                          ),
                          const SizedBox(height: 17),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Открыто $opened из $total',
                                  style: const TextStyle(
                                    fontFamily: 'Roboto',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFE2EBDD),
                                  ),
                                ),
                              ),
                              const Text(
                                'Открыть',
                                style: TextStyle(
                                  fontFamily: 'Roboto',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: _gold,
                                ),
                              ),
                              const SizedBox(width: 3),
                              const Icon(
                                Icons.chevron_right_rounded,
                                size: 18,
                                color: _gold,
                              ),
                            ],
                          ),
                          const SizedBox(height: 9),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: LayoutBuilder(
                              builder: (context, bar) {
                                return SizedBox(
                                  height: 4,
                                  child: Stack(
                                    children: [
                                      const ColoredBox(
                                        color: Color(0x33E1F2D9),
                                        child: SizedBox.expand(),
                                      ),
                                      SizedBox(
                                        width: bar.maxWidth * progress,
                                        height: 4,
                                        child: const DecoratedBox(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Color(0xFFD2E8AE),
                                                _gold,
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}

class _EntryMedallion extends StatelessWidget {
  const _EntryMedallion();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x38D0E6AE)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x3AD6EEBE), Color(0x0BB8D08D)],
        ),
      ),
      child: const Icon(
        Icons.auto_awesome_rounded,
        size: 22,
        color: Color(0xFFE9D9A3),
      ),
    );
  }
}

class _NewYearBadge extends StatelessWidget {
  const _NewYearBadge({required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 79,
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(13),
        color: const Color(0x13FFE6B4),
        border: Border.all(color: const Color(0x41EDD29A)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (days > 0) ...[
            Text(
              '$days',
              maxLines: 1,
              style: const TextStyle(
                color: AdventEntryCard._gold,
                fontFamily: 'Yeseva One',
                fontFamilyFallback: ['Georgia'],
                fontSize: 30,
                height: 1,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              AdventEntryCard._dayWord(days) + ' до 2027',
              maxLines: 2,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Roboto',
                color: Color(0xFFE6D9BA),
                fontSize: 9,
                fontWeight: FontWeight.w600,
                height: 1.15,
              ),
            ),
          ] else ...[
            const Icon(
              Icons.auto_awesome_rounded,
              color: AdventEntryCard._gold,
              size: 23,
            ),
            const SizedBox(height: 5),
            const Text(
              'С Новым годом!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AdventEntryCard._gold,
                fontSize: 10,
                height: 1.25,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
