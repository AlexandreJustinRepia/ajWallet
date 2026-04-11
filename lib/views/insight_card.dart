import 'package:flutter/material.dart';
import '../services/financial_insights_service.dart';

/// A fade-in card displaying a single financial insight.
class InsightCard extends StatefulWidget {
  final Insight insight;
  const InsightCard({super.key, required this.insight});

  @override
  State<InsightCard> createState() => _InsightCardState();
}

class _InsightCardState extends State<InsightCard> {
  double _opacity = 0;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _opacity = 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 1000),
      opacity: _opacity,
      curve: Curves.easeOut,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.dividerColor, width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: widget.insight.color.withValues(alpha:0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                widget.insight.icon,
                size: 18,
                color: widget.insight.color,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                widget.insight.message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                  color: theme.textTheme.bodyMedium?.color?.withValues(alpha:0.8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
