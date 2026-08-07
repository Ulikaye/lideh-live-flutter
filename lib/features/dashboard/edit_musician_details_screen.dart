import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/utils/validators.dart';
import '../../models/musician.dart';
import '../../providers/auth_provider.dart';
import '../../providers/musician_provider.dart';
import '../../shared/widgets/loading_indicator.dart';

/// Lets a musician update their professional details after the
/// one-time signup flow — stage name, skills, starting price, years
/// of experience, availability notes, and performance video link.
///
/// Before this screen existed, these fields could only ever be set
/// once during profile setup, with no way to change them afterward.
/// `availabilityNotes` in particular had no editing entry point at
/// all anywhere in the app, despite being shown on public profiles.
class EditMusicianDetailsScreen extends ConsumerStatefulWidget {
  const EditMusicianDetailsScreen({super.key});

  @override
  ConsumerState<EditMusicianDetailsScreen> createState() => _EditMusicianDetailsScreenState();
}

class _EditMusicianDetailsScreenState extends ConsumerState<EditMusicianDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _stageNameController = TextEditingController();
  final _priceController = TextEditingController();
  final _experienceController = TextEditingController();
  final _youtubeController = TextEditingController();
  final _availabilityController = TextEditingController();
  final Set<String> _selectedSkills = {};

  bool _saving = false;
  bool _initialized = false;

  void _initFromMusician(Musician musician) {
    if (_initialized) return;
    _stageNameController.text = musician.stageName;
    _priceController.text = musician.startingPrice?.toStringAsFixed(0) ?? '';
    _experienceController.text = musician.yearsOfExperience?.toString() ?? '';
    _availabilityController.text = musician.availabilityNotes ?? '';
    _youtubeController.text = musician.youtubeVideoId != null ? 'https://www.youtube.com/watch?v=${musician.youtubeVideoId}' : '';
    _selectedSkills.addAll(musician.skills);
    _initialized = true;
  }

  String? _extractYoutubeId(String url) {
    if (url.isEmpty) return null;
    final regExp = RegExp(r'(?:v=|youtu\.be/)([a-zA-Z0-9_-]{6,})');
    final match = regExp.firstMatch(url);
    return match?.group(1);
  }

  Future<void> _save(Musician current) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final updated = current.copyWith(
        stageName: _stageNameController.text.trim(),
        skills: _selectedSkills.toList(),
        startingPrice: double.tryParse(_priceController.text.trim()),
        yearsOfExperience: int.tryParse(_experienceController.text.trim()),
        availabilityNotes: _availabilityController.text.trim(),
        youtubeVideoId: _extractYoutubeId(_youtubeController.text.trim()),
      );
      await ref.read(firestoreServiceProvider).setMusicianProfile(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Details updated')));
        context.pop();
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = ref.read(authServiceProvider).currentUser!.uid;
    final musicianAsync = ref.watch(musicianByIdProvider(uid));
    final skillsAsync = ref.watch(skillsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Edit My Details')),
      body: musicianAsync.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (musician) {
          if (musician == null) return const LoadingIndicator(message: 'Loading your details...');
          _initFromMusician(musician);

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
                        controller: _stageNameController,
                        decoration: const InputDecoration(labelText: 'Stage / performing name', prefixIcon: Icon(Icons.badge_outlined)),
                        validator: (v) => Validators.required(v, field: 'Stage name'),
                      ),
                      const SizedBox(height: 20),
                      Text('Skills / instruments', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      skillsAsync.when(
                        loading: () => const LinearProgressIndicator(),
                        error: (_, __) => const Text('Could not load skills list'),
                        data: (skills) => Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: skills.map((skill) {
                            final selected = _selectedSkills.contains(skill.name);
                            return FilterChip(
                              label: Text(skill.name),
                              selected: selected,
                              onSelected: (v) => setState(() => v ? _selectedSkills.add(skill.name) : _selectedSkills.remove(skill.name)),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _priceController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Starting price (USD)'),
                              validator: (v) => Validators.positiveNumber(v, field: 'Price'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _experienceController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Years of experience'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _availabilityController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Availability notes',
                          hintText: 'e.g. Weekends only, or available for evening events on short notice',
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _youtubeController,
                        decoration: const InputDecoration(labelText: 'YouTube video link (optional)', prefixIcon: Icon(Icons.play_circle_outline)),
                        validator: Validators.youtubeUrl,
                      ),
                      const SizedBox(height: 28),
                      ElevatedButton(
                        onPressed: _saving ? null : () => _save(musician),
                        child: _saving
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Save Changes'),
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
