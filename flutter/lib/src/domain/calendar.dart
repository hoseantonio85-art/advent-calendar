import 'dart:collection';

enum DayKind { event, advice }

/// Source fields are immutable, including source formatting and unknown times.
class AdventDay {
  AdventDay(Map<String, dynamic> json) : data = _freeze(json) as Map<String, dynamic>;
  final Map<String, dynamic> data;
  String get id => data['id'] as String;
  DateTime get date => DateTime.parse(data['date'] as String);
  DayKind get kind => DayKind.values.byName(data['kind'] as String);
  String get title => data['title'] as String;
  String get art => data['art'] as String;
  int get columns => data['columns'] as int;
  String get theme => data['theme'] as String;
  Map<String, dynamic> get advice => data['advice'] as Map<String, dynamic>;
  Map<String, dynamic>? get event => data['event'] as Map<String, dynamic>?;
}

dynamic _freeze(dynamic value) {
  if (value is Map) {
    return Map<String, dynamic>.unmodifiable(value.map((k, v) => MapEntry(k as String, _freeze(v))));
  }
  if (value is List) return List<dynamic>.unmodifiable(value.map(_freeze));
  return value;
}

/// A calendar date (UTC container only); never an instant or device-local time.
DateTime civilDate(DateTime value) => DateTime.utc(value.year, value.month, value.day);

class AdventCalendar {
  AdventCalendar(Iterable<AdventDay> values) : days = List.unmodifiable(values) {
    if (days.length != 31 || days.map((d) => d.id).toSet().length != 31 ||
        days.where((d) => d.kind == DayKind.event).length != 14 ||
        days.where((d) => d.kind == DayKind.advice).length != 17) {
      throw FormatException('Expected 31 unique days / 14 events / 17 advice');
    }
    for (var i = 0; i < days.length; i++) {
      final d = days[i];
      if (d.data['date'] != '2026-12-${(i + 1).toString().padLeft(2, '0')}' ||
          d.id != 'december-2026-${(i + 1).toString().padLeft(2, '0')}' ||
          d.title.isEmpty || d.art.isEmpty || ![1, 2].contains(d.columns) ||
          (d.kind == DayKind.event) != (d.event != null)) {
        throw FormatException('Invalid day ${d.id}');
      }
    }
  }
  final List<AdventDay> days;
  bool isAvailable(AdventDay day, DateTime campaignDate) =>
      day.kind == DayKind.event || !civilDate(day.date).isAfter(civilDate(campaignDate));
  Set<String> eligibleProgress(Iterable<String> opened, DateTime campaignDate) =>
      UnmodifiableSetView(days.where((d) => opened.contains(d.id) && isAvailable(d, campaignDate)).map((d) => d.id).toSet());
  Set<String> open(String id, Iterable<String> opened, DateTime campaignDate) {
    final result = eligibleProgress(opened, campaignDate).toSet();
    for (final day in days) {
      if (day.id == id && isAvailable(day, campaignDate)) result.add(id);
    }
    return UnmodifiableSetView(result);
  }
}
