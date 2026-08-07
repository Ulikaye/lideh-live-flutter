import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/strings.dart';
import '../../core/utils/responsive.dart';
import 'app_icon_asset.dart';

/// The top-level shell rendered around every primary route.
///
/// - Mobile: a Material 3 [NavigationBar] pinned to the bottom.
/// - Tablet/Desktop/Web: a [NavigationRail] docked to the side, plus a
///   wider top app bar — this is the key adaptation that keeps the web
///   build from looking like a stretched phone app.
class AppScaffold extends StatelessWidget {
  final Widget child;
  final int currentIndex;
  final UserType? userType;

  const AppScaffold({super.key, required this.child, required this.currentIndex, this.userType});

  // Icon names map to files in assets/icons/ (custom brand icon set).
  // The same asset is used for both the selected and unselected slot —
  // Flutter's NavigationBar/NavigationRail already apply a different
  // ambient IconTheme color per state, and AppIconAsset reads that
  // automatically, so one icon file covers both states cleanly.
  static const _destinations = [
    _NavDest('Home', 'home', '/'),
    _NavDest('Musicians', 'music', '/musicians'),
    _NavDest('Events', 'calendar', '/events'),
    _NavDest('Blog', 'blog', '/blog'),
    _NavDest('Dashboard', 'person_single', '/dashboard'),
  ];

  void _onSelect(BuildContext context, int index) {
    context.go(_destinations[index].route);
  }

  @override
  Widget build(BuildContext context) {
    if (Responsive.isMobile(context)) {
      return Scaffold(
        body: SafeArea(child: child),
        bottomNavigationBar: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: (i) => _onSelect(context, i),
          destinations: _destinations
              .map((d) => NavigationDestination(
                    icon: AppIconAsset(d.iconName, size: 24),
                    selectedIcon: AppIconAsset(d.iconName, size: 24),
                    label: d.label,
                  ))
              .toList(),
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: currentIndex,
            onDestinationSelected: (i) => _onSelect(context, i),
            labelType: NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  Image.asset('assets/images/logo.png', height: 40),
                  const SizedBox(height: 4),
                  Text(AppStrings.appName, style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
            ),
            destinations: _destinations
                .map((d) => NavigationRailDestination(
                      icon: AppIconAsset(d.iconName, size: 24),
                      selectedIcon: AppIconAsset(d.iconName, size: 24),
                      label: Text(d.label),
                    ))
                .toList(),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _NavDest {
  final String label;
  final String iconName;
  final String route;
  const _NavDest(this.label, this.iconName, this.route);
}
