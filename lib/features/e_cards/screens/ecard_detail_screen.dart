import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/strings.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/ecard_provider.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../templates/ecard_preview.dart';

/// E-Card management dashboard. Phase 5 enabled "Add & manage guests".
/// Phase 6 enables "Scan & check in" (-> ScanEcardScreen) — every
/// entry point on this page is now live.
class EcardDetailScreen extends ConsumerWidget {
  final String ecardId;
  const EcardDetailScreen({super.key, required this.ecardId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ecardAsync = ref.watch(ecardByIdProvider(ecardId));

    return Scaffold(
      appBar: AppBar(title: const Text('E-Card')),
      body: ecardAsync.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => AppErrorWidget(message: 'Could not load this E-Card'),
        data: (ecard) {
          if (ecard == null) {
            return const AppErrorWidget(message: 'This E-Card no longer exists');
          }
          final guestsAsync = ref.watch(guestsForEcardProvider(ecardId));

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(ecard.occasion.label, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(
                    ecard.templateId.isEmpty ? 'Default fields (no template selected)' : 'Template: ${ecard.templateId}',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: SizedBox(
                      width: 260,
                      child: EcardPreview(ecard: ecard),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: const Text('Fields', style: TextStyle(fontWeight: FontWeight.w600)),
                    children: [
                      for (final entry in ecard.fields.entries)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              Expanded(child: Text(_humanize(entry.key), style: const TextStyle(color: AppColors.textSecondary))),
                              Expanded(child: Text('${entry.value}', textAlign: TextAlign.end)),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: SwitchListTile(
                      value: ecard.isPublic,
                      onChanged: (value) => ref
                          .read(firestoreServiceProvider)
                          .updateEcardVisibility(ecardId, value ? 'public' : 'private'),
                      secondary: Icon(
                        ecard.isPublic ? Icons.public : Icons.lock_outline,
                        color: ecard.isPublic ? AppColors.primary : AppColors.textSecondary,
                      ),
                      title: const Text('Visible on public E-Cards page'),
                      subtitle: Text(
                        ecard.isPublic
                            ? 'Anyone can find this on the public listing'
                            : 'Private — only reachable by direct link or QR (WhatsApp, email, etc.)',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  guestsAsync.when(
                    loading: () => const LoadingIndicator(),
                    error: (e, _) => AppErrorWidget(message: 'Could not load guests'),
                    data: (guests) {
                      final checkedIn = guests.where((g) => g.checkedIn).length;
                      return Row(
                        children: [
                          Expanded(child: _StatCard(label: 'Guests', value: '${guests.length}')),
                          const SizedBox(width: 12),
                          Expanded(child: _StatCard(label: 'Checked in', value: '$checkedIn')),
                          const SizedBox(width: 12),
                          Expanded(child: _StatCard(label: 'Pending', value: '${guests.length - checkedIn}')),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.group_add_outlined, color: AppColors.primary),
                      title: const Text('Add & manage guests'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.go('/e-cards/$ecardId/guests'),
                    ),
                  ),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.qr_code_scanner_outlined, color: AppColors.primary),
                      title: const Text('Scan & check in'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.go('/e-cards/$ecardId/scan'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _humanize(String key) {
    final words = key.replaceAll('_', ' ').split(' ');
    return words.map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primary)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
