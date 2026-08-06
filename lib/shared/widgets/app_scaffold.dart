import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/strings.dart';
import '../../core/utils/responsive.dart';

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

  static const _destinations = [
    _NavDest('Home', Icons.home_outlined, Icons.home_rounded, '/'),
    _NavDest('Musicians', Icons.music_note_outlined, Icons.music_note_rounded, '/musicians'),
    _NavDest('Events', Icons.event_outlined, Icons.event_rounded, '/events'),
    _NavDest('Blog', Icons.article_outlined, Icons.article_rounded, '/blog'),
    _NavDest('Dashboard', Icons.dashboard_outlined, Icons.dashboard_rounded, '/dashboard'),
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
              .map((d) => NavigationDestination(icon: Icon(d.icon), selectedIcon: Icon(d.activeIcon), label: d.label))
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
                .map((d) => NavigationRailDestination(icon: Icon(d.icon), selectedIcon: Icon(d.activeIcon), label: Text(d.label)))
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
  final IconData icon;
  final IconData activeIcon;
  final String route;
  const _NavDest(this.label, this.icon, this.activeIcon, this.route);
}
