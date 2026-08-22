import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/strings.dart';
import '../../models/user_profile.dart';
import '../../providers/auth_provider.dart';
import '../../shared/widgets/loading_indicator.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final _bioController = TextEditingController();
  bool _saving = false;
  bool _uploadingPhoto = false;
  bool _initialized = false;

  void _initFromProfile(UserProfile profile) {
    if (_initialized) return;
    _nameController.text = profile.displayName ?? '';
    _phoneController.text = profile.phone ?? '';
    _locationController.text = profile.location ?? '';
    _bioController.text = profile.bio ?? '';
    _initialized = true;
  }

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.gallery, maxWidth: 800, imageQuality: 85);
    if (picked == null) return;

    setState(() => _uploadingPhoto = true);
    try {
      final bytes = await picked.readAsBytes();
      final url = await ref.read(storageServiceProvider).uploadBytes(
            folder: AppStrings.profilePicturesPath,
            bytes: bytes,
            extension: 'jpg',
          );
      final uid = ref.read(authServiceProvider).currentUser!.uid;
      await ref
          .read(firestoreServiceProvider)
          .updateUser(uid, {'profile_picture_url': url});
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final uid = ref.read(authServiceProvider).currentUser!.uid;
    try {
      // ✅ Convert location to lowercase for consistency
      await ref.read(firestoreServiceProvider).updateUser(uid, {
        'display_name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'location': _locationController.text.trim().toLowerCase(),
        'bio': _bioController.text.trim(),
      });
      if (mounted) context.go('/profile');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentUserProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: profileAsync.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (profile) {
          if (profile == null) return const LoadingIndicator();
          _initFromProfile(profile);

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 48,
                            backgroundImage: profile.profilePictureUrl != null
                                ? NetworkImage(profile.profilePictureUrl!)
                                : null,
                            child: profile.profilePictureUrl == null
                                ? const Icon(Icons.person, size: 40)
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: InkWell(
                              onTap:
                                  _uploadingPhoto ? null : _pickAndUploadPhoto,
                              child: CircleAvatar(
                                radius: 16,
                                child: _uploadingPhoto
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2))
                                    : const Icon(Icons.camera_alt, size: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                        controller: _nameController,
                        decoration:
                            const InputDecoration(labelText: 'Display name')),
                    const SizedBox(height: 16),
                    TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(labelText: 'Phone')),
                    const SizedBox(height: 16),
                    TextFormField(
                        controller: _locationController,
                        decoration:
                            const InputDecoration(labelText: 'Location')),
                    const SizedBox(height: 16),
                    TextFormField(
                        controller: _bioController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                            labelText: 'Bio', alignLabelWithHint: true)),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _saving ? null : _save,
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
          );
        },
      ),
    );
  }
}
