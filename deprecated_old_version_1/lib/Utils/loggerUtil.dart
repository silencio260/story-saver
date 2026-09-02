import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:logger/logger.dart';

var logger = Logger(
  printer: PrettyPrinter(
    methodCount: 2, // Number of method calls to be displayed
    errorMethodCount: 8, // Number of method calls if stacktrace is provided
    lineLength: 120, // Width of the output
    colors: true, // Colorful log messages
    printEmojis: true, // Print an emoji for each log message
    // Should each log print contain a timestamp
    dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
  ),
);

/// Print formatted ad impression log with all relevant details
void printLogAdImpression({
  required String ad,
  required double valueMicros,
  required String currencyCode,
  PrecisionType? precision,
}) {
  final double value = valueMicros / 1000000.0;

  logger.d('''
📊 Ad Impression Logged
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Ad Format: ${ad}
  Value: ${value.toStringAsFixed(6)} $currencyCode
  Micros: $valueMicros
  Precision: ${precision?.toString().split('.').last ?? 'unknown'}
  Timestamp: ${DateTime.now().toIso8601String()}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━''');
}
