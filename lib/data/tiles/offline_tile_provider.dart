import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;

/// A [TileProvider] that reads tiles from a local cache directory first,
/// falling back to the network only when a tile hasn't been pre-downloaded.
/// Any network fetch is opportunistically written back to the cache, so
/// tiles seen once (e.g. at the gate, on wifi) stay available offline —
/// on top of whatever was explicitly pre-downloaded for the route.
class OfflineFirstTileProvider extends TileProvider {
  final Directory cacheDir;
  final http.Client _client;

  OfflineFirstTileProvider({required this.cacheDir, http.Client? client})
      : _client = client ?? http.Client();

  File _fileFor(TileCoordinates c) =>
      File('${cacheDir.path}/${c.z}/${c.x}/${c.y}.png');

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    final file = _fileFor(coordinates);
    if (file.existsSync()) {
      return FileImage(file);
    }
    final url = getTileUrl(coordinates, options);
    unawaited(_cacheInBackground(url, file));
    return NetworkImage(url, headers: headers);
  }

  Future<void> _cacheInBackground(String url, File file) async {
    try {
      final response = await _client.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        await file.parent.create(recursive: true);
        await file.writeAsBytes(response.bodyBytes);
      }
    } catch (_) {
      // No connectivity or request failed — fine, this is best-effort.
    }
  }

  @override
  void dispose() {
    _client.close();
    super.dispose();
  }
}
