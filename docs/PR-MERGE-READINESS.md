# PR #5/#6: готовность и безопасная последовательность

> **Этап 2/2 завершён · 24.11.2026:** полный CI #133 и signed update 13203 → 13303
> прошли, приложение/HTML/визуал не менялись. [Финальный отчёт](PR6-STAGE2-READINESS-2026-11-24.md).
> PR готов к отдельному одобрению автора; не слит. Ниже сохранены прежние этапы.

> **Последний запрос · этап 1/2, 24.11.2026:** повторно получены свежие refs;
> main edf180b обычным merge внесён в #6 без новых конфликтов. Только быстрые
> проверки, публикация с `[skip ci]`, без нового полного QA/Android/APK.
> [Текущий отчёт этапа 1 и отложенный этап 2](PR6-STAGE1-SYNC-2026-11-24.md).
> Ранее выполненные полные CI и signed update ниже сохранены как история;
> они не означают запуска этапа 2 по текущему запросу. PR #6 не слит.

> **Актуальный этап · 24.11.2026:** автор слил #5, main dad3144 прошёл CI #130
> и Pages. #6 перенаправлен на main и обновляется обычным merge, конфликты трёх
> документов решены с сохранением обеих историй. Полный CI, signed APK update,
> подготовка публикации main-source и итоговый Git audit:
> [текущий отчёт #6](PR6-MERGE-READINESS-2026-11-24.md).
> Ниже дословно сохранён прежний аудит и порядок **до** merge #5; это история.
> Разрешение подготовить/пушить ветку #6 получено от автора, разрешения слить #6 нет.

24 ноября 2026. Код проверенной сборки 13ec6164ea9196a716627d7c52388e7e61f12c1e, [CI #122](https://github.com/hoseantonio85-art/advent-calendar/actions/runs/45382287564). Автоматического слияния не было и не настроено.

- #5: feature/issue-3-advent-foundation, head 704aa862aaa893151ff17f46c23869a7b2a9ab27 → main. Исторический CI #66 успешен; актуальный JSON уже **31/14/17**. Это foundation, не готовое пользовательское приложение отдельно от #6. **Полный Git-пробник подтвердил конфликты README.md и docs/ROADMAP.md.** Ранний изолированный файловый пробник не был достаточным доказательством: он не учитывал полную историю merge-base.
- #6: feature/issue-2-native-calendar → foundation. Draft, содержит всю последнюю реализацию, вариант А и тестовый release. GitHub mergeable=true относится к **этому base**, не к будущему main. При проверке против main найдены README.md, docs/ROADMAP.md и add/add в docs/FLUTTER-SYNC-HANDOFF-2026-11-23.md. Dart/asset-конфликтов на проверенных SHA нет. После любого обновления base нужны новая проверка и явное одобрение.
- main: актуальный HTML вариант А, 31/14/17; в этом техническом этапе менялись публикация/документация, не публичный HTML. До merge не подменять им Flutter-код без branch/ref.

## Фактический полный Git-пробник

[Скачиваемый отчёт](https://github.com/hoseantonio85-art/advent-calendar/releases/download/android-preview-45382287564/pr-merge-audit.txt). В CI checkout с полной историей выполнен merge-tree --write-tree для main + #5 и main + #6; это создаёт временные tree objects, **не merge-коммиты и не движения refs**. Exit 0 — механически чисто, 1 — перечисленные конфликты; иной код — проверка не подтверждена. Проверяется конкретный набор SHA в отчёте; README download-метаданные и последующие записи могут измениться после него.

```text
git version 2.56.1
main c1001797adf56a11e5ac75434396bc53f79039f2
feature/issue-3-advent-foundation 704aa862aaa893151ff17f46c23869a7b2a9ab27
feature/issue-2-native-calendar 13ec6164ea9196a716627d7c52388e7e61f12c1e

PAIR: origin/main + origin/feature/issue-3-advent-foundation
e22eded394be9b68420236d8c5e9344089d0acb2
100644 b4d2c7ba68db60eca2cc1007d8aea2a354909ce7 1	README.md
100644 f6eae73106e2c72ecacbec59ce703fd4f0399e1b 2	README.md
100644 5adc7bc7385572a26aad9d6b272d8f6bba21c9ad 3	README.md
100644 20a74c1a703784c7b44cfdccb41d575f0d58bf21 1	docs/ROADMAP.md
100644 fcd162e68d62980ef3120dcc77a4b579209bef96 2	docs/ROADMAP.md
100644 19672156404a01c136b8eaf264a5a2fdabeb8244 3	docs/ROADMAP.md

Auto-merging README.md
CONFLICT (content): Merge conflict in README.md
Auto-merging docs/ROADMAP.md
CONFLICT (content): Merge conflict in docs/ROADMAP.md
merge-tree exit: 1 (0 clean, 1 conflicts, other indeterminate)

PAIR: origin/main + origin/feature/issue-2-native-calendar
5f429a82f0ca7eb63af2af327e08a58e0e54b2c8
100644 b4d2c7ba68db60eca2cc1007d8aea2a354909ce7 1	README.md
100644 f6eae73106e2c72ecacbec59ce703fd4f0399e1b 2	README.md
100644 1f3005d0487da0bced008dcfce6d93652fa4d165 3	README.md
100644 5d021082b2256df1cbaf5def12327b8f4117dbd4 2	docs/FLUTTER-SYNC-HANDOFF-2026-11-23.md
100644 ede625a7dab79b0d2da68589d938c6a421470493 3	docs/FLUTTER-SYNC-HANDOFF-2026-11-23.md
100644 20a74c1a703784c7b44cfdccb41d575f0d58bf21 1	docs/ROADMAP.md
100644 fcd162e68d62980ef3120dcc77a4b579209bef96 2	docs/ROADMAP.md
100644 17dda6a0bfbcf11bd8d632d10c24f30ad21e066b 3	docs/ROADMAP.md

Auto-merging README.md
CONFLICT (content): Merge conflict in README.md
Auto-merging docs/FLUTTER-SYNC-HANDOFF-2026-11-23.md
CONFLICT (add/add): Merge conflict in docs/FLUTTER-SYNC-HANDOFF-2026-11-23.md
Auto-merging docs/ROADMAP.md
CONFLICT (content): Merge conflict in docs/ROADMAP.md
merge-tree exit: 1 (0 clean, 1 conflicts, other indeterminate)
```

## Порядок после разрешения автора на слияние

1. Fetch свежих refs в чистой отдельной рабочей копии. Проверить актуальные main/#5/#6 и сохранить ветки. Для #5 воспроизвести пробник: git merge-tree --write-tree origin/main origin/feature/issue-3-advent-foundation. Если API и Git расходятся — обновить base/merge state в GitHub и не считать единственный bool разрешением слияния.
2. В review-worktree #5 обновить main обычным merge, если нужен, без rebase/reset/force. Для README/ROADMAP сохранить **обе** летописи, один актуальный download block и текущий статус сверху; прежние планы — явно история. Бинарные добавления main и HTML не заменять старым snapshot. Проверить content verifier и CI на обновлённом #5, затем **отдельное одобрение** merge #5 → main.
3. Не удалять foundation-ветку до retarget #6 на main. После merge #5 retarget #6, обновить main в review-worktree #6 и разрешить оставшееся семантически. В add/add handoff сохранить обе записи как датированную историю, сверху дать текущую сводку; не отбрасывать подтверждённые уточнения main. Не применять blanket ours/theirs к domain/host/данным. Сохранить current eligibleProgress (raw known opened + полная московская дата), независимый surprise claim, 31/14/17 и последние визуально принятые виджеты.
4. На конечном merge-base #6 выполнить полный CI, ARM64 audit и QA. Сравнить lib/asset hashes; layout/art не менять. Проверить, что README содержит единственный управляемый блок и новые исторические записи не потеряны. Затем **отдельное одобрение** merge #6 → main.
5. Сохранить links/теги/протокол. Production/integration требуют отдельной физической QA и исходников хоста; test release не становится store-релизом после Git merge.

Пример подготовки без правки рабочего дерева автора:

```text
git fetch origin
git worktree add ../advent-foundation-review -b review/foundation-main origin/feature/issue-3-advent-foundation
git -C ../advent-foundation-review merge --no-commit --no-ff origin/main
```

После проверки не завершать/пушить merge автоматически. Git CLI в среде Codex не прошёл TLS handshake с github.com; поэтому полный пробник перенесён на GitHub Actions, а не подменён догадкой. Никакие чужие branch refs не переписывались.
