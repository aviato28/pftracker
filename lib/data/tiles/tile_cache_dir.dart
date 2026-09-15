import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Resolves the on-disk directory used for cached/pre-downloaded map tiles.
/// Uses the app's documents directory so tiles survive between app runs —
/// crucial since they're meant to be downloaded once, on the ground, and
/// used for the whole flight with no connectivity.
Future<Directory> tileCacheDirectory() async {
  final docs = await getApplicationDocumentsDirectory();
  final dir = Directory('${docs.path}/tile_cache');
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
  return dir;
}
