import 'package:flutter/material.dart';
import '../../../services/update_service.dart';

class DashboardUpdateBanner extends StatelessWidget {
  const DashboardUpdateBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ValueListenableBuilder<UpdateInfo?>(
      valueListenable: UpdateService.updateNotifier,
      builder: (context, info, _) {
        if (info == null) return const SizedBox.shrink();

        final backgroundColor = theme.colorScheme.primary;
        final foregroundColor = theme.colorScheme.onPrimary;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: backgroundColor,
            boxShadow: [
              BoxShadow(
                color: backgroundColor.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                Icons.system_update_rounded,
                color: foregroundColor,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Update Available (${info.latestVersion})',
                      style: TextStyle(
                        color: foregroundColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      info.releaseNotes,
                      style: TextStyle(
                        color: foregroundColor.withValues(alpha: 0.8),
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => UpdateService.launchDownload(),
                style: TextButton.styleFrom(
                  backgroundColor: foregroundColor.withValues(alpha: 0.15),
                  foregroundColor: foregroundColor,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'UPDATE',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  color: foregroundColor.withValues(alpha: 0.7),
                  size: 18,
                ),
                onPressed: () => UpdateService.updateNotifier.value = null,
              ),
            ],
          ),
        );
      },
    );
  }
}
