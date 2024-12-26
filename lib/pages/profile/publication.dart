import 'package:flutter/material.dart';

import '../../shareui/zonedetext.dart';
import 'CreatePostWidget.dart';

class PublicationPage extends StatelessWidget {
  const PublicationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:SafeArea(child: CreatePostWidget()),
    );
  }
}
