import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart'; // ✅ Added for date formatting
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/strings.dart';
import '../../../core/utils/validators.dart';
import '../../../models/ecard.dart';
import '../../../models/ecard_request.dart';
import '../../../models/ecard_template.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/ecard_provider.dart';
import '../../../providers/event_provider.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../shared/widgets/loading_indicator.dart';

/// Occasion -> fallback field set, used only when no EcardTemplate
/// documents exist yet for that occasion (ecard_templates/ is seeded
/// via Admin SDK per firestore.rules — this keeps the create flow
/// usable end-to-end before real templates are seeded). Any key
/// ending in "_image_url" renders as a photo picker instead of a text
/// field — see _isImageField below — uploaded through the existing
/// StorageService, same pattern as edit_profile_screen.dart's avatar
/// upload, never base64-in-Firestore.
const _fallbackFields = <EcardOccasion, List<String>>{
  EcardOccasion.wedding: [
    'bride_name',
    'groom_name',
    'wedding_date',
    'venue',
    'bride_image_url',
    'groom_image_url',
    'single_amount',
    'double_amount'
  ],
  EcardOccasion.worship: [
    'church_name',
    'service_title',
    'date',
    'time',
    'venue',
    'theme'
  ],
  EcardOccasion.conference: [
    'title',
    'organizer_name',
    'date',
    'time',
    'venue',
    'description'
  ],
  EcardOccasion.other: ['title', 'date', 'time', 'venue', 'description'],
};

bool _isImageField(String key) => key.endsWith('_image_url');

/// ✅ New helpers to detect date/time fields
bool _isDateField(String key) => key.toLowerCase().contains('date');
bool _isTimeField(String key) => key.toLowerCase().contains('time');

String _humanize(String key) {
  final base = key.endsWith('_image_url')
      ? key.substring(0, key.length - '_image_url'.length)
      : key;
  final words = base.replaceAll('_', ' ').split(' ');
  return words
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

class CreateEcardScreen extends ConsumerStatefulWidget {
  /// Pre-filled when arriving from "Create an E-Card for this event?"
  /// on create_event_screen.dart. If null, step 0 asks the organizer
  /// to pick one of their existing events instead.
  final String? eventId;
  const CreateEcardScreen({super.key, this.eventId});

  @override
  ConsumerState<CreateEcardScreen> createState() => _CreateEcardScreenState();
}

class _CreateEcardScreenState extends ConsumerState<CreateEcardScreen> {
  late String? _eventId = widget.eventId;
  EcardOccasion? _occasion;
  EcardTemplate? _template;
  bool _useFallbackFields = false;
  final _fieldControllers = <String, TextEditingController>{};
  final _imageUrls = <String, String?>{};
  final _uploadingImage = <String, bool>{};
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  // ✅ Maps to store actual ISO values for date/time while keeping display text in controllers
  final _storedDateValues = <String, String>{};
  final _storedTimeValues = <String, String>{};

  Widget _buildStep() {
    if (_eventId == null) {
      return _EventPickerStep(onPicked: (id) => setState(() => _eventId = id));
    }
    final organizerId = ref.read(authServiceProvider).currentUser!.uid;
    final requestAsync =
        ref.watch(ecardRequestForEventProvider((organizerId, _eventId!)));
    return requestAsync.when(
      loading: () => const LoadingIndicator(),
      error: (e, _) =>
          AppErrorWidget(message: 'Could not check approval status'),
      data: (EcardRequest? request) {
        if (request == null || request.isRejected) {
          return _ApprovalGateStep(
            organizerId: organizerId,
            eventId: _eventId!,
            rejectedReply:
                request?.isRejected == true ? request!.adminReply : null,
          );
        }
        if (request.isPending) {
          return const _ApprovalPendingStep();
        }
        // approved
        if (_occasion == null) {
          return _OccasionPickerStep(
              onPicked: (o) => setState(() => _occasion = o));
        }
        if (_template == null && !_useFallbackFields) {
          return _TemplatePickerStep(
            occasion: _occasion!,
            onPicked: (t) => setState(() {
              _template = t;
              _prepareControllersFor(_activeFieldSchema);
            }),
            onSkip: () => setState(() {
              _useFallbackFields = true;
              _prepareControllersFor(_activeFieldSchema);
            }),
          );
        }
        return _buildFieldForm();
      },
    );
  }

  List<String> get _activeFieldSchema =>
      _template?.fieldSchema ?? _fallbackFields[_occasion!]!;

  void _prepareControllersFor(List<String> keys) {
    for (final k in keys) {
      if (_isImageField(k)) {
        _imageUrls.putIfAbsent(k, () => null);
        _uploadingImage.putIfAbsent(k, () => false);
      } else {
        _fieldControllers.putIfAbsent(k, () => TextEditingController());
      }
    }
  }

  Future<void> _pickAndUploadImage(String key) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.gallery, maxWidth: 800, imageQuality: 85);
    if (picked == null) return;
    setState(() => _uploadingImage[key] = true);
    try {
      final bytes = await picked.readAsBytes();
      final url = await ref.read(storageServiceProvider).uploadBytes(
            folder: AppStrings.ecardMediaPath,
            bytes: bytes,
            extension: 'jpg',
          );
      setState(() => _imageUrls[key] = url);
    } finally {
      if (mounted) setState(() => _uploadingImage[key] = false);
    }
  }

  // ✅ Modified _submit to use stored ISO values for date/time fields
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final missingImage = _activeFieldSchema
        .where(_isImageField)
        .where((k) => (_imageUrls[k] ?? '').isEmpty)
        .toList();
    if (missingImage.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please add ${_humanize(missingImage.first)}')),
      );
      return;
    }
    setState(() => _saving = true);
    final organizerId = ref.read(authServiceProvider).currentUser!.uid;

    // Build fields map, using stored ISO values for date/time, controller text for others
    final fields = <String, String>{};
    for (final e in _fieldControllers.entries) {
      if (_storedDateValues.containsKey(e.key)) {
        fields[e.key] = _storedDateValues[e.key]!;
      } else if (_storedTimeValues.containsKey(e.key)) {
        fields[e.key] = _storedTimeValues[e.key]!;
      } else {
        fields[e.key] = e.value.text.trim();
      }
    }
    // Add image URLs
    for (final e in _imageUrls.entries) {
      fields[e.key] = e.value ?? '';
    }

    final ecard = Ecard(
      id: '',
      eventId: _eventId!,
      organizerId: organizerId,
      occasion: _occasion!,
      templateId: _template?.id ?? '',
      fields: fields,
    );
    try {
      final id = await ref.read(firestoreServiceProvider).createEcard(ecard);
      if (mounted) context.go('/e-cards/$id');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    for (final c in _fieldControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create E-Card')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: _buildStep(),
          ),
        ),
      ),
    );
  }

  // ---- ✅ NEW: Date picker field ----
  Widget _buildDatePickerField(String key) {
    final controller = _fieldControllers[key]!;
    return TextFormField(
      controller: controller,
      readOnly: true, // prevents manual typing
      decoration: InputDecoration(
        labelText: _humanize(key),
        suffixIcon: const Icon(Icons.calendar_today_outlined),
      ),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (picked != null) {
          final isoString = DateFormat('yyyy-MM-dd').format(picked);
          final display = DateFormat.yMMMd().format(picked);
          setState(() {
            controller.text = display;
            _storedDateValues[key] = isoString;
          });
        }
      },
      validator: (value) => Validators.required(value, field: _humanize(key)),
    );
  }

  // ---- ✅ NEW: Time picker field ----
  Widget _buildTimePickerField(String key) {
    final controller = _fieldControllers[key]!;
    return TextFormField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: _humanize(key),
        suffixIcon: const Icon(Icons.access_time_outlined),
      ),
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
        );
        if (picked != null) {
          final hour = picked.hour.toString().padLeft(2, '0');
          final minute = picked.minute.toString().padLeft(2, '0');
          final isoTime = '$hour:$minute';
          final display = picked.format(context); // localised format
          setState(() {
            controller.text = display;
            _storedTimeValues[key] = isoTime;
          });
        }
      },
      validator: (value) => Validators.required(value, field: _humanize(key)),
    );
  }

  Widget _buildFieldForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(_occasion!.label,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
            _template != null
                ? 'Template: ${_template!.name}'
                : 'Using default fields for this occasion',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          for (final key in _activeFieldSchema) ...[
            if (_isImageField(key))
              _ImageFieldPicker(
                label: _humanize(key),
                url: _imageUrls[key],
                uploading: _uploadingImage[key] ?? false,
                onTap: () => _pickAndUploadImage(key),
              )
            else if (_isDateField(key))
              _buildDatePickerField(key)
            else if (_isTimeField(key))
              _buildTimePickerField(key)
            else
              TextFormField(
                controller: _fieldControllers[key],
                decoration: InputDecoration(labelText: _humanize(key)),
                validator: (v) => Validators.required(v, field: _humanize(key)),
              ),
            const SizedBox(height: 16),
          ],
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _saving ? null : _submit,
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Create E-Card'),
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// Everything below this line is UNCHANGED from your original file.
// =========================================================================

class _ImageFieldPicker extends StatelessWidget {
  final String label;
  final String? url;
  final bool uploading;
  final VoidCallback onTap;
  const _ImageFieldPicker(
      {required this.label,
      required this.url,
      required this.uploading,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: uploading ? null : onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(8)),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.background,
              backgroundImage:
                  (url != null && url!.isNotEmpty) ? NetworkImage(url!) : null,
              child: uploading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : (url == null || url!.isEmpty)
                      ? const Icon(Icons.add_a_photo_outlined,
                          color: AppColors.textSecondary)
                      : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                (url != null && url!.isNotEmpty)
                    ? '$label — tap to change'
                    : 'Add $label',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventPickerStep extends ConsumerWidget {
  final ValueChanged<String> onPicked;
  const _EventPickerStep({required this.onPicked});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentUserProfileProvider).value;
    if (profile == null) return const LoadingIndicator();
    final eventsAsync = ref.watch(eventsForOrganizerProvider(profile.uid));

    return eventsAsync.when(
      loading: () => const LoadingIndicator(),
      error: (e, _) => AppErrorWidget(message: 'Could not load your events'),
      data: (events) {
        if (events.isEmpty) {
          return EmptyStateWidget(
            title: 'No events yet',
            subtitle: 'Publish an event first, then add an E-Card to it',
            icon: Icons.event_outlined,
            action: ElevatedButton(
              onPressed: () => context.go('/events/create'),
              child: const Text('Create an event'),
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Which event is this E-Card for?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            for (final event in events) ...[
              _ExistingEcardGuard(
                eventId: event.id,
                organizerId: profile.uid,
                child: Card(
                  child: ListTile(
                    title: Text(event.title),
                    subtitle: Text(event.location),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => onPicked(event.id),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ],
        );
      },
    );
  }
}

/// Wraps an event's tile and swaps it for a warning if that event
/// already has an E-Card — avoids silently creating a second one
/// (there's no data-layer constraint against it; see
/// firestore_service.dart's watchEcardForEvent doc comment).
class _ExistingEcardGuard extends ConsumerWidget {
  final String eventId;
  final String organizerId;
  final Widget child;
  const _ExistingEcardGuard(
      {required this.eventId, required this.organizerId, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final existing =
        ref.watch(ecardForEventProvider((eventId, organizerId))).value;
    if (existing == null) return child;
    return Card(
      color: AppColors.background,
      child: ListTile(
        leading: const Icon(Icons.info_outline, color: AppColors.textSecondary),
        title: const Text('E-Card already exists for this event'),
        trailing: TextButton(
          onPressed: () => context.go('/e-cards/${existing.id}'),
          child: const Text('View'),
        ),
      ),
    );
  }
}

class _ApprovalGateStep extends ConsumerStatefulWidget {
  final String organizerId;
  final String eventId;

  /// Set only when the most recent request for this event was
  /// rejected — shown so the organizer knows why before sending
  /// another one, rather than it feeling like a mystery re-block.
  final String? rejectedReply;
  const _ApprovalGateStep(
      {required this.organizerId, required this.eventId, this.rejectedReply});

  @override
  ConsumerState<_ApprovalGateStep> createState() => _ApprovalGateStepState();
}

class _ApprovalGateStepState extends ConsumerState<_ApprovalGateStep> {
  bool _sending = false;

  Future<void> _sendRequest() async {
    setState(() => _sending = true);
    try {
      await ref.read(firestoreServiceProvider).createEcardRequest(
          organizerId: widget.organizerId, eventId: widget.eventId);
      // No manual navigation needed — CreateEcardScreen._buildStep is
      // watching this exact (organizerId, eventId) request live, so it
      // swaps to _ApprovalPendingStep on its own the moment this new
      // document appears.
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.verified_user_outlined,
            size: 40, color: AppColors.primary),
        const SizedBox(height: 12),
        const Text(
          'This needs admin approval',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          widget.rejectedReply != null
              ? 'Your last request wasn\'t approved: "${widget.rejectedReply}". You can send a new one.'
              : 'Send a request and an admin will review it — this page updates on its own once it\'s resolved.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _sending ? null : _sendRequest,
          child: _sending
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Send request'),
        ),
      ],
    );
  }
}

class _ApprovalPendingStep extends StatelessWidget {
  const _ApprovalPendingStep();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Icon(Icons.hourglass_top_outlined,
            size: 40, color: AppColors.textSecondary),
        SizedBox(height: 12),
        Text('Waiting for admin approval',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        SizedBox(height: 8),
        Text(
          'You\'ll move to the next step automatically as soon as this is approved.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _OccasionPickerStep extends StatelessWidget {
  final ValueChanged<EcardOccasion> onPicked;
  const _OccasionPickerStep({required this.onPicked});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('What kind of occasion is this?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        for (final occasion in EcardOccasion.values) ...[
          Card(
            child: ListTile(
              title: Text(occasion.label),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => onPicked(occasion),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _TemplatePickerStep extends ConsumerWidget {
  final EcardOccasion occasion;
  final ValueChanged<EcardTemplate> onPicked;
  final VoidCallback onSkip;
  const _TemplatePickerStep(
      {required this.occasion, required this.onPicked, required this.onSkip});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(ecardTemplatesProvider(occasion));
    return templatesAsync.when(
      loading: () => const LoadingIndicator(),
      error: (e, _) => AppErrorWidget(message: 'Could not load templates'),
      data: (templates) {
        if (templates.isEmpty) {
          // Expected until Phase 4 seeds ecard_templates/ — proceed
          // with the occasion's default field set rather than
          // blocking the organizer.
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('No templates yet for this occasion',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              const Text('You can continue with the default fields for now.',
                  style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: onSkip, child: const Text('Continue')),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Choose a template',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            for (final template in templates) ...[
              Card(
                child: ListTile(
                  title: Text(template.name),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => onPicked(template),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ],
        );
      },
    );
  }
}
