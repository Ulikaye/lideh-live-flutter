import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/strings.dart';
import '../../core/utils/validators.dart';
import '../../models/event.dart';
import '../../providers/auth_provider.dart';
import '../../providers/event_provider.dart';
import '../../shared/widgets/error_widget.dart'; // ✅ AppErrorWidget
import '../../shared/widgets/loading_indicator.dart';

class EditEventScreen extends ConsumerStatefulWidget {
  final String eventId;
  const EditEventScreen({super.key, required this.eventId});

  @override
  ConsumerState<EditEventScreen> createState() => _EditEventScreenState();
}

class _EditEventScreenState extends ConsumerState<EditEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _date;
  TimeOfDay? _time;
  String? _existingCoverImageUrl;
  bool _saving = false;

  // Image upload
  File? _imageFile;
  String? _uploadedImageUrl;
  bool _uploadingImage = false;

  bool _initialized = false;

  void _initFromEvent(Event event) {
    if (_initialized) return;
    _titleController.text = event.title;
    _locationController.text = event.location;
    _descriptionController.text = event.description ?? '';
    _date = event.date;
    _time = event.time != null ? _parseTimeOfDay(event.time!) : null;
    _existingCoverImageUrl = event.coverImageUrl;
    _uploadedImageUrl = event.coverImageUrl;
    _initialized = true;
  }

  TimeOfDay? _parseTimeOfDay(String time) {
    try {
      final parts = time.split(':');
      if (parts.length == 2) {
        return TimeOfDay(
            hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.gallery, maxWidth: 1200, imageQuality: 85);
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
      await _uploadImage();
    }
  }

  Future<void> _uploadImage() async {
    if (_imageFile == null) return;
    setState(() => _uploadingImage = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not signed in');
      await user.getIdToken(true);

      final uid = user.uid;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = 'event_images/${uid}_$timestamp.jpg';

      final bytes = await _imageFile!.readAsBytes();
      final url = await ref.read(storageServiceProvider).uploadBytes(
            folder: 'event_images',
            bytes: bytes,
            extension: 'jpg',
          );
      setState(() => _uploadedImageUrl = url);
      debugPrint('✅ Event poster uploaded: $url');
    } catch (e) {
      debugPrint('❌ Upload error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_date == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please choose a date')));
      return;
    }
    setState(() => _saving = true);

    final firestore = ref.read(firestoreServiceProvider);
    final currentEvent = ref.read(eventByIdProvider(widget.eventId)).value;
    if (currentEvent == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event not found')),
        );
      }
      setState(() => _saving = false);
      return;
    }

    final updatedEvent = Event(
      id: widget.eventId,
      organizerId: currentEvent.organizerId,
      title: _titleController.text.trim(),
      date: _date!,
      time: _time?.format(context),
      location: _locationController.text.trim(),
      description: _descriptionController.text.trim(),
      coverImageUrl: _uploadedImageUrl ?? _existingCoverImageUrl,
      isCancelled: currentEvent.isCancelled,
      isPublished: currentEvent.isPublished,
      isPinned: currentEvent.isPinned,
      createdAt: currentEvent.createdAt,
      updatedAt: DateTime.now(),
    );

    try {
      // ✅ Use the correct method: updateEvent (NOT setBlogPost)
      await firestore.updateEvent(widget.eventId, updatedEvent);
      if (mounted) context.go('/events/${widget.eventId}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Could not update event: $e'),
              backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventAsync = ref.watch(eventByIdProvider(widget.eventId));

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Event')),
      body: eventAsync.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => AppErrorWidget(message: 'Could not load event: $e'),
        data: (event) {
          if (event == null) return AppErrorWidget(message: 'Event not found');
          _initFromEvent(event);
          return _buildForm();
        },
      ),
    );
  }

  Widget _buildForm() {
    final user = FirebaseAuth.instance.currentUser;
    final event = ref.read(eventByIdProvider(widget.eventId)).value;
    final isOwner =
        user != null && event != null && user.uid == event.organizerId;
    if (!isOwner) {
      return const Center(
          child: Text('You do not have permission to edit this event.'));
    }

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
                // Event poster picker
                GestureDetector(
                  onTap: _uploadingImage ? null : _pickImage,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Container(
                        color: AppColors.background,
                        child: _uploadingImage
                            ? const Center(child: CircularProgressIndicator())
                            : _uploadedImageUrl != null &&
                                    _uploadedImageUrl!.isNotEmpty
                                ? Image.network(_uploadedImageUrl!,
                                    fit: BoxFit.cover)
                                : const Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.add_photo_alternate_outlined,
                                            size: 32,
                                            color: AppColors.textSecondary),
                                        SizedBox(height: 8),
                                        Text('Tap to upload event poster',
                                            style: TextStyle(
                                                color:
                                                    AppColors.textSecondary)),
                                      ],
                                    ),
                                  ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                      labelText: 'Event title',
                      prefixIcon: Icon(Icons.event_outlined)),
                  validator: (v) => Validators.required(v, field: 'Title'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickDate,
                        icon: const Icon(Icons.calendar_today_outlined),
                        label: Text(_date == null
                            ? 'Pick date'
                            : '${_date!.month}/${_date!.day}/${_date!.year}'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickTime,
                        icon: const Icon(Icons.access_time_outlined),
                        label: Text(_time == null
                            ? 'Pick time'
                            : _time!.format(context)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                      labelText: 'Location',
                      prefixIcon: Icon(Icons.location_on_outlined)),
                  validator: (v) => Validators.required(v, field: 'Location'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                      labelText: 'Description', alignLabelWithHint: true),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _saving ? null : _submit,
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Save Changes'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
