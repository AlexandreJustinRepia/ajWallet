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

enum ExportStatus { success, cancelled, failed }

class ExportFilters {
  final DateTime startDate;
  final DateTime endDate;
  final int? walletKey;       // null = all wallets
  final String? category;     // null = all categories
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
      final start = DateTime(f.startDate.year, f.startDate.month, f.startDate.day);
      final end = DateTime(f.endDate.year, f.endDate.month, f.endDate.day);
      if (date.isBefore(start) || date.isAfter(end)) { return false; }
      if (f.walletKey != null &&
          tx.walletKey != f.walletKey &&
          tx.toWalletKey != f.walletKey) { return false; }
      if (f.category != null && tx.category != f.category) { return false; }
      if (f.type != null && tx.type != f.type) { return false; }
      return true;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
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
        'Period,${_displayDate.format(filters.startDate)} to ${_displayDate.format(filters.endDate)}');
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
      buf.writeln([
        _dateFormat.format(tx.date),
        _escapeCsv(tx.title),
        _escapeCsv(tx.category),
        tx.type.name,
        tx.amount.toStringAsFixed(2),
        _escapeCsv(walletName),
        _escapeCsv(tx.description),
      ].join(','));
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

    try {
      // Robust font loading with fallback
      fontRegular = await PdfGoogleFonts.robotoRegular();
      fontBold = await PdfGoogleFonts.robotoBold();
    } catch (e) {
      debugPrint('PDF regular fonts failed, falling back to Helvetica: $e');
      fontRegular = pw.Font.helvetica();
      fontBold = pw.Font.helveticaBold();
    }

    final doc = pw.Document(
      theme: pw.ThemeData.withFont(
        base: fontRegular,
        bold: fontBold,
      ),
    );

    // Colors
    const primaryColor = PdfColor.fromInt(0xFF1B5E20);      // deep green
    const incomeColor = PdfColor.fromInt(0xFF2E7D32);
    const expenseColor = PdfColor.fromInt(0xFFC62828);
    const bgColor = PdfColor.fromInt(0xFFF5F5F5);
    const cardBg = PdfColors.white;
    const textMuted = PdfColor.fromInt(0xFF757575);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (ctx) => _buildHeader(
          ctx, accountName, filters, primaryColor, bgColor,
        ),
        footer: (ctx) => _buildFooter(ctx, textMuted),
        build: (ctx) => [
          pw.SizedBox(height: 16),
          // ── Summary cards ──────────────────────────────────────────────
          _buildSummarySection(summary, incomeColor, expenseColor, primaryColor, bgColor),
          pw.SizedBox(height: 20),
          // ── Top categories ─────────────────────────────────────────────
          if (summary.topCategories.isNotEmpty) ...[
            _buildSectionTitle('Top Spending Categories', primaryColor),
            pw.SizedBox(height: 8),
            _buildCategoryTable(summary.topCategories, summary.totalExpenses, primaryColor, bgColor, cardBg),
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
            _buildTransactionTable(transactions, walletMap, incomeColor, expenseColor, bgColor, cardBg, textMuted),
        ],
      ),
    );

    return doc.save();
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
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(pw.Context ctx, PdfColor muted) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 8),
      child: pw.Text(
        'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
        style: pw.TextStyle(fontSize: 9, color: muted),
      ),
    );
  }

  static pw.Widget _buildSectionTitle(String title, PdfColor color) {
    return pw.Text(
      title.toUpperCase(),
      style: pw.TextStyle(
        fontSize: 9,
        fontWeight: pw.FontWeight.bold,
        letterSpacing: 1.5,
        color: color,
      ),
    );
  }

  static pw.Widget _buildSummarySection(
    ExportSummary summary,
    PdfColor incomeColor,
    PdfColor expenseColor,
    PdfColor primary,
    PdfColor bg,
  ) {
    return pw.Row(
      children: [
        _summaryCard('TOTAL INCOME', '₱${_currency.format(summary.totalIncome)}', incomeColor, bg),
        pw.SizedBox(width: 8),
        _summaryCard('TOTAL EXPENSES', '₱${_currency.format(summary.totalExpenses)}', expenseColor, bg),
        pw.SizedBox(width: 8),
        _summaryCard(
          'NET BALANCE',
          '₱${_currency.format(summary.netBalance)}',
          summary.netBalance >= 0 ? incomeColor : expenseColor,
          bg,
        ),
        pw.SizedBox(width: 8),
        _summaryCard('TRANSACTIONS', '${summary.transactionCount}', primary, bg),
      ],
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
              '₱${_currency.format(e.value)}',
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
            '${isIncome ? '+' : tx.type == TransactionType.expense ? '-' : ''}₱${_currency.format(tx.amount)}',
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
          decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF1B5E20)),
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

  static pw.Widget _cell(
    String text, {
    PdfColor? color,
    PdfColor? muted,
    bool bold = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color ?? muted ?? PdfColors.black,
        ),
        overflow: pw.TextOverflow.clip,
      ),
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
      fontSize: 14,
      fontColorHex: xl.ExcelColor.fromHexString('#FFFFFF'),
      backgroundColorHex: xl.ExcelColor.fromHexString('#1B5E20'), // Theme Green
      horizontalAlign: xl.HorizontalAlign.Center,
    );

    final subHeaderStyle = xl.CellStyle(
      bold: true,
      fontSize: 11,
      fontColorHex: xl.ExcelColor.fromHexString('#757575'),
    );

    final incomeStyle = xl.CellStyle(
      fontColorHex: xl.ExcelColor.fromHexString('#2E7D32'),
      bold: true,
    );

    final expenseStyle = xl.CellStyle(
      fontColorHex: xl.ExcelColor.fromHexString('#C62828'),
      bold: true,
    );

    // Title Row
    summarySheet.merge(xl.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0), 
                      xl.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 0));
    summarySheet.cell(xl.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
      ..value = xl.TextCellValue('RootEXP — Financial Summary')
      ..cellStyle = headerStyle;

    summarySheet.cell(xl.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1))
      ..value = xl.TextCellValue('Period')
      ..cellStyle = subHeaderStyle;
    summarySheet.cell(xl.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 1))
      .value = xl.TextCellValue('${_displayDate.format(filters.startDate)} to ${_displayDate.format(filters.endDate)}');

    // Summary Stats
    summarySheet.cell(xl.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 3)).value = xl.TextCellValue('TOTAL INCOME');
    summarySheet.cell(xl.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 3))
      ..value = xl.DoubleCellValue(summary.totalIncome)
      ..cellStyle = incomeStyle;

    summarySheet.cell(xl.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 4)).value = xl.TextCellValue('TOTAL EXPENSES');
    summarySheet.cell(xl.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 4))
      ..value = xl.DoubleCellValue(summary.totalExpenses)
      ..cellStyle = expenseStyle;

    summarySheet.cell(xl.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 5)).value = xl.TextCellValue('NET BALANCE');
    summarySheet.cell(xl.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 5))
      ..value = xl.DoubleCellValue(summary.netBalance)
      ..cellStyle = summary.netBalance >= 0 ? incomeStyle : expenseStyle;

    // --- Sheet 2: Transactions ---
    final txSheet = excel['Transactions'];
    
    final txHeaderStyle = xl.CellStyle(
      bold: true,
      backgroundColorHex: xl.ExcelColor.fromHexString('#1B5E20'),
      fontColorHex: xl.ExcelColor.fromHexString('#FFFFFF'),
    );

    final headers = ['Date', 'Title', 'Category', 'Type', 'Amount', 'Wallet', 'Description'];
    for (int i = 0; i < headers.length; i++) {
      txSheet.cell(xl.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
        ..value = xl.TextCellValue(headers[i])
        ..cellStyle = txHeaderStyle;
    }

    for (int i = 0; i < transactions.length; i++) {
      final tx = transactions[i];
      final wallet = tx.walletKey != null ? walletMap[tx.walletKey] : null;
      final rowIndex = i + 1;
      
      txSheet.cell(xl.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value = xl.TextCellValue(_dateFormat.format(tx.date));
      txSheet.cell(xl.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value = xl.TextCellValue(tx.title);
      txSheet.cell(xl.CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex)).value = xl.TextCellValue(tx.category);
      txSheet.cell(xl.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex)).value = xl.TextCellValue(tx.type.name);
      txSheet.cell(xl.CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex)).value = xl.DoubleCellValue(tx.amount);
      txSheet.cell(xl.CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex)).value = xl.TextCellValue(wallet?.name ?? '');
      txSheet.cell(xl.CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex)).value = xl.TextCellValue(tx.description);
      
      // Zebra striping
      if (rowIndex % 2 == 0) {
        final stripeStyle = xl.CellStyle(backgroundColorHex: xl.ExcelColor.fromHexString('#F8F9FA'));
        for (int col = 0; col < headers.length; col++) {
          txSheet.cell(xl.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIndex)).cellStyle = stripeStyle;
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
        final result = await Share.shareXFiles(
          [XFile(file.path, mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')],
          subject: fileName,
        );
        return result.status == ShareResultStatus.dismissed ? ExportStatus.cancelled : ExportStatus.success;
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
        final result = await Share.shareXFiles(
          [XFile(file.path, mimeType: 'text/csv')],
          subject: fileName,
        );
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
        final ok = await Printing.sharePdf(bytes: pdfBytes, filename: '$fileName.pdf');
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
