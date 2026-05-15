import 'package:flutter/foundation.dart';

/// Direction of the bridge call.
enum LogDirection { request, callback }

/// A single console log entry.
class LogEntry {
  final DateTime timestamp;
  final LogDirection direction;
  final String method;
  final Map<String, String> params;
  final bool isError;

  const LogEntry({
    required this.timestamp,
    required this.direction,
    required this.method,
    required this.params,
    this.isError = false,
  });
}

/// Shared singleton-style service for capturing bridge I/O.
///
/// Lightweight: stores at most [maxEntries] log items in memory.
/// UI listens via [ChangeNotifier]. Controllers call [logRequest]
/// and [logCallback] to push entries.
class ConsoleLogService extends ChangeNotifier {
  static const int maxEntries = 200;

  final List<LogEntry> _entries = [];
  List<LogEntry> get entries => List.unmodifiable(_entries);

  /// Log an outgoing request to native.
  void logRequest(String method, Map<String, String> params) {
    _add(LogEntry(
      timestamp: DateTime.now(),
      direction: LogDirection.request,
      method: method,
      params: _sanitize(params),
    ));
  }

  /// Log an incoming callback from native.
  void logCallback(String method, Map<String, String> params, {bool isError = false}) {
    _add(LogEntry(
      timestamp: DateTime.now(),
      direction: LogDirection.callback,
      method: method,
      params: _sanitize(params),
      isError: isError,
    ));
  }

  /// Clear all log entries.
  void clear() {
    _entries.clear();
    notifyListeners();
  }

  void _add(LogEntry entry) {
    _entries.insert(0, entry); // newest first
    if (_entries.length > maxEntries) {
      _entries.removeLast();
    }
    notifyListeners();
  }

  /// Truncate values that look like base64 to 20 chars.
  Map<String, String> _sanitize(Map<String, String> params) {
    return params.map((key, value) => MapEntry(key, _truncateBase64(value)));
  }

  /// Detects base64-like strings (>40 chars, matches charset) and truncates.
  static String _truncateBase64(String value) {
    if (value.length <= 40) return value;
    // Base64 regex: only A-Za-z0-9+/= and no spaces
    if (RegExp(r'^[A-Za-z0-9+/=]+$').hasMatch(value)) {
      return '${value.substring(0, 20)}... (${value.length} chars)';
    }
    return value;
  }
}
