import 'package:flutter/material.dart';
import 'services/session_service.dart';
import 'services/database_service.dart';
import 'models/account.dart';
import 'account_list_screen.dart';
import 'theme_picker_screen.dart';
import 'add_transaction_screen.dart';
import 'wallet_form_screen.dart';
import 'security_settings_screen.dart';
import 'views/home_view.dart';
import 'views/activity_view.dart';
import 'views/wallets_view.dart';
import 'views/planning_view.dart';
import 'screens/add_budget_screen.dart';
import 'screens/add_goal_screen.dart';
import 'screens/add_debt_screen.dart';
import 'widgets/ai_assistant_view.dart';
import 'screens/about_screen.dart';
import 'services/update_service.dart';
import 'widgets/onboarding_overlay.dart';
import 'widgets/quick_add_input.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  bool _showTutorial = false;

  // Onboarding Keys
  final GlobalKey _balanceKey = GlobalKey();
  final GlobalKey<QuickAddInputState> _quickAddKey =
      GlobalKey<QuickAddInputState>();
  final GlobalKey _activityHeaderKey = GlobalKey();
  final GlobalKey _sampleTransactionKey = GlobalKey();

  // Activity Onboarding Keys
  final GlobalKey _activityTabKey = GlobalKey();
  final GlobalKey _activityListAreaKey = GlobalKey();
  final GlobalKey _activitySingleItemKey = GlobalKey();
  final GlobalKey _activityDateHeaderKey = GlobalKey();
  final GlobalKey _activityColorIndicatorKey = GlobalKey();
  final GlobalKey _activityFilterChipsKey = GlobalKey();
  final GlobalKey _activitySearchBarKey = GlobalKey();
  final GlobalKey _activityCalendarTabKey = GlobalKey();
  final GlobalKey _activityCalendarAreaKey = GlobalKey();

  // Wallets Onboarding Keys
  final GlobalKey _walletsTabKey = GlobalKey();
  final GlobalKey _walletsFabKey = GlobalKey();
  final GlobalKey _walletListKey = GlobalKey();
  final GlobalKey _singleWalletKey = GlobalKey();
  final GlobalKey _lifeOfMoneyKey = GlobalKey();

  // Plan Onboarding Keys
  final GlobalKey _planTabKey = GlobalKey();
  final GlobalKey _planBudgetSectionKey = GlobalKey();
  final GlobalKey _planBudgetAddKey = GlobalKey();
  final GlobalKey _planBudgetIndicatorKey = GlobalKey();
  final GlobalKey _planGoalSectionKey = GlobalKey();
  final GlobalKey _planGoalAddKey = GlobalKey();
  final GlobalKey _planGoalFundKey = GlobalKey();
  final GlobalKey _planGoalWithdrawKey = GlobalKey();
  final GlobalKey _planDebtSectionKey = GlobalKey();
  final GlobalKey _planDebtAddKey = GlobalKey();

  // New Edit/Delete Mock Keys
  final GlobalKey _fakeDetailsModalKey = GlobalKey();
  final GlobalKey _fakeDetailsEditIconKey = GlobalKey();
  final GlobalKey _fakeDetailsDeleteIconKey = GlobalKey();
  final GlobalKey _fakeDeleteConfirmKey = GlobalKey();

  // Fake Details Modal State
  bool _showFakeDetailsModal = false;
  bool _showFakeDeleteConfirm = false;
  bool _hasShownEditTutorial = false;
  int _activityTutorialTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _checkFirstRun();
  }

  Future<void> _checkFirstRun() async {
    final account = SessionService.activeAccount;
    if (account != null && !account.hasSeenTutorial) {
      // Small delay to ensure everything is rendered
      await Future.delayed(const Duration(milliseconds: 1000));
      if (mounted) {
        setState(() => _showTutorial = true);
      }
    }
  }

  Future<void> _onTutorialFinish() async {
    setState(() => _showTutorial = false);
    final account = SessionService.activeAccount;
    if (account != null) {
      account.hasSeenTutorial = true;
      await DatabaseService.updateAccount(account);
    }
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

  void _refresh() => setState(() {});

  // ---------------------------------------------------------------------------
  // Branded title widget
  // ---------------------------------------------------------------------------

  Widget _buildRootExpTitle(ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Root',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w500,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(width: 3),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: theme.primaryColor,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            'EXP',
            style: TextStyle(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.w900,
              fontSize: 13,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // App Bar
  // ---------------------------------------------------------------------------

  String get _appBarTitle => switch (_selectedIndex) {
    1 => 'Transactions',
    2 => 'Wallets',
    3 => 'Planning',
    4 => 'Assistant',
    _ => 'RootEXP',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accountKey = SessionService.activeAccount?.key as int?;

    final pages = [
      HomeView(
        onRefresh: _refresh,
        balanceKey: _balanceKey,
        quickAddKey: _quickAddKey,
        activityHeaderKey: _activityHeaderKey,
        sampleTransactionKey: _sampleTransactionKey,
        isTutorialActive: _showTutorial && _selectedIndex == 0,
      ),
      ActivityView(
        onRefresh: _refresh,
        isTutorialActive: _showTutorial && _selectedIndex == 1,
        listAreaKey: _activityListAreaKey,
        singleItemKey: _activitySingleItemKey,
        dateHeaderKey: _activityDateHeaderKey,
        colorIndicatorKey: _activityColorIndicatorKey,
        filterChipsKey: _activityFilterChipsKey,
        searchBarKey: _activitySearchBarKey,
        calendarTabKey: _activityCalendarTabKey,
        calendarAreaKey: _activityCalendarAreaKey,
        overrideTabIndex: _activityTutorialTabIndex,
      ),
      WalletsView(
        onRefresh: _refresh,
        walletListKey: _walletListKey,
        singleWalletKey: _singleWalletKey,
        lifeOfMoneyKey: _lifeOfMoneyKey,
      ),
      PlanningView(
        onRefresh: _refresh,
        isTutorialActive: _showTutorial && _selectedIndex == 3,
        budgetSectionKey: _planBudgetSectionKey,
        budgetAddKey: _planBudgetAddKey,
        budgetIndicatorKey: _planBudgetIndicatorKey,
        goalSectionKey: _planGoalSectionKey,
        goalAddKey: _planGoalAddKey,
        goalFundKey: _planGoalFundKey,
        goalWithdrawKey: _planGoalWithdrawKey,
        debtSectionKey: _planDebtSectionKey,
        debtAddKey: _planDebtAddKey,
      ),
      const AIAssistantView(),
    ];

    final tutorialSteps = [
      OnboardingStep(
        targetKey: _balanceKey,
        title: 'Total Balance',
        description:
            'This is your Total Balance — it shows how much money you currently have across your wallets.',
        onStepEnter: () => _scrollTo(_balanceKey, 0.1),
      ),
      OnboardingStep(
        targetKey: _quickAddKey,
        title: 'Quick Add',
        description:
            'Use Quick Add to instantly record a transaction without leaving the home screen.',
        onStepEnter: () => _scrollTo(_quickAddKey, 0.3),
      ),
      OnboardingStep(
        targetKey: _quickAddKey,
        title: 'Smart Parsing',
        description:
            'For example, enter "250 Food" to quickly log an expense. AJ Wallet automatically detects the amount and category!',
        onStepEnter: () {
          _quickAddKey.currentState?.simulateTyping('250 Food');
          _scrollTo(_quickAddKey, 0.3);
        },
      ),
      OnboardingStep(
        targetKey: _balanceKey,
        title: 'Automatic Updates',
        description:
            'Your balance updates automatically after adding a transaction, giving you a real-time view of your finances.',
        onStepEnter: () async {
          _scrollTo(_balanceKey, 0.1);
          await Future.delayed(const Duration(milliseconds: 300));
          await _quickAddKey.currentState?.simulateSubmit();
        },
      ),
      OnboardingStep(
        targetKey: _activityHeaderKey,
        title: 'Recent Activity',
        description:
            'Here you can see your latest transactions in real-time. Stay on top of your spending at a glance.',
        onStepEnter: () => _scrollTo(_activityHeaderKey, 0.5),
      ),
      OnboardingStep(
        targetKey: _sampleTransactionKey,
        title: 'Transaction Details',
        description:
            'Each entry shows the amount, category, and type of transaction. Tap any item to see more details.',
        onStepEnter: () => _scrollTo(_sampleTransactionKey, 0.6),
      ),
      OnboardingStep(
        targetKey: _activityTabKey,
        title: 'Transactions Tab',
        description: 'Tap here to view all your transactions in detail.',
        onStepEnter: () async {
          setState(() {
            _showFakeDetailsModal = false;
          });
        },
      ),
      OnboardingStep(
        targetKey: _activityListAreaKey,
        title: 'Transaction List',
        description: 'This is where all your transactions are displayed.',
        onStepEnter: () async {
          setState(() {
            _selectedIndex = 1;
            _showFakeDetailsModal = false;
          });
        },
      ),
      OnboardingStep(
        targetKey: _activitySingleItemKey,
        title: 'Transaction Details',
        description:
            'Each transaction shows the amount, category, and type (income, expense, or transfer).',
      ),
      OnboardingStep(
        targetKey: _activityColorIndicatorKey,
        title: 'Color Indicators',
        description:
            'Quickly identify transactions — income, expenses, and transfers have different colors!',
      ),
      OnboardingStep(
        targetKey: _activityDateHeaderKey,
        title: 'Timeline',
        description:
            'Transactions are organized by date so you can easily track your activity.',
      ),
      OnboardingStep(
        targetKey: _activityFilterChipsKey,
        title: 'Filters',
        description: 'Use filters to quickly find specific transactions.',
        onStepEnter: () {
          _scrollTo(_activityFilterChipsKey, 0.1);
        },
      ),
      OnboardingStep(
        targetKey: _activitySearchBarKey,
        title: 'Search Bar',
        description: 'Search for transactions by keyword, category, or amount.',
        onStepEnter: () {
          _scrollTo(_activitySearchBarKey, 0.1);
        },
      ),
      OnboardingStep(
        targetKey: _activitySingleItemKey,
        title: 'View Details',
        description: 'Tap a transaction to view more details.',
        onStepEnter: () {
          _scrollTo(_activitySingleItemKey, 0.5);
          setState(() {
            _showFakeDetailsModal = false;
          });
        },
      ),
      OnboardingStep(
        targetKey: _fakeDetailsModalKey,
        title: 'Transaction Details',
        description:
            'Here you can see complete information about the transaction.',
        onStepEnter: () {
          setState(() {
            _showFakeDetailsModal = true;
            _showFakeDeleteConfirm = false;
          });
        },
      ),
      OnboardingStep(
        targetKey: _fakeDetailsEditIconKey,
        title: 'Edit Transaction',
        description: 'Tap here to edit this transaction.',
      ),
      OnboardingStep(
        targetKey: _fakeDetailsDeleteIconKey,
        title: 'Delete Transaction',
        description: 'Tap here to delete this transaction if needed.',
        onStepEnter: () async {
          if (!_hasShownEditTutorial) {
            _hasShownEditTutorial = true;
            // Push to the AddTransactionScreen in tutorial mode!
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
        targetKey: _fakeDetailsDeleteIconKey,
        title: 'Permanent Deletion',
        description:
            'Deleting will permanently remove this transaction from your records.',
        onStepEnter: () {
          setState(() {
            _showFakeDeleteConfirm = true;
          });
        },
      ),
      OnboardingStep(
        targetKey: _fakeDeleteConfirmKey,
        title: 'Confirm Delete',
        description: 'Confirm to delete the transaction.',
      ),
      OnboardingStep(
        title: 'Easily Manageable',
        description:
            'Your transactions are always editable and easy to manage!',
        onStepEnter: () {
          setState(() {
            _showFakeDetailsModal = false;
            _showFakeDeleteConfirm = false;
          });
        },
      ),
      OnboardingStep(
        targetKey: _activityCalendarTabKey,
        title: 'Calendar View',
        description:
            'Switch to the Calendar View to see your activity across the month.',
        onStepEnter: () {
          setState(() {
            _showFakeDetailsModal = false;
            _activityTutorialTabIndex = 0;
          });
        },
      ),
      OnboardingStep(
        targetKey: _activityCalendarAreaKey,
        title: 'Monthly Calendar',
        description:
            'Days with transactions will have a bright marker dot. Tap on any day to see its summary!',
        onStepEnter: () {
          setState(() {
            _activityTutorialTabIndex = 1;
          });
        },
      ),
      OnboardingStep(
        targetKey: _walletsTabKey,
        title: 'Wallets Tab',
        description: 'Tap here to manage your wallets.',
        onStepEnter: () {
          setState(() {
            _showFakeDetailsModal = false;
            _activityTutorialTabIndex = 0;
          });
        },
      ),
      OnboardingStep(
        targetKey: _walletListKey,
        title: 'Your Wallets',
        description: 'Here you can see all your wallets in one place.',
        onStepEnter: () {
          setState(() {
            _selectedIndex = 2; // Wallets Tab
          });
        },
      ),
      OnboardingStep(
        targetKey: _singleWalletKey,
        title: 'Wallet Balances',
        description: 'Each wallet shows your current balance.',
      ),
      OnboardingStep(
        targetKey: _walletsFabKey,
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
        targetKey: _lifeOfMoneyKey,
        title: 'Life of Your Money',
        description: 'This shows how long your money will last.',
        onStepEnter: () => _scrollTo(_lifeOfMoneyKey, 0.1),
      ),
      OnboardingStep(
        targetKey: _lifeOfMoneyKey,
        title: 'Dynamic Calculation',
        description: 'It’s based on your daily spending habits.',
      ),
      OnboardingStep(
        targetKey: _lifeOfMoneyKey,
        title: 'Real-time Updates',
        description: 'As your spending changes, this adjusts automatically.',
      ),
      OnboardingStep(
        targetKey: _planTabKey,
        title: 'Plan Tab',
        description: 'Tap here to manage your financial plans.',
        onStepEnter: () {
          setState(() {
            _selectedIndex = 3; // Plan Tab
          });
        },
      ),
      OnboardingStep(
        title: 'Financial Planning',
        description:
            'Plan your money with budgets, savings, and debt tracking.',
      ),
      OnboardingStep(
        targetKey: _planBudgetSectionKey,
        title: 'Monthly Budget',
        description: 'Set limits for your spending categories.',
        onStepEnter: () => _scrollTo(_planBudgetSectionKey, 0.1),
      ),
      OnboardingStep(
        targetKey: _planBudgetAddKey,
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
        targetKey: _planBudgetIndicatorKey,
        title: 'Track Your Limits',
        description:
            'When you add transactions, you\'ll see how much budget is left.',
        onStepEnter: () => _scrollTo(_planBudgetSectionKey, 0.2),
      ),
      OnboardingStep(
        targetKey: _planGoalSectionKey,
        title: 'Savings Goals',
        description: 'Save money for your future plans.',
        onStepEnter: () => _scrollTo(_planGoalSectionKey, 0.2),
      ),
      OnboardingStep(
        targetKey: _planGoalAddKey,
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
        targetKey: _planGoalFundKey,
        title: 'Add to Savings',
        description:
            'Add money to your goal — it will be deducted from your balance.',
        onStepEnter: () => _scrollTo(_planGoalFundKey, 0.4),
      ),
      OnboardingStep(
        targetKey: _planGoalWithdrawKey,
        title: 'Withdraw Target',
        description: 'Withdraw anytime — it will return to your balance.',
      ),
      OnboardingStep(
        targetKey: _planDebtSectionKey,
        title: 'Debts & Loans',
        description: 'Track money you gave or borrowed.',
        onStepEnter: () => _scrollTo(_planDebtSectionKey, 0.4),
      ),
      OnboardingStep(
        targetKey: _planDebtAddKey,
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
        description:
            'Giving money deducts from your wallet. Borrowing adds to your wallet.',
      ),
      OnboardingStep(
        title: 'Manage Your Finances',
        description: 'Now you can budget, save, and track debts بسهولة!',
        onStepEnter: () {
          setState(() {
            _showFakeDetailsModal = false;
            _activityTutorialTabIndex = 0;
          });
        },
      ),
    ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: _selectedIndex == 0
            ? _buildRootExpTitle(theme)
            : Text(_appBarTitle, style: theme.textTheme.titleLarge),
        automaticallyImplyLeading: false,
        actions: [_buildProfileMenu(context, theme)],
      ),
      body: OnboardingOverlay(
        visible: _showTutorial,
        steps: tutorialSteps,
        onFinish: _onTutorialFinish,
        child: Stack(
          children: [
            Column(
              children: [
                _buildUpdateBanner(theme),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      _refresh();
                      await Future.delayed(const Duration(milliseconds: 500));
                    },
                    child: pages[_selectedIndex],
                  ),
                ),
              ],
            ),

            if (_showFakeDetailsModal)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    height: 520,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: theme.scaffoldBackgroundColor,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(32),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Transaction Details',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  key: _fakeDetailsEditIconKey,
                                  icon: const Icon(Icons.edit_rounded),
                                  onPressed: () {},
                                ),
                                IconButton(
                                  key: _fakeDetailsDeleteIconKey,
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    color: Colors.red,
                                  ),
                                  onPressed: () {},
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 20,
                            horizontal: 20,
                          ),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(
                              color: theme.dividerColor,
                              width: 0.5,
                            ),
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.error.withValues(
                                    alpha: 0.1,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.south_west_rounded,
                                  color: theme.colorScheme.error,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '- ₱250.00',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  color: theme.colorScheme.error,
                                  letterSpacing: -1,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'EXPENSE',
                                style: TextStyle(
                                  letterSpacing: 2,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                  color: theme.textTheme.bodyMedium?.color
                                      ?.withValues(alpha: 0.4),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: theme.dividerColor.withValues(
                                  alpha: 0.05,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.category_rounded,
                                size: 20,
                                color: theme.primaryColor,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              'Category',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: theme.textTheme.bodyMedium?.color
                                    ?.withValues(alpha: 0.5),
                              ),
                            ),
                            const Spacer(),
                            const Text(
                              'Food',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: theme.dividerColor.withValues(
                                  alpha: 0.05,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.calendar_today_rounded,
                                size: 20,
                                color: theme.primaryColor,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              'Note',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: theme.textTheme.bodyMedium?.color
                                    ?.withValues(alpha: 0.5),
                              ),
                            ),
                            const Spacer(),
                            const Text(
                              'Grocery Run',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            if (_showFakeDeleteConfirm)
              Container(
                color: Colors.black.withValues(alpha: 0.5),
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: theme.scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Delete Transaction?',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'This action cannot be undone. Are you sure you want to remove this record?',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () {},
                              child: const Text('Cancel'),
                            ),
                            const SizedBox(width: 8),
                            TextButton(
                              key: _fakeDeleteConfirmKey,
                              onPressed: () {},
                              child: const Text(
                                'Delete',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: _selectedIndex == 4
          ? null
          : FloatingActionButton(
              key: _walletsFabKey,
              onPressed: () => _onFabPressed(context, accountKey),
              child: const Icon(Icons.add_rounded, size: 28),
            ),
      bottomNavigationBar: _buildBottomNavBar(theme),
    );
  }

  // ---------------------------------------------------------------------------
  // FAB
  // ---------------------------------------------------------------------------

  Future<void> _onFabPressed(BuildContext context, int? accountKey) async {
    if (accountKey == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No active account found.')));
      return;
    }

    final targetScreen = _selectedIndex == 2
        ? WalletFormScreen(accountKey: accountKey)
        : AddTransactionScreen(accountKey: accountKey);

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => targetScreen),
    );
    if (!mounted) return;
    if (result == true) _refresh();
  }

  // ---------------------------------------------------------------------------
  // Bottom navigation bar
  // ---------------------------------------------------------------------------

  Widget _buildBottomNavBar(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: theme.dividerColor, width: 0.5)),
      ),
      child: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.grid_view_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            key: _activityTabKey,
            icon: const Icon(Icons.receipt_long_rounded),
            label: 'Activity',
          ),
          NavigationDestination(
            key: _walletsTabKey,
            icon: const Icon(Icons.account_balance_wallet_rounded),
            label: 'Wallets',
          ),
          NavigationDestination(
            key: _planTabKey,
            icon: const Icon(Icons.track_changes_rounded),
            label: 'Plan',
          ),
          const NavigationDestination(
            icon: Icon(Icons.auto_awesome_rounded),
            label: 'Assistant',
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Profile popup menu
  // ---------------------------------------------------------------------------

  Widget _buildProfileMenu(BuildContext context, ThemeData theme) {
    final account = SessionService.activeAccount;
    return Container(
      margin: const EdgeInsets.only(right: 16),
      child: PopupMenuButton<String>(
        offset: const Offset(0, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: theme.dividerColor, width: 1.5),
          ),
          child: CircleAvatar(
            radius: 14,
            backgroundColor: theme.cardColor,
            child: Icon(
              Icons.person_outline,
              size: 20,
              color: theme.primaryColor,
            ),
          ),
        ),
        onSelected: (value) => _onMenuSelected(context, value),
        itemBuilder: (context) => [
          _buildPopupHeader(context, account?.name ?? 'User'),
          const PopupMenuDivider(),
          _buildPopupItem(Icons.account_circle_outlined, 'Account', 'account'),
          _buildPopupItem(Icons.palette_outlined, 'Theme Settings', 'theme'),
          _buildPopupItem(Icons.security_rounded, 'Security', 'security'),
          _buildPopupItem(Icons.info_outline_rounded, 'About', 'about'),
          const PopupMenuDivider(),
          _buildPopupItem(
            Icons.logout_rounded,
            'Logout',
            'logout',
            color: theme.colorScheme.error,
          ),
        ],
      ),
    );
  }

  void _onMenuSelected(BuildContext context, String value) async {
    final account = SessionService.activeAccount;
    switch (value) {
      case 'account':
        if (account != null) _showEditAccountDialog(context, account);
      case 'theme':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ThemePickerScreen()),
        );
      case 'security':
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SecuritySettingsScreen(),
          ),
        );
        if (result == true) _refresh();
      case 'about':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AboutScreen()),
        );
      case 'logout':
        _showLogoutDialog(context);
    }
  }

  void _showEditAccountDialog(BuildContext context, Account account) {
    final theme = Theme.of(context);
    final controller = TextEditingController(text: account.name);
    final editFormKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Edit Account Name'),
        content: Form(
          key: editFormKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            style: theme.textTheme.bodyLarge,
            decoration: InputDecoration(
              labelText: 'Account Name',
              hintText: 'e.g. My Savings',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) =>
                (value == null || value.trim().isEmpty) ? 'Enter a name' : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: theme.textTheme.bodyMedium?.color?.withValues(
                  alpha: 0.5,
                ),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {

              if (editFormKey.currentState!.validate()) {
                account.name = controller.text.trim();
                await DatabaseService.updateAccount(account);
                if (context.mounted) {
                  Navigator.pop(context);
                  _refresh();
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: theme.colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildPopupItem(
    IconData icon,
    String title,
    String value, {
    Color? color,
  }) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildPopupHeader(BuildContext context, String name) {
    final theme = Theme.of(context);
    return PopupMenuItem<String>(
      enabled: false,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.person_rounded,
              color: theme.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Account',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.textTheme.bodyMedium?.color?.withValues(
                      alpha: 0.5,
                    ),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Logout dialog
  // ---------------------------------------------------------------------------

  void _showLogoutDialog(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Exit Vault'),
        content: const Text(
          'Are you sure you want to log out of your session?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: theme.textTheme.bodyMedium?.color?.withValues(
                  alpha: 0.5,
                ),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => const AccountListScreen(),
                ),
                (route) => false,
              );
            },
            child: Text(
              'Logout',
              style: TextStyle(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Update Banner
  // ---------------------------------------------------------------------------

  Widget _buildUpdateBanner(ThemeData theme) {
    return ValueListenableBuilder<UpdateInfo?>(
      valueListenable: UpdateService.updateNotifier,
      builder: (context, info, _) {
        if (info == null) return const SizedBox.shrink();

        final backgroundColor = theme.colorScheme.primary;
        final foregroundColor = theme.colorScheme.onPrimary;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: backgroundColor,
            boxShadow: [
              BoxShadow(
                color: backgroundColor.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                Icons.system_update_rounded,
                color: foregroundColor,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Update Available (${info.latestVersion})',
                      style: TextStyle(
                        color: foregroundColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      info.releaseNotes,
                      style: TextStyle(
                        color: foregroundColor.withValues(alpha: 0.8),
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => UpdateService.launchDownload(),
                style: TextButton.styleFrom(
                  backgroundColor: foregroundColor.withValues(alpha: 0.15),
                  foregroundColor: foregroundColor,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'UPDATE',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  color: foregroundColor.withValues(alpha: 0.7),
                  size: 18,
                ),
                onPressed: () => UpdateService.updateNotifier.value = null,
              ),
            ],
          ),
        );
      },
    );
  }
}
