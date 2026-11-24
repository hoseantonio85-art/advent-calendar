# Issue #7 · единый источник контента · 24 ноября 2026

Исходная база — main 38d24cd после авторских merge PR #5/#6. Отдельная ветка
feature/issue-7-content-source. PR автоматически не сливается.

## Реализовано

content/calendar_2026.json — единственный редактируемый production-источник,
format advent-content/schemaVersion1. На каждой дате стабильные id/date, полный
advice с собственным fallback-оформлением, optional event со всеми исходными
полями/verification, revealOnDate. Для runtime сохраняется прежняя Flutter-схема1.

Генератор меняет только три отмеченных блока HTML: events/thoughts/Bento,
советный art/theme, активные surprise dates. Одна прежняя формула theme заменена
обращением к сгенерированной таблице; CSS/DOM/анимации/встроенные изображения
не переписывались. HTML остаётся standalone, без fetch/server/backend/CMS.

Начальное преобразование проверено на immutable main: Flutter JSON **побайтово
прежний**, blob 32c94c0aa2fb3436014393a438e86fe061a00e81, все 31 тройки thoughts,
14 мероприятий/17 советных дат, metadata/cardLines/NBSP/Markdown и 17 art-файлов
сохранены. Fingerprint fixture защищает эту утверждённую редакцию и HTML shell.

Runtime убирает только жёсткое ограничение 14/17: даты/ID/advice/kind/сюрпризы
по-прежнему проверяются. Контракт хоста, storage namespace, SDK/plugins, entry,
Bento UI/шторки/таймер/анимации не менялись. Поля startTime/locations — строгое
представление исходного time/place, без автоматических догадок.

## Проверки

Локально **9 Node tests PASS**: edit19 в обеих версиях, event add/remove/fallback,
стабильные ID/advice, 15/13/0 events, dormant surprise, malformed schema/date/art,
determinism, восстановление исходников, script-escaping, обнаружение вручную
изменённых выходов и CSV с multiline/quotes. Content и progress parity PASS.

Добавлены Dart-тесты реальных временных выходов Node-генератора: loader разных
составов, raw progress/saved keys без сброса при смене event/advice, московская
полночь, сохранение independent surprise claim после remove/restore. Browser
acceptance использует существующий preview=31 и проверяет edit19/overlay/fallback,
закрытые состояния и реальные localStorage факты на временном HTML, не app assets.
Полный CI и pixel comparison будут записаны после завершения проверок PR.

## CI и подпись

В существующий verify gate добавлены generator --check, content tests/CSV и
browser acceptance. Ручной drift generated files блокирует PR. Workflow ID,
нумерация, все четыре gates и защищённая main-only публикация сохранены.
Issue7 PR не получает ключ и не добавляется в доверенные signing branches.

Обнаружена самостоятельная инфраструктурная проблема main после merge #6:
[CI](https://github.com/hoseantonio85-art/advent-calendar/actions/runs/45474142428)
прошёл verify/native/release, но API35 эмулятор завершился при запуске APK в
android-upgrade (connection refused, emulator process died). Publisher корректно
skipped, непроверенная сборка не опубликована. Package-update smoke переведён
на API28, как уже работающий trusted signed publisher; все проверки UID/raw/UI/
install-r сохранены. Native UI/restart/stress остаются на API35. Ключи/signing/
provenance/cert/code/checksum helpers и environment rules не менялись.

## Использование и оставшиеся границы

[Инструкция редактора и команды](CONTENT-EDITOR.md). Генерация/сверка/CSV — Node22,
без Flutter SDK для редактора. CSV не обратный импорт. Текущие 31/14/17 — snapshot
утверждённой кампании, не runtime-ограничение нового schema; новая согласованная
редакция требует осознанного обновления approval/QA fixtures в PR.

Не добавлены backend/CMS/админка, QA UI в APK, новый дизайн, переупаковка арта
или дедупликация alias-картинок. Физическая QA, согласование релизного контента/
прав и интеграция «ВторогоКрыла» после получения исходников остаются отдельно.
