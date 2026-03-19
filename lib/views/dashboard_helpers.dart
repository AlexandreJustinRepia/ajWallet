import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

/// Builds a date section header for grouped transaction lists.
Widget buildDateHeader(BuildContext context, DateTime date) {
  final theme = Theme.of(context);
  final now = DateTime.now();
  final isToday = isSameDay(date, now);
  final isYesterday = isSameDay(date, now.subtract(const Duration(days: 1)));

  final String dateStr;
  if (isToday) {
    dateStr = 'Today';
  } else if (isYesterday) {
    dateStr = 'Yesterday';
  } else {
    dateStr = DateFormat('MMMM dd, yyyy').format(date);
  }

  return Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 12, left: 4),
    child: Text(
      dateStr.toUpperCase(),
      style: theme.textTheme.labelLarge?.copyWith(
        letterSpacing: 1.5,
        fontWeight: FontWeight.w900,
        fontSize: 11,
        color: theme.textTheme.bodyMedium?.color?.withOpacity(0.4),
      ),
    ),
  );
}

/// A pill-shaped filter tab used in the Calendar view.
class FilterTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const FilterTab({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? theme.primaryColor : theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? theme.primaryColor : theme.dividerColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? theme.scaffoldBackgroundColor
                : theme.textTheme.bodyMedium?.color,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// A compact income/expense summary stat shown in the Calendar view.
class DaySummaryStat extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;

  const DaySummaryStat({
    super.key,
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.4),
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '₱${amount.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
