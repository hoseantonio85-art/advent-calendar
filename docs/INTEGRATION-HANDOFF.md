# Advent Calendar · передача Flutter-команде · актуализация 27 ноября 2026

Готовый автономный feature-package. Команда «ВторогоКрыла» сама подключает,
принимает и выпускает его в своём приложении. Исходники host поставщику не нужны
и предоставляться не будут. Подробные контракты: [HOST-INTEGRATION.md](HOST-INTEGRATION.md).

## 1. Что зафиксировать и получить

**Финальный code SHA: 1d711936b0716a77cf4963f20f59539301863a6c**, [PR #12](https://github.com/hoseantonio85-art/advent-calendar/pull/12),
[CI #143](https://github.com/hoseantonio85-art/advent-calendar/actions/runs/46000671866) успешен: analyze, функциональные/визуальные тесты, Android integration,
release/audit/update. **PR ещё не слит; merge требует одобрения автора.**
Предыдущая поставка main/CI #136 сохранена в летописи. Package version **0.1.0**;
demo 0.1.143.1/code14303 — другая нумерация. Новый tag не создаётся.
[Проверки, APK и ограничения](FINAL-POLISH-2026-11-27.md).
Уточнение 14 декабря: в place/locations только адрес; **«Навка Арена»** выделена
в описании. HTML/Flutter проверены на одну строку адреса при обычном масштабе на
320/360/390/430 dp; при крупном тексте переносы сохраняются для доступности.

В pubspec.yaml host:

`publish_to: none` package не мешает Git/path-поставке; pub.dev-релиз не требуется.

```yaml
dependencies:
  advent_calendar:
    git:
      url: https://github.com/hoseantonio85-art/advent-calendar.git
      ref: 1d711936b0716a77cf4963f20f59539301863a6c
      path: flutter
  timezone: ^0.10.1 # прямой import в bootstrap ниже
```

Альтернатива: [полный ZIP того же SHA](https://github.com/hoseantonio85-art/advent-calendar/archive/1d711936b0716a77cf4963f20f59539301863a6c.zip),
распаковать целиком, подключить вложенный flutter/ как path dependency и передать
**эту актуальную инструкцию вместе с архивом**. Архив содержит также master-source
и генераторы; его старая документация относится к моменту code SHA. Проверены
36 runtime-файлов, 18 относительных ссылок и 17 art-ресурсов; байты совпадают с Git.
Для работы package нужны lib/, assets/ и pubspec; example/ и demo Android не импортируются.

Проверено на **Flutter 3.50.1 / Dart 3.14.0 / Java17**. Pubspec объявляет Dart
>=3.4 <4 без нижнего Flutter bound; проверенные locks требуют Dart >=3.13 /
Flutter >=3.47. Нижняя декларация не обещает совместимость со старым SDK.
Deps: timezone ^0.10.1, shared_preferences ^2.5.3, share_plus ^12.0.1,
add_2_calendar ^3.0.1, url_launcher ^6.3.2; CI locks:
0.10.1/2.5.6/12.0.2/3.1.1/6.3.2 соответственно. url_launcher Android backend
6.3.35 требует Dart >=3.12 / Flutter >=3.44, ниже прежнего lock floor;
добавление plugin не меняет обязательные параметры/интерфейсы host.
Git SHA не закрепляет транзитивные версии host: его команда разрешает конфликты
и фиксирует свой pubspec.lock. Demo Android: min24/compile36/target36; нативную
конфигурацию и iOS требования plugins проверить в host, не копировать demo Gradle.

## 2. API и минимальное подключение

Единственный import — package:advent_calendar/advent_calendar.dart. Публичны:
AdventContent/AdventCalendar/AdventDay/DayKind; AdventClock/CampaignTime/AdventProgress;
AdventEntryCard/AdventCalendarScreen; ProgressRepository/SavedAdviceRepository/
SurpriseRepository, AdventBoolStorage/PreferencesBoolStorage/LocalAdventRepository;
AdventSystemActions/NativeAdventActions, SystemActionResult и CalendarExportMode/
CalendarExport/calendarExport; helpers civilDate, ConfirmCalendarExport, ShareDay,
LaunchCalendar. AdventNavigation — необязательный контракт
навигационного адаптера; достаточно штатных onOpen/onExit callbacks host.

```dart
import 'package:flutter/material.dart';
import 'package:advent_calendar/advent_calendar.dart';
import 'package:timezone/data/latest.dart' as tzdata;

class HostClock implements AdventClock {
  @override
  DateTime nowUtc() => DateTime.now().toUtc();
}

// Host вызывает после WidgetsFlutterBinding.ensureInitialized(),
// показывает loading/error/retry и передаёт готовый content в entry.
Future<AdventContent> loadAdvent() {
  tzdata.initializeTimeZones();
  return AdventContent.load();
}

Widget adventEntry(BuildContext context, {
  required AdventContent content,
  required String userId,
  required AdventSystemActions actions,
}) {
  final time = CampaignTime.moscow(clock: HostClock());
  final store = LocalAdventRepository(storage: PreferencesBoolStorage(),
    calendar: content.calendar, userId: userId);
  final progress = AdventProgress(calendar: content.calendar,
    time: time, repository: store);
  return AdventEntryCard(key: ValueKey('advent-entry:$userId'),
    daysUntilNewYear: time.daysUntilNewYear,
    onOpen: () => Navigator.of(context).push<void>(MaterialPageRoute<void>(
      settings: const RouteSettings(name: '/advent/december-2026'),
      builder: (routeContext) => AdventCalendarScreen(
        key: ValueKey('advent:$userId'), content: content, time: time,
        progress: progress, savedAdvice: store, actions: actions,
        onExit: () => Navigator.of(routeContext).pop(),
      ),
    )),
  );
}
```

В host сохраните content/time/store/progress на сессию пользователя; пример
показывает сборку зависимостей. Передайте стабильный непустой несекретный userId
аккаунта, не token/email/новый UUID при каждом запуске. Гостя согласовать отдельно.
Для go_router/другого router заменить callbacks своими push/pop. Это полноэкранный
route; внутренними шторками владеет package. Assets/JSON/шрифты уже зарегистрированы
в package pubspec, их не копируют и не регистрируют заново в host.

## 3. Системные действия, время и данные

Параметр actions в примере — готовый NativeAdventActions либо реализация host
интерфейса AdventSystemActions. Native adapter требует два callback:

- confirmCalendar: Future<CalendarExportMode?> Function(AdventDay). Показать
  исходные дату/время/место и подтверждение; null — отмена, allDay — явно выбранная
  дата, sourceTime — только при startTime и положительной duration. Не угадывать время.
- shareOrigin: Rect Function() — корректный непустой anchor активного RenderBox,
  в том числе для iPad. Проверить настройки plugins/Manifest/Info.plist на целевых
  платформах ([share_plus](https://pub.dev/packages/share_plus/versions/12.0.2),
  [add_2_calendar](https://pub.dev/packages/add_2_calendar/versions/3.1.1)).

Optional event.mapUrl открывается самим package через url_launcher с
LaunchMode.externalApplication из прежнего блока «Место». Небольшой значок справа,
адрес без URL. ОС выбирает Яндекс Карты или внешний браузер по своим handlers.
Без mapUrl поведение прежнее. false/error дают существующий unavailable/error
UI и повтор. Новых обязательных callbacks нет; host делает pub get/native rebuild
и проверяет переход/возврат на физическом Android. canLaunchUrl/preflight нет;
package не требует новых query/permissions для него. Не обещать наличие Яндекс Карт.

Результаты completed/cancelled/unavailable; ошибка даёт retry в UI. completed
календаря означает запуск редактора ОС, **не доказательство сохранения события**.
Без savedAdvice/actions соответствующие возможности не включены полностью;
для принятого MVP передайте все adapters, как в примере. progress.repository
должен реализовывать SurpriseRepository для постоянного однократного claim.

Кампания — Europe/Moscow, clock поставляет host. Экран сам пересчитывает состояние
на midnight/resume; **entry-card host должен перестроить сам** с новым
daysUntilNewYear на московскую полночь/resume. Его timer/observer — ресурс host.
Прогресс А: raw ранние просмотры обычных events сохраняются, начисление с полной
московской даты; будущие советы/сюрпризы закрыты. Советы/claims независимы от opened.

По умолчанию это локальные bool-факты в namespace
advent.v1.<base64url(userId)>.december-2026.<opened|saved|revealed>.<dayId>.
Base64 не шифрует данные; собственного сервера/синхронизации между устройствами
нет. Backup/restore/purge — политика host. Очистка/удаление без backup теряет данные.
Claim сериализуется в одном UI-isolate; multi-engine/isolate требует своего
атомарного адаптера. При logout убрать route **со всеми шторками**, пересоздать
user-scoped store/progress/keys; не очищать все preferences host и не смешивать аккаунты.

## 4. Обновления и ответственность

31 дата декабря 2026, у каждой advice и необязательный event. 14/17 — текущая
редакция, не ограничение runtime. Master: content/calendar_2026.json полного
checkout. Правка → node tools/generate-content.cjs → --check/CI/review → новый
package ref/host lock → **новая сборка и выпуск host**. Готовый SHA уже содержит
generated asset; HTML/master/Node в runtime не загружаются. [Редакторская инструкция](CONTENT-EDITOR.md).
Сохранить userId/campaignId/dayId/advent.v1; при смене identity/schema нужна миграция.

Package поставляет UI/domain/content/local adapters. Host владеет auth/userId,
router/lifecycle/loading/errors, clock, storage/backup policy, OS callbacks и
platform config, зависимостями/приёмкой/выпуском. Исходники host поставщику не передаются.
**Demo APK, com.example.advent_demo, demo signing key и versionCode не используются
в настоящем приложении.** Production appId/подпись/версии принадлежат host.

## 5. Приёмка команды host

- flutter pub get/analyze и native build на согласованных SDK/plugins; все fonts/art
  видны offline, полный экран открывается из реального router, Back/drag/close работают.
- 320/360/390/430 dp, XXS/крупный текст/reduced motion; принятые v9/Bento/таймер сохранены.
- Ранний event/закрытые advice и четыре сюрприза, московская полночь/resume,
  уникальный прогресс, saved add/remove/restore и однократное конфетти корректны.
- Перезапуск, logout/relogin/смена аккаунта и обычное обновление **host APK** поверх
  предыдущего сохраняют данные; старые callback/шторки не показывают чужой аккаунт.
- Реальный переход карты/браузер/возврат для 14 декабря и статичные места 17/18;
  Share pressed/cancel/error и Calendar confirmation/allDay/sourceTime/unavailable;
  физические PROFILE/память/accessibility и целевые Android/iOS устройства приняты.

До интеграции подтвердить: **SDK/платформы и native config; совместимые plugin/lock;
router/Navigator/lifecycle entry; userId/гостя/logout/backup; источник часов и
OS permissions/anchor; владельца контента/прав/QA и обновлений ref**. Нужны эти
решения и результаты проверки команды, а не доступ к закрытым исходникам.
