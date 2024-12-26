import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../service/authservice.dart';
import '../shareui/showsnackbar.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}


class _LoginPageState extends State<LoginPage> {

  // final _formKey = GlobalKey<FormState>();
  // final _phoneController = TextEditingController();
  // final _passwordController = TextEditingController();
  // final _codeController = TextEditingController();
  //
  // String _verificationId = "";
  // bool _codeSent = false;
  //
  // final FirebaseAuth _auth = FirebaseAuth.instance;
  // final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  //
  // Future<void> _verifyPhone() async {
  //   await _auth.verifyPhoneNumber(
  //     phoneNumber: _phoneController.text,
  //     verificationCompleted: (PhoneAuthCredential credential) async {
  //       await _auth.signInWithCredential(credential);
  //       _onAuthSuccess();
  //     },
  //     verificationFailed: (FirebaseAuthException e) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text("Échec de la vérification: ${e.message}")),
  //       );
  //     },
  //     codeSent: (String verificationId, int? resendToken) {
  //       setState(() {
  //         _verificationId = verificationId;
  //         _codeSent = true;
  //       });
  //     },
  //     codeAutoRetrievalTimeout: (String verificationId) {
  //       setState(() {
  //         _verificationId = verificationId;
  //       });
  //     },
  //   );
  // }
  //
  // Future<void> _signUpWithPhone() async {
  //   try {
  //     PhoneAuthCredential credential = PhoneAuthProvider.credential(
  //       verificationId: _verificationId,
  //       smsCode: _codeController.text,
  //     );
  //
  //     UserCredential userCredential = await _auth.signInWithCredential(credential);
  //     User? user = userCredential.user;
  //
  //     if (user != null) {
  //       await user.updatePassword(_passwordController.text);
  //       await _firestore.collection('users').doc(user.uid).set({
  //         'phoneNumber': user.phoneNumber,
  //         'createdAt': FieldValue.serverTimestamp(),
  //       });
  //       _onAuthSuccess();
  //     }
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text("Erreur lors de l'inscription: $e")),
  //     );
  //   }
  // }
  //
  // void _onAuthSuccess() {
  //   Navigator.of(context).pushReplacementNamed('/home'); // Assurez-vous d'avoir défini cette route
  // }


  bool inLoginProcess = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                height: MediaQuery.of(context).size.height*0.40,
                decoration: BoxDecoration(
                    color: Colors.grey,
                    image: DecorationImage(
                      image: AssetImage("asset/pay and buy.jpg"),
                      fit: BoxFit.cover,

                    )
                ),
              ),
        // Form(
        //   key: _formKey,
        //   child: Padding(
        //     padding: EdgeInsets.all(16.0),
        //     child: Column(
        //       children: [
        //         TextFormField(
        //           controller: _phoneController,
        //           decoration: InputDecoration(labelText: "Numéro de téléphone"),
        //           keyboardType: TextInputType.phone,
        //           validator: (value) {
        //             if (value == null || value.isEmpty) {
        //               return 'Veuillez entrer votre numéro de téléphone';
        //             }
        //             return null;
        //           },
        //         ),
        //         TextFormField(
        //           controller: _passwordController,
        //           decoration: InputDecoration(labelText: "Mot de passe"),
        //           obscureText: true,
        //           validator: (value) {
        //             if (value == null || value.isEmpty) {
        //               return 'Veuillez entrer un mot de passe';
        //             }
        //             return null;
        //           },
        //         ),
        //         if (_codeSent)
        //           TextFormField(
        //             controller: _codeController,
        //             decoration: InputDecoration(labelText: "Code de vérification"),
        //             validator: (value) {
        //               if (value == null || value.isEmpty) {
        //                 return 'Veuillez entrer le code de vérification';
        //               }
        //               return null;
        //             },
        //           ),
        //         SizedBox(height: 20),
        //         ElevatedButton(
        //           onPressed: () {
        //             if (_formKey.currentState!.validate()) {
        //               if (!_codeSent) {
        //                 _verifyPhone();
        //               } else {
        //                 _signUpWithPhone();
        //               }
        //             }
        //           },
        //           child: Text(_codeSent ? "S'inscrire" : "Vérifier le numéro"),
        //         ),
        //       ],
        //     ),
        //   ),
        // ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  "Bienvenue sur pay and buy l'application qui vous permettra de présenter vos produis a tous le monde",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24.0,
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: SizedBox(
                  width: 300.0,
                  height: 50.0,
                  child: inLoginProcess ? Center(
                    child: CircularProgressIndicator(),
                  ) : ElevatedButton(onPressed: (){
                    signIn(context);
                  },
                      child:Text(
                          "Connectez vous avec google"
                      )
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Future signIn(BuildContext context) async {
    try {
      final result = await InternetAddress.lookup("google.com");
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        setState(() {
          inLoginProcess = true;
        });

        try {
          UserCredential userCredential = await AuthServices().signInWithGoogle();
          if (userCredential.user != null) {
            // Navigation vers la page suivante après connexion réussie
            Navigator.of(context).pushReplacementNamed('/home');
          }
        } catch (e) {
          showNotification(context, "Erreur de connexion : $e");
        } finally {
          setState(() {
            inLoginProcess = false;
          });
        }
      }
    } on SocketException catch (_) {
      showNotification(context, "Aucune connexion internet");
    }
  }

}
