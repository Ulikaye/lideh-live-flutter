import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/ecard_guest.dart';
import '../../../providers/ecard_provider.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../templates/ecard_preview.dart';

/// One guest's invitation — the real card design (Phase 4) rendered
/// with their name and their actual check-in QR code (Phase 6). This
/// is the screen an organizer opens to show/share a specific guest's
/// invitation, and the QR here is what the scanner in
/// scan_ecard_screen.dart reads.
class GuestCardScreen extends ConsumerWidget {
  final String ecardId;
  final String guestId;
  const GuestCardScreen({super.key, required this.ecardId, required this.guestId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ecardAsync = ref.watch(ecardByIdProvider(ecardId));
    final guestAsync = ref.watch(ecardGuestProvider((ecardId, guestId)));

    return Scaffold(
      appBar: AppBar(title: const Text('Invitation')),
      body: ecardAsync.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => AppErrorWidget(message: 'Could not load this E-Card'),
        data: (ecard) {
          if (ecard == null) return const AppErrorWidget(message: 'This E-Card no longer exists');
          return guestAsync.when(
            loading: () => const LoadingIndicator(),
            error: (e, _) => AppErrorWidget(message: 'Could not load this guest'),
            data: (guest) {
              if (guest == null) return const AppErrorWidget(message: 'This guest no longer exists');
              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 340),
                    child: Column(
                      children: [
                        EcardPreview(
                          ecard: ecard,
                          guestName: guest.fullName,
                          qrData: buildEcardQrPayload(ecardId: ecardId, guestId: guest.id),
                        ),
                        const SizedBox(height: 20),
                        Text(guest.displayId, style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1)),
                        const SizedBox(height: 6),
                        _StatusChip(guest: guest),
                        const SizedBox(height: 24),
                        Card(
                          child: ListTile(
                            leading: const Icon(Icons.ios_share_outlined, color: AppColors.textSecondary),
                            title: const Text('Share / export invitation'),
                            subtitle: const Text('Coming in the next phase'),
                            enabled: false,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final EcardGuest guest;
  const _StatusChip({required this.guest});

  @override
  Widget build(BuildContext context) {
    final checkedIn = guest.checkedIn;
    return Chip(
      avatar: Icon(checkedIn ? Icons.check_circle : Icons.schedule, size: 18, color: checkedIn ? AppColors.success : AppColors.textSecondary),
      label: Text(checkedIn ? 'Checked in' : 'Not checked in yet'),
      backgroundColor: checkedIn ? AppColors.success.withValues(alpha: 0.12) : AppColors.background,
    );
  }
}
