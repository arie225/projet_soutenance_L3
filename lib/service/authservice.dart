import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'post.dart'; // Importez votre FirebaseService

class AuthServices {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<UserCredential> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) throw Exception('Connexion Google annulée');

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken
    );

    // Connecter l'utilisateur
    final userCredential = await _auth.signInWithCredential(credential);

    // Sauvegarder les informations de l'utilisateur dans Firestore
    if (userCredential.user != null) {
      await FirebaseService.saveUserInfo(userCredential.user!);
    }

    return userCredential;
  }

  Stream<User?> get user => _auth.authStateChanges();

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
    } catch (e) {
      print("Erreur lors de la déconnexion : $e");
      throw e;
    }
  }
}