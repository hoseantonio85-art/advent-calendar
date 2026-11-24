# Подключение Advent Calendar к «ВторомуКрылу»

Статус: инструкция передачи независимого package, без изменения настоящего хоста. Его исходников и ограничений пока нет. Визуальная приёмка MVP подтверждена автором 24 ноября 2026; дизайн зафиксирован.

## 1. Зависимость и проверенная среда

Подключить каталог `flutter/` как обычный Flutter-package, а не копировать его в монолит:

```yaml
dependencies:
  advent_calendar:
    path: ../advent-calendar/flutter
```

Для репозитория также доступна Git-зависимость с `path: flutter` и **проверенным commit ref**. В production-хосте выбирать ref после одобренного слияния. Исходники не импортируют `example/`, не вызывают `runApp`, не создают собственный backend или глобальный router.

CI закреплён на Flutter **3.50.1**, Java **17**. Текущие lock-файлы тестового репозитория требуют Dart >=3.13 / Flutter >=3.47; это не обещание совместимости со старым SDK хоста. Хост использует свой pubspec.lock и согласует версии share_plus, shared_preferences, timezone, add_2_calendar и Android Gradle/Kotlin. Точные SDK, зависимости, min/target SDK и manifest сохраняются в артефакте APK-аудита.

Assets/шрифты/JSON подключаются из package через `packages/advent_calendar/...`. Их **не нужно копировать** в хост или дублировать в его pubspec. Пакет содержит кампанию декабря 2026 с 31/14/17; другая кампания требует отдельной согласованной версии контракта (#7).

## 2. Инициализация контента и времени

```dart
import 'package:advent_calendar/advent_calendar.dart';
import 'package:timezone/data/latest.dart' as tzdata;

class HostAdventClock implements AdventClock {
  @override
  DateTime nowUtc() => DateTime.now().toUtc();
}

// Один раз после WidgetsFlutterBinding.ensureInitialized():
tzdata.initializeTimeZones();
final content = await AdventContent.load();
final time = CampaignTime.moscow(clock: HostAdventClock());
```

Хост может предоставить свои часы вместо системных. Часовой пояс кампании — **Europe/Moscow**, независимо от зоны телефона. `AdventContent.load` проверяет схему/кампанию/31 уникальную дату/14 мероприятий/17 советов/арты и пробрасывает ошибку. Загружать один раз на сессию, передавать один объект в маршрут. При ошибке bundle/JSON показывать штатное состояние ошибки и повтор загрузки хоста; не открывать экран с выдуманным/пустым календарём и не очищать прогресс.

## 3. Пользователь и хранилище

```dart
final store = LocalAdventRepository(
  storage: PreferencesBoolStorage(),
  calendar: content.calendar,
  userId: stableOpaqueAccountId,
);
final progress = AdventProgress(calendar: content.calendar, time: time, repository: store);
```

`stableOpaqueAccountId` — стабильный **несекретный** идентификатор аккаунта; не токен, email или случайный id каждой сессии. Пустой id отклоняется. Для гостя нужна отдельная явно принятая политика; не использовать один общий `guest` после выхода другого пользователя.

Ключи `advent.v1.<base64url(userId)>.december-2026.<opened|saved|revealed>.<dayId>`. Base64 — namespace, не шифрование. Хранятся bool-факты, без отдельного счётчика. `opened` — все известные уникальные просмотры, включая будущие мероприятия; UI считает только даты, уже наступившие по Москве. Записи не мигрируются и не обнуляются. `saved` и одноразовый claim `revealed` независимы.

Для своего хранилища реализовать `ProgressRepository`, `SavedAdviceRepository`, `SurpriseRepository`; последний обязателен для однократного конфетти. `recordOpened` — идемпотентный set-union, claim — атомарный на уровне выбранного хранилища. Локальный claim сериализуется в одном UI-isolate. Multi-engine/isolate-сценарий и межустройственная синхронизация не заявлены; при необходимости хост даёт иной адаптер. Для локального MVP backend не нужен.

## 4. Входная карточка и штатный маршрут

```dart
AdventEntryCard(
  key: ValueKey('advent-entry:$stableOpaqueAccountId'),
  daysUntilNewYear: time.daysUntilNewYear,
  onOpen: () => Navigator.of(context).push<void>(MaterialPageRoute<void>(
    settings: const RouteSettings(name: '/advent/december-2026'),
    builder: (routeContext) => AdventCalendarScreen(
      key: ValueKey('advent:$stableOpaqueAccountId'),
      content: content,
      time: time,
      progress: progress,
      savedAdvice: store,
      actions: hostActions,
      onExit: () => Navigator.of(routeContext).pop(),
    ),
  )),
)
```

Это **полноэкранный route**, не WebView, iframe или шторка. Для go_router/другого router сохранить тот же контракт открытия/закрытия. Детали и история — внутренние bottom sheet; Android Back закрывает сначала шторку, затем полный маршрут. `onExit` — callback штатного router, без зависимости от demo.

Полный экран сам обновляет состояние при московской полуночи и `resumed`. Для карточки на домашнем экране хост обновляет передаваемый `daysUntilNewYear` на смене московской даты и resume. Следующую полночь считать как `TZDateTime(location, y, m, d + 1)`, а не как `now + 24h`. Host-observer/timer отменять в dispose. Общий `CampaignTime` использовать и в карточке, и в маршруте.

## 5. Share и календарь ОС

```dart
final hostActions = NativeAdventActions(
  confirmCalendar: hostConfirmCalendarExport, // Future<CalendarExportMode?>
  shareOrigin: hostShareAnchor,              // Rect, непустой и в границах view
);
```

`hostConfirmCalendarExport(day)` возвращает `null` при отмене, `allDay` для даты без подтверждённого времени либо `sourceTime` **только** если source содержит startTime и положительную duration. Диалог должен показывать исходные дату/время/место и требовать подтверждение; callback-пример находится в example/lib/main.dart, сам пакет от demo не зависит. Время не угадывать. Для iPad shareAnchor задаётся из валидного RenderBox активного интерфейса.

Можно полностью заменить `AdventSystemActions`. Результаты: completed/cancelled/unavailable; исключение платформы даёт существующее сообщение об ошибке и возможность повторить. Share cancellation поддерживается адаптером. **Add2Calendar сообщает запуск системного редактора, не подтверждение сохранения и не отмену внутри чужого приложения.** Поэтому completed здесь означает передачу запроса ОС; пакет не сообщает «событие сохранено». Достоверное отслеживание сохранения/отмены требует другого адаптера хоста, если это станет требованием. Web/desktop calendar возвращает unavailable. Нативные разрешения/intent handlers проверить в manifest реального хоста и на телефоне.

## 6. Logout, смена аккаунта и отключение

На logout/смене аккаунта:

1. Штатным router убрать **весь** маршрут календаря вместе со шторками из того Navigator, где он открыт.
2. Убрать/пересоздать entry, заменить user-scoped store/progress и key пользователя. Не менять только `userId` у уже открытого state и не оставлять старые overlays.
3. Не очищать весь SharedPreferences хоста. По умолчанию данные прежнего аккаунта остаются в его namespace для следующего входа. Физическое удаление — отдельная политика/адаптер хоста.

Поздние ответы старого store не должны перерисовать новый экран: сценарий с разными ValueKey проверен. Пакет отменяет свои таймеры, controllers и observers при dispose. Уже начатая запись может завершиться только в старом namespace. Хост владеет отменой собственных сетевых операций, если введёт удалённый адаптер.

Для отключения удалить entry и регистрацию маршрута, затем dependency/adapters из хоста. Настройки других функций не затрагиваются, фоновых сервисов и серверов у модуля нет. Собственные ключи можно оставить или удалить по политике аккаунта. Не внедрять модуль в реальный хост до получения его исходников/ограничений.

## Что запросить у команды хоста

Flutter/Dart, Android Gradle/Kotlin/minSdk, router/nested Navigators, id и жизненный цикл аккаунта, политика logout/backup/purge, используемые plugin-версии и OS-action ограничения. Доступ к исходникам нужен для интеграции, не для выполненной автономной стабилизации.
