


import 'package:path_provider/path_provider.dart';

Future<void> clearOldCachedFiles() async {
  final cacheDir = await getTemporaryDirectory();
  final now = DateTime.now();

  if (cacheDir.existsSync()) {
    final files = cacheDir.listSync(); // List all files in the cache directory

    for (final file in files) {
      final stat = file.statSync(); // Get file stats
      final lastModified = stat.modified; // Get last modified time

      print("temp dir $file $lastModified ${files.length}");

      print("file life ${now.difference(lastModified).inHours }");

      // Check if the file is older than 24 hours
      // if (now.difference(lastModified) > const Duration(hours: 24)) {
        print("file life ${now.difference(lastModified) }");
         // await file.delete(recursive: true); // Delete the file
      // }
    }
  }
}