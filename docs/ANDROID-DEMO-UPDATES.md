# Android demo: постоянная подпись и обновления

> **Этап 1/2 · 24.11.2026:** main edf180b синхронизирован с #6; подготовленная
> main-source схема и main-only signing policy сохранены. Только быстрые проверки;
> новая подпись, APK build, signed upgrade и публикация не запускались.
> Существующий Release 0.1.132.1/code13203 остаётся действующим.
> [Объём подготовки и этап 2](PR6-STAGE1-SYNC-2026-11-24.md).

> **Подготовка PR #6 · 24.11.2026:** #5 слит автором; #6 теперь направлен на main.
> После merge #6 publisher принимает также успешный push main того же Flutter
> workflow ID 427003215. Все четыре CI jobs обязательны и выполняются на main.
> Policy отвергает fork/иной workflow/неподходящий event+branch/неполные gates;
> main SHA дополнительно проверяется на принадлежность истории main.
> Publisher/helper checkout фиксируется на доверенном main commit, environment
> по-прежнему только refs/heads/main, PR не получает ключ. Merge-аудит использует
> точный sourceSha, не зависит от сохранения слитых feature-веток и требует exit 0.
> Нумерация workflow, ключ, appId, fingerprint, checksum и signed install-r gate
> сохранены. Main-source обновляет README/metadata только main, без зависимости
> от native-ветки. [Финальная готовность/CI и новый update proof](PR6-MERGE-READINESS-2026-11-24.md).
> Реальный первый main-source run возможен после отдельного разрешения merge #6;
> до него обновлённый package проверяется и подписывается через существующий PR path.

Дополнение к технической стабилизации от **24 ноября 2026**. Визуальный MVP и Flutter-package не меняются. Production-подпись «ВторогоКрыла» не используется, магазина нет.

## Исходное состояние и текущий статус

Проверен опубликованный APK CI #122: applicationId `com.example.advent_demo`, versionName `1.0`, versionCode `1`, сертификат Android Debug с временным ключом runner. Разные runner не обязаны иметь тот же сертификат; такой APK не обеспечивает безопасные последующие обновления.

**Постоянная подпись настроена.** 24 ноября 2026 создан environment secret, политика проверена: только branch main. Приватные временные файлы удалены. Публичный SHA-256 сертификата: `509461ec29c2ca387c2399a1f510e807a0818a97e873dbee4ba83cb71db7eaba`.

**Первый реальный signed-upgrade PASS:** [защищённый CI probe](https://github.com/hoseantonio85-art/advent-calendar/actions/runs/45395638381), обычные release APK **12302 → 12303**, один applicationId/cert, UID 10148, raw opened 1/3 и saved 3, видимые 2/31 и совет «Оставь место чуду» сохранены. Установка `adb install -r`, без uninstall/clear/reset. Это API35 x86_64 эмулятор, не физический телефон.

**Критерий готовности подтверждён 24 ноября 2026 реальным обновлением двух независимых CI-публикаций: 12403 → 12503.** Вторая проверка скачала именно предыдущую опубликованную APK и проверила её SHA-256, создала данные через обычный UI, затем выполнила adb install -r. Удаления/очистки/повторного копирования данных не было.

| Поле | Первая опубликованная версия | Следующая версия |
|---|---|---|
| applicationId | com.example.advent_demo | com.example.advent_demo |
| versionName | 0.1.124.1 | 0.1.125.1 |
| versionCode | 12403 | 12503 |
| подпись | постоянная Advent Demo | тот же сертификат |
| исходник APK | a70dde50db2d132eb3105b8b846dfd4ad3104879 | a704dbaaa86c5d027796403a9be713ac80bcc3e8 |
| ARM64 APK | 17.26 MiB | 17.26 MiB |

**Результат после обновления:** UID 10067 не изменился; исходные bool-факты opened дней 1/3 и saved дня 3 совпали до/после; в новом процессе UI показал **2 / 31** и избранный совет **«Оставь место чуду»**. [Публичный JSON-тест](https://github.com/hoseantonio85-art/advent-calendar/releases/download/android-preview-45397779151/upgrade-report.json) · [подписанные версии/fingerprint](https://github.com/hoseantonio85-art/advent-calendar/releases/download/android-preview-45397779151/demo-signing.json). SHA-256 прежней APK в доказательстве совпал с candidateChecksum предыдущего Release, новой — с candidateChecksum текущего Release.

**[Скачать актуальный ARM64 APK](https://github.com/hoseantonio85-art/advent-calendar/releases/download/android-preview-45397779151/advent-calendar-test-release-arm64.apk)** · [предыдущая APK проверенной пары](https://github.com/hoseantonio85-art/advent-calendar/releases/download/android-preview-45397779151/advent-calendar-upgrade-baseline.apk) · [новая APK проверенной пары](https://github.com/hoseantonio85-art/advent-calendar/releases/download/android-preview-45397779151/advent-calendar-upgrade-candidate.apk). Пара содержит ARM64+x86_64; основной компактный APK — только ARM64 с тем же applicationId/candidate code/сертификатом.

Проверка между публикациями выполнена на **Android API28 x86_64 эмуляторе** с обычными release APK из lib/main.dart. Первичная signed-пара 12302 → 12303 также прошла [API35 probe](https://github.com/hoseantonio85-art/advent-calendar/actions/runs/45395638381). На физическом ARM64 телефоне тест не выполнялся; это не оценка производительности телефона. Дата 15 декабря задана только тестовому устройству; APK не содержит переключателя даты/QA entrypoint. Для CI software GPU используется существующий renderer override, настройки телефона/продуктовый дизайн не менялись.

[Полный CI #124](https://github.com/hoseantonio85-art/advent-calendar/actions/runs/45394222577) и [#125](https://github.com/hoseantonio85-art/advent-calendar/actions/runs/45397779151) успешны: 2 теста нумерации, проверка отсутствия приватного signing-материала в tracked files, 67 unit/widget (3 visual включены отдельным прогоном), 29 visual, flutter analyze пакета/demo, web, native Android, release/profile и update smoke. [Публикация первой версии](https://github.com/hoseantonio85-art/advent-calendar/actions/runs/45417058596) и [следующей](https://github.com/hoseantonio85-art/advent-calendar/actions/runs/45420936409) отдельно проверили подпись и install-r перед выдачей ссылок.

Исправления этого этапа затронули сборочную инфраструктуру: постоянную подпись, версии, UID parser/ADB readiness/clock совместимость тестового Android и CI preview-теги с ограниченным GITHUB_TOKEN. Новая матрица использует стабильный поддерживаемый runtime для install-теста, отдельный native CI сохраняет API35. Flutter lib/дизайн/контент/пользовательские storage-ключи не менялись. Версия/подпись реального «ВторогоКрыла» по-прежнему принадлежат хосту; production/store-выпуска и merge PR не было.

Основные файлы: .github/workflows/flutter.yml, android-preview.yml и android-upgrade-probe.yml; tools/demo-android-version.cjs и его тест; configure-demo-android.cjs, provision-demo-signing.cjs, sign-demo-apks.cjs, android-demo-upgrade.py, check-demo-signing-source.cjs; example pubspec, APK audit, .gitignore, HOST-INTEGRATION/PHYSICAL-ANDROID-QA и летопись. Приватные ключи/пароли не включены ни в один из этих файлов или артефактов.

## Постоянная demo-идентичность

- ApplicationId навсегда `com.example.advent_demo` для этой линии demo. Генерируемый Gradle-файл проверяется сборочным helper; изменение id прерывает сборку.
- Отдельный случайный RSA-3072 PKCS12-ключ, alias `advent-demo`, сертификат на 30 лет. Это test/demo, не Android Debug и не production-ключ хоста.
- Единственное постоянное хранение приватного материала — environment secret **ADVENT_DEMO_SIGNING** в GitHub environment **advent-demo-signing**, с deployment branch policy **только branch main**, без PR refs. Secret — зашифрованный GitHub Actions secret, не repository variable.
- Обычный PR CI не получает этот environment/secret. Подписание выполняет доверенный workflow из default branch; из PR скачиваются только проверенные APK/инвентарь, скрипты PR с секретом не запускаются.
- Во время подписания ключ декодируется в случайный каталог RUNNER_TEMP с mode 0700, файл 0600. Пароли передаются Android signer через env, не CLI-аргументы/логи. Каталог удаляется в finally **до запуска APK/эмулятора**. Артефакты/репозиторий не содержат ключей/паролей. Публичный fingerprint сертификата публиковать допустимо.
- Нет fallback на случайную подпись и автоматической регенерации. Следующие публикации проверяют совпадение fingerprint с предыдущей постоянной линией и увеличение versionCode. Если секрет потерян — остановить публикацию и согласовать переход; новый ключ не создаётся молча.

## Одноразовая настройка администратором

В обычном GitHub CLI войти в аккаунт с доступом к environments и environment secrets этого репозитория. Учётные данные не отправлять в чат. Затем из доверенной рабочей копии:

```text
node tools/provision-demo-signing.cjs
```

Helper использует стандартные `gh api`/`gh secret` без извлечения токенов. Создаёт выделенное окружение с единственной разрешённой веткой main (или проверяет существующее), отказывается заменить уже существующий ключ. Генерация выполняется в защищённом временном каталоге рабочего компьютера, загрузка — stdin в `gh secret set`, затем временные файлы удаляются даже при ошибке. В выводе только публичный fingerprint. На Windows используется установленный OpenSSL из Git for Windows; дополнительно Java/Android SDK для provisioning не нужны.

После настройки повторить/запустить `Publish Android preview` с успешным source_run_id текущего Flutter CI. Не запускать provisioning на каждый build. Environment и секрет должны сохраняться между сборками.

## Нумерация

В существующем workflow **Flutter foundation**, ID 427003215:

```text
baselineVersionCode = run_number * 100 + run_attempt * 2
candidateVersionCode = baselineVersionCode + 1
versionName = 0.1.<run_number>.<run_attempt>
```

Разрешены attempts 1–49; неправильные значения и Android-limit 2 100 000 000 прерывают сборку. Повторный attempt и следующий run дают больший code. Пропуски номеров нормальны; понижать/обнулять счётчик или заменять workflow с новым namespace без плана нельзя. Publisher независимо проверяет id/code/name каждого APK и не публикует старый номер поверх нового. Debug, profile и основной ARM64 release одной публикации получают один candidate code и один сертификат. Локальное `version: 0.1.0+1` — только fallback несдаваемой локальной сборки; CI всегда передаёт вычисленные build-name/build-number.

## Реальный тест установки поверх

CI собирает **две обычные release APK из lib/main.dart**, ABI arm64-v8a+x86_64, с соседними codes. Это не integration_test entrypoint и не версия с QA-переключателями. Оптимизированный основной ARM64 APK остаётся отдельным вариантом с тем же applicationId/candidate code/сертификатом.

1. Свежий изолированный API35 x86_64 Android-эмулятор; дата 15 декабря 2026 задаётся только устройству теста. Установить baseline, открыть настоящий интерфейс, дни 1/3, сохранить совет 3.
2. Подтвердить в UI **2 / 31** и избранный совет. Через настоящий DataStore проверить bool-факты пользовательского namespace standalone-demo, сохранить UID.
3. Остановить процесс и выполнить **adb install -r candidate.apk**. В сценарии нет uninstall, clear/reset или копирования данных заново.
4. Подтвердить тот же UID и прежние raw-факты, запустить новый процесс, проверить **2 / 31** и избранный совет в UI второй версии.
5. При первой постоянной подписи используется созданная пара соседних codes. Для следующих публикаций baseline — **настоящая предыдущая опубликованная candidate APK**, скачанная по проверенному SHA-256; новая версия должна иметь больший code. Тест допускает совместимое изменение текстов, но проверяет прежние campaign/day ids и сохранённые данные.
6. Повторить этот тест после постоянного подписания в main CI. Публикация разрешена только после PASS; реальные signed baseline/candidate APK, публичные версии/fingerprint, JSON-доказательство и PNG доступны вместе со сборкой.

**Для обычных обновлений брать APK из GitHub Releases/кнопки README.** Сырые build-артефакты Actions до защищённой публикации имеют временную подпись и не являются линией безопасных demo-обновлений.

Source PR smoke проверяет упаковку/сохранение с build-local сертификатом; **он не подменяет** финальную проверку постоянной подписи. Эмулятор — реальная Android-установка APK, но не физическая ARM64 QA/замер производительности. На телефоне автора нужно дополнительно проверить обновление двух выданных APK при обычных условиях.

## Переход со старой debug-подписи

Android не позволяет заменить старую подпись новым ключом простым увеличением versionCode. Приватный ключ старых случайных runner не сохранён; восстановление этой идентичности не обещается.

Один раз пользователь вручную удаляет старое demo и устанавливает APK с постоянным ключом. **Удаление стирает старые локальные просмотры, избранное и claims; переноса этих данных пока нет.** Автоматического удаления приложения/обнуления данных или утверждения о сохранении при этом переходе нет. Действие на телефоне автора выполняется только им осознанно. После перехода следующие APK устанавливаются поверх, без удаления. AppId остаётся прежним; не подменяем его ради скрытого сброса/параллельной установки.

## Интеграция в «ВтороеКрыло»

Подпись, applicationId, versionName/versionCode и выпуск принадлежат **хост-приложению**. Advent подключается как Flutter-package; demo Gradle/signing helpers, CI secrets, идентификатор standalone-demo и номера demo в хост не переносятся. Сценарий обновления пакета и сохранения пользовательских ключей — [HOST-INTEGRATION.md](HOST-INTEGRATION.md).

## Тег тестовой публикации и исходники APK

Для least-privilege GITHUB_TOKEN тег android-preview-* указывает на доверенный publisher commit main. GitHub запрещает такому токену создавать некоторые теги на стороннем PR commit с изменёнными workflow; дополнительный PAT в CI не вводится. **Исходники APK — sourceSha**, явно указанный в Release/README и docs/android-preview.json; publisherCommit указывает отдельно на конфигурацию публикации. Автоматический Source code ZIP этого тестового тега не является исходником Flutter APK. Для воспроизведения использовать sourceSha, для интеграции — согласованный ref package после review. Checksums и signed-upgrade доказательства относятся к выданным APK, не к ZIP исходников тега.

## Повторная проверка после обновления #6 на main

24.11.2026: [CI #131](https://github.com/hoseantonio85-art/advent-calendar/actions/runs/45448214632) и [trusted publisher](https://github.com/hoseantonio85-art/advent-calendar/actions/runs/45451293476) success.
Реальная публичная версия 0.1.125.1/code12503 обновлена до 0.1.131.1/code13103:
тот же certificate/UID, opened/saved/2 из 31/избранный совет сохранены, install -r
без удаления/очистки. [JSON-доказательство](https://github.com/hoseantonio85-art/advent-calendar/releases/download/android-preview-45448214632/upgrade-report.json). Main-only policy ключа
проверена: единственная deployment branch main; secret не читался/не менялся.
Main-source path подготовлен в #6, его первый реальный запуск — после отдельного
одобрения merge. [Готовность и Git audit](PR6-MERGE-READINESS-2026-11-24.md).

## Этап 2/2 · 24 ноября 2026: новое подписанное обновление

[CI #133](https://github.com/hoseantonio85-art/advent-calendar/actions/runs/45462441956) и [trusted publisher](https://github.com/hoseantonio85-art/advent-calendar/actions/runs/45465732090) success. Реальная предыдущая
публичная APK 0.1.132.1/code13203 заменена 0.1.133.1/code13303 через adb install -r:
тот же appId/cert/UID, raw opened/saved, 2 из 31 и избранный совет сохранены.
[JSON proof](https://github.com/hoseantonio85-art/advent-calendar/releases/download/android-preview-45462441956/upgrade-report.json) · [новый ARM64 release](https://github.com/hoseantonio85-art/advent-calendar/releases/download/android-preview-45462441956/advent-calendar-test-release-arm64.apk).
Main-only signing policy сохранена; ключи не копировались/не менялись.
Первый реальный main-source run проверить после отдельно одобренного merge,
без обхода provenance/gates/environment. [Готовность и ограничения](PR6-STAGE2-READINESS-2026-11-24.md).
