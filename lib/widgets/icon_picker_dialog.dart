import 'package:flutter/material.dart';

class IconPickerDialog extends StatelessWidget {
  final IconData? selectedIcon;

  const IconPickerDialog({super.key, this.selectedIcon});

  static final List<IconData> financialIcons = [
    // General
    Icons.account_balance_wallet,
    Icons.payments,
    Icons.payments_rounded,
    Icons.shopping_cart,
    Icons.receipt_long,
    Icons.credit_card,
    Icons.savings,
    Icons.monetization_on,
    Icons.trending_up,
    Icons.trending_down,
    Icons.handshake_rounded,
    
    // Expenses
    Icons.fastfood,
    Icons.restaurant,
    Icons.coffee,
    Icons.shopping_bag,
    Icons.directions_car,
    Icons.directions_bus,
    Icons.flight,
    Icons.home,
    Icons.lightbulb,
    Icons.water_drop,
    Icons.electric_bolt,
    Icons.wifi,
    Icons.router,
    Icons.phone_android,
    Icons.medical_services,
    Icons.health_and_safety,
    Icons.school,
    Icons.movie,
    Icons.videogame_asset,
    Icons.sports_soccer,
    Icons.fitness_center,
    Icons.pets,
    Icons.local_gas_station,
    Icons.build,
    Icons.cleaning_services,
    Icons.dry_cleaning,
    Icons.content_cut,
    Icons.brush,
    Icons.card_giftcard,
    Icons.redeem,
    
    // Income
    Icons.work,
    Icons.business_center,
    Icons.store,
    Icons.attach_money,
    Icons.euro,
    Icons.currency_bitcoin,
    Icons.pie_chart,
    Icons.auto_graph,
    
    // Others
    Icons.more_horiz,
    Icons.category,
    Icons.star,
    Icons.favorite,
    Icons.public,
    Icons.cloud,
    Icons.security,
    Icons.key,
    Icons.category_rounded,
    Icons.subscriptions,
    Icons.directions_run,
    Icons.local_shipping,
    Icons.celebration,
    Icons.child_care,
    Icons.spa,
    Icons.car_repair,
    Icons.cottage,
    Icons.volunteer_activism,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      title: const Text('Pick an Icon'),
      content: SizedBox(
        width: double.maxFinite,
        child: GridView.builder(
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
          ),
          itemCount: financialIcons.length,
          itemBuilder: (context, index) {
            final icon = financialIcons[index];
            final isSelected = selectedIcon?.codePoint == icon.codePoint;
            
            return InkWell(
              onTap: () => Navigator.pop(context, icon),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? theme.primaryColor.withValues(alpha: 0.1) : null,
                  border: Border.all(
                    color: isSelected ? theme.primaryColor : Colors.grey.withValues(alpha: 0.3),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? theme.primaryColor : null,
                ),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
