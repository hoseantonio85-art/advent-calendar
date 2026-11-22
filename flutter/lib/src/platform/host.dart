import 'package:timezone/timezone.dart' as tz;
import '../domain/calendar.dart';

abstract interface class AdventClock { DateTime nowUtc(); }

/// Host initializes IANA timezone data and explicitly supplies a location.
/// Campaign timezone confirmed by the owner: Europe/Moscow (22 November 2026).
class CampaignTime {
  CampaignTime({required this.clock, required this.location});
  static const campaignTimeZone = 'Europe/Moscow';
  factory CampaignTime.moscow({required AdventClock clock}) => CampaignTime(
    clock: clock, location: tz.getLocation(campaignTimeZone));
  final AdventClock clock;
  final tz.Location location;
  DateTime get today => civilDate(tz.TZDateTime.from(clock.nowUtc().toUtc(), location));
  int get daysUntilNewYear {
    final count = DateTime.utc(2027).difference(today).inDays;
    return count < 0 ? 0 : count;
  }
}

abstract interface class ProgressRepository {
  Future<Set<String>> read(String campaignId);
  /// Atomic set-union, scoped to the host user + campaign. Never overwrite.
  Future<void> recordOpened(String campaignId, String dayId);
}

abstract interface class AdventNavigation {
  Future<void> openCalendar();
  void closeCalendar();
}

enum SystemActionResult { completed, cancelled, unavailable }
abstract interface class AdventSystemActions {
  Future<SystemActionResult> share(AdventDay day);
  /// Adapter must require confirmation of unverified source time/location.
  Future<SystemActionResult> addToCalendar(AdventDay day, tz.Location zone);
}

class AdventProgress {
  AdventProgress({required this.calendar, required this.time, required this.repository});
  final AdventCalendar calendar;
  final CampaignTime time;
  final ProgressRepository repository;
  static const campaignId = 'december-2026';
  Future<Set<String>> read() async => calendar.eligibleProgress(await repository.read(campaignId), time.today);
  Future<bool> open(String id) async {
    final day = calendar.days.where((d) => d.id == id).firstOrNull;
    if (day == null || !calendar.isAvailable(day, time.today)) return false;
    await repository.recordOpened(campaignId, id);
    return true;
  }
}

/// Stored per host user/campaign; independent of opened-day progress.
abstract interface class SavedAdviceRepository {
  Future<Set<String>> readSaved(String campaignId);
  Future<void> setSaved(String campaignId, String dayId, bool saved);
}
