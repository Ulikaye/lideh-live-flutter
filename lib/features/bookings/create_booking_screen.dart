import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/strings.dart';
import '../../core/utils/validators.dart';
import '../../models/booking.dart';
import '../../providers/auth_provider.dart';
import '../../providers/musician_provider.dart';
import '../../shared/widgets/loading_indicator.dart';

class CreateBookingScreen extends ConsumerStatefulWidget {
  final String musicianId;
  const CreateBookingScreen({super.key, required this.musicianId});

  @override
  ConsumerState<CreateBookingScreen> createState() => _CreateBookingScreenState();
}

class _CreateBookingScreenState extends ConsumerState<CreateBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _eventNameController = TextEditingController();
  final _venueController = TextEditingController();
  final _messageController = TextEditingController();
  final _phoneController = TextEditingController();
  DateTime? _eventDate;
  TimeOfDay? _eventTime;
  bool _saving = false;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked != null) setState(() => _eventDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked != null) setState(() => _eventTime = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_eventDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please choose an event date')));
      return;
    }
    setState(() => _saving = true);
    final organizerId = ref.read(authServiceProvider).currentUser!.uid;
    final booking = Booking(
      id: '',
      musicianId: widget.musicianId,
      organizerId: organizerId,
      eventName: _eventNameController.text.trim(),
      eventDate: _eventDate!,
      eventTime: _eventTime?.format(context),
      venue: _venueController.text.trim(),
      message: _messageController.text.trim(),
      contactPhone: _phoneController.text.trim(),
      status: BookingStatus.pending,
    );
    try {
      final id = await ref.read(firestoreServiceProvider).createBooking(booking);
      if (mounted) context.go('/bookings/$id');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final musicianAsync = ref.watch(musicianByIdProvider(widget.musicianId));

    return Scaffold(
      appBar: AppBar(title: const Text('Request Booking')),
      body: musicianAsync.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (musician) {
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
                      if (musician != null)
                        Text('Booking ${musician.stageName}', style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _eventNameController,
                        decoration: const InputDecoration(labelText: 'Event name', prefixIcon: Icon(Icons.event_outlined)),
                        validator: (v) => Validators.required(v, field: 'Event name'),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _pickDate,
                              icon: const Icon(Icons.calendar_today_outlined),
                              label: Text(_eventDate == null ? 'Pick date' : '${_eventDate!.month}/${_eventDate!.day}/${_eventDate!.year}'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _pickTime,
                              icon: const Icon(Icons.access_time_outlined),
                              label: Text(_eventTime == null ? 'Pick time' : _eventTime!.format(context)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _venueController,
                        decoration: const InputDecoration(labelText: 'Venue / location', prefixIcon: Icon(Icons.location_on_outlined)),
                        validator: (v) => Validators.required(v, field: 'Venue'),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(labelText: 'Contact phone', prefixIcon: Icon(Icons.phone_outlined)),
                        validator: Validators.phone,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _messageController,
                        maxLines: 4,
                        decoration: const InputDecoration(labelText: 'Message to musician', alignLabelWithHint: true),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _saving ? null : _submit,
                        child: _saving
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Send Booking Request'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
