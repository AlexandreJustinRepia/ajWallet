import 'package:flutter/material.dart';
import '../models/tree_skin.dart';

class TreeSkinService {
  static const String springId = 'spring';
  static const String sakuraId = 'sakura';
  static const String autumnId = 'autumn';
  static const String winterId = 'winter';
  static const String wealthOakId = 'wealth_oak';
  static const String goldenMoneyId = 'golden_money';
  static const String techId = 'tech';

  static final List<TreeSkin> allSkins = [
    const TreeSkin(
      id: springId,
      name: 'Spring Growth',
      description: 'The default symbol of fresh beginnings and steady progress.',
      price: 0,
      config: TreeSkinConfig(
        trunkColor: Color(0xFF5D4037),
        leafColor: Color(0xFF2E7D32),
        particleColor: Colors.lightGreenAccent,
        leafShape: LeafShape.circle,
        glowColor: Colors.lightGreenAccent,
        assetPath: 'assets/images/trees/spring.png',
      ),
    ),
    const TreeSkin(
      id: sakuraId,
      name: 'Cherry Blossom',
      description: 'A magical Japanese sakura theme with falling pink petals.',
      price: 500,
      config: TreeSkinConfig(
        trunkColor: Color(0xFF795548),
        leafColor: Color(0xFFF48FB1),
        particleColor: Color(0xFFFFC1E3),
        leafShape: LeafShape.petal,
        glowColor: Color(0xFFFFC1E3),
        assetPath: 'assets/images/trees/sakura.png',
      ),
    ),
    const TreeSkin(
      id: autumnId,
      name: 'Autumn Gold',
      description: 'Warm golden orange leaves representing stability and maturity.',
      price: 500,
      config: TreeSkinConfig(
        trunkColor: Color(0xFF4E342E),
        leafColor: Color(0xFFE64A19),
        particleColor: Color(0xFFFFB300),
        leafShape: LeafShape.petal,
        glowColor: Color(0xFFFFB300),
        assetPath: 'assets/images/trees/autumn.png',
      ),
    ),
    const TreeSkin(
      id: winterId,
      name: 'Winter Frost',
      description: 'Icy blue tones representing discipline and financial control.',
      price: 1000,
      config: TreeSkinConfig(
        trunkColor: Color(0xFF37474F),
        leafColor: Color(0xFF81D4FA),
        particleColor: Colors.white,
        leafShape: LeafShape.crystal,
        glowColor: Colors.white,
        assetPath: 'assets/images/trees/winter.png',
      ),
    ),
    const TreeSkin(
      id: wealthOakId,
      name: 'Wealth Oak',
      description: 'A majestic ancient tree with glowing golden veins.',
      price: 2000,
      config: TreeSkinConfig(
        trunkColor: Color(0xFF3E2723),
        leafColor: Color(0xFF1B5E20),
        particleColor: Color(0xFFFFD54F),
        leafShape: LeafShape.circle,
        glowColor: Color(0xFFFFD54F),
        assetPath: 'assets/images/trees/wealth_oak.png',
      ),
    ),
    const TreeSkin(
      id: goldenMoneyId,
      name: 'Golden Money',
      description: 'Ultimate abundance with shimmering gold coin leaves.',
      price: 5000,
      config: TreeSkinConfig(
        trunkColor: Color(0xFFB8860B),
        leafColor: Color(0xFFFFD700),
        particleColor: Color(0xFFFFEB3B),
        leafShape: LeafShape.crystal,
        glowColor: Color(0xFFFFD700),
      ),
    ),
    const TreeSkin(
      id: techId,
      name: 'Tech Tree',
      description: 'Futuristic digital growth with neon circuit lines.',
      price: 5000,
      config: TreeSkinConfig(
        trunkColor: Color(0xFF1A237E),
        leafColor: Color(0xFF00B0FF),
        particleColor: Color(0xFFB2FF59),
        leafShape: LeafShape.techSquare,
        isTechMode: true,
        glowColor: Color(0xFF00B0FF),
      ),
    ),
  ];

  static TreeSkin getSkin(String id) {
    return allSkins.firstWhere((s) => s.id == id, orElse: () => allSkins.first);
  }
}
