import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../network/api_client.dart';

class WindowsUpdateInfo {
  const WindowsUpdateInfo({
    required this.hasUpdate,
    required this.latestVersion,
    required this.installerUrl,
    required this.mandatory,
    required this.releaseNotes,
  });

  final bool hasUpdate;
  final String latestVersion;
  final String installerUrl;
  final bool mandatory;
  final String releaseNotes;

  factory WindowsUpdateInfo.fromMap(Map<String, dynamic> data) {
    final rawHasUpdate = data['has_update'];
    final rawMandatory = data['mandatory'];
    return WindowsUpdateInfo(
      hasUpdate: rawHasUpdate == true ||
          rawHasUpdate == 1 ||
          '${rawHasUpdate ?? ''}'.toLowerCase() == 'true',
      latestVersion: '${data['latest_version'] ?? ''}'.trim(),
      installerUrl: '${data['installer_url'] ?? ''}'.trim(),
      mandatory: rawMandatory == true ||
          rawMandatory == 1 ||
          '${rawMandatory ?? ''}'.toLowerCase() == 'true',
      releaseNotes: '${data['release_notes'] ?? ''}'.trim(),
    );
  }
}

class WindowsUpdater {
  WindowsUpdater(this._apiClient);

  static const String appVersion =
      String.fromEnvironment('APP_VERSION', defaultValue: '1.0.0');

  final ApiClient _apiClient;

  Future<WindowsUpdateInfo?> checkForUpdate() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.windows) return null;

    final response = await _apiClient.get(
      '/app/update?platform=windows&current_version=${Uri.encodeComponent(appVersion)}',
    );
    if (response['success'] != true) return null;
    if (response['data'] is! Map) return null;

    final info = WindowsUpdateInfo.fromMap(
      (response['data'] as Map).cast<String, dynamic>(),
    );

    if (info.installerUrl.isEmpty || info.latestVersion.isEmpty) return null;
    return info;
  }

  Future<File> downloadInstaller(
    WindowsUpdateInfo info, {
    void Function(double progress)? onProgress,
  }) async {
    final uri = Uri.tryParse(info.installerUrl);
    if (uri == null) {
      throw Exception('URL de instalador inválida');
    }

    final client = HttpClient();
    final request = await client.getUrl(uri);
    final response = await request.close();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('No se pudo descargar el instalador (HTTP ${response.statusCode})');
    }

    final tempDir = await getTemporaryDirectory();
    final outFile = File(
      '${tempDir.path}\\rons_pizza_update_${DateTime.now().millisecondsSinceEpoch}.exe',
    );
    final sink = outFile.openWrite();

    final total = response.contentLength;
    var received = 0;
    await for (final chunk in response) {
      sink.add(chunk);
      received += chunk.length;
      if (onProgress != null && total > 0) {
        onProgress((received / total).clamp(0, 1));
      }
    }
    await sink.flush();
    await sink.close();
    client.close();

    return outFile;
  }

  Future<void> runInstallerSilent(File installerFile) async {
    await Process.start(
      installerFile.path,
      <String>[
        '/VERYSILENT',
        '/SUPPRESSMSGBOXES',
        '/NORESTART',
        '/CLOSEAPPLICATIONS',
      ],
      mode: ProcessStartMode.detached,
    );
  }
}
