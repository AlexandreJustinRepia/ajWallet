import 'package:flutter/foundation.dart';

/// A singleton [ValueNotifier] that controls balance visibility across all views.
/// When [value] is `true`, balances are hidden (shown as ••••••).
class BalanceVisibilityService extends ValueNotifier<bool> {
  BalanceVisibilityService._() : super(false);

  static final BalanceVisibilityService instance = BalanceVisibilityService._();

  bool get isHidden => value;

  void toggle() => value = !value;

  void show() => value = false;

  void hide() => value = true;
}
