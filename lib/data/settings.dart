import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Settings extends ChangeNotifier {
  late SharedPreferences _preferences;

  /// Should be: `light`, `dark` or `system`
  static const String theme = "theme";
  /// Should be a valid route, e.g. `/map` or `/list`
  static const String startPage = "startPage";
  static const String lastListId = "lastListId";
  static const String lastEntryId = "lastEntryId";
  static const String lastMapLatitude = "lastMapLatitude";
  static const String lastMapLongitude = "lastMapLongitude";
  static const String lastMapZoom = "lastMapZoom";
  static const String lastMapRotationLocked = "lastMapRotationLocked";
  static const String checkForUpdates = "checkForUpdates";
  static const String tileUrlTemplate = "tileUrlTemplate";
  static const String tileUserAgent = "tileUserAgent";

  static const String defaultTileUrlTemplate =
      "https://tile.openstreetmap.org/{z}/{x}/{y}.png";
  static const String defaultTileUserAgent = "pinpoint";

  static const defaultSettings = {
    theme: "system",
    startPage: "/map",
    lastListId: 0,
    lastMapLatitude: 52.517848902676384,
    lastMapLongitude: 13.393738827437122,
    lastMapZoom: 12.0,
    lastMapRotationLocked: false,
    checkForUpdates: false,
    tileUrlTemplate: defaultTileUrlTemplate,
    tileUserAgent: defaultTileUserAgent,
  };

  Future<void> init() async {
    _preferences = await SharedPreferences.getInstance();
  }

  dynamic get(String key) {
    return _preferences.get(key) ?? defaultSettings[key];
  }

  void set(String key, dynamic value) {
    if (value is String) {
      _preferences.setString(key, value);
    } else if (value is int) {
      _preferences.setInt(key, value);
    } else if (value is double) {
      _preferences.setDouble(key, value);
    } else if (value is bool) {
      _preferences.setBool(key, value);
    } else if (value is List<String>) {
      _preferences.setStringList(key, value);
    }
    notifyListeners();
  }

  void remove(String key) {
    _preferences.remove(key);
    notifyListeners();
  }
}
