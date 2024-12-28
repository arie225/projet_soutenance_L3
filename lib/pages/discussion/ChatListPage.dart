import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatListPage extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return const Center(
        child: Text('Veuillez vous connecter pour voir vos messages'),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Messages"),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('chats')
            .where('participants', arrayContains: currentUser.uid)
            .orderBy('lastMessageTime', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final chats = snapshot.data!.docs;

          if (chats.isEmpty) {
            return const Center(
              child: Text('Aucune discussion en cours'),
            );
          }

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index].data() as Map<String, dynamic>;
              final participants = List<String>.from(chat['participants']);
              final otherUserId = participants.firstWhere(
                    (id) => id != currentUser.uid,
                orElse: () => '',
              );

              return FutureBuilder<DocumentSnapshot>(
                future: _firestore.collection('users').doc(otherUserId).get(),
                builder: (context, userSnapshot) {
                  String userName = 'Utilisateur';
                  String? userPhoto;

                  if (userSnapshot.hasData && userSnapshot.data != null) {
                    final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                    if (userData != null) {
                      userName = userData['displayName'] ?? 'Utilisateur';
                      userPhoto = userData['photoURL'];
                    }
                  }

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: userPhoto != null ? NetworkImage(userPhoto) : null,
                      child: userPhoto == null ? const Icon(Icons.person) : null,
                    ),
                    title: Text(userName),
                    subtitle: Text(
                      chat['lastMessage'] ?? 'Nouvelle conversation',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: chat['lastMessageTime'] != null
                        ? Text(_formatTimestamp(chat['lastMessageTime'] as Timestamp))
                        : null,
                    onTap: () => Navigator.pushNamed(
                      context,
                      '/message',
                      arguments: {
                        'chatId': chats[index].id,
                        'otherUserName': userName,
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final now = DateTime.now();
    final date = timestamp.toDate();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return '${diff.inMinutes}m';
      }
      return '${diff.inHours}h';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}j';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}