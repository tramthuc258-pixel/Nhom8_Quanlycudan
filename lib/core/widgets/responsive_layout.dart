import 'package:flutter/material.dart';

enum WindowSizeClass { compact, medium, expanded }

/// Chọn bố cục phù hợp theo chiều rộng khả dụng thay vì theo loại thiết bị.
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    required this.compact,
    this.medium,
    this.expanded,
    this.compactBreakpoint = 600,
    this.expandedBreakpoint = 1024,
    super.key,
  }) : assert(compactBreakpoint < expandedBreakpoint);

  final Widget compact;
  final Widget? medium;
  final Widget? expanded;
  final double compactBreakpoint;
  final double expandedBreakpoint;

  static WindowSizeClass sizeClassOf(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 600) return WindowSizeClass.compact;
    if (width < 1024) return WindowSizeClass.medium;
    return WindowSizeClass.expanded;
  }

  static bool isCompact(BuildContext context) =>
      sizeClassOf(context) == WindowSizeClass.compact;

  static bool isExpanded(BuildContext context) =>
      sizeClassOf(context) == WindowSizeClass.expanded;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;

        if (width >= expandedBreakpoint) {
          return expanded ?? medium ?? compact;
        }
        if (width >= compactBreakpoint) {
          return medium ?? expanded ?? compact;
        }
        return compact;
      },
    );
  }
}

/// Biến thể builder khi bố cục cần dùng trực tiếp kích thước hiện tại.
class ResponsiveBuilder extends StatelessWidget {
  const ResponsiveBuilder({required this.builder, super.key});

  final Widget Function(
    BuildContext context,
    BoxConstraints constraints,
    WindowSizeClass sizeClass,
  )
  builder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final sizeClass = width < 600
            ? WindowSizeClass.compact
            : width < 1024
            ? WindowSizeClass.medium
            : WindowSizeClass.expanded;
        return builder(context, constraints, sizeClass);
      },
    );
  }
}
