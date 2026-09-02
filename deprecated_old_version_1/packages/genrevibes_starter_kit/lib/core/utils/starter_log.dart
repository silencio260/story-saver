import 'package:logger/logger.dart';

/// Centralized Logger for StarterKit and App Features
///
/// Provides beautifully styled console output with frames, emojis, and colors.
class StarterLog {
  /// Default logger so log calls made before [init] (e.g. before
  /// StarterKit.initialize) don't throw a LateInitializationError. [init]
  /// replaces this with the configured pretty-printing logger.
  static Logger _logger = Logger();
  static bool _loggingEnabled = true;

  /// Initialize the logger with custom settings
  static void init({bool enableLogging = true}) {
    _loggingEnabled = enableLogging;
    _logger = Logger(
      printer: PrettyPrinter(
        methodCount: 0, // Number of method calls to be displayed
        errorMethodCount: 8, // Number of method calls if stacktrace is provided
        lineLength: 80, // Width of the output
        colors: true, // Colorful log messages
        printEmojis: true, // Print an emoji for each log message
        dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
      ),
    );
  }

  /// Log a debug message
  static void d(
    String title, {
    String? tag,
    Map<String, dynamic>? values,
    bool debugLog = false,
  }) {
    if (!_loggingEnabled && !debugLog) return;
    _logger.d(_formatMessage(title, tag, values));
  }

  /// Log an info message
  static void i(
    String title, {
    String? tag,
    Map<String, dynamic>? values,
    bool debugLog = false,
  }) {
    if (!_loggingEnabled && !debugLog) return;
    _logger.i(_formatMessage(title, tag, values));
  }

  /// Log a warning message
  static void w(
    String title, {
    String? tag,
    Map<String, dynamic>? values,
    bool debugLog = false,
  }) {
    if (!_loggingEnabled && !debugLog) return;
    _logger.w(_formatMessage(title, tag, values));
  }

  /// Log an error message (honors the global logging flag like d/i/w)
  static void e(
    String title, {
    String? tag,
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? values,
    bool debugLog = false,
  }) {
    if (!_loggingEnabled && !debugLog) return;
    _logger.e(
      _formatMessage('❌ $title', tag, values),
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Format the message with optional tags and values
  static String _formatMessage(
    String title,
    String? tag,
    Map<String, dynamic>? values,
  ) {
    final buffer = StringBuffer();

    // Tag/Feature header
    if (tag != null) {
      buffer.writeln('[$tag] $title');
    } else {
      buffer.writeln(title);
    }

    // Values and Labels
    if (values != null && values.isNotEmpty) {
      buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      values.forEach((key, value) {
        buffer.writeln('  • $key: $value');
      });
      buffer.write('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    }

    return buffer.toString();
  }

  // --- Specialized Loggers for Common Events ---

  static void logAdEvent(
    String event, {
    required String adUnitId,
    String? format,
    double? value,
    String? currency,
    bool debugLog = false,
  }) {
    i(
      'Ad Event: $event',
      tag: 'ADS',
      debugLog: debugLog,
      values: {
        'Ad Unit': adUnitId,
        if (format != null) 'Format': format,
        if (value != null) 'Value': value,
        if (currency != null) 'Currency': currency,
      },
    );
  }

  static void logPurchaseEvent(
    String event, {
    required String productId,
    double? price,
    String? currency,
    bool debugLog = false,
  }) {
    i(
      'IAP Event: $event',
      tag: 'IAP',
      debugLog: debugLog,
      values: {
        'Product': productId,
        if (price != null) 'Price': price,
        if (currency != null) 'Currency': currency,
      },
    );
  }

  static void logAnalyticsEvent(
    String name,
    Map<String, dynamic> params, {
    bool debugLog = false,
  }) {
    d(
      'Analytics Logged: $name',
      tag: 'ANALYTICS',
      debugLog: debugLog,
      values: params,
    );
  }

  static void logRemoteConfigEvent(
    String event, {
    Map<String, dynamic>? params,
    bool debugLog = false,
  }) {
    i(
      'Remote Config: $event',
      tag: 'CONFIG',
      debugLog: debugLog,
      values: params,
    );
  }
}
