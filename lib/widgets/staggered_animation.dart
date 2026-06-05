import 'package:flutter/material.dart';

/// A wrapper to animate list items with a staggered slide and fade effect
class StaggeredAnimation extends StatelessWidget {
  final int index;
  final Widget child;
  final Duration duration;
  final double offset;

  const StaggeredAnimation({
    super.key,
    required this.index,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
    this.offset = 50.0,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration,
      curve: Interval(
        (index * 0.1).clamp(0.0, 0.5), // Stagger delay based on index
        1.0,
        curve: Curves.easeOutCubic,
      ),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, offset * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
