# Финальная доводка · 27 ноября 2026

База: main 3af07ac19ab52d8104bea8fe69b638a59291c2b7. Отдельный PR;
merge только после разрешения автора. Календарь в целом принят в host.

## Состав

- 14: **Навка Арена · Москва, ул. Нижние Мнёвники, 10А**; отдельный mapUrl
  https://yandex.com/maps/org/navka_arena/26422616706/.
- 17: **БКЗ, корпус Г**; 18: **Елка возле переговорной Б.39.04**.
- Master content/calendar_2026.json → генератор → standalone index.html и Flutter
  asset. 31/14/17, все прочие тексты, даты/время, иллюстрации и Bento прежние.
  Исходные approved hashes сохранены; тест обратной подстановки ровно трёх мест
  и удаления mapUrl доказывает отсутствие других контентных изменений.
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
anchor, Android motion/release/audit/update запускаются штатным CI этого PR.
Итоговые ссылки/результаты будут добавлены после завершения проверки.

PR не получает постоянный ключ. Доверенный publisher на main не принимает эту
ветку: тестовая APK из CI не равна постоянно подписанной demo 0.1.137.1.
Её нельзя заявлять обновлением постоянной demo без удаления. После разрешённого
merge main workflow штатно выпускает подписанную версию с возрастающим code.
Механизм подписи/публикации и существующие Releases не изменены.

Физический Android с интеграционной сборкой «ВторогоКрыла» здесь недоступен.
Команда host должна подтвердить реальное открытие Яндекс Карт/браузера, возврат
в sheet, Share pressed, отзывчивость и обновление host без потери локальных
данных. Автотест OS adapter/эмулятор не заменяет эту приёмку.
