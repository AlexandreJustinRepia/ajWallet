import 'package:flutter/material.dart';

class IconMapper {
  /// A centralized map of all available category icons as constants.
  /// This ensures that Flutter's icon tree-shaker can statically identify which icons are used,
  /// enabling optimized release builds.
  static final Map<int, IconData> _iconMap = {
    // General
    Icons.account_balance_wallet.codePoint: Icons.account_balance_wallet,
    Icons.payments.codePoint: Icons.payments,
    Icons.payments_rounded.codePoint: Icons.payments_rounded,
    Icons.shopping_cart.codePoint: Icons.shopping_cart,
    Icons.receipt_long.codePoint: Icons.receipt_long,
    Icons.credit_card.codePoint: Icons.credit_card,
    Icons.savings.codePoint: Icons.savings,
    Icons.monetization_on.codePoint: Icons.monetization_on,
    Icons.trending_up.codePoint: Icons.trending_up,
    Icons.trending_down.codePoint: Icons.trending_down,
    Icons.handshake_rounded.codePoint: Icons.handshake_rounded,

    // Expenses
    Icons.fastfood.codePoint: Icons.fastfood,
    Icons.restaurant.codePoint: Icons.restaurant,
    Icons.coffee.codePoint: Icons.coffee,
    Icons.shopping_bag.codePoint: Icons.shopping_bag,
    Icons.directions_car.codePoint: Icons.directions_car,
    Icons.directions_bus.codePoint: Icons.directions_bus,
    Icons.flight.codePoint: Icons.flight,
    Icons.home.codePoint: Icons.home,
    Icons.lightbulb.codePoint: Icons.lightbulb,
    Icons.water_drop.codePoint: Icons.water_drop,
    Icons.electric_bolt.codePoint: Icons.electric_bolt,
    Icons.wifi.codePoint: Icons.wifi,
    Icons.router.codePoint: Icons.router,
    Icons.phone_android.codePoint: Icons.phone_android,
    Icons.medical_services.codePoint: Icons.medical_services,
    Icons.health_and_safety.codePoint: Icons.health_and_safety,
    Icons.school.codePoint: Icons.school,
    Icons.movie.codePoint: Icons.movie,
    Icons.videogame_asset.codePoint: Icons.videogame_asset,
    Icons.sports_soccer.codePoint: Icons.sports_soccer,
    Icons.fitness_center.codePoint: Icons.fitness_center,
    Icons.pets.codePoint: Icons.pets,
    Icons.local_gas_station.codePoint: Icons.local_gas_station,
    Icons.build.codePoint: Icons.build,
    Icons.cleaning_services.codePoint: Icons.cleaning_services,
    Icons.dry_cleaning.codePoint: Icons.dry_cleaning,
    Icons.content_cut.codePoint: Icons.content_cut,
    Icons.brush.codePoint: Icons.brush,
    Icons.card_giftcard.codePoint: Icons.card_giftcard,
    Icons.redeem.codePoint: Icons.redeem,

    // Income
    Icons.work.codePoint: Icons.work,
    Icons.business_center.codePoint: Icons.business_center,
    Icons.store.codePoint: Icons.store,
    Icons.attach_money.codePoint: Icons.attach_money,
    Icons.euro.codePoint: Icons.euro,
    Icons.currency_bitcoin.codePoint: Icons.currency_bitcoin,
    Icons.pie_chart.codePoint: Icons.pie_chart,
    Icons.auto_graph.codePoint: Icons.auto_graph,

    // Others
    Icons.more_horiz.codePoint: Icons.more_horiz,
    Icons.category.codePoint: Icons.category,
    Icons.star.codePoint: Icons.star,
    Icons.favorite.codePoint: Icons.favorite,
    Icons.public.codePoint: Icons.public,
    Icons.cloud.codePoint: Icons.cloud,
    Icons.security.codePoint: Icons.security,
    Icons.key.codePoint: Icons.key,
    Icons.category_rounded.codePoint: Icons.category_rounded,
    Icons.subscriptions.codePoint: Icons.subscriptions,
    Icons.directions_run.codePoint: Icons.directions_run,
    Icons.local_shipping.codePoint: Icons.local_shipping,
    Icons.celebration.codePoint: Icons.celebration,
    Icons.child_care.codePoint: Icons.child_care,
    Icons.spa.codePoint: Icons.spa,
    Icons.car_repair.codePoint: Icons.car_repair,
    Icons.cottage.codePoint: Icons.cottage,
    Icons.volunteer_activism.codePoint: Icons.volunteer_activism,
  };

  /// Retrieves the constant IconData for a given codePoint.
  /// Falls back to Icons.category if the code is not recognized.
  static IconData getIcon(int codePoint) {
    return _iconMap[codePoint] ?? Icons.category;
  }
}
