import 'package:shared_preferences/shared_preferences.dart';

class DailyLimitManager {
  static final DailyLimitManager _instance = DailyLimitManager._internal();
  factory DailyLimitManager() => _instance;
  DailyLimitManager._internal();

  static const String _gallerySwipesKeyPrefix = 'gallery_swipes_';
  static const int _freeDailySwipes = 3;

  /// Increment the gallery swipe count for today
  Future<void> incrementGallerySwipe() async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getTodayKey();
    final current = prefs.getInt(key) ?? 0;
    await prefs.setInt(key, current + 1);
    print('DailyLimitManager: Swipe count incremented to ${current + 1}');
  }

  /// Check if user has reached their daily swipe limit
  Future<bool> isSwipeLimitReached() async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getTodayKey();
    final current = prefs.getInt(key) ?? 0;
    return current >= _freeDailySwipes;
  }

  /// Get current swipe count (for debugging/UI)
  Future<int> getGallerySwipeCount() async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getTodayKey();
    return prefs.getInt(key) ?? 0;
  }

  /// Reset count (for testing)
  Future<void> resetDailySwipes() async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getTodayKey();
    await prefs.remove(key);
    print('DailyLimitManager: Swipe count reset');
  }

  String _getTodayKey() {
    final now = DateTime.now();
    return '$_gallerySwipesKeyPrefix${now.year}-${now.month}-${now.day}';
  }
}
