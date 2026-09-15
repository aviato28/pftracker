import 'dart:io';

import 'package:http/http.dart' as http;

import 'tile_math.dart';

/// Bulk pre-download of map tiles for a bounding box, meant to run once
/// on the ground (gate wifi) before a flight. Downloaded tiles land in the
/// same cache directory [OfflineFirstTileProvider] reads from.
///
/// The default tile source is the public OpenStreetMap tile server, which
/// is fine for development but its usage policy (https://operations.osmfoundation.org/policies/tiles/)
/// prohibits sustained bulk downloading from third-party apps. Before
/// shipping, point [urlTemplate] at a provider meant for this (e.g.
/// MapTiler, Stadia Maps, Thunderforest) with your own API key.
class TileDownloader {
  final Directory cacheDir;
  final String urlTemplate;
  final http.Client _client;

  TileDownloader({
    required this.cacheDir,
    this.urlTemplate = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    http.Client? client,
  }) : _client = client ?? http.Client();

  int estimateTileCount(
    LatLngBoundsSimple bounds, {
    required int minZoom,
    required int maxZoom,
  }) {
    return TileMath.tilesForBounds(bounds, minZoom: minZoom, maxZoom: maxZoom)
        .length;
  }

  /// Downloads every tile covering [bounds] across the given zoom range.
  /// Tiles already on disk are skipped. Best-effort: a failed tile is
  /// counted as "done" (so progress still completes) and simply leaves a
  /// gap in the offline map rather than aborting the whole download.
  Future<void> downloadRoute({
    required LatLngBoundsSimple bounds,
    required int minZoom,
    required int maxZoom,
    void Function(int downloaded, int total)? onProgress,
    int concurrency = 6,
  }) async {
    final tiles = TileMath.tilesForBounds(bounds, minZoom: minZoom, maxZoom: maxZoom);
    final total = tiles.length;
    var downloaded = 0;
    onProgress?.call(0, total);

    final queue = List<TileCoord>.from(tiles);

    Future<void> worker() async {
      while (queue.isNotEmpty) {
        final tile = queue.removeLast();
        await _downloadTile(tile);
        downloaded++;
        onProgress?.call(downloaded, total);
      }
    }

    await Future.wait(List.generate(concurrency, (_) => worker()));
  }

  Future<void> _downloadTile(TileCoord tile) async {
    final file = File('${cacheDir.path}/${tile.z}/${tile.x}/${tile.y}.png');
    if (await file.exists()) return;

    final url = urlTemplate
        .replaceAll('{z}', '${tile.z}')
        .replaceAll('{x}', '${tile.x}')
        .replaceAll('{y}', '${tile.y}');
    try {
      final response = await _client.get(
        Uri.parse(url),
        headers: {'User-Agent': 'pftracker-offline-flight-tracker'},
      );
      if (response.statusCode == 200) {
        await file.parent.create(recursive: true);
        await file.writeAsBytes(response.bodyBytes);
      }
    } catch (_) {
      // No connectivity mid-download, rate limited, etc — leave the gap.
    }
  }

  void dispose() => _client.close();
}
