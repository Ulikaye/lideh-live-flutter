import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/strings.dart';
import '../../../models/ecard_guest.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/ecard_provider.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../widgets/guest_form_sheet.dart';

/// Guest add/edit/delete/search for one E-Card. Reached from the
/// "Add & manage guests" row on EcardDetailScreen (Phase 3/4), now
/// enabled. Search is a client-side substring filter over the live
/// guest list — same pattern as Harusi Cards' RecordsFragment (see
/// Phase 1 doc §2), reasonable for the guest-list sizes this is meant
/// for; if that stops being true for a given organizer, a Firestore
/// query filter is the natural next step and wouldn't change this
/// screen's shape, only how `guests` is produced.
class GuestListScreen extends ConsumerStatefulWidget {
  final String ecardId;
  const GuestListScreen({super.key, required this.ecardId});

  @override
  ConsumerState<GuestListScreen> createState() => _GuestListScreenState();
}

class _GuestListScreenState extends ConsumerState<GuestListScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<EcardGuest> _filter(List<EcardGuest> guests) {
    if (_query.trim().isEmpty) return guests;
    final q = _query.trim().toLowerCase();
    return guests.where((g) => g.fullName.toLowerCase().contains(q) || g.displayId.toLowerCase().contains(q)).toList();
  }

  Future<void> _addGuest(EcardOccasion occasion) async {
    final result = await showGuestFormSheet(context, occasion: occasion);
    if (result == null) return;
    await ref.read(firestoreServiceProvider).addEcardGuest(
          ecardId: widget.ecardId,
          occasion: occasion,
          fullName: result.fullName,
          phone: result.phone,
          category: result.category,
        );
  }

  Future<void> _editGuest(EcardOccasion occasion, EcardGuest guest) async {
    final result = await showGuestFormSheet(context, occasion: occasion, existing: guest);
    if (result == null) return;
    await ref.read(firestoreServiceProvider).updateEcardGuest(widget.ecardId, guest.id, {
      'full_name': result.fullName,
      'phone': result.phone,
      'category': result.category,
    });
  }

  Future<void> _deleteGuest(EcardGuest guest) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove this guest?'),
        content: Text('${guest.fullName} (${guest.displayId}) will be permanently removed from this E-Card.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(firestoreServiceProvider).deleteEcardGuest(widget.ecardId, guest.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ecardAsync = ref.watch(ecardByIdProvider(widget.ecardId));

    return Scaffold(
      appBar: AppBar(title: const Text('Guests')),
      body: ecardAsync.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => AppErrorWidget(message: 'Could not load this E-Card'),
        data: (ecard) {
          if (ecard == null) {
            return const AppErrorWidget(message: 'This E-Card no longer exists');
          }
          final guestsAsync = ref.watch(guestsForEcardProvider(widget.ecardId));

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _query = v),
                      decoration: InputDecoration(
                        hintText: 'Search by name or ID',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _query.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () => setState(() {
                                  _searchController.clear();
                                  _query = '';
                                }),
                              ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  Expanded(
                    child: guestsAsync.when(
                      loading: () => const LoadingIndicator(),
                      error: (e, _) => AppErrorWidget(message: 'Could not load guests'),
                      data: (allGuests) {
                        final guests = _filter(allGuests);
                        if (allGuests.isEmpty) {
                          return EmptyStateWidget(
                            title: 'No guests yet',
                            subtitle: 'Add your first guest to generate their invitation',
                            icon: Icons.person_add_alt_outlined,
                            action: ElevatedButton.icon(
                              onPressed: () => _addGuest(ecard.occasion),
                              icon: const Icon(Icons.add),
                              label: const Text('Add guest'),
                            ),
                          );
                        }
                        if (guests.isEmpty) {
                          return const EmptyStateWidget(title: 'No matches', icon: Icons.search_off_rounded);
                        }
                        return ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: guests.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, i) {
                            final guest = guests[i];
                            return Card(
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: guest.checkedIn ? AppColors.success.withValues(alpha: 0.15) : AppColors.border,
                                  child: Icon(
                                    guest.checkedIn ? Icons.check_circle_outline : Icons.person_outline,
                                    color: guest.checkedIn ? AppColors.success : AppColors.textSecondary,
                                    size: 20,
                                  ),
                                ),
                                title: Text(guest.fullName),
                                subtitle: Text([
                                  guest.displayId,
                                  if (guest.category != null) guest.category!,
                                  if (guest.phone != null) guest.phone!,
                                ].join(' · ')),
                                onTap: () => context.go('/e-cards/${widget.ecardId}/guests/${guest.id}'),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == 'view') context.go('/e-cards/${widget.ecardId}/guests/${guest.id}');
                                    if (value == 'edit') _editGuest(ecard.occasion, guest);
                                    if (value == 'delete') _deleteGuest(guest);
                                  },
                                  itemBuilder: (context) => const [
                                    PopupMenuItem(value: 'view', child: Text('View card')),
                                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                                    PopupMenuItem(value: 'delete', child: Text('Remove')),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: ecardAsync.maybeWhen(
        data: (ecard) => ecard == null
            ? null
            : FloatingActionButton(
                onPressed: () => _addGuest(ecard.occasion),
                child: const Icon(Icons.add),
              ),
        orElse: () => null,
      ),
    );
  }
}
