---
name: moonleaf-architecture
description: >-
  Use whenever adding, editing, or refactoring Dart code in the Moonleaf Flutter
  app (anything under lib/). Enforces the project's MVVM + SOLID architecture,
  the lib/src folder layout (models, services, viewmodels, views, components,
  theme, utils, data), constructor-injected abstractions via provider, the
  locally-bundled Lora/Inter fonts, and the centralized theme. Apply before
  writing code so new work matches the existing structure.
---

# Moonleaf architecture & conventions

Moonleaf is a Flutter book-reader built on **MVVM + SOLID**. Every change must
preserve this structure. When in doubt, copy the pattern of an existing file in
the same folder.

## Folder layout (all app code lives in `lib/src/`)

```
lib/
  main.dart                  # composition root: build deps, runApp
  src/
    app.dart                 # MoonleafApp: MultiProvider + MaterialApp + theme
    models/                  # pure data classes ONLY (no Flutter widgets, no IO)
    services/                # i_*.dart abstractions + concrete impls + service_locator.dart
    viewmodels/              # *_viewmodel.dart (ChangeNotifier) — state + commands
    views/<feature>/         # *_view.dart — UI only, one folder per screen
    components/              # reusable widgets shared across views
    theme/                   # app_colors, app_theme, reader_theme — all styling
    utils/                   # constants.dart, extensions.dart (no business logic)
    data/                    # sample/static data sources
```

## The layers (respect the dependency direction)

`View → ViewModel → Service (interface) → data`. Views never skip to services
directly; services never import views or viewmodels.

- **Models** (`models/`): immutable-ish plain Dart. No `SharedPreferences`, no
  `BuildContext`, no widgets. Value objects expose `copyWith` + `==`/`hashCode`
  (see `reader_settings.dart`).
- **Services** (`services/`): each capability is an abstract interface named
  `IXxx` in `i_xxx.dart`, with a concrete `Xxx` in `xxx.dart`. Persistence goes
  **only** through `IPreferencesService` — never call `SharedPreferences`
  elsewhere. Wire all concrete instances in `service_locator.dart` (the single
  place that knows concrete types).
- **ViewModels** (`viewmodels/`): extend `ChangeNotifier`. Hold view state and
  expose intent methods (e.g. `next()`, `setFontSize()`). Depend on service
  **interfaces** injected through the constructor — never `new` a concrete
  service inside a ViewModel. Call `notifyListeners()` after state changes. No
  `BuildContext`, no widgets.
- **Views** (`views/`): dumb UI. Read state with `context.watch<VM>()`, fire
  intent with `context.read<VM>().method()`. No business logic, no persistence,
  no direct service calls beyond reading them to build a child VM/provider.

## SOLID rules

- **S**: one class = one job. Split files; keep ViewModels per-screen.
- **O/L**: extend behaviour by adding a new `IXxx` implementation, not by
  editing call sites. New impls must be drop-in substitutable.
- **I**: keep interfaces small and focused (e.g. `IProgressService` is only
  about progress).
- **D**: depend on `IXxx` abstractions; concrete wiring happens solely in
  `service_locator.dart` and `app.dart`.

## State management (provider)

- App-wide state (theme mode, reader settings) lives in `AppViewModel`, provided
  above `MaterialApp` in `app.dart`.
- Per-screen ViewModels are provided at the navigation boundary with
  `ChangeNotifierProvider<XxxViewModel>(create: (ctx) => XxxViewModel(... ctx.read<IService>()))`.
- Services are exposed with `Provider<IXxx>.value(...)` in `app.dart`.

## Theme & fonts (never hardcode)

- Use `AppConstants.fontReading` (**Lora**, serif/body) and `AppConstants.fontUi`
  (**Inter**, UI). Both are **bundled locally** in `assets/fonts/` and declared
  in `pubspec.yaml`. **Do not** add `google_fonts` or any runtime font fetching.
- Colours come from `AppColors` (brand) and `ReaderColors`/`ReaderPalette`
  (reading surface). Don't scatter raw `Color(0xFF…)` through views — add it to
  `theme/`.
- Spacing/radii/durations come from `AppConstants`.
- Use `Color.withValues(alpha: …)` (not the deprecated `withOpacity`).

## Checklist: adding a new feature

1. **Model** → add/extend a class in `models/` (pure data).
2. **Service** → if it needs data/IO, define `i_<thing>.dart` + `<thing>.dart`,
   then register it in `service_locator.dart` and expose it in `app.dart`.
3. **ViewModel** → `<feature>_viewmodel.dart` extending `ChangeNotifier`, taking
   service interfaces via constructor.
4. **View** → `views/<feature>/<feature>_view.dart`, bound to the VM via
   provider; reusable bits go in `components/`.
5. **Navigation** → push with `fadeThroughRoute(...)` from `utils/constants.dart`
   wrapping the screen in its `ChangeNotifierProvider`.

## Naming

`i_*.dart` (interfaces), `*_service.dart`, `*_viewmodel.dart`, `*_view.dart`,
one folder per screen under `views/`. Classes: `IFoo`/`Foo`, `FooViewModel`,
`FooView`.

## After editing

Verify with the fast loop (see the `flutter-verify` skill): `flutter analyze`
then `flutter test`. Keep `flutter analyze` at **No issues found**.
