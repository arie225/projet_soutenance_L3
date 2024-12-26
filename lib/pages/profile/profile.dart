import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Définition de la classe ProfilePage comme un widget avec état
class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Contrôleurs et variables pour gérer l'état de la page
  final TextEditingController _nameController = TextEditingController();
  File? _profileImage;
  File? _coverImage;
  String? _coverImageUrl;
  bool _isEditingName = false;

  @override
  void initState() {
    super.initState();
    // Initialisation du contrôleur de nom avec le nom d'utilisateur actuel
    _nameController.text = FirebaseAuth.instance.currentUser?.displayName ?? "";
    // Chargement de l'URL de l'image de couverture
    _loadCoverImageUrl();
  }

  // Fonction pour charger l'URL de l'image de couverture depuis Firestore
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

  // Fonction pour mettre à jour la photo de profil
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

  // Fonction pour mettre à jour l'image de couverture
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

  // Fonction pour télécharger une image sur Firebase Storage
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

  // Fonction pour mettre à jour le nom d'affichage de l'utilisateur
  Future<void> _updateDisplayName() async {
    if (_nameController.text.isNotEmpty) {
      try {
        // Mise à jour du nom dans Firebase Auth
        await FirebaseAuth.instance.currentUser!.updateDisplayName(_nameController.text);

        // Mise à jour du nom dans Firestore
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
      appBar: AppBar(
        title: Text("Profile"),
        actions: [
          IconButton(
            onPressed: () {
              signOut(context);
            },
            icon: Icon(Icons.logout),
          ),
        ],
      ),
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          final user = snapshot.data!;
          return SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Widget pour afficher l'image de couverture et la photo de profil
                  Stack(
                    children: [
                      // Image de couverture
                      Container(
                        height: 200,
                        width: double.infinity,
                        child: _coverImage != null
                            ? Image.file(_coverImage!, fit: BoxFit.cover)
                            : (_coverImageUrl != null
                            ? Image.network(_coverImageUrl!, fit: BoxFit.cover)
                            : Container(color: Colors.grey)),
                      ),
                      // Bouton pour modifier l'image de couverture
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: IconButton(
                          icon: Icon(Icons.camera_alt),
                          onPressed: _updateCoverPicture,
                        ),
                      ),
                      // Photo de profil
                      Positioned(
                        bottom: 0,
                        left: 20,
                        child: GestureDetector(
                          onTap: _updateProfilePicture,
                          child: CircleAvatar(
                            radius: 60,
                            backgroundImage: _profileImage != null
                                ? FileImage(_profileImage!)
                                : NetworkImage(user.photoURL ?? "") as ImageProvider,
                            child: Align(
                              alignment: Alignment.bottomRight,
                              child: CircleAvatar(
                                backgroundColor: Colors.white,
                                radius: 18,
                                child: Icon(Icons.camera_alt, size: 18, color: Colors.grey),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  // Widget pour afficher et modifier le nom d'utilisateur
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: _isEditingName
                              ? TextField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: 'Display Name',
                            ),
                          )
                              : Text(
                            user.displayName ?? "",
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          icon: Icon(_isEditingName ? Icons.check : Icons.edit),
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
                  SizedBox(height: 20),
                  // Bouton pour naviguer vers la page de publication
                  OutlinedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, "/publier");
                    },
                    child: Text(
                      "Publier",
                      style: TextStyle(color: Colors.blue),
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

  // Fonction pour déconnecter l'utilisateur
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