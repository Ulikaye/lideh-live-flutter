import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../models/event.dart';
import '../../providers/auth_provider.dart';
import '../../shared/widgets/loading_indicator.dart';

class CreateEventScreen extends ConsumerStatefulWidget {
  const CreateEventScreen({super.key});

  @override
  ConsumerState<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends ConsumerState<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _date;
  TimeOfDay? _time;
  bool _saving = false;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_date == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please choose a date')));
      return;
    }
    setState(() => _saving = true);
    final organizerId = ref.read(authServiceProvider).currentUser!.uid;
    final event = Event(
      id: '',
      organizerId: organizerId,
      title: _titleController.text.trim(),
      date: _date!,
      time: _time?.format(context),
      location: _locationController.text.trim(),
      description: _descriptionController.text.trim(),
      // New events start as drafts, not published — the organizer
      // publishes explicitly from the event's own detail page
      // (event_detail_screen.dart) whenever they're ready, rather
      // than everything going live the instant it's created.
      isPublished: false,
    );
    try {
      final id = await ref.read(firestoreServiceProvider).createEvent(event);
      // No interrupting dialog here anymore — straight to the event's
      // own page, where "Create E-Card" is a persistent, always-there
      // option (not just a one-time prompt right after creation), and
      // the publish toggle lives too.
      if (mounted) context.go('/events/$id');
    } catch (e) {
      // The screen-level verified check below should prevent an
      // unverified organizer from ever reaching this form in the
      // first place — this catch is the backstop for anything else
      // that could still fail (network drop, etc.), so it's never
      // silent.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not create event: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentUserProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Create Event')),
      body: profileAsync.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (profile) {
          // Account-level approval gate: an unverified organizer sees
          // a clear explanation instead of the form, rather than
          // being able to fill everything out and only then hit an
          // opaque permission error from the security rule.
          if (profile != null && !profile.verified) {
            return _PendingVerificationNotice();
          }
          return _buildForm(context);
        },
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Event title', prefixIcon: Icon(Icons.event_outlined)),
                  validator: (v) => Validators.required(v, field: 'Title'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickDate,
                        icon: const Icon(Icons.calendar_today_outlined),
                        label: Text(_date == null ? 'Pick date' : '${_date!.month}/${_date!.day}/${_date!.year}'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickTime,
                        icon: const Icon(Icons.access_time_outlined),
                        label: Text(_time == null ? 'Pick time' : _time!.format(context)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(labelText: 'Location', prefixIcon: Icon(Icons.location_on_outlined)),
                  validator: (v) => Validators.required(v, field: 'Location'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Description', alignLabelWithHint: true),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _saving ? null : _submit,
                  child: _saving
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Create Event'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PendingVerificationNotice extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.hourglass_top_rounded, size: 56, color: AppColors.textSecondary),
            const SizedBox(height: 20),
            Text('Account pending verification', style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            const Text(
              'Before you can create and publish events, an admin needs to verify your organizer account. '
              "This is a one-time check — you'll be able to create events as soon as it's approved.",
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
