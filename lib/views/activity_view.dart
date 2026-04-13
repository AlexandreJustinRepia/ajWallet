import 'package:flutter/material.dart';
import '../services/session_service.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/database_service.dart';
import '../models/transaction_model.dart';
import '../widgets/slide_in_list_item.dart';
import '../widgets/transaction_card.dart';
import 'dashboard_helpers.dart';

/// Merged Activity tab: toggles between a full transaction list and a calendar view.
class ActivityView extends StatefulWidget {
  final VoidCallback onRefresh;
  final bool isTutorialActive;
  final GlobalKey? listAreaKey;
  final GlobalKey? singleItemKey;
  final GlobalKey? dateHeaderKey;
  final GlobalKey? colorIndicatorKey;
  final GlobalKey? filterChipsKey;
  final GlobalKey? searchBarKey;
  final GlobalKey? calendarTabKey;
  final GlobalKey? calendarAreaKey;
  final int? overrideTabIndex;

  const ActivityView({
    super.key, 
    required this.onRefresh,
    this.isTutorialActive = false,
    this.listAreaKey,
    this.singleItemKey,
    this.dateHeaderKey,
    this.colorIndicatorKey,
    this.filterChipsKey,
    this.searchBarKey,
    this.calendarTabKey,
    this.calendarAreaKey,
    this.overrideTabIndex,
  });

  @override
  State<ActivityView> createState() => _ActivityViewState();
}

class _ActivityViewState extends State<ActivityView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.overrideTabIndex ?? 0);
  }

  @override
  void didUpdateWidget(ActivityView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.overrideTabIndex != null && widget.overrideTabIndex != oldWidget.overrideTabIndex) {
      _tabController.animateTo(widget.overrideTabIndex!);
    }
  }

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  TransactionType? _filter;

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
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
                  theme.textTheme.bodyMedium?.color?.withValues(alpha:0.5),
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
              dividerColor: Colors.transparent,
              tabs: [
                const Tab(text: 'List'),
                Tab(key: widget.calendarTabKey, text: 'Calendar'),
              ],
            ),
          ),
        ),

        // ── Search Bar ─────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Container(
            key: widget.searchBarKey,
            height: 44,
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: theme.dividerColor, width: 0.5),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search transactions...',
                hintStyle: TextStyle(color: theme.textTheme.bodyMedium?.color?.withValues(alpha:0.4), fontSize: 13),
                prefixIcon: Icon(Icons.search, size: 20, color: theme.dividerColor),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ),

        // ── Filter Chips (Shared) ──────────────────────────────────────────
        Padding(
          key: widget.filterChipsKey,
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
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
                const SizedBox(width: 8),
                FilterTab(
                  label: 'Transfer',
                  isSelected: _filter == TransactionType.transfer,
                  onTap: () => setState(() => _filter = TransactionType.transfer),
                ),
              ],
            ),
          ),
        ),

        // ── Content ────────────────────────────────────────────────────────
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _ListViewTab(
                onRefresh: widget.onRefresh,
                isTutorialActive: widget.isTutorialActive,
                searchQuery: _searchQuery,
                filter: _filter,
                listAreaKey: widget.listAreaKey,
                singleItemKey: widget.singleItemKey,
                dateHeaderKey: widget.dateHeaderKey,
                colorIndicatorKey: widget.colorIndicatorKey,
              ),
              _CalendarViewTab(
                onRefresh: widget.onRefresh,
                isTutorialActive: widget.isTutorialActive,
                searchQuery: _searchQuery,
                filter: _filter,
                calendarAreaKey: widget.calendarAreaKey,
              ),
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
  final bool isTutorialActive;
  final String searchQuery;
  final TransactionType? filter;
  
  final GlobalKey? listAreaKey;
  final GlobalKey? singleItemKey;
  final GlobalKey? dateHeaderKey;
  final GlobalKey? colorIndicatorKey;

  const _ListViewTab({
    required this.onRefresh,
    required this.isTutorialActive,
    required this.searchQuery,
    required this.filter,
    this.listAreaKey,
    this.singleItemKey,
    this.dateHeaderKey,
    this.colorIndicatorKey,
  });

  @override
  Widget build(BuildContext context) {
    final account = SessionService.activeAccount;
    final theme = Theme.of(context);
    List<Transaction> baseTransactions = [];

    if (isTutorialActive) {
      final now = DateTime.now();
      baseTransactions = [
        Transaction(accountKey: 0, title: 'Grocery Run', amount: 250.00, type: TransactionType.expense, date: now, category: 'Food', description: 'Bought some food at the store'),
        Transaction(accountKey: 0, title: 'Salary', amount: 5000.00, type: TransactionType.income, date: now.subtract(const Duration(days: 1)), category: 'Salary', description: 'Monthly salary from work'),
        Transaction(accountKey: 0, title: 'Transfer to Savings', amount: 500.00, type: TransactionType.transfer, date: now.subtract(const Duration(days: 2)), category: 'Transfer', description: 'Moving cash to savings'),
      ];
    } else if (account != null) {
      baseTransactions = DatabaseService.getTransactions(account.key as int);
    }

    final transactions = baseTransactions.where((tx) {
      if (filter != null && tx.type != filter) return false;
      if (searchQuery.isNotEmpty) {
        final q = searchQuery;
        if (!tx.title.toLowerCase().contains(q) && !tx.category.toLowerCase().contains(q)) return false;
      }
      return true;
    }).toList();

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
                color: theme.textTheme.bodyMedium?.color?.withValues(alpha:0.4),
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

    return Container(
      key: listAreaKey,
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        if (item is DateTime) {
          return SizedBox(
            key: index == 0 ? dateHeaderKey : null,
            child: buildDateHeader(context, item),
          );
        }
        final tx = item as Transaction;
        
        // Target the first transaction card for the tutorial
        final isFirstTx = index == (items.first is DateTime ? 1 : 0);

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SlideInListItem(
            index: index,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  key: isFirstTx ? colorIndicatorKey : null,
                  width: 14,
                  height: 14,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: tx.type == TransactionType.income ? theme.colorScheme.tertiary : (tx.type == TransactionType.expense ? theme.colorScheme.error : const Color(0xFF00796B)),
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  key: isFirstTx ? singleItemKey : null,
                  child: TransactionCard(tx: tx, onRefresh: onRefresh),
                ),
              ],
            ),
          ),
        );
      },
    ));
  }
}

// ============================================================================
// CALENDAR VIEW TAB
// ============================================================================

class _CalendarViewTab extends StatefulWidget {
  final VoidCallback onRefresh;
  final bool isTutorialActive;
  final String searchQuery;
  final TransactionType? filter;
  final GlobalKey? calendarAreaKey;

  const _CalendarViewTab({
    required this.onRefresh,
    required this.isTutorialActive,
    required this.searchQuery,
    required this.filter,
    this.calendarAreaKey,
  });

  @override
  State<_CalendarViewTab> createState() => _CalendarViewTabState();
}

class _CalendarViewTabState extends State<_CalendarViewTab> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  @override
  Widget build(BuildContext context) {
    final account = SessionService.activeAccount;
    final theme = Theme.of(context);
    List<Transaction> transactions = [];

    if (widget.isTutorialActive) {
      final now = DateTime.now();
      transactions = [
        Transaction(accountKey: 0, title: 'Grocery Run', amount: 250.00, type: TransactionType.expense, date: now, category: 'Food', description: 'Bought some food at the store'),
        Transaction(accountKey: 0, title: 'Salary', amount: 5000.00, type: TransactionType.income, date: now.subtract(const Duration(days: 1)), category: 'Salary', description: 'Monthly salary from work'),
        Transaction(accountKey: 0, title: 'Transfer to Savings', amount: 500.00, type: TransactionType.transfer, date: now.subtract(const Duration(days: 2)), category: 'Transfer', description: 'Moving cash to savings'),
      ];
    } else if (account != null) {
      transactions = DatabaseService.getTransactions(account.key as int);
    }

    final globalFiltered = transactions.where((tx) {
      final typeMatch = widget.filter == null || tx.type == widget.filter;
      final searchMatch = widget.searchQuery.isEmpty || 
        tx.title.toLowerCase().contains(widget.searchQuery) || 
        tx.category.toLowerCase().contains(widget.searchQuery);
      return typeMatch && searchMatch;
    }).toList();

    final filtered = globalFiltered.where((tx) {
      return isSameDay(tx.date, _selectedDay ?? _focusedDay);
    }).toList();

    final dayIncome = filtered
        .where((tx) => tx.type == TransactionType.income)
        .fold(0.0, (s, tx) => s + tx.amount);
    final dayExpense = filtered
        .where((tx) => tx.type == TransactionType.expense)
        .fold(0.0, (s, tx) => s + tx.amount);

    final categoryData = <String, double>{};
    for (final tx in filtered) {
      if (widget.filter == null && tx.type != TransactionType.expense) continue;
      if (tx.type == TransactionType.transfer) continue;
      categoryData[tx.category] = (categoryData[tx.category] ?? 0) + tx.amount;
    }

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
                color: theme.textTheme.bodyMedium?.color?.withValues(alpha:0.4),
              ),
            ),
          ),
        ),

        // Calendar
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Container(
              key: widget.calendarAreaKey,
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
              eventLoader: (day) {
                return globalFiltered.where((tx) => isSameDay(tx.date, day)).toList();
              },
              headerVisible: false,
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: TextStyle(
                  color: theme.textTheme.bodyMedium?.color?.withValues(alpha:0.4),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                weekendStyle: TextStyle(
                  color: theme.textTheme.bodyMedium?.color?.withValues(alpha:0.4),
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
                  color: theme.colorScheme.onSurface,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.onSurface.withValues(alpha:0.2),
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
                markerDecoration: BoxDecoration(
                  color: theme.primaryColor,
                  shape: BoxShape.circle,
                ),
                markersMaxCount: 1,
                markerMargin: const EdgeInsets.only(top: 6),
              ),
            ),
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

        // Chart sliver
        if (categoryData.isNotEmpty)
          _buildChartSliver(theme, categoryData),

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
                                        theme.dividerColor.withValues(alpha:0.5),
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

  Widget _buildChartSliver(ThemeData theme, Map<String, double> categoryData) {
    if (categoryData.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

    final colors = [
      theme.primaryColor,
      theme.dividerColor,
      theme.textTheme.bodyMedium?.color?.withValues(alpha:0.5) ?? Colors.grey,
      theme.primaryColor.withValues(alpha:0.3),
      theme.primaryColor.withValues(alpha:0.6),
    ];

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.dividerColor, width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.filter == TransactionType.income ? 'INCOME BREAKDOWN' : 'SPENDING BREAKDOWN',
                style: theme.textTheme.labelLarge?.copyWith(
                  letterSpacing: 2,
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                  color: theme.textTheme.bodyMedium?.color?.withValues(alpha:0.4),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 30,
                        sections: categoryData.entries
                            .toList()
                            .asMap()
                            .entries
                            .map((e) => PieChartSectionData(
                                  value: e.value.value,
                                  color: colors[e.key % colors.length],
                                  radius: 12,
                                  title: '',
                                ))
                            .toList(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: categoryData.entries
                          .toList()
                          .asMap()
                          .entries
                          .map((e) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: colors[e.key % colors.length],
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        e.value.key,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      '₱${e.value.value.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
