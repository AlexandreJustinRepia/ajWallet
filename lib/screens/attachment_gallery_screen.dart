import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../services/database_service.dart';
import '../services/month_dump_service.dart';
import '../widgets/image_gallery_viewer.dart';
import '../transaction_details_screen.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';

enum GalleryZoomLevel {
  days,
  months,
  years,
}

class AttachmentGalleryScreen extends StatefulWidget {
  const AttachmentGalleryScreen({super.key});

  @override
  State<AttachmentGalleryScreen> createState() => _AttachmentGalleryScreenState();
}

class _AttachmentGalleryScreenState extends State<AttachmentGalleryScreen> {
  GalleryZoomLevel _zoomLevel = GalleryZoomLevel.days;
  double _currentScale = 1.0;
  double _baseScale = 1.0;

  void _zoomOut() {
    setState(() {
      if (_zoomLevel == GalleryZoomLevel.days) {
        _zoomLevel = GalleryZoomLevel.months;
      } else if (_zoomLevel == GalleryZoomLevel.months) {
        _zoomLevel = GalleryZoomLevel.years;
      }
    });
  }

  void _zoomIn() {
    setState(() {
      if (_zoomLevel == GalleryZoomLevel.years) {
        _zoomLevel = GalleryZoomLevel.months;
      } else if (_zoomLevel == GalleryZoomLevel.months) {
        _zoomLevel = GalleryZoomLevel.days;
      }
    });
  }

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
      String dateKey;
      switch (_zoomLevel) {
        case GalleryZoomLevel.days:
          dateKey = DateFormat('yyyy-MM-dd').format(entry.transaction.date);
          break;
        case GalleryZoomLevel.months:
          dateKey = DateFormat('yyyy-MM').format(entry.transaction.date);
          break;
        case GalleryZoomLevel.years:
          dateKey = DateFormat('yyyy').format(entry.transaction.date);
          break;
      }

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
          PopupMenuButton<GalleryZoomLevel>(
            icon: const Icon(Icons.grid_view_rounded),
            tooltip: 'View mode',
            onSelected: (level) => setState(() => _zoomLevel = level),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: GalleryZoomLevel.days,
                child: Row(
                  children: [
                    Icon(Icons.view_module_rounded, color: _zoomLevel == GalleryZoomLevel.days ? theme.primaryColor : null),
                    const SizedBox(width: 12),
                    Text('Group by Days', style: TextStyle(color: _zoomLevel == GalleryZoomLevel.days ? theme.primaryColor : null)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: GalleryZoomLevel.months,
                child: Row(
                  children: [
                    Icon(Icons.calendar_month_rounded, color: _zoomLevel == GalleryZoomLevel.months ? theme.primaryColor : null),
                    const SizedBox(width: 12),
                    Text('Group by Months', style: TextStyle(color: _zoomLevel == GalleryZoomLevel.months ? theme.primaryColor : null)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: GalleryZoomLevel.years,
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, color: _zoomLevel == GalleryZoomLevel.years ? theme.primaryColor : null),
                    const SizedBox(width: 12),
                    Text('Group by Years', style: TextStyle(color: _zoomLevel == GalleryZoomLevel.years ? theme.primaryColor : null)),
                  ],
                ),
              ),
            ],
          ),
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
      body: GestureDetector(
        onScaleStart: (details) {
          _baseScale = _currentScale;
        },
        onScaleUpdate: (details) {
          _currentScale = _baseScale * details.scale;
        },
        onScaleEnd: (details) {
          if (_currentScale < 0.7) {
            _zoomOut();
          } else if (_currentScale > 1.3) {
            _zoomIn();
          }
          _currentScale = 1.0;
          _baseScale = 1.0;
        },
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          itemCount: sortedDates.length,
          itemBuilder: (context, dateIndex) {
            final dateKey = sortedDates[dateIndex];
            final entries = groupedByDate[dateKey]!;
            
            String headerTitle = '';
            String headerSubtitle = '';
            
            switch (_zoomLevel) {
              case GalleryZoomLevel.days:
                final date = DateFormat('MMMM dd, yyyy').format(entries.first.transaction.date);
                final dayName = DateFormat('EEEE').format(entries.first.transaction.date);
                headerTitle = dateKey == DateFormat('yyyy-MM-dd').format(DateTime.now()) ? 'Today' : date;
                headerSubtitle = '$dayName, ${entries.length} ${entries.length == 1 ? "item" : "items"}';
                break;
              case GalleryZoomLevel.months:
                final date = DateFormat('MMMM yyyy').format(entries.first.transaction.date);
                headerTitle = dateKey == DateFormat('yyyy-MM').format(DateTime.now()) ? 'This Month' : date;
                headerSubtitle = '${entries.length} ${entries.length == 1 ? "item" : "items"}';
                break;
              case GalleryZoomLevel.years:
                final date = DateFormat('yyyy').format(entries.first.transaction.date);
                headerTitle = dateKey == DateFormat('yyyy').format(DateTime.now()) ? 'This Year' : date;
                headerSubtitle = '${entries.length} ${entries.length == 1 ? "item" : "items"}';
                break;
            }

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
                          headerSubtitle,
                          style: TextStyle(
                            color: theme.primaryColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          headerTitle,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                      ),
                      if (_zoomLevel != GalleryZoomLevel.days)
                        IconButton(
                          icon: Icon(Icons.ios_share_rounded, color: theme.primaryColor),
                          tooltip: 'Export Dump',
                          onPressed: () => _showExportDialog(context, entries, headerTitle),
                        ),
                    ],
                  ),
                ),
                // Grid layout for attachments
                _buildGrid(entries, theme, context),
                const SizedBox(height: 20),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showExportDialog(BuildContext context, List<AttachmentEntry> entries, String title) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Export $title Dump',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Share your recent attachments to Instagram or Facebook Stories!',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.grid_on_rounded, color: Colors.blue),
                  ),
                  title: const Text('Picture Collage'),
                  subtitle: const Text('Creates a beautiful single image collage'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _exportDump(context, entries, title, isVideo: false);
                  },
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.purple.withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.gif_box_rounded, color: Colors.purple),
                  ),
                  title: const Text('Video Slideshow'),
                  subtitle: const Text('Generates an animated GIF slideshow'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _exportDump(context, entries, title, isVideo: true);
                  },
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.photo_library_rounded, color: Colors.orange),
                  ),
                  title: const Text('Multiple Images'),
                  subtitle: const Text('Share all pictures directly to Stories'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _exportMultiple(context, entries, title);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPreviewDialog(BuildContext context, String title, List<String> filePaths, bool isGif) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Preview: $title', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                if (filePaths.length == 1)
                  Flexible(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(File(filePaths.first), fit: BoxFit.contain),
                    ),
                  )
                else
                  Flexible(
                    child: SizedBox(
                      height: 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: filePaths.length,
                        itemBuilder: (c, i) => Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(File(filePaths[i]), height: 200, fit: BoxFit.cover),
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        final xFiles = filePaths.map((p) => XFile(p)).toList();
                        Share.shareXFiles(xFiles, text: '$title Dump from ajWallet');
                      },
                      icon: const Icon(Icons.share_rounded),
                      label: const Text('Share'),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _exportMultiple(BuildContext context, List<AttachmentEntry> entries, String title) async {
    final paths = entries.map((e) => e.imagePath).take(15).toList(); // IG allows max 10-15 usually
    if (paths.isEmpty) return;
    
    _showPreviewDialog(context, title, paths, false);
  }

  Future<void> _exportDump(BuildContext context, List<AttachmentEntry> entries, String title, {required bool isVideo}) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final paths = entries.map((e) => e.imagePath).toList();
      File file;
      if (isVideo) {
        file = await MonthDumpService.generateVideoSlideshow(paths, title);
      } else {
        file = await MonthDumpService.generatePictureCollage(paths, title);
      }
      
      if (context.mounted) {
        Navigator.pop(context); // close loading
        _showPreviewDialog(context, title, [file.path], isVideo);
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // close loading
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error generating export: $e')));
      }
    }
  }

  Widget _buildGrid(List<AttachmentEntry> entries, ThemeData theme, BuildContext context) {
    int crossAxisCount = 3;
    if (_zoomLevel == GalleryZoomLevel.months) crossAxisCount = 4;
    if (_zoomLevel == GalleryZoomLevel.years) crossAxisCount = 5;

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        return _AttachmentCard(
          entry: entries[index], 
          theme: theme, 
          context: context,
          zoomLevel: _zoomLevel,
        );
      },
    );
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
  final GalleryZoomLevel zoomLevel;

  const _AttachmentCard({
    required this.entry,
    required this.theme,
    required this.context,
    required this.zoomLevel,
  });

  @override
  Widget build(BuildContext context) {
    final file = File(entry.imagePath);
    final exists = file.existsSync();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
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
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.dividerColor, width: 0.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Image preview
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: exists
                    ? Image.file(
                        file,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(context),
                      )
                    : _buildPlaceholder(context),
              ),
              if (zoomLevel != GalleryZoomLevel.years) ...[
                // Gradient overlay for better text readability
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.8),
                        ],
                      ),
                    ),
                  ),
                ),
                // Transaction amount and icon
                Positioned(
                  bottom: 6,
                  left: 6,
                  right: 6,
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: entry.transaction.typeColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${entry.transaction.type == TransactionType.expense ? '-' : entry.transaction.type == TransactionType.income ? '+' : ''}₱${entry.transaction.amount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                // View transaction button (top right)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Material(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (ctx) => TransactionDetailsScreen(transaction: entry.transaction),
                          ),
                        );
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(6.0),
                        child: Icon(Icons.receipt_long_rounded, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      color: theme.dividerColor.withValues(alpha: 0.1),
      child: Center(
        child: Icon(Icons.broken_image_rounded, color: theme.dividerColor.withValues(alpha: 0.3), size: 24),
      ),
    );
  }
}
