import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../services/database_service.dart';
import '../widgets/image_gallery_viewer.dart';
import '../transaction_details_screen.dart';
import 'dart:io';

class AttachmentGalleryScreen extends StatelessWidget {
  const AttachmentGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final account = DatabaseService.getLatestAccount();
    
    if (account == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Attachment Gallery')),
        body: const Center(child: Text('No account found')),
      );
    }

    final transactions = DatabaseService.getTransactions(account.key as int)
        .where((tx) => tx.attachmentPaths != null && tx.attachmentPaths!.isNotEmpty)
        .toList();

    if (transactions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Attachment Gallery')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image_outlined, size: 80, color: theme.dividerColor.withValues(alpha: 0.3)),
              const SizedBox(height: 24),
              Text('No attachments found', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Text('Add receipts and photos to your transactions',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5))),
            ],
          ),
        ),
      );
    }

    // Build a flat list of all attachment entries with their transaction reference
    final List<AttachmentEntry> allAttachments = [];
    for (final tx in transactions) {
      for (int i = 0; i < tx.attachmentPaths!.length; i++) {
        allAttachments.add(AttachmentEntry(
          transaction: tx,
          imagePath: tx.attachmentPaths![i],
          attachmentIndex: i,
        ));
      }
    }

    // Sort by transaction date (newest first)
    allAttachments.sort((a, b) => b.transaction.date.compareTo(a.transaction.date));

    // Group by date for section headers
    final Map<String, List<AttachmentEntry>> groupedByDate = {};
    for (final entry in allAttachments) {
      final dateKey = DateFormat('yyyy-MM-dd').format(entry.transaction.date);
      if (!groupedByDate.containsKey(dateKey)) {
        groupedByDate[dateKey] = [];
      }
      groupedByDate[dateKey]!.add(entry);
    }

    final sortedDates = groupedByDate.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attachment Gallery'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Badge(
                label: Text('${allAttachments.length}'),
                largeSize: 20,
                child: const Icon(Icons.photo_library_rounded),
              ),
            ),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        itemCount: sortedDates.length,
        itemBuilder: (context, dateIndex) {
          final dateKey = sortedDates[dateIndex];
          final entries = groupedByDate[dateKey]!;
          final date = DateFormat('MMMM dd, yyyy').format(entries.first.transaction.date);
          final dayName = DateFormat('EEEE').format(entries.first.transaction.date);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$dayName, ${entries.length} ${entries.length == 1 ? "item" : "items"}',
                        style: TextStyle(
                          color: theme.primaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      dateKey == DateFormat('yyyy-MM-dd').format(DateTime.now()) ? 'Today' : date,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                  ],
                ),
              ),
              // Staggered grid: 2 columns with varying heights based on aspect ratio
              ..._buildStaggeredGrid(entries, theme, context),
              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildStaggeredGrid(List<AttachmentEntry> entries, ThemeData theme, BuildContext context) {
    final List<Widget> widgets = [];
    for (int i = 0; i < entries.length; i++) {
      widgets.add(_AttachmentCard(entry: entries[i], theme: theme, context: context));
    }
    return widgets;
  }
}

class AttachmentEntry {
  final Transaction transaction;
  final String imagePath;
  final int attachmentIndex;

  AttachmentEntry({
    required this.transaction,
    required this.imagePath,
    required this.attachmentIndex,
  });
}

class _AttachmentCard extends StatelessWidget {
  final AttachmentEntry entry;
  final ThemeData theme;
  final BuildContext context;

  const _AttachmentCard({
    required this.entry,
    required this.theme,
    required this.context,
  });

  @override
  Widget build(BuildContext context) {
    final file = File(entry.imagePath);
    final exists = file.existsSync();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            // Show the gallery starting from this attachment
            final account = DatabaseService.getLatestAccount();
            if (account == null) return;

            final transactions = DatabaseService.getTransactions(account.key as int)
                .where((tx) => tx.attachmentPaths != null && tx.attachmentPaths!.isNotEmpty)
                .toList();

            final List<String> allPaths = [];
            for (final tx in transactions) {
              allPaths.addAll(tx.attachmentPaths!);
            }

            final currentIndex = allPaths.indexOf(entry.imagePath);
            if (currentIndex >= 0) {
              ImageGalleryViewer.show(context, allPaths, currentIndex);
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.dividerColor, width: 0.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image preview
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: AspectRatio(
                    aspectRatio: 4 / 3,
                    child: exists
                        ? Image.file(
                            file,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => _buildPlaceholder(context),
                          )
                        : _buildPlaceholder(context),
                  ),
                ),
                // Transaction info header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Transaction title and type badge
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              entry.transaction.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: entry.transaction.typeColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              entry.transaction.type.name[0].toUpperCase() +
                                  entry.transaction.type.name.substring(1),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: entry.transaction.typeColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Amount and category
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: theme.dividerColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(Icons.category_rounded, size: 14, color: theme.primaryColor.withValues(alpha: 0.7)),
                                const SizedBox(width: 4),
                                Text(
                                  entry.transaction.category,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${entry.transaction.type == TransactionType.expense ? '-' : entry.transaction.type == TransactionType.income ? '+' : ''}₱${entry.transaction.amount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: entry.transaction.typeColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Date and description
                      Row(
                        children: [
                          Icon(Icons.calendar_today_rounded, size: 14, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.4)),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('MMM dd, yyyy').format(entry.transaction.date),
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.access_time_rounded, size: 14, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.4)),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('hh:mm a').format(entry.transaction.date),
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                      if (entry.transaction.description.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            entry.transaction.description,
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      const SizedBox(height: 8),
                      // View transaction button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.receipt_rounded, size: 16),
                          label: const Text('View Transaction'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: theme.primaryColor,
                            side: BorderSide(color: theme.primaryColor.withValues(alpha: 0.3)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (ctx) => TransactionDetailsScreen(transaction: entry.transaction),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      color: theme.dividerColor.withValues(alpha: 0.1),
      child: Center(
        child: Icon(Icons.broken_image_rounded, color: theme.dividerColor.withValues(alpha: 0.3), size: 40),
      ),
    );
  }
}
