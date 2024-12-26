import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:pay_and_buy/pages/home/home.dart';
import 'package:pay_and_buy/pages/login.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:pay_and_buy/pages/message.dart';
import 'package:pay_and_buy/pages/profile/profile.dart';
import 'package:pay_and_buy/pages/profile/publication.dart';
import 'package:pay_and_buy/service/authservice.dart';
import 'package:pay_and_buy/wrapper.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
      MultiProvider(
        providers: [
          StreamProvider.value(
            initialData: null,
            value: AuthServices().user,
          ),
          // StreamProvider<List<Voiture>>.value(
          //   value: DataBaseService().voiture,
          //   initialData: [],
          // ),

        ],

        child: MyApp(),
      )
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(

      debugShowCheckedModeBanner: false,

      initialRoute: "/",
      routes: {
        "/": (context) => Wrapper(),
        "/profile": (context) => ProfilePage(),
        "/home": (context) => HomePage(),
        "/message": (context) => MessagePage(),
        "/publier": (context) => PublicationPage()
      },
    );
  }
}
