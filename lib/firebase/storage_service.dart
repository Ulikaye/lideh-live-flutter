import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

/// Handles all Firebase Storage uploads. Large binary files never go
/// into Firestore — only the resulting download URL is stored there.
class StorageService {
  final FirebaseStorage _storage;
  static const _uuid = Uuid();

  StorageService({FirebaseStorage? storage}) : _storage = storage ?? FirebaseStorage.instance;

  /// Uploads bytes to `folder/fileName` and returns the download URL.
  /// [onProgress] receives a 0.0–1.0 fraction for progress indicators.
  Future<String> uploadBytes({
    required String folder,
    required Uint8List bytes,
    required String extension,
    String? contentType,
    void Function(double progress)? onProgress,
  }) async {
    final fileName = '${_uuid.v4()}.$extension';
    final ref = _storage.ref().child('$folder/$fileName');
    final task = ref.putData(
      bytes,
      SettableMetadata(contentType: contentType ?? _contentTypeFor(extension)),
    );

    task.snapshotEvents.listen((snapshot) {
      if (onProgress != null && snapshot.totalBytes > 0) {
        onProgress(snapshot.bytesTransferred / snapshot.totalBytes);
      }
    });

    await task;
    return ref.getDownloadURL();
  }

  /// Falls back to a sensible MIME type from the file extension when the
  /// caller doesn't supply one explicitly (e.g. web bytes from
  /// image_picker often carry no type metadata of their own).
  String _contentTypeFor(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      default:
        return 'application/octet-stream';
    }
  }

  /// Deletes a previously uploaded file given its full download URL,
  /// used when replacing a profile picture/media asset to avoid orphans.
  Future<void> deleteByUrl(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (_) {
      // Non-fatal: file may already be gone or URL malformed.
    }
  }
}
