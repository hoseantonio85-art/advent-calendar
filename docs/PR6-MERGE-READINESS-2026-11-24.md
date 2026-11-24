# PR #6: подготовка финального слияния · 24 ноября 2026

**Реализация готова к review: полный CI #131 и signed update прошли; итоговые Checks последнего документационного merge — в PR #6. PR не слит; требуется отдельное одобрение автора.**

## База и история

Автор слил PR #5: main `dad3144d351da685fbb36126eb9eddedd52278f4`.
[CI #130](https://github.com/hoseantonio85-art/advent-calendar/actions/runs/45445991129)
и [GitHub Pages](https://github.com/hoseantonio85-art/advent-calendar/actions/runs/45445988556) успешны.
PR #6 перенаправлен с foundation на main. Исходный head #6:
`1ec0d1f08b1369f118d7357603fb8acb5367c5d5`. Отдельный worktree, обычный merge
main в native-ветку; исходная локальная ветка автора не изменялась.
Force push, rebase, reset и автоматического слияния PR нет.

Git подтвердил только три конфликта: README.md, docs/ROADMAP.md и
docs/FLUTTER-SYNC-HANDOFF-2026-11-23.md. Сохранён весь текст main, десять
отличающихся блоков Flutter README, полная прежняя Flutter ROADMAP и обе
исходные handoff-записи. Старые статусы помечены как история; есть ссылки на
неизменяемые исходные коммиты. Текущий download-блок остаётся один.

## Сохранённое приложение

Flutter lib, test, example, assets и lock-файлы сравниваются с исходным head
по Git hashes. Принятый UI не редактируется. HTML/index.html сохраняет blob
`35ded5223f0fcaeb25e5b736118f64865570457b`; GitHub Pages не переделывается.
Нет backend, переноса старых тем/лайков/QA-переключателей или внедрения в монолит.

Контент: **31 день / 14 мероприятий / 17 советных дат**, исходные тексты,
время/места, 17 art-файлов и Bento сверяются с HTML. Прогресс А: raw уникальные
просмотры будущих доступных мероприятий сохраняются, начисление только с полной
московской даты. Будущие советы/четыре revealOnDate-сюрприза закрыты до даты;
opened, saved и одноразовый claim независимы. Границы года/суток, повторы,
гонки чтения/записи, ошибки и смена пользователя покрываются существующими тестами.

## Публикация из main после merge #6

Сохраняются workflow `Flutter foundation`, путь flutter.yml и workflow ID
427003215: нумерация не сбрасывается. Все четыре jobs выполняются на PR и
push main; прежние ограничения только pull_request у motion/upgrade сняты.

Trusted publisher принимает только успешный same-repository run этого workflow:
push main либо существующий календарный PR. Проверяются event+branch, SHA,
номер/попытка и ровно по одному успешному verify/android-motion/android-release/
android-upgrade. Для main дополнительно проверяется происхождение SHA из истории
main. Fork, иной workflow/event/branch, missing/skipped/duplicate gate отвергаются.

Код подписания и policy берутся **из конкретного доверенного publisher commit
main**, а не из PR/source APK. Job дополнительно требует refs/heads/main;
environment advent-demo-signing остаётся main-only, secret доступен только
шагу подписания. Ключ, пароли и provisioning не меняются. После подписания ключ
удаляется до исполнения APK. AppId com.example.advent_demo, fingerprint,
возрастающий versionCode, проверки APK/подписи/предыдущего checksum и реальный
install -r сохранены. PR CI не получает секрет.

Merge-аудит будущего publisher сравнивает текущий main с **точным sourceSha**
сборки и требует exit 0; больше не зависит от существования уже слитой foundation
или native-ветки. Main-source публикация обновляет только main; preview PR —
также живую native-ветку. Поэтому удаление слитых feature-веток не ломает main.
Автоматическая README-запись использует skip ci и сохраняет текст вне блока,
публикация сериализована, ветки обновляются без force. Тег/metadata различают
publisherCommit и sourceSha; дополнительный PAT не вводится.

**До слияния #6 main не содержит полного Flutter-календаря.** Его будущий
push-path проверяется policy-тестами и теми же четырьмя CI jobs на обновлённом PR;
первый реальный main-source run появится только после разрешённого merge.
Текущая новая APK подписывается существующим main publisher из проверенного PR,
что позволяет реально проверить обновление до слияния, не предоставляя ключ PR.

## Проверки и доказательства

- Локально: Node version/policy tests, content/progress parity, отсутствие private
  signing-файлов и маркеров конфликта, syntax workflow и Git merge-аудит.
- GitHub CI: analyze package/demo, unit/widget и отдельные visual tests, web,
  Android motion/native persistence/24 sheet cycles, debug/release/profile APK,
  manifest/ABI/DEX/size audit и обычный release update smoke.
- Защищённая публикация: прежняя публичная APK 0.1.125.1/code12503 → новая
  подписанная candidate, тот же сертификат/UID, raw opened/saved и видимые
  2/31/избранное должны сохраниться без удаления/очистки приложения.

Полные доказательства приведены ниже. На этой машине нет Flutter/
Android SDK и подключённого телефона; тесты выполняются на GitHub runners.
Эмулятор не подтверждает performance/доступность/OS-интенты физического телефона:
[оставшаяся физическая QA](PHYSICAL-ANDROID-QA.md) сохраняется отдельным этапом.
Production signing/applicationId/version принадлежат «ВторомуКрылу», package
подключается по [HOST-INTEGRATION.md](HOST-INTEGRATION.md).

**Перед merge #6 обязательно отдельное одобрение автора.**

## Полученные результаты

Обычный merge **e6375f004e798379e33f13ab67426828e1a8c4f5**, родители
1ec0d1f08b1369f118d7357603fb8acb5367c5d5 и dad3144d351da685fbb36126eb9eddedd52278f4.
[Полный CI #131](https://github.com/hoseantonio85-art/advent-calendar/actions/runs/45448214632) — success, все четыре jobs; Flutter 3.50.1 / Java 17.
После публикации main ca2f7de2e96ce9ccc46dcfc35a45c462b11bb227 вносится ещё одним обычным merge только для
README/metadata и этого отчёта; приложение/CI код остаются проверенными #131.
Итоговые Checks этого merge и точный head видны в [PR #6](https://github.com/hoseantonio85-art/advent-calendar/pull/6).

| Проверка | Результат |
|---|---|
| flutter analyze package + demo | No issues found, оба |
| Unit/widget | 67 passed, 3 visual skipped только в этом прогоне |
| Отдельный visual run | 29 passed; 320/360/390/430 dp, XXS/200%, обычное/праздничное состояния |
| Visual PNG hashes | Все 12 after-PNG входа и 8 PNG таймера идентичны предыдущей принятой версии |
| Content/progress parity | 31/14/17, все исходные поля, тексты, advice/layout и 17 art; московские даты/год/unique views |
| Native API35 x86_64 | PASS: реальные preferences, process restart, raw opened/saved/derived progress, 24 sheet cycles, Back/drag/close, reduced motion |
| Build | Web + debug universal/ARM64 + release/profile ARM64 + обычная upgrade-пара ARM64/x86_64 |
| APK audit | Manifest, ABI, DEX, release без debug/kernel/integration_test; release до постоянного signing 18 059 028 bytes / 17.22 MiB |
| Version/security policy | 2 version + 4 publication-policy tests PASS; actual workflow selector/job guard дополнительно проверены локально без секретов/сетевых записей |
| Source release upgrade, API35 | install -r PASS, без uninstall/clear/reset, UID/raw facts/UI сохранены |
| Persistent signed upgrade, API28 | Реальная предыдущая опубликованная APK 12503 → 13103, PASS |

[Новая APK 0.1.131.1](https://github.com/hoseantonio85-art/advent-calendar/releases/download/android-preview-45448214632/advent-calendar-test-release-arm64.apk) · [trusted publication](https://github.com/hoseantonio85-art/advent-calendar/actions/runs/45451293476) · [JSON proof](https://github.com/hoseantonio85-art/advent-calendar/releases/download/android-preview-45448214632/upgrade-report.json).
Следующие выпуски обновляют единственную кнопку APK в README; эта запись сохраняет
конкретную проверенную пару. Public certificate SHA-256:
509461ec29c2ca387c2399a1f510e807a0818a97e873dbee4ba83cb71db7eaba.
UID 10067, visibleProgress 2 / 31, совет «Оставь место чуду».
rawFactsBefore == rawFactsAfter: opened01=true, opened03=true, saved03=true.
Baseline SHA-256 2dbc4f9c4d59d48027badf74e4e6053e95debaa0dd7f385c9d4ab14908f25d18; candidate 8787bb4c49434fe35a01f741c2cc13b212e29e51e7a20e6f8ab830f72fd48611.

Git audit merge-tree для main dad3144 + e6375f0: **exit 0**, tree
4b37c977c178d72eb87314be733ad9cf8906555e, равен tree проверенного merge.
Unmerged index entries и conflict markers — 0; рабочее дерево автора не изменено.
Flutter/** и index.html относительно исходного #6 — **0 изменений**.
Protected sign/provision/version/update/audit helpers, .gitignore и upgrade-probe
совпадают с main по Git blob; менялись только подготовленные workflow/policy/docs.

| Зафиксированный файл | Blob SHA |
|---|---|
| index.html | 35ded5223f0fcaeb25e5b736118f64865570457b |
| flutter/lib/advent_entry_card.dart | 2d26dbd8b542f5f8bf050eb6a2a59bc2a428dea5 |
| flutter/lib/src/ui/history_countdown.dart | 44a31928915ff558a0fc24492d6b606cb0d63a03 |
| flutter/assets/advent/calendar_2026.json | 32c94c0aa2fb3436014393a438e86fe061a00e81 |

Первый **main-source** выпуск намеренно остаётся после разрешённого автором merge:
до этого нет полного календаря в main. Проверенные source-policy и те же четыре
CI gates готовы для него; текущий signed update доказан через существующий trusted
PR-source path. Это не обещание уже выполненной main-source публикации.
