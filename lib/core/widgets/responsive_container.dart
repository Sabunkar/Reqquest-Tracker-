import 'package:flutter/material.dart';

/// A reusable layout container that centers its child and enforces a maximum
/// width on wide displays (tablets, desktops, large monitors).
///
/// On mobile screens smaller than [maxWidth], the child expands to fill the
/// available width with optional [padding].
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth = 960,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
