# Moonleaf

**Read by moonlight.** A beautiful, distraction-free book reader built with Flutter.

## Features

- 📖 **Book-style page flip** — chapters are paginated to fit the screen and
  turned with a real paper-curl effect: **swipe** to flip within a chapter, or
  use the **footer arrows**, which also roll over to the next/previous chapter
  at the page edges.
- 🎨 **Reading palettes** — Light, Sepia and Night reading surfaces, independent
  of the app theme.
- 🔠 **Typography controls** — adjustable font size, line height, and a
  serif/sans toggle (Lora for reading, Inter for UI; both bundled locally).
- 🗂️ **Library & chapters** — browse bundled public-domain books, jump between
  chapters from the table of contents.
- 📄 **Import your own PDFs** — bring in a PDF and read it in a Moonleaf-styled
  PDF reader: the **original pages are rendered as-is** (layout, fonts and images
  preserved), one per screen, on the chosen palette/warmth surface with the same
  progress footer and page controls as the bundled books. Your place is
  remembered per PDF.
- 🔖 **Progress** — your place is remembered per book and surfaced in
  "Continue reading".

## Architecture

MVVM + SOLID. All app code lives under `lib/src/` —
`models / services / viewmodels / views / components / theme / utils / data`.
Views depend on ViewModels, ViewModels depend on service **interfaces**
(`IXxx`), and concrete wiring happens only in `service_locator.dart`. See the
`moonleaf-architecture` skill for the full conventions.

## Notable dependencies

| Package | Why |
| --- | --- |
| [`provider`](https://pub.dev/packages/provider) | State management / dependency injection across the MVVM layers. |
| [`shared_preferences`](https://pub.dev/packages/shared_preferences) | Local persistence (theme, reading settings, progress) behind `IPreferencesService`. |
| [`page_flip`](https://pub.dev/packages/page_flip) | The paper-curl page-turn animation. It flips page *widgets*; the app paginates chapter text into those pages itself ([`text_paginator.dart`](lib/src/utils/text_paginator.dart)). |
| [`pdfrx`](https://pub.dev/packages/pdfrx) | Renders imported PDF pages (`PdfPageView`) in the Moonleaf-styled PDF reader. |
| [`file_picker`](https://pub.dev/packages/file_picker) | Picking a PDF from device storage to import. |
| [`path_provider`](https://pub.dev/packages/path_provider) | Resolving the app documents directory where imported PDFs are stored. |
| [`cupertino_icons`](https://pub.dev/packages/cupertino_icons) | iOS-style icon glyphs. |

## Getting started

```bash
flutter pub get
flutter run        # on a connected device or emulator
```

## Verifying changes

Use the fast loop (see the `flutter-verify` skill) — no APK build needed for
routine changes:

```bash
flutter analyze    # must report: No issues found
flutter test
```
