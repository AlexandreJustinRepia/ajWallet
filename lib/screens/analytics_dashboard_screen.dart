import 'package:flutter/material.dart';
import '../services/financial_insights_service.dart';
import '../widgets/analytics/category_pie_chart.dart';
import '../widgets/analytics/trend_comparison_bar.dart';
import '../widgets/card_decorator.dart';
import '../views/insight_card.dart';

import '../views/dashboard/dashboard_keys.dart';
import '../widgets/onboarding_overlay.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  final DashboardAnalytics analytics;

  const AnalyticsDashboardScreen({
    super.key,
    required this.analytics,
  });

  @override
  State<AnalyticsDashboardScreen> createState() => _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  final DashboardKeys _keys = DashboardKeys();
  bool _showTutorial = false;

  void _startTutorial() {
    setState(() => _showTutorial = true);
  }

  List<OnboardingStep> _getOnboardingSteps(BuildContext context) {
    return [
      OnboardingStep(
        targetKey: _keys.analyticsBurnRateKey,
        title: 'Daily Burn Rate',
        description: 'This shows your average daily spending based on your recent activity.',
      ),
      OnboardingStep(
        targetKey: _keys.analyticsSavingsRateKey,
        title: 'Savings Rate',
        description: 'The percentage of your income you managed to keep in the last 30 days.',
      ),
      OnboardingStep(
        targetKey: _keys.analyticsPieChartKey,
        title: 'Categorical Breakdown',
        description: 'A visual map of where your money goes. Tap the legend to see specific amounts.',
      ),
      OnboardingStep(
        targetKey: _keys.analyticsTrendBarKey,
        title: 'Monthly Pacing',
        description: 'Compare your current month-to-date spending with the same period last month.',
      ),
      if (widget.analytics.extremeTrends.isNotEmpty)
        OnboardingStep(
          targetKey: _keys.analyticsNotableHabitsKey,
          title: 'Notable Habits',
          description: 'We call out categories where your spending has significantly increased or decreased.',
        ),
      OnboardingStep(
        targetKey: _keys.analyticsStrategicInsightsKey,
        title: 'Strategic Insights',
        description: 'Personalized advice and observations about your overall financial health.',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: OnboardingOverlay(
        visible: _showTutorial,
        steps: _getOnboardingSteps(context),
        onFinish: () => setState(() => _showTutorial = false),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildSliverAppBar(context, theme),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeroMetrics(context, theme),
                    const SizedBox(height: 32),
                    
                    _buildSectionTitle(theme, 'WHERE YOUR MONEY GOES', Icons.pie_chart_rounded),
                    const SizedBox(height: 16),
                    CardDecorator(
                      key: _keys.analyticsPieChartKey,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: CategoryPieChart(categoryPercentages: widget.analytics.categoryPercentages),
                      ),
                    ),
                    const SizedBox(height: 32),

                    _buildSectionTitle(theme, 'PACING & TRENDS', Icons.analytics_rounded),
                    const SizedBox(height: 16),
                    TrendComparisonBar(
                      key: _keys.analyticsTrendBarKey,
                      percent: widget.analytics.monthlyComparisonPercent,
                      label: 'MONTH-TO-DATE SPENDING',
                    ),
                    const SizedBox(height: 24),

                    if (widget.analytics.extremeTrends.isNotEmpty) ...[
                      _buildSectionTitle(theme, 'NOTABLE HABITS', Icons.auto_awesome_rounded),
                      const SizedBox(height: 12),
                      Column(
                        key: _keys.analyticsNotableHabitsKey,
                        children: widget.analytics.extremeTrends.map((trend) => _buildTrendChangeItem(context, theme, trend)).toList(),
                      ),
                      const SizedBox(height: 32),
                    ],

                    _buildSectionTitle(theme, 'STRATEGIC INSIGHTS', Icons.lightbulb_outline_rounded),
                    const SizedBox(height: 16),
                    Column(
                      key: _keys.analyticsStrategicInsightsKey,
                      children: widget.analytics.smartInsights.map((insight) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InsightCard(insight: insight),
                      )).toList(),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, ThemeData theme) {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          onPressed: _startTutorial,
          icon: Icon(
            Icons.help_outline_rounded,
            size: 20,
            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
        centerTitle: false,
        title: Text(
          'Advanced Insights',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.primary.withValues(alpha: 0.6)),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.labelLarge?.copyWith(
            letterSpacing: 1.5,
            fontWeight: FontWeight.w900,
            fontSize: 11,
            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.45),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroMetrics(BuildContext context, ThemeData theme) {
    return Row(
      children: [
        Expanded(
          key: _keys.analyticsBurnRateKey,
          child: _heroMetricCard(
            theme,
            'DAILY BURN',
            '₱${widget.analytics.dailyBurn.toStringAsFixed(0)}',
            Icons.local_fire_department_rounded,
            const Color(0xFFC62828),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          key: _keys.analyticsSavingsRateKey,
          child: _heroMetricCard(
            theme,
            'SAVINGS RATE',
            '${(widget.analytics.savingsRate * 100).toStringAsFixed(1)}%',
            Icons.savings_rounded,
            const Color(0xFF2E7D32),
          ),
        ),
      ],
    );
  }

  Widget _heroMetricCard(ThemeData theme, String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 16),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              color: color.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendChangeItem(BuildContext context, ThemeData theme, CategoryTrend trend) {
    final color = trend.isIncrease ? const Color(0xFFC62828) : const Color(0xFF2E7D32);
    
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: CardDecorator(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  trend.isIncrease ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                  color: color,
                  size: 18,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trend.category,
                      style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      trend.isIncrease 
                        ? 'Increased by ${trend.changePercent.toStringAsFixed(1)}% MoM'
                        : 'Decreased by ${trend.changePercent.toStringAsFixed(1)}% MoM',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
