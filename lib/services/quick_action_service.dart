import 'package:flutter/material.dart';
import 'package:quick_actions/quick_actions.dart';

class QuickActionService {
  static final QuickActions _quickActions = const QuickActions();
  static bool _isInitialized = false;

  static void init(void Function(String) onAction) {
    if (_isInitialized) return;
    _isInitialized = true;

    _quickActions.setShortcutItems(<ShortcutItem>[
      const ShortcutItem(
        type: 'action_add',
        localizedTitle: 'Add Transaction',
        icon: 'action_add',
      ),
      const ShortcutItem(
        type: 'action_activity',
        localizedTitle: 'View Activity',
        icon: 'action_activity',
      ),
      const ShortcutItem(
        type: 'action_assistant',
        localizedTitle: 'Talk to AI',
        icon: 'action_assistant',
      ),
    ]);

    _quickActions.initialize((String shortcutType) {
      onAction(shortcutType);
    });
  }
}

// Simple routing helper used in main.dart
class ShortcutHandler {
  static void handle(String type, GlobalKey<NavigatorState> navigatorKey) {
    switch (type) {
      case 'action_add':
        // We'll navigate to the Home tab and trigger the Add Transaction modal or screen
        // Depending on existing project structure, we might need a specific route
        navigatorKey.currentState?.pushNamed('/add_transaction');
        break;
      case 'action_activity':
        // Navigate and switch tab
        navigatorKey.currentState?.pushNamed('/dashboard', arguments: 1);
        break;
      case 'action_assistant':
        // Navigate and switch tab
        navigatorKey.currentState?.pushNamed('/dashboard', arguments: 4);
        break;
    }
  }
}
