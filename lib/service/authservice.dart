import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';


class AuthServices {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  //connnection avec google
  Future<UserCredential> signInWithGoogle() async {
    //déclencer le flux d'authentification
    final googleuser = await _googleSignIn.signIn();

    //obtenir les details d'autorisatio de la demande
    final googleauth = await googleuser!.authentication;

    //créer un nouvel identifiant
    final credential = GoogleAuthProvider.credential(
        accessToken: googleauth.accessToken,
        idToken: googleauth.idToken
    );

    //une fois connecter renvoyer l'identifient de l'utilisateur
    return await _auth.signInWithCredential(credential);
  }

//pour obtenir l'etat de l'utilisateur en temps réel
  Stream<User?> get user => _auth.authStateChanges();

//déconnexion
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