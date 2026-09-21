import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:quick_actions/quick_actions.dart';

class QuickActionType {
  static const String location = 'action_location';
  static const String picture = 'action_picture';
  static const String blank = 'action_blank';
}

class QuickActionsService extends ChangeNotifier {
  final QuickActions _quickActions = const QuickActions();
  final GlobalKey<NavigatorState> navigatorKey;

  String? _pendingAction;
  String? get pendingAction => _pendingAction;

  String? _lastActionType;
  DateTime? _lastActionTime;

  QuickActionsService({required this.navigatorKey});

  Future<void> init() async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      return;
    }

    try {
      await _quickActions.initialize((String type) {
        handleAction(type);
      });

      final isAndroid = Platform.isAndroid;

      await _quickActions.setShortcutItems(<ShortcutItem>[
        ShortcutItem(
          type: QuickActionType.location,
          localizedTitle: 'Add at location',
          icon: isAndroid ? 'ic_shortcut_location' : null,
        ),
        ShortcutItem(
          type: QuickActionType.picture,
          localizedTitle: 'Add with picture',
          icon: isAndroid ? 'ic_shortcut_camera' : null,
        ),
        ShortcutItem(
          type: QuickActionType.blank,
          localizedTitle: 'Add blank entry',
          icon: isAndroid ? 'ic_shortcut_add' : null,
        ),
      ]);
    } catch (e, stack) {
      debugPrint('Failed to initialize quick actions: $e\n$stack');
    }
  }

  void handleAction(String type) {
    final now = DateTime.now();
    // On Android cold start, the quick_actions plugin fires the launch shortcut twice
    // (via both getLaunchAction and onAttachedToActivity). Drop duplicate events
    // within a 5-second threshold to prevent dismissing active dialogs/flows.
    if (_pendingAction == type ||
        (_lastActionType == type &&
            _lastActionTime != null &&
            now.difference(_lastActionTime!) < const Duration(seconds: 5))) {
      return;
    }
    _lastActionType = type;
    _lastActionTime = now;

    _pendingAction = type;

    // Ensure we route to MapViewPage where quick actions are handled,
    // popping any open modals or subroutes if the app is already running.
    final nav = navigatorKey.currentState;
    if (nav != null) {
      bool isOnMap = false;
      nav.popUntil((route) {
        if (route.settings.name == '/map') {
          isOnMap = true;
          return true;
        }
        if (route.isFirst) {
          isOnMap = route.settings.name == '/map';
          return true;
        }
        return false;
      });

      if (!isOnMap) {
        nav.pushNamedAndRemoveUntil('/map', (route) => false);
        return;
      }
    }

    notifyListeners();
  }

  String? consumePendingAction() {
    final action = _pendingAction;
    _pendingAction = null;
    return action;
  }
}
