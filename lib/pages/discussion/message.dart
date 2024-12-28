import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Modèle de données pour représenter un message dans le chat
class ChatMessage {
  final String senderId;      // ID unique de l'expéditeur
  final String senderName;    // Nom de l'expéditeur
  final String message;       // Contenu du message
  final DateTime timestamp;   // Horodatage du message

  ChatMessage({
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.timestamp,
  });

  // Convertit le message en Map pour le stockage dans Firestore
  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'message': message,
      'timestamp': timestamp.millisecondsSinceEpoch,  // Conversion en millisecondes pour Firestore
    };
  }

  // Crée une instance de ChatMessage à partir des données Firestore
  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      senderId: map['senderId'],
      senderName: map['senderName'],
      message: map['message'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
    );
  }
}

class MessagePage extends StatefulWidget {
  final String chatId;
  final String otherUserName;

  const MessagePage({
    super.key,
    required this.chatId,
    required this.otherUserName,
  });

  @override
  State<MessagePage> createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage> {
  // Instances des services Firebase et contrôleurs
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final currentUser = FirebaseAuth.instance.currentUser;

  // Stream pour récupérer les messages en temps réel
  Stream<List<ChatMessage>> getMessages() {
    return _firestore
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChatMessage.fromMap(doc.data()))
          .toList();
    });
  }

  // Fonction pour envoyer un nouveau message
  Future<void> sendMessage() async {
    if (_messageController.text.trim().isEmpty || currentUser == null) return;

    final message = ChatMessage(
      senderId: currentUser!.uid,
      senderName: currentUser!.displayName ?? 'Utilisateur',
      message: _messageController.text.trim(),
      timestamp: DateTime.now(),
    );

    try {
      await _firestore
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .add(message.toMap());

      // Update last message in chat document
      await _firestore.collection('chats').doc(widget.chatId).update({
        'lastMessage': message.message,
        'lastMessageTime': FieldValue.serverTimestamp(),
      });

      _messageController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur d\'envoi: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Vérifie si l'utilisateur est connecté
    if (currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text('Veuillez vous connecter pour accéder aux messages'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Discussion"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Zone d'affichage des messages
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: getMessages(),
              builder: (context, snapshot) {
                // Gestion des états du StreamBuilder
                if (snapshot.hasError) {
                  return Center(child: Text('Erreur: ${snapshot.error}'));
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!;
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,  // Affiche les messages du plus récent au plus ancien
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isCurrentUser = message.senderId == currentUser?.uid;

                    // Construction de chaque bulle de message
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 4.0,
                      ),
                      child: Align(
                        // Aligne les messages selon l'expéditeur
                        alignment: isCurrentUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          // Limite la largeur des bulles de message
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            // Couleurs différentes pour les messages envoyés et reçus
                            color: isCurrentUser
                                ? Theme.of(context).primaryColor
                                : Colors.grey[300],
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Column(
                            crossAxisAlignment: isCurrentUser
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              // Nom de l'expéditeur
                              Text(
                                message.senderName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: isCurrentUser
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Contenu du message
                              Text(
                                message.message,
                                style: TextStyle(
                                  color:
                                  isCurrentUser ? Colors.white : Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // Zone de saisie des messages
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              children: [
                // Champ de saisie
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Écrivez votre message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Bouton d'envoi
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: sendMessage,
                  color: Theme.of(context).primaryColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Libération des ressources
  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}