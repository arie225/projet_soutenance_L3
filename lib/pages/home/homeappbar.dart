import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';


class HomeAppBar extends StatelessWidget {
  final User? user;
  const HomeAppBar({this.user});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      title: Text(
        "pay and buy",
      ),
      elevation: 0.8,
      forceElevated: true,
      floating: true,
      backgroundColor: Colors.white,
      actions: [

           IconButton(
            onPressed: (){},
            icon:Icon(Icons.search),
             iconSize: 30.0,
             color: Colors.black87,
          ),

        Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: (){
              Navigator.pushNamed(context, "/profile");
            },
            child: Hero(
              tag: user!.photoURL!,
              child: CircleAvatar(
                //backgroundColor: Colors.blue,
                backgroundImage: NetworkImage(user!.photoURL!),
              ),
            ),
          ),
        ),

      ],

    );
  }
}
