---
name: flutter-verify
description: >-
  Use when verifying changes to the Moonleaf Flutter app. Defines the fast
  verification loop — `flutter analyze` + `flutter test` (and hot reload while
  `flutter run` is live) — and the rule that `flutter build apk`/`appbundle`
  must NOT be run for routine changes. Only build release artifacts when
  explicitly preparing a Play Store release or when the user asks.
---

# Verifying Flutter changes (fast loop, no APK build)

**Do not run `flutter build apk` / `flutter build appbundle` to check ordinary
code changes.** Full builds are slow and unnecessary for verifying Dart edits.

## Default verification loop (use this every time)

1. `flutter analyze` — must report **No issues found**. Fixes type/compile
   errors and lints quickly.
2. `flutter test` — runs widget/unit tests.
3. If an app is already running via `flutter run`, rely on **hot reload** (`r`)
   / **hot restart** (`R`) to see the change — no rebuild needed.

This loop catches virtually all problems in Dart/UI/architecture changes.

## When a full build IS appropriate

Only run `flutter build apk`/`appbundle` (or `flutter build ios`) when:

- The user explicitly asks to build, package, or release.
- You are **preparing a Play Store / App Store release** (then build a signed
  `--release` app bundle: `flutter build appbundle --release`).
- You changed **native/Gradle/manifest/signing** config (e.g. `build.gradle.kts`,
  `AndroidManifest.xml`, plugins, `pubspec.yaml` deps/assets/fonts) and need to
  confirm the native side still assembles. Even then, build **once** after the
  change — not on every subsequent edit.

## Notes

- Adding assets/fonts to `pubspec.yaml` only needs `flutter pub get` + a hot
  restart to take effect; it does not require a full APK build to verify.
- Prefer `flutter run` on a device/emulator for visual confirmation over
  building an APK and installing it manually.
- If you do need to sanity-check compilation without packaging, `flutter analyze`
  (and optionally `flutter build apk --debug` **once**) is enough — avoid
  repeating it per change.
