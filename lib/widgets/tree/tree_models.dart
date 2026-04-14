import 'package:flutter/material.dart';

class BranchData {
  final Offset start;
  final Offset end;
  final double thickness;
  final int depth;

  BranchData({
    required this.start,
    required this.end,
    required this.thickness,
    required this.depth,
  });
}

class LeafData {
  final Offset position;
  final double size;

  LeafData({
    required this.position,
    required this.size,
  });
}

class TreeState {
  final List<BranchData> branches;
  final List<LeafData> leaves;
  final double growth;
  final double health;

  TreeState({
    required this.branches,
    required this.leaves,
    required this.growth,
    required this.health,
  });
}
