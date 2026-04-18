import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/transaction_model.dart';
import '../models/wallet.dart';
import '../services/database_service.dart';
import '../services/export_service.dart';
import '../services/session_service.dart';

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen>
    with SingleTickerProviderStateMixin {
  // ── Period options ────────────────────────────────────────────────────────
  _Period _period = _Period.thisMonth;
  DateTime _customStart = DateTime.now().subtract(const Duration(days: 30));
  DateTime _customEnd = DateTime.now();

  // ── Additional filters ────────────────────────────────────────────────────
  int? _selectedWalletKey;
  String? _selectedCategory;
  TransactionType? _selectedType;

  // ── State ─────────────────────────────────────────────────────────────────
  bool _isExportingCsv = false;
  bool _isExportingPdf = false;
  bool _isExportingExcel = false;

  // ── Data ──────────────────────────────────────────────────────────────────
  late List<Transaction> _allTransactions;
  late Map<int, Wallet> _walletMap;
  late List<Wallet> _wallets;
  late List<String> _categories;

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  static final _currencyFmt = NumberFormat('#,##0.00');
  static final _dateFmt = DateFormat('MMM d, yyyy');

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);

    final account = SessionService.activeAccount;
    final key = account?.key as int?;

    _allTransactions =
        key != null ? DatabaseService.getTransactions(key) : [];
    _wallets =
        key != null ? DatabaseService.getWallets(key) : DatabaseService.getAllWallets();
    _walletMap = {for (final w in _wallets) w.key as int: w};

    final catSet = <String>{};
    for (final tx in _allTransactions) {
      if (tx.category.isNotEmpty) catSet.add(tx.category);
    }
    _categories = catSet.toList()..sort();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ── Date range helpers ─────────────────────────────────────────────────────

  DateTime get _startDate {
    final now = DateTime.now();
    switch (_period) {
      case _Period.thisWeek:
        final weekday = now.weekday; // Mon=1, Sun=7
        return DateTime(now.year, now.month, now.day - weekday + 1);
      case _Period.thisMonth:
        return DateTime(now.year, now.month, 1);
      case _Period.last3Months:
        final d = DateTime(now.year, now.month - 2, 1);
        return d;
      case _Period.thisYear:
        return DateTime(now.year, 1, 1);
      case _Period.custom:
        return _customStart;
    }
  }

  DateTime get _endDate {
    final now = DateTime.now();
    return _period == _Period.custom ? _customEnd : now;
  }

  ExportFilters get _filters => ExportFilters(
        startDate: _startDate,
        endDate: _endDate,
        walletKey: _selectedWalletKey,
        category: _selectedCategory,
        type: _selectedType,
      );

  List<Transaction> get _filtered =>
      ExportService.applyFilters(_allTransactions, _filters);

  ExportSummary get _summary => ExportService.buildSummary(_filtered);

  // ── Custom date range picker ───────────────────────────────────────────────

  Future<void> _pickCustomRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _customStart, end: _customEnd),
      builder: (ctx, child) {
        final theme = Theme.of(ctx);
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: theme.primaryColor,
              onPrimary: Colors.white,
              surface: theme.cardColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && mounted) {
      setState(() {
        _customStart = picked.start;
        _customEnd = picked.end;
        _period = _Period.custom;
      });
    }
  }

  // ── Export actions ────────────────────────────────────────────────────────

  Future<void> _exportCsv() async {
    final filtered = _filtered;
    if (filtered.isEmpty) return;
    setState(() => _isExportingCsv = true);
    try {
      final summary = ExportService.buildSummary(filtered);
      final csv = ExportService.buildCsv(filtered, _walletMap, summary, _filters);
      final fileName = ExportService.buildFileName(_filters, '');
      final status = await ExportService.saveCsv(csv, fileName);
      if (mounted) {
        if (status == ExportStatus.success) {
          _showSnack('CSV exported successfully!', true);
        } else if (status == ExportStatus.cancelled) {
          _showSnack('CSV export cancelled', false);
        } else {
          _showSnack('CSV export failed.', false);
        }
      }
    } finally {
      if (mounted) setState(() => _isExportingCsv = false);
    }
  }

  Future<void> _exportPdf() async {
    final filtered = _filtered;
    if (filtered.isEmpty) return;
    setState(() => _isExportingPdf = true);
    try {
      final summary = ExportService.buildSummary(filtered);
      final account = SessionService.activeAccount;
      final pdfBytes = await ExportService.buildPdf(
        filtered,
        _walletMap,
        summary,
        _filters,
        account?.name ?? 'Account',
      );
      final fileName = ExportService.buildFileName(_filters, '');
      final status = await ExportService.savePdf(pdfBytes, fileName);
      if (mounted) {
        if (status == ExportStatus.success) {
          _showSnack('PDF exported successfully!', true);
        } else if (status == ExportStatus.cancelled) {
          _showSnack('PDF export cancelled', false);
        } else {
          _showSnack('PDF export failed. Check internet or permissions.', false);
        }
      }
    } catch (e) {
      debugPrint('UI PDF Error: $e');
      if (mounted) _showSnack('Failed to generate PDF.', false);
    } finally {
      if (mounted) setState(() => _isExportingPdf = false);
    }
  }

  Future<void> _exportExcel() async {
    final filtered = _filtered;
    if (filtered.isEmpty) return;
    setState(() => _isExportingExcel = true);
    try {
      final summary = ExportService.buildSummary(filtered);
      final bytes = await ExportService.buildExcel(filtered, _walletMap, summary, _filters);
      if (bytes == null) throw Exception('Failed to encode Excel');
      
      final fileName = ExportService.buildFileName(_filters, '');
      final status = await ExportService.saveExcel(bytes, fileName);
      if (mounted) {
        if (status == ExportStatus.success) {
          _showSnack('Excel exported successfully!', true);
        } else if (status == ExportStatus.cancelled) {
          _showSnack('Excel export cancelled', false);
        } else {
          _showSnack('Excel export failed.', false);
        }
      }
    } catch (e) {
      debugPrint('UI Excel Error: $e');
      if (mounted) _showSnack('Failed to generate Excel file.', false);
    } finally {
      if (mounted) setState(() => _isExportingExcel = false);
    }
  }

  void _showSnack(String msg, bool isSuccess) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isSuccess ? theme.colorScheme.tertiary : theme.colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = _summary;
    final filtered = _filtered;
    final isEmpty = filtered.isEmpty;

    return FadeTransition(
      opacity: _fadeAnim,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'Export Transactions',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Period selector ──────────────────────────────────────────
              _SectionLabel(label: 'TIME RANGE'),
              const SizedBox(height: 10),
              _PeriodSelector(
                selected: _period,
                onChanged: (p) => setState(() => _period = p),
                onCustomTap: _pickCustomRange,
                customStart: _customStart,
                customEnd: _customEnd,
              ),
              const SizedBox(height: 24),

              // ── Wallet selector ──────────────────────────────────────────
              _SectionLabel(label: 'WALLET'),
              const SizedBox(height: 10),
              _FilterDropdown<int?>(
                value: _selectedWalletKey,
                items: [
                  const DropdownMenuItem(value: null, child: Text('All Wallets')),
                  ..._wallets.map(
                    (w) => DropdownMenuItem(
                      value: w.key as int,
                      child: Text(w.name),
                    ),
                  ),
                ],
                onChanged: (v) => setState(() => _selectedWalletKey = v),
                theme: theme,
                icon: Icons.account_balance_wallet_outlined,
              ),
              const SizedBox(height: 16),

              // ── Category selector ────────────────────────────────────────
              _SectionLabel(label: 'CATEGORY'),
              const SizedBox(height: 10),
              _FilterDropdown<String?>(
                value: _selectedCategory,
                items: [
                  const DropdownMenuItem(value: null, child: Text('All Categories')),
                  ..._categories.map(
                    (c) => DropdownMenuItem(value: c, child: Text(c)),
                  ),
                ],
                onChanged: (v) => setState(() => _selectedCategory = v),
                theme: theme,
                icon: Icons.label_outline_rounded,
              ),
              const SizedBox(height: 16),

              // ── Type selector ────────────────────────────────────────────
              _SectionLabel(label: 'TYPE'),
              const SizedBox(height: 10),
              _TypeSelector(
                selected: _selectedType,
                onChanged: (t) => setState(() => _selectedType = t),
                theme: theme,
              ),
              const SizedBox(height: 28),

              // ── Live summary card ────────────────────────────────────────
              _SectionLabel(label: 'PREVIEW SUMMARY'),
              const SizedBox(height: 10),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _SummaryCard(
                  key: ValueKey('${summary.transactionCount}_${summary.totalIncome}'),
                  summary: summary,
                  theme: theme,
                  isEmpty: isEmpty,
                  startDate: _startDate,
                  endDate: _endDate,
                  currencyFmt: _currencyFmt,
                  dateFmt: _dateFmt,
                ),
              ),
              const SizedBox(height: 28),

              // ── Export buttons ───────────────────────────────────────────
              _SectionLabel(label: 'EXPORT FORMAT'),
              const SizedBox(height: 12),
              _ExportButtons(
                isEmpty: isEmpty,
                isExportingCsv: _isExportingCsv,
                isExportingPdf: _isExportingPdf,
                isExportingExcel: _isExportingExcel,
                onCsv: _exportCsv,
                onPdf: _exportPdf,
                onExcel: _exportExcel,
                theme: theme,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Period enum ──────────────────────────────────────────────────────────────

enum _Period { thisWeek, thisMonth, last3Months, thisYear, custom }

extension _PeriodLabel on _Period {
  String get label {
    switch (this) {
      case _Period.thisWeek:
        return 'This Week';
      case _Period.thisMonth:
        return 'This Month';
      case _Period.last3Months:
        return 'Last 3 Months';
      case _Period.thisYear:
        return 'This Year';
      case _Period.custom:
        return 'Custom';
    }
  }
}

// ─── Section label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      label,
      style: theme.textTheme.labelSmall?.copyWith(
        letterSpacing: 1.8,
        fontWeight: FontWeight.w800,
        color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.45),
      ),
    );
  }
}

// ─── Period selector ──────────────────────────────────────────────────────────

class _PeriodSelector extends StatelessWidget {
  final _Period selected;
  final ValueChanged<_Period> onChanged;
  final VoidCallback onCustomTap;
  final DateTime customStart;
  final DateTime customEnd;

  const _PeriodSelector({
    required this.selected,
    required this.onChanged,
    required this.onCustomTap,
    required this.customStart,
    required this.customEnd,
  });

  static final _fmt = DateFormat('MMM d');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final periods = _Period.values;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: periods.map((p) {
        final isSelected = selected == p;
        final isCustom = p == _Period.custom;
        String label = p.label;
        if (isCustom && selected == _Period.custom) {
          label = '${_fmt.format(customStart)} – ${_fmt.format(customEnd)}';
        }
        return GestureDetector(
          onTap: () {
            if (isCustom) {
              onCustomTap();
            } else {
              onChanged(p);
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: isSelected ? theme.primaryColor : theme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? theme.primaryColor : theme.dividerColor,
                width: 0.5,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? theme.scaffoldBackgroundColor
                    : theme.textTheme.bodyMedium?.color,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Generic filter dropdown ──────────────────────────────────────────────────

class _FilterDropdown<T> extends StatelessWidget {
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final ThemeData theme;
  final IconData icon;

  const _FilterDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
    required this.theme,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor, width: 0.5),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          dropdownColor: theme.cardColor,
          style: theme.textTheme.bodyMedium?.copyWith(fontSize: 14),
        ),
      ),
    );
  }
}

// ─── Transaction type selector ────────────────────────────────────────────────

class _TypeSelector extends StatelessWidget {
  final TransactionType? selected;
  final ValueChanged<TransactionType?> onChanged;
  final ThemeData theme;

  const _TypeSelector({
    required this.selected,
    required this.onChanged,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final options = <TransactionType?>[
      null,
      TransactionType.income,
      TransactionType.expense,
      TransactionType.transfer,
    ];
    final labels = ['All', 'Income', 'Expense', 'Transfer'];
    final icons = [
      Icons.all_inclusive_rounded,
      Icons.arrow_downward_rounded,
      Icons.arrow_upward_rounded,
      Icons.swap_horiz_rounded,
    ];
    final colors = [
      theme.primaryColor,
      theme.colorScheme.tertiary,
      theme.colorScheme.error,
      const Color(0xFF00796B),
    ];

    return Row(
      children: List.generate(options.length, (i) {
        final isSelected = selected == options[i];
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: i == 0 ? 0 : 6),
            child: GestureDetector(
              onTap: () => onChanged(options[i]),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colors[i].withValues(alpha: 0.15)
                      : theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? colors[i] : theme.dividerColor,
                    width: isSelected ? 1.5 : 0.5,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icons[i],
                        size: 18,
                        color: isSelected ? colors[i] : theme.dividerColor),
                    const SizedBox(height: 4),
                    Text(
                      labels[i],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? colors[i]
                            : theme.textTheme.bodyMedium?.color
                                ?.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ─── Live summary card ────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final ExportSummary summary;
  final ThemeData theme;
  final bool isEmpty;
  final DateTime startDate;
  final DateTime endDate;
  final NumberFormat currencyFmt;
  final DateFormat dateFmt;

  const _SummaryCard({
    super.key,
    required this.summary,
    required this.theme,
    required this.isEmpty,
    required this.startDate,
    required this.endDate,
    required this.currencyFmt,
    required this.dateFmt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor, width: 0.5),
      ),
      child: isEmpty
          ? _emptyState()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Period label
                Text(
                  '${dateFmt.format(startDate)} — ${dateFmt.format(endDate)}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.textTheme.bodyMedium?.color
                        ?.withValues(alpha: 0.45),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 16),

                // Stat row
                Row(
                  children: [
                    _StatChip(
                      label: 'Income',
                      value: '₱${currencyFmt.format(summary.totalIncome)}',
                      color: theme.colorScheme.tertiary,
                      theme: theme,
                    ),
                    const SizedBox(width: 8),
                    _StatChip(
                      label: 'Expenses',
                      value: '₱${currencyFmt.format(summary.totalExpenses)}',
                      color: theme.colorScheme.error,
                      theme: theme,
                    ),
                    const SizedBox(width: 8),
                    _StatChip(
                      label: 'Net',
                      value:
                          '₱${currencyFmt.format(summary.netBalance)}',
                      color: summary.netBalance >= 0
                          ? theme.colorScheme.tertiary
                          : theme.colorScheme.error,
                      theme: theme,
                    ),
                  ],
                ),

                // Tx count
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    '${summary.transactionCount} transaction${summary.transactionCount == 1 ? '' : 's'}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.textTheme.bodyMedium?.color
                          ?.withValues(alpha: 0.45),
                    ),
                  ),
                ),

                // Top categories
                if (summary.topCategories.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Divider(color: theme.dividerColor, height: 1),
                  const SizedBox(height: 12),
                  Text(
                    'TOP CATEGORIES',
                    style: theme.textTheme.labelSmall?.copyWith(
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w800,
                      color: theme.textTheme.bodyMedium?.color
                          ?.withValues(alpha: 0.35),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...summary.topCategories.take(3).map(
                        (e) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: theme.primaryColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  e.key,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Text(
                                '₱${currencyFmt.format(e.value)}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.error,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                ],
              ],
            ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Icon(Icons.inbox_outlined,
                size: 36, color: theme.dividerColor),
            const SizedBox(height: 8),
            Text(
              'No transactions in this range',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodyMedium?.color
                    ?.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final ThemeData theme;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Export buttons ───────────────────────────────────────────────────────────

class _ExportButtons extends StatelessWidget {
  final bool isEmpty;
  final bool isExportingCsv;
  final bool isExportingPdf;
  final bool isExportingExcel;
  final VoidCallback onCsv;
  final VoidCallback onPdf;
  final VoidCallback onExcel;
  final ThemeData theme;

  const _ExportButtons({
    required this.isEmpty,
    required this.isExportingCsv,
    required this.isExportingPdf,
    required this.isExportingExcel,
    required this.onCsv,
    required this.onPdf,
    required this.onExcel,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Excel Button (Premium)
        _ExportButton(
          label: 'Export to Excel (.xlsx)',
          subtitle: 'Professional multi-sheet summary & data',
          icon: Icons.grid_on_rounded,
          isLoading: isExportingExcel,
          isDisabled: isEmpty || isExportingCsv || isExportingPdf,
          color: const Color(0xFF1B5E20), // Botanical Green
          onTap: onExcel,
          theme: theme,
        ),
        const SizedBox(height: 12),
        // CSV Button
        _ExportButton(
          label: 'Export as CSV',
          subtitle: 'Simple text format for other apps',
          icon: Icons.table_chart_rounded,
          isLoading: isExportingCsv,
          isDisabled: isEmpty || isExportingPdf || isExportingExcel,
          color: const Color(0xFF1565C0),
          onTap: onCsv,
          theme: theme,
        ),
        const SizedBox(height: 12),
        // PDF Button
        _ExportButton(
          label: 'Export as PDF Report',
          subtitle: 'Clean botanical report for printing',
          icon: Icons.picture_as_pdf_rounded,
          isLoading: isExportingPdf,
          isDisabled: isEmpty || isExportingCsv || isExportingExcel,
          color: const Color(0xFFC62828),
          onTap: onPdf,
          theme: theme,
        ),
      ],
    );
  }
}

class _ExportButton extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final bool isLoading;
  final bool isDisabled;
  final Color color;
  final VoidCallback onTap;
  final ThemeData theme;

  const _ExportButton({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.isLoading,
    required this.isDisabled,
    required this.color,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = isDisabled ? theme.dividerColor : color;

    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: isDisabled
              ? theme.cardColor
              : effectiveColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color:
                isDisabled ? theme.dividerColor : effectiveColor,
            width: isDisabled ? 0.5 : 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: effectiveColor.withValues(alpha: isDisabled ? 0.06 : 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: isLoading
                  ? Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: effectiveColor,
                      ),
                    )
                  : Icon(icon, color: effectiveColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isLoading ? 'Generating...' : label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: effectiveColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.textTheme.bodyMedium?.color
                          ?.withValues(alpha: isDisabled ? 0.3 : 0.5),
                    ),
                  ),
                ],
              ),
            ),
            if (!isLoading)
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: effectiveColor.withValues(alpha: isDisabled ? 0.3 : 0.7),
              ),
          ],
        ),
      ),
    );
  }
}
