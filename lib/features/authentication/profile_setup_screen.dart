import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
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
  final UserType userType;
  const ProfileSetupScreen({super.key, required this.userType});

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

  // Profile picture
  File? _imageFile;
  String? _uploadedImageUrl;
  bool _uploadingImage = false;

  bool _saving = false;

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

      // ✅ Force token refresh to ensure it's valid
      await user.getIdToken(true);

      final uid = user.uid;
      // Use 'musician_media/' – allowed in your rules, 50MB limit
      final storageRef = FirebaseStorage.instance.ref().child(
        'musician_media/$uid.jpg',
      );

      final metadata = SettableMetadata(contentType: 'image/jpeg');
      await storageRef.putFile(_imageFile!, metadata);
      final url = await storageRef.getDownloadURL();
      setState(() => _uploadedImageUrl = url);
      debugPrint('✅ Image uploaded: $url');
    } catch (e) {
      debugPrint('❌ Upload error: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Image upload failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  // ---------- Form submission ----------
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You must be logged in to set up your profile.'),
          ),
        );
        context.go('/login');
      }
      return;
    }
    final uid = user.uid;
    final firestore = ref.read(firestoreServiceProvider);
    final userType = widget.userType;

    try {
      // ✅ Safety net: create the user document if it's missing
      final userDoc = FirebaseFirestore.instance
          .collection(AppStrings.usersCollection)
          .doc(uid);
      final snap = await userDoc.get();
      if (!snap.exists) {
        await userDoc.set({
          'uid': uid,
          'email': user.email,
          'user_type': userType.name,
          'display_name': user.displayName ?? '',
          'created_at': FieldValue.serverTimestamp(),
        });
        debugPrint('PROFILE SETUP: Created missing user doc for UID: $uid');
      }

      if (userType == UserType.musician) {
        debugPrint('PROFILE SETUP: Creating musician document for UID: $uid');

        await firestore.setMusicianProfile(
          Musician(
            uid: uid,
            stageName: _stageNameController.text.trim(),
            skills: _selectedSkills.toList(),
            location: _locationController.text.trim(),
            startingPrice: double.tryParse(_priceController.text.trim()),
            yearsOfExperience: int.tryParse(_experienceController.text.trim()),
            youtubeVideoId: _extractYoutubeId(_youtubeController.text.trim()),
            photoURL: _uploadedImageUrl,
            joinedAt: DateTime.now(),
          ),
        );

        debugPrint(
          'PROFILE SETUP: Musician document created successfully for UID: $uid',
        );
      } else {
        await firestore.setOrganizerProfile(
          Organizer(
            uid: uid,
            organizationName: _orgNameController.text.trim(),
            churchAffiliation: _churchController.text.trim(),
            location: _locationController.text.trim(),
          ),
        );
      }

      await firestore.updateUser(uid, {
        'location': _locationController.text.trim(),
        'bio': _bioController.text.trim(),
      });

      debugPrint('PROFILE SETUP: User profile updated successfully.');

      if (mounted) {
        context.go('/');
      }
    } catch (e, stackTrace) {
      debugPrint('PROFILE SETUP ERROR: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save profile: $e'),
            duration: const Duration(seconds: 8),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  String? _extractYoutubeId(String url) {
    if (url.isEmpty) return null;
    final regExp = RegExp(r'(?:v=|youtu\.be/)([a-zA-Z0-9_-]{6,})');
    final match = regExp.firstMatch(url);
    return match?.group(1);
  }

  // ---------- Build ----------
  @override
  Widget build(BuildContext context) {
    final userType = widget.userType;

    return Scaffold(
      appBar: AppBar(title: const Text('Complete Your Profile')),
      body: Center(
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
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(
                                    Icons.camera_alt,
                                    size: 40,
                                    color: Colors.grey,
                                  ))
                          : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _uploadedImageUrl != null
                        ? 'Tap to change photo'
                        : 'Tap to add photo',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),

                  // ----- Welcome text -----
                  Text(
                    userType == UserType.musician
                        ? "Tell us about your music"
                        : 'Tell us about your organization',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 20),

                  // ----- Role-specific fields -----
                  if (userType == UserType.musician)
                    ..._musicianFields()
                  else
                    ..._organizerFields(),

                  const SizedBox(height: 16),

                  // ----- Location -----
                  TextFormField(
                    controller: _locationController,
                    decoration: const InputDecoration(
                      labelText: 'City / Region',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                    validator: (v) => Validators.required(v, field: 'Location'),
                  ),
                  const SizedBox(height: 16),

                  // ----- Bio -----
                  TextFormField(
                    controller: _bioController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Short bio',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ----- Submit button -----
                  ElevatedButton(
                    onPressed: _saving ? null : _submit,
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Finish Setup'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------- Musician fields ----------
  List<Widget> _musicianFields() {
    final skillsAsync = ref.watch(skillsProvider);
    return [
      TextFormField(
        controller: _stageNameController,
        decoration: const InputDecoration(
          labelText: 'Stage / performing name',
          prefixIcon: Icon(Icons.badge_outlined),
        ),
        validator: (v) => Validators.required(v, field: 'Stage name'),
      ),
      const SizedBox(height: 16),
      Text(
        'Skills / instruments',
        style: Theme.of(context).textTheme.titleMedium,
      ),
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
              onSelected: (v) => setState(
                () => v
                    ? _selectedSkills.add(skill.name)
                    : _selectedSkills.remove(skill.name),
              ),
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
              decoration: const InputDecoration(
                labelText: 'Starting price (USD)',
              ),
              validator: (v) => Validators.positiveNumber(v, field: 'Price'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              controller: _experienceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Years of experience',
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _youtubeController,
        decoration: const InputDecoration(
          labelText: 'YouTube video link (optional)',
          prefixIcon: Icon(Icons.play_circle_outline),
        ),
        validator: Validators.youtubeUrl,
      ),
    ];
  }

  // ---------- Organizer fields ----------
  List<Widget> _organizerFields() {
    return [
      TextFormField(
        controller: _orgNameController,
        decoration: const InputDecoration(
          labelText: 'Organization name',
          prefixIcon: Icon(Icons.church_outlined),
        ),
        validator: (v) => Validators.required(v, field: 'Organization name'),
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _churchController,
        decoration: const InputDecoration(
          labelText: 'Church affiliation (optional)',
        ),
      ),
    ];
  }
}
