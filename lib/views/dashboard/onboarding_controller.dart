import 'package:flutter/material.dart';
import '../../widgets/onboarding_overlay.dart';
import '../../add_transaction_screen.dart';
import '../../wallet_form_screen.dart';
import '../../screens/add_budget_screen.dart';
import '../../screens/add_goal_screen.dart';
import '../../screens/add_debt_screen.dart';
import '../../services/session_service.dart';
import 'dashboard_view_model.dart';
import 'dashboard_keys.dart';

class OnboardingController {
  final DashboardViewModel viewModel;
  final DashboardKeys keys;

  OnboardingController({required this.viewModel, required this.keys});

  List<OnboardingStep> getSteps(BuildContext context) {
    final accountKey = SessionService.activeAccount?.key as int?;

    return [
      OnboardingStep(
        targetKey: keys.balanceKey,
        title: 'Total Balance',
        description: 'This is your Total Balance — it shows how much money you currently have across your wallets.',
        onStepEnter: () => _scrollTo(keys.balanceKey, 0.1),
      ),
      OnboardingStep(
        targetKey: keys.quickAddKey,
        title: 'Quick Add',
        description: 'Use Quick Add to instantly record a transaction without leaving the home screen.',
        onStepEnter: () => _scrollTo(keys.quickAddKey, 0.3),
      ),
      OnboardingStep(
        targetKey: keys.quickAddKey,
        title: 'Smart Parsing',
        description: 'For example, enter "250 Food" to quickly log an expense. AJ Wallet automatically detects the amount and category!',
        onStepEnter: () {
          keys.quickAddKey.currentState?.simulateTyping('250 Food');
          _scrollTo(keys.quickAddKey, 0.3);
        },
      ),
      OnboardingStep(
        targetKey: keys.balanceKey,
        title: 'Automatic Updates',
        description: 'Your balance updates automatically after adding a transaction, giving you a real-time view of your finances.',
        onStepEnter: () async {
          _scrollTo(keys.balanceKey, 0.1);
          await Future.delayed(const Duration(milliseconds: 300));
          await keys.quickAddKey.currentState?.simulateSubmit();
        },
      ),
      OnboardingStep(
        targetKey: keys.treeKey,
        title: 'Your Financial Tree',
        description: 'Meet your interactive financial tree! It grows as your balance increases and reacts in real-time to every transaction you record.',
        onStepEnter: () => _scrollTo(keys.treeKey, 0.2),
      ),
      OnboardingStep(
        targetKey: keys.treeKey,
        title: 'Visualize Progress',
        description: 'Watch the leaves flutter when you spend, and see it grow majestic green as your wealth builds up. It\'s a living map of your journey!',
      ),
      OnboardingStep(
        targetKey: keys.activityHeaderKey,
        title: 'Recent Activity',
        description: 'Here you can see your latest transactions in real-time. Stay on top of your spending at a glance.',
        onStepEnter: () => _scrollTo(keys.activityHeaderKey, 0.5),
      ),
      OnboardingStep(
        targetKey: keys.sampleTransactionKey,
        title: 'Transaction Details',
        description: 'Each entry shows the amount, category, and type of transaction. Tap any item to see more details.',
        onStepEnter: () => _scrollTo(keys.sampleTransactionKey, 0.6),
      ),
      OnboardingStep(
        targetKey: keys.activityTabKey,
        title: 'Transactions Tab',
        description: 'Tap here to view all your transactions in detail.',
        onStepEnter: () {
          viewModel.setOverlayState(DashboardOverlayState.none);
        },
      ),
      OnboardingStep(
        targetKey: keys.activityListAreaKey,
        title: 'Transaction List',
        description: 'This is where all your transactions are displayed.',
        onStepEnter: () {
          viewModel.setSelectedIndex(1);
          viewModel.setOverlayState(DashboardOverlayState.none);
        },
      ),
      OnboardingStep(
        targetKey: keys.activitySingleItemKey,
        title: 'Transaction Details',
        description: 'Each transaction shows the amount, category, and type (income, expense, or transfer).',
      ),
      OnboardingStep(
        targetKey: keys.activityColorIndicatorKey,
        title: 'Color Indicators',
        description: 'Quickly identify transactions — income, expenses, and transfers have different colors!',
      ),
      OnboardingStep(
        targetKey: keys.activityDateHeaderKey,
        title: 'Timeline',
        description: 'Transactions are organized by date so you can easily track your activity.',
      ),
      OnboardingStep(
        targetKey: keys.activityFilterChipsKey,
        title: 'Filters',
        description: 'Use filters to quickly find specific transactions.',
        onStepEnter: () => _scrollTo(keys.activityFilterChipsKey, 0.1),
      ),
      OnboardingStep(
        targetKey: keys.activitySearchBarKey,
        title: 'Search Bar',
        description: 'Search for transactions by keyword, category, or amount.',
        onStepEnter: () => _scrollTo(keys.activitySearchBarKey, 0.1),
      ),
      OnboardingStep(
        targetKey: keys.activitySingleItemKey,
        title: 'View Details',
        description: 'Tap a transaction to view more details.',
        onStepEnter: () {
          _scrollTo(keys.activitySingleItemKey, 0.5);
          viewModel.setOverlayState(DashboardOverlayState.none);
        },
      ),
      OnboardingStep(
        targetKey: keys.fakeDetailsModalKey,
        title: 'Transaction Details',
        description: 'Here you can see complete information about the transaction.',
        onStepEnter: () {
          viewModel.setOverlayState(DashboardOverlayState.details);
        },
      ),
      OnboardingStep(
        targetKey: keys.fakeDetailsEditIconKey,
        title: 'Edit Transaction',
        description: 'Tap here to edit this transaction.',
      ),
      OnboardingStep(
        targetKey: keys.fakeDetailsDeleteIconKey,
        title: 'Delete Transaction',
        description: 'Tap here to delete this transaction if needed.',
        onStepEnter: () async {
          if (!viewModel.hasShownEditTutorial) {
            viewModel.markEditTutorialAsShown();
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddTransactionScreen(
                  accountKey: accountKey ?? 0,
                  isTutorialMode: true,
                ),
              ),
            );
          }
        },
      ),
      OnboardingStep(
        targetKey: keys.fakeDetailsDeleteIconKey,
        title: 'Permanent Deletion',
        description: 'Deleting will permanently remove this transaction from your records.',
        onStepEnter: () {
          viewModel.setOverlayState(DashboardOverlayState.deleteConfirm);
        },
      ),
      OnboardingStep(
        targetKey: keys.fakeDeleteConfirmKey,
        title: 'Confirm Delete',
        description: 'Confirm to delete the transaction.',
      ),
      OnboardingStep(
        title: 'Easily Manageable',
        description: 'Your transactions are always editable and easy to manage!',
        onStepEnter: () {
          viewModel.setOverlayState(DashboardOverlayState.none);
        },
      ),
      OnboardingStep(
        targetKey: keys.activityCalendarTabKey,
        title: 'Calendar View',
        description: 'Switch to the Calendar View to see your activity across the month.',
        onStepEnter: () {
          viewModel.setOverlayState(DashboardOverlayState.none);
          viewModel.setActivityTutorialTabIndex(0);
        },
      ),
      OnboardingStep(
        targetKey: keys.activityCalendarAreaKey,
        title: 'Monthly Calendar',
        description: 'Days with transactions will have a bright marker dot. Tap on any day to see its summary!',
        onStepEnter: () {
          viewModel.setActivityTutorialTabIndex(1);
        },
      ),
      OnboardingStep(
        targetKey: keys.walletsTabKey,
        title: 'Wallets Tab',
        description: 'Tap here to manage your wallets.',
        onStepEnter: () {
          viewModel.setOverlayState(DashboardOverlayState.none);
          viewModel.setActivityTutorialTabIndex(0);
        },
      ),
      OnboardingStep(
        targetKey: keys.walletListKey,
        title: 'Your Wallets',
        description: 'Here you can see all your wallets in one place.',
        onStepEnter: () {
          viewModel.setSelectedIndex(2);
        },
      ),
      OnboardingStep(
        targetKey: keys.singleWalletKey,
        title: 'Wallet Balances',
        description: 'Each wallet shows your current balance.',
      ),
      OnboardingStep(
        targetKey: keys.walletsFabKey,
        title: 'Add Wallet',
        description: 'Tap here to add a new wallet.',
        onStepEnter: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => WalletFormScreen(
                accountKey: accountKey ?? 0,
                isTutorialMode: true,
              ),
            ),
          );
        },
      ),
      OnboardingStep(
        targetKey: keys.lifeOfMoneyKey,
        title: 'Life of Your Money',
        description: 'This shows how long your money will last.',
        onStepEnter: () => _scrollTo(keys.lifeOfMoneyKey, 0.1),
      ),
      OnboardingStep(
        targetKey: keys.lifeOfMoneyKey,
        title: 'Dynamic Calculation',
        description: 'It’s based on your daily spending habits.',
      ),
      OnboardingStep(
        targetKey: keys.lifeOfMoneyKey,
        title: 'Real-time Updates',
        description: 'As your spending changes, this adjusts automatically.',
      ),
      OnboardingStep(
        targetKey: keys.planTabKey,
        title: 'Plan Tab',
        description: 'Tap here to manage your financial plans.',
        onStepEnter: () {
          viewModel.setSelectedIndex(3);
        },
      ),
      OnboardingStep(
        title: 'Financial Planning',
        description: 'Plan your money with budgets, savings, and debt tracking.',
      ),
      OnboardingStep(
        targetKey: keys.planBudgetSectionKey,
        title: 'Monthly Budget',
        description: 'Set limits for your spending categories.',
        onStepEnter: () => _scrollTo(keys.planBudgetSectionKey, 0.1),
      ),
      OnboardingStep(
        targetKey: keys.planBudgetAddKey,
        title: 'Add Budget',
        description: 'Tap here to create a new budget.',
        onStepEnter: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddBudgetScreen(
                accountKey: accountKey ?? 0,
                isTutorialMode: true,
              ),
            ),
          );
        },
      ),
      OnboardingStep(
        targetKey: keys.planBudgetIndicatorKey,
        title: 'Track Your Limits',
        description: 'When you add transactions, you\'ll see how much budget is left.',
        onStepEnter: () => _scrollTo(keys.planBudgetSectionKey, 0.2),
      ),
      OnboardingStep(
        targetKey: keys.planGoalSectionKey,
        title: 'Savings Goals',
        description: 'Save money for your future plans.',
        onStepEnter: () => _scrollTo(keys.planGoalSectionKey, 0.2),
      ),
      OnboardingStep(
        targetKey: keys.planGoalAddKey,
        title: 'Add Goal',
        description: 'Tap here to create a savings goal.',
        onStepEnter: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddGoalScreen(
                accountKey: accountKey ?? 0,
                isTutorialMode: true,
              ),
            ),
          );
        },
      ),
      OnboardingStep(
        targetKey: keys.planGoalFundKey,
        title: 'Add to Savings',
        description: 'Add money to your goal — it will be deducted from your balance.',
        onStepEnter: () => _scrollTo(keys.planGoalFundKey, 0.4),
      ),
      OnboardingStep(
        targetKey: keys.planGoalWithdrawKey,
        title: 'Withdraw Target',
        description: 'Withdraw anytime — it will return to your balance.',
      ),
      OnboardingStep(
        targetKey: keys.planDebtSectionKey,
        title: 'Debts & Loans',
        description: 'Track money you gave or borrowed.',
        onStepEnter: () => _scrollTo(keys.planDebtSectionKey, 0.4),
      ),
      OnboardingStep(
        targetKey: keys.planDebtAddKey,
        title: 'Record Debt',
        description: 'Tap here to record a debt or loan.',
        onStepEnter: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddDebtScreen(
                accountKey: accountKey ?? 0,
                isTutorialMode: true,
              ),
            ),
          );
        },
      ),
      OnboardingStep(
        title: 'Balance Reflections',
        description: 'Giving money deducts from your wallet. Borrowing adds to your wallet.',
      ),
      OnboardingStep(
        title: 'Manage Your Finances',
        description: 'Now you can budget, save, and track debts easily!',
        onStepEnter: () {
          viewModel.setOverlayState(DashboardOverlayState.none);
          viewModel.setActivityTutorialTabIndex(0);
        },
      ),
    ];
  }

  void _scrollTo(GlobalKey key, double alignment) {
    final context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
        alignment: alignment,
      );
    }
  }
}
