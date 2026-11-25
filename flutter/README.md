# Advent Calendar · независимый Flutter feature

**25 ноября 2026.** Реализованы входная карточка v9, полноэкранный нативный
календарь, Bento, шторки, хвойный счётчик, прогресс А, избранное, сюрпризы
и заменяемые системные действия. Это package `advent_calendar` версии **0.1.0**;
автономное demo находится в example/ и не подключается в host.
`publish_to: none` исключает публикацию на pub.dev, но не Git/path dependency.

[Короткий handoff](../docs/INTEGRATION-HANDOFF.md) ·
[Подробные контракты](../docs/HOST-INTEGRATION.md) ·
[Редактура контента](../docs/CONTENT-EDITOR.md).

## Подключение

Проверенная ревизия кода/ресурсов из main:
**aa741a7fa98cfd097bc3ad9814b595f068837203**, [CI #136](https://github.com/hoseantonio85-art/advent-calendar/actions/runs/45545383091).
В pubspec.yaml host-приложения:

```yaml
dependencies:
  advent_calendar:
    git:
      url: https://github.com/hoseantonio85-art/advent-calendar.git
      ref: aa741a7fa98cfd097bc3ad9814b595f068837203
      path: flutter
  timezone: ^0.10.1 # host bootstrap импортирует timezone/data/latest.dart
```

Public entrypoint: `import 'package:advent_calendar/advent_calendar.dart';`.
Доступны AdventContent, AdventEntryCard, AdventCalendarScreen, CampaignTime,
AdventProgress, интерфейсы clock/storage/actions/navigation и готовые local/native
adapters. JSON, изображения и Yeseva One/Roboto зарегистрированы в package pubspec;
вручную копировать их или повторно регистрировать шрифты в host не требуется.
Пакет использует собственный namespace `packages/advent_calendar/...`.

CI: Flutter **3.50.1 / Dart 3.14.0**, Java 17. Pubspec объявляет Dart >=3.4 <4,
но проверенные lock-файлы требуют Dart >=3.13 / Flutter >=3.47; нижняя декларация
не является обещанием совместимости со старым host. Его команда согласует SDK,
plugin-версии/нативные настройки и фиксирует собственный pubspec.lock.

## Обязанности host и контент

Host инициализирует IANA timezone data, передаёт стабильный несекретный userId,
владеет route/logout, обновлением countdown входной карточки на midnight/resume
и системными Share/Calendar callbacks. Готовый LocalAdventRepository сохраняет
opened/saved/revealed отдельно по пользователю; серверной/межустройственной
синхронизации нет. Package не требует исходников «ВторогоКрыла» у поставщика:
подключение и приёмку в настоящем приложении выполняет команда host.

Master — `../content/calendar_2026.json`, 31 дата и переменное число event.
Текущая утверждённая редакция — 14 event / 17 advice; совет сохранён на каждой дате.
Из корня полного репозитория: `node tools/generate-content.cjs`, затем
`node tools/generate-content.cjs --check`. Результат — standalone HTML и прежний
runtime asset `assets/advent/calendar_2026.json`; HTML/Node при работе package
не исполняются. Новая редакция контента требует новой ревизии и сборки host APK.

Demo APK **0.1.136.1**, её appId/ключ/versionCode — отдельная тестовая линия.
В настоящий host они не переносятся; подпись и версии host принадлежат его команде.
Обычная интеграция не копирует example/, demo Gradle или signing helpers.
