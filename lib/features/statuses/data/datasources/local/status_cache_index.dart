import 'dart:convert';
import 'dart:io';

import 'package:docman/docman.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// A source-specific index allows repeat visits to render without a SAF scan.
class StatusCacheIndex {
  static const channel = MethodChannel('story_saver/status_directory');
  final Map<String, Map<String, dynamic>> entries = {};
  late File _index;

  Future<List<File>> read(bool business) async {
    final directory = await getApplicationSupportDirectory();
    _index = File(
      '${directory.path}/statuses_${business ? 'business' : 'regular'}.json',
    );
    try {
      final records = jsonDecode(await _index.readAsString()) as List;
      final files = <File>[];
      for (final raw in records) {
        final record = Map<String, dynamic>.from(raw as Map);
        final time = DateTime.fromMillisecondsSinceEpoch(
          record['modified'] as int,
        );
        if (DateTime.now().difference(time).inHours > 25) continue;
        final file = File(record['path'] as String);
        if (!await file.exists()) continue;
        entries[record['uri'] as String] = record;
        files.add(file);
      }
      return files;
    } on FileSystemException {
      return [];
    } on FormatException {
      return [];
    } on TypeError {
      entries.clear();
      return [];
    }
  }

  Future<File?> cache(DocumentFile document) async {
    final old = entries[document.uri];
    if (old != null &&
        old['modified'] == document.lastModified &&
        old['size'] == document.size) {
      final file = File(old['path'] as String);
      if (await file.exists()) return file;
    }
    File? file;
    try {
      final path = await channel.invokeMethod<String>('cache', {
        'uri': document.uri,
        'modified': document.lastModified,
        'size': document.size,
        'name': document.name,
      });
      if (path != null) file = File(path);
    } on MissingPluginException {
      file = await document.cache();
    }
    if (file != null) {
      entries[document.uri] = {
        'uri': document.uri,
        'modified': document.lastModified,
        'size': document.size,
        'path': file.path,
      };
    }
    return file;
  }

  Future<void> save(List<DocumentFile> documents) async {
    final records = [
      for (final doc in documents)
        if (entries.containsKey(doc.uri)) entries[doc.uri],
    ];
    final temporary = File('${_index.path}.tmp');
    await temporary.writeAsString(jsonEncode(records));
    await temporary.rename(_index.path);
    // Housekeeping runs after publishing all statuses.
    await _pruneExpiredFiles();
  }

  Future<void> _pruneExpiredFiles() async {
    final cache = Directory(
      '${(await getTemporaryDirectory()).path}/status_media',
    );
    if (!await cache.exists()) return;
    final activePaths =
        entries.values.map((entry) => entry['path'] as String).toSet();
    await for (final directory in cache.list()) {
      if (directory is! Directory) continue;
      if (DateTime.now()
              .difference((await directory.stat()).modified)
              .inHours <=
          26)
        continue;
      final files = await directory.list().toList();
      if (files.any((file) => activePaths.contains(file.path))) continue;
      await directory.delete(recursive: true);
    }
  }

  static Future<List<DocumentFile>> list(DocumentFile directory) async {
    try {
      final records = await channel.invokeListMethod<dynamic>('list', {
        'uri': directory.uri,
      });
      if (records == null) throw StateError('Status query returned no result');
      return records
          .map(
            (record) =>
                DocumentFile.fromMap(Map<String, dynamic>.from(record as Map)),
          )
          .toList();
    } on MissingPluginException {
      return directory.listDocuments(mimeTypes: ['image/*', 'video/*']);
    }
  }
}
