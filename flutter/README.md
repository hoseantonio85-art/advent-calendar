> Обновление Issue #2: нативный AdventCalendarScreen и demo уже реализованы.
> Статус: [NATIVE-CALENDAR.md](../docs/NATIVE-CALENDAR.md).

# Advent Calendar · независимый Flutter feature

Пакет, не приложение. Полный экран и demo — следующий Issue #2.
[Архитектура, схема и хост-контракты](../docs/FLUTTER-MODULE.md).

Подключение через path dependency; import package:advent_calendar/advent_calendar.dart.
Входная карточка v9 и package assets уже зарегистрированы. Полный календарь пока не реализован.
Не копировать вручную виджет в хост: это нарушит package asset lookup.
Хост регистрирует Yeseva One/Roboto, передаёт часы/IANA-зону, ProgressRepository и навигацию.

Проверка: flutter pub get, flutter analyze, flutter test.
Из корня: node tools/verify-content.cjs.
Контент production — assets/advent/calendar_2026.json, без runtime-зависимости от HTML.
