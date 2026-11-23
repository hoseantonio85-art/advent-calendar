# Android APK на главной странице GitHub

Кнопка «Скачать APK» находится в начале README на main и в feature-ветке.
Она ведёт на обычный APK в публичном GitHub Release, не на временный ZIP из Actions.
Первый опубликованный файл взят без пересборки из полностью зелёной проверки
45211174588, source b01a141686cc75b2e64c4ab31ff9ee7d36662bd1.

Публикация: .github/workflows/android-preview.yml на default branch main.
После успешного Flutter foundation из нашего PR в feature/issue-2-native-calendar
проверяются принадлежность репозиторию/ветке, workflow id и успех verify/android-motion.
Выгружается только уже проверенный APK. Fork PR, main и непрошедшие проверки не
публикуются. APK из артефакта не исполняется; токен имеет только actions:read и contents:write.

Для каждой проверки создаётся отдельный pre-release android-preview-RUN_ID,
неподвижный source tag, APK advent-calendar-preview.apk и SHA-256 в описании.
Старые опубликованные сборки остаются. README обновляется только между маркерами
android-preview:start/end, остальная летопись сохраняется. Изменение main выполняется
с проверкой актуального родителя, без force; README и docs/android-preview.json
меняются одним коммитом. Более старая проверка не заменяет ссылку на новую.
Разработка в PR #6 не сливается. index.html и GitHub Pages не изменяются.

Ручной запуск Publish Android preview принимает id полностью успешного source run.
Статус, исходный SHA, ссылка и checksum текущей сборки: main/docs/android-preview.json.
Сейчас механизм рассчитан на текущую feature-ветку; при переносе разработки на другую
ветку следует явно обновить фильтр и проверку источника в workflow.

APK остаётся demo с отладочной подписью CI. При конфликте подписи может потребоваться
удаление старого demo; это стирает его локальный прогресс. Production-подпись хоста
этим механизмом не определяется.
