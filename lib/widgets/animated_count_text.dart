import 'package:flutter/material.dart';

class AnimatedCountText extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value),
      duration: duration,
      curve: Curves.easeOutQuart,
      builder: (context, animatedValue, child) {
        return Text(
          '$prefix${animatedValue.toStringAsFixed(decimalPlaces)}',
          style: style,
        );
      },
    );
  }
}
