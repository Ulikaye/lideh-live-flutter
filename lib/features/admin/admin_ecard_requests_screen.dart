import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../models/ecard_request.dart';
import '../../models/user_profile.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ecard_provider.dart';
import '../../providers/event_provider.dart';
import '../../shared/widgets/error_widget.dart';
import '../../shared/widgets/loading_indicator.dart';

/// Admin review queue for E-Card creation requests (see
/// create_ecard_screen.dart's approval gate). Reachable only by an
/// admin — the underlying watchAllEcardRequestsForAdmin() query
/// requires isAdmin() server-side regardless of route guards.
///
/// Only pending requests are shown by default — once resolved, a
/// request clears out of the working queue rather than sitting there
/// permanently mixed in with ones still needing a decision. Resolved
/// history is still one tap away, not deleted.
class AdminEcardRequestsScreen extends ConsumerStatefulWidget {
  const AdminEcardRequestsScreen({super.key});

  @override
  ConsumerState<AdminEcardRequestsScreen> createState() => _AdminEcardRequestsScreenState();
}

class _AdminEcardRequestsScreenState extends ConsumerState<AdminEcardRequestsScreen> {
  bool _showResolved = false;

  @override
  Widget build(BuildContext context) {
    final requestsAsync = ref.watch(allEcardRequestsForAdminProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('E-Card Requests'),
        actions: [
          TextButton.icon(
            onPressed: () => setState(() => _showResolved = !_showResolved),
            icon: Icon(_showResolved ? Icons.visibility_off_outlined : Icons.history_outlined),
            label: Text(_showResolved ? 'Hide resolved' : 'View resolved'),
          ),
        ],
      ),
      body: requestsAsync.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => AppErrorWidget(message: 'Could not load requests'),
        data: (requests) {
          final visible = _showResolved ? requests : requests.where((r) => r.isPending).toList();

          if (visible.isEmpty) {
            return EmptyStateWidget(
              title: _showResolved ? 'No requests yet' : 'No pending requests',
              subtitle: _showResolved ? null : 'All caught up — resolved requests are hidden by default',
              icon: Icons.verified_user_outlined,
            );
          }
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: visible.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) => _RequestCard(request: visible[i]),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RequestCard extends ConsumerWidget {
  final EcardRequest request;
  const _RequestCard({required this.request});

  Color _statusColor() {
    if (request.isApproved) return AppColors.success;
    if (request.isRejected) return AppColors.danger;
    return AppColors.textSecondary;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventAsync = ref.watch(eventByIdProvider(request.eventId));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.circle, size: 10, color: _statusColor()),
                const SizedBox(width: 8),
                Text(request.status.toUpperCase(), style: TextStyle(color: _statusColor(), fontWeight: FontWeight.w700, fontSize: 12)),
                const Spacer(),
                if (request.createdAt != null)
                  Text(DateFormat('MMM d, y · h:mm a').format(request.createdAt!), style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
              ],
            ),
            const SizedBox(height: 8),
            eventAsync.when(
              loading: () => const Text('Loading event…'),
              error: (e, _) => const Text('Event unavailable', style: TextStyle(color: AppColors.textSecondary)),
              data: (event) => Text(
                event?.title ?? 'Event no longer exists',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 4),
            _OrganizerContactLine(organizerId: request.organizerId),
            if (request.adminReply != null && request.adminReply!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Reply: "${request.adminReply}"', style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12)),
            ],
            if (request.isPending) ...[
              const SizedBox(height: 12),
              _ResolveRow(request: request),
            ],
          ],
        ),
      ),
    );
  }
}

class _OrganizerContactLine extends ConsumerWidget {
  final String organizerId;
  const _OrganizerContactLine({required this.organizerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProfileByIdProvider(organizerId));
    return userAsync.when(
      loading: () => const Text('Loading organizer…', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      error: (e, _) => const Text('Organizer unavailable', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      data: (UserProfile? user) {
        if (user == null) return const Text('Organizer no longer exists', style: TextStyle(color: AppColors.textSecondary, fontSize: 12));
        final name = user.displayName ?? user.email;
        final phone = user.phone;
        return Text(
          'Organizer: $name · ${user.email}${phone != null ? ' · $phone' : ''}',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        );
      },
    );
  }
}

class _ResolveRow extends ConsumerStatefulWidget {
  final EcardRequest request;
  const _ResolveRow({required this.request});

  @override
  ConsumerState<_ResolveRow> createState() => _ResolveRowState();
}

class _ResolveRowState extends ConsumerState<_ResolveRow> {
  final _replyController = TextEditingController();
  bool _resolving = false;

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _resolve(bool approved) async {
    setState(() => _resolving = true);
    try {
      final adminUid = ref.read(authServiceProvider).currentUser!.uid;
      await ref.read(firestoreServiceProvider).resolveEcardRequest(
            widget.request.id,
            approved: approved,
            reply: _replyController.text.trim().isEmpty ? null : _replyController.text.trim(),
            adminUid: adminUid,
          );
    } catch (e) {
      // Previously uncaught — a rules rejection (or any other write
      // failure) would flash the optimistic local update and then
      // silently revert with zero explanation once Firestore's actual
      // response came back.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not resolve request: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _resolving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _replyController,
          decoration: const InputDecoration(labelText: 'Reply (optional)', isDense: true),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _resolving ? null : () => _resolve(false),
                child: const Text('Reject'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: _resolving ? null : () => _resolve(true),
                child: _resolving
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Approve'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
