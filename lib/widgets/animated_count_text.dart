import 'package:flutter/material.dart';

class AnimatedCountText extends StatefulWidget {
  final double value;
  final TextStyle? style;
  final Duration duration;
  final String prefix;
  final int decimalPlaces;

  const AnimatedCountText({
    super.key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 800),
    this.prefix = '',
    this.decimalPlaces = 2,
  });

  @override
  State<AnimatedCountText> createState() => _AnimatedCountTextState();
}

class _AnimatedCountTextState extends State<AnimatedCountText> {
  double _oldValue = 0;

  @override
  void initState() {
    super.initState();
    _oldValue = widget.value;
  }

  @override
  void didUpdateWidget(AnimatedCountText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _oldValue = oldWidget.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: _oldValue, end: widget.value),
      duration: widget.duration,
      curve: Curves.easeOutQuart,
      builder: (context, animatedValue, child) {
        String formattedVal;
        if (widget.decimalPlaces == 0) {
          formattedVal = animatedValue.round().toString();
        } else {
          formattedVal = animatedValue.toStringAsFixed(widget.decimalPlaces);
        }
        return Text(
          '${widget.prefix}$formattedVal',
          style: widget.style,
        );
      },
    );
  }
}
