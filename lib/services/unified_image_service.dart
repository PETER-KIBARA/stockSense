import 'dart:convert';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class UnifiedImageService {
  static final ImagePicker _picker = ImagePicker();

  // Photos are stored as base64 data URLs inside the Firestore document, so no Storage
  // bucket is needed. Firestore limits a document to 1 MiB: keep photos small.
  static const double _maxDimension = 640;
  static const int _quality = 70;
  static const int _maxEncodedChars = 700 * 1024;

  static Future<XFile?> pickImageFromGallery() => _pick(ImageSource.gallery);
  static Future<XFile?> pickImageFromCamera() => _pick(ImageSource.camera);

  static Future<XFile?> _pick(ImageSource source) async {
    try {
      return await _picker.pickImage(
        source: source,
        maxWidth: _maxDimension,
        maxHeight: _maxDimension,
        imageQuality: _quality,
      );
    } catch (e) {
      return null;
    }
  }

  /// Returns a base64 data URL for the profile photo.
  static Future<String?> uploadProfileImage(XFile imageFile) =>
      _toDataUrl(imageFile);

  /// Returns a base64 data URL for an inventory item photo.
  static Future<String?> uploadInventoryImage(XFile imageFile) =>
      _toDataUrl(imageFile);

  static Future<String> _toDataUrl(XFile imageFile) async {
    final Uint8List bytes;
    try {
      bytes = await imageFile.readAsBytes();
    } catch (e) {
      throw Exception('Could not read the selected image.');
    }

    final encoded = base64Encode(bytes);
    if (encoded.length > _maxEncodedChars) {
      throw Exception('That photo is too large. Please choose a smaller one.');
    }

    final mime =
        (imageFile.mimeType != null && imageFile.mimeType!.startsWith('image/'))
            ? imageFile.mimeType!
            : 'image/jpeg';
    return 'data:$mime;base64,$encoded';
  }

  /// Deletes an image from Firebase Storage. Base64 images live in the document
  /// itself, so there is nothing to delete for them.
  static Future<bool> deleteImage(String imageUrl) async {
    if (imageUrl.isEmpty || imageUrl.startsWith('data:')) return true;
    try {
      await FirebaseStorage.instance.refFromURL(imageUrl).delete();
      return true;
    } catch (e) {
      return false;
    }
  }
}
