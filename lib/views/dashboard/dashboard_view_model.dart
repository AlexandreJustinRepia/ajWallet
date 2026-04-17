import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../services/session_service.dart';
import '../../services/database_service.dart';

enum DashboardOverlayState { none, details, deleteConfirm }

class DashboardViewModel extends ChangeNotifier {
  int _selectedIndex = 0;
  bool _showTutorial = false;
  DashboardOverlayState _overlayState = DashboardOverlayState.none;
  int _activityTutorialTabIndex = 0;
  bool _hasShownEditTutorial = false;

  int get selectedIndex => _selectedIndex;
  bool get showTutorial => _showTutorial;
  DashboardOverlayState get overlayState => _overlayState;
  int get activityTutorialTabIndex => _activityTutorialTabIndex;
  bool get hasShownEditTutorial => _hasShownEditTutorial;

  void setSelectedIndex(int index) {
    if (_selectedIndex != index) {
      _selectedIndex = index;
      notifyListeners();
      checkTutorialForTab(index);
    }
  }

  void setShowTutorial(bool show) {
    _showTutorial = show;
    notifyListeners();
  }

  void setOverlayState(DashboardOverlayState state) {
    _overlayState = state;
    notifyListeners();
  }

  void setActivityTutorialTabIndex(int index) {
    _activityTutorialTabIndex = index;
    notifyListeners();
  }

  void markEditTutorialAsShown() {
    _hasShownEditTutorial = true;
    notifyListeners();
  }

  Future<void> checkTutorialForTab(int tabIndex) async {
    final box = await Hive.openBox('settings');
    bool hasSeen = false;
    switch (tabIndex) {
      case 0:
        hasSeen = box.get('has_seen_home_tutorial', defaultValue: false);
        break;
      case 1:
        hasSeen = box.get('has_seen_activity_tutorial', defaultValue: false);
        break;
      case 2:
        hasSeen = box.get('has_seen_wallets_tutorial', defaultValue: false);
        break;
      case 3:
        hasSeen = box.get('has_seen_plan_tutorial', defaultValue: false);
        break;
      default:
        return;
    }
    
    if (!hasSeen) {
      await Future.delayed(const Duration(milliseconds: 500));
      setShowTutorial(true);
    }
  }

  Future<void> finishTutorial() async {
    setShowTutorial(false);
    final box = await Hive.openBox('settings');
    switch (_selectedIndex) {
      case 0:
        await box.put('has_seen_home_tutorial', true);
        break;
      case 1:
        await box.put('has_seen_activity_tutorial', true);
        break;
      case 2:
        await box.put('has_seen_wallets_tutorial', true);
        break;
      case 3:
        await box.put('has_seen_plan_tutorial', true);
        break;
    }
    
    // Also mark global as seen just in case
    final account = SessionService.activeAccount;
    if (account != null && !account.hasSeenTutorial) {
      account.hasSeenTutorial = true;
      await DatabaseService.updateAccount(account);
    }
  }

  void refresh() {
    notifyListeners();
  }
}
