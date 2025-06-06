import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SavedMediaManager {
  static const String _mediaKey = "saved_media"; // Key for shared prefs
  static const int _expiryDuration = 25 * 60 * 60 * 1000; // 25 hours in milliseconds

  /// Check if a media is already saved
  Future<bool> isMediaSaved(String mediaPath) async {
    final prefs = await SharedPreferences.getInstance();
    final savedMedia = prefs.getString(_mediaKey);
    if (savedMedia == null) return false;


    final mediaList = jsonDecode(savedMedia) as List<dynamic>;
    final now = DateTime.now().millisecondsSinceEpoch;

    for (var media in mediaList) {
      if (media['path'] == mediaPath) {
        final savedTime = media['timestamp'];
        // Check if the media has expired
        if (now - savedTime > _expiryDuration) {
          await _removeExpiredMedia(mediaPath);
          return false;
        }
        return true;
      }
    }
    return false;
  }

  /// Save media to shared preferences
  Future<void> saveMedia(String mediaPath) async {
    final prefs = await SharedPreferences.getInstance();
    final savedMedia = prefs.getString(_mediaKey);
    final now = DateTime.now().millisecondsSinceEpoch;

    List<dynamic> mediaList = savedMedia != null ? jsonDecode(savedMedia) : [];

    // Prevent duplicates
    if (!await isMediaSaved(mediaPath)) {
      mediaList.add({'path': mediaPath, 'timestamp': now});
      await prefs.setString(_mediaKey, jsonEncode(mediaList));
    }




    // String fileName = path.split('/').last.split('.').first;

    print('SavedMediaManager ${mediaList} -  ${mediaList.length}');
    print('SavedMediaManagerLength -  ${mediaList.length}');
    for (var media in mediaList) {
      int currentTime = DateTime.now().millisecondsSinceEpoch;
      final differenceMs = currentTime - media['timestamp'];
      double differenceHours = differenceMs / (1000 * 60 * 60);
      bool isOlderThan24Hours = differenceHours > 24;

      print("object ${media['path']} - ${differenceHours.toStringAsFixed(1)} Hrs (${isOlderThan24Hours ? 'Older' : 'Newer'} than 24h)");

    }
  }

  /// Delete media manually
  Future<void> deleteMedia(String mediaPath) async {
    final prefs = await SharedPreferences.getInstance();
    final savedMedia = prefs.getString(_mediaKey);

    if (savedMedia != null) {
      List<dynamic> mediaList = jsonDecode(savedMedia);
      mediaList.removeWhere((media) => media['path'] == mediaPath || media['path'].contains(mediaPath));
      await prefs.setString(_mediaKey, jsonEncode(mediaList));

      print('deleteMedia ${mediaList} -  ${mediaList.length}');
      // print('object');
    }

  }

  /// Remove expired media from shared preferences
  Future<void> _removeExpiredMedia(String mediaPath) async {
    await deleteMedia(mediaPath);
  }

  /// Delete all expired media from shared preferences
  Future<void> cleanExpiredMedia() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMedia = prefs.getString(_mediaKey);
    if (savedMedia == null) return;

    List<dynamic> mediaList = jsonDecode(savedMedia);
    final now = DateTime.now().millisecondsSinceEpoch;

    mediaList.removeWhere((media) => now - media['timestamp'] > _expiryDuration);
    await prefs.setString(_mediaKey, jsonEncode(mediaList));
  }
}
