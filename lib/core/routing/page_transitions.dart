import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Used for "drilling in" routes — musician profile, booking/event
/// detail, create-booking/create-event forms, edit profile — so
/// navigating deeper into the app feels distinct from switching
/// between top-level tabs (which use the fade+scale set globally in
/// AppTheme.pageTransitionsTheme). Slides in from the right and fades
/// slightly, the familiar "going deeper" pattern.
CustomTransitionPage<T> slideTransitionPage<T>({
  required Widget child,
  required GoRouterState state,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return SlideTransition(
        position: Tween<Offset>(begin: const Offset(0.08, 0), end: Offset.zero).animate(curved),
        child: FadeTransition(opacity: curved, child: child),
      );
    },
  );
}
