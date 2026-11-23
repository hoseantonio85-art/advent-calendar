part of 'calendar_screen.dart';

AnimationStyle _calendarSheetMotion(BuildContext context) =>
    MediaQuery.disableAnimationsOf(context)
        ? AnimationStyle.noAnimation
        : const AnimationStyle(duration: Duration(milliseconds: 420), reverseDuration: Duration(milliseconds: 300));

/// One notice, owned by the route. Repeated taps replace/reset it, never queue.
class _ClosedDateNotice extends StatelessWidget {
  const _ClosedDateNotice({required this.message, required this.motion});
  final String message;
  final Animation<double> motion;

  @override
  Widget build(BuildContext context) => Positioned(top: 0, left: 0, right: 0,
    child: SafeArea(bottom: false, minimum: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(padding: const EdgeInsets.only(top: 12), child: Align(alignment: Alignment.topCenter,
        child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 418),
          child: IgnorePointer(child: FadeTransition(opacity: motion,
            child: SlideTransition(position: Tween(begin: const Offset(0, -.16), end: Offset.zero).animate(motion),
              child: Semantics(key: const ValueKey('closed-date-notice'), container: true, liveRegion: true,
                child: Material(type: MaterialType.transparency, child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0x80e6ca8b)),
                    gradient: const LinearGradient(colors: [Color(0xff214735), Color(0xff123426)]),
                    boxShadow: const [BoxShadow(color: Color(0x4003130d), blurRadius: 18, offset: Offset(0, 6))]),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const ExcludeSemantics(child: CustomPaint(size: Size.square(15), painter: _SparkPainter(_gold))),
                    const SizedBox(width: 10),
                    Flexible(child: Text(message, textScaler: MediaQuery.textScalerOf(context).clamp(minScaleFactor: 1), style: const TextStyle(fontFamily: 'packages/advent_calendar/Roboto',
                      fontSize: 13, letterSpacing: 0, height: 1.35, fontWeight: FontWeight.w600, color: Color(0xfffff2cf)))),
                  ]))))))))))));
}

class _ProgressPanel extends StatelessWidget {
  const _ProgressPanel({required this.opened, required this.onTap});
  final int opened;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(button: true,
    label: 'Твоя история декабря. Открыто $opened из 31',
    child: Padding(padding: const EdgeInsets.only(bottom: 24),
      child: CustomPaint(painter: const _PanelShadowPainter(),
        child: ClipRRect(borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Material(color: Colors.transparent,
              child: Ink(decoration: BoxDecoration(borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0x2cd2e7c2)),
                gradient: const LinearGradient(begin: Alignment(-1, -.47), end: Alignment(1, .47),
                  colors: [Color(0x24d9eec0), Color(0x10c2d9b0)])),
                child: InkWell(onTap: onTap, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
                  child: Row(children: [
                    Container(width: 36, height: 36,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0x2bb3df9d)),
                        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                          colors: [Color(0x28d8f3bf), Color(0x09accb6b)])),
                      child: const CustomPaint(painter: _MedalPainter())),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Expanded(child: Text('Твоя история декабря', style: TextStyle(color: Color(0xfff4f5e8),
                          fontSize: 11, letterSpacing: 0, fontWeight: FontWeight.w700))),
                        const SizedBox(width: 8),
                        Text('$opened / 31', key: const ValueKey('progress-count'),
                          style: const TextStyle(color: Color(0xffcce9b9), fontSize: 11, fontWeight: FontWeight.w700)),
                      ]),
                      const SizedBox(height: 8),
                      Semantics(value: '$opened из 31', child: ClipRRect(borderRadius: BorderRadius.circular(20),
                        child: SizedBox(height: 4, child: LayoutBuilder(builder: (context, box) => Stack(children: [
                          const Positioned.fill(child: ColoredBox(color: Color(0x1cd3e2bd))),
                          Align(alignment: Alignment.centerLeft, child: Container(
                            key: const ValueKey('progress-fill'), width: box.maxWidth * (opened / 31).clamp(0, 1),
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(20),
                              gradient: const LinearGradient(colors: [Color(0xffd0e99b), Color(0xfff5ce92)])))),
                        ]))))),
                    ])),
                  ]))))))))));
}

/// CSS radial lights approximated with analytic gradients: no per-tile blur layer.
class _EventLightPainter extends CustomPainter {
  const _EventLightPainter(this.day);
  final AdventDay day;
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final (center, color, radius) = switch (day.theme) {
      'ruby' => (const Alignment(.6, -.72), const Color(0x1bff9e79), .98),
      'green' => (const Alignment(.64, -.28), const Color(0x2669ffaf), 1.1),
      'purple' => (const Alignment(.7, -.5), const Color(0x29d3baff), 1.06),
      'sand' => (const Alignment(.68, -.5), const Color(0x47ffd7aa), 1.06),
      'ice' => (const Alignment(.6, -.5), const Color(0x2aa8faff), 1.06),
      'night' => (const Alignment(.7, -.1), Colors.transparent, 1.16),
      _ => (const Alignment(.56, -.4), const Color(0x23fce7ad), 1.0),
    };
    canvas.drawRect(rect, Paint()..shader = RadialGradient(center: center, radius: radius,
      colors: [color, color.withValues(alpha: 0)]).createShader(rect));
    final wide = day.columns == 2;
    final x = size.width - (wide ? 100 : 54), y = wide ? 97.5 : 100.0;
    final glow = day.date.day == 9 ? const Color(0xffffb47b) : const Color(0xfffff6dc);
    canvas.save();
    canvas.translate(x, y); canvas.scale(wide ? 100 : 80, wide ? 90 : 80);
    canvas.drawCircle(Offset.zero, 1, Paint()..shader = RadialGradient(
      colors: [glow.withValues(alpha: day.date.day == 9 ? .3 : .16), glow.withValues(alpha: .07), glow.withValues(alpha: 0)],
      stops: const [0, .45, 1]).createShader(const Rect.fromLTWH(-1, -1, 2, 2)));
    canvas.restore();
  }
  @override
  bool shouldRepaint(_EventLightPainter old) => day.id != old.day.id;
}

// CSS outer shadows do not tint their own translucent background. Clip the
// interior before painting, so BackdropFilter samples the tree, not its own shadow.
class _PanelShadowPainter extends CustomPainter {
  const _PanelShadowPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final clip = Path()..fillType = PathFillType.evenOdd
      ..addRect(rect.inflate(80))..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(16)));
    canvas.save(); canvas.clipPath(clip);
    canvas.drawRRect(RRect.fromRectAndRadius(rect.shift(const Offset(0,12)), const Radius.circular(16)),
      Paint()..color=const Color(0x3d06130f)..maskFilter=const MaskFilter.blur(BlurStyle.normal,17.5));
    canvas.restore();
  }
  @override
  bool shouldRepaint(_PanelShadowPainter old) => false;
}
