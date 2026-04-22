import 'package:flutter/material.dart';
import '../../widgets/onboarding_overlay.dart';
// Removed unused import
import '../../wallet_form_screen.dart';
import '../../screens/add_budget_screen.dart';
import '../../screens/add_goal_screen.dart';
import '../../screens/add_debt_screen.dart';
import '../../services/session_service.dart';
import 'dashboard_view_model.dart';
import '../../transaction_details_screen.dart';
import '../../models/transaction_model.dart';
import 'dashboard_keys.dart';

class OnboardingController {
  final DashboardViewModel viewModel;
  final DashboardKeys keys;

  OnboardingController({required this.viewModel, required this.keys});

  List<OnboardingStep> getSteps(BuildContext context) {
    switch (viewModel.selectedIndex) {
      case 0:
        return _getHomeSteps(context);
      case 1:
        if (viewModel.activityCurrentTabIndex == 2) {
          return _getSquadSteps(context);
        }
        return _getActivitySteps(context);
      case 2:
        return _getWalletsSteps(context);
      case 3:
        return _getPlanSteps(context);
      default:
        return [];
    }
  }

  List<OnboardingStep> _getHomeSteps(BuildContext context) {
    return [
      OnboardingStep(
        targetKey: keys.balanceKey,
        title: 'Total Balance',
        description:
            'This is your Total Balance — it shows how much money you currently have across your wallets.',
        scrollAlignment: 0.1,
      ),
      OnboardingStep(
        targetKey: keys.quickAddKey,
        title: 'Quick Add',
        description:
            'Use Quick Add to instantly record a transaction without leaving the home screen.',
        scrollAlignment: 0.3,
      ),
      OnboardingStep(
        targetKey: keys.quickAddKey,
        title: 'Smart Parsing',
        description:
            'For example, enter "250 Food" to quickly log an expense. AJ Wallet automatically detects the amount and category!',
        scrollAlignment: 0.3,
        onStepEnter: () {
          keys.quickAddKey.currentState?.simulateTyping('250 Food');
        },
      ),
      OnboardingStep(
        targetKey: keys.balanceKey,
        title: 'Automatic Updates',
        description:
            'Your balance updates automatically after adding a transaction, giving you a real-time view of your finances.',
        scrollAlignment: 0.1,
        onStepEnter: () async {
          await Future.delayed(const Duration(milliseconds: 300));
          await keys.quickAddKey.currentState?.simulateSubmit();
        },
      ),
      OnboardingStep(
        targetKey: keys.treeKey,
        title: 'Your Financial Tree',
        description:
            'This tree is the heart of RootEXP. It\'s a living visualization of your wealth. As your balance grows, the tree grows more branches and lush leaves.',
        scrollAlignment: 0.2,
      ),
      OnboardingStep(
        targetKey: keys.treeKey,
        title: 'Real-Time Health Indicator',
        description:
            'The tree doesn\'t just look pretty—it reacts to your habits. Healthy saving makes it bloom flowers, while overspending causes it to shed leaves. It\'s your financial discipline, visualized.',
      ),
      OnboardingStep(
        targetKey: keys.activityHeaderKey,
        title: 'Recent Activity',
        description:
            'Here you can see your latest transactions in real-time. Stay on top of your spending at a glance.',
        scrollAlignment: 0.5,
      ),
      OnboardingStep(
        targetKey: keys.sampleTransactionKey,
        title: 'Activity List',
        description:
            'Each entry here gives you a quick snapshot of your transaction. For full management tools, you can tap on these items.',
        scrollAlignment: 0.6,
      ),
    ];
  }

  List<OnboardingStep> _getSquadSteps(BuildContext context) {
    return [
      OnboardingStep(
        targetKey: keys.squadsListKey,
        title: 'Squads',
        description: 'Here you can manage expenses shared with your friends or family.',
        onStepEnter: () {
          viewModel.setOverlayState(DashboardOverlayState.none);
          viewModel.setActivityTutorialTabIndex(2);
        },
      ),
      OnboardingStep(
        targetKey: keys.squadsCreateBtnKey,
        title: 'Create a Squad',
        description: 'Start by creating your first squad to keep track of shared bills and group debts.',
      ),
    ];
  }

  List<OnboardingStep> _getActivitySteps(BuildContext context) {
    final accountKey = SessionService.activeAccount?.key as int?;
    return [
      OnboardingStep(
        targetKey: keys.activityListAreaKey,
        title: 'Transaction List',
        description: 'This is where all your transactions are displayed.',
        onStepEnter: () {
          viewModel.setOverlayState(DashboardOverlayState.none);
          viewModel.setActivityTutorialTabIndex(0);
        },
      ),
      OnboardingStep(
        targetKey: keys.activitySingleItemKey,
        title: 'Transaction Details',
        description:
            'Each transaction shows the amount, category, and type (income, expense, or transfer).',
      ),
      OnboardingStep(
        targetKey: keys.activityColorIndicatorKey,
        title: 'Color Indicators',
        description:
            'Quickly identify transactions — income, expenses, and transfers have different colors!',
      ),
      OnboardingStep(
        targetKey: keys.activityDateHeaderKey,
        title: 'Timeline',
        description:
            'Transactions are organized by date so you can easily track your activity.',
      ),
      OnboardingStep(
        targetKey: keys.activityFilterChipsKey,
        title: 'Filters',
        description: 'Use filters to quickly find specific transactions.',
        scrollAlignment: 0.1,
      ),
      OnboardingStep(
        targetKey: keys.activitySearchBarKey,
        title: 'Search Bar',
        description: 'Search for transactions by keyword, category, or amount.',
        scrollAlignment: 0.1,
      ),
      OnboardingStep(
        targetKey: keys.activitySingleItemKey,
        title: 'Manage Transactions',
        description:
            'To edit or delete a transaction, you first need to tap on it to view its full details.',
        scrollAlignment: 0.5,
        onStepEnter: () {
          Future.delayed(const Duration(milliseconds: 300), () {
            if (context.mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TransactionDetailsScreen(
                    transaction: Transaction(
                      title: 'Lunch',
                      accountKey: accountKey ?? 0,
                      amount: 250.00,
                      category: 'Food',
                      description: 'Grocery Run',
                      date: DateTime.now(),
                      type: TransactionType.expense,
                      walletKey: 0,
                    ),
                    editKey: keys.detailsEditKey,
                    deleteKey: keys.detailsDeleteKey,
                    tutorialSteps: [
                      OnboardingStep(
                        targetKey: keys.detailsEditKey,
                        title: 'Edit Transaction',
                        description:
                            'This pencil icon allows you to modify the transaction if you made a mistake.',
                      ),
                      OnboardingStep(
                        targetKey: keys.detailsDeleteKey,
                        title: 'Delete Transaction',
                        description:
                            'If you need to remove the record entirely, use this trash icon.',
                      ),
                      OnboardingStep(
                        title: 'Transaction Management',
                        description:
                            'Managing your finances is that simple! Your balance and tree will update automatically whenever you make changes.',
                      ),
                    ],
                  ),
                ),
              );
            }
          });
        },
      ),
      OnboardingStep(
        targetKey: keys.activityCalendarTabKey,
        title: 'Calendar View',
        description:
            'Switch to the Calendar View to see your activity across the month.',
        onStepEnter: () {
          viewModel.setOverlayState(DashboardOverlayState.none);
          viewModel.setActivityTutorialTabIndex(0);
        },
      ),
      OnboardingStep(
        targetKey: keys.activityCalendarAreaKey,
        title: 'Monthly Calendar',
        description:
            'Days with transactions will have a bright marker dot. Tap on any day to see its summary!',
        onStepEnter: () {
          viewModel.setActivityTutorialTabIndex(1);
        },
      ),
    ];
  }

  List<OnboardingStep> _getWalletsSteps(BuildContext context) {
    final accountKey = SessionService.activeAccount?.key as int?;
    return [
      OnboardingStep(
        targetKey: keys.walletListKey,
        title: 'Your Wallets',
        description: 'Here you can see all your wallets in one place.',
        onStepEnter: () {
          viewModel.setOverlayState(DashboardOverlayState.none);
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
        scrollAlignment: 0.1,
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
    ];
  }

  List<OnboardingStep> _getPlanSteps(BuildContext context) {
    final accountKey = SessionService.activeAccount?.key as int?;
    
    final allSteps = [
      OnboardingStep(
        title: 'Financial Planning',
        description:
            'Plan your money with budgets, savings, and debt tracking.',
        onStepEnter: () {
          viewModel.setOverlayState(DashboardOverlayState.none);
        },
      ),
      OnboardingStep(
        targetKey: keys.planBudgetSectionKey,
        title: 'Monthly Budget',
        description: 'Set limits for your spending categories.',
        scrollAlignment: 0.1,
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
        description:
            'When you add transactions, you\'ll see how much budget is left.',
        scrollAlignment: 0.2,
      ),
      OnboardingStep(
        targetKey: keys.planGoalSectionKey,
        title: 'Savings Goals',
        description: 'Save money for your future plans.',
        scrollAlignment: 0.2,
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
        description:
            'Add money to your goal — it will be deducted from your balance.',
        scrollAlignment: 0.4,
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
        scrollAlignment: 0.4,
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
        targetKey: keys.planShoppingSectionKey,
        title: 'Smart Shopping List',
        description: 'Organize your grocery runs and shopping trips with ease.',
        scrollAlignment: 0.3,
      ),
      OnboardingStep(
        targetKey: keys.planShoppingAddKey,
        title: 'Create a List',
        description: 'Tap here to create a new shopping list. You can specify a store and even track your progress as you buy!',
      ),
      OnboardingStep(
        targetKey: keys.planShoppingSectionKey,
        title: 'Visual Items',
        description: 'Inside each list, you can add items with photos to create a visual and intuitive planning environment.',
      ),
      OnboardingStep(
        title: 'Balance Reflections',
        description:
            'Giving money deducts from your wallet. Borrowing adds to your wallet.',
      ),
      OnboardingStep(
        title: 'Manage Your Finances',
        description: 'Now you can budget, save, and track debts easily!',
      ),
    ];

    if (viewModel.planTutorialSection == 'shopping') {
      return allSteps.where((s) => s.targetKey == keys.planShoppingSectionKey || s.targetKey == keys.planShoppingAddKey).toList();
    }

    return allSteps;
  }
}
