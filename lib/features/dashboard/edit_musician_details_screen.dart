import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/utils/validators.dart';
import '../../models/musician.dart';
import '../../providers/auth_provider.dart';
import '../../providers/musician_provider.dart';
import '../../shared/widgets/loading_indicator.dart';

/// Lets a musician update their professional details after the
/// one-time signup flow — stage name, skills, starting price, years
/// of experience, availability notes, performance video link, and profile picture.
class EditMusicianDetailsScreen extends ConsumerStatefulWidget {
  const EditMusicianDetailsScreen({super.key});

  @override
  ConsumerState<EditMusicianDetailsScreen> createState() =>
      _EditMusicianDetailsScreenState();
}

class _EditMusicianDetailsScreenState
    extends ConsumerState<EditMusicianDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _stageNameController = TextEditingController();
  final _priceController = TextEditingController();
  final _experienceController = TextEditingController();
  final _youtubeController = TextEditingController();
  final _availabilityController = TextEditingController();
  final Set<String> _selectedSkills = {};

  // Profile picture
  File? _imageFile;
  String? _uploadedImageUrl;
  bool _uploadingImage = false;

  bool _saving = false;
  bool _initialized = false;

  // ---------- Image picker & upload ----------
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
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
      final path = 'musician_media/$uid.jpg';
      debugPrint('🔼 Uploading to: $path');

      final storageRef = FirebaseStorage.instance.ref().child(path);
      final metadata = SettableMetadata(contentType: 'image/jpeg');
      await storageRef.putFile(_imageFile!, metadata);
      final url = await storageRef.getDownloadURL();
      setState(() => _uploadedImageUrl = url);
      debugPrint('✅ Upload success: $url');
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

  // ---------- Initialization ----------
  void _initFromMusician(Musician musician) {
    if (_initialized) return;
    _stageNameController.text = musician.stageName;
    _priceController.text = musician.startingPrice?.toStringAsFixed(0) ?? '';
    _experienceController.text = musician.yearsOfExperience?.toString() ?? '';
    _availabilityController.text = musician.availabilityNotes ?? '';
    _youtubeController.text = musician.youtubeVideoId != null
        ? 'https://www.youtube.com/watch?v=${musician.youtubeVideoId}'
        : '';
    _selectedSkills.addAll(musician.skills);
    _uploadedImageUrl = musician.photoURL; // existing photo
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
        photoURL: _uploadedImageUrl, // updated or existing
      );
      await ref.read(firestoreServiceProvider).setMusicianProfile(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Details updated')),
        );
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
          if (musician == null)
            return const LoadingIndicator(message: 'Loading your details...');
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
                      // ----- Profile picture picker -----
                      GestureDetector(
                        onTap: _pickImage,
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: _uploadedImageUrl != null
                              ? NetworkImage(_uploadedImageUrl!)
                              : null,
                          child: _uploadedImageUrl == null
                              ? (_uploadingImage
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : const Icon(Icons.camera_alt,
                                      size: 40, color: Colors.grey))
                              : null,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _uploadedImageUrl != null
                            ? 'Tap to change photo'
                            : 'Tap to add photo',
                        textAlign: TextAlign.center,
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 24),

                      // ----- Fields -----
                      TextFormField(
                        controller: _stageNameController,
                        decoration: const InputDecoration(
                          labelText: 'Stage / performing name',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                        validator: (v) =>
                            Validators.required(v, field: 'Stage name'),
                      ),
                      const SizedBox(height: 20),
                      Text('Skills / instruments',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      skillsAsync.when(
                        loading: () => const LinearProgressIndicator(),
                        error: (_, __) =>
                            const Text('Could not load skills list'),
                        data: (skills) => Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: skills.map((skill) {
                            final selected =
                                _selectedSkills.contains(skill.name);
                            return FilterChip(
                              label: Text(skill.name),
                              selected: selected,
                              onSelected: (v) => setState(() => v
                                  ? _selectedSkills.add(skill.name)
                                  : _selectedSkills.remove(skill.name)),
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
                              decoration: const InputDecoration(
                                  labelText: 'Starting price (USD)'),
                              validator: (v) =>
                                  Validators.positiveNumber(v, field: 'Price'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _experienceController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                  labelText: 'Years of experience'),
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
                          hintText:
                              'e.g. Weekends only, or available for evening events on short notice',
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _youtubeController,
                        decoration: const InputDecoration(
                          labelText: 'YouTube video link (optional)',
                          prefixIcon: Icon(Icons.play_circle_outline),
                        ),
                        validator: Validators.youtubeUrl,
                      ),
                      const SizedBox(height: 28),
                      ElevatedButton(
                        onPressed: _saving ? null : () => _save(musician),
                        child: _saving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
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
