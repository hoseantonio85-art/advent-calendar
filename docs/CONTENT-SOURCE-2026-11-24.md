# Issue #7 · единый источник контента · 24 ноября 2026

> **Завершено · 24.11.2026:** [CI #135](https://github.com/hoseantonio85-art/advent-calendar/actions/runs/45480145540) success, все четыре gates.
> 71 unit/widget, 29 visual, 65 PNG идентичны; edit19/add/remove/restore/preview
> и source APK update PASS. PR #10 открыт для review, не слит. Подробности ниже.

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

## Фактический итог CI и приёмки

[Код 0292413](https://github.com/hoseantonio85-art/advent-calendar/commit/02924132a95fa7af2efc9f457e495a921ab67ea3),
[полный CI #135](https://github.com/hoseantonio85-art/advent-calendar/actions/runs/45480145540) — **success**, verify/android-motion/android-release/
android-upgrade. Последующий коммит изменяет только датированные отчёты/README/
ROADMAP и помечен [skip ci]; код генератора, master и приложения после QA не менялся.
Точный конечный head/merge-аудит указан в [PR #10](https://github.com/hoseantonio85-art/advent-calendar/pull/10).

| Проверка | Результат |
|---|---|
| Node content acceptance | 9 passed; edit19, overlay/fallback, 15/13/0 events, schema/date/art, determinism, drift, escaping, CSV |
| Signing/version policy tests | 6 passed; helpers/allowlist/environment не менялись |
| Flutter analyze package/demo | Оба No issues found |
| Unit/widget | 71 passed; 3 visual намеренно skipped только в обычном прогоне |
| Отдельный visual run | 29 passed |
| Browser acceptance | PASS: edit19, add/remove, advice art/Bento, preview31/3, removed surprise, progress/saved persistence; page errors 0 |
| Pixel comparison | 12 entry + 8 history + 45 Flutter/HTML PNG точно совпали с принятым набором CI #133 |
| Native Android API35 | PASS: entry/history/XXS/200%/Back/drag/close/reduced motion, preferences/new process и 24 cycles |
| Builds | Web, debug universal/ARM64, release/profile ARM64 и обычная upgrade-пара ARM64/x86_64 |
| APK audit | Manifest/ABI/DEX/size PASS; release AOT, только ARM64, debuggable=false, без native integration_test |
| Upgrade smoke API28 | PASS: два обычных release APK, adb install -r без uninstall/clear/reset, UID/raw opened/saved/UI/favorite сохранены |
| Live Pages main | HTTP200, HTML blob 35ded522 совпал с main; feature ещё не опубликован на Pages |

**19 декабря:** временно изменённые title/desc из master fixture появились в HTML
шторке и загруженном Flutter JSON, time/place остались исходными. После восстановления
генерация вернула исходные выходы. Ни одной тестовой правки в content/calendar_2026.json,
index.html или app assets не оставлено: snapshot утверждённой кампании PASS.

**Добавление/удаление:** event на советной дате3 даёт 15/16, event:null возвращает
исходные advice/art/theme/columns и тот же id. Удаление event1 даёт13/18 и fallback
spark/alt/1; 0events/31advice также загружается. Raw opened/saved keys сохраняются,
сохранённый совет скрывается под event и возвращается после удаления. Московская
полночь пересчитывает прогресс А без повторного открытия, claim4 не выдаётся снова
после remove/restore. Тем самым14/17 не является runtime/schema-ограничением.

Артефакты CI: **advent-editor-csv** (CSV с 31 датой и всеми советами/event-полями),
**advent-content-preview-tests** (result.json, временный standalone HTML и preview31 PNG),
advent-entry-v9-review, advent-history-countdown-review, advent-visual-review,
advent-android-motion, advent-apk-size-report, advent-demo-upgrade-smoke.
CSV: build/content/calendar_2026.csv; инструкции/команды — [CONTENT-EDITOR.md](CONTENT-EDITOR.md).

Issue7 PR намеренно не получает signing key и не включён в publishing allowlist.
Прогон update здесь — CI smoke с временной сборочной подписью, **не новая публичная
постоянно подписанная версия**. Действующая Release 0.1.133.1 не заменялась и её
ссылки сохранены. После отдельно разрешённого merge полный main CI должен пройти
все4gates, затем существующий trusted publisher выполнит постоянную подпись,
проверку предыдущей публичной APK/certificate/version/checksum и публикацию.

Не менялись entry v9/UI/шрифты/анимации/изображения, integration contract/storage
keys/namespace, protected signing/version/provenance helpers и secret policy.
Новый источник — build-time data tool, не backend/CMS или админка. История main,
PR #5/#6 и предыдущих этапов сохранена. **PR #10 не слит: отдельное одобрение автора.**
