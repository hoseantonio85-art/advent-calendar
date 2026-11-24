# PR #6 · этап 1/2: синхронизация с main · 24 ноября 2026

**Этап ограничен подготовкой и быстрыми проверками. Этап 2 не запущен, PR не слит.**
Предыдущие полные CI/Android-проверки остаются историческими доказательствами;
они не выдаются за новый QA текущего merge.

## Свежие состояния и обычный merge

- PR #5 действительно слит автором, merge commit
  `dad3144d351da685fbb36126eb9eddedd52278f4` присутствует в истории main.
- Получены main `edf180b8ef7a2fe8e07d0faf5488cc5d601b6950`, native PR #6
  `38a2425b03a144dfe723814fd916cd8691266c5b` и foundation
  `cfed69717d2186e0424ac669cc060a2f3eb5c1b3`.
- PR #6 уже направлен на main; повторное изменение правильной базы не требуется.
- Main вносится в native обычным двухродительским merge без force, reset или
  rebase. Работа в отдельном worktree; исходная локальная ветка автора сохранена.
  Точный опубликованный head — в [PR #6](https://github.com/hoseantonio85-art/advent-calendar/pull/6).

**Новых конфликтов на свежей базе: 0.** README объединился автоматически;
merge внёс только актуальный docs/android-preview.json для существующего Release
0.1.132.1/code13203. Конфликты README.md, docs/ROADMAP.md и
docs/FLUTTER-SYNC-HANDOFF-2026-11-23.md уже были разрешены ранее в
[e6375f0](https://github.com/hoseantonio85-art/advent-calendar/commit/e6375f004e798379e33f13ab67426828e1a8c4f5).
Повторно заменять их версии не потребовалось. Обе летописи, handoff, старые отчёты,
ссылки и Releases сохранены; добавлены только текущие датированные записи.

## Сохранность реализации и публикации

Flutter/**, index.html, tools/** и .github/workflows/** не редактировались на
этом этапе. Их Git blobs сравниваются с исходным native 38a2425; приложение
также совпадает с ранее принятым native 1ec0d1f. Сохранены прогресс А, московские
полные даты, пользовательские ключи opened/saved/revealed, независимые избранное
и surprise claim, 31/14/17, тексты/время/места/арт/Bento, интерфейс и анимации.

Ранее подготовленные изменения main-source publisher из e6375f0 сохранены без
дублирования workflow или ослабления проверок. До будущего merge #6 конфигурация
из feature не становится trusted main publisher. После него:

- workflow Flutter foundation, путь flutter.yml и ID 427003215 сохраняют общий
  счётчик версий; verify/android-motion/android-release/android-upgrade работают
  и на push main, все четыре успешных результата обязательны;
- источник — только same-repository успешный run нужного workflow, main push
  либо согласованный календарный PR; проверяются event/branch/SHA, происхождение
  main SHA и номер/попытка, missing/skipped/duplicate gates отвергаются;
- publisher и signing helpers загружаются из конкретного trusted main commit,
  job требует refs/heads/main, environment advent-demo-signing допускает только
  branch main; секрет доступен только шагу подписания, PR его не получает;
- appId com.example.advent_demo, постоянный сертификат и монотонный versionCode,
  checksum предыдущей APK, signed install-r gate и GitHub Releases сохранены;
- main-source не зависит от существования слитых feature-веток, Git merge-аудит
  требует exit 0 для точного sourceSha, публикация сериализована, README обновляется
  внутри единственного управляемого блока без удаления летописи.

Значения секретов не читались, не копировались и не менялись. Прочитана только
deployment policy окружения: единственное правило `{name: main, type: branch}`.
Provisioning, подпись и публикация новых APK на этапе 1 не выполнялись.

## Быстрые проверки этого этапа

- Node: **6 passed** — 2 теста монотонного версионирования и 4 теста security policy.
- verify-content: **PASS 31/14/17**, все source fields/advice/layout и 17 art-файлов
  точно совпадают с HTML; отсутствующие время/места не придумывались.
- verify-progress-parity: **PASS**, вариант А, уникальные raw views, неизвестные ID,
  полные даты и границы года.
- check-demo-signing-source: **PASS**, отслеживаемых private key-файлов/PEM нет.
- Actual workflow selector/job guard: **PASS** на локальных fixtures, без сетевых
  записей и секретов: main/PR допускаются, чужие refs/repo/event, неполные gates
  и посторонняя main-история отвергаются; устаревшая сборка пропускается.
- Syntax: **13 JS/shell блоков** обоих workflow проверены, Bash использован
  только с `-n`, команды сборки из блоков не исполнялись.
- Git: отсутствие unmerged entries/маркеров, whitespace check с сохранением
  исторических Markdown hard breaks, полный merge-tree и сравнение blobs.

Flutter/Dart недоступны в PATH этой среды; SDK не устанавливался. Flutter analyze,
unit/widget/visual и Android QA этого этапа не запускались. Изучены актуальные
[merge-инструкция](PR-MERGE-READINESS.md), [интеграция](HOST-INTEGRATION.md) и
[demo updates](ANDROID-DEMO-UPDATES.md).

## Граница затрат и этап 2

Подготовительный merge публикуется с **[skip ci]**: новый полный Flutter/Android CI,
emulator/integration/profile, APK rebuild и signed upgrade не запускаются.
Workflow и его будущие gates не отключаются. Существующий подписанный Release
0.1.132.1 и все прежние ссылки остаются действующими; новой APK нет.

Только после отдельного запроса на этап 2: определить необходимый QA с учётом
нулевого diff приложения; при полном прогоне выполнить Flutter analyze обоих
пакетов, unit/widget/visual, native Android/restart/stress, APK build/audit и
обновление реальной предыдущей подписанной версии с сохранением данных.
Физическая QA остаётся по [процедуре](PHYSICAL-ANDROID-QA.md). Первый настоящий
main-source выпуск возможен лишь после отдельно разрешённого merge #6 и
успешных обязательных CI gates. Production-подпись и номера хоста принадлежат
«ВторомуКрылу»; backend и интеграция в недоступный хост не выполняются.

**Остановка после подготовки. Автозапуска этапа 2 и разрешения на merge нет.**
