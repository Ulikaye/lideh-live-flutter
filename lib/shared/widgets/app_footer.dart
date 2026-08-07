import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/strings.dart';

/// Persistent footer shown at the bottom of the home page and the
/// static pages themselves — this is the actual entry point into
/// About/Contact/Terms/Privacy, none of which are otherwise reachable
/// from the main navigation. Also carries the attribution required by
/// Flaticon's free-tier icon license.
class AppFooter extends StatelessWidget {
  const AppFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      color: AppColors.primary.withValues(alpha: 0.04),
      child: Column(
        children: [
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 24,
            runSpacing: 8,
            children: [
              _FooterLink('About', '/about'),
              _FooterLink('Contact', '/contact'),
              _FooterLink('Terms of Service', '/terms'),
              _FooterLink('Privacy Policy', '/privacy'),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            '© ${DateTime.now().year} ${AppStrings.appName}. All rights reserved.',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  final String label;
  final String route;
  const _FooterLink(this.label, this.route);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go(route),
      child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, decoration: TextDecoration.underline)),
    );
  }
}
