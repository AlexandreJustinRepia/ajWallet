import 'package:flutter/material.dart';

class FinancialHealthStrip extends StatefulWidget {
  final double budgetUsedPct;
  final double savingsPct;
  final double activeDebtAmount;

  const FinancialHealthStrip({
    super.key,
    required this.budgetUsedPct,
    required this.savingsPct,
    required this.activeDebtAmount,
  });

  @override
  State<FinancialHealthStrip> createState() => _FinancialHealthStripState();
}

class _FinancialHealthStripState extends State<FinancialHealthStrip> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final items = [
      _HealthCard(
        label: 'MONTHLY BUDGET',
        value: '${widget.budgetUsedPct.toStringAsFixed(0)}%',
        subtext: widget.budgetUsedPct > 100 ? 'Overspent' : 'Budget Used',
        icon: Icons.pie_chart_rounded,
        color: widget.budgetUsedPct > 100 ? theme.colorScheme.error : theme.colorScheme.secondary,
        progress: (widget.budgetUsedPct / 100).clamp(0.0, 1.0),
      ),
      _HealthCard(
        label: 'SAVINGS GOALS',
        value: '${widget.savingsPct.toStringAsFixed(0)}%',
        subtext: 'Overall Progress',
        icon: Icons.savings_rounded,
        color: theme.primaryColor,
        progress: (widget.savingsPct / 100).clamp(0.0, 1.0),
      ),
      _HealthCard(
        label: 'TOTAL DEBT',
        value: '₱${widget.activeDebtAmount.toStringAsFixed(0)}',
        subtext: 'Money You Owe',
        icon: Icons.warning_rounded,
        color: widget.activeDebtAmount > 0 ? (isDark ? Colors.amber[300]! : Colors.amber[700]!) : Colors.grey,
        progress: widget.activeDebtAmount > 0 ? 0.0 : 1.0, 
      ),
    ];

    return Column(
      children: [
        SizedBox(
          height: 100,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemCount: items.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
               return Padding(
                 padding: const EdgeInsets.symmetric(horizontal: 24.0),
                 child: items[index],
               );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(items.length, (index) {
             return AnimatedContainer(
               duration: const Duration(milliseconds: 300),
               margin: const EdgeInsets.symmetric(horizontal: 4),
               width: _currentPage == index ? 20 : 6,
               height: 6,
               decoration: BoxDecoration(
                 color: _currentPage == index ? theme.primaryColor : theme.dividerColor,
                 borderRadius: BorderRadius.circular(3),
               ),
             );
          }),
        ),
      ],
    );
  }
}

class _HealthCard extends StatelessWidget {
  final String label;
  final String value;
  final String subtext;
  final IconData icon;
  final Color color;
  final double progress;

  const _HealthCard({
    required this.label,
    required this.value,
    required this.subtext,
    required this.icon,
    required this.color,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
               SizedBox(
                 width: 50,
                 height: 50,
                 child: CircularProgressIndicator(
                   value: progress,
                   backgroundColor: color.withValues(alpha:0.1),
                   valueColor: AlwaysStoppedAnimation<Color>(color),
                   strokeWidth: 4,
                 ),
               ),
               Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w900,
                    color: theme.textTheme.bodyMedium?.color?.withValues(alpha:0.4),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      value,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      subtext,
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.textTheme.bodyMedium?.color?.withValues(alpha:0.5),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: theme.dividerColor),
        ],
      ),
    );
  }
}
