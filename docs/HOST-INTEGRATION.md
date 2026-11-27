# Подключение Advent Calendar к «ВторомуКрылу»

**Актуализировано 27 ноября 2026.** Передаётся готовый автономный package.
Исходники «ВторогоКрыла» поставщику не предоставляются и не требуются: команда
host самостоятельно подключает и принимает модуль в своём приложении.
Визуальная приёмка MVP подтверждена автором 24 ноября 2026; дизайн зафиксирован.
[Короткая самостоятельная инструкция передачи](INTEGRATION-HANDOFF.md).

## 1. Зависимость и проверенная среда

Подключить package с фиксированным проверенным SHA:

```yaml
dependencies:
  advent_calendar:
    git:
      url: https://github.com/hoseantonio85-art/advent-calendar.git
      ref: 1d711936b0716a77cf4963f20f59539301863a6c
      path: flutter
  timezone: ^0.10.1 # прямая зависимость для bootstrap import ниже
```

Это финальный code SHA [PR #12](https://github.com/hoseantonio85-art/advent-calendar/pull/12),
[CI #143](https://github.com/hoseantonio85-art/advent-calendar/actions/runs/46000671866) полностью успешен. До merge требуется отдельное одобрение автора.
Package version остаётся **0.1.0**; demo APK 0.1.143.1 имеет другую нумерацию
и в PR подписана только CI debug-ключом. Постоянная demo-подпись доступна лишь
доверенному main после разрешённого merge. Поставка: закреплённые исходники плюс актуальная handoff-
инструкция. Если Git недоступен, [полный ZIP этого SHA](https://github.com/hoseantonio85-art/advent-calendar/archive/1d711936b0716a77cf4963f20f59539301863a6c.zip)
содержит flutter/, master-source и tools; после распаковки можно использовать
`path: ../vendor/advent-calendar/flutter` (путь выбрать по фактическому каталогу).
Архивная документация соответствует моменту code SHA; передавайте вместе с ZIP
актуальный INTEGRATION-HANDOFF.md. Исходники package не импортируют example/,
не вызывают runApp, не создают backend или глобальный router.

Проверенная среда: Flutter **3.50.1 / Dart 3.14.0**, Java **17**. Pubspec формально
объявляет Dart >=3.4 <4 без нижнего Flutter bound; проверенные lock-файлы требуют
Dart >=3.13 / Flutter >=3.47. Это разные сведения: старый SDK host не объявляется
совместимым без его проверки. Demo CI использовал Android minSdk24/compileSdk36/
targetSdk36; это фактическая конфигурация demo, не автоматическая настройка host.

| Зависимость | Ограничение package | Разрешено в проверенном lock |
|---|---|---|
| timezone | ^0.10.1 | 0.10.1 |
| shared_preferences | ^2.5.3 | 2.5.6 |
| share_plus | ^12.0.1 | 12.0.2 |
| add_2_calendar | ^3.0.1 | 3.1.1 |
| url_launcher | ^6.3.2 | 6.3.2 |

Host использует собственный pubspec.lock: Git SHA закрепляет код/контент package,
но не подменяет разрешение транзитивных зависимостей host. Не копировать demo lock
и не обходить конфликты слепыми dependency_overrides. Согласовать SDK/plugins,
AGP/Gradle/Kotlin/min/compile/target SDK и нативные настройки целевых платформ.
CI проверял Android; iOS и реальные OS-приложения принимаются командой host.

Assets/шрифты/JSON подключаются через `packages/advent_calendar/...`. Их не нужно
копировать или дублировать в host pubspec; package уже регистрирует Yeseva One и
Roboto. Кампания — 31 дата декабря 2026, у каждой есть advice, event необязателен.
14/17 — текущая утверждённая редакция, не лимит runtime; сценарии 15/13/0 проверены.
Новая кампания/изменение identity/schema требует отдельной совместимой миграции.

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

Host может предоставить свои часы; достоверность clock — его ответственность.
Часовой пояс кампании — Europe/Moscow, независимо от зоны телефона. Загрузчик
проверяет schema/campaign, 31 стабильную уникальную дату/ID, advice, соответствие
kind/event, разрешённые surprise-состояния и art; число мероприятий переменное.
Загружать content один раз, передавать его в user session/route. При ошибке bundle/
JSON показывать штатную ошибку/retry host, не пустой календарь и не сброс прогресса.

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

Готовый store реализует все три интерфейса. Для своего хранилища нужны
ProgressRepository, SavedAdviceRepository, SurpriseRepository; последний нужен
для однократного конфетти и должен быть реализован progress.repository.
recordOpened — идемпотентный set-union, claim — атомарный на уровне хранилища.
Локальный claim сериализуется только в одном UI-isolate. Multi-engine/isolate и
межустройственная синхронизация не реализованы. Preferences — локальные bool-
факты, не зашифрованное хранилище или аккаунтный backend. OS backup/restore,
удаление данных и политика гостя принадлежат host. При очистке/удалении приложения
без сохранения данных host прогресс теряется. Новый сервер package не требует.

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

### Внешние карты · 27 ноября

Optional event.mapUrl — отдельная абсолютная HTTPS-ссылка. Package показывает
в прежнем блоке «Место» небольшой внешний значок и вызывает url_launcher через
LaunchMode.externalApplication. Яндекс Карты откроются при соответствующей
ассоциации ОС, иначе внешний браузер; error/false обрабатываются с возможностью
повтора. Обязательные AdventSystemActions/параметры экрана не расширялись:
переход работает и с существующим host adapter. Без mapUrl блок не кликабелен.
Адрес и locations не содержат URL; Share/Add to Calendar используют текст места.
canLaunchUrl не вызывается; дополнительных query/permissions для preflight
package не требует. Host подтверждает свои OS restrictions и физический переход
с возвратом в календарь. Новый plugin требует pub get и native rebuild;
[проверенные версии и границы SDK](FINAL-POLISH-2026-11-27.md).

## 6. Logout, смена аккаунта и отключение

На logout/смене аккаунта:

1. Штатным router убрать **весь** маршрут календаря вместе со шторками из того Navigator, где он открыт.
2. Убрать/пересоздать entry, заменить user-scoped store/progress и key пользователя. Не менять только `userId` у уже открытого state и не оставлять старые overlays.
3. Не очищать весь SharedPreferences хоста. По умолчанию данные прежнего аккаунта остаются в его namespace для следующего входа. Физическое удаление — отдельная политика/адаптер хоста.

Поздние ответы старого store не должны перерисовать новый экран: сценарий с разными ValueKey проверен. Пакет отменяет свои таймеры, controllers и observers при dispose. Уже начатая запись может завершиться только в старом namespace. Хост владеет отменой собственных сетевых операций, если введёт удалённый адаптер.

Для отключения убрать entry/route, затем dependency/adapters. Настройки других
функций не затрагиваются, фоновых сервисов нет. Ключи можно оставить или удалить
по политике аккаунта. Реальное подключение выполняет команда host в своей среде;
передавать исходники поставщику package не требуется.

## Что запросить у команды хоста

Подтвердить версии Flutter/Dart и платформы/SDK/Gradle/Kotlin; router/nested
Navigator и lifecycle entry; стабильный userId/гостя/logout/backup/purge;
разрешение plugin-версий и OS-action permissions/handlers. Также согласовать
clock, владельца контентных правок/приёмки и способ обновления package SHA.
Нужны ответы о контракте, **не исходники приложения**.

## 7. Обновление версии модуля в работающем хосте

Подпись APK, applicationId и возрастающий versionCode принадлежат «ВторомуКрылу». Demo key/environment и demo version namespace в хост не переносятся; package не содержит собственного Android-приложения. [Правила demo-обновлений](ANDROID-DEMO-UPDATES.md).

Зафиксировать новый package ref/host lock, проверить SDK/plugins и campaignId/dayId/
schema. Стабильный userId и advent.v1/raw opened/saved/revealed сохраняются; не
очищать Preferences и не заводить namespace на каждый package release. Добавление/
удаление event при прежнем dayId не сбрасывает факты; скрытый saved advice
возвращается после удаления event. Изменение identity/schema требует миграции.

Проверка хоста: установить предыдущий APK хоста, открыть дни/сохранить советы/claim сюрприза; обновить APK хоста обычной подписью и увеличенным host versionCode; после нового процесса проверить данные, московский derived progress, logout/relogin и отсутствие повторного конфетти. Тестировать прежние data fixtures, не только новую установку. Затем QA/выпуск по процессу хоста. Не менять signing identity из-за подключения/обновления Advent.

## 8. Контент после Issue #7

Единственный редактируемый source — content/calendar_2026.json полного checkout.
После согласованной правки из корня: `node tools/generate-content.cjs`, затем
`node tools/generate-content.cjs --check` и проверки [редактора](CONTENT-EDITOR.md).
Генерируются standalone HTML и flutter/assets/advent/calendar_2026.json; их
ручная параллельная редактура не нужна. Потребителю уже закреплённого SHA Node
для runtime не нужен: generated asset включён в package и APK.

Контент не обновляется по сети и не читается из HTML/master в runtime.
Чтобы доставить изменения пользователю, выпустить согласованную ревизию package,
обновить ref/lock host, заново собрать и выпустить его приложение. Node22 нужен
редактору при генерации, а не пользователю приложения. Не добавлять QA preview
в host APK; HTML preview=31 остаётся инструментом редакторской проверки.
