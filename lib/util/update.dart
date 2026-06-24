import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

Future<bool> checkForUpdates() async {
  try {
    final packageInfo = await PackageInfo.fromPlatform();
    final response = await http.get(Uri.parse(
        'https://api.github.com/repos/StrangeGirlMurph/Pinpoint/releases/latest'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final latestVersion = data['tag_name'] as String?;
      if (latestVersion != null) {
        final currentVersion = packageInfo.version;
        final latestClean = latestVersion.startsWith('v')
            ? latestVersion.substring(1)
            : latestVersion;

        return _isNewerVersion(currentVersion, latestClean);
      }
    }
  } catch (e) {
    // Ignore errors
  }
  return false;
}

bool _isNewerVersion(String currentVersion, String latestVersion) {
  List<String> currentParts = currentVersion.split('+')[0].split('.');
  List<String> latestParts = latestVersion.split('+')[0].split('.');

  for (int i = 0; i < currentParts.length && i < latestParts.length; i++) {
    int current = int.tryParse(currentParts[i]) ?? 0;
    int latest = int.tryParse(latestParts[i]) ?? 0;
    if (latest > current) return true;
    if (latest < current) return false;
  }
  return latestParts.length > currentParts.length;
}
