# Flutter entry card · «Открой свой декабрь» · утверждённый UI v9

This folder is a **portable UI candidate**, not a standalone Flutter app. Sources of the real «ВтороеКрыло» app are not available on the connected GitHub account, so no production APK was modified.

## Files

- [lib/advent_entry_card.dart](lib/advent_entry_card.dart) — entry widget on the home screen.
- [assets/advent/entry_fir_v9.webp](assets/advent/entry_fir_v9.webp) — approved v9 cropped pine-and-warm-lights background for the entry card.
- [assets/advent/hero_tree.webp](assets/advent/hero_tree.webp) — 3D tree from the calendar hero; no longer used in the entry card.
- [UX spec (RU)](../docs/flutter-entry-card.md) and [ROADMAP](../docs/ROADMAP.md).

## Host integration

Copy `lib/advent_entry_card.dart` into the host project. The **approved v9 entry card requires the pine WebP background**. Copy the asset and register it in the host's `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/advent/entry_fir_v9.webp
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

The **approved v9** banner has no icon, no 'АДВЕНТ · 2026' capsule and no foreground 3D tree. It shows two lines «Открой свой / декабрь» (Yeseva One 26px / 23px on narrow screens), dark-green pine background with warm lights, height 120px (114px narrow), 16px padding, and a translucent square countdown tile 88×88px (82×82px narrow) with two small holes. The caption `дней до 2027` is a single line. No openedDays/progress/secondary CTA. The host supplies day count in the campaign timezone and updates it on date changes.

**Web reference:** [isolated approved v9 entry card](../docs/prototypes/advent-entry-card-v9.html). The full screenshot-backed HTML is archived privately in the materials library. Do not put the internal app screenshot in this public repository. The Flutter candidate reproduces the geometry, copy and image, **not the HTML snow animation 1:1**.

## Status

- Visual v9 approved by the author. Full screenshot-backed HTML v9 is stored privately in the materials library, **not this public repository**. A safe isolated HTML preview is committed under `docs/prototypes/`.
- Dart candidate updated; **not yet checked with Flutter SDK** or connected to the real app. Register the asset, review image licensing, accessibility and Android rendering before production.
- The approved full Advent Calendar `../index.html` is unchanged.
