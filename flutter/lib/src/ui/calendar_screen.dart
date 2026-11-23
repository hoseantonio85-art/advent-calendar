import 'dart:async';
import 'dart:ui' as ui;
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

class _CalendarState extends State<AdventCalendarScreen> with WidgetsBindingObserver, TickerProviderStateMixin {
  late final AnimationController _motion;
  late final AnimationController _heroMotion;
  Timer? _midnight;
  Set<String> _opened = {}, _savedIds = {};
  String? _error;
  bool _opening = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _motion = AnimationController(vsync: this, duration: const Duration(milliseconds: 5500));
    _heroMotion = AnimationController(vsync:this,duration:const Duration(seconds:9));
    _refresh();
  }
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) { _motion.stop(); _heroMotion.stop(); } else { _motion.repeat(); _heroMotion.repeat(); }
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
      _savedIds=await widget.savedAdvice?.readSaved(AdventProgress.campaignId)??{};
      if (mounted) setState(() { _opened = opened; _error = null; });
    } catch (_) { if (mounted) setState(() => _error = 'Не удалось загрузить прогресс. Повторить'); }
  }
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _midnight?.cancel(); _motion.dispose(); _heroMotion.dispose(); super.dispose();
  }
  Future<void> _open(AdventDay day) async {
    if(day.revealOnDate&&!widget.content.calendar.isAvailable(day,widget.time.today)){ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Сюрприз откроется ${day.date.day} декабря ✦')));return;}
    if (_opening || !widget.content.calendar.isAvailable(day, widget.time.today)) return;
    _opening = true;
    try {
      if (!await widget.progress.open(day.id) || !mounted) return;
      final celebrate=day.revealOnDate?(await widget.progress.surprises?.claimSurprise(AdventProgress.campaignId,day.id)??false):false;
      final opened = await widget.progress.read();
      if (!mounted) return;
      setState(() => _opened = opened);
      await showModalBottomSheet<void>(context: context, isScrollControlled: true,
        useSafeArea: true, showDragHandle: false, barrierColor:const Color(0xc202100c),shape:const RoundedRectangleBorder(borderRadius:BorderRadius.vertical(top:Radius.circular(27))),backgroundColor: const Color(0xfffaf2e6),
        builder: (_) => _DaySheet(day: day, content: widget.content, time: widget.time,
          actions: widget.actions, savedAdvice: widget.savedAdvice,celebrate:celebrate,onSaved:(){_refresh();}));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Не удалось открыть день. Попробуйте ещё раз.')));
    } finally { _opening = false; }
  }
  @override
  Widget build(BuildContext context) => _featureTheme(context,Scaffold(backgroundColor: _forest, body: SafeArea(
    child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 450),
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
        return SingleChildScrollView(key:const ValueKey('calendar-scroll'),child:CustomPaint(painter:const _BackdropPainter(),child:Padding(padding: EdgeInsets.fromLTRB(width<=380?12:16,0,width<=380?12:16,29), child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children: [
          Padding(padding: const EdgeInsets.only(top: 16), child: Row(children: [
            SizedBox(width: 32, height: 32, child: IconButton(padding: EdgeInsets.zero,
              tooltip: 'Назад на главный экран', onPressed: widget.onExit ?? () => Navigator.maybePop(context),
              style:IconButton.styleFrom(backgroundColor:const Color(0x18edf4d9),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(10),side:const BorderSide(color:Color(0x2be6edd4)))), icon: const Icon(Icons.chevron_left, color: _gold, size: 18))),
            const SizedBox(width: 10), const Expanded(child: Text('ДЕКАБРЬ ЧУДЕС · 2026',
              style: TextStyle(color: _gold, fontSize: 10, letterSpacing: 1, fontWeight: FontWeight.w800))),
          ])),
          _Hero(content: widget.content, motion:_heroMotion),
          Semantics(button: true, label: 'Твоя история декабря. Открыто ${_opened.length} из 31',
            child: InkWell(onTap:()=>showModalBottomSheet<void>(context:context,isScrollControlled:true,useSafeArea:true,showDragHandle:false,barrierColor:const Color(0xc202100c),shape:const RoundedRectangleBorder(borderRadius:BorderRadius.vertical(top:Radius.circular(27))),backgroundColor:const Color(0xfffaf2e6),
              builder:(_)=>_HistorySheet(opened:_opened.length,content:widget.content,time:widget.time,saved:_savedIds)),
              child: Container(padding: const EdgeInsets.symmetric(horizontal:13,vertical:12), margin: const EdgeInsets.only(bottom:24),
                decoration: BoxDecoration(color: const Color(0x1fd9eec0), borderRadius: BorderRadius.circular(19), border: Border.all(color: const Color(0x30d9eec0))),
                child: Row(children:[Container(width:36,height:36,decoration:BoxDecoration(color:const Color(0x16d9eec0),borderRadius:BorderRadius.circular(12),border:Border.all(color:const Color(0x22d9eec0))),
                  child:const CustomPaint(painter:_MedalPainter())),const SizedBox(width:12),
                  Expanded(child:Column(children:[Row(children:[
                    const Expanded(child:Text('Твоя история декабря',style:TextStyle(color:Color(0xffe3e9d5),fontSize:11,fontWeight:FontWeight.w700))),
                    Text('${_opened.length} / 31',key:const ValueKey('progress-count'),style:const TextStyle(color:_gold,fontSize:10,fontWeight:FontWeight.w700))]),
                    const SizedBox(height:8),LinearProgressIndicator(value:_opened.length/31,minHeight:3,color:_gold,backgroundColor:const Color(0x22ffffff)),
                  ])),
                ])))),
          if (_error != null) TextButton(onPressed: _refresh, child: Text(_error!, style: const TextStyle(color: _gold))),
          for (final row in rows) Padding(padding: EdgeInsets.only(bottom: row == rows.last ? 0 : gap), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            for (var i = 0; i < row.length; i++) ...[
              if (i > 0) SizedBox(width: gap),
              SizedBox(width: ((width - (width <= 380 ? 24 : 32) - gap * 2) / 3) * row[i].columns + gap * (row[i].columns - 1),
                height: tileHeight * math.max(1, MediaQuery.textScalerOf(context).scale(1)),
                child: _Tile(day: row[i], content: widget.content, date: widget.time.today,
                  available: widget.content.calendar.isAvailable(row[i], widget.time.today),
                  motion: _motion, saved:_savedIds.contains(row[i].id), onTap: () => _open(row[i])))
            ]
          ])),
          const _MonthFooter(),
        ]))));
      })),
  ))));
}

Widget _art(AdventContent content, String key, {double? size}) => Image.asset(
  content.assets[key]!, package: 'advent_calendar', width: size, height: size, fit: BoxFit.contain,
  excludeFromSemantics: true, errorBuilder: (_, __, ___) => SizedBox(width: size, height: size));

class _Hero extends StatelessWidget {
  const _Hero({required this.content,required this.motion});
  final Animation<double> motion;
  final AdventContent content;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.fromLTRB(5,39,0,29), child: Stack(clipBehavior: Clip.none, children: [
    Positioned(right: MediaQuery.sizeOf(context).width<=335?-157:MediaQuery.sizeOf(context).width<=380?-150:-158, top:MediaQuery.sizeOf(context).width<=335?-69:MediaQuery.sizeOf(context).width<=380?-76:-82, child: ShaderMask(shaderCallback: (rect) => const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
      colors: [Colors.white, Colors.white, Colors.transparent], stops: [0, .63, .93]).createShader(rect), child: AnimatedBuilder(animation:motion,child:_art(content,'hero_tree',size:MediaQuery.sizeOf(context).width<=335?310:MediaQuery.sizeOf(context).width<=380?325:356),builder:(_,child)=>Transform.rotate(angle:-8*math.pi/180,child:Transform.scale(scale:1+.018*math.sin(motion.value*2*math.pi),child:child))))),
    Positioned.fill(child:ShaderMask(blendMode:BlendMode.dstIn,shaderCallback:(rect)=>const LinearGradient(begin:Alignment.topCenter,end:Alignment.bottomCenter,colors:[Colors.transparent,Colors.white,Colors.white,Colors.transparent],stops:[0,.16,.61,1]).createShader(rect),child:DecoratedBox(decoration:BoxDecoration(gradient:LinearGradient(colors:[_forest,_forest.withValues(alpha:.75),Colors.transparent],stops:const [0,.43,.79]))))),
    const Positioned(right:26,top:1,child:CustomPaint(size:Size.square(17),painter:_SparkPainter(Color(0xb3f1dbaf)))),
    const Positioned(right:7,top:188,child:CustomPaint(size:Size.square(12),painter:_SparkPainter(Color(0xb3f1dbaf)))),
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text.rich(TextSpan(children: [const TextSpan(text: '31 день\nмаленьких\n'), TextSpan(text: 'чудес', style: const TextStyle(color: _gold))]),
        style: _serif.copyWith(color: const Color(0xfff8f2e8), fontSize: MediaQuery.sizeOf(context).width <= 335 ? 36 : MediaQuery.sizeOf(context).width <= 380 ? 39 : 43, height: .99, letterSpacing: -1.4)),
      const SizedBox(height: 16), SizedBox(width: MediaQuery.sizeOf(context).width<=335?178:MediaQuery.sizeOf(context).width<=380?195:218, child: Text('События, тёплые мысли и немного волшебства — в каждом дне.', style: TextStyle(color:const Color(0xffd1dccb),fontSize:MediaQuery.sizeOf(context).width<=380?11:12,height:1.58))),
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

ColorFilter _cardFilter(double saturation, double brightness) {
  final r = .213 * (1 - saturation), g = .715 * (1 - saturation), b = .072 * (1 - saturation);
  return ColorFilter.matrix([
    (r+saturation)*brightness,g*brightness,b*brightness,0,0,
    r*brightness,(g+saturation)*brightness,b*brightness,0,0,
    r*brightness,g*brightness,(b+saturation)*brightness,0,0,
    0,0,0,1,0,
  ]);
}

class _Tile extends StatelessWidget {
  const _Tile({required this.day,required this.content,required this.date,
    required this.available,required this.motion,required this.onTap,this.saved=false});
  final AdventDay day;
  final AdventContent content;
  final DateTime date;
  final bool available,saved;
  final Animation<double> motion;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final event=day.event, n=day.date.day, width=MediaQuery.sizeOf(context).width;
    final small=width<=335, compact=width<=380, wide=day.columns==2;
    final today=civilDate(day.date)==date, past=civilDate(day.date).isBefore(date);
    final light=event==null && (n%4==1 || n%4==2), locked=!available;
    final radius=compact?15.0:17.0;
    var artSize=wide?(compact?126.0:142.0):(compact?86.0:96.0);
    var artRight=wide?(compact?-6.0:-4.0):(compact?-8.0:-9.0);
    var artTop=wide?(compact?-5.0:-9.0):(compact?15.0:17.0);
    var artAngle=wide?-4.0:-5.0;
    if(small) artSize=wide?118:80;
    if(n==2) artTop=compact?6:7;
    if(n==9){artSize=small?94:compact?101:111;artTop=small?3:compact?2:3;artRight=small?-21:compact?-22:-23;}
    if(n==25){artSize=compact?143:154;artTop=compact?-12:-14;artRight=compact?-20:-23;}
    if(n==31){artSize=(small?185:compact?199:218)*1.06;artTop=small?-4:compact?-6:-11;artRight=small?-38:compact?-35:-33;artAngle=-7;}
    var titleSize=wide?(small?13.0:compact?14.0:15.5):(small?10.2:compact?11.0:12.0);
    var titleWidth=wide?(small?113.0:compact?125.0:135.0):double.infinity;
    if(n==1){titleWidth=165;if(small)titleSize=12.4;}
    if(n==8){titleWidth=174;titleSize=small?11.6:compact?12.7:14;}
    if(n==14){titleWidth=160;if(compact)titleSize=small?12.4:13.5;}
    if(n==9)titleSize=12;
    if(n==31)titleWidth=127;
    final numeral=compact?(width*.15).clamp(43.0,66.0).toDouble():(width*.17).clamp(48.0,75.0).toDouble();
    final pad=wide?(compact?12.0:15.0):(compact?10.0:12.0);
    final opacity=past? .85:locked?(light? .82:.88):1.0;
    final saturation=past? .70:locked?(light? .87:.90):1.0;
    final brightness=past? .93:locked&&light? .96:1.0;
    if(day.revealOnDate&&!available)return KeyedSubtree(key:ValueKey('day-$n'),child:_SurpriseTile(day:day,onTap:onTap));
    return Semantics(key:ValueKey('day-$n'),button:true,enabled:available,excludeSemantics:true,
      label:'$n декабря, ${event!=null?'мероприятие: ${day.title}':available?'совет дня: ${day.title}${saved?', совет сохранён':''}':'закрыто, совет откроется $n декабря'}',
      child:RepaintBoundary(child:Opacity(opacity:opacity,child:ColorFiltered(colorFilter:_cardFilter(saturation,brightness),
        child:Material(color:Colors.transparent,borderRadius:BorderRadius.circular(radius),clipBehavior:Clip.antiAlias,
          child:InkWell(onTap:available?onTap:null,child:Stack(children:[
            Positioned.fill(child:DecoratedBox(decoration:BoxDecoration(gradient:LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,colors:_colors(day))))),
            if(event!=null)...[
              Positioned(right:artRight,top:artTop,child:Transform.rotate(angle:artAngle*math.pi/180,child:_art(content,day.art,size:artSize))),
              Positioned.fill(child:DecoratedBox(decoration:BoxDecoration(gradient:LinearGradient(begin:wide?Alignment.centerLeft:Alignment.bottomCenter,end:wide?Alignment.centerRight:Alignment.topCenter,
                colors:wide?const [Color(0x4d101d1b),Colors.transparent]:const [Color(0x85111b1c),Colors.transparent],stops:wide?const [0,.75]:const [0,.65])))),
            ]else...[
              Positioned(right:compact?-23:-18,top:10,child:Transform.rotate(angle:15*math.pi/180,alignment:const Alignment(.04,-.42),
                child:CustomPaint(size:Size(compact?92:100,compact?116:126),painter:_OrnamentPainter(
                  n%4==1?const Color(0x24b77f69):n%4==2?const Color(0x1fb9807a):n%4==3?const Color(0x21c4ebd3):const Color(0x1fffe2ca))))),
            ],
            Positioned.fill(child:IgnorePointer(child:CustomPaint(painter:_CardTexturePainter(day:n,advice:event==null,locked:locked,light:light)))),
            if(event==null)...[
              Positioned(left:compact?9:11,top:compact?8:10,child:CustomPaint(size:Size.square(compact?14:15),painter:_SnowflakePainter(light?const Color(0xb8957566):const Color(0xc7e0eedf)))),
              Positioned.fill(child:Center(child:Text('$n',style:_serif.copyWith(fontSize:numeral,height:1,color:light?const Color(0xff774f4b):const Color(0xfff7e8d6),fontFeatures:const [FontFeature.tabularFigures()])))),
            ]else...[
              Positioned(left:pad,top:compact?10:10,child:Text('$n',style:_serif.copyWith(color:const Color(0xfffff8e8),height:1,fontSize:small?23:compact?25:28))),
              Positioned(left:pad,right:pad,bottom:wide?(compact?12:13):pad,child:Align(alignment:Alignment.bottomLeft,
                child:ConstrainedBox(constraints:BoxConstraints(maxWidth:titleWidth),child:Text((event['cardLines'] as List?)?.join('\n')??event['shortTitle'] as String? ??day.title,
                  style:TextStyle(color:const Color(0xfff9f7ee),fontSize:titleSize,height:1.13,letterSpacing:-.025*titleSize,fontWeight:FontWeight.w700,
                    shadows:const [Shadow(color:Color(0x99250c0b),offset:Offset(0,1),blurRadius:10)]))))),
            ],
            Positioned.fill(child:IgnorePointer(child:AnimatedBuilder(animation:motion,builder:(_,__)=>CustomPaint(painter:_WinterPainter(day:n,phase:motion.value,today:today,snow:event==null,locked:locked,radius:radius))))),
            if(event==null&&available&&saved)Positioned(right:11,top:today?35:10,child:const _SavedHeart()),
            if(today)const Positioned(top:9,right:10,child:CustomPaint(size:Size.square(17),painter:_SparkPainter(_gold))),
          ])),
        )))));
  }
}

class _OrnamentPainter extends CustomPainter {
  const _OrnamentPainter(this.color);final Color color;
  @override
  void paint(Canvas canvas,Size size){
    canvas.save();canvas.scale(size.width/100,size.height/124);
    final p=Paint()..color=color;
    final shape=Path()..moveTo(50,36)..cubicTo(26.2,36,9,54.1,9,78.4)..cubicTo(9,102.7,26.9,120,50,120)..cubicTo(73.1,120,91,102.7,91,78.4)..cubicTo(91,54.1,73.8,36,50,36)..close();
    canvas.drawPath(shape,p);canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(38,26,24,11),const Radius.circular(3)),p);
    canvas.drawCircle(const Offset(50,17),9,p..style=PaintingStyle.stroke..strokeWidth=4);canvas.restore();
  }
  @override
  bool shouldRepaint(_OrnamentPainter old)=>color!=old.color;
}

class _SnowflakePainter extends CustomPainter {
  const _SnowflakePainter(this.color);final Color color;
  @override
  void paint(Canvas canvas,Size size){
    canvas.save();canvas.scale(size.width/24,size.height/24);
    final p=Paint()..color=color..style=PaintingStyle.stroke..strokeWidth=1.45..strokeCap=StrokeCap.round;
    final shape=Path()..moveTo(12,2.75)..lineTo(12,21.25)..moveTo(2.75,12)..lineTo(21.25,12)..moveTo(5.45,5.45)..lineTo(18.55,18.55)..moveTo(18.55,5.45)..lineTo(5.45,18.55);
    for(var i=0;i<4;i++){
      canvas.save();canvas.translate(12,12);canvas.rotate(i*math.pi/2);canvas.translate(-12,-12);
      canvas.drawPath(Path()..moveTo(9.4,5.3)..lineTo(12,7.8)..lineTo(14.6,5.3),p);canvas.restore();
    }
    canvas.drawPath(shape,p);canvas.restore();
  }
  @override
  bool shouldRepaint(_SnowflakePainter old)=>color!=old.color;
}

class _CardTexturePainter extends CustomPainter {
  const _CardTexturePainter({required this.day,required this.advice,this.locked=false,this.light=false,this.sheet=false});
  final int day;final bool advice,locked,light,sheet;
  double _edge(double t){
    if(t<.17)return 1-t/.17*.3;
    if(t<.42)return .7*(.42-t)/.25;
    if(t<.63)return 0;
    return ((t-.63)/.32*.6).clamp(0.0,.6).toDouble();
  }
  @override
  void paint(Canvas canvas,Size size){
    final rect=Offset.zero&size;
    if(locked){
      canvas.drawRect(rect,Paint()..shader=RadialGradient(center:const Alignment(-1.14,-1.2),radius:3,colors:[light?const Color(0x78f1ffff):const Color(0x91f1ffff),const Color(0x23e3faff),Colors.transparent],stops:const [0,.39,.64]).createShader(rect));
      canvas.drawRect(rect,Paint()..shader=RadialGradient(center:const Alignment(1.16,1.12),radius:3,colors:[light?const Color(0x50e8fbff):const Color(0x6ce8fbff),Colors.transparent],stops:const [0,.54]).createShader(rect));
      canvas.drawRect(rect,Paint()..shader=LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,colors:[light?const Color(0x23e9faff):const Color(0x2fe9faff),Colors.transparent,const Color(0x18d6f2ff)],stops:const [0,.47,1]).createShader(rect));
      for(var grid=0;grid<2;grid++){
        final dx=grid==0?15.0:21.0,dy=grid==0?19.0:23.0;
        for(var x=grid==0?7.5:16.5;x<size.width;x+=dx){for(var y=grid==0?9.5:20.5;y<size.height;y+=dy){
          final weight=_edge(.58*x/size.width+.42*y/size.height);
          canvas.drawCircle(Offset(x,y),grid==0? .65:.75,Paint()..color=(grid==0?Colors.white:const Color(0xffd6f4ff)).withValues(alpha:weight*.47));
        }}
      }
      canvas.save();canvas.clipRect(rect);
      for(var y=-size.width;y<size.height+size.width;y+=25){
        for(var x=0.0;x<size.width;x+=8){final yy=y-x*.47;final weight=_edge(.58*x/size.width+.42*yy/size.height);
          canvas.drawLine(Offset(x,yy),Offset(x+8,yy-3.76),Paint()..strokeWidth=.6..color=const Color(0xffeefeff).withValues(alpha:.12*weight));}
      }canvas.restore();
      canvas.drawRRect(RRect.fromRectAndRadius(rect.deflate(4),const Radius.circular(15)),Paint()..style=PaintingStyle.stroke..strokeWidth=8..color=const Color(0x34e0faff)..maskFilter=const MaskFilter.blur(BlurStyle.normal,7));
    }else{
      final step=sheet?18.0:16.0;
      for(var x=step/2;x<size.width;x+=step){for(var y=step/2;y<size.height;y+=step){
        final weight=sheet?1.0:((x/size.width+y/size.height- .7)/1.3).clamp(0.0,1.0).toDouble();
        canvas.drawCircle(Offset(x,y),sheet?1:.8,Paint()..color=Colors.white.withValues(alpha:weight*(sheet? .18:advice? .14:.16)));
      }}
    }
  }
  @override
  bool shouldRepaint(_CardTexturePainter old)=>day!=old.day||locked!=old.locked||light!=old.light||advice!=old.advice||sheet!=old.sheet;
}

class _WinterPainter extends CustomPainter {
  const _WinterPainter({required this.day,required this.phase,required this.today,required this.snow,required this.locked,required this.radius});
  final int day;final double phase,radius;final bool today,snow,locked;
  @override
  void paint(Canvas canvas,Size size){
    if(snow){for(var i=0;i<4;i++){
      final x=size.width*(14+(day*17+i*23)%73)/100;
      final y=size.height*((10+(day*9+i*13)%29)/100+phase)%size.height;
      canvas.drawCircle(Offset(x,y),i==1?1.45:i==3?1.125:.95,Paint()..color=Colors.white.withValues(alpha:locked? .24:.6));
    }}
    final rect=Offset.zero&size,p=Paint()..style=PaintingStyle.stroke..strokeWidth=today?1.35:1;
    if(today){p.shader=SweepGradient(transform:GradientRotation(phase*2*math.pi),colors:const [Color(0x55d7ac64),Color(0x99d5a05f),Color(0xffffe09f),Color(0xfffff7d8),Color(0xffffd27b),Color(0x99c28c46),Color(0x55d7ac64)],stops:const [0,.514,.678,.717,.769,.853,1]).createShader(rect);}
    else{p.color=locked?const Color(0x9bdff9f6):const Color(0x27ffffff);}
    canvas.drawRRect(RRect.fromRectAndRadius(rect.deflate(p.strokeWidth/2),Radius.circular(radius)),p);
  }
  @override
  bool shouldRepaint(_WinterPainter old)=>phase!=old.phase||day!=old.day||today!=old.today||snow!=old.snow||locked!=old.locked||radius!=old.radius;
}

class _DaySheet extends StatefulWidget {
  const _DaySheet({required this.day, required this.content, required this.time, this.actions, this.savedAdvice,this.celebrate=false,this.onSaved});
  final bool celebrate;final VoidCallback? onSaved;
  final AdventDay day; final AdventContent content; final CampaignTime time;
  final AdventSystemActions? actions; final SavedAdviceRepository? savedAdvice;
  @override
  State<_DaySheet> createState() => _SheetState();
}
class _SheetChrome extends StatelessWidget {
  const _SheetChrome();
  @override
  Widget build(BuildContext context)=>SizedBox(key:const ValueKey('sheet-chrome'),height:60,child:Stack(children:[
    Align(alignment:Alignment.topCenter,child:Container(width:42,height:5,margin:const EdgeInsets.only(top:14),decoration:BoxDecoration(color:const Color(0xffc9cfc4),borderRadius:BorderRadius.circular(5)))),
    Positioned(right:14,top:14,child:SizedBox(width:38,height:38,child:IconButton(onPressed:()=>Navigator.pop(context),tooltip:'Закрыть',
      style:IconButton.styleFrom(backgroundColor:const Color(0xffeef0e9),side:const BorderSide(color:Color(0xffd6ded4))),icon:const Icon(Icons.close,size:18,color:Color(0xff395247)))))
  ]));
}

class _SheetState extends State<_DaySheet> {
  bool _saved=false,_busy=false,_loaded=false,_loadError=false;
  @override
  void initState(){super.initState();_load();}
  Future<void> _load()async{
    try{final ids=await widget.savedAdvice?.readSaved(AdventProgress.campaignId);
      if(mounted)setState((){_saved=ids?.contains(widget.day.id)??false;_loaded=true;_loadError=false;});
    }catch(_){if(mounted)setState(()=>_loadError=true);}
  }
  void _message(String message)=>ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(message)));
  Future<void> _action(Future<SystemActionResult> Function() action)async{
    if(_busy)return;setState(()=>_busy=true);
    try{final result=await action();if(mounted&&result==SystemActionResult.unavailable)_message('Действие недоступно на этом устройстве');}
    catch(_){if(mounted)_message('Не удалось выполнить действие. Попробуйте ещё раз.');}
    finally{if(mounted)setState(()=>_busy=false);}
  }
  @override
  Widget build(BuildContext context){
    final day=widget.day,event=day.event,width=MediaQuery.sizeOf(context).width;
    final titleSize=(width*.074).clamp(28.0,36.0).toDouble(),horizontal=width<=360?16.0:21.0;
    return _featureTheme(context,ConstrainedBox(constraints:BoxConstraints(maxHeight:MediaQuery.sizeOf(context).height*.91),child:SafeArea(top:false,child:Column(mainAxisSize:MainAxisSize.min,children:[
      const _SheetChrome(),
      Flexible(child:SingleChildScrollView(key:const ValueKey('day-sheet-scroll'),padding:EdgeInsets.fromLTRB(horizontal,2,horizontal,20),
        child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
          Padding(padding:const EdgeInsets.only(top:3,bottom:6),child:Text(_dateCaption(day),style:const TextStyle(color:Color(0xff688576),fontSize:10,height:1.1,fontWeight:FontWeight.w800,letterSpacing:1.3))),
          Align(alignment:Alignment.centerLeft,child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:340),child:Text(day.title,style:_serif.copyWith(fontSize:titleSize,height:1.04,letterSpacing:-.025*titleSize,color:const Color(0xff21372b))))),
          const SizedBox(height:17),
          if(event!=null)...[
            const SizedBox(height:2),
            ClipRRect(borderRadius:BorderRadius.circular(20),child:SizedBox(height:174,child:Stack(fit:StackFit.expand,children:[
              DecoratedBox(decoration:BoxDecoration(gradient:LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,colors:_sheetColors(day.theme)))),
              const CustomPaint(painter:_CardTexturePainter(day:0,advice:false,sheet:true)),
              const DecoratedBox(decoration:BoxDecoration(gradient:RadialGradient(colors:[Color(0x40eac690),Colors.transparent],radius:.8))),
              Center(child:OverflowBox(maxWidth:188,maxHeight:188,child:_art(widget.content,day.art,size:188))),
              if(widget.celebrate&&!MediaQuery.disableAnimationsOf(context))const Positioned.fill(child:_SurpriseConfetti()),
            ]))),
            const SizedBox(height:17),
            if(MediaQuery.textScalerOf(context).scale(1)>1.4)...[
              _detail(Icons.calendar_today_outlined,'Дата','${day.date.day} декабря 2026',width,first:true),SizedBox(height:width<=360?7:9),
              _detail(Icons.schedule,'Время',event['time'] as String,width),SizedBox(height:width<=360?7:9),
              _detail(Icons.location_on_outlined,'Место',event['place'] as String,width),
            ]else...[
            IntrinsicHeight(child:Row(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
              Expanded(child:_detail(Icons.calendar_today_outlined,'Дата','${day.date.day} декабря 2026',width,first:true)),
              SizedBox(width:width<=360?7:9),Expanded(child:_detail(Icons.schedule,'Время',event['time'] as String,width)),
            ])),SizedBox(height:width<=360?7:9),_detail(Icons.location_on_outlined,'Место',event['place'] as String,width),
            ],
            const SizedBox(height:17),const Text('О СОБЫТИИ',style:TextStyle(color:Color(0xff789083),fontSize:10,height:1.1,fontWeight:FontWeight.w800,letterSpacing:1)),const SizedBox(height:9),
            _SourceText(event['desc'] as String),const SizedBox(height:19),const Divider(height:1,color:Color(0xffe1e3d8)),const SizedBox(height:16),
            FilledButton.icon(style:_primaryButtonStyle,icon:const Icon(Icons.event_available,size:18),onPressed:widget.actions==null||_busy?null:()=>_action(()=>widget.actions!.addToCalendar(day,widget.time.location)),
              label:Text(event['cta'] as String? ?? 'Добавить в календарь')),
            const SizedBox(height:9),
            OutlinedButton.icon(style:_shareButtonStyle,icon:const Icon(Icons.share_outlined,size:17),onPressed:widget.actions==null||_busy?null:()=>_action(()=>widget.actions!.share(day)),label:const Text('Поделиться')),
          ]else...[
            const SizedBox(height:10),
            Container(constraints:const BoxConstraints(minHeight:215),padding:const EdgeInsets.symmetric(vertical:22,horizontal:20),
              decoration:BoxDecoration(border:Border.all(color:const Color(0xffdce4cf)),borderRadius:BorderRadius.circular(17),gradient:const LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,colors:[Color(0xffe2ead4),Color(0xfff2e9d9)])),
              child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                SizedBox(width:62,height:52,child:OverflowBox(alignment:Alignment.topLeft,maxWidth:62,maxHeight:62,child:_art(widget.content,day.art,size:62))),const SizedBox(height:13),
                const _Kicker('МАЛЕНЬКАЯ МУДРОСТЬ'),const SizedBox(height:9),
                Text('«${day.advice['text']}»',style:const TextStyle(fontSize:26,height:1.2,letterSpacing:-1.3,fontWeight:FontWeight.w700,color:Color(0xff284936))),
                const SizedBox(height:18),Text.rich(TextSpan(children:[const TextSpan(text:'Попробуй сегодня: ',style:TextStyle(fontWeight:FontWeight.w700)),TextSpan(text:day.advice['action'] as String)]),style:const TextStyle(fontSize:13,height:1.55,color:Color(0xff758476))),
              ])),const SizedBox(height:19),
            FilledButton.icon(style:_primaryButtonStyle,onPressed:widget.savedAdvice==null||!_loaded||_busy?null:()=>_action(()async{
              await widget.savedAdvice!.setSaved(AdventProgress.campaignId,day.id,!_saved);
              if(mounted)setState(()=>_saved=!_saved);widget.onSaved?.call();return SystemActionResult.completed;
            }),icon:Icon(!_loaded?Icons.hourglass_empty:_saved?Icons.favorite:Icons.favorite_border,size:14),label:Text(!_loaded?'Загрузка…':_saved?'Совет сохранён':'Сохранить совет')),
            TextButton(style:TextButton.styleFrom(minimumSize:Size.zero,tapTargetSize:MaterialTapTargetSize.shrinkWrap,padding:const EdgeInsets.fromLTRB(12,15,12,4),foregroundColor:const Color(0xff486457),textStyle:const TextStyle(fontFamily:'packages/advent_calendar/Roboto',fontSize:12,height:1.2,fontWeight:FontWeight.w700)),
              onPressed:widget.actions==null||_busy?null:()=>_action(()=>widget.actions!.share(day)),child:const Text('Поделиться советом')),
          ],
          if(_loadError)TextButton(onPressed:_load,child:const Text('Повторить загрузку совета')),
        ]))),
    ]))));
  }
}

List<Color> _sheetColors(String theme)=>switch(theme){
  'ruby'=>const [Color(0xff943946),Color(0xff431e2e)],
  'green'=>const [Color(0xff5a865b),Color(0xff184937)],
  'moss'=>const [Color(0xff838d54),Color(0xff285b4a)],
  'purple'=>const [Color(0xff68587f),Color(0xff2e3c5b)],
  'sand'=>const [Color(0xffa77456),Color(0xff6a3f46)],
  'ice'=>const [Color(0xff4c9194),Color(0xff235c6a)],
  _=>const [Color(0xff426e83),Color(0xff233655)],
};
final _shareButtonStyle=OutlinedButton.styleFrom(backgroundColor:const Color(0xfff4f4ed),side:const BorderSide(color:Color(0xffdce3d9)),textStyle:const TextStyle(fontFamily:'packages/advent_calendar/Roboto',fontSize:12,fontWeight:FontWeight.w700),minimumSize:const Size.fromHeight(45),foregroundColor:const Color(0xff3f5b4a),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(13)));
/// Only the source's **strong** and *emphasis* syntax; no HTML execution.
class _SourceText extends StatelessWidget {
  const _SourceText(this.text); final String text;
  @override
  Widget build(BuildContext context) {
    final spans = <TextSpan>[]; var offset = 0;
    for (final match in RegExp(r'\*\*(.+?)\*\*|\*(.+?)\*').allMatches(text)) {
      spans.add(TextSpan(text: text.substring(offset, match.start)));
      spans.add(TextSpan(text: match.group(1) ?? match.group(2), style: TextStyle(
        fontWeight: match.group(1) == null ? null : FontWeight.w800, color:match.group(1)==null?null:const Color(0xff304d38),fontStyle: match.group(2) == null ? null : FontStyle.italic)));
      offset = match.end;
    }
    spans.add(TextSpan(text: text.substring(offset)));
    return Text.rich(TextSpan(children: spans), style: const TextStyle(color: Color(0xff4f6258), fontSize: 13, height: 1.63,fontFamilyFallback:const ['Noto Color Emoji','Apple Color Emoji']));
  }
}

String _dateCaption(AdventDay day){
  const names=['ПОНЕДЕЛЬНИК','ВТОРНИК','СРЕДА','ЧЕТВЕРГ','ПЯТНИЦА','СУББОТА','ВОСКРЕСЕНЬЕ'];
  return '${day.date.day} ДЕКАБРЯ · ${names[day.date.weekday-1]} · ${day.event==null?'СОВЕТ ДНЯ':'СОБЫТИЕ'}';
}
final _primaryButtonStyle=FilledButton.styleFrom(backgroundColor:const Color(0xff183e30),foregroundColor:Colors.white,
  minimumSize:const Size.fromHeight(48),padding:const EdgeInsets.symmetric(horizontal:18,vertical:15),textStyle:const TextStyle(fontFamily: 'packages/advent_calendar/Roboto',fontSize:13,fontWeight:FontWeight.w700),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(13)));
Widget _detail(IconData icon,String label,String value,double width,{bool first=false}){
  final iconSize=width<=360?34.0:38.0,valueSize=width<=335&&first?10.0:width<=360?11.0:12.0;
  return Container(padding:const EdgeInsets.all(8),decoration:BoxDecoration(color:const Color(0xffeff0e8),border:Border.all(color:const Color(0xffe4e7dc)),borderRadius:BorderRadius.circular(13)),
    child:Row(children:[Container(width:iconSize,height:iconSize,decoration:BoxDecoration(gradient:const LinearGradient(colors:[Color(0xffdce8dd),Color(0xffe5ebdf)]),borderRadius:BorderRadius.circular(width<=360?10:11),border:Border.all(color:const Color(0xffd3ddd3))),child:Icon(icon,size:19,color:const Color(0xff557e65))),
      const SizedBox(width:8),Expanded(child:Column(mainAxisAlignment:MainAxisAlignment.center,crossAxisAlignment:CrossAxisAlignment.start,children:[Text(label,style:const TextStyle(fontSize:10,fontWeight:FontWeight.w600,color:Color(0xff819285))),const SizedBox(height:3),Text(value,style:TextStyle(fontSize:valueSize,height:1.4,fontWeight:FontWeight.w700,color:const Color(0xff2d4536)))]))]));
}


class _MedalPainter extends CustomPainter{
  const _MedalPainter();
  @override
  void paint(Canvas canvas,Size size){canvas.save();canvas.translate(5,5);canvas.scale((size.width-10)/160);
    final path=Path()..moveTo(81,10)..cubicTo(85,54,108,75,151,80)..cubicTo(111,87,87,109,81,150)..cubicTo(74,108,50,87,10,80)..cubicTo(51,73,75,53,81,10)..close();
    canvas.drawPath(path,Paint()..shader=const LinearGradient(colors:[Color(0xfffff2c0),Color(0xffbf914b)]).createShader(const Rect.fromLTWH(0,0,160,160)));canvas.restore();}
  @override
  bool shouldRepaint(_MedalPainter old)=>false;
}

Widget _featureTheme(BuildContext context,Widget child)=>Theme(data:Theme.of(context).copyWith(textTheme:Theme.of(context).textTheme.apply(fontFamily:'packages/advent_calendar/Roboto')),child:child);

class _BackdropPainter extends CustomPainter {
  const _BackdropPainter();
  @override
  void paint(Canvas canvas,Size size){
    final rect=Offset.zero&size;
    canvas.drawRect(rect,Paint()..shader=const LinearGradient(begin:Alignment(-.087,-1),end:Alignment(.087,1),colors:[Color(0xff0b2b20),Color(0xff09261d),Color(0xff061e18)],stops:[0,.5,1]).createShader(rect));
    canvas.save();canvas.translate(size.width*.94,size.height*.05);canvas.scale(370,260);
    canvas.drawCircle(Offset.zero,1,Paint()..shader=const RadialGradient(colors:[Color(0xff1d5844),Colors.transparent],stops:[0,.82]).createShader(const Rect.fromLTWH(-1,-1,2,2)));canvas.restore();
    for(var x=14.0;x<size.width;x+=28){for(var y=14.0;y<size.height*.43;y+=28){
      canvas.drawCircle(Offset(x,y),.65,Paint()..isAntiAlias=false..color=const Color(0xffd5eac1).withValues(alpha:.19*(1-y/(size.height*.43))));
    }}
  }
  @override
  bool shouldRepaint(_BackdropPainter old)=>false;
}

class _HistorySheet extends StatefulWidget {
  const _HistorySheet({required this.opened,required this.content,required this.time,required this.saved});
  final int opened;final AdventContent content;final CampaignTime time;final Set<String> saved;
  @override
  State<_HistorySheet> createState()=>_HistoryState();
}
class _HistoryState extends State<_HistorySheet>{
  Timer? _timer;
  @override
  void initState(){super.initState();_timer=Timer.periodic(const Duration(seconds:1),(_){if(mounted)setState((){});});}
  @override
  void dispose(){_timer?.cancel();super.dispose();}
  @override
  Widget build(BuildContext context){
    final width=MediaQuery.sizeOf(context).width,titleSize=(width*.074).clamp(28.0,36.0).toDouble();
    final seconds=tz.TZDateTime(widget.time.location,2027).difference(widget.time.clock.nowUtc()).inSeconds;
    final s=math.max(0,seconds);
    final values=[s~/86400,s%86400~/3600,s%3600~/60,s%60],labels=['дней','часов','минут','секунд'];
    final large=MediaQuery.textScalerOf(context).scale(1)>1.4;
    return _featureTheme(context,ConstrainedBox(constraints:BoxConstraints(maxHeight:MediaQuery.sizeOf(context).height*.91),child:SafeArea(top:false,child:Column(mainAxisSize:MainAxisSize.min,children:[
      const _SheetChrome(),Flexible(child:SingleChildScrollView(key:const ValueKey('history-sheet-scroll'),padding:EdgeInsets.fromLTRB(width<=360?16:21,2,width<=360?16:21,20),
        child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
          const Padding(padding:EdgeInsets.only(top:3,bottom:6),child:Text('ТВОЙ ДЕКАБРЬ',style:TextStyle(color:Color(0xff688576),fontSize:10,fontWeight:FontWeight.w800,letterSpacing:1.3))),
          Text('Твоя история декабря',style:_serif.copyWith(fontSize:titleSize,height:1.04,letterSpacing:-.025*titleSize,color:const Color(0xff21372b))),
          Padding(padding:const EdgeInsets.only(top:9,bottom:16),child:Text.rich(TextSpan(children:[const TextSpan(text:'Открыто '),TextSpan(text:'${widget.opened} из 31',style:const TextStyle(fontWeight:FontWeight.w700)),const TextSpan(text:' дней календаря')]),style:const TextStyle(fontSize:13,color:Color(0xff686b66)))),
          ClipRRect(borderRadius:BorderRadius.circular(18),child:Container(padding:const EdgeInsets.fromLTRB(12,16,12,12),decoration:BoxDecoration(border:Border.all(color:const Color(0x369fc69d)),gradient:const LinearGradient(colors:[Color(0xff174638),Color(0xff10382c),Color(0xff0a291f)],stops:[0,.53,1])),
            child:Stack(children:[
              Positioned(right:-54,top:-56,child:Opacity(opacity:.28,child:Transform.rotate(angle:-9*math.pi/180,child:_art(widget.content,'hero_tree',size:192)))),
              Column(children:[const Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[Row(mainAxisSize:MainAxisSize.min,children:[CustomPaint(size:Size.square(10),painter:_SparkPainter(Color(0xfff6efdb))),SizedBox(width:4),Text('До Нового года',style:TextStyle(color:Color(0xfff6efdb),fontSize:12,fontWeight:FontWeight.w700))]),Text('2027',style:TextStyle(color:_gold,fontSize:11))]),
                const SizedBox(height:12),LayoutBuilder(builder:(context,box){
                  final columns=large?2:4,gap=7.0;
                  return Wrap(spacing:gap,runSpacing:gap,children:[for(var i=0;i<4;i++)SizedBox(width:(box.maxWidth-gap*(columns-1))/columns,
                    child:Container(padding:const EdgeInsets.symmetric(vertical:14,horizontal:4),decoration:BoxDecoration(color:const Color(0x10f3ffe5),border:Border.all(color:const Color(0x2ee7f3ce)),borderRadius:BorderRadius.circular(17)),child:Column(children:[
                      FittedBox(fit:BoxFit.scaleDown,child:Text(values[i].toString().padLeft(2,'0'),style:_serif.copyWith(fontSize:36,height:1,color:const Color(0xffffdfa0)))),
                      const SizedBox(height:3),Text(labels[i],style:const TextStyle(fontSize:10,color:Color(0xffd0ddca))),
                    ]))) ]);
                }),const SizedBox(height:12),Text(s==0?'С Новым годом! Пусть сбудется всё самое светлое.':'До 1 января, 00:00 по московскому времени',textAlign:TextAlign.center,style:const TextStyle(fontSize:12,height:1.5,color:Color(0xffc2d3bf))),
              ]),
            ]))),const SizedBox(height:20),
          _SavedAdviceList(days:widget.content.calendar.days.where((d)=>d.kind==DayKind.advice&&widget.saved.contains(d.id)&&widget.content.calendar.isAvailable(d,widget.time.today)).toList()),
          const Text('Открывай даты, узнавай о мероприятиях и собирай маленькие моменты праздника.',style:TextStyle(fontSize:13.5,height:1.68,color:Color(0xff526257))),const SizedBox(height:16),
          Container(padding:const EdgeInsets.symmetric(vertical:16,horizontal:17),decoration:BoxDecoration(gradient:const LinearGradient(colors:[Color(0xffeaf0dd),Color(0xffe7e8d6)]),border:Border.all(color:const Color(0xffdce4cf)),borderRadius:BorderRadius.circular(17)),
            child:const Column(crossAxisAlignment:CrossAxisAlignment.start,children:[_Kicker('О КАЛЕНДАРЕ'),SizedBox(height:9),Text('У каждого дня — своё время',style:TextStyle(fontSize:17,height:1.38,letterSpacing:-.425,fontWeight:FontWeight.w700,color:Color(0xff284936))),SizedBox(height:9),Text('Просмотр доступных дней отмечается в прогрессе. События доступны заранее, а советы открываются в свой день и остаются доступными позже.',style:TextStyle(fontSize:12,height:1.45,color:Color(0xff758476)))])),
          const SizedBox(height:19),FilledButton(style:_primaryButtonStyle,onPressed:()=>Navigator.pop(context),child:const Text('Понятно!')),
        ]))),
    ]))));
  }
}

class _SparkPainter extends CustomPainter{
  const _SparkPainter(this.color);final Color color;
  @override
  void paint(Canvas canvas,Size size){canvas.save();canvas.scale(size.width/160,size.height/160);
    canvas.drawPath(Path()..moveTo(81,10)..cubicTo(85,54,108,75,151,80)..cubicTo(111,87,87,109,81,150)..cubicTo(74,108,50,87,10,80)..cubicTo(51,73,75,53,81,10)..close(),Paint()..color=color);canvas.restore();}
  @override
  bool shouldRepaint(_SparkPainter old)=>color!=old.color;
}
class _Kicker extends StatelessWidget{
  const _Kicker(this.text);final String text;
  @override
  Widget build(BuildContext context)=>Row(children:[const CustomPaint(size:Size.square(8),painter:_SparkPainter(Color(0xff69836c))),const SizedBox(width:7),Expanded(child:Text(text,style:const TextStyle(fontSize:9,fontWeight:FontWeight.w800,letterSpacing:.99,color:Color(0xff69836c))))]);
}
class _MonthFooter extends StatelessWidget{
  const _MonthFooter();
  @override
  Widget build(BuildContext context)=>Padding(padding:const EdgeInsets.only(top:20,bottom:15),child:Container(padding:const EdgeInsets.all(20),clipBehavior:Clip.antiAlias,
    decoration:BoxDecoration(gradient:const LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,colors:[Color(0x33e0ca94),Color(0x1396b17b)]),border:Border.all(color:const Color(0x2befdbac)),borderRadius:BorderRadius.circular(23)),
    child:Stack(clipBehavior:Clip.none,children:[
      const Positioned(right:-1,top:-15,child:CustomPaint(size:Size.square(73),painter:_FooterStarPainter())),
      Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Праздник в деталях',style:_serif.copyWith(color:const Color(0xfff7f9ed),fontSize:19,height:1.2,letterSpacing:-.475)),const SizedBox(height:7),
        ConstrainedBox(constraints:const BoxConstraints(maxWidth:270),child:const Text('Самое волшебное часто прячется в небольших моментах. Открывай свой декабрь каждый день.',style:TextStyle(color:Color(0xffbfd0bc),fontSize:12,height:1.56)))])
    ])));
}
class _FooterStarPainter extends CustomPainter{
  const _FooterStarPainter();
  @override
  void paint(Canvas canvas,Size size){final c=Offset(size.width/2,size.height/2),p=Paint()..color=const Color(0x38f9dba9)..strokeWidth=4;for(var i=0;i<8;i++){final angle=i*math.pi/4;canvas.drawLine(c,c+Offset(math.cos(angle)*26,math.sin(angle)*26),p);}}
  @override
  bool shouldRepaint(_FooterStarPainter old)=>false;
}

class _SavedHeart extends StatefulWidget {
  const _SavedHeart();
  @override
  State<_SavedHeart> createState()=>_SavedHeartState();
}
class _SavedHeartState extends State<_SavedHeart> with SingleTickerProviderStateMixin {
  late final AnimationController motion;
  @override
  void initState(){super.initState();motion=AnimationController(vsync:this,duration:const Duration(seconds:8));}
  @override
  void didChangeDependencies(){super.didChangeDependencies();if(MediaQuery.disableAnimationsOf(context)){motion.stop();motion.value=0;}else{motion.repeat();}}
  @override
  void dispose(){motion.dispose();super.dispose();}
  @override
  Widget build(BuildContext context)=>SizedBox(width:17,height:17,child:Center(child:AnimatedBuilder(animation:motion,builder:(_,__)=>CustomPaint(size:const Size.square(15),painter:_HeartPainter(motion.value)))));
}
class _HeartPainter extends CustomPainter {
  const _HeartPainter(this.phase);final double phase;
  @override
  void paint(Canvas canvas,Size size){
    canvas.save();canvas.scale(size.width/24,size.height/24);
    final heart=Path()..moveTo(20.8,8.4)..cubicTo(20.8,12.5,15.8,16.3,12,19.5)..cubicTo(8.2,16.3,3.2,12.5,3.2,8.4)..cubicTo(3.2,3.8,10,2.1,12,6.7)..cubicTo(14,2.1,20.8,3.8,20.8,8.4)..close();
    canvas.drawPath(heart,Paint()..color=const Color(0xffe04460));
    if(phase>=.72&&phase<=.95){
      final t=(phase-.72)/.23,opacity=math.sin(t*math.pi)*.8;
      canvas.clipPath(heart);canvas.drawRect(const Rect.fromLTWH(0,0,24,24),Paint()..shader=LinearGradient(begin:Alignment(-3+6*t,-1),end:Alignment(-1+6*t,1),colors:[Colors.transparent,Colors.white.withValues(alpha:opacity),Colors.transparent],stops:const [0,.5,1]).createShader(const Rect.fromLTWH(0,0,24,24)));
    }canvas.restore();
  }
  @override
  bool shouldRepaint(_HeartPainter old)=>phase!=old.phase;
}
class _SavedAdviceList extends StatefulWidget {
  const _SavedAdviceList({required this.days});final List<AdventDay> days;
  @override
  State<_SavedAdviceList> createState()=>_SavedListState();
}
class _SavedListState extends State<_SavedAdviceList>{
  bool all=false;final expanded=<String>{};
  @override
  Widget build(BuildContext context){
    final days=all?widget.days:widget.days.take(3).toList();
    return Padding(padding:const EdgeInsets.symmetric(vertical:16),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
      Row(children:[const Expanded(child:Text('Сохранённые советы',style:TextStyle(fontSize:16,fontWeight:FontWeight.w700,color:Color(0xff284936)))),Text('${widget.days.length}')]),const SizedBox(height:9),
      if(widget.days.isEmpty)Container(padding:const EdgeInsets.symmetric(vertical:15,horizontal:14),decoration:BoxDecoration(color:const Color(0xffeff2e9),border:Border.all(color:const Color(0xffdce4d7)),borderRadius:BorderRadius.circular(15)),child:const Text('Пока нет сохранённых советов. Открой совет и нажми «Сохранить совет» — он появится здесь.',style:TextStyle(fontSize:12,height:1.55,color:Color(0xff6d8073)))),
      for(final day in days)Container(decoration:BoxDecoration(color:const Color(0xffeff2e9),border:Border.all(color:const Color(0xffdce4d7)),borderRadius:BorderRadius.circular(12)),child:Column(children:[
        Material(color:Colors.transparent,child:ListTile(dense:true,title:Text(day.title,style:const TextStyle(fontSize:13,fontWeight:FontWeight.w700)),subtitle:Text('${day.date.day} декабря'),trailing:Icon(expanded.contains(day.id)?Icons.expand_less:Icons.expand_more),onTap:()=>setState((){if(!expanded.add(day.id))expanded.remove(day.id);}))),
        if(expanded.contains(day.id))Padding(padding:const EdgeInsets.fromLTRB(16,0,16,14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(day.advice['text'] as String),const SizedBox(height:8),Text('Попробуй сегодня: ${day.advice['action']}')]))
      ])),
      if(widget.days.length>3)TextButton(onPressed:()=>setState((){all=!all;if(!all)expanded.removeWhere((id)=>!widget.days.take(3).any((d)=>d.id==id));}),child:Text(all?'Свернуть':'Показать все ${widget.days.length}')),
    ]));
  }
}
class _SurpriseTile extends StatelessWidget {
  const _SurpriseTile({required this.day,required this.onTap});final AdventDay day;final VoidCallback onTap;
  @override
  Widget build(BuildContext context)=>Semantics(button:true,label:'${day.date.day} декабря, сюрприз, откроется ${day.date.day} декабря',child:Material(borderRadius:BorderRadius.circular(17),clipBehavior:Clip.antiAlias,color:Colors.transparent,
    child:InkWell(onTap:onTap,child:Stack(fit:StackFit.expand,children:[
      Image.asset('assets/advent/snow_maiden_surprise.webp',package:'advent_calendar',fit:BoxFit.cover,alignment:Alignment.center,excludeFromSemantics:true),
      const DecoratedBox(decoration:BoxDecoration(gradient:LinearGradient(begin:Alignment.topCenter,end:Alignment.bottomCenter,colors:[Color(0x61081c38),Color(0x1f081c38),Colors.transparent],stops:[0,.26,.57]))),
      Positioned(left:day.columns==2?15:12,top:12,child:Text('${day.date.day}',style:_serif.copyWith(color:const Color(0xfffff8e8),fontSize:MediaQuery.sizeOf(context).width<=335?23:MediaQuery.sizeOf(context).width<=380?25:28,height:1))),
      Positioned(left:day.columns==2?20:12,bottom:day.columns==2?17:12,child:const _SurpriseBadge()),
    ]))));
}
class _SurpriseConfetti extends StatefulWidget {
  const _SurpriseConfetti();
  @override
  State<_SurpriseConfetti> createState()=>_ConfettiState();
}
class _ConfettiState extends State<_SurpriseConfetti> with SingleTickerProviderStateMixin{
  late final AnimationController motion;
  @override
  void initState(){super.initState();motion=AnimationController(vsync:this,duration:const Duration(milliseconds:1450))..forward();}
  @override
  void dispose(){motion.dispose();super.dispose();}
  @override
  Widget build(BuildContext context)=>IgnorePointer(child:AnimatedBuilder(animation:motion,builder:(_,__)=>CustomPaint(painter:_ConfettiPainter(motion.value))));
}
class _ConfettiPainter extends CustomPainter{
  const _ConfettiPainter(this.t);final double t;
  @override
  void paint(Canvas canvas,Size size){if(t>=1)return;const colors=[Color(0xfff3d495),Color(0xffe04460),Color(0xffb7ead7),Color(0xffcbb9ed)];
    for(var i=0;i<18;i++){final angle=i*2*math.pi/18;final p=Offset(size.width*.5+math.cos(angle)*size.width*.45*t,size.height*.52+math.sin(angle)*65*t+35*t*t);canvas.save();canvas.translate(p.dx,p.dy);canvas.rotate(t*(i%2==0?8:-8));canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-2.5,-5,5,10),const Radius.circular(2)),Paint()..color=colors[i%4].withValues(alpha:math.sin(math.pi*t)));canvas.restore();}}
  @override
  bool shouldRepaint(_ConfettiPainter old)=>t!=old.t;
}

class _SurpriseBadge extends StatelessWidget {
  const _SurpriseBadge();
  @override
  Widget build(BuildContext context)=>ClipRRect(borderRadius:BorderRadius.circular(8),child:BackdropFilter(filter:ui.ImageFilter.blur(sigmaX:7,sigmaY:7),child:Container(padding:const EdgeInsets.symmetric(horizontal:8,vertical:4),decoration:BoxDecoration(color:const Color(0x5510253a),border:Border.all(color:const Color(0x44ffffff)),borderRadius:BorderRadius.circular(8)),child:const Text('Сюрприз',style:TextStyle(fontSize:11,color:Colors.white)))));
}
