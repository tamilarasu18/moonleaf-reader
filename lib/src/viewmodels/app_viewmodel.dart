import 'package:flutter/material.dart';

import '../components/page_turner.dart';
import '../models/reader_settings.dart';
import '../services/i_preferences_service.dart';
import '../theme/reader_theme.dart';
import '../utils/constants.dart';

/// App-wide ViewModel: owns the global, persisted preferences — the app theme
/// mode and the reading-surface settings. Bound to [MaterialApp] (for the
/// theme), the reader and the settings screen.
///
/// Depends only on the [IPreferencesService] abstraction (DIP).
class AppViewModel extends ChangeNotifier {
  AppViewModel(this._prefs) {
    _load();
  }

  final IPreferencesService _prefs;

  ThemeMode _themeMode = ThemeMode.system;
  ReaderSettings _reader = const ReaderSettings();

  ThemeMode get themeMode => _themeMode;
  ReaderSettings get reader => _reader;

  void _load() {
    _themeMode = ThemeMode
        .values[_prefs.getInt(PrefKeys.themeMode) ?? ThemeMode.system.index];
    _reader = ReaderSettings(
      palette: ReaderPalette.values[
          _prefs.getInt(PrefKeys.readerPalette) ?? ReaderPalette.sepia.index],
      fontSize: _prefs.getDouble(PrefKeys.fontSize) ?? 19,
      lineHeight: _prefs.getDouble(PrefKeys.lineHeight) ?? 1.6,
      serif: _prefs.getBool(PrefKeys.serif) ?? true,
      warmth: _prefs.getDouble(PrefKeys.warmth) ?? 0.0,
      flipStyle: PageFlipStyle.values[
          _prefs.getInt(PrefKeys.flipStyle) ?? PageFlipStyle.curl.index],
      pageColumns: _prefs.getInt(PrefKeys.pageColumns) ?? 1,
    );
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    if (mode == _themeMode) return;
    _themeMode = mode;
    _prefs.setInt(PrefKeys.themeMode, mode.index);
    notifyListeners();
  }

  void setPalette(ReaderPalette palette) {
    _update(_reader.copyWith(palette: palette));
    _prefs.setInt(PrefKeys.readerPalette, palette.index);
  }

  void setFontSize(double size) {
    final clamped =
        size.clamp(AppConstants.minFontSize, AppConstants.maxFontSize);
    _update(_reader.copyWith(fontSize: clamped));
    _prefs.setDouble(PrefKeys.fontSize, clamped);
  }

  void setLineHeight(double height) {
    final clamped =
        height.clamp(AppConstants.minLineHeight, AppConstants.maxLineHeight);
    _update(_reader.copyWith(lineHeight: clamped));
    _prefs.setDouble(PrefKeys.lineHeight, clamped);
  }

  void setSerif(bool serif) {
    _update(_reader.copyWith(serif: serif));
    _prefs.setBool(PrefKeys.serif, serif);
  }

  void setWarmth(double warmth) {
    final clamped = warmth.clamp(0.0, 1.0);
    _update(_reader.copyWith(warmth: clamped));
    _prefs.setDouble(PrefKeys.warmth, clamped);
  }

  void setFlipStyle(PageFlipStyle style) {
    _update(_reader.copyWith(flipStyle: style));
    _prefs.setInt(PrefKeys.flipStyle, style.index);
  }

  void setPageColumns(int columns) {
    final clamped = columns.clamp(1, 2);
    _update(_reader.copyWith(pageColumns: clamped));
    _prefs.setInt(PrefKeys.pageColumns, clamped);
  }

  void _update(ReaderSettings next) {
    if (next == _reader) return;
    _reader = next;
    notifyListeners();
  }
}
