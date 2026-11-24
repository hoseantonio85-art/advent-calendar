# PR #6: подготовка финального слияния · 24 ноября 2026

**Статус: база обновлена; полный CI и новая signed-update проверка выполняются до окончательного вывода. PR не слит.**

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

Финальные ссылки/результаты будут добавлены после CI. На этой машине нет Flutter/
Android SDK и подключённого телефона; тесты выполняются на GitHub runners.
Эмулятор не подтверждает performance/доступность/OS-интенты физического телефона:
[оставшаяся физическая QA](PHYSICAL-ANDROID-QA.md) сохраняется отдельным этапом.
Production signing/applicationId/version принадлежат «ВторомуКрылу», package
подключается по [HOST-INTEGRATION.md](HOST-INTEGRATION.md).

**Перед merge #6 обязательно отдельное одобрение автора.**
