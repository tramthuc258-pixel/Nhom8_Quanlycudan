import 'package:flutter/material.dart';

import 'responsive_layout.dart';

class AdaptiveDestination {
  const AdaptiveDestination({
    required this.label,
    required this.icon,
    this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData? selectedIcon;
}

/// Khung điều hướng dùng bottom navigation trên mobile và navigation rail trên
/// màn hình lớn.
class AdaptiveScaffold extends StatelessWidget {
  const AdaptiveScaffold({
    required this.body,
    this.destinations = const [],
    this.selectedIndex = 0,
    this.onDestinationSelected,
    this.title,
    this.leading,
    this.actions,
    this.floatingActionButton,
    this.drawer,
    this.extendedRailBreakpoint = 1200,
    super.key,
  }) : assert(
         destinations.length == 0 ||
             (selectedIndex >= 0 && selectedIndex < destinations.length),
         'selectedIndex phải nằm trong danh sách destinations.',
       );

  final Widget body;
  final List<AdaptiveDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int>? onDestinationSelected;
  final Widget? title;
  final Widget? leading;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Widget? drawer;
  final double extendedRailBreakpoint;

  @override
  Widget build(BuildContext context) {
    final hasNavigation = destinations.isNotEmpty;

    return ResponsiveBuilder(
      builder: (context, constraints, sizeClass) {
        final isCompact = sizeClass == WindowSizeClass.compact;
        final appBar = title == null && leading == null && actions == null
            ? null
            : AppBar(title: title, leading: leading, actions: actions);

        if (isCompact) {
          return Scaffold(
            appBar: appBar,
            drawer: drawer,
            body: body,
            floatingActionButton: floatingActionButton,
            bottomNavigationBar: hasNavigation
                ? SafeArea(
                    top: false,
                    child: NavigationBar(
                      selectedIndex: selectedIndex,
                      onDestinationSelected: onDestinationSelected,
                      destinations: [
                        for (final destination in destinations)
                          NavigationDestination(
                            icon: Icon(destination.icon),
                            selectedIcon: Icon(
                              destination.selectedIcon ?? destination.icon,
                            ),
                            label: destination.label,
                          ),
                      ],
                    ),
                  )
                : null,
          );
        }

        final useExtendedRail = constraints.maxWidth >= extendedRailBreakpoint;
        return Scaffold(
          appBar: appBar,
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (hasNavigation)
                SafeArea(
                  child: NavigationRail(
                    extended: useExtendedRail,
                    minExtendedWidth: 224,
                    selectedIndex: selectedIndex,
                    onDestinationSelected: onDestinationSelected,
                    labelType: useExtendedRail
                        ? NavigationRailLabelType.none
                        : NavigationRailLabelType.all,
                    groupAlignment: -0.85,
                    destinations: [
                      for (final destination in destinations)
                        NavigationRailDestination(
                          icon: Icon(destination.icon),
                          selectedIcon: Icon(
                            destination.selectedIcon ?? destination.icon,
                          ),
                          label: Text(destination.label),
                        ),
                    ],
                  ),
                ),
              if (hasNavigation) const VerticalDivider(width: 1),
              Expanded(child: body),
            ],
          ),
          floatingActionButton: floatingActionButton,
        );
      },
    );
  }
}
