# PR #6 · этап 2/2: финальная техническая проверка · 24 ноября 2026

**Готов к отдельному одобрению merge. PR открыт, не слит.**
Ниже фактические результаты нового полного прогона этапа 2; предыдущие отчёты
и [этап 1](PR6-STAGE1-SYNC-2026-11-24.md) сохранены как история.

## Источники, CI и граница документационного коммита

PR #5 слит автором (dad3144). На старте main edf180b и этап 1 9339042 актуальны,
base PR #6 — main, конфликтов нет. Служебный commit
[a803adf7eb4f0fe9c5e216b3e38277235a51df0e](https://github.com/hoseantonio85-art/advent-calendar/commit/a803adf7eb4f0fe9c5e216b3e38277235a51df0e)
запустил [полный CI #133](https://github.com/hoseantonio85-art/advent-calendar/actions/runs/45462441956) — **success, все четыре gates**.
Его tree a894ebfc1304996e96a78130122aec7a9b921fc8 совпадает с этапом 1;
изменений приложения или workflow для запуска CI нет. Flutter 3.50.1, Java 17.

После [trusted publication](https://github.com/hoseantonio85-art/advent-calendar/actions/runs/45465732090) текущий main ff079ddb79d8fdd5d9b39ecab778b39f574996c7 и native 1c3ba2dc13546f41435b20313cdb0a1b69a79b75
обычным merge сохраняют автоматические README/metadata нового Release и получают
только эту летопись/отчёт. Документационный merge помечен [skip ci], чтобы не
повторять дорогой QA при нулевом diff Flutter/index.html/tools/workflows.
Точный конечный head и итоговый Git merge-аудит приведены в [PR #6](https://github.com/hoseantonio85-art/advent-calendar/pull/6).

## Результаты и сохранённые сценарии

| Проверка | Результат |
|---|---|
| flutter analyze пакета и demo | No issues found, оба |
| Unit/widget | 67 passed, 3 visual намеренно skipped только здесь |
| Отдельный visual run | 29 passed; четыре ширины 320/360/390/430, XXS/200%, обычные/праздничные состояния |
| Pixel regression | 12 PNG входа + 8 истории + 45 Flutter/HTML calendar/sheet/state PNG побайтово идентичны прежним принятым |
| Content | 31 день / 14 мероприятий / 17 советных дат; все source fields/advice/layout и 17 art match HTML |
| Прогресс А / время | Уникальные raw views, будущие события, начисление с полной московской даты, midnight/resume, границы года, unknown/duplicate IDs |
| Избранное / сюрпризы | Saved add/remove/restore, user isolation; закрытые даты 4/9/11/15, независимый однократный claim/конфетти, перезапуск |
| UI | Вход v9 → полноэкранный route, Bento, стеклянный хвойный таймер, Back/drag-down/close, reduced motion и крупный текст |
| OS actions | Share details/cancel/error/retry; Calendar sourceTime/allDay, московский export через Новый год, confirmation/cancel/unavailable |
| Native API35 x86_64 | PASS: реальный Preferences/DataStore, force-stop/новый процесс и восстановление raw opened/saved/derived progress; 24 sheet cycles без исключений |
| Build/audit | Web, debug universal/ARM64, release/profile ARM64, обычная upgrade-пара ARM64+x86_64; manifest/ABI/DEX/size audit PASS |
| Release содержимое | ARM64 AOT, debuggable=false, нет debug Dart/kernel и native integration_test plugin; пользовательский entrypoint lib/main.dart |
| Версии / policy | 2 version + 4 publication-policy tests PASS; подпись/проверка предыдущей APK ниже |
| Source release update API35 | Два обычных release APK, adb install -r PASS, UID/raw facts/UI сохранены |

Ошибок, требующих изменения приложения, не обнаружено. Визуал не менялся для тестов.
Share/Calendar здесь проверены контрактно, не через сторонние приложения телефона.
Add2Calendar подтверждает запуск редактора ОС, не сохранение события внутри него.

Артефакты [CI #133](https://github.com/hoseantonio85-art/advent-calendar/actions/runs/45462441956): advent-entry-v9-review,
advent-history-countdown-review, advent-visual-review, advent-android-motion
(Android PNG, видео, driver.log, process-restart.log и timings.json),
advent-apk-size-report и advent-demo-upgrade-smoke.

## Производительность и стабильность в пределах CI

Нативный debug-эмулятор с software GPU: 277 FrameTiming samples,
build p50/p95 23.53/79.13 ms,
raster p50/p95 75/126.8 ms;
максимумы 318.37/2053.25 ms включают прогрев/декодирование.
За 24 цикла event/history RSS samples MiB:
433.17, 436.43, 439.87, 435.73, 437.76, 440.35, 438.33; maxRSS 499.6 MiB.
Сценарии завершены без ошибок; значения — диагностика CI, **не FPS-приёмка телефона
и не доказательство отсутствия утечки**. Нужны реальные PROFILE/DevTools/GC и
целевые устройства по [PHYSICAL-ANDROID-QA.md](PHYSICAL-ANDROID-QA.md).
Profile APK собран, физический profile target не запускался в эмуляторе.

## Постоянная подпись и реальное обновление

[ARM64 release 0.1.133.1](https://github.com/hoseantonio85-art/advent-calendar/releases/download/android-preview-45462441956/advent-calendar-test-release-arm64.apk) — 18094403 bytes,
17.26 MiB. [Profile ARM64](https://github.com/hoseantonio85-art/advent-calendar/releases/download/android-preview-45462441956/advent-calendar-profile-arm64.apk) ·
[аудит](https://github.com/hoseantonio85-art/advent-calendar/releases/download/android-preview-45462441956/apk-size-report.md) · [Release](https://github.com/hoseantonio85-art/advent-calendar/releases/tag/android-preview-45462441956) ·
[JSON upgrade proof](https://github.com/hoseantonio85-art/advent-calendar/releases/download/android-preview-45462441956/upgrade-report.json) · [signing metadata](https://github.com/hoseantonio85-art/advent-calendar/releases/download/android-preview-45462441956/demo-signing.json).

| Свойство | Предыдущая публичная APK | Новая |
|---|---|---|
| applicationId | com.example.advent_demo | com.example.advent_demo |
| versionName | 0.1.132.1 | 0.1.133.1 |
| versionCode | 13203 | 13303 |
| certificate SHA-256 | 509461ec29c2ca387c2399a1f510e807a0818a97e873dbee4ba83cb71db7eaba | тот же |

Trusted main publisher скачал **реальную предыдущую опубликованную candidate APK**,
проверил её checksum, создал просмотры/избранное через обычный UI, force-stop,
затем adb install -r новой обычной release APK. Uninstall/clear/reset и переноса
данных копированием нет. UID 10067 сохранён; rawFactsBefore ==
rawFactsAfter (opened01=true, opened03=true, saved03=true); после нового процесса
visible progress 2 / 31, избранный совет «Оставь место чуду».
Это реальный Android package update API28 x86_64, **не физический ARM64 телефон**.

Baseline universal APK SHA-256: 521ff7d0c970658be87f53d64cd3ce0a0aceff38dd2e111b4bc1d77f31c6a1e8.
Candidate universal APK SHA-256: 392f3b3b6e55ed729367fc21539ac1b5ffeb67a0732b3555a183677cfc6774f5.
Публичная ARM64 APK скачана отдельно, SHA-256 **21b1c48d824c605b2207757f89be127dc84a7d3c59f786d5bac9245e7220b8a8** совпал с metadata.

## Ключи, логи и безопасная публикация

Environment advent-demo-signing допускает только branch main; deployment metadata
проверены без получения секрета. Ключ/пароли не менялись, provisioning не запускался.
PR CI не получает signing environment. Trusted main signer использует private
RUNNER_TEMP с 0700/0600, пароли только env, key cleanup finally **до** APK execution.
В upload allowlist только APK/public reports/proof; private temp туда не входит.
Source guard, имена опубликованных assets, содержимое ZIP скачанной APK и логи
публикации проверены: private key/keystore payload не обнаружены, secret env masked.
Публичный certificate fingerprint не является секретом.

Сохраняются com.example.advent_demo, постоянный сертификат, workflow ID427003215
и общий run counter, монотонный versionCode, expected APK identity/version/cert,
previous checksum и обязательный signed install-r gate. Тег Release фиксирует
publisherCommit; исходники APK — **sourceSha a803adf**, как указано в metadata.
Дополнительный PAT, обход environment или публикация PR без gates не вводились.

## Main-source после будущего merge

На этом этапе безопасно проверена **фактическая конфигурация** publisher:
JS selector/job guard с mocks, Bash syntax и negative tests policy; оба допустимых
пути (main push/согласованный PR), отказ для fork/чужого workflow/event/branch,
неполных/skipped/duplicate gates и SHA вне main. Secret не использовался в тесте.

Все четыре jobs включены на push main. Publisher/helper checkout закреплён на
конкретном trusted main commit, ref/environment только main. Проверки provenance,
cert/version/checksum/real update остаются обязательными. Merge-audit использует
точный sourceSha, не зависит от удалённых feature-веток. README main-source
обновляется без записи в уже слитую native-ветку; [skip ci] предотвращает цикл.

**Реальная main-source публикация до merge невозможна:** main пока содержит
foundation, а не весь package #6. Текущая подписанная APK проверена существующим
trusted PR-source path. После отдельно разрешённого merge необходимо дождаться
первого полного main push CI, четырёх success gates и trusted publication;
проверить sourceSha=main commit, рост code, прежний fingerprint, новый signed-update
proof, Release/README/checksum и GitHub Pages. До этого не объявлять main-source
выпуск уже проверенным. Ограничения безопасности не обходились.

## Git и регрессионные ограничения

Full merge-tree main edf180b + проверяемый a803adf: exit 0, tree
a894ebfc1304996e96a78130122aec7a9b921fc8. Unmerged entries/маркеров нет.
Финальный аудит свежих refs после release и документационного merge — в PR.
Flutter/** и index.html относительно принятого native 1ec0d1f имеют 0 изменений;
tools/workflows относительно этапа 1 также не менялись. Сохраняются исходные
storage keys, UI/анимации, оба родителя/истории, старые отчёты и существующие Releases.

| Файл | Неизменный blob SHA |
|---|---|
| index.html | 35ded5223f0fcaeb25e5b736118f64865570457b |
| flutter/lib/advent_entry_card.dart | 2d26dbd8b542f5f8bf050eb6a2a59bc2a428dea5 |
| flutter/lib/src/ui/history_countdown.dart | 44a31928915ff558a0fc24492d6b606cb0d63a03 |
| flutter/assets/advent/calendar_2026.json | 32c94c0aa2fb3436014393a438e86fe061a00e81 |

GitHub Pages проверен HTTP200; HTML blob совпадает с main, старым файлом не заменён.
Рабочая ветка автора не менялась, работа шла в отдельном worktree. Без force/reset/
rebase, backend, встраивания в монолит и магазина.

## Оставшиеся работы перед настоящим выпуском

1. Физическая QA: PROFILE/FPS/память/GC, accessibility, реальные Share/Calendar,
   устройство автора и согласованная матрица Android.
2. Issue #7: единый редакторский источник и согласованные идентификаторы/миграции;
   сейчас HTML/JSON сверяются CI, старые данные не сбрасываются.
3. Согласовать релизный контент, даты/время/места и права на арт.
4. После получения исходников «ВторогоКрыла» согласовать SDK/plugins/router/account
   и выполнить [интеграцию](HOST-INTEGRATION.md), обновление хост-APK с сохранением
   namespace/прогресса и финальную QA. Production signing/appId/version принадлежат
   хосту, demo key и demo counters туда не переносятся.

**Остановиться перед merge. Требуется отдельное разрешение автора.**
