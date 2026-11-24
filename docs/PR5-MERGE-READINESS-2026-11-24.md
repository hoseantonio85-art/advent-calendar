# PR #5: подготовка к слиянию · 24 ноября 2026

**Статус: PR #5 подготовлен к review/отдельному одобрению merge. Конфликты разрешены, CI после merge main успешен. PR не слит; #6 не изменён.**

Проверенные исходные refs: main 5a7dc1a021aab191dcd6a49e6b0b645774b95f6b; foundation 704aa862aaa893151ff17f46c23869a7b2a9ab27; #6 1ec0d1f08b1369f118d7357603fb8acb5367c5d5. Работа выполнена в отдельном worktree, исходная рабочая ветка пользователя не менялась. Это обычный двухродительский merge main в ветку #5, без rebase/force/reset.

## Конфликты и история

Фактический Git merge дал только README.md и docs/ROADMAP.md. Сохранён полный актуальный main; все отличающиеся исторические блоки foundation помещены в явно помеченные details без изменения текста. Полные старые версии доступны по immutable commit links; оба родителя остаются в истории. Текущие 31/14/17 и одна кнопка APK 0.1.125.1 имеют приоритет над архивными 13/18.

## Сохранение защищённой публикации

index.html, android-preview.yml, android-upgrade-probe.yml, demo-android-version.cjs, sign-demo-apks.cjs, provision-demo-signing.cjs, android-demo-upgrade.py, APK audit и android-preview.json сравниваются с main по Git blob/hash. Private key/passwords не находятся в Git и не копируются: environment advent-demo-signing допускает только main. PR #5 CI не получает этот environment. Действующая публикация/ссылки/versionCode 12503 остаются прежними; #5 не является новым пользовательским APK.

**Граница проверки после merge #5:** источник подписанной сборки пока PR #6; trusted publisher запускается из main. Его ветка-источник и проверки сохраняются без изменений. Само слияние foundation не публикует APK.

**Обязательный пункт этапа #6 после отдельного разрешения:** нынешний publisher принимает только PR-run feature/issue-2-native-calendar, а android-motion/android-upgrade в полном Flutter CI включены только для pull_request. Перед завершением #6 нужно согласованно добавить push main как источник, включить обе проверки для main и сохранить все 4 gates, same-repo/workflow-id validation, environment main-only и signature/version/checksum guards. Без этого автоматическая публикация будущих main-build после merge #6 не подтверждена. Сейчас схема намеренно не меняется до обновления #6 на согласованную базу.

## Границы foundation и следующего этапа

#5 содержит архитектуру/JSON/исходные календарные контракты, не финальное приложение. Политика прогресса А, surprise claim/revealOnDate, избранное, финальные UI и native adapters находятся в #6 и должны сохраняться при его обновлении; готовность #5 не означает их device QA на новой базе. Не переносить старую foundation eligibleProgress поверх реализации #6.

## Проверки

- Разрешение конфликтов, отсутствие маркеров и сохранение уникальных блоков обеих историй проверяются до commit.
- На merge-коммите **01b9241b3345fa59571cf3adbdb63c9c590a77e9** прошли [push CI #126](https://github.com/hoseantonio85-art/advent-calendar/actions/runs/45442721775) и [PR CI #127](https://github.com/hoseantonio85-art/advent-calendar/actions/runs/45442741859): полное совпадение source fields/advice/layout/16 art с HTML, **31/14/17**, Flutter **3.50.1**, pub get, **flutter analyze: No issues found**, **7 tests passed**. Последующий commit меняет только этот отчёт/README/ROADMAP; актуальные head checks доступны в [PR #5 checks](https://github.com/hoseantonio85-art/advent-calendar/pull/5/checks) и должны быть успешны перед одобрением.
- Подпись/секреты и HTML — hash-проверки; действующая install-r проверка 12403 → 12503 остаётся в docs/ANDROID-DEMO-UPDATES.md.
- Без повторного визуального согласования, backend, store и внедрения в реальный хост.

## Порядок

1. Закончить CI #5 и review текущего merge-коммита; получить отдельное разрешение автора.
2. Merge #5 → main только после этого разрешения, сохранить foundation-ветку до retarget #6.
3. Retarget #6 на обновлённый main, обычный merge main в #6; сохранить обе летописи/постоянную подпись/31/14/17/вариант А.
4. Доработать переход CI/publisher на main-source, полный Flutter/native/packaging/signed update CI на конечной базе.
5. Отдельная готовность/разрешение merge #6. Автоматического слияния нет.

## Точные результаты сохранения и зависимости

- Main является предком подготовленной ветки; merge 01b9241 имеет ровно родителей 704aa862 и 5a7dc1a. GitHub подтвердил mergeable=true на этом состоянии.
- `index.html` остался blob **35ded5223f0fcaeb25e5b736118f64865570457b**.
- `android-preview.yml` — **4cf96e1e0df7cea187a91c06163acfb0b0264713**, `android-upgrade-probe.yml` — **dd0102f8e8e91d59e014888ac40ec86c3e9075a3**; оба совпадают с main. Все signing/version helpers и android-preview.json также совпадают по blob SHA.
- Репозиторий не содержит tracked .jks/.keystore/.p12/.pfx/.key/key.properties/signing-secret JSON. Значения secrets не читались; внешняя deployment policy проверена: единственный разрешённый ref — branch main.
- README сохраняет одну действующую download section; 2 уникальные записи foundation и 2 блока roadmap сохранены дословно; остальные блоки присутствуют в main. Markdown hardbreaks исторических записей сохранены, проверка diff игнорирует только blank-at-eol.
- Виртуальный merge подготовленного #5 с неизменённым #6 подтвердил только README, ROADMAP и add/add FLUTTER-SYNC-HANDOFF-2026-11-23.md; изменений refs/worktree #6 не было. Dart/asset-конфликтов в пробнике нет. Это аудит зависимости, не подготовка/слияние #6 и не новая full-native QA.
- Основная рабочая копия автора остаётся feature/issue-2-native-calendar; работа #5 изолирована в merge-review-pr5.
