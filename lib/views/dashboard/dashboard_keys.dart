import 'package:flutter/material.dart';
import '../../widgets/quick_add_input.dart';

class DashboardKeys {
  // Home Onboarding Keys
  final GlobalKey balanceKey = GlobalKey();
  final GlobalKey<QuickAddInputState> quickAddKey = GlobalKey<QuickAddInputState>();
  final GlobalKey treeKey = GlobalKey();
  final GlobalKey activityHeaderKey = GlobalKey();
  final GlobalKey sampleTransactionKey = GlobalKey();

  // Activity Onboarding Keys
  final GlobalKey activityTabKey = GlobalKey();
  final GlobalKey activityListAreaKey = GlobalKey();
  final GlobalKey activitySingleItemKey = GlobalKey();
  final GlobalKey activityDateHeaderKey = GlobalKey();
  final GlobalKey activityColorIndicatorKey = GlobalKey();
  final GlobalKey activityFilterChipsKey = GlobalKey();
  final GlobalKey activitySearchBarKey = GlobalKey();
  final GlobalKey activityCalendarTabKey = GlobalKey();
  final GlobalKey activityCalendarAreaKey = GlobalKey();

  // Squads Onboarding Keys
  final GlobalKey squadsTabKey = GlobalKey();
  final GlobalKey squadsListKey = GlobalKey();
  final GlobalKey squadsCreateBtnKey = GlobalKey();

  // Wallets Onboarding Keys
  final GlobalKey walletsTabKey = GlobalKey();
  final GlobalKey walletsFabKey = GlobalKey();
  final GlobalKey walletListKey = GlobalKey();
  final GlobalKey singleWalletKey = GlobalKey();
  final GlobalKey lifeOfMoneyKey = GlobalKey();

  // Plan Onboarding Keys
  final GlobalKey planTabKey = GlobalKey();
  final GlobalKey planBudgetSectionKey = GlobalKey();
  final GlobalKey planBudgetAddKey = GlobalKey();
  final GlobalKey planBudgetIndicatorKey = GlobalKey();
  final GlobalKey planGoalSectionKey = GlobalKey();
  final GlobalKey planGoalAddKey = GlobalKey();
  final GlobalKey planGoalFundKey = GlobalKey();
  final GlobalKey planGoalWithdrawKey = GlobalKey();
  final GlobalKey planDebtSectionKey = GlobalKey();
  final GlobalKey planDebtAddKey = GlobalKey();

  // Real Details Keys
  final GlobalKey detailsEditKey = GlobalKey();
  final GlobalKey detailsDeleteKey = GlobalKey();

  // Fake Details Mock Keys (Keeping for compat if needed, but will move to real ones)
  final GlobalKey fakeDetailsModalKey = GlobalKey();
  final GlobalKey fakeDetailsEditIconKey = GlobalKey();
  final GlobalKey fakeDetailsDeleteIconKey = GlobalKey();
  final GlobalKey fakeDeleteConfirmKey = GlobalKey();
  // Analytics Dashboard Keys
  final GlobalKey analyticsBurnRateKey = GlobalKey();
  final GlobalKey analyticsSavingsRateKey = GlobalKey();
  final GlobalKey analyticsPieChartKey = GlobalKey();
  final GlobalKey analyticsTrendBarKey = GlobalKey();
  final GlobalKey analyticsNotableHabitsKey = GlobalKey();
  final GlobalKey analyticsStrategicInsightsKey = GlobalKey();
}
