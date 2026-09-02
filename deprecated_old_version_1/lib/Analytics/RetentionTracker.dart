import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storysaver/Services/analytics_service.dart';

/// Pure analytics class for tracking user retention and engagement
///
/// NO targeting logic - just data tracking and metrics calculation
///
/// Usage:
/// ```dart
/// await RetentionTracker().trackAppOpen();
/// int days = RetentionTracker().getDaysSinceInstall();
/// ```
class RetentionTracker extends ChangeNotifier {
  // Singleton pattern
  static final RetentionTracker _instance = RetentionTracker._internal();
  factory RetentionTracker() => _instance;
  RetentionTracker._internal();

  // Storage keys
  static const String _firstInstallKey = 'first_install_date';
  static const String _lastOpenKey = 'last_open_date';
  static const String _totalOpensKey = 'total_app_opens';
  static const String _sessionTimestampsKey = 'session_timestamps';
  static const String _dailyOpenDatesKey = 'daily_open_dates';

  // Cache
  DateTime? _firstInstallDate;
  DateTime? _lastOpenDate;
  int? _totalAppOpens;
  List<DateTime>? _sessionTimestamps;
  List<DateTime>? _dailyOpenDates;
  bool _isInitialized = false;

  /// Initialize and track app open
  Future<void> trackAppOpen() async {
    await _ensureInitialized();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // First time setup
    if (_firstInstallDate == null) {
      _firstInstallDate = now;
      await _saveDateTime(_firstInstallKey, now);
      print('RetentionTracker: First install detected at $now');
    }

    // Update last open
    _lastOpenDate = now;
    await _saveDateTime(_lastOpenKey, now);

    // Increment total opens
    _totalAppOpens = (_totalAppOpens ?? 0) + 1;
    await _saveInt(_totalOpensKey, _totalAppOpens!);

    // Add session timestamp
    _sessionTimestamps ??= [];
    _sessionTimestamps!.add(now);
    await _saveDateTimeList(_sessionTimestampsKey, _sessionTimestamps!);

    // Add daily open date (if not already opened today)
    _dailyOpenDates ??= [];
    if (!_dailyOpenDates!.any((date) =>
        date.year == today.year &&
        date.month == today.month &&
        date.day == today.day)) {
      _dailyOpenDates!.add(today);
      await _saveDateTimeList(_dailyOpenDatesKey, _dailyOpenDates!);
      print(
          'RetentionTracker: New day tracked - ${today.toString().split(' ')[0]}');
    }

    print('RetentionTracker: App open tracked - Total: $_totalAppOpens');

    // Log to Analytics
    await _logRetentionAnalytics('retention_app_opened');

    notifyListeners();
  }

  /// Track a session (can be called multiple times per app open)
  Future<void> trackSession() async {
    await _ensureInitialized();

    final now = DateTime.now();
    _sessionTimestamps ??= [];
    _sessionTimestamps!.add(now);
    await _saveDateTimeList(_sessionTimestampsKey, _sessionTimestamps!);

    print('RetentionTracker: Session tracked');

    // Log to Analytics
    await _logRetentionAnalytics('retention_session_started');

    notifyListeners();
  }

  /// Helper to log retention analytics with standard params
  Future<void> _logRetentionAnalytics(String eventName) async {
    final params = getEngagementMetrics();

    // Add retention milestones if applicable
    final daysSinceInstall = getDaysSinceInstall();
    if (daysSinceInstall >= 1 && daysSinceInstall <= 7) {
      if (hasReturnedOnDay(daysSinceInstall)) {
        params['milestone_d$daysSinceInstall'] = true;
      }
    }

    // Add D7 retention rate
    params['d7_retention_rate'] = getD7RetentionRate();

    await AnalyticsService.logRetentionEvent(eventName, params);

    // Check for specific milestones and log them separately
    if (eventName == 'retention_app_opened') {
      if (daysSinceInstall == 1)
        await AnalyticsService.logRetentionEvent(
            'retention_day_1_returned', params);
      if (daysSinceInstall == 3)
        await AnalyticsService.logRetentionEvent(
            'retention_day_3_returned', params);
      if (daysSinceInstall == 7)
        await AnalyticsService.logRetentionEvent(
            'retention_day_7_returned', params);
      if (daysSinceInstall == 30)
        await AnalyticsService.logRetentionEvent(
            'retention_day_30_returned', params);
    }
  }

  // ========== DATA QUERIES ==========

  /// Total number of times app has been opened
  int getTotalAppOpens() {
    return _totalAppOpens ?? 0;
  }

  /// Number of sessions today
  int getSessionCountToday() {
    if (_sessionTimestamps == null) return 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    return _sessionTimestamps!
        .where((timestamp) =>
            timestamp.isAfter(today) && timestamp.isBefore(tomorrow))
        .length;
  }

  /// Days since first install
  int getDaysSinceInstall() {
    if (_firstInstallDate == null) return 0;
    return DateTime.now().difference(_firstInstallDate!).inDays;
  }

  /// Days since last open
  int getDaysSinceLastOpen() {
    if (_lastOpenDate == null) return 0;
    return DateTime.now().difference(_lastOpenDate!).inDays;
  }

  /// First install date
  DateTime? getFirstInstallDate() {
    return _firstInstallDate;
  }

  /// Last open date
  DateTime? getLastOpenDate() {
    return _lastOpenDate;
  }

  /// List of all dates user opened the app (YYYY-MM-DD format)
  List<String> getActiveDays() {
    if (_dailyOpenDates == null) return [];
    return _dailyOpenDates!
        .map((date) =>
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}')
        .toList();
  }

  /// All session timestamps
  List<DateTime> getSessionTimestamps() {
    return _sessionTimestamps ?? [];
  }

  // ========== RETENTION METRICS ==========

  /// Check if user returned on specific day after install (D1-D7)
  /// D1 = returned 1 day after install
  bool hasReturnedOnDay(int day) {
    if (_firstInstallDate == null || _dailyOpenDates == null) return false;
    if (day < 1 || day > 7) return false;

    final targetDate = DateTime(
      _firstInstallDate!.year,
      _firstInstallDate!.month,
      _firstInstallDate!.day + day,
    );

    return _dailyOpenDates!.any((date) =>
        date.year == targetDate.year &&
        date.month == targetDate.month &&
        date.day == targetDate.day);
  }

  /// Check if user was active in specific week (W1-W4)
  /// W1 = days 1-7, W2 = days 8-14, etc.
  bool hasReturnedOnWeek(int week) {
    if (_firstInstallDate == null || _dailyOpenDates == null) return false;
    if (week < 1 || week > 4) return false;

    final startDay = (week - 1) * 7 + 1;
    final endDay = week * 7;

    for (int day = startDay; day <= endDay; day++) {
      if (hasReturnedOnDay(day)) return true;
    }
    return false;
  }

  /// Check if user was active in specific month (M1-M12)
  /// M1 = days 1-30, M2 = days 31-60, etc.
  bool hasReturnedOnMonth(int month) {
    if (_firstInstallDate == null || _dailyOpenDates == null) return false;
    if (month < 1 || month > 12) return false;

    final startDay = (month - 1) * 30 + 1;
    final endDay = month * 30;

    final startDate = DateTime(
      _firstInstallDate!.year,
      _firstInstallDate!.month,
      _firstInstallDate!.day,
    ).add(Duration(days: startDay - 1));

    final endDate = startDate.add(Duration(days: 30));

    return _dailyOpenDates!.any((date) =>
        date.isAfter(startDate.subtract(const Duration(days: 1))) &&
        date.isBefore(endDate.add(const Duration(days: 1))));
  }

  /// D7 retention rate (percentage of first 7 days user was active)
  double getD7RetentionRate() {
    if (_firstInstallDate == null) return 0.0;

    int activeDays = 0;
    for (int day = 1; day <= 7; day++) {
      if (hasReturnedOnDay(day)) activeDays++;
    }

    return (activeDays / 7.0) * 100.0;
  }

  /// Weekly retention rate (percentage of first 4 weeks active)
  double getWeeklyRetentionRate() {
    if (_firstInstallDate == null) return 0.0;

    int activeWeeks = 0;
    for (int week = 1; week <= 4; week++) {
      if (hasReturnedOnWeek(week)) activeWeeks++;
    }

    return (activeWeeks / 4.0) * 100.0;
  }

  /// Monthly retention rate (percentage of first 12 months active)
  double getMonthlyRetentionRate() {
    if (_firstInstallDate == null) return 0.0;

    int activeMonths = 0;
    for (int month = 1; month <= 12; month++) {
      if (hasReturnedOnMonth(month)) activeMonths++;
    }

    return (activeMonths / 12.0) * 100.0;
  }

  // ========== ANALYTICS SNAPSHOTS ==========

  /// Complete retention snapshot
  Map<String, dynamic> getRetentionSnapshot() {
    final d7Map = <String, bool>{};
    for (int day = 1; day <= 7; day++) {
      d7Map['D$day'] = hasReturnedOnDay(day);
    }

    final w4Map = <String, bool>{};
    for (int week = 1; week <= 4; week++) {
      w4Map['W$week'] = hasReturnedOnWeek(week);
    }

    final m12Map = <String, bool>{};
    for (int month = 1; month <= 12; month++) {
      m12Map['M$month'] = hasReturnedOnMonth(month);
    }

    return {
      'first_install_date': _firstInstallDate?.toIso8601String(),
      'last_open_date': _lastOpenDate?.toIso8601String(),
      'days_since_install': getDaysSinceInstall(),
      'days_since_last_open': getDaysSinceLastOpen(),
      'total_opens': getTotalAppOpens(),
      'active_days_count': _dailyOpenDates?.length ?? 0,
      'active_days': getActiveDays(),
      'd7_retention': d7Map,
      'd7_retention_rate': getD7RetentionRate(),
      'w4_retention': w4Map,
      'weekly_retention_rate': getWeeklyRetentionRate(),
      'm12_retention': m12Map,
      'monthly_retention_rate': getMonthlyRetentionRate(),
    };
  }

  /// Engagement metrics snapshot
  Map<String, dynamic> getEngagementMetrics() {
    return {
      'total_opens': getTotalAppOpens(),
      'sessions_today': getSessionCountToday(),
      'total_sessions': _sessionTimestamps?.length ?? 0,
      'active_days_count': _dailyOpenDates?.length ?? 0,
      'days_since_install': getDaysSinceInstall(),
      'days_since_last_open': getDaysSinceLastOpen(),
      'avg_opens_per_day': _calculateAverageOpensPerDay(),
    };
  }

  double _calculateAverageOpensPerDay() {
    final daysSinceInstall = getDaysSinceInstall();
    if (daysSinceInstall == 0) return getTotalAppOpens().toDouble();
    return getTotalAppOpens() / daysSinceInstall;
  }

  // ========== STORAGE HELPERS ==========

  Future<void> _ensureInitialized() async {
    if (_isInitialized) return;

    final prefs = await SharedPreferences.getInstance();

    _firstInstallDate = await _loadDateTime(_firstInstallKey);
    _lastOpenDate = await _loadDateTime(_lastOpenKey);
    _totalAppOpens = prefs.getInt(_totalOpensKey);
    _sessionTimestamps = await _loadDateTimeList(_sessionTimestampsKey);
    _dailyOpenDates = await _loadDateTimeList(_dailyOpenDatesKey);

    _isInitialized = true;
    print(
        'RetentionTracker: Initialized with ${_totalAppOpens ?? 0} total opens');
  }

  Future<void> _saveDateTime(String key, DateTime value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value.toIso8601String());
  }

  Future<DateTime?> _loadDateTime(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(key);
    return str != null ? DateTime.parse(str) : null;
  }

  Future<void> _saveInt(String key, int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, value);
  }

  Future<void> _saveDateTimeList(String key, List<DateTime> values) async {
    final prefs = await SharedPreferences.getInstance();
    final strings = values.map((dt) => dt.toIso8601String()).toList();
    await prefs.setStringList(key, strings);
  }

  Future<List<DateTime>> _loadDateTimeList(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final strings = prefs.getStringList(key);
    if (strings == null) return [];
    return strings.map((str) => DateTime.parse(str)).toList();
  }

  /// Reset all retention data (for testing/debugging)
  Future<void> resetAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_firstInstallKey);
    await prefs.remove(_lastOpenKey);
    await prefs.remove(_totalOpensKey);
    await prefs.remove(_sessionTimestampsKey);
    await prefs.remove(_dailyOpenDatesKey);

    _firstInstallDate = null;
    _lastOpenDate = null;
    _totalAppOpens = null;
    _sessionTimestamps = null;
    _dailyOpenDates = null;
    _isInitialized = false;

    print('RetentionTracker: All data reset');
    notifyListeners();
  }
}
