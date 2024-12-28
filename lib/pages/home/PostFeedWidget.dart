import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../service/post.dart';
import 'FullScreenImage.dart';

class PostFeedWidget extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Fonction pour créer ou obtenir un ID de chat unique
  Future<String> _createOrGetChatId(String otherUserId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('Non connecté');

    // Créer un ID unique pour la conversation (toujours dans le même ordre)
    final chatId = [currentUser.uid, otherUserId]..sort();
    final conversationId = chatId.join('_');

    // Vérifier si le chat existe déjà
    final chatDoc = await _firestore.collection('chats').doc(conversationId).get();

    if (!chatDoc.exists) {
      // Créer un nouveau document de chat
      await _firestore.collection('chats').doc(conversationId).set({
        'participants': [currentUser.uid, otherUserId],
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    return conversationId;
  }

  // Fonction pour naviguer vers la page de messages
  void _navigateToChat(BuildContext context, String otherUserId, String otherUserName) async {
    try {
      final chatId = await _createOrGetChatId(otherUserId);
      Navigator.pushNamed(
        context,
        '/message',
        arguments: {
          'chatId': chatId,
          'otherUserName': otherUserName,
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseService.getPostsStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Une erreur est survenue',
              style: TextStyle(color: Colors.red[400], fontSize: 16),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
            ),
          );
        }

        return ListView(
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          children: snapshot.data!.docs.map((DocumentSnapshot document) {
            Map<String, dynamic> data = document.data()! as Map<String, dynamic>;
            List<String> imageUrls = List<String>.from(data['imageUrls'] ?? []);

            return Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              margin: EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.all(12),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundImage: data['userPhoto'] != null
                              ? NetworkImage(data['userPhoto'])
                              : null,
                          child: data['userPhoto'] == null
                              ? Icon(Icons.person)
                              : null,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  // Ne pas permettre de démarrer une conversation avec soi-même
                                  if (data['userId'] != _auth.currentUser?.uid) {
                                    _navigateToChat(
                                      context,
                                      data['userId'],
                                      data['userName'] ?? 'Utilisateur',
                                    );
                                  }
                                },
                                child: Text(
                                  data['userName'] ?? 'Utilisateur',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: data['userId'] != _auth.currentUser?.uid
                                        ? Theme.of(context).primaryColor
                                        : null,
                                    decoration: data['userId'] != _auth.currentUser?.uid
                                        ? TextDecoration.underline
                                        : null,
                                  ),
                                ),
                              ),
                              if (data['timestamp'] != null)
                                Text(
                                  _formatDate(data['timestamp'] as Timestamp),
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Galerie d'images
                  if (imageUrls.isNotEmpty)
                    Container(
                      height: 250,
                      child: ClipRRect(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                        child: PageView.builder(
                          itemCount: imageUrls.length,
                          itemBuilder: (context, index) {
                            return Stack(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => FullScreenImage(
                                          imageUrl: imageUrls[index],
                                          allImages: imageUrls,
                                          initialIndex: index,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    width: double.infinity,
                                    child: Image.network(
                                      imageUrls[index],
                                      fit: BoxFit.cover,
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return Center(
                                          child: CircularProgressIndicator(
                                            value: loadingProgress.expectedTotalBytes != null
                                                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                                : null,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                if (imageUrls.length > 1)
                                  Positioned(
                                    right: 8,
                                    bottom: 8,
                                    child: Container(
                                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${index + 1}/${imageUrls.length}',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),

                  // Contenu du post
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['titre_prod'] ?? '',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 12),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${(data['prix_prod'] as double?)?.toStringAsFixed(0) ?? ''} FCFA',
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          data["description"] ?? "",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  String _formatDate(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    DateTime now = DateTime.now();
    Duration difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return 'Il y a ${difference.inMinutes} minutes';
      }
      return 'Il y a ${difference.inHours} heures';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jours';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}