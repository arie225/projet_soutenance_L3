import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  static Future<void> createPost({
    required String titre,
    required double prix,
    required String description,
    required String categorie,
    required List<File> images,
  }) async {
    List<String> imageUrls = [];

    // Télécharge chaque image et récupère son URL
    for (var image in images) {
      final ref = _storage.ref().child('post_images/${DateTime.now().toIso8601String()}_${image.path.split('/').last}');
      await ref.putFile(image);
      String imageUrl = await ref.getDownloadURL();
      imageUrls.add(imageUrl);
    }

    // Ajoute le post à Firestore avec la liste des URLs d'images et les nouveaux champs
    await _firestore.collection('posts').add({
      'titre_prod': titre,
      'prix_prod': prix,
      'description': description,
      'categorie': categorie,
      'imageUrls': imageUrls,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Méthode pour obtenir un flux de posts triés par date
  static Stream<QuerySnapshot> getPostsStream() {
    return _firestore.collection('posts')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
}