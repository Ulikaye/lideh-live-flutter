import 'package:flutter/material.dart';

/// Breakpoints follow Material 3 window-size classes so the same
/// widget tree can adapt cleanly across phone, tablet, and desktop/web.
enum ScreenType { mobile, tablet, desktop }

class Responsive {
  Responsive._();

  static const double tabletBreakpoint = 700;
  static const double desktopBreakpoint = 1100;

  static ScreenType typeOf(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= desktopBreakpoint) return ScreenType.desktop;
    if (width >= tabletBreakpoint) return ScreenType.tablet;
    return ScreenType.mobile;
  }

  static bool isMobile(BuildContext context) => typeOf(context) == ScreenType.mobile;
  static bool isTablet(BuildContext context) => typeOf(context) == ScreenType.tablet;
  static bool isDesktop(BuildContext context) => typeOf(context) == ScreenType.desktop;
  static bool isDesktopOrTablet(BuildContext context) => !isMobile(context);

  /// Number of grid columns for musician/event/blog cards based on width.
  static int gridColumns(BuildContext context) {
    switch (typeOf(context)) {
      case ScreenType.desktop:
        return 4;
      case ScreenType.tablet:
        return 3;
      case ScreenType.mobile:
        return 1;
    }
  }

  /// Caps content width on very large screens so text doesn't stretch edge
  /// to edge — mirrors a desktop-friendly max-width container.
  static double maxContentWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width > 1400 ? 1400 : width;
  }
}

/// Convenience widget: renders different widgets per breakpoint.
class ResponsiveBuilder extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;

  const ResponsiveBuilder({super.key, required this.mobile, this.tablet, required this.desktop});

  @override
  Widget build(BuildContext context) {
    final type = Responsive.typeOf(context);
    switch (type) {
      case ScreenType.desktop:
        return desktop;
      case ScreenType.tablet:
        return tablet ?? desktop;
      case ScreenType.mobile:
        return mobile;
    }
  }
}

/// Centers content and caps its width on large screens.
class CenteredContent extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const CenteredContent({super.key, required this.child, this.padding = const EdgeInsets.all(16)});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: Responsive.maxContentWidth(context)),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
