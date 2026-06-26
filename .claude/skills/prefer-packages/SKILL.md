---
name: prefer-packages
description: >-
  Use BEFORE writing any non-trivial feature from scratch in the Moonleaf app
  (animations, gestures, parsing, formatting, networking, storage, complex
  widgets, etc.). Check pub.dev for a well-maintained package that already does
  it and prefer wiring that in over hand-rolling. Triggers on phrasing like
  "build/implement/make a <effect/feature>", "from scratch", "page flip",
  "carousel", "charts", "PDF/EPUB", or any custom widget that smells like a
  solved problem.
---

# Prefer a maintained package over building from scratch

When a task could be solved by an existing, maintained pub.dev package, **use
the package** instead of writing the mechanism by hand. Hand-rolled animation/
gesture/parsing code is slow to write, easy to get subtly wrong, and a long-term
maintenance cost. A good package is faster and smarter.

## Decision flow

1. **Name the capability** in package terms ("page-curl flip", "swipe
   carousel", "markdown render", "shimmer skeleton") — not in app terms.
2. **Search pub.dev** for it (WebFetch `https://pub.dev/packages?q=<terms>` or
   `https://pub.dev/packages/<name>`). Note version, last-published date,
   likes/pub points, and the SDK constraint.
3. **Vet** the top candidate against the checklist below.
4. If a candidate passes: `flutter pub add <name>`, confirm it resolves against
   the project SDK, then read the **installed source** in the pub cache to learn
   the real API (pub.dev examples are often thin or stale).
5. Only build from scratch if **no** candidate passes — and say why in your
   summary (e.g. "all candidates are pre-null-safety / abandoned").

## Vetting checklist

- **Resolves** against this project's `environment.sdk` (currently `^3.12.2`) —
  `flutter pub add` must succeed without forcing downgrades of other deps.
- **Maintained**: published within ~2 years; not flagged discontinued.
- **Healthy signal**: reasonable likes / pub points / popularity; null-safe.
- **Right scope**: solves the core mechanic. It's fine to keep your own glue
  around it (the package owns the hard part; you own the integration).
- **Platforms**: supports the targets you need (Android first here).

## Split the work: package owns the mechanic, you own the glue

Most packages do **one** hard thing and hand you the rest. Keep your domain code.

> Example (already in this app): the **page_flip** package owns the paper-curl
> animation, but it flips *page widgets* — it does not paginate text. So
> [text_paginator.dart](../../../lib/src/utils/text_paginator.dart) still splits
> a chapter into page-sized strings, and
> [reader_view.dart](../../../lib/src/views/reader/reader_view.dart) feeds those
> pages to `PageFlipWidget`. Package = animation; our code = pagination + chapter
> rollover + persistence.

## Fit it to the architecture

A package is a dependency detail, not an excuse to bypass MVVM. Keep package
types **behind the existing layers** (see the `moonleaf-architecture` skill):
wrap data/IO packages behind an `IXxx` service, drive UI packages from the View,
and never let a package type leak into a Model or ViewModel signature.

## Hard exclusions (do NOT add these)

- **`google_fonts` / any runtime font fetching** — fonts are bundled locally in
  `assets/fonts/` on purpose. (Carried over from `moonleaf-architecture`.)
- Anything that pulls a heavyweight transitive native dependency for a trivial
  gain, or that is unmaintained / pre-null-safety.

## After adding a package

- Commit the `pubspec.yaml` **and** `pubspec.lock` change together.
- Verify with the `flutter-verify` loop (`flutter analyze` + `flutter test`).
- Update the README via the `update-readme` skill (new dependency / feature).
