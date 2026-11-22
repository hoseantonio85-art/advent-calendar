import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/calendar.dart';
import 'host.dart';

abstract interface class AdventBoolStorage {
  Future<bool?> read(String key);
  Future<void> write(String key, bool value);
}

class PreferencesBoolStorage implements AdventBoolStorage {
  PreferencesBoolStorage({SharedPreferencesAsync? preferences})
      : _preferences = preferences ?? SharedPreferencesAsync();
  final SharedPreferencesAsync _preferences;
  @override
  Future<bool?> read(String key) => _preferences.getBool(key);
  @override
  Future<void> write(String key, bool value) => _preferences.setBool(key, value);
}

/// One persistent key per day: concurrent opens never overwrite another day.
/// The host must use a stable, non-secret user id and replace this on logout.
class LocalAdventRepository implements ProgressRepository, SavedAdviceRepository {
  LocalAdventRepository({required this.storage, required this.calendar, required String userId})
      : _scope = base64Url.encode(utf8.encode(userId)) {
    if (userId.isEmpty) throw ArgumentError.value(userId, 'userId');
  }
  final AdventBoolStorage storage;
  final AdventCalendar calendar;
  final String _scope;
  String _key(String campaign, String group, String id) {
    if (campaign != AdventProgress.campaignId) throw ArgumentError.value(campaign, 'campaign');
    return 'advent.v1.$_scope.$campaign.$group.$id';
  }
  AdventDay _day(String id) => calendar.days.firstWhere((d) => d.id == id,
      orElse: () => throw ArgumentError.value(id, 'dayId'));
  Future<Set<String>> _read(String campaign, String group, Iterable<AdventDay> days) async {
    final ids = await Future.wait(days.map((day) async =>
      await storage.read(_key(campaign, group, day.id)) == true ? day.id : null));
    return ids.whereType<String>().toSet();
  }
  @override
  Future<Set<String>> read(String campaignId) => _read(campaignId, 'opened', calendar.days);
  @override
  Future<void> recordOpened(String campaignId, String dayId) {
    _day(dayId);
    return storage.write(_key(campaignId, 'opened', dayId), true);
  }
  @override
  Future<Set<String>> readSaved(String campaignId) =>
      _read(campaignId, 'saved', calendar.days.where((d) => d.kind == DayKind.advice));
  @override
  Future<void> setSaved(String campaignId, String dayId, bool saved) {
    if (_day(dayId).kind != DayKind.advice) throw ArgumentError('Only advice can be saved');
    return storage.write(_key(campaignId, 'saved', dayId), saved);
  }
}
