import 'package:flutter/foundation.dart';

/// A simple in-app buffer for capturing print() output so we can show logs
/// on web/iOS Safari without external dev tools.
class LogConsoleBuffer {
  LogConsoleBuffer._();
  static final LogConsoleBuffer instance = LogConsoleBuffer._();

  /// Last N lines of logs.
  final ValueNotifier<List<String>> lines = ValueNotifier<List<String>>(<String>[]);

  /// Maximum number of lines to keep.
  static const int _maxLines = 500;

  void add(String line) {
    final ts = DateTime.now().toIso8601String();
    final entry = '[$ts] $line';
    final next = List<String>.from(lines.value)..add(entry);
    if (next.length > _maxLines) {
      next.removeRange(0, next.length - _maxLines);
    }
    lines.value = next;
  }

  void clear() {
    lines.value = <String>[];
  }
}
