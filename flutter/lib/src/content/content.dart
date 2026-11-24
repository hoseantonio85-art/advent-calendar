import 'dart:convert';
import 'package:flutter/services.dart';
import '../domain/calendar.dart';

class AdventContent {
  AdventContent._(this.calendar, this.assets);
  final AdventCalendar calendar;
  final Map<String, String> assets;
  factory AdventContent.decode(String source) {
    final json = jsonDecode(source) as Map<String, dynamic>;
    if (json['schemaVersion'] != 1 || json['campaignId'] != 'december-2026') {
      throw FormatException('Unsupported campaign');
    }
    final calendar = AdventCalendar((json['days'] as List).map((d) => AdventDay(d as Map<String, dynamic>)));
    final assets = Map<String, String>.unmodifiable((json['assets'] as Map).cast<String, String>());
    for (final day in calendar.days) {
      if (!assets.containsKey(day.art)) throw FormatException('Missing art: ${day.art}');
    }
    return AdventContent._(calendar, assets);
  }
  static Future<AdventContent> load({AssetBundle? bundle}) async => AdventContent.decode(
    await (bundle ?? rootBundle).loadString('packages/advent_calendar/assets/advent/calendar_2026.json'));
}
