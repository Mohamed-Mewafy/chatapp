import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';


class MediaService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  // Upload image
  Future<String?> uploadImage(XFile image) async {
    try {
      final ref = _storage.ref().child(
        'chat_images/${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      final uploadTask = ref.putFile(File(image.path));
      await uploadTask;
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('Upload image error: $e');
      return null;
    }
  }

  // Pick image
  Future<XFile?> pickImage() async {
    return await _picker.pickImage(source: ImageSource.gallery);
  }

  // Record voice - simplified (full implementation after UI)
  Future<String?> recordVoice() async {
    // Placeholder - full record with hold-to-talk UI coming
    debugPrint('Voice recording placeholder');
    return null;
  }

  Future<String?> uploadAudio(String path) async {
    try {
      final ref = _storage.ref().child(
        'chat_audio/${DateTime.now().millisecondsSinceEpoch}.m4a',
      );
      final uploadTask = ref.putFile(File(path));
      await uploadTask;
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('Upload audio error: $e');
      return null;
    }
  }
}

enum MessageType { text, image, voice }
