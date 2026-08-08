import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/strings.dart';
import '../../core/utils/responsive.dart';
import '../../providers/musician_provider.dart';
import '../../shared/widgets/app_icon_asset.dart';
import '../../shared/widgets/app_logo.dart';
import '../../shared/widgets/app_footer.dart';
import '../../shared/widgets/notification_bell_button.dart';
import '../../shared/widgets/profile_menu_button.dart';
import 'widgets/featured_musicians.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppLogo(size: 28),
            const SizedBox(width: 10),
            Text(AppStrings.appName),
          ],
        ),
        actions: [
          if (Responsive.isDesktopOrTablet(context)) ...[
            TextButton(onPressed: () => context.go('/musicians'), child: const Text('Find Musicians')),
            TextButton(onPressed: () => context.go('/events'), child: const Text('Events')),
            TextButton(onPressed: () => context.go('/blog'), child: const Text('Blog')),
            const SizedBox(width: 8),
          ],
          const NotificationBellButton(),
          const ProfileMenuButton(),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _HeroSection(),
            CenteredContent(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Featured Musicians', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 16),
                  const FeaturedMusicians(),
                  const SizedBox(height: 40),
                  _QuickLinksSection(),
                ],
              ),
            ),
            const AppFooter(),
          ],
        ),
      ),
    );
  }
}

class _HeroSection extends ConsumerStatefulWidget {
  @override
  ConsumerState<_HeroSection> createState() => _HeroSectionState();
}

class _HeroSectionState extends ConsumerState<_HeroSection> {
  final _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final isWide = Responsive.isDesktopOrTablet(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: isWide ? 72 : 48),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            children: [
              Text(
                'Find the Right Gospel Musician\nfor Your Next Event',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(color: Colors.white, fontSize: isWide ? 40 : 28),
              ),
              const SizedBox(height: 12),
              Text(
                AppStrings.tagline,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 28),
              Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by city or region...',
                    prefixIcon: const Icon(Icons.search),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.arrow_forward_rounded, color: AppColors.primary),
                      onPressed: () => _search(context),
                    ),
                  ),
                  onSubmitted: (_) => _search(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _search(BuildContext context) {
    final query = _searchController.text.trim();
    ref.read(musicianFilterProvider.notifier).state = MusicianFilter(location: query.isEmpty ? null : query);
    context.go('/musicians');
  }
}

class _QuickLinksSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final columns = Responsive.gridColumns(context).clamp(1, 3);
    final items = [
      _QuickLink(iconName: 'calendar', title: 'Upcoming Events', subtitle: 'See what\'s happening near you', route: '/events'),
      _QuickLink(iconName: 'blog', title: 'Content Hub', subtitle: 'Stories, tips and testimonials', route: '/blog'),
      _QuickLink(iconName: 'music', title: 'Browse Musicians', subtitle: 'Explore the full directory', route: '/musicians'),
    ];
    return GridView.count(
      crossAxisCount: columns,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.6,
      children: items.map((item) => _QuickLinkCard(item: item)).toList(),
    );
  }
}

class _QuickLink {
  final String iconName;
  final String title;
  final String subtitle;
  final String route;
  _QuickLink({required this.iconName, required this.title, required this.subtitle, required this.route});
}

class _QuickLinkCard extends StatelessWidget {
  final _QuickLink item;
  const _QuickLinkCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.go(item.route),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppIconAsset(item.iconName, color: AppColors.primary, size: 28),
              const SizedBox(height: 12),
              Text(item.title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(item.subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}
