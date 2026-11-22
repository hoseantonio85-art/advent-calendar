import 'dart:async';
import 'dart:math' as math;
// Compatibility with hosts using Flutter before the Material package split.
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;
import '../content/content.dart';
import '../domain/calendar.dart';
import '../platform/host.dart';

const _forest = Color(0xff0a2a20), _gold = Color(0xfff3d495);
const _serif = TextStyle(fontFamily: 'packages/advent_calendar/Yeseva One', fontWeight: FontWeight.w400);

/// Full-page route. Host owns persistence, time, system actions and routing.
class AdventCalendarScreen extends StatefulWidget {
  const AdventCalendarScreen({super.key, required this.content, required this.time,
    required this.progress, this.actions, this.savedAdvice, this.onExit});
  final AdventContent content;
  final CampaignTime time;
  final AdventProgress progress;
  final AdventSystemActions? actions;
  final SavedAdviceRepository? savedAdvice;
  final VoidCallback? onExit;
  @override
  State<AdventCalendarScreen> createState() => _CalendarState();
}

class _CalendarState extends State<AdventCalendarScreen> with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  late final AnimationController _motion;
  Timer? _midnight;
  Set<String> _opened = {};
  String? _error;
  bool _opening = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _motion = AnimationController(vsync: this, duration: const Duration(milliseconds: 5500));
    _refresh();
  }
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) { _motion.stop(); } else { _motion.repeat(); }
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }
  Future<void> _refresh() async {
    _midnight?.cancel();
    final now = tz.TZDateTime.from(widget.time.clock.nowUtc(), widget.time.location);
    final next = tz.TZDateTime(widget.time.location, now.year, now.month, now.day + 1);
    _midnight = Timer(next.difference(now), _refresh);
    try {
      final opened = await widget.progress.read();
      if (mounted) setState(() { _opened = opened; _error = null; });
    } catch (_) { if (mounted) setState(() => _error = 'Не удалось загрузить прогресс. Повторить'); }
  }
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _midnight?.cancel(); _motion.dispose(); super.dispose();
  }
  Future<void> _open(AdventDay day) async {
    if (_opening || !widget.content.calendar.isAvailable(day, widget.time.today)) return;
    _opening = true;
    try {
      if (!await widget.progress.open(day.id) || !mounted) return;
      final opened = await widget.progress.read();
      if (!mounted) return;
      setState(() => _opened = opened);
      await showModalBottomSheet<void>(context: context, isScrollControlled: true,
        useSafeArea: true, showDragHandle: true, backgroundColor: const Color(0xfff8f2e8),
        builder: (_) => _DaySheet(day: day, content: widget.content, time: widget.time,
          actions: widget.actions, savedAdvice: widget.savedAdvice));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Не удалось открыть день. Попробуйте ещё раз.')));
    } finally { _opening = false; }
  }
  @override
  Widget build(BuildContext context) => Scaffold(backgroundColor: _forest, body: SafeArea(
    child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 480),
      child: LayoutBuilder(builder: (context, constraints) {
        final width = constraints.maxWidth;
        final rows = <List<AdventDay>>[];
        var row = <AdventDay>[], used = 0;
        for (final day in widget.content.calendar.days) {
          if (used + day.columns > 3) { rows.add(row); row = []; used = 0; }
          row.add(day); used += day.columns;
        }
        if (row.isNotEmpty) rows.add(row);
        final gap = width <= 335 ? 5.0 : width <= 380 ? 6.0 : 8.0;
        final tileHeight = width <= 335 ? 104.0 : width <= 380 ? 111.0 : 124.0;
        return ListView(padding: EdgeInsets.symmetric(horizontal: width <= 380 ? 12 : 16), children: [
          Padding(padding: const EdgeInsets.only(top: 8), child: Row(children: [
            SizedBox(width: 32, height: 32, child: IconButton(padding: EdgeInsets.zero,
              tooltip: 'Назад на главный экран', onPressed: widget.onExit ?? () => Navigator.maybePop(context),
              icon: const Icon(Icons.chevron_left, color: _gold, size: 22))),
            const SizedBox(width: 10), const Expanded(child: Text('ДЕКАБРЬ ЧУДЕС · 2026',
              style: TextStyle(color: _gold, fontSize: 10, letterSpacing: 1, fontWeight: FontWeight.w800))),
          ])),
          _Hero(content: widget.content),
          Semantics(button: true, label: 'Твоя история декабря. Открыто ${_opened.length} из 31',
            child: InkWell(onTap: () => showModalBottomSheet<void>(context: context, useSafeArea: true,
              showDragHandle: true, builder: (_) => SafeArea(child: Padding(padding: const EdgeInsets.all(24),
                child: Text('Твоя история декабря\n\nМероприятия доступны заранее. Советы открываются каждый день в полночь по Москве.\n\nДо Нового года: ${widget.time.daysUntilNewYear} дней.', style: const TextStyle(fontSize: 18))))),
              child: Container(padding: const EdgeInsets.all(16), margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: const Color(0x1fd9eec0), borderRadius: BorderRadius.circular(19), border: Border.all(color: const Color(0x30d9eec0))),
                child: Column(children: [Row(children: [const Icon(Icons.auto_awesome, color: _gold), const SizedBox(width: 10),
                  const Expanded(child: Text('Твоя история декабря', style: TextStyle(color: Color(0xffe3e9d5), fontSize: 12))),
                  Text('${_opened.length} / 31', key: const ValueKey('progress-count'), style: const TextStyle(color: _gold, fontSize: 12))]),
                  const SizedBox(height: 10), LinearProgressIndicator(value: _opened.length / 31, minHeight: 3, color: _gold, backgroundColor: const Color(0x22ffffff))])))),
          if (_error != null) TextButton(onPressed: _refresh, child: Text(_error!, style: const TextStyle(color: _gold))),
          for (final row in rows) Padding(padding: EdgeInsets.only(bottom: gap), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            for (var i = 0; i < row.length; i++) ...[
              if (i > 0) SizedBox(width: gap),
              SizedBox(width: ((width - (width <= 380 ? 24 : 32) - gap * 2) / 3) * row[i].columns + gap * (row[i].columns - 1),
                height: tileHeight * math.max(1, MediaQuery.textScalerOf(context).scale(1)),
                child: _Tile(day: row[i], content: widget.content, date: widget.time.today,
                  available: widget.content.calendar.isAvailable(row[i], widget.time.today),
                  motion: _motion, onTap: () => _open(row[i])))
            ]
          ])),
          const Padding(padding: EdgeInsets.symmetric(vertical: 30), child: Column(children: [
            Text('✳', style: TextStyle(color: _gold, fontSize: 26)), SizedBox(height: 12),
            Text('Праздник в деталях', style: TextStyle(fontFamily: 'packages/advent_calendar/Yeseva One', color: _gold, fontSize: 24)),
            SizedBox(height: 12), Text('Самое волшебное часто прячется в небольших моментах. Открывай свой декабрь каждый день.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xffa3bba9), height: 1.5)),
          ])),
        ]);
      })),
  )));
}

Widget _art(AdventContent content, String key, {double? size}) => Image.asset(
  content.assets[key]!, package: 'advent_calendar', width: size, height: size, fit: BoxFit.contain,
  excludeFromSemantics: true, errorBuilder: (_, __, ___) => SizedBox(width: size, height: size));

class _Hero extends StatelessWidget {
  const _Hero({required this.content});
  final AdventContent content;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 32), child: Stack(clipBehavior: Clip.hardEdge, children: [
    Positioned(right: -142, top: -55, child: ShaderMask(shaderCallback: (rect) => const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
      colors: [Colors.white, Colors.white, Colors.transparent], stops: [0, .63, .93]).createShader(rect), child: _art(content, 'hero_tree', size: 356))),
    Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(colors: [_forest, _forest.withValues(alpha: .75), Colors.transparent], stops: const [0, .43, .79])))),
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text.rich(TextSpan(children: [const TextSpan(text: '31 день\nмаленьких\n'), TextSpan(text: 'чудес', style: const TextStyle(color: _gold))]),
        style: _serif.copyWith(color: const Color(0xfff8f2e8), fontSize: MediaQuery.sizeOf(context).width <= 335 ? 36 : 43, height: .99, letterSpacing: -1.4)),
      const SizedBox(height: 16), const SizedBox(width: 218, child: Text('События, тёплые мысли и немного волшебства — в каждом дне.', style: TextStyle(color: Color(0xffd1dccb), fontSize: 12, height: 1.58))),
    ]),
  ]));
}

List<Color> _colors(AdventDay day) {
  if (day.kind == DayKind.advice) {
    return switch (day.date.day % 4) { 2 => [const Color(0xffe5cab9), const Color(0xfff5dacc)],
      3 => [const Color(0xff1d5b48), const Color(0xff24503e)], 0 => [const Color(0xffb94e4d), const Color(0xff8e2e3b)],
      _ => [const Color(0xffecddc7), const Color(0xfff9e9d1)] };
  }
  return switch(day.theme) {
    'ruby' => [const Color(0xffa33345), const Color(0xff67223a)],
    'purple' => [const Color(0xff544c75), const Color(0xff2d3a65)],
    'sand' => [const Color(0xff915f5a), const Color(0xff6f354a)],
    'ice' => [const Color(0xff35788a), const Color(0xff174a66)],
    'night' => [const Color(0xff294e65), const Color(0xff183b4f)],
    _ => [const Color(0xff466b4b), const Color(0xff22523c)],
  };
}

class _Tile extends StatelessWidget {
  const _Tile({required this.day, required this.content, required this.date,
    required this.available, required this.motion, required this.onTap});
  final AdventDay day; final AdventContent content; final DateTime date;
  final bool available; final Animation<double> motion; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final event = day.event, today = civilDate(day.date) == date, past = civilDate(day.date).isBefore(date);
    final wide = day.columns == 2, compact = MediaQuery.sizeOf(context).width <= 380;
    final dark = event != null || day.date.day % 4 == 0 || day.date.day % 4 == 3;
    return Semantics(key: ValueKey('day-${day.date.day}'), button: true, enabled: available,
      label: '${day.date.day} декабря, ${event != null ? 'мероприятие: ${day.title}' : available ? 'совет дня: ${day.title}' : 'закрыто, совет откроется ${day.date.day} декабря'}',
      excludeSemantics: true, child: Opacity(opacity: past ? .85 : 1, child: Material(color: Colors.transparent,
        borderRadius: BorderRadius.circular(17), clipBehavior: Clip.antiAlias,
        child: InkWell(onTap: available ? onTap : null, child: Stack(children: [
          Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: _colors(day))))),
          if (event != null) ...[
            Positioned(right: day.date.day == 31 ? -35 : wide ? -6 : -9, top: day.date.day == 31 ? -37 : wide ? -9 : 17,
              child: _art(content, day.art, size: day.date.day == 31 ? 199 : wide ? (compact ? 126 : 142) : (compact ? 86 : 96))),
            Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: wide ? Alignment.centerLeft : Alignment.bottomCenter,
              end: wide ? Alignment.centerRight : Alignment.topCenter, colors: const [Color(0x65101d1b), Colors.transparent])))),
            Positioned(left: 12, top: 10, child: Text('${day.date.day}', style: _serif.copyWith(color: const Color(0xfffff8e8), fontSize: compact ? 25 : 28))),
            Positioned(left: 12, right: wide ? 65 : 8, bottom: 12, child: Text(
              (event['cardLines'] as List?)?.join('\n') ?? event['shortTitle'] as String? ?? day.title,
              style: TextStyle(color: const Color(0xfff9f7ee), fontSize: wide ? (compact ? 13 : 15) : (compact ? 10.2 : 12), height: 1.13, fontWeight: FontWeight.w700))),
          ] else ...[
            Positioned(right: -18, top: 10, child: CustomPaint(size: const Size(90,112), painter: _OrnamentPainter(dark ? const Color(0x20ffe2ca) : const Color(0x20774f4b)))),
            Positioned.fill(child: Center(child: Text('${day.date.day}', style: _serif.copyWith(fontSize: compact ? 60 : 70,
              fontFeatures: const [FontFeature.tabularFigures()], color: dark ? const Color(0xfff7e8d6) : const Color(0xff774f4b))))),
          ],
          Positioned.fill(child: IgnorePointer(child: AnimatedBuilder(animation: motion, builder: (_, __) => CustomPaint(painter: _WinterPainter(
            day: day.date.day, phase: motion.value, today: today, snow: event == null, frost: !available))))),
          if (today) const Positioned(top: 8, right: 9, child: Text('✦', style: TextStyle(color: _gold, fontSize: 17))),
        ])),
      )));
  }
}

class _OrnamentPainter extends CustomPainter {
  const _OrnamentPainter(this.color); final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save(); canvas.scale(size.width / 100, size.height / 124);
    final paint = Paint()..color = color;
    canvas.drawOval(const Rect.fromLTWH(9,36,82,84),paint);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(38,26,24,11),const Radius.circular(3)),paint);
    canvas.drawCircle(const Offset(50,17),9,paint..style=PaintingStyle.stroke..strokeWidth=4);
    canvas.restore();
  }
  @override
  bool shouldRepaint(_OrnamentPainter old) => color != old.color;
}

class _WinterPainter extends CustomPainter {
  _WinterPainter({required this.day, required this.phase, required this.today, required this.snow, required this.frost});
  final int day; final double phase; final bool today, snow, frost;
  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    if (frost) canvas.drawRect(bounds, Paint()..shader = const LinearGradient(colors: [Color(0x40ffffff), Color(0x0cffffff)]).createShader(bounds));
    if (snow) {
      for (var i = 0; i < 4; i++) {
        final x = size.width * (14 + (day * 17 + i * 23) % 73) / 100;
        final y = size.height * ((day * 9 + i * 13) / 100 + phase) % size.height;
        canvas.drawCircle(Offset(x, y), i == 1 ? 1.45 : 1, Paint()..color = const Color(0x99ffffff));
      }
    }
    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = today ? 1.35 : 1;
    if (today) { paint.shader = SweepGradient(transform: GradientRotation(phase * 2 * math.pi), colors: const [Color(0x88d7ac64), Color(0xfffff7d8), Color(0xffffd27b), Color(0x88d7ac64)]).createShader(bounds); }
    else { paint.color = const Color(0x30ffffff); }
    canvas.drawRRect(RRect.fromRectAndRadius(bounds.deflate(paint.strokeWidth / 2), const Radius.circular(17)), paint);
  }
  @override
  bool shouldRepaint(_WinterPainter old) => phase != old.phase || today != old.today || frost != old.frost;
}

class _DaySheet extends StatefulWidget {
  const _DaySheet({required this.day, required this.content, required this.time, this.actions, this.savedAdvice});
  final AdventDay day; final AdventContent content; final CampaignTime time;
  final AdventSystemActions? actions; final SavedAdviceRepository? savedAdvice;
  @override
  State<_DaySheet> createState() => _SheetState();
}
class _SheetState extends State<_DaySheet> {
  bool _saved = false, _busy = false;
  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    try { final ids = await widget.savedAdvice?.readSaved(AdventProgress.campaignId);
      if (mounted) setState(() => _saved = ids?.contains(widget.day.id) ?? false);
    } catch (_) { if(mounted) _message('Не удалось загрузить сохранённые советы'); }
  }
  void _message(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  Future<void> _action(Future<SystemActionResult> Function() action) async {
    if (_busy) return; setState(() => _busy = true);
    try { final result = await action(); if(mounted && result == SystemActionResult.unavailable) _message('Действие недоступно на этом устройстве'); }
    catch (_) { if(mounted) _message('Не удалось выполнить действие. Попробуйте ещё раз.'); }
    finally { if(mounted) setState(() => _busy = false); }
  }
  @override
  Widget build(BuildContext context) {
    final day = widget.day, event = day.event;
    return FractionallySizedBox(heightFactor: .9, child: SafeArea(top: false, child: Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(20, 0, 8, 8), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${day.date.day} декабря 2026 · ${event == null ? 'совет дня' : 'событие'}', style: const TextStyle(color: Color(0xff69836c), fontSize: 12)),
          const SizedBox(height: 8), Text(day.title, style: _serif.copyWith(fontSize: 28, height: 1.04, color: const Color(0xff284936))),
        ])), IconButton(onPressed: () => Navigator.pop(context), tooltip: 'Закрыть', icon: const Icon(Icons.close)),
      ])),
      Expanded(child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(20, 12, 20, 24), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (event != null) ...[
          Container(height: 160, decoration: BoxDecoration(gradient: LinearGradient(colors: _colors(day)), borderRadius: BorderRadius.circular(17)), child: _art(widget.content, day.art)),
          const SizedBox(height: 16),
          for (final field in [('Дата', '${day.date.day} декабря 2026'), ('Время', event['time'] as String), ('Место', event['place'] as String)])
            Padding(padding: const EdgeInsets.only(bottom: 12), child: Text('${field.$1}\n${field.$2}', style: const TextStyle(color: Color(0xff284936), height: 1.5))),
          const Text('О событии', style: TextStyle(color: Color(0xff69836c), fontSize: 12)), const SizedBox(height: 10),
          _SourceText(event['desc'] as String), const SizedBox(height: 20),
          FilledButton(onPressed: widget.actions == null || _busy ? null : () => _action(() => widget.actions!.addToCalendar(day, widget.time.location)),
            child: Text(event['cta'] as String? ?? 'Добавить в календарь')),
        ] else ...[
          Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(borderRadius: BorderRadius.circular(17), gradient: const LinearGradient(colors: [Color(0xffe2ead4), Color(0xfff2e9d9)])),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_art(widget.content, day.art, size: 62),
              const SizedBox(height: 12), const Text('✦  МАЛЕНЬКАЯ МУДРОСТЬ', style: TextStyle(fontSize: 10, color: Color(0xff69836c))), const SizedBox(height: 14),
              Text('«${day.advice['text']}»', style: const TextStyle(fontSize: 26, height: 1.2, color: Color(0xff284936))),
              const SizedBox(height: 18), Text('Попробуй сегодня: ${day.advice['action']}', style: const TextStyle(fontSize: 13, height: 1.55, color: Color(0xff69836c))),
            ])), const SizedBox(height: 20),
          FilledButton(onPressed: widget.savedAdvice == null || _busy ? null : () => _action(() async {
            await widget.savedAdvice!.setSaved(AdventProgress.campaignId, day.id, !_saved);
            if(mounted) setState(() => _saved = !_saved); return SystemActionResult.completed;
          }), child: Text(_saved ? '✓ Совет сохранён' : 'Сохранить совет')),
        ],
        TextButton(onPressed: widget.actions == null || _busy ? null : () => _action(() => widget.actions!.share(day)),
          child: Text(event == null ? 'Поделиться советом' : 'Поделиться')),
      ]))),
    ])));
  }
}

/// Only the source's **strong** and *emphasis* syntax; no HTML execution.
class _SourceText extends StatelessWidget {
  const _SourceText(this.text); final String text;
  @override
  Widget build(BuildContext context) {
    final spans = <TextSpan>[]; var offset = 0;
    for (final match in RegExp(r'\*\*(.+?)\*\*|\*(.+?)\*').allMatches(text)) {
      spans.add(TextSpan(text: text.substring(offset, match.start)));
      spans.add(TextSpan(text: match.group(1) ?? match.group(2), style: TextStyle(
        fontWeight: match.group(1) == null ? null : FontWeight.w700, fontStyle: match.group(2) == null ? null : FontStyle.italic)));
      offset = match.end;
    }
    spans.add(TextSpan(text: text.substring(offset)));
    return Text.rich(TextSpan(children: spans), style: const TextStyle(color: Color(0xff284936), fontSize: 14, height: 1.6));
  }
}
