import 'package:flutter/material.dart';
import 'animated_count_text.dart';

class GamificationCounter extends StatefulWidget {
  final int value;
  final String unit;
  final TextStyle? style;
  final IconData? icon;
  final Color? color;
  final String? prefix;

  const GamificationCounter({
    super.key,
    required this.value,
    this.unit = '',
    this.style,
    this.icon,
    this.color,
    this.prefix,
  });

  @override
  State<GamificationCounter> createState() => _GamificationCounterState();
}

class _GamificationCounterState extends State<GamificationCounter> with SingleTickerProviderStateMixin {
  int _lastValue = 0;
  int _delta = 0;
  bool _showDelta = false;
  late AnimationController _deltaController;
  late Animation<double> _deltaOpacity;
  late Animation<Offset> _deltaPosition;

  @override
  void initState() {
    super.initState();
    _lastValue = widget.value;
    _deltaController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _deltaOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 40),
    ]).animate(_deltaController);

    _deltaPosition = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(0, -1.5),
    ).animate(CurvedAnimation(parent: _deltaController, curve: Curves.easeOut));

    _deltaController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) {
          setState(() {
            _showDelta = false;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _deltaController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(GamificationCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _delta = widget.value - oldWidget.value;
      if (_delta != 0) {
        _showDelta = true;
        _deltaController.forward(from: 0);
      }
      _lastValue = widget.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final indicatorColor = _delta > 0 ? Colors.green : Colors.red;
    final deltaText = _delta > 0 ? '+$_delta' : '$_delta';

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.centerLeft,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (widget.icon != null) ...[
              Icon(widget.icon, color: widget.color ?? Colors.amber, size: widget.style?.fontSize ?? 14),
              const SizedBox(width: 4),
            ],
            AnimatedCountText(
              value: widget.value.toDouble(),
              decimalPlaces: 0,
              prefix: widget.prefix ?? '',
              style: widget.style ?? const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (widget.unit.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(widget.unit, style: widget.style?.copyWith(fontSize: (widget.style?.fontSize ?? 12) * 0.8)),
            ],
          ],
        ),
        if (_showDelta)
          Positioned(
            right: -30,
            top: -10,
            child: SlideTransition(
              position: _deltaPosition,
              child: FadeTransition(
                opacity: _deltaOpacity,
                child: Text(
                  deltaText,
                  style: TextStyle(
                    color: indicatorColor,
                    fontWeight: FontWeight.w900,
                    fontSize: (widget.style?.fontSize ?? 14) * 0.9,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha:0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
