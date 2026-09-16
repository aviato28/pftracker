import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import 'update_info.dart';

/// GitHub personal access token baked in at build time via
/// `--dart-define=GITHUB_UPDATE_TOKEN=...` — never commit an actual token.
/// This repo is private, so checking for/downloading releases needs auth;
/// use a fine-grained token scoped to just this repo with Contents:
/// Read-only. Building without the define simply disables update checks
/// (see [AppUpdateService.checkForUpdate]).
const _updateToken = String.fromEnvironment('GITHUB_UPDATE_TOKEN');

const _repoOwner = 'aviato28';
const _repoName = 'pftracker';

/// Checks GitHub Releases for a newer build than the one currently
/// running, and downloads it. There is no Play Store distribution here,
/// so this is the update mechanism — see README.md ("Releasing an
/// update") for how a release needs to be tagged for this to find it.
class AppUpdateService {
  final http.Client _client;
  AppUpdateService({http.Client? client}) : _client = client ?? http.Client();

  Map<String, String> get _authHeaders => {
        'Accept': 'application/vnd.github+json',
        'X-GitHub-Api-Version': '2022-11-28',
        if (_updateToken.isNotEmpty) 'Authorization': 'Bearer $_updateToken',
      };

  /// Returns the latest release's info if it's newer than the running
  /// build, or null if up to date, unreachable, or no token was baked in
  /// at build time. Always best-effort — an update check must never block
  /// or interrupt using the app.
  Future<UpdateInfo?> checkForUpdate() async {
    if (_updateToken.isEmpty) return null;
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentBuild = int.tryParse(packageInfo.buildNumber) ?? 0;

      final response = await _client.get(
        Uri.https('api.github.com', '/repos/$_repoOwner/$_repoName/releases/latest'),
        headers: _authHeaders,
      );
      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final tag = json['tag_name'] as String? ?? '';
      final latestBuild = _buildNumberFromTag(tag);
      if (latestBuild == null || latestBuild <= currentBuild) return null;

      final assets = (json['assets'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
      Map<String, dynamic>? apkAsset;
      for (final asset in assets) {
        final name = asset['name'] as String?;
        if (name != null && name.endsWith('.apk')) {
          apkAsset = asset;
          break;
        }
      }
      if (apkAsset == null) return null;

      return UpdateInfo(
        versionTag: tag,
        buildNumber: latestBuild,
        downloadApiUrl: apkAsset['url'] as String,
        sizeBytes: (apkAsset['size'] as num?)?.toInt() ?? 0,
        releaseNotes: (json['body'] as String?)?.trim() ?? '',
      );
    } catch (_) {
      // Offline, rate-limited, malformed release — none of it should ever
      // surface as an error to someone just trying to track their flight.
      return null;
    }
  }

  /// Parses the build number from a release tag of the form `v1.2.0+11`
  /// (matching pubspec.yaml's `version: 1.2.0+11`).
  int? _buildNumberFromTag(String tag) {
    final match = RegExp(r'\+(\d+)$').firstMatch(tag);
    if (match == null) return null;
    return int.tryParse(match.group(1)!);
  }

  /// Downloads the update APK to a temp file, reporting progress as
  /// bytes received out of [UpdateInfo.sizeBytes].
  Future<File> download(
    UpdateInfo info, {
    void Function(int received, int total)? onProgress,
  }) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/pftracker-update.apk');
    if (await file.exists()) await file.delete();

    final request = http.Request('GET', Uri.parse(info.downloadApiUrl));
    request.headers.addAll({..._authHeaders, 'Accept': 'application/octet-stream'});
    final response = await _client.send(request);
    if (response.statusCode != 200) {
      throw Exception('Download failed (HTTP ${response.statusCode})');
    }

    final sink = file.openWrite();
    var received = 0;
    await response.stream.listen((chunk) {
      sink.add(chunk);
      received += chunk.length;
      onProgress?.call(received, info.sizeBytes);
    }).asFuture<void>();
    await sink.close();

    return file;
  }

  void dispose() => _client.close();
}
