import 'package:flutter/material.dart';
import '../../services/session_service.dart';
import '../../widgets/onboarding_overlay.dart';
import '../home_view.dart';
import '../activity_view.dart';
import '../wallets_view.dart';
import '../planning_view.dart';
import '../../widgets/ai_assistant_view.dart';
import '../../add_transaction_screen.dart';
import '../../wallet_form_screen.dart';
import '../../account_list_screen.dart';
import 'dashboard_view_model.dart';
import 'dashboard_keys.dart';
import 'onboarding_controller.dart';
import 'widgets/dashboard_app_bar.dart';
import 'widgets/dashboard_bottom_nav.dart';
import 'widgets/dashboard_update_banner.dart';

class DashboardScreen extends StatefulWidget {
  final int initialIndex;
  const DashboardScreen({super.key, this.initialIndex = 0});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late DashboardViewModel _viewModel;
  late DashboardKeys _keys;
  late OnboardingController _onboardingController;

  @override
  void initState() {
    super.initState();
    _viewModel = DashboardViewModel(initialIndex: widget.initialIndex);
    _keys = DashboardKeys();
    _onboardingController = OnboardingController(
      viewModel: _viewModel,
      keys: _keys,
    );
    _viewModel.checkTutorialForTab(0);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final theme = Theme.of(context);
        final accountKey = SessionService.activeAccount?.key as int?;

        final pages = [
          HomeView(
            onRefresh: _viewModel.refresh,
            balanceKey: _keys.balanceKey,
            quickAddKey: _keys.quickAddKey,
            treeKey: _keys.treeKey,
            activityHeaderKey: _keys.activityHeaderKey,
            sampleTransactionKey: _keys.sampleTransactionKey,
            isTutorialActive: _viewModel.showTutorial && _viewModel.selectedIndex == 0,
          ),
          ActivityView(
            onRefresh: _viewModel.refresh,
            isTutorialActive: _viewModel.showTutorial && _viewModel.selectedIndex == 1,
            listAreaKey: _keys.activityListAreaKey,
            singleItemKey: _keys.activitySingleItemKey,
            dateHeaderKey: _keys.activityDateHeaderKey,
            colorIndicatorKey: _keys.activityColorIndicatorKey,
            filterChipsKey: _keys.activityFilterChipsKey,
            searchBarKey: _keys.activitySearchBarKey,
            calendarTabKey: _keys.activityCalendarTabKey,
            calendarAreaKey: _keys.activityCalendarAreaKey,
            squadsTabKey: _keys.squadsTabKey,
            squadsListKey: _keys.squadsListKey,
            squadsCreateBtnKey: _keys.squadsCreateBtnKey,
            onTabChanged: _viewModel.setActivityCurrentTabIndex,
            overrideTabIndex: _viewModel.activityTutorialTabIndex,
          ),
          WalletsView(
            onRefresh: _viewModel.refresh,
            walletListKey: _keys.walletListKey,
            singleWalletKey: _keys.singleWalletKey,
            lifeOfMoneyKey: _keys.lifeOfMoneyKey,
          ),
          PlanningView(
            onRefresh: _viewModel.refresh,
            isTutorialActive: _viewModel.showTutorial && _viewModel.selectedIndex == 3,
            budgetSectionKey: _keys.planBudgetSectionKey,
            budgetAddKey: _keys.planBudgetAddKey,
            budgetIndicatorKey: _keys.planBudgetIndicatorKey,
            goalSectionKey: _keys.planGoalSectionKey,
            goalAddKey: _keys.planGoalAddKey,
            goalFundKey: _keys.planGoalFundKey,
            goalWithdrawKey: _keys.planGoalWithdrawKey,
            debtSectionKey: _keys.planDebtSectionKey,
            debtAddKey: _keys.planDebtAddKey,
          ),
          const AIAssistantView(),
        ];

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: DashboardAppBar(
            selectedIndex: _viewModel.selectedIndex,
            onRefresh: _viewModel.refresh,
            onLogout: () => _handleLogout(context),
            onHelp: () => _viewModel.setShowTutorial(true),
          ),
          body: OnboardingOverlay(
            visible: _viewModel.showTutorial,
            steps: _onboardingController.getSteps(context),
            onFinish: _viewModel.finishTutorial,
            child: Stack(
              children: [
                Column(
                  children: [
                    const DashboardUpdateBanner(),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () async {
                          _viewModel.refresh();
                          await Future.delayed(const Duration(milliseconds: 500));
                        },
                        child: pages[_viewModel.selectedIndex],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          floatingActionButton: _viewModel.selectedIndex == 4
              ? null
              : FloatingActionButton(
                  key: _keys.walletsFabKey,
                  onPressed: () => _onFabPressed(context, accountKey),
                  child: const Icon(Icons.add_rounded, size: 28),
                ),
          bottomNavigationBar: DashboardBottomNav(
            selectedIndex: _viewModel.selectedIndex,
            onSelected: _viewModel.setSelectedIndex,
            keys: _keys,
          ),
        );
      },
    );
  }

  Future<void> _onFabPressed(BuildContext context, int? accountKey) async {
    if (accountKey == null) return;

    final targetScreen = _viewModel.selectedIndex == 2
        ? WalletFormScreen(accountKey: accountKey)
        : AddTransactionScreen(accountKey: accountKey);

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => targetScreen),
    );
    if (!mounted) return;
    if (result == true) _viewModel.refresh();
  }

  void _handleLogout(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const AccountListScreen()),
      (route) => false,
    );
  }
}
