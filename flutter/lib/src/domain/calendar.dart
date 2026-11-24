import 'dart:collection';

enum DayKind { event, advice }

/// Source fields are immutable, including source formatting and unknown times.
class AdventDay {
  AdventDay(Map<String, dynamic> json) : data = _freeze(json) as Map<String, dynamic>;
  final Map<String, dynamic> data;
  String get id => data['id'] as String;
  DateTime get date => DateTime.parse(data['date'] as String);
  DayKind get kind => DayKind.values.byName(data['kind'] as String);
  bool get revealOnDate => data['revealOnDate'] == true;
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
    // Event/advice counts are editorial data, not a runtime schema constraint.
    if (days.length != 31 || days.map((d) => d.id).toSet().length != 31) {
      throw FormatException('Expected 31 unique December days');
    }
    for (var i = 0; i < days.length; i++) {
      final d = days[i];
      final advice = d.data['advice'];
      if (d.data['date'] != '2026-12-${(i + 1).toString().padLeft(2, '0')}' ||
          d.id != 'december-2026-${(i + 1).toString().padLeft(2, '0')}' ||
          d.title.isEmpty || d.art.isEmpty || ![1, 2].contains(d.columns) ||
          (d.kind == DayKind.event) != (d.event != null) ||
          (d.revealOnDate && (d.kind != DayKind.event || ![4, 9, 11, 15].contains(d.date.day))) ||
          (advice is! Map<String, dynamic> ||
           ['title', 'text', 'action'].any((key) => advice[key] is! String || (advice[key] as String).trim().isEmpty))) {
        throw FormatException('Invalid day ${d.id}');
      }
    }
  }
  final List<AdventDay> days;
  bool isAvailable(AdventDay day, DateTime campaignDate) =>
      day.kind == DayKind.event && !day.revealOnDate || !civilDate(day.date).isAfter(civilDate(campaignDate));
  /// Credited days are viewed AND reached their full campaign date.
  /// Availability is separate: an ordinary future event may be viewed early.
  Set<String> eligibleProgress(Iterable<String> opened, DateTime campaignDate) {
    final viewed = opened.toSet(), today = civilDate(campaignDate);
    return UnmodifiableSetView(days.where((day) =>
      viewed.contains(day.id) && !civilDate(day.date).isAfter(today)).map((day) => day.id).toSet());
  }

  /// Returns raw known views, not the displayed progress. Future views survive
  /// subsequent opens; callers project them with eligibleProgress when needed.
  Set<String> open(String id, Iterable<String> opened, DateTime campaignDate) {
    final known = days.map((day) => day.id).toSet();
    final result = opened.where(known.contains).toSet();
    for (final day in days) {
      if (day.id == id && isAvailable(day, campaignDate)) result.add(id);
    }
    return UnmodifiableSetView(result);
  }
}
