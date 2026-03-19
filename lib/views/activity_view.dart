import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../models/transaction_model.dart';
import '../widgets/slide_in_list_item.dart';
import '../widgets/transaction_card.dart';
import 'dashboard_helpers.dart';

/// Merged Activity tab: toggles between a full transaction list and a calendar view.
class ActivityView extends StatefulWidget {
  final VoidCallback onRefresh;
  const ActivityView({super.key, required this.onRefresh});

  @override
  State<ActivityView> createState() => _ActivityViewState();
}

class _ActivityViewState extends State<ActivityView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // ── Toggle Header ──────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: theme.dividerColor, width: 0.5),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: theme.primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: theme.scaffoldBackgroundColor,
              unselectedLabelColor:
                  theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'List'),
                Tab(text: 'Calendar'),
              ],
            ),
          ),
        ),

        // ── Content ────────────────────────────────────────────────────────
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _ListViewTab(onRefresh: widget.onRefresh),
              _CalendarViewTab(onRefresh: widget.onRefresh),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// LIST VIEW TAB
// ============================================================================

class _ListViewTab extends StatelessWidget {
  final VoidCallback onRefresh;
  const _ListViewTab({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final account = DatabaseService.getLatestAccount();
    final theme = Theme.of(context);
    final transactions = account != null
        ? DatabaseService.getTransactions(account.key as int)
        : <Transaction>[];

    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_rounded,
                size: 48, color: theme.dividerColor),
            const SizedBox(height: 16),
            Text(
              'No transactions yet',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.4),
              ),
            ),
          ],
        ),
      );
    }

    final sortedTx = List<Transaction>.from(transactions)
      ..sort((a, b) => b.date.compareTo(a.date));

    final List<dynamic> items = [];
    DateTime? lastDate;
    for (final tx in sortedTx) {
      if (lastDate == null || !isSameDay(lastDate, tx.date)) {
        items.add(tx.date);
        lastDate = tx.date;
      }
      items.add(tx);
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        if (item is DateTime) return buildDateHeader(context, item);
        final tx = item as Transaction;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SlideInListItem(
            index: index,
            child: TransactionCard(tx: tx, onRefresh: onRefresh),
          ),
        );
      },
    );
  }
}

// ============================================================================
// CALENDAR VIEW TAB
// ============================================================================

class _CalendarViewTab extends StatefulWidget {
  final VoidCallback onRefresh;
  const _CalendarViewTab({required this.onRefresh});

  @override
  State<_CalendarViewTab> createState() => _CalendarViewTabState();
}

class _CalendarViewTabState extends State<_CalendarViewTab> {
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
    final account = DatabaseService.getLatestAccount();
    final theme = Theme.of(context);
    final transactions = account != null
        ? DatabaseService.getTransactions(account.key as int)
        : <Transaction>[];

    final filtered = transactions.where((tx) {
      final dateMatch = isSameDay(tx.date, _selectedDay ?? _focusedDay);
      final typeMatch = _filter == null || tx.type == _filter;
      return dateMatch && typeMatch;
    }).toList();

    final dayIncome = filtered
        .where((tx) => tx.type == TransactionType.income)
        .fold(0.0, (s, tx) => s + tx.amount);
    final dayExpense = filtered
        .where((tx) => tx.type == TransactionType.expense)
        .fold(0.0, (s, tx) => s + tx.amount);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Month label
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Text(
              DateFormat('MMMM yyyy').format(_focusedDay).toUpperCase(),
              style: theme.textTheme.labelLarge?.copyWith(
                letterSpacing: 2,
                fontWeight: FontWeight.w900,
                fontSize: 10,
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.4),
              ),
            ),
          ),
        ),

        // Calendar
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: CalendarFormat.month,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) => setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              }),
              onPageChanged: (focusedDay) =>
                  setState(() => _focusedDay = focusedDay),
              headerVisible: false,
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: TextStyle(
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.4),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                weekendStyle: TextStyle(
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.4),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                todayTextStyle: TextStyle(
                  color: theme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
                selectedDecoration: BoxDecoration(
                  color: theme.colorScheme.onBackground,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.onBackground.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                selectedTextStyle: TextStyle(
                  color: theme.scaffoldBackgroundColor,
                  fontWeight: FontWeight.bold,
                ),
                defaultTextStyle: const TextStyle(fontWeight: FontWeight.w500),
                weekendTextStyle: const TextStyle(fontWeight: FontWeight.w500),
                outsideDaysVisible: false,
              ),
            ),
          ),
        ),

        // Filter chips
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
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
                  onTap: () =>
                      setState(() => _filter = TransactionType.income),
                ),
                const SizedBox(width: 8),
                FilterTab(
                  label: 'Expense',
                  isSelected: _filter == TransactionType.expense,
                  onTap: () =>
                      setState(() => _filter = TransactionType.expense),
                ),
              ],
            ),
          ),
        ),

        // Day summary
        if (filtered.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: theme.dividerColor, width: 0.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    DaySummaryStat(
                      label: 'Income',
                      amount: dayIncome,
                      color: theme.colorScheme.tertiary,
                    ),
                    Container(
                        width: 1, height: 30, color: theme.dividerColor),
                    DaySummaryStat(
                      label: 'Expense',
                      amount: dayExpense,
                      color: theme.colorScheme.error,
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Transaction list or empty
        filtered.isEmpty
            ? SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_busy_rounded,
                          size: 40, color: theme.dividerColor),
                      const SizedBox(height: 12),
                      Text(
                        'No records for this day',
                        style: TextStyle(
                            color: theme.dividerColor, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              )
            : SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 80),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final tx = filtered[index];
                      final isLast = index == filtered.length - 1;
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
                                    color:
                                        tx.type == TransactionType.income
                                            ? theme.colorScheme.tertiary
                                            : theme.colorScheme.error,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                if (!isLast)
                                  Container(
                                    width: 2,
                                    height: 60,
                                    color:
                                        theme.dividerColor.withOpacity(0.5),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 16),
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
                    childCount: filtered.length,
                  ),
                ),
              ),
      ],
    );
  }
}
