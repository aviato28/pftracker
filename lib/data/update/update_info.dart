/// A newer build found on GitHub Releases.
class UpdateInfo {
  final String versionTag;
  final int buildNumber;
  final String downloadApiUrl;
  final int sizeBytes;
  final String releaseNotes;

  const UpdateInfo({
    required this.versionTag,
    required this.buildNumber,
    required this.downloadApiUrl,
    required this.sizeBytes,
    required this.releaseNotes,
  });
}
