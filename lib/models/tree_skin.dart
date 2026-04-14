import 'package:flutter/material.dart';

enum LeafShape { circle, petal, crystal, techSquare }

class TreeSkin {
  final String id;
  final String name;
  final String description;
  final int price;
  final TreeSkinConfig config;

  const TreeSkin({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.config,
  });
}

class TreeSkinConfig {
  final Color trunkColor;
  final Color leafColor;
  final Color? particleColor;
  final LeafShape leafShape;
  final bool isTechMode;
  final Color? glowColor;
  final String? assetPath;

  const TreeSkinConfig({
    required this.trunkColor,
    required this.leafColor,
    this.particleColor,
    this.leafShape = LeafShape.circle,
    this.isTechMode = false,
    this.glowColor,
    this.assetPath,
  });
}
