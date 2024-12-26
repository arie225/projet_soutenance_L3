import 'package:flutter/material.dart';

import 'PostFeedWidget.dart';

class affichage extends StatefulWidget {
  const affichage({super.key});

  @override
  State<affichage> createState() => _affichageState();
}

class _affichageState extends State<affichage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 10.0,
        leading: Icon(Icons.shopping_basket),

        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(
              width: 300.0,
              child: TextFormField(
                decoration: InputDecoration(
                  //labelText: "Recherche",
                  hintText: "Recherche",
                  suffixIcon: Icon(Icons.search),
                  border: OutlineInputBorder()
                ),
              ),
            ),
          )
        ],
      ),
      body: SafeArea(
          child:PostFeedWidget()
      ),
    );
  }
}
