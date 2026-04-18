import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';

class WidgetSyncService {
  static const String _androidWidgetName = 'BalanceWidget';

  static Future<void> sync({
    required double balance,
    required String accountName,
  }) async {
    try {
      final currencyFormatter = NumberFormat.currency(
        symbol: '₱',
        decimalDigits: 2,
      );
      
      final formattedBalance = currencyFormatter.format(balance);
      final updateTime = DateFormat('h:mm a').format(DateTime.now());

      // Save data for the widget to read
      await HomeWidget.saveWidgetData<String>('total_balance', formattedBalance);
      await HomeWidget.saveWidgetData<String>('account_name', accountName);
      await HomeWidget.saveWidgetData<String>('last_update', 'Updated $updateTime');

      // Trigger native widget refresh
      await HomeWidget.updateWidget(
        name: _androidWidgetName,
      );
    } catch (_) {
      // Fail silently for now
    }
  }
}
