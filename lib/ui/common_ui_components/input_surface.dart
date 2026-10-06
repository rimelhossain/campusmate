import 'package:flutter/material.dart';

/// Adds a restrained lift under form controls while leaving their own
/// InputDecoration border and fill responsible for the visible field surface.
class InputSurface extends StatelessWidget {
  const InputSurface({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.24 : 0.075),
            blurRadius: isDark ? 8 : 7,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}
