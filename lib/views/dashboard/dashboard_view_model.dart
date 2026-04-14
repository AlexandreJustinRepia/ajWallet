import 'package:flutter/material.dart';
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
    _selectedIndex = index;
    notifyListeners();
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

  Future<void> checkFirstRun() async {
    final account = SessionService.activeAccount;
    if (account != null && !account.hasSeenTutorial) {
      await Future.delayed(const Duration(milliseconds: 1000));
      setShowTutorial(true);
    }
  }

  Future<void> finishTutorial() async {
    setShowTutorial(false);
    final account = SessionService.activeAccount;
    if (account != null) {
      account.hasSeenTutorial = true;
      await DatabaseService.updateAccount(account);
    }
  }

  void refresh() {
    notifyListeners();
  }
}
