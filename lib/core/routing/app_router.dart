import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
import '../../features/bookings/booking_chat_screen.dart';
import '../../features/events/event_list_screen.dart';
import '../../features/events/event_detail_screen.dart';
import '../../features/events/create_event_screen.dart';
import '../../features/events/edit_event_screen.dart'; // ✅ ADDED
import '../../features/blog/content_hub_screen.dart';
import '../../features/blog/blog_detail_screen.dart';
import '../../features/admin/admin_blog_list_screen.dart';
import '../../features/admin/admin_blog_editor_screen.dart';
import '../../features/admin/admin_ecard_list_screen.dart';
import '../../features/admin/admin_ecard_requests_screen.dart';
import '../../features/admin/admin_messages_screen.dart';
import '../../features/admin/admin_message_thread_screen.dart';
import '../../features/messages/user_message_screen.dart';
import '../../features/admin/admin_user_list_screen.dart';
import '../../features/admin/admin_event_list_screen.dart';
import '../../features/authentication/account_deactivated_screen.dart';
import '../../features/dashboard/musician_dashboard.dart';
import '../../features/dashboard/organizer_dashboard.dart';
import '../../features/e_cards/screens/ecard_list_screen.dart';
import '../../features/e_cards/screens/create_ecard_screen.dart';
import '../../features/e_cards/screens/ecard_detail_screen.dart';
import '../../features/e_cards/screens/public_ecards_screen.dart';
import '../../features/e_cards/screens/public_ecard_screen.dart';
import '../../features/e_cards/screens/guest_list_screen.dart';
import '../../features/e_cards/screens/guest_card_screen.dart';
import '../../features/e_cards/screens/scan_ecard_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/profile/edit_profile_screen.dart';
import '../../features/dashboard/edit_musician_details_screen.dart';
import '../../features/notifications/notification_inbox_screen.dart';
import '../../features/static/static_pages.dart';
import '../../shared/widgets/error_widget.dart';
import '../../shared/widgets/loading_indicator.dart';
import 'page_transitions.dart';
import '../../features/admin/admin_booking_notifications_screen.dart';

final _publicRoutes = <String>{
  '/',
  '/musicians',
  '/events',
  '/blog',
  '/e-cards/public',
  '/login',
  '/register',
  '/about',
  '/contact',
  '/terms',
  '/privacy',
  '/credits',
};

bool _isPublic(String path) {
  if (_publicRoutes.contains(path)) return true;
  if (path.startsWith('/musicians/')) return true;
  if (path.startsWith('/events/')) return true;
  if (path.startsWith('/blog/')) return true;
  if (path.startsWith('/e-cards/public/')) return true;
  return false;
}

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = ValueNotifier<bool>(false);
  ref.listen(authStateProvider, (prev, next) {
    authNotifier.value = !authNotifier.value;
  });
  ref.listen(currentUserProfileProvider, (prev, next) {
    authNotifier.value = !authNotifier.value;
  });

  return GoRouter(
    initialLocation: '/',
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final isLoggedIn = FirebaseAuth.instance.currentUser != null;
      final path = state.matchedLocation;

      debugPrint('🔁 Redirect: path="$path", isLoggedIn=$isLoggedIn');

      if (path == '/profile-setup') {
        if (isLoggedIn) {
          debugPrint('✅ Allowing /profile-setup');
          return null;
        } else {
          debugPrint('❌ Not logged in, redirect to login');
          return '/login?redirect=${Uri.encodeComponent(path)}';
        }
      }

      if (!isLoggedIn && !_isPublic(path)) {
        debugPrint('🔒 Not logged in, public? false -> redirect to login');
        return '/login?redirect=${Uri.encodeComponent(path)}';
      }

      if (isLoggedIn && path != '/account-deactivated') {
        final profile = ref.read(currentUserProfileProvider).value;
        if (profile?.disabled == true) {
          debugPrint('⛔ Account disabled -> redirect to /account-deactivated');
          return '/account-deactivated';
        }
      }

      if (path.startsWith('/admin')) {
        final profile = ref.read(currentUserProfileProvider).value;
        if (profile?.userType != UserType.admin) {
          debugPrint('🛑 Not admin -> redirect to /');
          return '/';
        }
      }

      debugPrint('✅ No redirect, stay on $path');
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
          GoRoute(
              path: '/musicians',
              builder: (_, __) => const MusicianListScreen()),
          GoRoute(
            path: '/musicians/:id',
            pageBuilder: (_, s) => slideTransitionPage(
                state: s,
                child:
                    MusicianProfileScreen(musicianId: s.pathParameters['id']!)),
          ),
          GoRoute(path: '/events', builder: (_, __) => const EventListScreen()),
          GoRoute(
            path: '/events/create',
            pageBuilder: (_, s) =>
                slideTransitionPage(state: s, child: const CreateEventScreen()),
          ),
          GoRoute(
            path: '/events/:id',
            pageBuilder: (_, s) => slideTransitionPage(
                state: s,
                child: EventDetailScreen(eventId: s.pathParameters['id']!)),
          ),
          GoRoute(
            path: '/events/:id/edit',
            pageBuilder: (_, s) => slideTransitionPage(
                state: s,
                child: EditEventScreen(eventId: s.pathParameters['id']!)),
          ),
          GoRoute(path: '/blog', builder: (_, __) => const ContentHubScreen()),
          GoRoute(
            path: '/blog/:id',
            pageBuilder: (_, s) => slideTransitionPage(
                state: s,
                child: BlogDetailScreen(postId: s.pathParameters['id']!)),
          ),
          GoRoute(
              path: '/admin/blog',
              builder: (_, __) => const AdminBlogListScreen()),
          GoRoute(
            path: '/admin/blog/new',
            pageBuilder: (_, s) => slideTransitionPage(
                state: s, child: const AdminBlogEditorScreen()),
          ),
          GoRoute(
            path: '/admin/blog/:id/edit',
            pageBuilder: (_, s) => slideTransitionPage(
                state: s,
                child: AdminBlogEditorScreen(postId: s.pathParameters['id'])),
          ),
          GoRoute(
              path: '/admin/e-cards',
              builder: (_, __) => const AdminEcardListScreen()),
          GoRoute(
              path: '/admin/ecard-requests',
              builder: (_, __) => const AdminEcardRequestsScreen()),
          GoRoute(
              path: '/admin/users',
              builder: (_, __) => const AdminUserListScreen()),
          GoRoute(
              path: '/admin/events',
              builder: (_, __) => const AdminEventListScreen()),
          GoRoute(
              path: '/admin/messages',
              builder: (_, __) => const AdminMessagesScreen()),
          GoRoute(
            path: '/admin/messages/:uid',
            pageBuilder: (_, s) => slideTransitionPage(
                state: s,
                child: AdminMessageThreadScreen(uid: s.pathParameters['uid']!)),
          ),
          GoRoute(
            path: '/messages',
            pageBuilder: (_, s) =>
                slideTransitionPage(state: s, child: const UserMessageScreen()),
          ),
          GoRoute(
              path: '/account-deactivated',
              builder: (_, __) => const AccountDeactivatedScreen()),
          GoRoute(
              path: '/dashboard',
              builder: (_, __) => const DashboardRouterScreen()),
          GoRoute(
              path: '/e-cards/public',
              builder: (_, __) => const PublicEcardsScreen()),
          GoRoute(
            path: '/e-cards/public/:id',
            pageBuilder: (_, s) => slideTransitionPage(
                state: s,
                child: PublicEcardScreen(ecardId: s.pathParameters['id']!)),
          ),
          GoRoute(
              path: '/e-cards', builder: (_, __) => const EcardListScreen()),
          GoRoute(
            path: '/e-cards/create',
            pageBuilder: (_, s) => slideTransitionPage(
                state: s,
                child: CreateEcardScreen(
                    eventId: s.uri.queryParameters['eventId'])),
          ),
          GoRoute(
            path: '/e-cards/:id',
            pageBuilder: (_, s) => slideTransitionPage(
                state: s,
                child: EcardDetailScreen(ecardId: s.pathParameters['id']!)),
          ),
          GoRoute(
            path: '/e-cards/:id/guests',
            pageBuilder: (_, s) => slideTransitionPage(
                state: s,
                child: GuestListScreen(ecardId: s.pathParameters['id']!)),
          ),
          GoRoute(
            path: '/e-cards/:id/guests/:guestId',
            pageBuilder: (_, s) => slideTransitionPage(
                state: s,
                child: GuestCardScreen(
                    ecardId: s.pathParameters['id']!,
                    guestId: s.pathParameters['guestId']!)),
          ),
          GoRoute(
            path: '/e-cards/:id/scan',
            pageBuilder: (_, s) => slideTransitionPage(
                state: s,
                child: ScanEcardScreen(ecardId: s.pathParameters['id']!)),
          ),
          GoRoute(
              path: '/bookings', builder: (_, __) => const MyBookingsScreen()),
          GoRoute(
            path: '/bookings/create/:musicianId',
            pageBuilder: (_, s) => slideTransitionPage(
                state: s,
                child: CreateBookingScreen(
                    musicianId: s.pathParameters['musicianId']!)),
          ),
          GoRoute(
            path: '/bookings/:id',
            pageBuilder: (_, s) => slideTransitionPage(
                state: s,
                child: BookingDetailScreen(bookingId: s.pathParameters['id']!)),
          ),
          GoRoute(
            path: '/bookings/:id/chat',
            pageBuilder: (_, s) => slideTransitionPage(
                state: s,
                child: BookingChatScreen(bookingId: s.pathParameters['id']!)),
          ),
          GoRoute(
            path: '/admin/booking-notifications',
            pageBuilder: (_, s) => slideTransitionPage(
                state: s, child: const AdminBookingNotificationsScreen()),
          ),
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
          GoRoute(
            path: '/profile/edit',
            pageBuilder: (_, s) =>
                slideTransitionPage(state: s, child: const EditProfileScreen()),
          ),
          GoRoute(
            path: '/musician-details/edit',
            pageBuilder: (_, s) => slideTransitionPage(
                state: s, child: const EditMusicianDetailsScreen()),
          ),
          GoRoute(
            path: '/notifications',
            pageBuilder: (_, s) => slideTransitionPage(
                state: s, child: const NotificationInboxScreen()),
          ),
          GoRoute(
              path: '/about',
              builder: (_, __) => const StaticPage(type: StaticPageType.about)),
          GoRoute(
              path: '/contact',
              builder: (_, __) =>
                  const StaticPage(type: StaticPageType.contact)),
          GoRoute(
              path: '/terms',
              builder: (_, __) => const StaticPage(type: StaticPageType.terms)),
          GoRoute(
              path: '/privacy',
              builder: (_, __) =>
                  const StaticPage(type: StaticPageType.privacy)),
          GoRoute(
              path: '/credits',
              builder: (_, __) =>
                  const StaticPage(type: StaticPageType.credits)),
        ],
      ),
      GoRoute(
          path: '/login',
          builder: (_, s) =>
              LoginScreen(redirectTo: s.uri.queryParameters['redirect'])),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(
        path: '/profile-setup',
        builder: (_, state) {
          final userTypeParam = state.uri.queryParameters['userType'];
          final userType = userTypeParam != null
              ? UserType.values.firstWhere((e) => e.name == userTypeParam)
              : UserType.organizer;
          return ProfileSetupScreen(userType: userType);
        },
      ),
    ],
  );
});

int _indexForPath(String path) {
  if (path.startsWith('/musicians')) return 1;
  if (path.startsWith('/events')) return 2;
  if (path.startsWith('/blog')) return 3;
  if (path.startsWith('/dashboard')) return 4;
  if (path.startsWith('/e-cards')) return 4;
  return 0;
}

class DashboardRouterScreen extends ConsumerWidget {
  const DashboardRouterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentUserProfileProvider);

    return profileAsync.when(
      loading: () => const Scaffold(
          body: LoadingIndicator(message: 'Loading your dashboard...')),
      error: (e, _) => Scaffold(
          body: AppErrorWidget(message: 'Could not load your profile: $e')),
      data: (profile) {
        if (profile == null) {
          return const Scaffold(
              body: AppErrorWidget(
                  message:
                      'No profile found for this account. Try signing out and back in.'));
        }
        if (profile.userType == UserType.musician)
          return const MusicianDashboard();
        return const OrganizerDashboard();
      },
    );
  }
}
