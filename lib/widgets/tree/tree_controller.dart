import 'dart:math';
import 'package:flutter/material.dart';
import 'tree_models.dart';

class TreeController extends ChangeNotifier {
  final TickerProvider vsync;
  
  double _rawBalance = 0;
  double _currentGrowth = 0;
  double _currentHealth = 0;
  
  late AnimationController _growthController;
  late AnimationController _healthController;
  
  TreeState? _cachedState;
  
  TreeController({required this.vsync, required double initialBalance}) {
    _rawBalance = initialBalance;
    _currentGrowth = _calculateGrowth(initialBalance);
    _currentHealth = _calculateHealth(initialBalance);

    _growthController = AnimationController(
      vsync: vsync,
      duration: const Duration(seconds: 2),
      value: _currentGrowth / 4.0,
    )..addListener(_onAnimationTick);

    _healthController = AnimationController(
      vsync: vsync,
      duration: const Duration(seconds: 1),
      value: _currentHealth,
    )..addListener(_onAnimationTick);

    _recalculateStructure();
  }

  TreeState get state => _cachedState!;
  double get totalGrowth => _growthController.value * 4.0;
  double get health => _healthController.value;

  void updateBalance(double balance) {
    if (_rawBalance == balance) return;
    _rawBalance = balance;
    
    final targetGrowth = _calculateGrowth(balance);
    final targetHealth = _calculateHealth(balance);
    
    _growthController.animateTo(targetGrowth / 4.0, curve: Curves.easeInOutCubic);
    _healthController.animateTo(targetHealth, curve: Curves.easeInOutCubic);
  }

  void _onAnimationTick() {
    _recalculateStructure();
    notifyListeners();
  }

  double _calculateGrowth(double balance) {
    if (balance <= 0) return 0.0;
    if (balance <= 1000) return (balance / 1000); // 0.0 -> 1.0
    if (balance <= 10000) return 1.0 + ((balance - 1000) / 9000); // 1.0 -> 2.0
    if (balance <= 50000) return 2.0 + ((balance - 10000) / 40000); // 2.0 -> 3.0
    return min(4.0, 3.0 + ((balance - 50000) / 150000)); // 3.0 -> 4.0
  }

  double _calculateHealth(double balance) {
    if (balance <= 0) return 0.0;
    if (balance < 500) return 0.3 + (balance / 500) * 0.4;
    return min(1.0, 0.7 + (balance / 5000) * 0.3);
  }

  void _recalculateStructure() {
    // We only recalculate the structure if the growth value has changed significantly
    // to avoid heavy recursion on every micro-frame.
    final growth = _growthController.value * 4.0;
    final health = _healthController.value;
    
    final List<BranchData> branches = [];
    final List<LeafData> leaves = [];
    
    final startPoint = const Offset(0, 0); // Origin for the painter
    
    _generateBranches(
      branches: branches,
      leaves: leaves,
      start: startPoint,
      angle: -pi / 2,
      length: 20.0 + (growth * 16.0),
      thickness: 5.0 + (growth * 5.0),
      depth: (2 + (growth * 1.5).floor()).clamp(1, 5),
      growth: growth,
      health: health,
    );
    
    _cachedState = TreeState(
      branches: branches,
      leaves: leaves,
      growth: growth,
      health: health,
    );
  }

  void _generateBranches({
    required List<BranchData> branches,
    required List<LeafData> leaves,
    required Offset start,
    required double angle,
    required double length,
    required double thickness,
    required int depth,
    required double growth,
    required double health,
  }) {
    final end = Offset(
      start.dx + cos(angle) * length,
      start.dy + sin(angle) * length,
    );

    branches.add(BranchData(start: start, end: end, thickness: thickness, depth: depth));

    if (depth > 0) {
      final branchDecay = 0.72 + (growth * 0.02);
      final newLength = length * branchDecay;
      final newThickness = thickness * 0.65;
      
      _generateBranches(
        branches: branches,
        leaves: leaves,
        start: end,
        angle: angle + 0.5 - (depth * 0.05),
        length: newLength,
        thickness: newThickness,
        depth: depth - 1,
        growth: growth,
        health: health,
      );
      
      _generateBranches(
        branches: branches,
        leaves: leaves,
        start: end,
        angle: angle - 0.4 + (depth * 0.05),
        length: newLength,
        thickness: newThickness,
        depth: depth - 1,
        growth: growth,
        health: health,
      );

      if (growth > 2.5 && depth > 2 && depth % 2 == 0) {
         _generateBranches(
          branches: branches,
          leaves: leaves,
          start: end,
          angle: angle + 0.1,
          length: newLength * 0.6,
          thickness: newThickness * 0.8,
          depth: depth - 2,
          growth: growth,
          health: health,
        );
      }
    } else {
      _generateLeafCluster(leaves, end, growth, health);
    }
  }

  void _generateLeafCluster(List<LeafData> leaves, Offset position, double growth, double health) {
    if (health <= 0.05) return;
    final baseCount = (health * 6 + growth).floor().clamp(1, 10);
    final random = Random(position.dx.toInt() ^ position.dy.toInt());

    for (int i = 0; i < baseCount; i++) {
        final offsetX = (random.nextDouble() - 0.5) * (22 + growth * 3);
        final offsetY = (random.nextDouble() - 0.5) * (22 + growth * 3);
        final leafSize = 4.0 + random.nextDouble() * (6.0 + growth);
        leaves.add(LeafData(
          position: Offset(position.dx + offsetX, position.dy + offsetY),
          size: leafSize,
        ));
    }
  }

  @override
  void dispose() {
    _growthController.dispose();
    _healthController.dispose();
    super.dispose();
  }
}
