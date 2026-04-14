

class CardSkin {
  final String id;
  final String name;
  final String description;
  final int price;

  const CardSkin({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
  });
}

class CardSkinService {
  static const List<CardSkin> premiumSkins = [
    CardSkin(
      id: 'skin_nature_vines',
      name: 'Nature\'s Touch',
      description: 'Elegant vines growing on the borders.',
      price: 150,
    ),
    CardSkin(
      id: 'skin_neon_pulse',
      name: 'Neon Pulse',
      description: 'Glowing dynamic colored borders.',
      price: 300,
    ),
    CardSkin(
      id: 'skin_royal_gold',
      name: 'Royal Gold',
      description: 'Ornate metallic gold borders and corners.',
      price: 450,
    ),
  ];

  static CardSkin? getSkinById(String? id) {
    if (id == null) return null;
    try {
      return premiumSkins.firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  }
}
