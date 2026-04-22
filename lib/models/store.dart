class Store {
  final String name;
  final String logoPath;

  const Store({required this.name, required this.logoPath});

  static const List<Store> convenienceStores = [
    Store(name: '7-Eleven', logoPath: 'assets/images/stores/7-eleven-logo.png'),
    Store(name: 'Alfamart', logoPath: 'assets/images/stores/alfamart-logo.png'),
    Store(name: 'Dali', logoPath: 'assets/images/stores/dali-logo.webp'),
    Store(name: 'OSave', logoPath: 'assets/images/stores/osave-logo.png'),
    Store(name: 'Puregold', logoPath: 'assets/images/stores/puregold-logo.webp'),
    Store(name: 'Super8', logoPath: 'assets/images/stores/Super8-logo.jpg'),
    Store(name: 'S&R', logoPath: 'assets/images/stores/snr-logo.png'),
  ];

  static String? getLogoForStore(String? storeName) {
    if (storeName == null) return null;
    try {
      return convenienceStores
          .firstWhere((s) => s.name.toLowerCase() == storeName.toLowerCase())
          .logoPath;
    } catch (_) {
      return null;
    }
  }
}
