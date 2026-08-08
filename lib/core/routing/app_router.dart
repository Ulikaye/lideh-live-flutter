import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_profile.dart';
import '../constants/strings.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../features/authentication/login_screen.dart';
import '../../features/authentication/register_screen.dart';
import '../../features/authentication/profile_setup_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/musicians/musician_list_screen.dart';
import '../../features/musicians/musician_profile_screen.dart';
import '../../features/bookings/create_booking_screen.dart';
import '../../features/bookings/booking_detail_screen.dart';
import '../../features/bookings/my_bookings_screen.dart';
import '../../features/events/event_list_screen.dart';
import '../../features/events/event_detail_screen.dart';
import '../../features/events/create_event_screen.dart';
import '../../features/blog/content_hub_screen.dart';
import '../../features/blog/blog_detail_screen.dart';
import '../../features/dashboard/musician_dashboard.dart';
import '../../features/dashboard/organizer_dashboard.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/profile/edit_profile_screen.dart';
import '../../features/dashboard/edit_musician_details_screen.dart';
import '../../features/notifications/notification_inbox_screen.dart';
import '../../features/static/static_pages.dart';
import '../../shared/widgets/error_widget.dart';
import '../../shared/widgets/loading_indicator.dart';
import 'page_transitions.dart';

final _publicRoutes = <String>{
  '/', '/musicians', '/events', '/blog', '/login', '/register', '/about', '/contact', '/terms', '/privacy', '/credits',
};

/// Any route not in [_publicRoutes] (and not a detail page nested under
/// a public prefix) requires an authenticated session. Role-specific
/// dashboards are additionally checked in their own screens.
bool _isPublic(String path) {
  if (_publicRoutes.contains(path)) return true;
  if (path.startsWith('/musicians/')) return true; // musician profile pages are public
  if (path.startsWith('/events/')) return true;
  if (path.startsWith('/blog/')) return true;
  return false;
}

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = ValueNotifier<bool>(false);
  ref.listen(authStateProvider, (prev, next) {
    authNotifier.value = !authNotifier.value; // force GoRouter to re-evaluate redirects
  });

  return GoRouter(
    initialLocation: '/',
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final auth = ref.read(authStateProvider);
      final isLoggedIn = auth.value != null;
      final path = state.matchedLocation;

      final goingToAuthPages = path == '/login' || path == '/register';

      if (!isLoggedIn && !_isPublic(path)) {
        return '/login?redirect=${Uri.encodeComponent(path)}';
      }
      if (isLoggedIn && goingToAuthPages) {
        return '/';
      }
      return null;
    },
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          final index = _indexForPath(state.matchedLocation);
          return AppScaffold(currentIndex: index, child: child);
        },
        routes: [
          GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
          GoRoute(path: '/musicians', builder: (_, __) => const MusicianListScreen()),
          GoRoute(
            path: '/musicians/:id',
            pageBuilder: (_, s) => slideTransitionPage(state: s, child: MusicianProfileScreen(musicianId: s.pathParameters['id']!)),
          ),
          GoRoute(path: '/events', builder: (_, __) => const EventListScreen()),
          GoRoute(
            path: '/events/create',
            pageBuilder: (_, s) => slideTransitionPage(state: s, child: const CreateEventScreen()),
          ),
          GoRoute(
            path: '/events/:id',
            pageBuilder: (_, s) => slideTransitionPage(state: s, child: EventDetailScreen(eventId: s.pathParameters['id']!)),
          ),
          GoRoute(path: '/blog', builder: (_, __) => const ContentHubScreen()),
          GoRoute(
            path: '/blog/:id',
            pageBuilder: (_, s) => slideTransitionPage(state: s, child: BlogDetailScreen(postId: s.pathParameters['id']!)),
          ),
          GoRoute(path: '/dashboard', builder: (_, __) => const DashboardRouterScreen()),
          GoRoute(path: '/bookings', builder: (_, __) => const MyBookingsScreen()),
          GoRoute(
            path: '/bookings/create/:musicianId',
            pageBuilder: (_, s) => slideTransitionPage(state: s, child: CreateBookingScreen(musicianId: s.pathParameters['musicianId']!)),
          ),
          GoRoute(
            path: '/bookings/:id',
            pageBuilder: (_, s) => slideTransitionPage(state: s, child: BookingDetailScreen(bookingId: s.pathParameters['id']!)),
          ),
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
          GoRoute(
            path: '/profile/edit',
            pageBuilder: (_, s) => slideTransitionPage(state: s, child: const EditProfileScreen()),
          ),
          GoRoute(
            path: '/musician-details/edit',
            pageBuilder: (_, s) => slideTransitionPage(state: s, child: const EditMusicianDetailsScreen()),
          ),
          GoRoute(
            path: '/notifications',
            pageBuilder: (_, s) => slideTransitionPage(state: s, child: const NotificationInboxScreen()),
          ),
          GoRoute(path: '/about', builder: (_, __) => const StaticPage(type: StaticPageType.about)),
          GoRoute(path: '/contact', builder: (_, __) => const StaticPage(type: StaticPageType.contact)),
          GoRoute(path: '/terms', builder: (_, __) => const StaticPage(type: StaticPageType.terms)),
          GoRoute(path: '/privacy', builder: (_, __) => const StaticPage(type: StaticPageType.privacy)),
          GoRoute(path: '/credits', builder: (_, __) => const StaticPage(type: StaticPageType.credits)),
        ],
      ),
      GoRoute(path: '/login', builder: (_, s) => LoginScreen(redirectTo: s.uri.queryParameters['redirect'])),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/profile-setup', builder: (_, __) => const ProfileSetupScreen()),
    ],
  );
});

int _indexForPath(String path) {
  if (path.startsWith('/musicians')) return 1;
  if (path.startsWith('/events')) return 2;
  if (path.startsWith('/blog')) return 3;
  if (path.startsWith('/dashboard')) return 4;
  return 0;
}

/// Routes `/dashboard` to the correct role-specific dashboard.
class DashboardRouterScreen extends ConsumerWidget {
  const DashboardRouterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentUserProfileProvider);

    return profileAsync.when(
      loading: () => const Scaffold(body: LoadingIndicator(message: 'Loading your dashboard...')),
      error: (e, _) => Scaffold(body: AppErrorWidget(message: 'Could not load your profile: $e')),
      data: (profile) {
        if (profile == null) {
          return const Scaffold(body: AppErrorWidget(message: 'No profile found for this account. Try signing out and back in.'));
        }
        if (profile.userType == UserType.musician) return const MusicianDashboard();
        return const OrganizerDashboard();
      },
    );
  }
}
