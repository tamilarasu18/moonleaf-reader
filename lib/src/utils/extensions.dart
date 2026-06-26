import 'package:flutter/material.dart';

/// Small ergonomic helpers. Keeps view code terse without pulling in a
/// dependency just for sugar.
extension BuildContextX on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;
  Size get screenSize => MediaQuery.sizeOf(this);
}

extension StringX on String {
  /// "1" -> "1 min", pluralising a unit.
  String plural(int count) => '$count $this${count == 1 ? '' : 's'}';
}
