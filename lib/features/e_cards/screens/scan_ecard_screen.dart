import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/ecard_guest.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/ecard_provider.dart';

/// Camera-based check-in scanner for one E-Card. Reads a QR payload
/// of the form "ecardId:guestId" (see EcardGuest.buildEcardQrPayload)
/// and calls FirestoreService.checkInEcardGuest, which does the
/// read-verify-write as a single transaction — see that method's doc
/// comment for why this replaces the original ScanGateFragment's
/// separate read-then-write calls.
///
/// A QR from a different E-Card (right shape, wrong ecardId) is
/// rejected client-side before ever hitting Firestore — scanning
/// someone else's wedding invite at this conference's check-in desk
/// shouldn't silently check anyone in anywhere.
class ScanEcardScreen extends ConsumerStatefulWidget {
  final String ecardId;
  const ScanEcardScreen({super.key, required this.ecardId});

  @override
  ConsumerState<ScanEcardScreen> createState() => _ScanEcardScreenState();
}

enum _ResultKind { success, alreadyCheckedIn, wrongCard, notFound, invalid }

class _ScanResult {
  final _ResultKind kind;
  final String message;
  const _ScanResult(this.kind, this.message);
}

class _ScanEcardScreenState extends ConsumerState<ScanEcardScreen> {
  final _controller = MobileScannerController();
  bool _processing = false;
  _ScanResult? _lastResult;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleDetect(BarcodeCapture capture) async {
    if (_processing) return;
    final raw = capture.barcodes.isEmpty ? null : capture.barcodes.first.rawValue;
    if (raw == null) return;

    final parts = raw.split(':');
    if (parts.length != 2 || parts[0].isEmpty || parts[1].isEmpty) {
      setState(() => _lastResult = const _ScanResult(_ResultKind.invalid, 'Not a valid E-Card invitation code'));
      return;
    }
    final scannedEcardId = parts[0];
    final guestId = parts[1];

    if (scannedEcardId != widget.ecardId) {
      setState(() => _lastResult = const _ScanResult(_ResultKind.wrongCard, 'This invitation is for a different E-Card'));
      return;
    }

    setState(() => _processing = true);
    try {
      await ref.read(firestoreServiceProvider).checkInEcardGuest(widget.ecardId, guestId);
      final name = await _guestName(guestId);
      setState(() => _lastResult = _ScanResult(_ResultKind.success, '$name checked in'));
    } on AlreadyCheckedInException catch (e) {
      final name = await _guestName(guestId);
      final when = e.checkedInTime != null ? ' at ${_formatTime(e.checkedInTime!)}' : '';
      setState(() => _lastResult = _ScanResult(_ResultKind.alreadyCheckedIn, '$name already checked in$when'));
    } on StateError {
      setState(() => _lastResult = const _ScanResult(_ResultKind.notFound, 'Guest not found on this E-Card'));
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  /// Best-effort display name for the result banner — checkInEcardGuest
  /// only confirms success/failure, it doesn't return the guest, so
  /// this reads the already-cached guest list rather than adding a
  /// second one-off Firestore read method just for a label.
  Future<String> _guestName(String guestId) async {
    try {
      final guests = await ref.read(guestsForEcardProvider(widget.ecardId).future);
      for (final g in guests) {
        if (g.id == guestId) return g.fullName;
      }
    } catch (_) {
      // fall through to generic label below
    }
    return 'Guest';
  }

  String _formatTime(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  void _dismissResult() => setState(() => _lastResult = null);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan & check in'),
        actions: [
          IconButton(icon: const Icon(Icons.flash_on_outlined), onPressed: () => _controller.toggleTorch()),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _handleDetect),
          if (_processing) const Center(child: CircularProgressIndicator()),
          if (_lastResult != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: _ResultBanner(result: _lastResult!, onDismiss: _dismissResult),
            ),
        ],
      ),
    );
  }
}

class _ResultBanner extends StatelessWidget {
  final _ScanResult result;
  final VoidCallback onDismiss;
  const _ResultBanner({required this.result, required this.onDismiss});

  Color get _color {
    switch (result.kind) {
      case _ResultKind.success:
        return AppColors.success;
      case _ResultKind.alreadyCheckedIn:
        return AppColors.warning;
      case _ResultKind.wrongCard:
      case _ResultKind.notFound:
      case _ResultKind.invalid:
        return AppColors.danger;
    }
  }

  IconData get _icon {
    switch (result.kind) {
      case _ResultKind.success:
        return Icons.check_circle;
      case _ResultKind.alreadyCheckedIn:
        return Icons.info;
      case _ResultKind.wrongCard:
      case _ResultKind.notFound:
      case _ResultKind.invalid:
        return Icons.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: _color, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Icon(_icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(result.message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
            IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: onDismiss),
          ],
        ),
      ),
    );
  }
}
