import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';

import '../../data/update/app_update_service.dart';
import '../../data/update/update_info.dart';
import '../theme/app_theme.dart';

/// Slim dismissible banner offering an available update. Sits inline at
/// the top of a screen's content, not a dialog — an update is worth
/// mentioning, not worth interrupting someone mid-flight-setup for.
class UpdateBanner extends StatelessWidget {
  final UpdateInfo info;
  final VoidCallback onDismiss;

  const UpdateBanner({super.key, required this.info, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.accentDim,
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.system_update_alt_rounded, color: AppColors.accent, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Update available — ${info.versionTag}',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Downloads in-app, no browser needed.',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onDismiss,
            child: const Text('Later'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () => startUpdateDownload(context, info),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}

/// Shows the download/install progress sheet for [info]. Used by
/// [UpdateBanner]'s "Update" button and by a manual "Check for updates"
/// entry point alike, so there's one download/install flow in the app.
Future<void> startUpdateDownload(BuildContext context, UpdateInfo info) async {
  final service = AppUpdateService();
  await showModalBottomSheet<void>(
    context: context,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => _DownloadSheet(service: service, info: info),
  );
  service.dispose();
}

class _DownloadSheet extends StatefulWidget {
  final AppUpdateService service;
  final UpdateInfo info;
  const _DownloadSheet({required this.service, required this.info});

  @override
  State<_DownloadSheet> createState() => _DownloadSheetState();
}

class _DownloadSheetState extends State<_DownloadSheet> {
  double? _progress;
  String? _error;
  bool _readyToInstall = false;
  File? _file;

  @override
  void initState() {
    super.initState();
    _download();
  }

  Future<void> _download() async {
    setState(() {
      _progress = 0;
      _error = null;
    });
    try {
      final file = await widget.service.download(
        widget.info,
        onProgress: (received, total) {
          if (mounted && total > 0) {
            setState(() => _progress = received / total);
          }
        },
      );
      if (mounted) {
        setState(() {
          _file = file;
          _readyToInstall = true;
        });
        await OpenFilex.open(file.path);
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Download failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _error != null
                  ? 'Update failed'
                  : _readyToInstall
                      ? 'Ready to install'
                      : 'Downloading ${widget.info.versionTag}…',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            if (_error == null)
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: _progress == 0 ? null : _progress,
                  minHeight: 6,
                  backgroundColor: AppColors.border,
                  valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                ),
              )
            else
              Text(_error!, style: const TextStyle(color: AppColors.error)),
            const SizedBox(height: 20),
            if (_readyToInstall)
              const Text(
                'Android should have opened the installer. If nothing '
                'happened, tap Install below.',
                style: TextStyle(fontSize: 12.5, color: AppColors.textMuted, height: 1.4),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ),
                if (_readyToInstall || _error != null) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _error != null
                          ? _download
                          : () => OpenFilex.open(_file!.path),
                      child: Text(_error != null ? 'Retry' : 'Install'),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
