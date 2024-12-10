import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';

class ImageService {
  static Future<void> uploadProfileImage({
    required String userId,
    required bool isProfileImage,
    required BuildContext context,
  }) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      final File imageFile = File(image.path);
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String path = isProfileImage ? 'profile_images' : 'cover_images';
      
      final Reference storageRef = FirebaseStorage.instance
          .ref()
          .child(path)
          .child(userId)
          .child(fileName);

      final UploadTask uploadTask = storageRef.putFile(imageFile);
      final TaskSnapshot taskSnapshot = await uploadTask;
      final String downloadUrl = await taskSnapshot.ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({
            isProfileImage ? 'profileImageUrl' : 'coverImageUrl': downloadUrl,
          });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Immagine caricata con successo!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore nel caricamento dell\'immagine: $e')),
      );
    }
  }
} 