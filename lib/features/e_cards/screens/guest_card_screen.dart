import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/ecard_guest.dart';
import '../../../providers/ecard_provider.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../templates/ecard_preview.dart';

/// One guest's invitation — the real card design rendered with their
/// name and their actual check-in QR code. This is the screen an
/// organizer opens to share a specific guest's invitation as an
/// image (WhatsApp, email, etc.), and the QR here is what the
/// scanner in scan_ecard_screen.dart reads.
///
/// Sharing works by capturing the rendered EcardPreview widget itself
/// as a PNG (via RepaintBoundary — no server round-trip, no
/// screenshot package, just Flutter's own render tree) and handing
/// those bytes to the platform share sheet, which lets the organizer
/// pick WhatsApp, email, Save to Photos, or anything else registered
/// on their device.
class GuestCardScreen extends ConsumerStatefulWidget {
  final String ecardId;
  final String guestId;
  const GuestCardScreen({super.key, required this.ecardId, required this.guestId});

  @override
  ConsumerState<GuestCardScreen> createState() => _GuestCardScreenState();
}

class _GuestCardScreenState extends ConsumerState<GuestCardScreen> {
  final _previewKey = GlobalKey();
  bool _sharing = false;

  Future<void> _shareCard(EcardGuest guest) async {
    setState(() => _sharing = true);
    try {
      final boundary = _previewKey.currentContext?.findRenderObject();
      if (boundary is! RenderRepaintBoundary) {
        throw StateError('Card is not ready yet');
      }
      // pixelRatio 3.0 gives a sharp image on high-density phone
      // screens — this card is meant to be viewed full-size after
      // sharing, not just as a thumbnail.
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw StateError('Could not encode image');
      final bytes = byteData.buffer.asUint8List();

      await SharePlus.instance.share(ShareParams(
        text: 'You are invited! Here is your invitation.',
        files: [XFile.fromData(bytes, name: '${guest.displayId}.png', mimeType: 'image/png')],
      ));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not prepare the invitation. Please try again.'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ecardAsync = ref.watch(ecardByIdProvider(widget.ecardId));
    final guestAsync = ref.watch(ecardGuestProvider((widget.ecardId, widget.guestId)));

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
                        RepaintBoundary(
                          key: _previewKey,
                          child: EcardPreview(
                            ecard: ecard,
                            guestName: guest.fullName,
                            qrData: buildEcardQrPayload(ecardId: widget.ecardId, guestId: guest.id),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(guest.displayId, style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1)),
                        const SizedBox(height: 6),
                        _StatusChip(guest: guest),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _sharing ? null : () => _shareCard(guest),
                            icon: _sharing
                                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.ios_share_outlined),
                            label: Text(_sharing ? 'Preparing...' : 'Share invitation'),
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
