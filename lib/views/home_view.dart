import 'package:flutter/material.dart';
import '../widgets/quick_add_input.dart';
import '../widgets/animated_tree.dart';
import '../services/session_service.dart';
import 'home/home_view_model.dart';
import 'home/widgets/home_header.dart';
import 'home/widgets/home_balance_card.dart';
import 'home/widgets/home_insights_section.dart';
import 'home/widgets/recent_activity_section.dart';

class HomeView extends StatefulWidget {
  final VoidCallback onRefresh;
  final GlobalKey? balanceKey;
  final GlobalKey? quickAddKey;
  final GlobalKey? treeKey;
  final GlobalKey? activityHeaderKey;
  final GlobalKey? sampleTransactionKey;
  final bool isTutorialActive;

  const HomeView({
    super.key,
    required this.onRefresh,
    this.balanceKey,
    this.quickAddKey,
    this.treeKey,
    this.activityHeaderKey,
    this.sampleTransactionKey,
    this.isTutorialActive = false,
  });

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  late HomeViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = HomeViewModel(isTutorialActive: widget.isTutorialActive);
  }

  @override
  void didUpdateWidget(HomeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isTutorialActive != widget.isTutorialActive) {
      _viewModel = HomeViewModel(isTutorialActive: widget.isTutorialActive);
    }
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final account = SessionService.activeAccount;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header & Gamification
              HomeHeader(
                name: account?.name ?? 'User',
                profile: _viewModel.gamificationProfile,
              ),
              const SizedBox(height: 24),

              // Balance Card (Isolated Rebuilds)
              RepaintBoundary(
                child: HomeBalanceCard(
                  key: widget.balanceKey,
                  totalBalance: _viewModel.totalBalance,
                  isNetWorth: _viewModel.isNetWorthMode,
                  showGlow: _viewModel.showGlow,
                  onToggle: (_) => _viewModel.toggleNetWorth(),
                ),
              ),
              const SizedBox(height: 32),

              // Animated Tree (Isolated Drawing)
              RepaintBoundary(
                child: AnimatedTree(
                  key: widget.treeKey,
                  balance: _viewModel.totalBalance,
                ),
              ),

              if (account != null || widget.isTutorialActive) ...[
                const SizedBox(height: 16),
                QuickAddInput(
                  key: widget.quickAddKey,
                  accountKey: account?.key as int? ?? 999,
                  onSaved: () {
                    _viewModel.refresh();
                    widget.onRefresh();
                  },
                  onTutorialSubmit: widget.isTutorialActive
                      ? (t) async {
                          _viewModel.handleTutorialSubmit(t);
                          widget.onRefresh();
                        }
                      : null,
                ),
              ],
              const SizedBox(height: 32),

              // Insights
              HomeInsightsSection(insights: _viewModel.insights),
              const SizedBox(height: 32),

              // Recent Activity
              RecentActivitySection(
                headerKey: widget.activityHeaderKey,
                sampleTransactionKey: widget.sampleTransactionKey,
                transactions: _viewModel.transactions,
                onRefresh: () {
                  _viewModel.refresh();
                  widget.onRefresh();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
