import 'dart:math';
import 'package:flutter/material.dart';
import 'tree/tree_controller.dart';
import 'tree/tree_layers.dart';

class AnimatedTree extends StatefulWidget {
  final double balance;

  const AnimatedTree({super.key, required this.balance});

  @override
  State<AnimatedTree> createState() => _AnimatedTreeState();
}

class _AnimatedTreeState extends State<AnimatedTree> with TickerProviderStateMixin {
  late TreeController _controller;
  late AnimationController _swayController;
  late AnimationController _pulseController;
  late AnimationController _incomeEffectController;
  late AnimationController _expenseEffectController;

  late Animation<double> _pulseAnimation;
  bool _isIncomePulse = true;

  @override
  void initState() {
    super.initState();
    
    _controller = TreeController(vsync: this, initialBalance: widget.balance);

    _swayController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _pulseAnimation = ConstantTween<double>(1.0).animate(_pulseController);

    _incomeEffectController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _expenseEffectController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void didUpdateWidget(AnimatedTree oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.balance != oldWidget.balance) {
      _controller.updateBalance(widget.balance);

      if (widget.balance > oldWidget.balance) {
        _isIncomePulse = true;
        _pulseAnimation = TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.08).chain(CurveTween(curve: Curves.easeOut)), weight: 40),
          TweenSequenceItem(tween: Tween(begin: 1.08, end: 1.0).chain(CurveTween(curve: Curves.bounceOut)), weight: 60),
        ]).animate(_pulseController);
        _incomeEffectController.forward(from: 0.0);
      } else {
        _isIncomePulse = false;
        _pulseAnimation = TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.95).chain(CurveTween(curve: Curves.easeOut)), weight: 30),
          TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.0).chain(CurveTween(curve: Curves.elasticOut)), weight: 70),
        ]).animate(_pulseController);
        _expenseEffectController.forward(from: 0.0);
      }
      _pulseController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _swayController.dispose();
    _pulseController.dispose();
    _incomeEffectController.dispose();
    _expenseEffectController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return RepaintBoundary(
      child: Container(
        height: 280,
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 24),
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _controller,
            _swayController,
            _pulseController,
            _incomeEffectController,
            _expenseEffectController
          ]),
          builder: (context, child) {
            final state = _controller.state;
            final scaleEffect = _pulseAnimation.value;
            final vibrancyPulse = _isIncomePulse ? (_pulseAnimation.value - 1.0) * 5 : 0.0;
            
            // Dynamic colors
            final trunkColor = Color.lerp(
              isDark ? const Color(0xFF3E2723) : const Color(0xFF5D4037),
              isDark ? const Color(0xFF8D6E63) : const Color(0xFF795548),
              state.health,
            )!;

            Color leafColor = Color.lerp(
              isDark ? const Color(0xFF6D4C41) : const Color(0xFF8D6E63),
              isDark ? const Color(0xFF43A047) : const Color(0xFF2E7D32),
              state.health,
            )!;

            if (vibrancyPulse > 0) {
              leafColor = Color.lerp(leafColor, Colors.greenAccent, vibrancyPulse.clamp(0.0, 0.4))!;
            }

            return Stack(
              alignment: Alignment.bottomCenter,
              children: [
                // 1. Majestic Glow Layer (Static/Smooth)
                if (state.growth > 3.0)
                  RepaintBoundary(
                    child: _buildGlow(state.growth, isDark),
                  ),

                // 2. Main Tree Structure (Static branches, transform sway)
                Transform.scale(
                  scale: scaleEffect,
                  alignment: Alignment.bottomCenter,
                  child: Transform.rotate(
                    angle: sin(_swayController.value * pi * 2) * 0.01, // Slight base sway
                    alignment: Alignment.bottomCenter,
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        // Trunk & Branches (Cached)
                        RepaintBoundary(
                          child: CustomPaint(
                            painter: TreeStructurePainter(
                              branches: state.branches,
                              trunkColor: trunkColor,
                              health: state.health,
                              growth: state.growth,
                            ),
                            size: Size.infinite,
                          ),
                        ),
                        
                        // Foliage (Batched & Cached)
                        RepaintBoundary(
                          child: Transform.rotate(
                            angle: sin(_swayController.value * pi * 2 + 1.0) * 0.02, // Canopy sways more
                            alignment: Alignment.bottomCenter,
                            child: CustomPaint(
                              painter: LeafPainter(
                                leaves: state.leaves,
                                leafColor: leafColor,
                                growth: state.growth,
                              ),
                              size: Size.infinite,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 3. Effect Particles (Frequent repaints, isolated)
                Positioned.fill(
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: ParticlePainter(
                        incomeProgress: _incomeEffectController.value,
                        expenseProgress: _expenseEffectController.value,
                        leafColor: leafColor,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildGlow(double growth, bool isDark) {
    final glowProgress = (growth - 3.0).clamp(0.0, 1.0);
    return Container(
      width: 150 + growth * 20,
      height: 150 + growth * 20,
      margin: EdgeInsets.only(bottom: 60 + growth * 10),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.greenAccent : Colors.lightGreenAccent)
                .withValues(alpha: 0.1 * glowProgress),
            blurRadius: 40,
            spreadRadius: 10,
          ),
        ],
      ),
    );
  }
}
