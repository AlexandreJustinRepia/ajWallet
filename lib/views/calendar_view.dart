import 'package:flutter/material.dart';
import '../services/session_service.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/database_service.dart';
import '../models/transaction_model.dart';
import '../widgets/transaction_card.dart';
import 'dashboard_helpers.dart';

class CalendarView extends StatefulWidget {
  final VoidCallback onRefresh;
  const CalendarView({super.key, required this.onRefresh});

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  TransactionType? _filter;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  @override
  Widget build(BuildContext context) {
    final account = SessionService.activeAccount;
    final transactions = account != null
        ? DatabaseService.getTransactions(account.key as int)
        : <Transaction>[];
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final filteredTransactions = transactions.where((tx) {
      final dateMatch = isSameDay(tx.date, _selectedDay ?? _focusedDay);
      final typeMatch = _filter == null || tx.type == _filter;
      return dateMatch && typeMatch;
    }).toList();

    final dayIncome = filteredTransactions
        .where((tx) => tx.type == TransactionType.income)
        .fold(0.0, (sum, tx) => sum + tx.amount);
    final dayExpense = filteredTransactions
        .where((tx) => tx.type == TransactionType.expense)
        .fold(0.0, (sum, tx) => sum + tx.amount);

    return Container(
      color: theme.scaffoldBackgroundColor,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildCalendarSliverAppBar(context, theme, isDark),
          _buildFilterRow(context),
          if (filteredTransactions.isNotEmpty)
            _buildDaySummary(context, theme, dayIncome, dayExpense),
          filteredTransactions.isEmpty
              ? _buildEmptySliver(theme)
              : _buildTransactionSliver(filteredTransactions),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  SliverAppBar _buildCalendarSliverAppBar(
    BuildContext context,
    ThemeData theme,
    bool isDark,
  ) {
    return SliverAppBar(
      expandedHeight: 460,
      floating: false,
      pinned: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Column(
          children: [
            const SizedBox(height: 60),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('MMMM yyyy').format(_focusedDay).toUpperCase(),
                    style: theme.textTheme.labelLarge?.copyWith(
                      letterSpacing: 2,
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                      color:
                          theme.textTheme.bodyMedium?.color?.withValues(alpha:0.4),
                    ),
                  ),
                  const Text(
                    'Financial Timeline',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: CalendarFormat.month,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              headerVisible: false,
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: TextStyle(
                  color:
                      theme.textTheme.bodyMedium?.color?.withValues(alpha:0.4),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                weekendStyle: TextStyle(
                  color:
                      theme.textTheme.bodyMedium?.color?.withValues(alpha:0.4),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: theme.primaryColor.withValues(alpha:0.1),
                  shape: BoxShape.circle,
                ),
                todayTextStyle: TextStyle(
                  color: theme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
                selectedDecoration: BoxDecoration(
                  color: isDark ? Colors.white : Colors.black,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (isDark ? Colors.white : Colors.black)
                          .withValues(alpha:0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                selectedTextStyle: TextStyle(
                  color: isDark ? Colors.black : Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                defaultTextStyle: const TextStyle(fontWeight: FontWeight.w500),
                weekendTextStyle:
                    const TextStyle(fontWeight: FontWeight.w500),
                outsideDaysVisible: false,
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildFilterRow(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            FilterTab(
              label: 'All',
              isSelected: _filter == null,
              onTap: () => setState(() => _filter = null),
            ),
            const SizedBox(width: 8),
            FilterTab(
              label: 'Income',
              isSelected: _filter == TransactionType.income,
              onTap: () => setState(() => _filter = TransactionType.income),
            ),
            const SizedBox(width: 8),
            FilterTab(
              label: 'Expense',
              isSelected: _filter == TransactionType.expense,
              onTap: () => setState(() => _filter = TransactionType.expense),
            ),
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildDaySummary(
    BuildContext context,
    ThemeData theme,
    double income,
    double expense,
  ) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: theme.dividerColor, width: 0.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              DaySummaryStat(
                label: 'Income',
                amount: income,
                color: theme.colorScheme.tertiary,
              ),
              Container(width: 1, height: 30, color: theme.dividerColor),
              DaySummaryStat(
                label: 'Expense',
                amount: expense,
                color: theme.colorScheme.error,
              ),
            ],
          ),
        ),
      ),
    );
  }

  SliverFillRemaining _buildEmptySliver(ThemeData theme) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy_rounded, size: 48, color: theme.dividerColor),
            const SizedBox(height: 16),
            Text(
              'No records for this day',
              style: TextStyle(color: theme.dividerColor),
            ),
          ],
        ),
      ),
    );
  }

  SliverPadding _buildTransactionSliver(
    List<Transaction> filteredTransactions,
  ) {
    return SliverPadding(
      padding: const EdgeInsets.all(24),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final tx = filteredTransactions[index];
            final theme = Theme.of(context);
            final isLast = index == filteredTransactions.length - 1;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        margin: const EdgeInsets.only(top: 20),
                        decoration: BoxDecoration(
                          color: tx.type == TransactionType.income
                              ? theme.colorScheme.tertiary
                              : theme.colorScheme.error,
                          shape: BoxShape.circle,
                        ),
                      ),
                      if (!isLast)
                        Container(
                          width: 2,
                          height: 60,
                          color: theme.dividerColor.withValues(alpha:0.5),
                        ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: TransactionCard(
                      tx: tx,
                      onRefresh: widget.onRefresh,
                    ),
                  ),
                ],
              ),
            );
          },
          childCount: filteredTransactions.length,
        ),
      ),
    );
  }
}
