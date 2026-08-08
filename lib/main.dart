import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/routing/app_router.dart';
import 'core/constants/strings.dart';
import 'providers/auth_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: LidehLiveApp()));
}

class LidehLiveApp extends ConsumerWidget {
  const LidehLiveApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    // Registers this device's push token against the signed-in user's
    // profile exactly once per login — previously FcmService existed
    // but was never actually called from anywhere in the app.
    ref.listen(authStateProvider, (previous, next) {
      final user = next.value;
      if (user != null && previous?.value?.uid != user.uid) {
        ref.read(fcmServiceProvider).initForUser(user.uid);
      }
    });

    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
