import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController _nameController = TextEditingController();
  File? _profileImage;
  File? _coverImage;
  String? _coverImageUrl;
  bool _isEditingName = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = FirebaseAuth.instance.currentUser?.displayName ?? "";
    _loadCoverImageUrl();
  }

  // Garder toutes les fonctions existantes identiques...
  Future<void> _loadCoverImageUrl() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      final docSnapshot = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (docSnapshot.exists) {
        setState(() {
          _coverImageUrl = docSnapshot.data()?['coverImageUrl'];
        });
      }
    }
  }

  Future<void> _updateProfilePicture() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _profileImage = File(image.path);
      });
      await _uploadImage(_profileImage!, 'profile_pictures/${FirebaseAuth.instance.currentUser!.uid}', true);
    }
  }

  Future<void> _updateCoverPicture() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _coverImage = File(image.path);
      });
      await _uploadImage(_coverImage!, 'cover_pictures/${FirebaseAuth.instance.currentUser!.uid}', false);
    }
  }

  Future<void> _uploadImage(File image, String path, bool isProfilePicture) async {
    try {
      final ref = FirebaseStorage.instance.ref().child(path);
      await ref.putFile(image);
      final url = await ref.getDownloadURL();
      if (isProfilePicture) {
        await FirebaseAuth.instance.currentUser!.updatePhotoURL(url);
      } else {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .set({'coverImageUrl': url}, SetOptions(merge: true));
        setState(() {
          _coverImageUrl = url;
        });
      }
    } catch (e) {
      print("Error uploading image: $e");
    }
  }

  Future<void> _updateDisplayName() async {
    if (_nameController.text.isNotEmpty) {
      try {
        await FirebaseAuth.instance.currentUser!.updateDisplayName(_nameController.text);
        await FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .set({'displayName': _nameController.text}, SetOptions(merge: true));
        setState(() {
          _isEditingName = false;
        });
      } catch (e) {
        print("Error updating display name: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          "Profil",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: IconButton(
              onPressed: () => signOut(context),
              icon: Icon(Icons.logout, color: Colors.red[400]),
              tooltip: 'Déconnexion',
            ),
          ),
        ],
      ),
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            );
          }
          final user = snapshot.data!;
          return SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          offset: Offset(0, 2),
                          blurRadius: 6.0,
                        ),
                      ],
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        Column(
                          children: [
                            // Image de couverture avec gradient
                            Container(
                              height: 200,
                              width: double.infinity,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  _coverImage != null
                                      ? Image.file(_coverImage!, fit: BoxFit.cover)
                                      : (_coverImageUrl != null
                                      ? Image.network(_coverImageUrl!, fit: BoxFit.cover)
                                      : Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Colors.blue[300]!,
                                          Colors.blue[600]!,
                                        ],
                                      ),
                                    ),
                                  )),
                                  // Gradient overlay
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          Colors.black.withOpacity(0.4),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 60), // Espace pour la photo de profil
                          ],
                        ),
                        // Bouton de modification de la couverture
                        Positioned(
                          top: 150,
                          right: 16,
                          child: Material(
                            elevation: 4,
                            borderRadius: BorderRadius.circular(30),
                            child: InkWell(
                              onTap: _updateCoverPicture,
                              borderRadius: BorderRadius.circular(30),
                              child: Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Icon(Icons.camera_alt,
                                  size: 20,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Photo de profil
                        Positioned(
                          top: 150,
                          child: GestureDetector(
                            onTap: _updateProfilePicture,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 4,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    blurRadius: 10,
                                    color: Colors.black26,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 50,
                                backgroundColor: Colors.white,
                                backgroundImage: _profileImage != null
                                    ? FileImage(_profileImage!)
                                    : (user.photoURL != null
                                    ? NetworkImage(user.photoURL!) as ImageProvider
                                    : null),
                                child: Stack(
                                  children: [
                                    if (user.photoURL == null && _profileImage == null)
                                      Icon(Icons.person, size: 50, color: Colors.grey[400]),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        padding: EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.blue,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 2,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.camera_alt,
                                          size: 14,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                    child: Column(
                      children: [
                        // Section nom d'utilisateur
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _isEditingName
                                    ? TextField(
                                  controller: _nameController,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'Nom d\'affichage',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                  ),
                                )
                                    : Text(
                                  user.displayName ?? "Utilisateur",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  _isEditingName ? Icons.check_circle : Icons.edit,
                                  color: Colors.blue,
                                  size: 28,
                                ),
                                onPressed: () {
                                  if (_isEditingName) {
                                    _updateDisplayName();
                                  } else {
                                    setState(() {
                                      _isEditingName = true;
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 24),
                        // Bouton Publier
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pushNamed(context, "/publier");
                            },
                            icon: Icon(Icons.add_photo_alternate),
                            label: Text(
                              "Publier",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.blue,
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      final GoogleSignIn googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
    } catch (e) {
      print("Erreur lors de la déconnexion : $e");
    }
  }
}