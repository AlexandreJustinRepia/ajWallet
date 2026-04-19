import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:excel/excel.dart' as xl;
import 'package:url_launcher/url_launcher.dart';

import '../models/transaction_model.dart';
import '../models/wallet.dart';
import '../models/squad.dart';
import '../models/squad_member.dart';
import '../models/squad_transaction.dart';
import 'squad_service.dart';

enum ExportStatus { success, cancelled, failed }

class ExportFilters {
  final DateTime startDate;
  final DateTime endDate;
  final int? walletKey; // null = all wallets
  final String? category; // null = all categories
  final TransactionType? type; // null = all types

  const ExportFilters({
    required this.startDate,
    required this.endDate,
    this.walletKey,
    this.category,
    this.type,
  });
}

class ExportSummary {
  final double totalIncome;
  final double totalExpenses;
  final double netBalance;
  final List<MapEntry<String, double>> topCategories;
  final int transactionCount;

  const ExportSummary({
    required this.totalIncome,
    required this.totalExpenses,
    required this.netBalance,
    required this.topCategories,
    required this.transactionCount,
  });
}

class ExportService {
  static final _currency = NumberFormat('#,##0.00');
  static final _dateFormat = DateFormat('yyyy-MM-dd');
  static final _displayDate = DateFormat('MMM d, yyyy');

  // ─── Filter helpers ────────────────────────────────────────────────────────

  static List<Transaction> applyFilters(
    List<Transaction> all,
    ExportFilters f,
  ) {
    return all.where((tx) {
      final date = DateTime(tx.date.year, tx.date.month, tx.date.day);
      final start = DateTime(
        f.startDate.year,
        f.startDate.month,
        f.startDate.day,
      );
      final end = DateTime(f.endDate.year, f.endDate.month, f.endDate.day);
      if (date.isBefore(start) || date.isAfter(end)) {
        return false;
      }
      if (f.walletKey != null &&
          tx.walletKey != f.walletKey &&
          tx.toWalletKey != f.walletKey) {
        return false;
      }
      if (f.category != null && tx.category != f.category) {
        return false;
      }
      if (f.type != null && tx.type != f.type) {
        return false;
      }
      return true;
    }).toList()..sort((a, b) => b.date.compareTo(a.date));
  }

  static ExportSummary buildSummary(List<Transaction> transactions) {
    double income = 0;
    double expense = 0;
    final Map<String, double> catMap = {};

    for (final tx in transactions) {
      if (tx.type == TransactionType.income) {
        income += tx.amount;
      } else if (tx.type == TransactionType.expense) {
        expense += tx.amount;
        catMap[tx.category] = (catMap[tx.category] ?? 0) + tx.amount;
      }
    }

    final sorted = catMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ExportSummary(
      totalIncome: income,
      totalExpenses: expense,
      netBalance: income - expense,
      topCategories: sorted.take(5).toList(),
      transactionCount: transactions.length,
    );
  }

  // ─── CSV export ────────────────────────────────────────────────────────────

  static String buildCsv(
    List<Transaction> transactions,
    Map<int, Wallet> walletMap,
    ExportSummary summary,
    ExportFilters filters,
  ) {
    final buf = StringBuffer();

    // Summary header block
    buf.writeln('RootEXP — Transaction Export');
    buf.writeln(
      'Period,${_displayDate.format(filters.startDate)} to ${_displayDate.format(filters.endDate)}',
    );
    buf.writeln('Total Income,₱${_currency.format(summary.totalIncome)}');
    buf.writeln('Total Expenses,₱${_currency.format(summary.totalExpenses)}');
    buf.writeln('Net Balance,₱${_currency.format(summary.netBalance)}');
    buf.writeln('Transaction Count,${summary.transactionCount}');
    buf.writeln();

    // Top categories
    if (summary.topCategories.isNotEmpty) {
      buf.writeln('Top Categories');
      buf.writeln('Category,Amount');
      for (final e in summary.topCategories) {
        buf.writeln('${_escapeCsv(e.key)},₱${_currency.format(e.value)}');
      }
      buf.writeln();
    }

    // Transaction table header
    buf.writeln('Date,Title,Category,Type,Amount,Wallet,Description');

    for (final tx in transactions) {
      final wallet = tx.walletKey != null ? walletMap[tx.walletKey] : null;
      final walletName = wallet?.name ?? '';
      buf.writeln(
        [
          _dateFormat.format(tx.date),
          _escapeCsv(tx.title),
          _escapeCsv(tx.category),
          tx.type.name,
          tx.amount.toStringAsFixed(2),
          _escapeCsv(walletName),
          _escapeCsv(tx.description),
        ].join(','),
      );
    }

    return buf.toString();
  }

  static String _escapeCsv(String s) {
    if (s.contains(',') || s.contains('"') || s.contains('\n')) {
      return '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }

  // ─── PDF export ────────────────────────────────────────────────────────────

  static Future<Uint8List> buildPdf(
    List<Transaction> transactions,
    Map<int, Wallet> walletMap,
    ExportSummary summary,
    ExportFilters filters,
    String accountName,
  ) async {
    pw.Font fontRegular;
    pw.Font fontBold;

    String symbol = '₱';
    try {
      // Robust font loading with fallback
      fontRegular = await PdfGoogleFonts.robotoRegular();
      fontBold = await PdfGoogleFonts.robotoBold();
    } catch (e) {
      debugPrint('PDF regular fonts failed, falling back to Helvetica: $e');
      fontRegular = pw.Font.helvetica();
      fontBold = pw.Font.helveticaBold();
      symbol = 'PHP ';
    }

    final doc = pw.Document(
      theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
    );

    // Colors
    const primaryColor = PdfColor.fromInt(0xFF1B5E20); // deep green
    const incomeColor = PdfColor.fromInt(0xFF2E7D32);
    const expenseColor = PdfColor.fromInt(0xFFC62828);
    const bgColor = PdfColor.fromInt(0xFFF5F5F5);
    const cardBg = PdfColors.white;
    const textMuted = PdfColor.fromInt(0xFF757575);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (ctx) =>
            _buildHeader(ctx, accountName, filters, primaryColor, bgColor),
        footer: (ctx) => _buildFooter(ctx, textMuted),
        build: (ctx) => [
          pw.SizedBox(height: 16),
          // ── Summary cards ──────────────────────────────────────────────
          _buildSummarySection(
            summary,
            incomeColor,
            expenseColor,
            primaryColor,
            bgColor,
            symbol,
          ),
          pw.SizedBox(height: 20),
          // ── Expense Chart & Categories ──────────────────────────────────
          if (summary.topCategories.isNotEmpty) ...[
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  flex: 1,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Spending Breakdown', primaryColor),
                      pw.SizedBox(height: 12),
                      _buildCategoryChart(summary.topCategories, primaryColor),
                    ],
                  ),
                ),
                pw.SizedBox(width: 32),
                pw.Expanded(
                  flex: 1,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle(
                        'Top Spending Categories',
                        primaryColor,
                      ),
                      pw.SizedBox(height: 8),
                      _buildCategoryTable(
                        summary.topCategories,
                        summary.totalExpenses,
                        primaryColor,
                        bgColor,
                        cardBg,
                        symbol,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 20),
          ],
          // ── Transactions table ─────────────────────────────────────────
          _buildSectionTitle('Transaction History', primaryColor),
          pw.SizedBox(height: 8),
          if (transactions.isEmpty)
            pw.Text(
              'No transactions in the selected period.',
              style: pw.TextStyle(color: textMuted, fontSize: 11),
            )
          else
            _buildTransactionTable(
              transactions,
              walletMap,
              incomeColor,
              expenseColor,
              bgColor,
              cardBg,
              textMuted,
              symbol,
            ),
        ],
      ),
    );

    return doc.save();
  }

  static Future<Uint8List> buildSquadPdf(
    Squad squad,
    List<SquadMember> members,
    List<SquadTransaction> transactions,
    SquadBalances balances,
    String accountName,
  ) async {
    pw.Font fontRegular;
    pw.Font fontBold;

    String symbol = '₱';
    try {
      fontRegular = await PdfGoogleFonts.robotoRegular();
      fontBold = await PdfGoogleFonts.robotoBold();
    } catch (e) {
      fontRegular = pw.Font.helvetica();
      fontBold = pw.Font.helveticaBold();
      symbol = 'PHP ';
    }

    final doc = pw.Document(
      theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
    );

    // Colors
    final primaryColor = squad.color != null
        ? PdfColor.fromInt(int.parse(squad.color!))
        : PdfColor.fromInt(0xFF1B5E20);
    const incomeColor = PdfColor.fromInt(0xFF2E7D32);
    const expenseColor = PdfColor.fromInt(0xFFC62828);
    const bgColor = PdfColor.fromInt(0xFFF5F5F5);
    const cardBg = PdfColors.white;
    const textMuted = PdfColor.fromInt(0xFF757575);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (ctx) =>
            _buildSquadHeader(ctx, squad, accountName, primaryColor),
        footer: (ctx) => _buildFooter(ctx, textMuted),
        build: (ctx) => [
          pw.SizedBox(height: 16),
          // ── Summary sections ──────────────────────────────────────────
          _buildSquadSummary(
            balances,
            incomeColor,
            expenseColor,
            primaryColor,
            bgColor,
            symbol,
          ),
          pw.SizedBox(height: 24),
          // ── Members & Balances ────────────────────────────────────────
          _buildSectionTitle('Member Balances', primaryColor),
          pw.SizedBox(height: 8),
          _buildMemberBalancesTable(
            members,
            balances,
            incomeColor,
            expenseColor,
            bgColor,
            cardBg,
            symbol,
          ),
          pw.SizedBox(height: 24),
          // ── Activity History ──────────────────────────────────────────
          _buildSectionTitle('Squad Activity History', primaryColor),
          pw.SizedBox(height: 8),
          if (transactions.isEmpty)
            pw.Text(
              'No activity recorded yet.',
              style: pw.TextStyle(color: textMuted, fontSize: 11),
            )
          else
            _buildSquadTransactionTable(
              transactions,
              members,
              incomeColor,
              expenseColor,
              bgColor,
              cardBg,
              textMuted,
              symbol,
            ),
        ],
      ),
    );

    return doc.save();
  }

  static Future<Uint8List> buildSquadTransactionPdf(
    SquadTransaction tx,
    Squad squad,
    List<SquadMember> members,
    SquadBalances balances,
    String accountName,
  ) async {
    pw.Font fontRegular;
    pw.Font fontBold;

    String symbol = '₱';
    try {
      fontRegular = await PdfGoogleFonts.robotoRegular();
      fontBold = await PdfGoogleFonts.robotoBold();
    } catch (e) {
      fontRegular = pw.Font.helvetica();
      fontBold = pw.Font.helveticaBold();
      symbol = 'PHP ';
    }

    final doc = pw.Document(
      theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
    );

    final primaryColor = squad.color != null
        ? PdfColor.fromInt(int.parse(squad.color!))
        : PdfColor.fromInt(0xFF1B5E20);

    final payer = members.firstWhere((m) => m.key == tx.payerMemberKey);

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.all(24),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'BILL RECEIPT',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    pw.Text(
                      squad.name,
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      _displayDate.format(tx.date),
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'ID: ${tx.key}',
                      style: const pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            pw.Divider(color: primaryColor, thickness: 1.5, height: 24),

            // Title & Amount
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(
                    tx.title.toUpperCase(),
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    '$symbol${_currency.format(tx.amount)}',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Paid by ${payer.name}',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 32),

            // Split Breakdown
            _buildSectionTitle('Split Breakdown', primaryColor),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FixedColumnWidth(70),
                2: const pw.FixedColumnWidth(85),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _tableHeaderSquad('MEMBER'),
                    _tableHeaderSquad('BILL SHARE', align: pw.TextAlign.right),
                    _tableHeaderSquad(
                      'TOTAL PENDING',
                      align: pw.TextAlign.right,
                    ),
                  ],
                ),
                ...tx.memberSplits.entries.map((entry) {
                  final member = members.firstWhere((m) => m.key == entry.key);
                  final netBalance =
                      balances.memberNetBalances[member.key as int] ?? 0.0;
                  final isPositive = netBalance > 0;
                  final isNegative = netBalance < 0;

                  double share = entry.value;
                  if (tx.splitType == SplitType.percentage) {
                    share = (entry.value / 100) * tx.amount;
                  } else if (tx.splitType == SplitType.equal) {
                    share = tx.amount / tx.memberSplits.length;
                  }
                  return pw.TableRow(
                    children: [
                      _cell(member.name + (member.isYou ? ' (You)' : '')),
                      _cell(
                        '$symbol${_currency.format(share)}',
                        align: pw.TextAlign.right,
                        bold: true,
                      ),
                      _cell(
                        isPositive
                            ? 'Gets $symbol${_currency.format(netBalance)}'
                            : (isNegative
                                  ? 'Owes $symbol${_currency.format(netBalance.abs())}'
                                  : 'Settled'),
                        align: pw.TextAlign.right,
                        color: isPositive
                            ? PdfColors.green
                            : (isNegative ? PdfColors.red : PdfColors.grey700),
                        bold: true,
                      ),
                    ],
                  );
                }),
              ],
            ),

            pw.Spacer(),
            pw.Divider(color: PdfColors.grey300),
            pw.Center(
              child: pw.Text(
                'Generated via RootEXP • Shared Economy Tracking',
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey500,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return doc.save();
  }

  static pw.Widget _buildSquadHeader(
    pw.Context ctx,
    Squad squad,
    String accountName,
    PdfColor primary,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 12),
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: primary, width: 2)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                squad.name.toUpperCase(),
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: primary,
                  letterSpacing: 1.2,
                ),
              ),
              pw.Text(
                'Squad Expense Report — $accountName',
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'DATE GENERATED',
                style: pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey600,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                _displayDate.format(DateTime.now()),
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSquadSummary(
    SquadBalances balances,
    PdfColor incomeColor,
    PdfColor expenseColor,
    PdfColor primary,
    PdfColor bg,
    String symbol,
  ) {
    return pw.Row(
      children: [
        _summaryCard(
          'YOU ARE OWED',
          '$symbol${_currency.format(balances.youAreOwed)}',
          incomeColor,
          bg,
        ),
        pw.SizedBox(width: 8),
        _summaryCard(
          'YOU OWE',
          '$symbol${_currency.format(balances.youOwe)}',
          expenseColor,
          bg,
        ),
        pw.SizedBox(width: 8),
        _summaryCard(
          'YOUR NET STATUS',
          '${balances.net >= 0 ? "+" : ""}$symbol${_currency.format(balances.net)}',
          balances.net >= 0 ? incomeColor : expenseColor,
          bg,
        ),
      ],
    );
  }

  static pw.Widget _buildMemberBalancesTable(
    List<SquadMember> members,
    SquadBalances balances,
    PdfColor incomeColor,
    PdfColor expenseColor,
    PdfColor bg,
    PdfColor cardBg,
    String symbol,
  ) {
    final rows = members.asMap().entries.map((entry) {
      final i = entry.key;
      final m = entry.value;
      final balance = balances.memberNetBalances[m.key as int] ?? 0.0;
      final isPositive = balance > 0;
      final isNegative = balance < 0;
      final rowColor = i.isEven ? cardBg : bg;
      final statusColor = isPositive
          ? incomeColor
          : (isNegative ? expenseColor : PdfColors.grey700);

      return pw.TableRow(
        decoration: pw.BoxDecoration(color: rowColor),
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            child: pw.Row(
              children: [
                pw.Text(
                  m.name,
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
                if (m.isYou) ...[
                  pw.SizedBox(width: 4),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey200,
                      borderRadius: pw.BorderRadius.circular(2),
                    ),
                    child: pw.Text(
                      'YOU',
                      style: pw.TextStyle(
                        fontSize: 7,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            child: pw.Text(
              isPositive ? 'Gets back' : (isNegative ? 'Owes' : 'Settled'),
              style: pw.TextStyle(
                color: statusColor,
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            child: pw.Text(
              '$symbol${_currency.format(balance.abs())}',
              style: pw.TextStyle(
                color: statusColor,
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
              ),
              textAlign: pw.TextAlign.right,
            ),
          ),
        ],
      );
    }).toList();

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FixedColumnWidth(100),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _tableHeaderSquad('MEMBER NAME'),
            _tableHeaderSquad('STATUS'),
            _tableHeaderSquad('AMOUNT', align: pw.TextAlign.right),
          ],
        ),
        ...rows,
      ],
    );
  }

  static pw.Widget _buildSquadTransactionTable(
    List<SquadTransaction> transactions,
    List<SquadMember> members,
    PdfColor incomeColor,
    PdfColor expenseColor,
    PdfColor bg,
    PdfColor cardBg,
    PdfColor muted,
    String symbol,
  ) {
    // Sort transactions by date descending
    final sorted = transactions.toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final rows = sorted.asMap().entries.map((entry) {
      final i = entry.key;
      final tx = entry.value;
      final payer = members.firstWhere((m) => m.key == tx.payerMemberKey);
      final rowColor = i.isEven ? cardBg : bg;

      return pw.TableRow(
        decoration: pw.BoxDecoration(color: rowColor),
        children: [
          _cell(DateFormat('MM/dd').format(tx.date), muted: muted),
          _cell(tx.title, bold: !tx.isSettlement),
          _cell(payer.name, muted: muted),
          _cell(tx.isSettlement ? 'Settlement' : tx.splitType.name),
          _cell(
            '$symbol${_currency.format(tx.amount)}',
            bold: true,
            color: tx.isSettlement ? incomeColor : expenseColor,
            align: pw.TextAlign.right,
          ),
        ],
      );
    }).toList();

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FixedColumnWidth(40),
        1: const pw.FlexColumnWidth(3),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FixedColumnWidth(60),
        4: const pw.FixedColumnWidth(80),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _tableHeaderSquad('DATE'),
            _tableHeaderSquad('DESCRIPTION'),
            _tableHeaderSquad('PAID BY'),
            _tableHeaderSquad('TYPE'),
            _tableHeaderSquad('AMOUNT', align: pw.TextAlign.right),
          ],
        ),
        ...rows,
      ],
    );
  }

  static pw.Widget _tableHeaderSquad(
    String text, {
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.grey800,
          letterSpacing: 0.5,
        ),
        textAlign: align,
      ),
    );
  }

  static pw.Widget _cell(
    String text, {
    PdfColor? color,
    PdfColor? muted,
    bool bold = false,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color ?? muted ?? PdfColors.black,
        ),
        textAlign: align,
      ),
    );
  }

  static pw.Widget _buildHeader(
    pw.Context ctx,
    String accountName,
    ExportFilters filters,
    PdfColor primary,
    PdfColor bg,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 12),
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: primary, width: 2)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'RootEXP',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: primary,
                ),
              ),
              pw.Text(
                'Transaction Report — $accountName',
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                '${_displayDate.format(filters.startDate)} – ${_displayDate.format(filters.endDate)}',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: primary,
                ),
              ),
              pw.Text(
                'Generated ${_displayDate.format(DateTime.now())}',
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(pw.Context ctx, PdfColor color) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 10),
      child: pw.Text(
        'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
        style: pw.TextStyle(color: color, fontSize: 9),
      ),
    );
  }

  static pw.Widget _buildSectionTitle(String title, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 4),
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: color, width: 1)),
      ),
      child: pw.Text(
        title.toUpperCase(),
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: color,
          letterSpacing: 1,
        ),
      ),
    );
  }

  static pw.Widget _buildSummarySection(
    ExportSummary summary,
    PdfColor incomeColor,
    PdfColor expenseColor,
    PdfColor primary,
    PdfColor bg,
    String symbol,
  ) {
    return pw.Row(
      children: [
        _summaryCard(
          'TOTAL INCOME',
          '$symbol${_currency.format(summary.totalIncome)}',
          incomeColor,
          bg,
        ),
        pw.SizedBox(width: 8),
        _summaryCard(
          'TOTAL EXPENSES',
          '$symbol${_currency.format(summary.totalExpenses)}',
          expenseColor,
          bg,
        ),
        pw.SizedBox(width: 8),
        _summaryCard(
          'NET BALANCE',
          '$symbol${_currency.format(summary.netBalance)}',
          summary.netBalance >= 0 ? incomeColor : expenseColor,
          bg,
        ),
        pw.SizedBox(width: 8),
        _summaryCard(
          'TRANSACTIONS',
          '${summary.transactionCount}',
          primary,
          bg,
        ),
      ],
    );
  }

  static pw.Widget _buildCategoryChart(
    List<MapEntry<String, double>> categories,
    PdfColor primary,
  ) {
    // Top 5 categories for chart stability
    final chartData = categories.take(5).toList();
    if (chartData.isEmpty) return pw.SizedBox();

    // Botanical / Material themed green palette
    final List<PdfColor> distinctColors = [
      PdfColor.fromInt(0xFF1B5E20), // Green 900
      PdfColor.fromInt(0xFF2E7D32), // Green 800
      PdfColor.fromInt(0xFF43A047), // Green 600
      PdfColor.fromInt(0xFF66BB6A), // Green 400
      PdfColor.fromInt(0xFF81C784), // Green 300
    ];

    return pw.Container(
      height: 140,
      child: pw.Chart(
        grid: pw.PieGrid(),
        datasets: List.generate(chartData.length, (index) {
          final entry = chartData[index];
          return pw.PieDataSet(
            value: entry.value,
            color: index < distinctColors.length
                ? distinctColors[index]
                : PdfColors.grey500,
            legend: entry.key,
            drawSurface: true,
            drawBorder: true,
            borderColor: PdfColors.white,
            borderWidth: 1,
          );
        }),
      ),
    );
  }

  static pw.Widget _summaryCard(
    String label,
    String value,
    PdfColor color,
    PdfColor bg,
  ) {
    return pw.Expanded(
      child: pw.Container(
        height: 40, // Fixed height for balance
        decoration: pw.BoxDecoration(
          color: bg,
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Row(
          children: [
            // Left indicator bar
            pw.Container(
              width: 3,
              margin: const pw.EdgeInsets.symmetric(vertical: 4),
              decoration: pw.BoxDecoration(
                color: color,
                borderRadius: pw.BorderRadius.circular(2),
              ),
            ),
            pw.SizedBox(width: 8),
            pw.Expanded(
              child: pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 6),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text(
                      label,
                      style: pw.TextStyle(
                        fontSize: 6,
                        fontWeight: pw.FontWeight.bold,
                        letterSpacing: 0.5,
                        color: PdfColors.grey600,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      value,
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildCategoryTable(
    List<MapEntry<String, double>> categories,
    double totalExpenses,
    PdfColor primary,
    PdfColor bg,
    PdfColor cardBg,
    String symbol,
  ) {
    final rows = categories.map((e) {
      final pct = totalExpenses > 0 ? (e.value / totalExpenses * 100) : 0.0;
      return pw.TableRow(
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: pw.Text(e.key, style: const pw.TextStyle(fontSize: 10)),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: pw.Text(
              '$symbol${_currency.format(e.value)}',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: pw.Text(
              '${pct.toStringAsFixed(1)}%',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            ),
          ),
        ],
      );
    }).toList();

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(1),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: primary),
          children: [
            _tableHeader('CATEGORY'),
            _tableHeader('AMOUNT'),
            _tableHeader('SHARE'),
          ],
        ),
        ...rows,
      ],
    );
  }

  static pw.Widget _tableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
          letterSpacing: 1,
        ),
      ),
    );
  }

  static pw.Widget _buildTransactionTable(
    List<Transaction> transactions,
    Map<int, Wallet> walletMap,
    PdfColor incomeColor,
    PdfColor expenseColor,
    PdfColor bg,
    PdfColor cardBg,
    PdfColor muted,
    String symbol,
  ) {
    final rows = transactions.asMap().entries.map((entry) {
      final i = entry.key;
      final tx = entry.value;
      final wallet = tx.walletKey != null ? walletMap[tx.walletKey] : null;
      final isIncome = tx.type == TransactionType.income;
      final rowColor = i.isEven ? cardBg : bg;
      final amountColor = isIncome ? incomeColor : expenseColor;

      return pw.TableRow(
        decoration: pw.BoxDecoration(color: rowColor),
        children: [
          _cell(DateFormat('MM/dd/yy').format(tx.date), muted: muted),
          _cell(tx.title),
          _cell(tx.category, muted: muted),
          _cell(tx.type.name, color: amountColor),
          _cell(
            '${isIncome
                ? '+'
                : tx.type == TransactionType.expense
                ? '-'
                : ''}$symbol${_currency.format(tx.amount)}',
            color: amountColor,
            bold: true,
          ),
          _cell(wallet?.name ?? '—', muted: muted),
        ],
      );
    }).toList();

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FixedColumnWidth(54),
        1: const pw.FlexColumnWidth(3),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FixedColumnWidth(52),
        4: const pw.FixedColumnWidth(72),
        5: const pw.FlexColumnWidth(2),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(
            color: PdfColor.fromInt(0xFF1B5E20),
          ),
          children: [
            _tableHeader('DATE'),
            _tableHeader('TITLE'),
            _tableHeader('CATEGORY'),
            _tableHeader('TYPE'),
            _tableHeader('AMOUNT'),
            _tableHeader('WALLET'),
          ],
        ),
        ...rows,
      ],
    );
  }

  // ─── Excel export ──────────────────────────────────────────────────────────

  static Future<Uint8List?> buildExcel(
    List<Transaction> transactions,
    Map<int, Wallet> walletMap,
    ExportSummary summary,
    ExportFilters filters,
  ) async {
    final excel = xl.Excel.createExcel();

    // --- Sheet 1: Summary ---
    final summarySheet = excel['Summary'];
    excel.delete('Sheet1'); // Remove default sheet

    // Styles for Summary
    final headerStyle = xl.CellStyle(
      bold: true,
      fontSize: 16,
      fontColorHex: xl.ExcelColor.fromHexString('#FFFFFF'),
      backgroundColorHex: xl.ExcelColor.fromHexString('#1B5E20'), // Theme Green
      horizontalAlign: xl.HorizontalAlign.Center,
      verticalAlign: xl.VerticalAlign.Center,
    );

    final subHeaderStyle = xl.CellStyle(
      bold: true,
      fontSize: 12,
      fontColorHex: xl.ExcelColor.fromHexString('#757575'),
    );

    final incomeStyle = xl.CellStyle(
      fontColorHex: xl.ExcelColor.fromHexString('#2E7D32'),
      bold: true,
      horizontalAlign: xl.HorizontalAlign.Right,
    );

    final expenseStyle = xl.CellStyle(
      fontColorHex: xl.ExcelColor.fromHexString('#C62828'),
      bold: true,
      horizontalAlign: xl.HorizontalAlign.Right,
    );

    final labelStyle = xl.CellStyle(
      bold: true,
      horizontalAlign: xl.HorizontalAlign.Left,
    );

    // Set Column Widths for Summary
    summarySheet.setColumnWidth(0, 25.0);
    summarySheet.setColumnWidth(1, 40.0);

    // Title Row
    summarySheet.merge(
      xl.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
      xl.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 0),
    );
    summarySheet.cell(
        xl.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
      )
      ..value = xl.TextCellValue('RootEXP — Financial Summary')
      ..cellStyle = headerStyle;

    summarySheet.cell(
        xl.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1),
      )
      ..value = xl.TextCellValue('Period')
      ..cellStyle = subHeaderStyle;
    summarySheet
        .cell(xl.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 1))
        .value = xl.TextCellValue(
      '${_displayDate.format(filters.startDate)} to ${_displayDate.format(filters.endDate)}',
    );

    // Summary Stats
    summarySheet.cell(
        xl.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 3),
      )
      ..value = xl.TextCellValue('TOTAL INCOME')
      ..cellStyle = labelStyle;
    summarySheet.cell(
        xl.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 3),
      )
      ..value = xl.DoubleCellValue(summary.totalIncome)
      ..cellStyle = incomeStyle;

    summarySheet.cell(
        xl.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 4),
      )
      ..value = xl.TextCellValue('TOTAL EXPENSES')
      ..cellStyle = labelStyle;
    summarySheet.cell(
        xl.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 4),
      )
      ..value = xl.DoubleCellValue(summary.totalExpenses)
      ..cellStyle = expenseStyle;

    summarySheet.cell(
        xl.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 5),
      )
      ..value = xl.TextCellValue('NET BALANCE')
      ..cellStyle = labelStyle;

    final finalNetStyle = xl.CellStyle(
      bold: true,
      horizontalAlign: xl.HorizontalAlign.Right,
      fontColorHex: xl.ExcelColor.fromHexString(
        summary.netBalance >= 0 ? '#2E7D32' : '#C62828',
      ),
    );

    summarySheet.cell(
        xl.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 5),
      )
      ..value = xl.DoubleCellValue(summary.netBalance)
      ..cellStyle = finalNetStyle;

    // --- Sheet 2: Transactions ---
    final txSheet = excel['Transactions'];

    final txHeaderStyle = xl.CellStyle(
      bold: true,
      fontSize: 12,
      backgroundColorHex: xl.ExcelColor.fromHexString('#1B5E20'),
      fontColorHex: xl.ExcelColor.fromHexString('#FFFFFF'),
      horizontalAlign: xl.HorizontalAlign.Center,
      verticalAlign: xl.VerticalAlign.Center,
    );

    // Set Column Widths for Transactions
    txSheet.setColumnWidth(0, 15.0); // Date
    txSheet.setColumnWidth(1, 30.0); // Title
    txSheet.setColumnWidth(2, 20.0); // Category
    txSheet.setColumnWidth(3, 15.0); // Type
    txSheet.setColumnWidth(4, 18.0); // Amount
    txSheet.setColumnWidth(5, 20.0); // Wallet
    txSheet.setColumnWidth(6, 40.0); // Description

    final headers = [
      'Date',
      'Title',
      'Category',
      'Type',
      'Amount',
      'Wallet',
      'Description',
    ];
    for (int i = 0; i < headers.length; i++) {
      txSheet.cell(xl.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
        ..value = xl.TextCellValue(headers[i])
        ..cellStyle = txHeaderStyle;
    }

    final amountCellFormat = xl.CellStyle(
      horizontalAlign: xl.HorizontalAlign.Right,
    );
    final dateCellFormat = xl.CellStyle(
      horizontalAlign: xl.HorizontalAlign.Center,
    );

    for (int i = 0; i < transactions.length; i++) {
      final tx = transactions[i];
      final wallet = tx.walletKey != null ? walletMap[tx.walletKey] : null;
      final rowIndex = i + 1;

      txSheet.cell(
          xl.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
        )
        ..value = xl.TextCellValue(_dateFormat.format(tx.date))
        ..cellStyle = dateCellFormat;
      txSheet
          .cell(
            xl.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex),
          )
          .value = xl.TextCellValue(
        tx.title,
      );
      txSheet
          .cell(
            xl.CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex),
          )
          .value = xl.TextCellValue(
        tx.category,
      );
      txSheet
          .cell(
            xl.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex),
          )
          .value = xl.TextCellValue(
        tx.type.name,
      );
      txSheet.cell(
          xl.CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex),
        )
        ..value = xl.DoubleCellValue(tx.amount)
        ..cellStyle = amountCellFormat;
      txSheet
          .cell(
            xl.CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex),
          )
          .value = xl.TextCellValue(
        wallet?.name ?? '',
      );
      txSheet
          .cell(
            xl.CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex),
          )
          .value = xl.TextCellValue(
        tx.description,
      );

      // Zebra striping
      if (rowIndex % 2 == 0) {
        final currentAmountStyle = xl.CellStyle(
          horizontalAlign: xl.HorizontalAlign.Right,
          backgroundColorHex: xl.ExcelColor.fromHexString('#F8F9FA'),
        );
        final currentDateStyle = xl.CellStyle(
          horizontalAlign: xl.HorizontalAlign.Center,
          backgroundColorHex: xl.ExcelColor.fromHexString('#F8F9FA'),
        );
        final defaultStripeStyle = xl.CellStyle(
          backgroundColorHex: xl.ExcelColor.fromHexString('#F8F9FA'),
        );

        for (int col = 0; col < headers.length; col++) {
          if (col == 0) {
            txSheet
                    .cell(
                      xl.CellIndex.indexByColumnRow(
                        columnIndex: col,
                        rowIndex: rowIndex,
                      ),
                    )
                    .cellStyle =
                currentDateStyle;
          } else if (col == 4) {
            txSheet
                    .cell(
                      xl.CellIndex.indexByColumnRow(
                        columnIndex: col,
                        rowIndex: rowIndex,
                      ),
                    )
                    .cellStyle =
                currentAmountStyle;
          } else {
            txSheet
                    .cell(
                      xl.CellIndex.indexByColumnRow(
                        columnIndex: col,
                        rowIndex: rowIndex,
                      ),
                    )
                    .cellStyle =
                defaultStripeStyle;
          }
        }
      }
    }

    return Uint8List.fromList(excel.encode()!);
  }

  // ─── Save / Share ──────────────────────────────────────────────────────────

  static Future<ExportStatus> saveExcel(
    Uint8List excelBytes,
    String fileName,
  ) async {
    try {
      final file = await _writeTempFile('$fileName.xlsx', excelBytes);
      if (Platform.isAndroid || Platform.isIOS) {
        final result = await Share.shareXFiles([
          XFile(
            file.path,
            mimeType:
                'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          ),
        ], subject: fileName);
        return result.status == ShareResultStatus.dismissed
            ? ExportStatus.cancelled
            : ExportStatus.success;
      } else {
        // Desktop (Windows): Launch the file to open it in Excel
        final uri = Uri.file(file.path);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
          return ExportStatus.success;
        } else {
          debugPrint('Excel saved to but could not launch: ${file.path}');
          return ExportStatus.success;
        }
      }
    } catch (e) {
      debugPrint('Excel export error: $e');
      return ExportStatus.failed;
    }
  }

  static Future<ExportStatus> saveCsv(
    String csvContent,
    String fileName,
  ) async {
    try {
      final bytes = Uint8List.fromList(csvContent.codeUnits);
      final file = await _writeTempFile('$fileName.csv', bytes);

      if (Platform.isAndroid || Platform.isIOS) {
        final result = await Share.shareXFiles([
          XFile(file.path, mimeType: 'text/csv'),
        ], subject: fileName);
        if (result.status == ShareResultStatus.dismissed) {
          return ExportStatus.cancelled;
        }
        return ExportStatus.success;
      } else {
        // Desktop (Windows): Launch the file to open it in NotePad/Excel
        final uri = Uri.file(file.path);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        } else {
          debugPrint('CSV saved to: ${file.path}');
        }
        return ExportStatus.success;
      }
    } catch (e) {
      debugPrint('CSV export error: $e');
      return ExportStatus.failed;
    }
  }

  static Future<ExportStatus> savePdf(
    Uint8List pdfBytes,
    String fileName,
  ) async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        final ok = await Printing.sharePdf(
          bytes: pdfBytes,
          filename: '$fileName.pdf',
        );
        return ok ? ExportStatus.success : ExportStatus.cancelled;
      } else {
        // On Windows/Desktop, Printing.layoutPdf shows the native print preview dialog
        // which includes "Save as PDF" and physical printer selection.
        final ok = await Printing.layoutPdf(
          onLayout: (format) async => pdfBytes,
          name: fileName,
        );
        return ok ? ExportStatus.success : ExportStatus.cancelled;
      }
    } catch (e) {
      debugPrint('PDF export error details: $e');
      return ExportStatus.failed;
    }
  }

  static Future<File> _writeTempFile(String name, Uint8List bytes) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$name');
    await file.writeAsBytes(bytes);
    return file;
  }

  /// Convenience — builds the suggested file name from the filters
  static String buildFileName(ExportFilters filters, String suffix) {
    final s = DateFormat('yyyyMMdd').format(filters.startDate);
    final e = DateFormat('yyyyMMdd').format(filters.endDate);
    return 'rootexp_${s}_$e$suffix';
  }
}
