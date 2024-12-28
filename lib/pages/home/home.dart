import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pay_and_buy/pages/home/affichage.dart';
import 'package:pay_and_buy/pages/home/homeappbar.dart';
import 'package:pay_and_buy/pages/discussion/message.dart';
import 'package:pay_and_buy/pages/profile/profile.dart';
import 'package:provider/provider.dart';
import 'package:pay_and_buy/shareui/bottomappbar.dart';

import '../discussion/ChatListPage.dart';


class HomePage extends StatefulWidget {
  final User? user;
  const HomePage({this.user});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  static List<Widget> _widgetOptions = <Widget>[
    affichage(),
    ChatListPage(),
    ProfilePage()
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }


  @override
  Widget build(BuildContext context) {
    final _user = Provider.of<User?>(context);
    return Scaffold(

      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomAppBar(
        elevation: 10.0,
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            IconButton(
              icon: Icon(_selectedIndex == 0 ? Icons.home : Icons.home_outlined),
              color: _selectedIndex == 0 ? Colors.blue : Colors.black,
              onPressed: () => _onItemTapped(0),
            ),
            IconButton(
              icon: Icon(_selectedIndex == 1 ? Icons.message : Icons.message_outlined),
              color: _selectedIndex == 1 ? Colors.blue : Colors.black,
              onPressed: () => _onItemTapped(1),
            ),
            IconButton(
              icon: Icon(_selectedIndex == 2 ? Icons.person : Icons.person_outlined),
              color: _selectedIndex == 2 ? Colors.blue : Colors.black,
              onPressed: () => _onItemTapped(2),
            ),
          ],
        ),
      ),
    );
  }
}
