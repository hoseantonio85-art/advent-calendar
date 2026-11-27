# Финальная доводка · 27 ноября 2026

База: main 3af07ac19ab52d8104bea8fe69b638a59291c2b7. Отдельный PR;
merge только после разрешения автора. Календарь в целом принят в host.

## Состав

- 14: **Москва, ул. Нижние Мнёвники, 10А**; отдельный mapUrl
  https://yandex.com/maps/org/navka_arena/26422616706/.
- 17: **БКЗ, корпус Г**; 18: **Елка возле переговорной Б.39.04**.
- Master content/calendar_2026.json → генератор → standalone index.html и Flutter
  asset. 31/14/17, все прочие тексты, даты/время, иллюстрации и Bento прежние.
  Исходные approved hashes сохранены; тест обратной подстановки ровно трёх мест
  и описания 14 декабря/удаления mapUrl доказывает отсутствие других контентных изменений.
- Место с mapUrl кликабельно: тот же блок + маленький внешний значок, без кнопки
  или URL в тексте. HTTPS без credentials/whitespace проверяется в генераторе и
  Flutter loader. Без mapUrl прежний статичный блок. CSV получил отдельный map_url.
- На доступном advice в правом верхнем углу один символ: star либо saved heart.
  Сохранение/удаление совета не меняет позицию и логику favorites.
- Route открывается сразу; запись/чтение прогресса и surprise claim завершаются
  асинхронно. Ошибка не создаёт ложного прогресса; устаревший ответ не заменяет
  новые данные. Entrance 360 ms вместо 420, reverse 300 ms, жесты/Back/reduced
  motion/layout сохранены.
- Advice Share: симметричная подложка, clip по форме, видимая область касания
  минимум 48 dp; прежние цвет/шрифт/действие. Pressed snapshot проверяет, что
  изменённые пиксели не выходят за границу кнопки на 320/360/390/430 dp.

## Зависимость и интеграция

Добавлена [url_launcher ^6.3.2](https://pub.dev/packages/url_launcher/versions/6.3.2)
(Flutter team). Проверенные locks: url_launcher 6.3.2, android 6.3.35, iOS 6.4.2,
macOS 3.2.6; остальные url_launcher backends/platform_interface уже были в locks.
Package ^6.3.2 требует Dart >=3.6 / Flutter >=3.27; зафиксированный Android
backend >=3.12 / Flutter >=3.44, ниже существующего lock floor >=3.13 / >=3.47.
Обязательных новых параметров/методов host API нет. Стандартный launchUrl с
LaunchMode.externalApplication вызывает OS handler HTTPS: Яндекс Карты при
соответствующей ассоциации либо внешний браузер. Наличие приложения Яндекс Карт
не обещается. Нет embedded webview, canLaunchUrl/preflight или новых permissions.
false и исключение обрабатываются существующим unavailable/error UI; повтор
доступен. Host выполняет pub get и обычную native-сборку со своим lock/SDK.

## Проверки и ограничения

Локально: генерация/--check, полная сверка master/HTML/Flutter/17 art, content
tests и version/publication policy tests, parity прогресса и аудит tracked keys.
Flutter analyze, unit/widget, snapshots/pressed pixel regression, browser map
anchor, Android motion/release/audit/update выполнены штатным CI этого PR.
**CI #142 завершён успешно**, [полный запуск](https://github.com/hoseantonio85-art/advent-calendar/actions/runs/45973890835).
Code SHA первой итерации **a4f9aa09a4359da777ba93b3551a22a138c471a3**, package version 0.1.0.
Документальный follow-up не меняет проверенные runtime/tests/assets/locks.

- Package + demo: flutter analyze без замечаний. Unit/widget: **81 passed**, три
  visual-only сценария пропущены в обычном запуске и включены следующим прогоном.
- Visual-прогон: **29 passed**, 42 Flutter snapshot и 19 HTML reference.
  Pressed pixel regression на четырёх ширинах: overlay видим, ни одного
  изменённого пикселя за границей Share. Все 12 входных v9 и 8 countdown снимков
  совпали пиксель в пиксель с прошлой принятой поставкой. Event-1/history/finale
  также совпали. В surprise-sheet изменились только 59 пикселей звезды advice-3
  на затемнённом календаре позади sheet, согласно новой логике индикатора.
- Browser: адреса 14/17/18 и optional HTTPS anchor, generated variants, storage/
  progress parity. [Снимки](https://github.com/hoseantonio85-art/advent-calendar/actions/runs/45973890835/artifacts/15185414354),
  [browser evidence](https://github.com/hoseantonio85-art/advent-calendar/actions/runs/45973890835/artifacts/15185648770).
- Android API35 integration: 360 ms, drag/Back/close/reduced motion, 24 stress
  cycles, рестарт; [motion evidence](https://github.com/hoseantonio85-art/advent-calendar/actions/runs/45973890835/artifacts/15186572474).
  Debug/software-GPU timings — диагностика, не физический FPS/PROFILE benchmark.
- Android release ARM64: **18 143 199 bytes**, debuggable=false, min24/target36,
  applicationId com.example.advent_demo, versionName 0.1.142.1 / code14203.
  В собранной APK runtime JSON побайтно совпал с generated source: все три адреса
  и mapUrl на месте; integration_test plugin в release отсутствует.
  [APK ZIP](https://github.com/hoseantonio85-art/advent-calendar/actions/runs/45973890835/artifacts/15187660383), [APK audit](https://github.com/hoseantonio85-art/advent-calendar/actions/runs/45973890835/artifacts/15186179690).
  APK SHA256: 610d5e83b2c76d117d6c34f95869d9d7c563f5ef2d89550a76dffbcdf74dd2b7.
- Реальный adb install -r на API28 x86_64 emulator: **14202 → 14203 PASS**,
  UID прежний, raw opened/saved сохранились, видны 2 / 31 и сохранённый advice-3.
  [Upgrade report/screenshots](https://github.com/hoseantonio85-art/advent-calendar/actions/runs/45973890835/artifacts/15186354617).
  Это две ordinary release APK из данного CI, не обновление постоянной demo #137.
  Их общий тестовый сертификат:
  cab9638b83f1989c54e1e25dd09c098b434965afbb919a6bf8151cb0bb1dc603.

PR не получает постоянный ключ. Доверенный publisher на main не принимает эту
ветку: тестовая APK из CI не равна постоянно подписанной demo 0.1.137.1.
Её нельзя заявлять обновлением постоянной demo без удаления. После разрешённого
merge main workflow штатно выпускает подписанную версию с возрастающим code.
Механизм подписи/публикации и существующие Releases не изменены.

Физический Android с интеграционной сборкой «ВторогоКрыла» здесь недоступен.
Команда host должна подтвердить реальное открытие Яндекс Карт/браузера, возврат
в sheet, Share pressed, отзывчивость и обновление host без потери локальных
данных. Автотест OS adapter/эмулятор не заменяет эту приёмку.

## Уточнение автора · 27 ноября 2026

У 14 декабря убрано название площадки из place/locations: остался только адрес
«Москва, ул. Нижние Мнёвники, 10А». Первое предложение описания:
«Вечер для тех, кто весь год держал риски под контролем, пройдёт на площадке
**«Навка Арена»**». Остальная часть описания и mapUrl прежние. Используется
существующий strong renderer, без изменения UI/шрифтов/контрактов. Master и оба
производных файла пересозданы. Дополнены Flutter/browser-тесты: полный адрес
в одну строку на 320/360/390/430 dp при стандартном масштабе и bold названия в
описании; крупный системный текст по-прежнему может переносить адрес.
CI #142 выше описывает предыдущую итерацию. **[CI #143](https://github.com/hoseantonio85-art/advent-calendar/actions/runs/46000671866) полностью успешен**:
analyze package/demo, 85 unit/widget + 29 visual, HTML one-line/bold/URL, Android
integration/motion/release/audit/update. Проверены прежние 31/14/17 и 17 art.
Из 42 Flutter snapshot 38 попиксельно совпали с CI #142; изменились только
четыре polish-map-14 на 320/360/390/430 dp. Подтверждены одна строка адреса
и bold названия; UI/шрифты/остальные даты не менялись.
Code SHA для передачи: **1d711936b0716a77cf4963f20f59539301863a6c**, package 0.1.0. ZIP того же SHA проверен:
36 runtime-файлов/18 относительных ссылок/17 art соответствуют Git.
[Новые snapshots](https://github.com/hoseantonio85-art/advent-calendar/actions/runs/46000671866/artifacts/15197698294).
[Новая тестовая APK 0.1.143.1, code14303 (ZIP)](https://github.com/hoseantonio85-art/advent-calendar/actions/runs/46000671866/artifacts/15198203244).
[adb install -r 14302 → 14303, сохранение данных](https://github.com/hoseantonio85-art/advent-calendar/actions/runs/46000671866/artifacts/15199710793).
У APK CI debug-подпись; обновление установленной постоянной demo по-прежнему
выпускается только trusted main после разрешённого merge. Ключи/workflows прежние.
Handoff/README/ROADMAP обновлены отдельным docs-only коммитом без нового CI.
