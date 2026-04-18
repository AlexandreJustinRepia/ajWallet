import 'package:flutter/material.dart';
import '../../../screens/analytics_dashboard_screen.dart';
import '../../../services/financial_insights_service.dart';
import '../../insight_card.dart';

class HomeInsightsSection extends StatelessWidget {
  final List<Insight> insights;
  final DashboardAnalytics? analytics;

  const HomeInsightsSection({
    super.key,
    required this.insights,
    this.analytics,
  });

  @override
  Widget build(BuildContext context) {
    if (insights.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInsightsHeader(context),
        const SizedBox(height: 16),
        _buildInsightsList(context),
      ],
    );
  }

  Widget _buildInsightsHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'INTELLIGENT INSIGHTS',
          style: theme.textTheme.labelLarge?.copyWith(
            letterSpacing: 2,
            fontWeight: FontWeight.w900,
            fontSize: 10,
            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.4),
          ),
        ),
        GestureDetector(
          onTap: () {
            if (analytics != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AnalyticsDashboardScreen(analytics: analytics!),
                ),
              );
            }
          },
          child: Row(
            children: [
              Text(
                'SEE ALL',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 10,
                color: theme.colorScheme.primary,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInsightsList(BuildContext context) {
    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: insights.length > 3 ? 3 : insights.length, // Show top 3
        separatorBuilder: (_, _) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          return SizedBox(
            width: 280,
            child: InsightCard(insight: insights[index]),
          );
        },
      ),
    );
  }
}
