---
name: update-readme
description: >-
  Use AFTER implementing a user-facing feature, adding/removing a dependency, or
  changing how the Moonleaf app is run/configured, to keep README.md accurate.
  Triggers on "update the readme", "document this", "we added a feature/package",
  or whenever a change makes the current README.md stale. Keeps the README a true
  description of what the app does and how to work with it.
---

# Keep README.md current with what we built

The README is the front door. After a meaningful change it must still be **true**.
Update it as the final step of a feature — never invent capabilities that aren't
in the code.

## When to update

Update `README.md` when a change:

- adds/changes a **user-facing feature** (e.g. page-flip reader, settings),
- adds/removes a **dependency** (`pubspec.yaml`),
- changes **how to run, build, configure, or test** the app,
- changes the **project structure** in a way worth orienting a newcomer to.

Pure internal refactors with no external effect don't need a README change.

## Target shape for this app's README

Keep these sections present and accurate (add others as needed):

1. **Title + one-line description** — keep in sync with `pubspec.yaml`
   `description`.
2. **Features** — short bullet list of what a user can actually do today
   (reading, page-flip, themes/palettes, font controls, library, progress…).
   Only list what exists in `lib/`.
3. **Architecture** — one line: MVVM + SOLID, `lib/src/{models,services,
   viewmodels,views,components,theme,utils,data}`; point to the
   `moonleaf-architecture` skill.
4. **Tech / notable dependencies** — list non-obvious packages and what each is
   for (e.g. `provider` state, `shared_preferences` persistence, `page_flip`
   page-curl). Pull names/versions from `pubspec.yaml` — don't guess.
5. **Getting started / Run** — the real commands (`flutter pub get`,
   `flutter run`). Keep the verify loop reference (`flutter analyze`,
   `flutter test`) per the `flutter-verify` skill.

## How to do it

1. Read the current `README.md`.
2. Cross-check claims against reality: `pubspec.yaml` (deps, description) and
   `lib/` (features actually implemented). **Verify before you write.**
3. Edit surgically — preserve existing tone and any sections still accurate;
   replace the boilerplate "starting point for a Flutter application" stub with
   real content the first time.
4. Keep it concise: bullets over prose, no marketing fluff, no future/aspirational
   features.
5. Use relative markdown links to point at code or skills where useful.

## Don'ts

- Don't list a dependency or feature that isn't in the repo.
- Don't paste large code blocks — link to the file instead.
- Don't duplicate the architecture rules; link to the skill.
