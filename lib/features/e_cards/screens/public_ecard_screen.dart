import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/ecard_provider.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/profile_menu_button.dart';
import '../templates/ecard_preview.dart';

/// Read-only public view of one E-Card's design — reached from the
/// public listing (public_ecards_screen.dart) or a shared direct
/// link. Deliberately separate from EcardDetailScreen: that screen is
/// the organizer's management page (visibility toggle, guest list,
/// scanner) and must never be shown to a random visitor just because
/// the underlying Firestore rule permits reading a public card's
/// document — the rule controls DATA access, this screen controls
/// what UI that data is allowed to appear inside.
///
/// If the card is private (or doesn't exist, or the caller lacks
/// access), Firestore itself denies the read and this renders the
/// same "not found" state — a private card is indistinguishable from
/// a nonexistent one to a visitor who isn't its owner, which is the
/// correct behavior for something that's supposed to only be
/// reachable by direct link/QR.
class PublicEcardScreen extends ConsumerWidget {
  final String ecardId;
  const PublicEcardScreen({super.key, required this.ecardId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ecardAsync = ref.watch(ecardByIdProvider(ecardId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invitation'),
        actions: const [ProfileMenuButton(), SizedBox(width: 8)],
      ),
      body: ecardAsync.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => const AppErrorWidget(message: 'This invitation is not available'),
        data: (ecard) {
          if (ecard == null || !ecard.isPublic) {
            return const AppErrorWidget(message: 'This invitation is not available');
          }
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 340),
                child: EcardPreview(ecard: ecard),
              ),
            ),
          );
        },
      ),
    );
  }
}
