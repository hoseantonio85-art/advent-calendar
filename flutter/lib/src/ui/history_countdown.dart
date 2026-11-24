// Part of calendar_screen.dart: visual countdown in the history sheet only.
part of 'calendar_screen.dart';

class _HistoryCountdown extends StatefulWidget {
  const _HistoryCountdown({required this.time});
  final CampaignTime time;

  @override
  State<_HistoryCountdown> createState() => _HistoryCountdownState();
}

class _HistoryCountdownState extends State<_HistoryCountdown> {
  late final ValueNotifier<int> _remaining;
  Timer? _timer;

  // Same clock, Moscow target and whole-second arithmetic as the history sheet.
  int _seconds() => math.max(0,
    tz.TZDateTime(widget.time.location, 2027).difference(widget.time.clock.nowUtc()).inSeconds);

  @override
  void initState() {
    super.initState();
    _remaining = ValueNotifier(_seconds());
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _remaining.value = _seconds());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _remaining.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ClipRRect(
    key: const ValueKey('history-countdown'),
    borderRadius: BorderRadius.circular(18),
    child: Stack(children: [
      // A retained layer, outside the second-by-second builder. The single
      // existing WebP keeps its proportions and fills the whole background.
      const Positioned.fill(child: RepaintBoundary(
        key: ValueKey('history-countdown-background'), child: _CountdownFirBackground())),
      Padding(
        // Includes the previous outer border's 1 dp padding on every side.
        padding: const EdgeInsets.fromLTRB(13, 17, 13, 13),
        child: ValueListenableBuilder<int>(valueListenable: _remaining, builder: (context, s, _) {
          final values = [s ~/ 86400, s % 86400 ~/ 3600, s % 3600 ~/ 60, s % 60];
          const labels = ['дней', 'часов', 'минут', 'секунд'];
          final large = MediaQuery.textScalerOf(context).scale(1) > 1.4;
          return Column(children: [
            const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Row(mainAxisSize: MainAxisSize.min, children: [
                CustomPaint(size: Size.square(10), painter: _SparkPainter(Color(0xfff6efdb))),
                SizedBox(width: 4),
                Text('До Нового года', style: TextStyle(color: Color(0xfff6efdb), fontSize: 12, fontWeight: FontWeight.w700)),
              ]),
              Text('2027', style: TextStyle(color: _gold, fontSize: 11)),
            ]),
            const SizedBox(height: 12),
            LayoutBuilder(builder: (context, box) {
              final columns = large ? 2 : 4, gap = 7.0;
              return Wrap(spacing: gap, runSpacing: gap, children: [
                for (var i = 0; i < 4; i++) SizedBox(
                  width: (box.maxWidth - gap * (columns - 1)) / columns,
                  child: _HistoryTimeTile(index: i, value: values[i], label: labels[i]),
                ),
              ]);
            }),
            const SizedBox(height: 12),
            Text(s == 0 ? 'С Новым годом! Пусть сбудется всё самое светлое.' : 'До 1 января, 00:00 по московскому времени',
              textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, height: 1.5, color: Color(0xffc2d3bf))),
          ]);
        }),
      ),
      Positioned.fill(child: IgnorePointer(child: DecoratedBox(decoration: BoxDecoration(
        border: Border.all(color: const Color(0x369fc69d)), borderRadius: BorderRadius.circular(18))))),
    ]),
  );
}

class _CountdownFirBackground extends StatelessWidget {
  const _CountdownFirBackground();

  @override
  Widget build(BuildContext context) => const DecoratedBox(
    decoration: BoxDecoration(color: Color(0xff10382c), image: DecorationImage(
      image: AssetImage('assets/advent/entry_fir_v9.webp', package: 'advent_calendar'),
      fit: BoxFit.cover, alignment: Alignment.centerRight, opacity: .9)),
    child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(
      begin: Alignment.topLeft, end: Alignment.bottomRight,
      colors: [Color(0x38102E25), Color(0x0D102E25), Color(0x590A2A20)], stops: [0, .5, 1])),
      child: SizedBox.expand()),
  );
}

class _HistoryTimeTile extends StatelessWidget {
  const _HistoryTimeTile({required this.index, required this.value, required this.label});
  final int index, value;
  final String label;

  @override
  Widget build(BuildContext context) => Stack(key: ValueKey('countdown-tile-$index'), children: [
    const Positioned.fill(child: _HistoryCountdownGlass()),
    RepaintBoundary(child: Padding(padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
      child: Column(children: [
        FittedBox(fit: BoxFit.scaleDown, child: Text(value.toString().padLeft(2, '0'),
          key: ValueKey('countdown-value-$index'), style: _serif.copyWith(fontSize: 36, height: 1, color: const Color(0xffffdfa0)))),
        const SizedBox(height: 3),
        Text(label, style: const TextStyle(fontSize: 10, color: Color(0xffd0ddca))),
      ]))),
  ]);
}

class _HistoryCountdownGlass extends StatelessWidget {
  const _HistoryCountdownGlass();

  @override
  Widget build(BuildContext context) => ClipRRect(borderRadius: BorderRadius.circular(16),
    child: BackdropFilter(filter: ui.ImageFilter.blur(sigmaX: 9, sigmaY: 9),
      // Exact v9 entry glass parameters. The entry card source stays untouched.
      // Paint tint separately: BoxDecoration's gradient replaces its colour.
      child: ColoredBox(color: const Color(0x59102E25), child: DecoratedBox(decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0x38F5F5DE), width: 1),
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0x18FFFFFF), Color(0x06E0EDCF)])), child: const SizedBox.expand())),
    ),
  );
}
