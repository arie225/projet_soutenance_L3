import 'package:flutter/material.dart';
import 'package:pay_and_buy/pages/home/home.dart';
import 'package:pay_and_buy/pages/profile/profile.dart';

class Bottomappbar extends StatefulWidget {
  const Bottomappbar({super.key});

  @override
  State<Bottomappbar> createState() => _BottomappbarState();


}

class _BottomappbarState extends State<Bottomappbar> {

  int _Currentindex = 0;

  setCurrentIndex(int index){
    setState(() {
      _Currentindex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: _Currentindex,
      onTap: (index){
        setCurrentIndex(index);
        switch (index) {
          case 0:
            Navigator.of(context).pushNamed("/home");
            //break;
          case 1:
            Navigator.of(context).pushNamed("/message");
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: "Accueil",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.message),
          label: "Message",
        ),
      ],
    );
  }
}
