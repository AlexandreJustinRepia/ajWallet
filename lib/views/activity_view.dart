import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/transaction_model.dart';
import '../widgets/slide_in_list_item.dart';
import '../widgets/transaction_card.dart';
import 'dashboard_helpers.dart';
import 'activity/activity_view_model.dart';
import '../screens/export_screen.dart';
import 'activity/squads_tab_view.dart';

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
  final GlobalKey? squadsTabKey;
  final GlobalKey? squadsListKey;
  final GlobalKey? squadsCreateBtnKey;
  final ValueChanged<int>? onTabChanged;
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
    this.squadsTabKey,
    this.squadsListKey,
    this.squadsCreateBtnKey,
    this.onTabChanged,
    this.overrideTabIndex,
  });

  @override
  State<ActivityView> createState() => _ActivityViewState();
}

class _ActivityViewState extends State<ActivityView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late ActivityViewModel _viewModel;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: widget.overrideTabIndex ?? 0);
    _tabController.addListener(() {
      if (!mounted) return;
      if (!_tabController.indexIsChanging) {
        // Report tab completion (e.g., after swipe) or tap
        widget.onTabChanged?.call(_tabController.index);
      }
      setState(() {}); // Rebuild to hide/show search & filters based on index
    });
    _viewModel = ActivityViewModel(isTutorialActive: widget.isTutorialActive);
  }

  @override
  void didUpdateWidget(ActivityView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.overrideTabIndex != null && widget.overrideTabIndex != oldWidget.overrideTabIndex) {
      _tabController.animateTo(widget.overrideTabIndex!);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        return Column(
          children: [
            // ── Toggle Header ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: Row(
                children: [
                  Expanded(
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
                            theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
                        labelStyle: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                        dividerColor: Colors.transparent,
                        tabs: [
                          const Tab(text: 'List'),
                          Tab(key: widget.calendarTabKey, text: 'Calendar'),
                          Tab(key: widget.squadsTabKey, text: 'Squads'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // ── Export button ──────────────────────────────────────────
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ExportScreen(),
                      ),
                    ),
                    child: Container(
                      height: 44,
                      width: 44,
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: theme.dividerColor, width: 0.5),
                      ),
                      child: Icon(
                        Icons.file_download_outlined,
                        size: 20,
                        color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Search Bar & Filter Chips (Hidden on Squads Tab) ────────────────────────
            if (_tabController.index != 2) ...[
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
                    onChanged: (val) => _viewModel.searchQuery = val,
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

              Padding(
                key: widget.filterChipsKey,
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterTab(
                        label: 'All',
                        isSelected: _viewModel.filter == null,
                        onTap: () => _viewModel.filter = null,
                      ),
                      const SizedBox(width: 8),
                      FilterTab(
                        label: 'Income',
                        isSelected: _viewModel.filter == TransactionType.income,
                        onTap: () => _viewModel.filter = TransactionType.income,
                      ),
                      const SizedBox(width: 8),
                      FilterTab(
                        label: 'Expense',
                        isSelected: _viewModel.filter == TransactionType.expense,
                        onTap: () => _viewModel.filter = TransactionType.expense,
                      ),
                      const SizedBox(width: 8),
                      FilterTab(
                        label: 'Transfer',
                        isSelected: _viewModel.filter == TransactionType.transfer,
                        onTap: () => _viewModel.filter = TransactionType.transfer,
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // ── Content ────────────────────────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _ListViewTab(
                    viewModel: _viewModel,
                    onRefresh: widget.onRefresh,
                    listAreaKey: widget.listAreaKey,
                    singleItemKey: widget.singleItemKey,
                    dateHeaderKey: widget.dateHeaderKey,
                    colorIndicatorKey: widget.colorIndicatorKey,
                  ),
                  _CalendarViewTab(
                    viewModel: _viewModel,
                    onRefresh: widget.onRefresh,
                    calendarAreaKey: widget.calendarAreaKey,
                  ),
                  SquadsTabView(
                    onRefresh: widget.onRefresh,
                    squadsListKey: widget.squadsListKey,
                    squadsCreateBtnKey: widget.squadsCreateBtnKey,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ListViewTab extends StatelessWidget {
  final ActivityViewModel viewModel;
  final VoidCallback onRefresh;
  
  final GlobalKey? listAreaKey;
  final GlobalKey? singleItemKey;
  final GlobalKey? dateHeaderKey;
  final GlobalKey? colorIndicatorKey;

  const _ListViewTab({
    required this.viewModel,
    required this.onRefresh,
    this.listAreaKey,
    this.singleItemKey,
    this.dateHeaderKey,
    this.colorIndicatorKey,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = viewModel.getGroupedItems();

    if (items.isEmpty) {
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
      ),
    );
  }
}

class _CalendarViewTab extends StatelessWidget {
  final ActivityViewModel viewModel;
  final VoidCallback onRefresh;
  final GlobalKey? calendarAreaKey;

  const _CalendarViewTab({
    required this.viewModel,
    required this.onRefresh,
    this.calendarAreaKey,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = viewModel.getTransactionsForSelectedDay();

    final dayIncome = filtered
        .where((tx) => tx.type == TransactionType.income)
        .fold(0.0, (s, tx) => s + tx.amount);
    final dayExpense = filtered
        .where((tx) => tx.type == TransactionType.expense)
        .fold(0.0, (s, tx) => s + tx.amount);

    final categoryData = <String, double>{};
    for (final tx in filtered) {
      if (viewModel.filter == null && tx.type != TransactionType.expense) continue;
      if (tx.type == TransactionType.transfer) continue;
      categoryData[tx.category] = (categoryData[tx.category] ?? 0) + tx.amount;
    }

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Text(
              DateFormat('MMMM yyyy').format(viewModel.focusedDay).toUpperCase(),
              style: theme.textTheme.labelLarge?.copyWith(
                letterSpacing: 2,
                fontWeight: FontWeight.w900,
                fontSize: 10,
                color: theme.textTheme.bodyMedium?.color?.withValues(alpha:0.4),
              ),
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Container(
              key: calendarAreaKey,
              child: TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: viewModel.focusedDay,
                calendarFormat: CalendarFormat.month,
                selectedDayPredicate: (day) => isSameDay(viewModel.selectedDay, day),
                onDaySelected: viewModel.onDaySelected,
                onPageChanged: viewModel.onPageChanged,
                eventLoader: (day) {
                  return viewModel.filteredTransactions.where((tx) => isSameDay(tx.date, day)).toList();
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
                    Container(width: 1, height: 30, color: theme.dividerColor),
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

        if (categoryData.isNotEmpty)
          _buildChartSliver(theme, categoryData, viewModel.filter),

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
                                onRefresh: onRefresh,
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

  Widget _buildChartSliver(ThemeData theme, Map<String, double> categoryData, TransactionType? filter) {
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
                filter == TransactionType.income ? 'INCOME BREAKDOWN' : 'SPENDING BREAKDOWN',
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

