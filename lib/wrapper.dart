import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pay_and_buy/pages/home/home.dart';
import 'package:pay_and_buy/pages/login.dart';
import 'package:provider/provider.dart';

class Wrapper extends StatefulWidget {
  const Wrapper({super.key});

  @override
  State<Wrapper> createState() => _WrapperState();
}

class _WrapperState extends State<Wrapper> {
  @override
  Widget build(BuildContext context) {
    final _user = Provider.of<User?>(context);
    if (_user==null) {
      return LoginPage();
    } else{
      return HomePage();
    }
  }
}
