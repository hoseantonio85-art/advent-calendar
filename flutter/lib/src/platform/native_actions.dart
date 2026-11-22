import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart' show Rect;
import 'package:share_plus/share_plus.dart';
import 'package:timezone/timezone.dart' as tz;
import '../domain/calendar.dart';
import 'host.dart';

enum CalendarExportMode { sourceTime, allDay }
class CalendarExport {
  const CalendarExport({required this.day, required this.start, required this.end, required this.allDay});
  final AdventDay day;
  final DateTime start, end;
  final bool allDay;
}

/// Does not infer missing times. Caller obtains explicit approval first.
CalendarExport calendarExport(AdventDay day, tz.Location zone, CalendarExportMode mode) {
  final event = day.event;
  if (event == null) throw ArgumentError('Only events can be exported');
  final date = day.date;
  if (mode == CalendarExportMode.allDay) {
    // All-day values are civil dates, not UTC instants converted on the device.
    return CalendarExport(day: day, start: DateTime(date.year,date.month,date.day),
      end: DateTime(date.year,date.month,date.day + 1), allDay: true);
  }
  final time = event['startTime'] as String?, duration = event['duration'] as int?;
  if(time == null || duration == null || duration <= 0) throw StateError('Source has no confirmed export time');
  final parts = time.split(':').map(int.parse).toList();
  final start = tz.TZDateTime(zone,date.year,date.month,date.day,parts[0],parts[1]);
  return CalendarExport(day:day,start:start.toUtc(),end:start.add(Duration(minutes:duration)).toUtc(),allDay:false);
}

typedef ConfirmCalendarExport = Future<CalendarExportMode?> Function(AdventDay day);
typedef ShareDay = Future<SystemActionResult> Function(String title, String text, Rect origin);
typedef LaunchCalendar = Future<bool> Function(CalendarExport export);

/// Replaceable OS adapter. Native editor launch is not proof of a saved event.
class NativeAdventActions implements AdventSystemActions {
  NativeAdventActions({required this.confirmCalendar, required this.shareOrigin,
    ShareDay? share, LaunchCalendar? launchCalendar, bool? calendarSupported})
    : _share = share ?? _systemShare, _launch = launchCalendar ?? _systemCalendar,
      _calendarSupported = calendarSupported ?? (!kIsWeb &&
        [TargetPlatform.android,TargetPlatform.iOS].contains(defaultTargetPlatform));
  final ConfirmCalendarExport confirmCalendar;
  final Rect Function() shareOrigin;
  final ShareDay _share;
  final LaunchCalendar _launch;
  final bool _calendarSupported;
  @override
  Future<SystemActionResult> share(AdventDay day) {
    final e = day.event;
    final details = e == null ? '${day.advice['text']}\n${day.advice['action']}' :
      '${e['time']} · ${e['place']}\n${e['desc']}';
    return _share(day.title, '${day.date.day} декабря 2026 · ${day.title}\n$details', shareOrigin());
  }
  @override
  Future<SystemActionResult> addToCalendar(AdventDay day, tz.Location zone) async {
    if (!_calendarSupported || day.event == null) return SystemActionResult.unavailable;
    final mode = await confirmCalendar(day);
    if (mode == null) return SystemActionResult.cancelled;
    final payload = calendarExport(day, zone, mode);
    return await _launch(payload) ? SystemActionResult.completed : SystemActionResult.unavailable;
  }
  static Future<SystemActionResult> _systemShare(String title,String text,Rect origin) async {
    final result = await SharePlus.instance.share(ShareParams(title:title,text:text,sharePositionOrigin:origin));
    return switch(result.status) {
      ShareResultStatus.success => SystemActionResult.completed,
      ShareResultStatus.dismissed => SystemActionResult.cancelled,
      ShareResultStatus.unavailable => SystemActionResult.unavailable,
    };
  }
  static Future<bool> _systemCalendar(CalendarExport payload) => Add2Calendar.addEvent2Cal(Event(
    title:payload.day.title,description:payload.day.event!['desc'] as String,
    location:payload.day.event!['place'] as String,
    startDate:payload.start.toLocal(),endDate:payload.end.toLocal(),allDay:payload.allDay));
}
