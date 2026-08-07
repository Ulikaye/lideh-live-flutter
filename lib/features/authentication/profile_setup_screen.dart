import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/strings.dart';
import '../../core/utils/validators.dart';
import '../../models/musician.dart';
import '../../models/organizer.dart';
import '../../providers/auth_provider.dart';
import '../../providers/musician_provider.dart';
import '../../shared/widgets/loading_indicator.dart';

/// Shown once, immediately after registration, so the role-specific
/// document (musicians/{uid} or organizers/{uid}) always exists before
/// the user reaches the rest of the app — mirroring the mandatory
/// "complete your profile" step in the original Django onboarding flow.
class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _locationController = TextEditingController();
  final _bioController = TextEditingController();

  // Musician-only fields
  final _stageNameController = TextEditingController();
  final _priceController = TextEditingController();
  final _experienceController = TextEditingController();
  final _youtubeController = TextEditingController();
  final Set<String> _selectedSkills = {};

  // Organizer-only fields
  final _orgNameController = TextEditingController();
  final _churchController = TextEditingController();

  bool _saving = false;

  Future<void> _submit(UserType userType) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final uid = ref.read(authServiceProvider).currentUser!.uid;
    final firestore = ref.read(firestoreServiceProvider);

    try {
      if (userType == UserType.musician) {
        await firestore.setMusicianProfile(Musician(
          uid: uid,
          stageName: _stageNameController.text.trim(),
          skills: _selectedSkills.toList(),
          location: _locationController.text.trim(),
          startingPrice: double.tryParse(_priceController.text.trim()),
          yearsOfExperience: int.tryParse(_experienceController.text.trim()),
          youtubeVideoId: _extractYoutubeId(_youtubeController.text.trim()),
          joinedAt: DateTime.now(),
        ));
      } else {
        await firestore.setOrganizerProfile(Organizer(
          uid: uid,
          organizationName: _orgNameController.text.trim(),
          churchAffiliation: _churchController.text.trim(),
          location: _locationController.text.trim(),
        ));
      }
      await firestore.updateUser(uid, {'location': _locationController.text.trim(), 'bio': _bioController.text.trim()});
      if (mounted) context.go('/');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _extractYoutubeId(String url) {
    if (url.isEmpty) return null;
    final regExp = RegExp(r'(?:v=|youtu\.be/)([a-zA-Z0-9_-]{6,})');
    final match = regExp.firstMatch(url);
    return match?.group(1);
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentUserProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Complete Your Profile')),
      body: profileAsync.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (profile) {
          if (profile == null) return const LoadingIndicator(message: 'Setting up your account...');
          final userType = profile.userType;

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
                      Text(
                        userType == UserType.musician ? "Tell us about your music" : 'Tell us about your organization',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 20),
                      if (userType == UserType.musician) ..._musicianFields() else ..._organizerFields(),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _locationController,
                        decoration: const InputDecoration(labelText: 'City / Region', prefixIcon: Icon(Icons.location_on_outlined)),
                        validator: (v) => Validators.required(v, field: 'Location'),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _bioController,
                        maxLines: 3,
                        decoration: const InputDecoration(labelText: 'Short bio', alignLabelWithHint: true),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _saving ? null : () => _submit(userType),
                        child: _saving
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Finish Setup'),
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

  List<Widget> _musicianFields() {
    final skillsAsync = ref.watch(skillsProvider);
    return [
      TextFormField(
        controller: _stageNameController,
        decoration: const InputDecoration(labelText: 'Stage / performing name', prefixIcon: Icon(Icons.badge_outlined)),
        validator: (v) => Validators.required(v, field: 'Stage name'),
      ),
      const SizedBox(height: 16),
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
      const SizedBox(height: 16),
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
      const SizedBox(height: 16),
      TextFormField(
        controller: _youtubeController,
        decoration: const InputDecoration(labelText: 'YouTube video link (optional)', prefixIcon: Icon(Icons.play_circle_outline)),
        validator: Validators.youtubeUrl,
      ),
    ];
  }

  List<Widget> _organizerFields() {
    return [
      TextFormField(
        controller: _orgNameController,
        decoration: const InputDecoration(labelText: 'Organization name', prefixIcon: Icon(Icons.church_outlined)),
        validator: (v) => Validators.required(v, field: 'Organization name'),
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _churchController,
        decoration: const InputDecoration(labelText: 'Church affiliation (optional)'),
      ),
    ];
  }
}
