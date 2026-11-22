# Flutter entry card · «Открой свой декабрь»

This folder is a **portable UI candidate**, not a standalone Flutter app. Sources of the real «ВтороеКрыло» app are not available on the connected GitHub account, so no production APK was modified.

## Files

- [lib/advent_entry_card.dart](lib/advent_entry_card.dart) — entry widget on the home screen.
- [assets/advent/hero_tree.webp](assets/advent/hero_tree.webp) — **the exact approved glass 3D Christmas tree** from the hero of the calendar's `index.html`.
- [UX spec (RU)](../docs/flutter-entry-card.md) and [ROADMAP](../docs/ROADMAP.md).

## Host integration

Copy `lib/advent_entry_card.dart` and `assets/advent/hero_tree.webp` into the host project (the latter at `assets/advent/hero_tree.webp`), then register the file in the host's `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/advent/hero_tree.webp
```

Register Yeseva One and Roboto with the host's own font-licensing/asset process, or accept platform fallbacks.

Example (the native calendar page is planned but not implemented here):

```dart
AdventEntryCard(
  daysUntilNewYear: campaignClock.daysUntilNewYear,
  onOpen: () {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const AdventCalendarScreen(),
      ),
    );
  },
)
```

**Important:** `AdventCalendarScreen` is a placeholder for the **future native full-screen calendar**, not a working class in this repository. The entry card must route to a **normal page**, not a modal bottom sheet. Events/advice *within* that page continue to use bottom sheets.

The banner has **no openedDays/progress or “Открыто N из 31”**. The host provides the days remaining to 2027 in the campaign's timezone, and updates it on date changes.

## Status

- The screenshot-based HTML placement prototype is in the conversation artifacts, **not this public repository**: publishing an internal host screenshot would require permission.
- Source updated; **not yet checked with Flutter SDK** or connected to the real app.
- The approved full Advent Calendar `../index.html` is unchanged.
