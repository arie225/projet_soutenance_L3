import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<void> createPost({
    required String titre,
    required double prix,
    required String description,
    required String categorie,
    required List<File> images,
  }) async {
    // Vérifier que l'utilisateur est connecté
    final user = _auth.currentUser;
    if (user == null) throw Exception('Utilisateur non connecté');

    // Récupérer les informations détaillées de l'utilisateur depuis Firestore
    final userDoc = await _firestore.collection('users').doc(user.uid).get();

    // Préparer les informations de l'utilisateur
    final userName = userDoc.exists
        ? userDoc.get('displayName')
        : user.displayName ?? 'Utilisateur';
    final userPhoto = userDoc.exists
        ? userDoc.get('photoURL')
        : user.photoURL ?? '';

    List<String> imageUrls = [];

    // Télécharge chaque image et récupère son URL
    for (var image in images) {
      final ref = _storage.ref().child('post_images/${DateTime.now().toIso8601String()}_${image.path.split('/').last}');
      await ref.putFile(image);
      String imageUrl = await ref.getDownloadURL();
      imageUrls.add(imageUrl);
    }

    // Créer le document du post avec les informations complètes
    await _firestore.collection('posts').add({
      'titre_prod': titre,
      'prix_prod': prix,
      'description': description,
      'categorie': categorie,
      'imageUrls': imageUrls,
      'timestamp': FieldValue.serverTimestamp(),
      'userId': user.uid,
      'userName': userName,
      'userPhoto': userPhoto,
      'userEmail': user.email ?? '',
    });
  }

  // Méthode pour sauvegarder/mettre à jour les informations de l'utilisateur
  static Future<void> saveUserInfo(User user) async {
    await _firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'displayName': user.displayName ?? 'Utilisateur',
      'email': user.email ?? '',
      'photoURL': user.photoURL ?? '',
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Stream<QuerySnapshot> getPostsStream() {
    return _firestore.collection('posts')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

// Autres méthodes existantes...
}