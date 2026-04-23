import 'package:flutter/material.dart';

class IconMapper {
  /// A centralized map of all available category icons as constants.
  /// This ensures that Flutter's icon tree-shaker can statically identify which icons are used,
  /// enabling optimized release builds.
  static const Map<int, IconData> _iconMap = {
    // General
    0xe041: Icons.account_balance_wallet,
    0xef63: Icons.payments,
    0xe59c: Icons.shopping_cart,
    0xef2a: Icons.receipt_long,
    0xe19f: Icons.credit_card,
    0xefc8: Icons.savings,
    0xe407: Icons.monetization_on,
    0xe65f: Icons.trending_up,
    0xe65e: Icons.trending_down,

    // Expenses
    0xe27a: Icons.fastfood,
    0xe532: Icons.restaurant,
    0xeb82: Icons.coffee,
    0xf37d: Icons.shopping_bag,
    0xe1d7: Icons.directions_car,
    0xe1d5: Icons.directions_bus,
    0xe295: Icons.flight,
    0xe318: Icons.home,
    0xe37a: Icons.lightbulb,
    0xe798: Icons.water_drop,
    0xe537: Icons.router,
    0xe4e2: Icons.phone_android,
    0xf1a1: Icons.medical_services,
    0xef12: Icons.health_and_safety,
    0xe559: Icons.school,
    0xe40f: Icons.movie,
    0xe6ab: Icons.videogame_asset,
    0xea3a: Icons.sports_soccer,
    0xeb43: Icons.fitness_center,
    0xe4a1: Icons.pets,
    0xe3ad: Icons.local_gas_station,
    0xe869: Icons.build,
    0xf0ff: Icons.cleaning_services,
    0xf008: Icons.dry_cleaning,
    0xe163: Icons.content_cut,
    0xe3ae: Icons.brush,
    0xe14f: Icons.card_giftcard,
    0xe8b1: Icons.redeem,

    // Income
    0xe8f4: Icons.work,
    0xe0af: Icons.business_center,
    0xe8d1: Icons.store,
    0xe0b2: Icons.attach_money,
    0xe23a: Icons.euro,
    0xef50: Icons.currency_bitcoin,
    0xe4a9: Icons.pie_chart,
    0xef80: Icons.auto_graph,

    // Others
    0xe5d3: Icons.more_horiz,
    0xe148: Icons.category,
    0xe8d0: Icons.star,
    0xe87d: Icons.favorite,
    0xe80b: Icons.public,
    0xe2bd: Icons.cloud,
    0xe32a: Icons.security,
    0xe369: Icons.key,
  };

  /// Retrieves the constant IconData for a given codePoint.
  /// Falls back to Icons.category if the code is not recognized.
  static IconData getIcon(int codePoint) {
    return _iconMap[codePoint] ?? Icons.category;
  }
}
