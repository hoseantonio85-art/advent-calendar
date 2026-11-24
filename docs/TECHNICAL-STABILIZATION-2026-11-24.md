# Техническая стабилизация Advent Calendar · 24 ноября 2026

**Результат:** подготовлен независимый Flutter-package для передачи команде хоста. Автономные проверки и оптимизированные тестовые сборки завершены; физическая QA и реальное встраивание остаются следующими этапами. Визуальная приёмка автором пройдена, MVP-дизайн не менялся. [Решение](ACCEPTED-MVP-2026-11-24.md).

Код приложения: [13ec616](https://github.com/hoseantonio85-art/advent-calendar/commit/13ec6164ea9196a716627d7c52388e7e61f12c1e); [полный CI #122](https://github.com/hoseantonio85-art/advent-calendar/actions/runs/45382287564). Поздние Markdown/публикационные изменения не меняют код APK. Flutter 3.50.1, Java 17, repository/application lock-файлы закреплены, pub get выполняется с enforce-lockfile. Версии release-графа: **timezone 0.10.1; shared_preferences 2.5.6; shared_preferences_android 2.5.5; share_plus 12.0.2; add_2_calendar 3.1.1**. Пакет и пример анализируются отдельно.

## APK: фактический размер и состав

| Режим | Байты | MiB | ABI |
|---|---:|---:|---|
| debug | 161,028,785 | 153.57 | arm64-v8a, armeabi-v7a, x86_64 |
| debug-arm64 | 89,250,692 | 85.12 | arm64-v8a |
| release | 18,059,012 | 17.22 | arm64-v8a |
| profile | 27,825,401 | 26.54 | arm64-v8a |

Release на **88.8%** меньше универсального Debug и на **79.8%** меньше Debug ARM64. Первая разница включает и ABI, и JIT/AOT; вторая контролирует ABI, но release/profile также исключают SDK-devplugin integration_test из сборочного demo-хоста. Это явно описанные сборочные варианты, не разные версии календаря.

| Категория APK | Debug ARM64, распаковано MiB | Release ARM64, распаковано MiB |
|---|---:|---:|
| Android DEX / plugins | 15.71 | 0.83 |
| Android shell / other | 15.63 | 0.37 |
| Dart AOT | 0.00 | 4.31 |
| Flutter engine | 36.31 | 10.82 |
| Fonts | 2.14 | 0.57 |
| Images | 0.92 | 0.91 |
| Other Flutter assets | 11.22 | 0.17 |

Точные compressed/uncompressed категории, largest files, SHA-256 и совпадающие изображения: [JSON/MD-аудит](https://github.com/hoseantonio85-art/advent-calendar/releases/download/android-preview-45382287564/apk-size-report.md); полный DevTools code-size JSON, dependency graph, manifest и сертификат — [CI artifact](https://github.com/hoseantonio85-art/advent-calendar/actions/runs/45382287564/artifacts/14915257450). ZIP-суммы не включают заголовки, alignment и signing overhead. Flutter --analyze-size отдельно раскрывает вклад Dart-пакетов; весь libapp.so отнесён к Dart AOT, libflutter.so — к engine.

**[Test release ARM64](https://github.com/hoseantonio85-art/advent-calendar/releases/download/android-preview-45382287564/advent-calendar-test-release-arm64.apk)** · [Debug universal](https://github.com/hoseantonio85-art/advent-calendar/releases/download/android-preview-45382287564/advent-calendar-preview.apk) · [Profile ARM64](https://github.com/hoseantonio85-art/advent-calendar/releases/download/android-preview-45382287564/advent-calendar-profile-arm64.apk) · [Release](https://github.com/hoseantonio85-art/advent-calendar/releases/tag/android-preview-45382287564). Основная ссылка README ведёт на оптимизированный test release, не ZIP/Actions. Release — debug-signing key, com.example.advent_demo, **не production**. Profile предназначен для замеров. Production applicationId, signing, store и host-policy не подменялись тестовой конфигурацией.

Release прошёл проверку единственного ABI arm64-v8a, debuggable=false, отсутствия kernel_blob/debug Dart, тестовых файлов и native integration_test plugin в DEX. Известная SDK-devdependency убирается только в CI release/profile-хосте; исходный example сохраняет её для тестов. Исходник main.dart не меняется. Значения SDK/permissions — release-manifest.xml, подпись — release-signing.txt. Наличие пользовательского preview/QA переключателя не обнаружено в production-entrypoint; HTML вообще не включён в APK.

## Ресурсы

Графика не пересжималась, шрифты и изображения исходников не менялись. Обнаружены четыре группы побайтовых alias-копий: hero_tree (3 файла), cube/snow, moon/orb, spark/star; избыточные копии занимают **206 666 байт (201.82 KiB)** исходников. Также отмечены файлы, не используемые current content/entry, в JSON-инвентаре. Их не удаляли: это небольшая доля веса, aliases проверяются существующим content verifier, а канонизация ссылок принадлежит следующему Issue #7. Автоматический Flutter tree-shaking удаляет лишь неиспользуемые icon glyphs; пользовательская графика и Yeseva/Roboto сохраняются.

## Исправления и функциональные результаты

- Найден race: медленное первоначальное чтение могло затереть только что открытый день. Разделены версии refresh и новых просмотров: старый progress snapshot отклоняется, но корректно загруженное избранное сохраняется. Нет миграции/очистки данных, второй persist-counter не введён. Поздний callback после dispose не запускает новый timer.
- Добавлены **6 gap-тестов**: вход/навигация/Back, stale read, сохранение избранного при stale progress, keyed logout при in-flight чтении, retry хранилища без обнуления фактов, permission/OS exception → повтор и тихая отмена.
- **67 unit/widget**, 3 visual-теста в обычном прогоне намеренно пропущены и включены отдельным visual run — **29 успешных тестов**; analyze пакета/demo, web, native Android и packaging audit успешны. Прежние успешные тесты не переписаны. Доступность, будущие события, пропущенные даты, московская полночь/год, surprise/claim один раз, saved add/remove, пользовательские ключи и повторные открытия покрыты прежними и новыми проверками.
- В Android-плагине реально записаны opened/saved, экземпляр адаптера пересоздан; затем shell остановил процесс и запустил тот же APK. Во втором процессе прочитаны прежние raw-факты и получен корректный derived progress. [Native artifact](https://github.com/hoseantonio85-art/advent-calendar/actions/runs/45382287564/artifacts/14915541053) содержит process-restart.log. Это больше, чем in-memory эмуляция, но не проверка телефона автора.
- 24 повторных открытия/закрытия event/history, Back, drag, close, text 80/100/200%, safe top notices и reduced motion завершены без ошибок. Статический PictureLayer фотографии сохраняется при секундном тике; отдельный тест границы Нового года остаётся.
- Share/cancel/unavailable/calendar-confirmation и ошибки/отказ ОС проверены контрактными тестами. Реальное приложение Share и календарь на телефоне ещё нужно принять. Add2Calendar сообщает запуск редактора, не достоверное сохранение/отмену внутри редактора; UI не выдаёт ложного подтверждения сохранения.
- HTML взят дословно из актуального main, blob **35ded5223f0fcaeb25e5b736118f64865570457b**; в нём уже был вариант А. Чистый JS-тест проверяет raw/unique/даты/год, content verifier — **31/14/17**, тексты/места/время/арт/Bento. Во Flutter та же политика, исходники JSON/изображений не заменялись. Это синхронизация готовой upstream-правки, не изменение дизайна или реализация Issue #7.
- CI перестал дублировать каждый PR push второй полной push-сборкой; superseded runs отменяются. SDK и зависимости закреплены. Для strict ARM64 заданы Android ndk.abiFilters, включая транзитивные JNI библиотеки. Сборочные shell-блоки проверены bash -n; временная ошибка копирования code-size отчёта исправлена до публикации.

## Основные изменённые файлы

| Файлы | Назначение |
|---|---|
| flutter/lib/src/ui/calendar_screen.dart | Единственная продуктовая правка: защита асинхронного progress от устаревшего ответа |
| flutter/test/stabilization_test.dart | 6 функциональных gap-тестов |
| flutter/example/integration_test/calendar_motion_test.dart; tools/android-motion.sh | Native storage/process restart и 24 цикла шторок |
| flutter/example/integration_test/stability_profile_test.dart | Отдельный профильный target для физического телефона |
| .github/workflows/flutter.yml; flutter/pubspec.lock; flutter/example/pubspec.lock | Закреплённая сборочная среда, ABI, release/profile и аудит |
| .github/workflows/android-preview.yml | Публичные APK/отчёты и ссылка на главной; полный Git-пробник |
| tools/android-apk-audit.py; tools/verify-progress-parity.cjs | Измерения APK и независимая проверка HTML-прогресса А |
| index.html | Дословная синхронизация уже принятой upstream-логики из main; main HTML не изменён |
| docs/HOST-INTEGRATION.md; docs/PHYSICAL-ANDROID-QA.md; README/ROADMAP и этот отчёт | Передача, ограничения и летопись |

Входная карточка, история/стеклянный отсчёт, ассеты и campaign JSON не изменялись. Значимые опубликованные коммиты: [фиксация визуальной приёмки b42d206](https://github.com/hoseantonio85-art/advent-calendar/commit/b42d20671e142db7fdf6e341bfb808a155b8bc35), [исправления/проверки afbaf48](https://github.com/hoseantonio85-art/advent-calendar/commit/afbaf48249966ff8bf9e939d82d535b8cc76aede), [сохранение избранного db212e5](https://github.com/hoseantonio85-art/advent-calendar/commit/db212e5f32c2443ecb3fa10bd484a54ef295cf22), проверенный код сборки — 13ec6164ea9196a716627d7c52388e7e61f12c1e.

## Кадры и память: предел доказательств

**Debug, API 35 x86_64, software GPU, 2 CPU. Это не производительность физического телефона.** В смешанном диагностическом наборе 236 кадров: build p50/p95/p99 30.87/99.37/171.82 ms; raster 80.10/139.87/349.38 ms. В выборке есть начальные декодирования и согласованные анимации, а не изолированный steady-state benchmark. Эти числа не использовались как повод менять графику/движение или объявлять нужный FPS достигнутым.

После прогрева 24 циклов RSS: **438.01 → 438.86 MiB**, delta 0.85 MiB; samples 438.01, 439.87, 436.45, 439.79, 437.80, 441.75, 438.86 MiB. Общий peak 501.09 MiB включает engine/decoded images/raster caches. Рост/колебания без GC и длительного physical profile не доказывают ни утечку, ни её отсутствие. Ошибок dispose/ticker/setState при циклах не обнаружено.

Физического Android в рабочем окружении нет. Подготовлены [ручная матрица, DevTools/Memory и automated PROFILE target](PHYSICAL-ANDROID-QA.md). Живые часы в профильном target позволяют измерить настоящий секундный tick; target статически проанализирован, на телефоне Codex не запускался. Реальные cold/warm frame percentiles, стекло, долгие 50/100 циклов, screen reader и OS-интенты — следующая QA, не пройденная проверка.

## Передача и PR

[Инструкция хоста](HOST-INTEGRATION.md): package, assets, clock, router, user scope, logout, progress/saved/surprise и заменяемые OS adapters; отключение без переписывания монолита. Нет зависимости от demo в lib, backend/CMS не создавались. Реального «ВторогоКрыла» встраивание не выполнялось. Нужны исходники и ограничения SDK/router/account/plugins, затем production-подпись, контент/права и финальная QA.

[Полный Git merge-tree audit](https://github.com/hoseantonio85-art/advent-calendar/releases/download/android-preview-45382287564/pr-merge-audit.txt) выполнен в отдельном CI checkout, без изменения веток и без слияния PR. Обе пары дали exit 1: #5 ↔ main — README/ROADMAP; #6 ↔ main — README/ROADMAP и add/add в docs/FLUTTER-SYNC-HANDOFF-2026-11-23.md. Dart/asset-конфликтов на проверенных SHA нет. Это **не готовность к прямому merge**: сначала разрешить документацию с сохранением обеих историй, затем CI на обновлённой базе. [Безопасная последовательность и ограничения](PR-MERGE-READINESS.md). #5 и #6 остаются открытыми; QA/интеграционные Issues не закрываются автоматически. #7 — следующий самостоятельный контентный этап, глобальный master-source/генератор/CMS сейчас не делались.

Порядок: техническая стабилизация → финальная QA → единый контент #7 → согласование контента релиза → интеграция в хост → финальная проверка/выпуск. Визуальный этап не открывается заново.
